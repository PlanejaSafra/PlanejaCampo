import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../privacy/agro_privacy_store.dart';

/// Service for LGPD-compliant data deletion (Art. 18, VI - Right to Erasure).
/// Deletes all user data from Firestore, Firebase Auth, and local Hive boxes.
class DataDeletionService {
  DataDeletionService._();
  static final DataDeletionService instance = DataDeletionService._();

  /// List of Hive box names to clear during data deletion.
  /// Apps should register their boxes using [registerHiveBox].
  final List<String> _hiveBoxNames = [
    'agro_settings',
    'properties',
    'talhoes',
    'weather_cache',
    'sync_queue',
  ];

  /// Register additional Hive box for deletion (app-specific boxes).
  void registerHiveBox(String boxName) {
    if (!_hiveBoxNames.contains(boxName)) {
      _hiveBoxNames.add(boxName);
    }
  }

  /// Delete ALL user data. This action is IRREVERSIBLE.
  ///
  /// Deletes:
  /// - Firestore: users/{uid}/* (all subcollections)
  /// - Firebase Auth: user account
  /// - Hive: all registered local boxes
  /// - Privacy store: reset to initial state
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> deleteAllUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('DataDeletionService: No user logged in');
      return false;
    }

    final uid = user.uid;
    debugPrint('DataDeletionService: Starting data deletion for uid=$uid');

    try {
      // 1. Delete Firestore user data (with subcollections)
      await _deleteFirestoreUserData(uid);

      // 2. Delete Firebase Storage backup (if exists)
      // Note: Storage deletion is optional, handled by Cloud Functions cleanup

      // 3. Clear all local Hive boxes
      await _clearAllLocalData();

      // 4. Reset privacy store
      await AgroPrivacyStore.resetAll();

      // 5. Delete Firebase Auth account (must be last - invalidates session)
      await user.delete();

      debugPrint('DataDeletionService: All data deleted successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('DataDeletionService: Auth error - ${e.code}: ${e.message}');
      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate before deleting account
        rethrow;
      }
      return false;
    } catch (e) {
      debugPrint('DataDeletionService: Error deleting data - $e');
      return false;
    }
  }

  /// Delete all Firestore data for the user from flat collections.
  Future<void> _deleteFirestoreUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Flat collections that store user data (with userId field)
    final flatCollections = [
      'users', // Main user document
      'rainfall_records', // Rainfall data
      'user_backups', // Cloud backup metadata
      'user_backup_chunks', // Cloud backup chunks (if chunked)
    ];

    // Delete documents from each flat collection where userId == uid
    for (final collectionName in flatCollections) {
      if (collectionName == 'users') {
        // Main users collection - delete by document ID (uid)
        await firestore.collection(collectionName).doc(uid).delete();
      } else {
        // Other collections - query by userId field
        await _deleteDocumentsByUserId(
          firestore.collection(collectionName),
          uid,
        );
      }
    }

    debugPrint('DataDeletionService: Firestore data deleted for uid=$uid');
  }

  /// Delete all documents in a collection where userId matches.
  Future<void> _deleteDocumentsByUserId(
    CollectionReference collection,
    String userId,
  ) async {
    const batchSize = 100;

    QuerySnapshot snapshot;
    do {
      snapshot = await collection
          .where('userId', isEqualTo: userId)
          .limit(batchSize)
          .get();

      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchSize);
  }

  /// Clear all registered Hive boxes.
  Future<void> _clearAllLocalData() async {
    for (final boxName in _hiveBoxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          debugPrint('DataDeletionService: Cleared Hive box "$boxName"');
        }
      } catch (e) {
        debugPrint('DataDeletionService: Error clearing box "$boxName": $e');
        // Continue clearing other boxes
      }
    }
  }

  /// Check if user needs to re-authenticate before deletion.
  /// Firebase requires recent login for sensitive operations.
  bool requiresRecentLogin(FirebaseAuthException e) {
    return e.code == 'requires-recent-login';
  }
}
