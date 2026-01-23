import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/consent_data.dart';
import '../models/device_info.dart' as models;
import '../models/user_cloud_data.dart';

/// Service for syncing user data with Firestore.
/// Implements offline-first with fire-and-forget cloud backup.
class UserCloudService {
  UserCloudService._();

  static final UserCloudService _instance = UserCloudService._();
  static UserCloudService get instance => _instance;

  static const String _boxName = 'user_cloud_data';
  static const String _collectionName = 'users';

  Box<UserCloudData>? _box;
  FirebaseFirestore? _firestore;

  /// Initialize the service (opens Hive box, sets up Firebase)
  /// Note: Hive adapters must be registered before calling this method
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    _box = await Hive.openBox<UserCloudData>(_boxName);
    _firestore = FirebaseFirestore.instance;
  }

  Box<UserCloudData> get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'UserCloudService not initialized. Call UserCloudService.init() first.',
      );
    }
    return _box!;
  }

  /// Get current user's cloud data (from Hive cache)
  UserCloudData? getCurrentUserData() {
    if (_safeBox.isEmpty) return null;
    return _safeBox.getAt(0);
  }

  /// Create initial user data when first launching the app
  Future<UserCloudData> createInitialUserData({
    required String uid,
    required ConsentData consents,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    final userData = UserCloudData.initial(
      uid: uid,
      deviceInfo: deviceInfo,
      consents: consents,
    );

    // Save to Hive
    await _safeBox.clear();
    await _safeBox.add(userData);

    // Sync to Firestore (fire-and-forget)
    _syncToFirestore(userData);

    return userData;
  }

  /// Update user consent data
  Future<void> updateConsents(ConsentData consents) async {
    final userData = getCurrentUserData();
    if (userData == null) {
      throw StateError('No user data found. Call createInitialUserData first.');
    }

    userData.consents = consents;
    userData.updateLastActive();
    await userData.save();

    // Sync to Firestore (fire-and-forget)
    _syncToFirestore(userData);
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    final userData = getCurrentUserData();
    if (userData == null) return; // Silently fail if no user data

    userData.updateLastActive();
    await userData.save();

    // Sync to Firestore (fire-and-forget, throttled)
    _syncToFirestoreThrottled(userData);
  }

  /// Sync user data to Firestore (fire-and-forget)
  void _syncToFirestore(UserCloudData userData) {
    if (!userData.syncEnabled) return;
    if (_firestore == null) return;

    // Fire-and-forget: don't await
    _firestore!
        .collection(_collectionName)
        .doc(userData.uid)
        .set(userData.toMap(), SetOptions(merge: true))
        .then((_) {
      userData.markSynced();
      userData.save();
    }).catchError((error) {
      // Silently fail - user is offline-first
      // We'll retry on next app launch
    });
  }

  /// Throttled sync (only if last sync was > 5 minutes ago)
  void _syncToFirestoreThrottled(UserCloudData userData) {
    if (!userData.syncEnabled) return;
    if (userData.lastSyncedAt != null) {
      final timeSinceLastSync =
          DateTime.now().difference(userData.lastSyncedAt!);
      if (timeSinceLastSync.inMinutes < 5) {
        return; // Skip sync, too recent
      }
    }
    _syncToFirestore(userData);
  }

  /// Enable/disable cloud sync
  Future<void> setSyncEnabled(bool enabled) async {
    final userData = getCurrentUserData();
    if (userData == null) return;

    userData.syncEnabled = enabled;
    await userData.save();

    if (!enabled) {
      // Delete from Firestore
      await deleteCloudData();
    }
  }

  /// Delete user data from Firestore (LGPD compliance)
  Future<void> deleteCloudData() async {
    final userData = getCurrentUserData();
    if (userData == null) return;
    if (_firestore == null) return;

    try {
      await _firestore!.collection(_collectionName).doc(userData.uid).delete();
    } catch (e) {
      // Ignore errors (user might be offline)
    }
  }

  /// Export all user data for LGPD compliance
  Map<String, dynamic> exportAllData() {
    final userData = getCurrentUserData();
    if (userData == null) return {};

    return {
      'uid': userData.uid,
      'created_at': userData.createdAt.toIso8601String(),
      'last_active': userData.lastActive.toIso8601String(),
      'device_info': userData.deviceInfo.toMap(),
      'consents': userData.consents.toMap(),
      'last_synced_at': userData.lastSyncedAt?.toIso8601String(),
      'sync_enabled': userData.syncEnabled,
    };
  }

  /// Get device information (GDPR-safe)
  Future<models.DeviceInfo> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String platform;
    String? deviceModel;
    String? osVersion;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      platform = 'android';
      deviceModel = androidInfo.model;
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      platform = 'ios';
      deviceModel = iosInfo.model;
      osVersion = iosInfo.systemVersion;
    } else {
      platform = 'unknown';
    }

    return models.DeviceInfo(
      platform: platform,
      appVersion: packageInfo.version,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  /// Fetch user data from Firestore (for account linking recovery)
  Future<UserCloudData?> fetchFromFirestore(String uid) async {
    if (_firestore == null) return null;

    try {
      final doc = await _firestore!.collection(_collectionName).doc(uid).get();
      if (!doc.exists) return null;

      final userData = UserCloudData.fromMap(uid, doc.data()!);

      // Save to Hive
      await _safeBox.clear();
      await _safeBox.add(userData);

      return userData;
    } catch (e) {
      return null;
    }
  }

  /// Sync a private rainfall record to flat collection (relational model)
  Future<void> syncRainfallRecord({
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final userData = getCurrentUserData();
    if (userData == null || !userData.syncEnabled) return;

    // Check specific backup consent
    if (userData.consents.cloudBackup != true) return;

    if (_firestore == null) return;

    try {
      // Use flat collection with userId as FK (no subcollections)
      final docData = Map<String, dynamic>.from(data);
      docData['userId'] = userData.uid;

      await _firestore!
          .collection('rainfall_records')
          .doc(recordId)
          .set(docData, SetOptions(merge: true));
    } catch (e) {
      // Fire-and-forget
    }
  }

  /// Delete a private rainfall record from cloud (flat collection)
  Future<void> deleteRainfallRecord(String recordId) async {
    final userData = getCurrentUserData();
    if (userData == null) return;

    // Even if consent is off NOW, if we are deleting, we should try to delete from cloud
    // in case it was synced BEFORE. Deletion should always propagate if possible.

    if (_firestore == null) return;

    try {
      // Use flat collection (no subcollections)
      await _firestore!.collection('rainfall_records').doc(recordId).delete();
    } catch (e) {
      // safe fail
    }
  }
}
