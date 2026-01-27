import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../privacy/agro_privacy_store.dart';

/// Data ready for Tier 2 upload (anonymized aggregate data).
///
/// Contains only Hive-serializable types (no Firestore-specific types).
/// DateTime fields are automatically converted to Firestore Timestamps
/// at upload time.
class Tier2UploadItem {
  /// Firestore document ID
  final String docId;

  /// Firestore collection name (flat root collection, NO subcollections)
  final String collection;

  /// Anonymized data map (Hive-serializable types only:
  /// String, int, double, bool, DateTime, List, Map)
  final Map<String, dynamic> data;

  Tier2UploadItem({
    required this.docId,
    required this.collection,
    required this.data,
  });
}

/// Manages the Tier 2 (anonymous aggregate) sync pipeline.
///
/// Tier 2 = anonymized, consent-gated, rate-limited, one-directional upload.
/// Used for aggregate statistics (e.g., rainfall data) that benefit the
/// community while preserving user privacy.
///
/// Features:
/// - Consent-gated via [AgroPrivacyStore.consentAggregateMetrics]
/// - Rate-limited (configurable daily max writes)
/// - Exponential backoff retry (1m, 5m, 15m, 1h, 6h)
/// - Periodic retry timer
/// - Flat root collections only (subcollection detection guard)
///
/// See also: [GenericSyncService.buildTier2Data]
class Tier2Pipeline {
  final String serviceName;
  final int dailyLimit;
  final Duration retryInterval;

  /// Optional callback to prepare data for Firestore upload.
  /// Called right before writing to Firestore, allowing conversion of
  /// Hive-serializable types to Firestore types (e.g., DateTime → Timestamp).
  /// If null, uses default conversion (DateTime → Timestamp, adds uploaded_at).
  final Map<String, dynamic> Function(Map<String, dynamic> data)?
      dataConverter;

  static const String _queueBoxPrefix = 'tier2_queue_';
  static const String _metaBoxPrefix = 'tier2_meta_';

  Box<dynamic>? _queueBox;
  Box<dynamic>? _metaBox;
  Timer? _retryTimer;
  bool _initialized = false;

  Tier2Pipeline({
    required this.serviceName,
    this.dailyLimit = 10,
    this.retryInterval = const Duration(minutes: 2),
    this.dataConverter,
  });

  String get _queueBoxName => '$_queueBoxPrefix$serviceName';
  String get _metaBoxName => '$_metaBoxPrefix$serviceName';

  /// Initialize Hive boxes and start periodic retry.
  Future<void> init() async {
    if (_initialized) return;

    if (!Hive.isBoxOpen(_queueBoxName)) {
      _queueBox = await Hive.openBox(_queueBoxName);
    } else {
      _queueBox = Hive.box(_queueBoxName);
    }

    if (!Hive.isBoxOpen(_metaBoxName)) {
      _metaBox = await Hive.openBox(_metaBoxName);
    } else {
      _metaBox = Hive.box(_metaBoxName);
    }

    _initialized = true;

    debugPrint('[Tier2/$serviceName] Pipeline initialized. '
        'Pending: $pendingCount');

    _startPeriodicRetry();
  }

  /// Dispose timer resources.
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Queue an item for Tier 2 upload.
  /// Skips if consent not given or subcollection detected.
  Future<void> queue(Tier2UploadItem item) async {
    if (!_initialized) return;

    if (!AgroPrivacyStore.consentAggregateMetrics) {
      debugPrint('[Tier2/$serviceName] queue: SKIPPED — no consent');
      return;
    }

    // Subcollection detection guard
    if (item.collection.contains('/')) {
      debugPrint('[Tier2/$serviceName] ERROR: Subcollection detected '
          'in collection "${item.collection}". '
          'Tier 2 requires flat root collections only!');
      return;
    }

    // Check for duplicates
    if (_queueBox!.containsKey(item.docId)) {
      debugPrint('[Tier2/$serviceName] queue: SKIPPED — '
          '${item.docId} already queued');
      return;
    }

    final queueEntry = <String, dynamic>{
      'docId': item.docId,
      'collection': item.collection,
      'data': item.data,
      'queuedAt': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
      'lastError': null,
      'shouldRetry': true,
    };

    await _queueBox!.put(item.docId, queueEntry);
    debugPrint('[Tier2/$serviceName] queue: QUEUED ${item.docId} '
        '(queue size: ${_queueBox!.length})');
  }

  /// Re-queue an item (replaces existing entry).
  Future<void> reQueue(Tier2UploadItem item) async {
    if (!_initialized) return;
    await _queueBox!.delete(item.docId);
    await queue(item);
  }

  /// Sync pending items to Firestore (rate-limited, consent-gated).
  Future<Tier2SyncResult> syncPending() async {
    if (!_initialized) {
      return Tier2SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'Pipeline not initialized',
      );
    }

