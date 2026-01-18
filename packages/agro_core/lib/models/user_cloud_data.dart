import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'consent_data.dart';
import 'device_info.dart';

part 'user_cloud_data.g.dart';

/// User cloud data synced with Firestore.
/// Combines device info, preferences, and consents for cloud backup.
@HiveType(typeId: 12)
class UserCloudData extends HiveObject {
  /// Firebase Auth UID (anonymous or linked account)
  @HiveField(0)
  String uid;

  /// When the user first used the app
  @HiveField(1)
  DateTime createdAt;

  /// Last time the user opened the app
  @HiveField(2)
  DateTime lastActive;

  /// Device information (GDPR-safe)
  @HiveField(3)
  DeviceInfo deviceInfo;

  /// User consent data with versioning
  @HiveField(4)
  ConsentData consents;

  /// When data was last synced to Firestore
  @HiveField(5)
  DateTime? lastSyncedAt;

  /// Whether sync is enabled (user can opt-out)
  @HiveField(6)
  bool syncEnabled;

  UserCloudData({
    required this.uid,
    required this.createdAt,
    required this.lastActive,
    required this.deviceInfo,
    required this.consents,
    this.lastSyncedAt,
    this.syncEnabled = true,
  });

  /// Convert to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      'last_active': Timestamp.fromDate(lastActive),
      'device_info': deviceInfo.toMap(),
      'consents': consents.toMap(),
      // userId is stored in the document path, not in the data
    };
  }

  /// Create from Firestore Map
  factory UserCloudData.fromMap(String uid, Map<String, dynamic> map) {
    return UserCloudData(
      uid: uid,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      lastActive: (map['last_active'] as Timestamp).toDate(),
      deviceInfo: DeviceInfo.fromMap(map['device_info'] as Map<String, dynamic>),
      consents: ConsentData.fromMap(map['consents'] as Map<String, dynamic>),
      lastSyncedAt: DateTime.now(), // Just synced
      syncEnabled: true,
    );
  }

  /// Factory for creating initial cloud data
  factory UserCloudData.initial({
    required String uid,
    required DeviceInfo deviceInfo,
    required ConsentData consents,
  }) {
    final now = DateTime.now();
    return UserCloudData(
      uid: uid,
      createdAt: now,
      lastActive: now,
      deviceInfo: deviceInfo,
      consents: consents,
      lastSyncedAt: null,
      syncEnabled: true,
    );
  }

  /// Update last active timestamp
  void updateLastActive() {
    lastActive = DateTime.now();
  }

  /// Mark as synced
  void markSynced() {
    lastSyncedAt = DateTime.now();
  }
}
