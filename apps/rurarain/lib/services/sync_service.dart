import 'dart:async';
import 'package:agro_core/agro_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/regional_stats.dart';
import '../models/registro_chuva.dart';
import '../models/sync_queue_item.dart';

/// Service for syncing rainfall data to Firestore and fetching regional statistics.
/// Implements opt-in consent, rate limiting, and periodic retry.
class SyncService {
  static const String _queueBoxName = 'sync_queue';
  static const String _metadataBoxName = 'sync_metadata';
  static const int _maxDailyWrites = 10;

  /// Interval between periodic sync attempts.
  static const Duration _retryInterval = Duration(minutes: 2);

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late Box<SyncQueueItem> _queueBox;
  late Box<dynamic> _metadataBox;
  final _firestore = FirebaseFirestore.instance;
  final _geoHasher = GeoHasher();
  Timer? _retryTimer;
  bool _initialized = false;

  /// Initialize Hive boxes and start periodic sync.
  Future<void> init() async {
    if (_initialized) return;

    _queueBox = await Hive.openBox<SyncQueueItem>(_queueBoxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);

    // Enable Firestore offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    _initialized = true;

    debugPrint('[Tier2] SyncService initialized. '
        'Pending items: $pendingItemCount');

    // Start periodic retry for items that failed or were queued while offline
    _startPeriodicSync();
  }

