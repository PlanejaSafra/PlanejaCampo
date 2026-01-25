import 'package:hive/hive.dart';

part 'sync_queue_item.g.dart';

/// Queue item for pending Firestore sync operations.
/// Stores rainfall data waiting to be uploaded to Firestore.
@HiveType(typeId: 4)
class SyncQueueItem extends HiveObject {
  /// Unique ID for this sync item (same as RegistroChuva.id)
  @HiveField(0)
  final int registroId;

  /// Date of the rainfall record
  @HiveField(1)
  final DateTime date;

  /// Precipitation in millimeters
  @HiveField(2)
  final double millimeters;

  /// Latitude of the property
  @HiveField(3)
  final double latitude;

  /// Longitude of the property
  @HiveField(4)
  final double longitude;

  /// GeoHash (5 characters) for regional grouping
  @HiveField(5)
  final String geoHash5;

  /// Property ID (for tracking)
  @HiveField(6)
  final String propertyId;

  /// When this item was added to the queue
  @HiveField(7)
  final DateTime queuedAt;

  /// Number of sync attempts
  @HiveField(8)
  int attempts;

  /// Last error message (if any)
  @HiveField(9)
  String? lastError;

  /// Whether this item should be retried
  @HiveField(10)
  bool shouldRetry;

  SyncQueueItem({
    required this.registroId,
    required this.date,
    required this.millimeters,
    required this.latitude,
    required this.longitude,
    required this.geoHash5,
    required this.propertyId,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
    this.shouldRetry = true,
  });

  /// Factory constructor to create from RegistroChuva
  factory SyncQueueItem.fromRainfallRecord({
    required int registroId,
    required DateTime date,
    required double millimeters,
    required double latitude,
    required double longitude,
    required String geoHash5,
    required String propertyId,
  }) {
    return SyncQueueItem(
      registroId: registroId,
      date: date,
      millimeters: millimeters,
      latitude: latitude,
      longitude: longitude,
      geoHash5: geoHash5,
      propertyId: propertyId,
      queuedAt: DateTime.now(),
    );
  }

  /// Increment attempt counter and record error
  void recordAttempt(String? error) {
    attempts++;
    lastError = error;

    // Stop retrying after 5 failed attempts
    if (attempts >= 5) {
      shouldRetry = false;
    }

    save();
  }

  /// Check if item is ready for retry (exponential backoff)
  bool get isReadyForRetry {
    if (!shouldRetry) return false;

    final now = DateTime.now();
    final timeSinceQueued = now.difference(queuedAt);

    // Exponential backoff: 1min, 5min, 15min, 1hour, 6hours
    final backoffMinutes = [1, 5, 15, 60, 360];
    final waitTime = attempts < backoffMinutes.length
        ? backoffMinutes[attempts]
        : 360;

    return timeSinceQueued.inMinutes >= waitTime;
  }

  @override
  String toString() {
    return 'SyncQueueItem(id: $registroId, date: $date, mm: $millimeters, geoHash: $geoHash5, attempts: $attempts)';
  }
}
