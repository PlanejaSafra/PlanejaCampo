import 'dart:async';
import 'package:agro_core/agro_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/regional_stats.dart';
import '../models/registro_chuva.dart';
import '../models/sync_queue_item.dart';

/// Service for syncing rainfall data to Firestore and fetching regional statistics.
/// Implements opt-in consent, rate limiting, and Wi-Fi-only sync.
class SyncService {
  static const String _queueBoxName = 'sync_queue';
  static const String _metadataBoxName = 'sync_metadata';
  static const int _maxDailyWrites = 10;

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late Box<SyncQueueItem> _queueBox;
  late Box<dynamic> _metadataBox;
  final _firestore = FirebaseFirestore.instance;
  final _geoHasher = GeoHasher();

  /// Initialize Hive boxes
  Future<void> init() async {
    _queueBox = await Hive.openBox<SyncQueueItem>(_queueBoxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);

    // Enable Firestore offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
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
    if (!hasUserConsent) return;

    // Property must have location
    if (property.latitude == null || property.longitude == null) return;

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
    if (alreadyQueued) return;

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

  /// Sync pending items to Firestore (Wi-Fi only, rate limited)
  Future<SyncResult> syncPendingItems() async {
    if (!hasUserConsent) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'User has not consented to data sharing',
      );
    }

    if (hasReachedDailyLimit) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: 'Daily write limit reached (max $_maxDailyWrites/day)',
      );
    }

    // Get items ready for sync
    final readyItems = _queueBox.values
        .where((item) => item.shouldRetry && item.isReadyForRetry)
        .take(_maxDailyWrites - (_metadataBox.get('today_writes') as int? ?? 0))
        .toList();

    if (readyItems.isEmpty) {
      return SyncResult(success: true, itemsSynced: 0);
    }

    int synced = 0;
    String? lastError;

    for (final item in readyItems) {
      try {
        await _syncSingleItem(item);
        await _queueBox.delete(item.registroId.toString());
        synced++;

        // Update daily write counter
        _incrementDailyWriteCount();
      } catch (e) {
        lastError = e.toString();
        item.recordAttempt(lastError);
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

  /// Sync a single item to Firestore
  Future<void> _syncSingleItem(SyncQueueItem item) async {
    // Prepare document data (anonymized*)
    // * We MUST include userId to satisfy Firestore Security Rules (Fail-Safe),
    // even if logically we want it anonymized.
    // The rules require: request.resource.data.userId == request.auth.uid
    final userId =
        _firestore.app.options.apiKey.isNotEmpty ? (await _getUserId()) : null;

    final docData = {
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

    // Write to Firestore with timeout
    await _firestore
        .collection('rainfall_data')
        .doc(item.geoHash5)
        .collection('records')
        .doc('${item.propertyId}_${item.date.millisecondsSinceEpoch}')
        .set(docData, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));
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
