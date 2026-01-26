import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/lgpd_deletion_result.dart';
import '../privacy/agro_privacy_store.dart';
import 'dependency_service.dart';

/// Interface for app-specific LGPD deletion logic.
///
/// Each app implements this to provide granular deletion capabilities:
/// - Delete only data created by this app (sourceApp matching)
/// - Respect cross-app dependencies via [DependencyService]
/// - Support ownership-based deletion (farm owner vs member)
///
/// See CORE-77 Section 9 and Section 16 for architecture.
abstract class AppDeletionProvider {
  /// App identifier (e.g., "rurarubber", "rurarain")
  String get appId;

  /// Delete all data created by this app for a specific farm.
  ///
  /// Only deletes entities where `sourceApp == appId`.
  /// Checks [DependencyService] before deleting — skips protected entities.
  ///
  /// [farmId]: The farm whose data to delete.
  /// [userId]: The user requesting deletion (for ownership verification).
  /// [isOwner]: Whether the user is the farm owner (full LGPD rights).
  Future<LgpdDeletionResult> deleteAppData({
    required String farmId,
    required String userId,
    required bool isOwner,
  });

  /// Delete only personal data (non-owner LGPD request).
  ///
  /// A non-owner (e.g., gerente, sangrador) can only request deletion
  /// of their personal data, NOT the farm data they created.
  /// The `createdBy` audit trail remains (it belongs to the farm owner).
  ///
  /// Returns what was deleted and what was retained.
  Future<LgpdDeletionResult> deletePersonalData({
    required String userId,
  });
}

/// Service for LGPD-compliant data deletion (Art. 18, VI - Right to Erasure).
///
/// Supports two deletion modes:
/// - **Full deletion** ([deleteAllUserData]): Deletes everything
///   (account + all data). Used when user deletes their account.
/// - **App-specific deletion** ([deleteAppDataForFarm]): Deletes only
///   one app's data, respecting cross-app dependencies.
/// - **Personal data only** ([deletePersonalDataOnly]): For non-owners
///   exercising LGPD rights without affecting farm data.
///
/// See CORE-77 Section 9 and Section 16 for ownership rules.
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

  /// Registered app-specific deletion providers
  final List<AppDeletionProvider> _deletionProviders = [];

  /// Register additional Hive box for deletion (app-specific boxes).
  void registerHiveBox(String boxName) {
    if (!_hiveBoxNames.contains(boxName)) {
      _hiveBoxNames.add(boxName);
    }
  }

  /// Register an app-specific deletion provider.
  void registerDeletionProvider(AppDeletionProvider provider) {
    if (!_deletionProviders.any((p) => p.appId == provider.appId)) {
      _deletionProviders.add(provider);
    }
  }

  /// Delete data for a specific app in a specific farm.
  ///
  /// Only deletes entities where `sourceApp == appId`.
  /// Respects cross-app dependencies (skips protected entities).
  ///
  /// [appId]: The app whose data to delete.
  /// [farmId]: The farm whose data to delete.
  /// [userId]: The user requesting deletion.
  /// [isOwner]: Whether the user is the farm owner.
  Future<LgpdDeletionResult> deleteAppDataForFarm({
    required String appId,
    required String farmId,
    required String userId,
    required bool isOwner,
  }) async {
    final provider = _deletionProviders
        .cast<AppDeletionProvider?>()
        .firstWhere((p) => p?.appId == appId, orElse: () => null);

    if (provider == null) {
      debugPrint('DataDeletionService: No provider registered for $appId');
      return const LgpdDeletionResult(
        success: false,
        errors: ['No deletion provider registered for app'],
      );
    }

    try {
      final result = await provider.deleteAppData(
        farmId: farmId,
        userId: userId,
        isOwner: isOwner,
      );

      // Clean up dependency manifest for this app
      if (DependencyService.instance.isInitialized) {
        DependencyService.instance.removeAllReferencesForApp(appId);
      }

      debugPrint('DataDeletionService: App deletion for $appId: $result');
      return result;
    } catch (e) {
      debugPrint('DataDeletionService: Error deleting app data for $appId: $e');
      return LgpdDeletionResult(
        success: false,
        errors: ['Deletion failed: $e'],
      );
    }
  }

  /// Delete only personal data for a non-owner user.
  ///
  /// LGPD allows any user to request deletion of their personal data.
  /// For non-owners:
  /// - Deletes personal profile/preferences
  /// - Does NOT delete farm data they created (audit trail belongs to owner)
  /// - Does NOT delete the `createdBy` field (owner's audit trail)
  ///
  /// See CORE-77 Section 16 for ownership rules.
  Future<LgpdDeletionResult> deletePersonalDataOnly({
    required String userId,
  }) async {
    final results = <LgpdDeletionResult>[];

    for (final provider in _deletionProviders) {
      try {
        final result = await provider.deletePersonalData(userId: userId);
        results.add(result);
      } catch (e) {
        debugPrint(
          'DataDeletionService: Error in personal deletion for '
          '${provider.appId}: $e',
        );
        results.add(LgpdDeletionResult(
          success: false,
          errors: ['${provider.appId}: $e'],
        ));
      }
    }

    return LgpdDeletionResult.merge(results);
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

      // 4. Clear dependency manifests
      if (DependencyService.instance.isInitialized) {
        for (final provider in _deletionProviders) {
          DependencyService.instance
              .removeAllReferencesForApp(provider.appId);
        }
      }

      // 5. Reset privacy store
      await AgroPrivacyStore.resetAll();

      // 6. Delete Firebase Auth account (must be last - invalidates session)
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