    if (!AgroPrivacyStore.consentAggregateMetrics) {
      debugPrint('[Tier2/$serviceName] syncPending: SKIPPED — no consent');
      return Tier2SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'No consent',
      );
    }

    if (_hasReachedDailyLimit) {
      debugPrint('[Tier2/$serviceName] syncPending: SKIPPED — daily limit');
      return Tier2SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'Daily limit reached ($dailyLimit/day)',
      );
    }

    final readyItems = _getReadyItems();
    if (readyItems.isEmpty) {
      return Tier2SyncResult(success: true, itemsSynced: 0);
    }

    debugPrint('[Tier2/$serviceName] syncPending: '
        '${readyItems.length} items ready');

    int synced = 0;
    String? lastError;

    for (final entry in readyItems) {
      if (_hasReachedDailyLimit) break;

      final docId = entry['docId'] as String;
      final collection = entry['collection'] as String;
      final rawData = Map<String, dynamic>.from(entry['data'] as Map);
      final attempts = entry['attempts'] as int;

      try {
        debugPrint('[Tier2/$serviceName] Syncing $docId '
            '(attempt ${attempts + 1})...');

        // Convert data for Firestore upload
        final uploadData = dataConverter != null
            ? dataConverter!(rawData)
            : _defaultDataConverter(rawData);

        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .set(uploadData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));

        // Success: remove from queue
        await _queueBox!.delete(docId);
        synced++;
        _incrementDailyCount();
        debugPrint('[Tier2/$serviceName] $docId synced OK');
      } catch (e) {
        lastError = e.toString();
        _recordAttempt(docId, lastError);
        debugPrint('[Tier2/$serviceName] $docId FAILED: $lastError '
            '(attempts: ${attempts + 1}/5)');
      }
    }

    if (synced > 0) {
      _updateLastSyncTimestamp();
    }

    return Tier2SyncResult(
      success: lastError == null,
      itemsSynced: synced,
      error: lastError,
    );
  }

  /// Number of pending items that can still retry.
  int get pendingCount {
    if (!_initialized) return 0;
    return _queueBox!.values
        .where((e) => (e as Map)['shouldRetry'] == true)
        .length;
  }

  /// Last successful sync timestamp.
  DateTime? get lastSyncTime {
    if (!_initialized) return null;
    final ts = _metaBox!.get('last_sync_timestamp') as int?;
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Clear all queue items (for testing/debugging).
  Future<void> clearQueue() async {
    await _queueBox?.clear();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────

  void _startPeriodicRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(retryInterval, (_) async {
      if (!AgroPrivacyStore.consentAggregateMetrics) return;
      if (_hasReachedDailyLimit) return;
      if (pendingCount == 0) return;

      debugPrint(
          '[Tier2/$serviceName] Periodic retry: $pendingCount pending');
      final result = await syncPending();
      if (result.itemsSynced > 0) {
        debugPrint('[Tier2/$serviceName] Periodic retry synced '
            '${result.itemsSynced} items');
      }
    });
  }

  bool get _hasReachedDailyLimit {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _metaBox!.get('last_sync_date') as String?;
    final todayWrites = _metaBox!.get('today_writes') as int? ?? 0;

    if (lastDate != today) return false;
    return todayWrites >= dailyLimit;
  }

  void _incrementDailyCount() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _metaBox!.get('last_sync_date') as String?;
    final todayWrites = _metaBox!.get('today_writes') as int? ?? 0;

    if (lastDate != today) {
      _metaBox!.put('last_sync_date', today);
      _metaBox!.put('today_writes', 1);
    } else {
      _metaBox!.put('today_writes', todayWrites + 1);
    }
  }

  void _updateLastSyncTimestamp() {
    _metaBox!.put(
        'last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>> _getReadyItems() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _metaBox!.get('last_sync_date') as String?;
    final todayWrites = _metaBox!.get('today_writes') as int? ?? 0;
    final remaining = lastDate != today ? dailyLimit : dailyLimit - todayWrites;

    if (remaining <= 0) return [];

    return _queueBox!.values
        .where((e) {
          final map = e as Map;
          if (map['shouldRetry'] != true) return false;
          return _isReadyForRetry(map);
        })
        .take(remaining)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Exponential backoff: first attempt immediate, then 1m, 5m, 15m, 1h, 6h.
  bool _isReadyForRetry(Map entry) {
    final attempts = entry['attempts'] as int? ?? 0;

    // First attempt: always ready (no backoff for fresh items)
    if (attempts == 0) return true;

    final queuedAt =
        DateTime.fromMillisecondsSinceEpoch(entry['queuedAt'] as int);
    final elapsed = DateTime.now().difference(queuedAt).inMinutes;

    const backoff = [1, 5, 15, 60, 360];
    final idx = attempts - 1;
    final waitMinutes = idx < backoff.length ? backoff[idx] : 360;

    return elapsed >= waitMinutes;
  }

  void _recordAttempt(String docId, String? error) {
    final entry = _queueBox!.get(docId);
    if (entry == null) return;

    final map = Map<String, dynamic>.from(entry as Map);
    map['attempts'] = (map['attempts'] as int? ?? 0) + 1;
    map['lastError'] = error;

    if ((map['attempts'] as int) >= 5) {
      map['shouldRetry'] = false;
    }

    _queueBox!.put(docId, map);
  }

  /// Default data converter: DateTime → Firestore Timestamp, adds uploaded_at.
  static Map<String, dynamic> _defaultDataConverter(
      Map<String, dynamic> data) {
    final upload = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is DateTime) {
        upload[entry.key] =
            Timestamp.fromDate(entry.value as DateTime);
      } else {
        upload[entry.key] = entry.value;
      }
    }
    upload['uploaded_at'] = FieldValue.serverTimestamp();
    return upload;
  }
}

/// Result of a Tier 2 sync operation.
class Tier2SyncResult {
  final bool success;
  final int itemsSynced;
  final String? error;

  Tier2SyncResult({
    required this.success,
    required this.itemsSynced,
    this.error,
  });

  @override
  String toString() =>
      'Tier2SyncResult(success: $success, synced: $itemsSynced, '
      'error: $error)';
}