  /// Start periodic sync timer to retry failed/pending items.
  void _startPeriodicSync() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) async {
      if (!hasUserConsent) return;
      if (hasReachedDailyLimit) return;
      if (pendingItemCount == 0) return;

      debugPrint('[Tier2] Periodic retry: $pendingItemCount pending items');
      final result = await syncPendingItems();
      if (result.itemsSynced > 0) {
        debugPrint('[Tier2] Periodic retry synced ${result.itemsSynced} items');
        updateLastSyncTimestamp();
      }
      if (result.error != null) {
        debugPrint('[Tier2] Periodic retry error: ${result.error}');
      }
    });
  }

  /// Stop periodic sync (call on dispose).
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Check if user has consented to data sharing
  bool get hasUserConsent => AgroPrivacyStore.consentAggregateMetrics;

  /// Check if daily write limit has been reached
  bool get hasReachedDailyLimit {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastSyncDate = _metadataBox.get('last_sync_date') as String?;
    final todayWrites = _metadataBox.get('today_writes') as int? ?? 0;

    if (lastSyncDate != today) {
      // New day, reset counter
      return false;
    }

    return todayWrites >= _maxDailyWrites;
  }

  /// Queue a rainfall record for sync
  Future<void> queueForSync(RegistroChuva registro, Property property) async {
    // Only queue if user has consented
    if (!hasUserConsent) {
      debugPrint('[Tier2] queueForSync: SKIPPED — no user consent');
      return;
    }

    // Property must have location
    if (property.latitude == null || property.longitude == null) {
      debugPrint('[Tier2] queueForSync: SKIPPED — property "${property.name}" '
          'has no location (lat=${property.latitude}, lon=${property.longitude})');
      return;
    }

    // Generate GeoHash
    final geoHash5 = _geoHasher.encode(
      property.longitude!,
      property.latitude!,
      precision: 5,
    );

    // Check if already queued
    final alreadyQueued = _queueBox.values.any(
      (item) => item.registroId == registro.id,
    );
    if (alreadyQueued) {
      debugPrint('[Tier2] queueForSync: SKIPPED — registro ${registro.id} already queued');
      return;
    }

    // Create queue item
    final queueItem = SyncQueueItem.fromRainfallRecord(
      registroId: registro.id,
      date: registro.data,
      millimeters: registro.milimetros,
      latitude: property.latitude!,
      longitude: property.longitude!,
      geoHash5: geoHash5,
      propertyId: property.id,
    );

    // Add to queue
    await _queueBox.put(registro.id.toString(), queueItem);
    debugPrint('[Tier2] queueForSync: QUEUED registro ${registro.id} '
        '(${registro.milimetros}mm, geoHash=$geoHash5). '
        'Queue size: ${_queueBox.length}');
  }

  /// Re-queue an updated rainfall record (replaces existing queue item).
  /// If the record was already synced (not in queue), queues as new.
  Future<void> reQueueForSync(
      RegistroChuva registro, Property property) async {
    if (!hasUserConsent) return;
    if (property.latitude == null || property.longitude == null) return;

    // Remove existing queue item if present
    await _queueBox.delete(registro.id.toString());

    // Queue with updated data
    await queueForSync(registro, property);
  }

  /// Sync pending items to Firestore (rate limited)
  Future<SyncResult> syncPendingItems() async {
    if (!hasUserConsent) {
      debugPrint('[Tier2] syncPendingItems: SKIPPED — no consent');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'User has not consented to data sharing',
      );
    }

    if (hasReachedDailyLimit) {
      debugPrint('[Tier2] syncPendingItems: SKIPPED — daily limit reached');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'Daily write limit reached (max $_maxDailyWrites/day)',
      );
    }

    // Get items ready for sync
    final allItems = _queueBox.values.toList();
    final readyItems = allItems
        .where((item) => item.shouldRetry && item.isReadyForRetry)
        .take(_maxDailyWrites - (_metadataBox.get('today_writes') as int? ?? 0))
        .toList();

    debugPrint('[Tier2] syncPendingItems: '
        'total=${allItems.length}, '
        'shouldRetry=${allItems.where((i) => i.shouldRetry).length}, '
        'ready=${readyItems.length}');

    if (readyItems.isEmpty) {
      return SyncResult(success: true, itemsSynced: 0);
    }

    int synced = 0;
    String? lastError;

    for (final item in readyItems) {
      try {
        debugPrint('[Tier2] Syncing item ${item.registroId} '
            '(attempt ${item.attempts + 1})...');
        await _syncSingleItem(item);
        await _queueBox.delete(item.registroId.toString());
        synced++;

        // Update daily write counter
        _incrementDailyWriteCount();
        debugPrint('[Tier2] Item ${item.registroId} synced SUCCESSFULLY');
      } catch (e) {
        lastError = e.toString();
        item.recordAttempt(lastError);
        debugPrint('[Tier2] Item ${item.registroId} FAILED: $lastError '
            '(attempts: ${item.attempts}/5)');
      }

      // Respect rate limit
      if (hasReachedDailyLimit) break;
    }

    return SyncResult(
      success: lastError == null,
      itemsSynced: synced,
      error: lastError,
    );
  }

  /// Sync a single item to Firestore.
  ///
  /// Uses flat root collection (no subcollections per project rules):
  /// `rainfall_data/{geoHash5}_{propertyId}_{timestamp}`
  Future<void> _syncSingleItem(SyncQueueItem item) async {
    // Prepare document data (anonymized — only userId for security rules)
    final userId = await _getUserId();

    final docData = <String, dynamic>{
      'mm': item.millimeters,
      'date': Timestamp.fromDate(item.date),
      'lat': item.latitude,
      'lon': item.longitude,
      'geohash5': item.geoHash5,
      'geohash4': item.geoHash5.substring(0, 4),
      'geohash3': item.geoHash5.substring(0, 3),
      'uploaded_at': FieldValue.serverTimestamp(),
    };

    if (userId != null) {
      docData['userId'] = userId;
    }

    // Flat collection — docId encodes geoHash + property + timestamp
    final docId =
        '${item.geoHash5}_${item.propertyId}_${item.date.millisecondsSinceEpoch}';
    debugPrint('[Tier2] Writing to Firestore: rainfall_data/$docId');

    // Write to Firestore with timeout
    await _firestore
        .collection('rainfall_data')
        .doc(docId)
        .set(docData, SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  /// Increment daily write counter
  void _incrementDailyWriteCount() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastSyncDate = _metadataBox.get('last_sync_date') as String?;
    final todayWrites = _metadataBox.get('today_writes') as int? ?? 0;

    if (lastSyncDate != today) {
      // New day, reset counter
      _metadataBox.put('last_sync_date', today);
      _metadataBox.put('today_writes', 1);
    } else {
      _metadataBox.put('today_writes', todayWrites + 1);
    }
  }

  /// Fetch regional statistics for a location
  Future<RegionalStats?> fetchRegionalStats({
    required double latitude,
    required double longitude,
  }) async {
    final geoHash5 = _geoHasher.encode(longitude, latitude, precision: 5);
    final geoHash4 = geoHash5.substring(0, 4);
    final geoHash3 = geoHash5.substring(0, 3);

    // Try geoHash5 first (most precise)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash5)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // Ignore, try broader area
    }

    // Try geoHash4 (broader area)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash4)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // Ignore, try even broader
    }

    // Try geoHash3 (very broad area)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash3)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // No regional data available
    }

    return null;
  }

  /// Get pending sync queue count
  int get pendingItemCount =>
      _queueBox.values.where((item) => item.shouldRetry).length;

  /// Clear all sync queue (for testing/debugging)
  Future<void> clearQueue() async {
    await _queueBox.clear();
  }

  /// Get last sync timestamp
  DateTime? get lastSyncTime {
    final timestamp = _metadataBox.get('last_sync_timestamp') as int?;
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update last sync timestamp
  void updateLastSyncTimestamp() {
    _metadataBox.put(
        'last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _getUserId() async {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final String? error;

  SyncResult({
    required this.success,
    required this.itemsSynced,
    this.error,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $itemsSynced, error: $error)';
  }
}
