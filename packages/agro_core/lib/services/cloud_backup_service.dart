import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/backup_meta.dart';
import '../models/restore_analysis.dart';
import 'auth_service.dart';

/// Interface for apps to provide their data for backup.
abstract class BackupProvider {
  /// Unique key for the app (e.g., 'planeja_chuva').
  String get key;

  /// Returns the data to be backed up as a JSON-encodable Map.
  Future<Map<String, dynamic>> getData();

  /// Restores data from the provided JSON Map.
  Future<void> restoreData(Map<String, dynamic> data);
}

/// Enhanced backup provider with dependency-aware 3-phase restore.
///
/// Apps implement this instead of [BackupProvider] to get:
/// - **Phase 1 (Analysis)**: Examine backup data, produce [RestoreAnalysis]
/// - **Phase 2 (Confirmation)**: User reviews the analysis via dialog
/// - **Phase 3 (Execution)**: Apply approved changes + recalculate
///
/// For backwards compatibility, [restoreData] calls all 3 phases
/// automatically (skipping user confirmation). Use [CloudBackupService]'s
/// [prepareRestore] + [executeRestoreSession] for the full 3-phase flow.
///
/// See CORE-77 for full architecture.
abstract class EnhancedBackupProvider extends BackupProvider {
  /// App identifier (e.g., "rurarubber", "rurarain")
  String get appId;

  /// Schema version for migration compatibility checks
  int get schemaVersion => 1;

  /// Build [BackupMeta] describing this provider's current state.
  /// Included in the backup data for restore-time validation.
  BackupMeta buildMeta();

  /// Phase 1: Analyze backup data without modifying anything.
  ///
  /// Returns a [RestoreAnalysis] describing what will happen:
  /// - Entities to add (in backup, not local)
  /// - Entities to delete (local, not in backup, same sourceApp)
  /// - Blocked deletions (cross-app dependencies)
  /// - Conflicts (different data in both)
  /// - Warnings and recalculation needs
  Future<RestoreAnalysis> analyzeRestore(Map<String, dynamic> data);

  /// Phase 3: Execute the restore after user confirmation.
  ///
  /// Only modifies data as described in [analysis].
  /// Blocked items are skipped. Conflicts use backup version.
  Future<void> executeRestore(
    Map<String, dynamic> data,
    RestoreAnalysis analysis,
  );

  /// Phase 3b: Recalculate derived data after restore.
  ///
  /// Each app implements its own recalculation logic
  /// (e.g., partner balances, production totals).
  /// Returns [RecalculationResult.empty] if nothing to recalculate.
  Future<RecalculationResult> recalculateAfterRestore() async {
    return RecalculationResult.empty();
  }

  /// Backwards-compatible restore: runs all 3 phases automatically.
  ///
  /// Used by the existing [CloudBackupService.restoreFromSlot] flow.
  /// For the full 3-phase flow with user confirmation, use
  /// [CloudBackupService.prepareRestore] + [executeRestoreSession].
  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    final analysis = await analyzeRestore(data);
    await executeRestore(data, analysis);
    await recalculateAfterRestore();
  }
}

/// Metadata about a cloud backup.
class CloudBackupMetadata {
  final DateTime? updated;
  final int appCount;
  final int chunkCount;
  final int slotIndex; // Sorted order (0 = newest)
  final int firestoreSlot; // Actual slot in Firestore (0, 1, or 2)
  final String? backupId; // Document ID in Firestore

  CloudBackupMetadata({
    required this.updated,
    required this.appCount,
    this.chunkCount = 1,
    this.slotIndex = 0,
    this.firestoreSlot = 0,
    this.backupId,
  });

  factory CloudBackupMetadata.fromMap(Map<String, dynamic> map,
      [int index = 0]) {
    DateTime? timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    }
    return CloudBackupMetadata(
      updated: timestamp,
      appCount: map['appCount'] as int? ?? 0,
      chunkCount: map['chunkCount'] as int? ?? 1,
      slotIndex: index,
      firestoreSlot: map['slot'] as int? ?? 0,
      backupId: map['backupId'] as String?,
    );
  }
}

/// Holds the state of a pending restore operation (3-phase flow).
///
/// Created by [CloudBackupService.prepareRestore] during Phase 1.
/// Passed to [CloudBackupService.executeRestoreSession] after user
/// confirms via [RestoreConfirmationDialog].
///
/// See CORE-77 Section 5 for full architecture.
class RestoreSession {
  /// The raw backup data loaded from cloud/local storage
  final Map<String, dynamic> appsData;

  /// Analysis results per provider key
  final Map<String, RestoreAnalysis> analyses;

  /// Providers that support enhanced restore (have analysis)
  final List<EnhancedBackupProvider> enhancedProviders;

  /// Providers that only support basic restore (no analysis)
  final List<BackupProvider> basicProviders;

  /// The backup slot this session was loaded from
  final int slotIndex;

  RestoreSession({
    required this.appsData,
    required this.analyses,
    required this.enhancedProviders,
    required this.basicProviders,
    required this.slotIndex,
  });

  /// Whether any provider has blocked deletions
  bool get hasBlocked => analyses.values.any((a) => a.hasBlocked);

  /// Whether any provider has warnings
  bool get hasWarnings => analyses.values.any((a) => a.hasWarnings);

  /// Total entities to add across all providers
  int get totalAdds =>
      analyses.values.fold(0, (total, a) => total + a.addCount);

  /// Total entities to delete across all providers
  int get totalDeletes =>
      analyses.values.fold(0, (total, a) => total + a.deleteCount);

  /// Total blocked deletions across all providers
  int get totalBlocked =>
      analyses.values.fold(0, (total, a) => total + a.blockedCount);
}

/// Service that manages cloud backups for all PlanejaCampo apps.
/// Stores backup data in Firestore (free tier) using flat collections.
/// Supports up to 3 backup slots with automatic rotation.
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService _instance = CloudBackupService._();
  static CloudBackupService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<BackupProvider> _providers = [];

  /// Collection for backup metadata
  static const String _backupsCollection = 'user_backups';

  /// Separate collection for backup chunks (flat, not subcollection)
  static const String _chunksCollection = 'user_backup_chunks';

  /// Maximum size per chunk (900KB to leave margin for Firestore's 1MB limit)
  static const int _maxChunkSize = 900 * 1024;

  /// Maximum number of backup slots to keep
  static const int _maxBackupSlots = 3;

  /// Local cache box name
  static const String _cacheBoxName = 'backup_cache';
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _currentSlotKey = 'current_backup_slot';
  static const String _backupListKey = 'backup_list';
  static const String _backupListTimeKey = 'backup_list_time';
  static const String _pendingBackupPrefix = 'pending_backup_';

  /// Check if there are pending backups to sync
  Future<void> syncPendingBackups() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final keys = box.keys.where((k) => k.toString().startsWith(_pendingBackupPrefix)).toList();

      if (keys.isEmpty) return;

      debugPrint('[CloudBackup] Found ${keys.length} pending backups to sync');

      for (final key in keys) {
        final pendingData = box.get(key) as Map?;
        if (pendingData == null) continue;

        final docId = pendingData['docId'] as String?;
        final backupData = pendingData['data'] as Map?;
        if (docId == null || backupData == null) {
          await box.delete(key);
          continue;
        }

        try {
          await _firestore
              .collection(_backupsCollection)
              .doc(docId)
              .set(Map<String, dynamic>.from(backupData))
              .timeout(const Duration(seconds: 15));

          await box.delete(key);
          debugPrint('[CloudBackup] Synced pending backup: $docId');
        } catch (e) {
          debugPrint('[CloudBackup] Failed to sync pending backup $docId: $e');
          // Keep for next retry
        }
      }
    } catch (e) {
      debugPrint('[CloudBackup] syncPendingBackups error: $e');
    }
  }

  /// Save backup data locally for retry if Firestore fails
  Future<void> _savePendingBackup(String docId, Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.put('$_pendingBackupPrefix$docId', {
        'docId': docId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('[CloudBackup] Saved pending backup locally: $docId');
    } catch (e) {
      debugPrint('[CloudBackup] Failed to save pending backup: $e');
    }
  }

  /// Remove pending backup after successful sync
  Future<void> _removePendingBackup(String docId) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.delete('$_pendingBackupPrefix$docId');
    } catch (_) {}
  }

  /// Cache the last backup timestamp locally for instant UI display
  Future<void> cacheLastBackupTime(DateTime timestamp) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.put(_lastBackupKey, timestamp.toIso8601String());
    } catch (e) {
      debugPrint('[CloudBackup] Cache write error: $e');
    }
  }

  /// Get cached last backup timestamp (instant, no network)
  Future<DateTime?> getCachedLastBackupTime() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final cached = box.get(_lastBackupKey) as String?;
      if (cached != null) {
        return DateTime.parse(cached);
      }
    } catch (e) {
      debugPrint('[CloudBackup] Cache read error: $e');
    }
    return null;
  }

  /// Cache backup list for instant restore after backup
  Future<void> _cacheBackupList(List<CloudBackupMetadata> backups) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final list = backups
          .map((b) => {
                'updated': b.updated?.toIso8601String(),
                'appCount': b.appCount,
                'chunkCount': b.chunkCount,
                'slotIndex': b.slotIndex,
                'firestoreSlot': b.firestoreSlot,
                'backupId': b.backupId,
              })
          .toList();
      await box.put(_backupListKey, list);
      await box.put(_backupListTimeKey, DateTime.now().toIso8601String());
      debugPrint('[CloudBackup] Cached ${backups.length} backups to Hive');
    } catch (e) {
      debugPrint('[CloudBackup] Cache backup list error: $e');
    }
  }

  /// Get cached backup list (returns null if cache is stale or empty)
  /// Use [ignoreExpiration] to get cache even if expired (for merging)
  Future<List<CloudBackupMetadata>?> _getCachedBackupList({bool ignoreExpiration = false}) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final cacheTimeStr = box.get(_backupListTimeKey) as String?;
      if (cacheTimeStr == null) return null;

      if (!ignoreExpiration) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        // Cache valid for 30 seconds after backup
        if (DateTime.now().difference(cacheTime).inSeconds > 30) {
          debugPrint('[CloudBackup] Backup list cache expired');
          return null;
        }
      }

      final list = box.get(_backupListKey) as List?;
      if (list == null || list.isEmpty) return null;

      final backups = list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return CloudBackupMetadata(
          updated: map['updated'] != null
              ? DateTime.parse(map['updated'] as String)
              : null,
          appCount: map['appCount'] as int? ?? 0,
          chunkCount: map['chunkCount'] as int? ?? 1,
          slotIndex: map['slotIndex'] as int? ?? 0,
          firestoreSlot: map['firestoreSlot'] as int? ?? 0,
          backupId: map['backupId'] as String?,
        );
      }).toList();

      debugPrint('[CloudBackup] Using cached backup list (${backups.length} items, ignoreExpiration=$ignoreExpiration)');
      return backups;
    } catch (e) {
      debugPrint('[CloudBackup] Get cached backup list error: $e');
      return null;
    }
  }

  /// Get next slot index - simple round-robin using local Hive only
  /// No Firestore reads needed - fast and reliable
  Future<int> _getNextSlot(String userId) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final current = box.get(_currentSlotKey) as int? ?? -1;
      final next = (current + 1) % _maxBackupSlots;
      await box.put(_currentSlotKey, next);
      debugPrint('[CloudBackup] Using slot $next (round-robin)');
      return next;
    } catch (e) {
      debugPrint('[CloudBackup] Error getting next slot: $e');
      return 0;
    }
  }

  /// Generate deterministic backup document ID for a slot
  String _getBackupDocId(String userId, int slot) {
    return '${userId}_slot_$slot';
  }

  /// Register a provider (app) to participate in backup.
  void registerProvider(BackupProvider provider) {
    // Avoid duplicates
    if (!_providers.any((p) => p.key == provider.key)) {
      _providers.add(provider);
    }
  }

  /// Minimum interval between automatic backups (24 hours)
  static const Duration _autoBackupInterval = Duration(hours: 24);

  /// Try to perform auto backup periodically.
  /// Only backs up if:
  /// - autoBackupEnabled is true
  /// - User is logged in (not anonymous)
  /// - User has cloud backup consent
  /// - Last backup was more than 24 hours ago
  /// Returns true if backup was performed, false otherwise.
  Future<bool> tryAutoBackup({
    required bool autoBackupEnabled,
    required bool hasCloudBackupConsent,
  }) async {
    // Always try to sync pending backups first
    await syncPendingBackups();

    if (!autoBackupEnabled) {
      debugPrint('[AutoBackup] Disabled');
      return false;
    }

    if (!hasCloudBackupConsent) {
      debugPrint('[AutoBackup] No cloud backup consent');
      return false;
    }

    final user = AuthService.currentUser;
    if (user == null || user.isAnonymous) {
      debugPrint('[AutoBackup] User not logged in or anonymous');
      return false;
    }

    try {
      // Check if enough time has passed since last backup
      final backups = await listAvailableBackups();
      if (backups.isNotEmpty) {
        final mostRecent = backups.first;
        if (mostRecent.updated != null) {
          final timeSinceLastBackup =
              DateTime.now().difference(mostRecent.updated!);
          if (timeSinceLastBackup < _autoBackupInterval) {
            debugPrint(
                '[AutoBackup] Skipped - last backup was ${timeSinceLastBackup.inHours}h ago');
            return false;
          }
        }
      }

      debugPrint('[AutoBackup] Starting automatic backup...');
      await backupAll();
      debugPrint('[AutoBackup] Backup completed successfully');
      return true;
    } catch (e) {
      debugPrint('[AutoBackup] Backup failed: $e');
      return false;
    }
  }

  /// List all available backups for current user, sorted by date (newest first).
  /// Includes local pending backups that haven't synced yet.
  Future<List<CloudBackupMetadata>> listAvailableBackups() async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[CloudBackup] listAvailableBackups: no user');
      return [];
    }

    // Check Hive cache first (valid for 30s after backup)
    final cached = await _getCachedBackupList();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // Load pending local backups (not yet synced to cloud)
    final pendingBackups = <int, CloudBackupMetadata>{};
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final pendingKeys = box.keys
          .where((k) => k.toString().startsWith(_pendingBackupPrefix))
          .toList();

      for (final key in pendingKeys) {
        final data = box.get(key) as Map?;
        if (data == null) continue;

        final backupData = data['data'] as Map?;
        final docId = data['docId'] as String?;
        if (backupData == null || docId == null) continue;

        final timestampStr = backupData['timestamp'] as String?;
        final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) : null;
        final firestoreSlot = backupData['slot'] as int? ?? 0;

        pendingBackups[firestoreSlot] = CloudBackupMetadata(
          updated: timestamp,
          appCount: backupData['appCount'] as int? ?? 0,
          chunkCount: 1,
          slotIndex: 0,
          firestoreSlot: firestoreSlot,
          backupId: docId,
        );
      }

      if (pendingBackups.isNotEmpty) {
        debugPrint('[CloudBackup] Found ${pendingBackups.length} local pending backups');
      }
    } catch (e) {
      debugPrint('[CloudBackup] Error reading local backups: $e');
    }

    debugPrint('[CloudBackup] Listing available backups for ${user.uid}...');
    try {
      // Query without orderBy to avoid requiring composite index
      // Sort in memory instead (max 3 backups per user, so this is efficient)
      debugPrint('[CloudBackup] Starting Firestore query...');
      // Use default source (cache + server) - Firestore handles cache invalidation
      final snapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: user.uid)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('[CloudBackup] listAvailableBackups timeout after 15s');
              throw Exception('Tempo esgotado. Verifique sua conexão.');
            },
          );

      debugPrint('[CloudBackup] Query completed, found ${snapshot.docs.length} docs');

      // Build map of slot -> backup metadata
      // Start with Firestore data, then override with pending local backups
      final slotMap = <int, CloudBackupMetadata>{};

      // Add Firestore backups
      for (final doc in snapshot.docs) {
        final data = doc.data();
        DateTime? timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        }
        final firestoreSlot = data['slot'] as int? ?? 0;
        slotMap[firestoreSlot] = CloudBackupMetadata(
          updated: timestamp,
          appCount: data['appCount'] as int? ?? 0,
          chunkCount: data['chunkCount'] as int? ?? 1,
          slotIndex: 0,
          firestoreSlot: firestoreSlot,
          backupId: doc.id,
        );
      }

      // Override with pending local backups (they're newer)
      for (final entry in pendingBackups.entries) {
        slotMap[entry.key] = entry.value;
        debugPrint('[CloudBackup] Slot ${entry.key} using local pending backup');
      }

      // Convert to list and sort by timestamp descending (newest first)
      final backups = slotMap.values.toList();
      backups.sort((a, b) {
        if (a.updated == null && b.updated == null) return 0;
        if (a.updated == null) return 1;
        if (b.updated == null) return -1;
        return b.updated!.compareTo(a.updated!);
      });

      debugPrint('[CloudBackup] Returning ${backups.length} backups (${pendingBackups.length} pending)');

      // Update slot indices after sorting
      final result = backups.asMap().entries.map((entry) {
        return CloudBackupMetadata(
          updated: entry.value.updated,
          appCount: entry.value.appCount,
          chunkCount: entry.value.chunkCount,
          slotIndex: entry.key,
          firestoreSlot: entry.value.firestoreSlot,
          backupId: entry.value.backupId,
        );
      }).take(_maxBackupSlots).toList();

      // Cache the result for subsequent calls
      await _cacheBackupList(result);

      return result;
    } catch (e) {
      debugPrint('[CloudBackup] listAvailableBackups error: $e');

      // If Firestore fails but we have pending local backups, return those
      if (pendingBackups.isNotEmpty) {
        debugPrint('[CloudBackup] Firestore failed, returning ${pendingBackups.length} local backups');
        final backups = pendingBackups.values.toList();
        backups.sort((a, b) {
          if (a.updated == null && b.updated == null) return 0;
          if (a.updated == null) return 1;
          if (b.updated == null) return -1;
          return b.updated!.compareTo(a.updated!);
        });
        return backups.asMap().entries.map((entry) {
          return CloudBackupMetadata(
            updated: entry.value.updated,
            appCount: entry.value.appCount,
            chunkCount: entry.value.chunkCount,
            slotIndex: entry.key,
            firestoreSlot: entry.value.firestoreSlot,
            backupId: entry.value.backupId,
          );
        }).toList();
      }

      rethrow;
    }
  }

  /// Perform a full backup of all registered apps.
  /// Creates a new backup slot, removing oldest if at max capacity.
  /// Returns metadata about the created backup (or null on failure).
  Future<CloudBackupMetadata?> backupAll() async {
    debugPrint('[CloudBackup] backupAll() started');
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    if (user.isAnonymous) {
      throw Exception('Backup indisponível para contas anônimas');
    }

    debugPrint('[CloudBackup] Collecting data from ${_providers.length} providers...');
    final appsData = <String, dynamic>{};

    // Collect data from all providers
    for (final provider in _providers) {
      try {
        debugPrint('[CloudBackup] Getting data from ${provider.key}...');
        final data = await provider.getData();
        appsData[provider.key] = data;
        debugPrint('[CloudBackup] Got data from ${provider.key}');
      } catch (e) {
        debugPrint('Erro ao obter dados para backup de ${provider.key}: $e');
      }
    }

    try {
      // Use slot-based approach - no queries needed!
      // Round-robin through slots 0, 1, 2 (overwrites oldest automatically)
      final slot = await _getNextSlot(user.uid);
      final newBackupId = _getBackupDocId(user.uid, slot);
      debugPrint('[CloudBackup] Using slot $slot, doc ID: $newBackupId');

      final backupDocRef =
          _firestore.collection(_backupsCollection).doc(newBackupId);

      // Check size of full backup
      final jsonString = jsonEncode(appsData);
      final dataSize = utf8.encode(jsonString).length;
      debugPrint('[CloudBackup] Data size: ${(dataSize / 1024).toStringAsFixed(1)}KB');

      if (dataSize <= _maxChunkSize) {
        debugPrint('[CloudBackup] Saving single document backup...');
        // Single document backup (most common case)
        final backupData = {
          'userId': user.uid,
          'backupId': newBackupId,
          'slot': slot,
          'version': 1,
          'timestamp': FieldValue.serverTimestamp(),
          'appCount': _providers.length,
          'chunkCount': 1,
          'chunked': false,
          'apps': appsData,
        };

        // LOCAL FIRST: Save to Hive immediately (guaranteed success)
        // This data is used for restore if cloud sync fails
        final localBackupData = Map<String, dynamic>.from(backupData);
        localBackupData['timestamp'] = DateTime.now().toIso8601String(); // Local timestamp
        await _savePendingBackup(newBackupId, localBackupData);
        debugPrint('[CloudBackup] Backup saved locally (${(dataSize / 1024).toStringAsFixed(1)}KB)');

        // CLOUD SYNC: Try in background, don't block
        backupDocRef.set(backupData).then((_) async {
          await _removePendingBackup(newBackupId);
          debugPrint('[CloudBackup] Backup synced to cloud');
        }).catchError((e) {
          debugPrint('[CloudBackup] Cloud sync failed (saved locally): $e');
        });
      } else {
        // Need to chunk the data
        debugPrint('[CloudBackup] Data too large, saving in chunks...');
        await _saveChunkedBackup(user.uid, newBackupId, slot, appsData);
      }

      debugPrint('[CloudBackup] backupAll() completed successfully');

      // Cache timestamp locally for instant UI display
      final now = DateTime.now();
      await cacheLastBackupTime(now);

      // Build cache from what we know (no Firestore query needed)
      // Get existing cache (ignore expiration) and update with new backup
      try {
        final existingCache = await _getCachedBackupList(ignoreExpiration: true) ?? [];

        // Create new backup entry
        final newBackup = CloudBackupMetadata(
          updated: now,
          appCount: _providers.length,
          chunkCount: 1,
          slotIndex: 0, // Will be reindexed
          firestoreSlot: slot,
          backupId: newBackupId,
        );

        // Remove any existing entry for this slot, add new one
        final updatedList = existingCache
            .where((b) => b.firestoreSlot != slot)
            .toList();
        updatedList.insert(0, newBackup);

        // Sort by timestamp descending (newest first)
        updatedList.sort((a, b) {
          if (a.updated == null && b.updated == null) return 0;
          if (a.updated == null) return 1;
          if (b.updated == null) return -1;
          return b.updated!.compareTo(a.updated!);
        });

        // Re-index and limit to max slots
        final sortedBackups = updatedList.asMap().entries.map((entry) {
          return CloudBackupMetadata(
            updated: entry.value.updated,
            appCount: entry.value.appCount,
            chunkCount: entry.value.chunkCount,
            slotIndex: entry.key,
            firestoreSlot: entry.value.firestoreSlot,
            backupId: entry.value.backupId,
          );
        }).take(_maxBackupSlots).toList();

        await _cacheBackupList(sortedBackups);
      } catch (e) {
        debugPrint('[CloudBackup] Could not cache backup list: $e');
      }

      // Return metadata directly without another query
      return CloudBackupMetadata(
        updated: now,
        appCount: _providers.length,
        chunkCount: 1,
        slotIndex: 0,
      );
    } catch (e) {
      debugPrint('[CloudBackup] Erro ao salvar backup no Firestore: $e');
      rethrow;
    }
  }

  /// Delete a backup document and its chunks
  Future<void> _deleteBackupDoc(String backupDocId) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // Delete chunks first (must include userId in query for Firestore rules)
    final chunksSnapshot = await _firestore
        .collection(_chunksCollection)
        .where('userId', isEqualTo: user.uid)
        .where('backupId', isEqualTo: backupDocId)
        .get();

    for (final doc in chunksSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete main document
    await _firestore.collection(_backupsCollection).doc(backupDocId).delete();
  }

  /// Save backup in multiple chunks using flat collection
  Future<void> _saveChunkedBackup(
    String userId,
    String backupId,
    int slot,
    Map<String, dynamic> appsData,
  ) async {
    // First, delete any old chunks for this slot
    try {
      final oldChunks = await _firestore
          .collection(_chunksCollection)
          .where('userId', isEqualTo: userId)
          .where('backupId', isEqualTo: backupId)
          .get()
          .timeout(const Duration(seconds: 10));
      for (final doc in oldChunks.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('[CloudBackup] Could not delete old chunks: $e');
      // Continue anyway - old chunks will be orphaned but not cause issues
    }
    // Split apps into chunks
    final chunks = <Map<String, dynamic>>[];
    var currentChunk = <String, dynamic>{};
    var currentChunkSize = 0;

    for (final entry in appsData.entries) {
      final entryJson = jsonEncode({entry.key: entry.value});
      final entrySize = utf8.encode(entryJson).length;

      if (currentChunkSize + entrySize > _maxChunkSize &&
          currentChunk.isNotEmpty) {
        chunks.add(currentChunk);
        currentChunk = <String, dynamic>{};
        currentChunkSize = 0;
      }

      currentChunk[entry.key] = entry.value;
      currentChunkSize += entrySize;
    }

    // Add last chunk
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    // Save metadata document
    final backupDocRef =
        _firestore.collection(_backupsCollection).doc(backupId);
    await backupDocRef.set({
      'userId': userId,
      'backupId': backupId,
      'slot': slot,
      'version': 1,
      'timestamp': FieldValue.serverTimestamp(),
      'appCount': _providers.length,
      'chunkCount': chunks.length,
      'chunked': true,
    });

    // Save each chunk
    for (var i = 0; i < chunks.length; i++) {
      final chunkDocId = '${backupId}_chunk_$i';
      await _firestore.collection(_chunksCollection).doc(chunkDocId).set({
        'userId': userId,
        'backupId': backupId,
        'index': i,
        'apps': chunks[i],
      });
    }

    debugPrint('Backup salvo em ${chunks.length} chunks');
  }

  /// Load backup apps data from a specific slot.
  ///
  /// Handles local Hive cache, Firestore cache, and server fallback.
  /// Also handles chunked backups transparently.
  Future<Map<String, dynamic>> _loadBackupData(int slotIndex) async {
    final backups = await listAvailableBackups();
    if (backups.isEmpty) {
      throw BackupNotFoundException();
    }

    if (slotIndex >= backups.length) {
      throw BackupSlotInvalidException();
    }

    final user = AuthService.currentUser;
    if (user == null) {
      throw BackupUserNotLoggedInException();
    }

    final selectedBackup = backups[slotIndex];
    final backupId = selectedBackup.backupId;

    debugPrint('[CloudBackup] _loadBackupData: slotIndex=$slotIndex, backupId=$backupId');

    final docId = backupId ?? _getBackupDocId(user.uid, selectedBackup.firestoreSlot);
    debugPrint('[CloudBackup] Reading backup by ID: $docId');

    Map<String, dynamic>? backupData;

    // LOCAL FIRST: Check Hive for pending backup (not yet synced to cloud)
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final pendingData = box.get('$_pendingBackupPrefix$docId') as Map?;
      if (pendingData != null && pendingData['data'] != null) {
        backupData = Map<String, dynamic>.from(pendingData['data'] as Map);
        debugPrint('[CloudBackup] Using local pending backup');
      }
    } catch (e) {
      debugPrint('[CloudBackup] Hive read error: $e');
    }

    // If no local data, try Firestore cache, then server
    if (backupData == null) {
      DocumentSnapshot<Map<String, dynamic>>? backupDoc;

      try {
        backupDoc = await _firestore
            .collection(_backupsCollection)
            .doc(docId)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(seconds: 2));

        if (backupDoc.exists) {
          debugPrint('[CloudBackup] Found backup in Firestore cache');
          backupData = backupDoc.data();
        }
      } catch (_) {
        // Cache miss - try server
      }

      if (backupData == null) {
        debugPrint('[CloudBackup] Trying server...');
        backupDoc = await _firestore
            .collection(_backupsCollection)
            .doc(docId)
            .get()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw BackupTimeoutException();
              },
            );

        if (backupDoc.exists) {
          backupData = backupDoc.data();
        }
      }
    }

    if (backupData == null) {
      throw BackupNotFoundException();
    }

    final actualBackupId = backupData['backupId'] as String? ?? docId;

    if (backupData['chunked'] == true) {
      return await _loadChunkedBackup(
        actualBackupId,
        backupData['chunkCount'] as int,
      );
    } else {
      return backupData['apps'] as Map<String, dynamic>? ?? {};
    }
  }

  /// Phase 1: Prepare a restore by loading and analyzing backup data.
  ///
  /// Returns a [RestoreSession] containing:
  /// - Loaded backup data
  /// - [RestoreAnalysis] for each [EnhancedBackupProvider]
  /// - Separated lists of enhanced vs basic providers
  ///
  /// Show the session's analyses to the user via RestoreConfirmationDialog,
  /// then call [executeRestoreSession] to apply.
  ///
  /// Basic [BackupProvider]s are included but have no analysis
  /// (they restore directly during [executeRestoreSession]).
  Future<RestoreSession> prepareRestore([int slotIndex = 0]) async {
    final appsData = await _loadBackupData(slotIndex);

    final analyses = <String, RestoreAnalysis>{};
    final enhanced = <EnhancedBackupProvider>[];
    final basic = <BackupProvider>[];

    for (final provider in _providers) {
      if (provider is EnhancedBackupProvider &&
          appsData.containsKey(provider.key)) {
        enhanced.add(provider);
        try {
          final analysis = await provider.analyzeRestore(
            appsData[provider.key] as Map<String, dynamic>,
          );
          analyses[provider.key] = analysis;
        } catch (e) {
          debugPrint('[CloudBackup] Analysis failed for ${provider.key}: $e');
          // Create empty analysis so restore can still proceed
          analyses[provider.key] = RestoreAnalysis(
            meta: provider.buildMeta(),
            warnings: ['Analysis failed: $e'],
          );
        }
      } else {
        basic.add(provider);
      }
    }

    return RestoreSession(
      appsData: appsData,
      analyses: analyses,
      enhancedProviders: enhanced,
      basicProviders: basic,
      slotIndex: slotIndex,
    );
  }

  /// Phase 3: Execute a prepared restore after user confirmation.
  ///
  /// Call this after showing RestoreConfirmationDialog with the session.
  /// - [EnhancedBackupProvider]s use [executeRestore] + [recalculateAfterRestore]
  /// - Basic [BackupProvider]s use [restoreData] directly
  Future<Map<String, RecalculationResult>> executeRestoreSession(
    RestoreSession session,
  ) async {
    final results = <String, RecalculationResult>{};

    // Execute enhanced providers (with analysis)
    for (final provider in session.enhancedProviders) {
      if (!session.appsData.containsKey(provider.key)) continue;

      final analysis = session.analyses[provider.key];
      if (analysis == null) continue;

      try {
        await provider.executeRestore(
          session.appsData[provider.key] as Map<String, dynamic>,
          analysis,
        );
        final recalc = await provider.recalculateAfterRestore();
        results[provider.key] = recalc;
      } catch (e) {
        debugPrint('[CloudBackup] Restore failed for ${provider.key}: $e');
        results[provider.key] = RecalculationResult(
          success: false,
          details: ['Restore failed: $e'],
        );
      }
    }

    // Execute basic providers (no analysis)
    for (final provider in session.basicProviders) {
      if (!session.appsData.containsKey(provider.key)) continue;
      try {
        await provider.restoreData(
          session.appsData[provider.key] as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('[CloudBackup] Restore failed for ${provider.key}: $e');
      }
    }

    debugPrint('[CloudBackup] Restore session completed');
    return results;
  }

  /// Restore data from a specific backup slot (0 = most recent).
  ///
  /// This is the legacy restore flow that restores all providers directly.
  /// For the 3-phase flow with user confirmation, use
  /// [prepareRestore] + [executeRestoreSession].
  Future<void> restoreFromSlot([int slotIndex = 0]) async {
    try {
      final appsData = await _loadBackupData(slotIndex);

      debugPrint('[CloudBackup] Restoring data for ${_providers.length} providers...');

      // Restore for each registered provider
      for (final provider in _providers) {
        if (appsData.containsKey(provider.key)) {
          try {
            await provider
                .restoreData(appsData[provider.key] as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar dados de ${provider.key}: $e');
          }
        }
      }

      debugPrint('[CloudBackup] Restore completed');
    } on FirebaseException catch (e) {
      debugPrint('Erro do Firebase ao restaurar: ${e.code} - ${e.message}');
      if (e.code == 'not-found') {
        throw BackupNotFoundException();
      }
      rethrow;
    }
  }

  /// Restore data from cloud backup (most recent).
  Future<void> restoreAll() async {
    await restoreFromSlot(0);
  }

  /// Load chunked backup from flat chunks collection
  Future<Map<String, dynamic>> _loadChunkedBackup(
    String backupId,
    int chunkCount,
  ) async {
    final appsData = <String, dynamic>{};

    for (var i = 0; i < chunkCount; i++) {
      final chunkDocId = '${backupId}_chunk_$i';
      final chunkDoc =
          await _firestore.collection(_chunksCollection).doc(chunkDocId).get();

      if (chunkDoc.exists) {
        final chunkApps = chunkDoc.data()?['apps'] as Map<String, dynamic>?;
        if (chunkApps != null) {
          appsData.addAll(chunkApps);
        }
      }
    }

    return appsData;
  }

  /// Get metadata of the last backup (timestamp, etc).
  Future<CloudBackupMetadata?> getLastBackupMetadata() async {
    final backups = await listAvailableBackups();
    return backups.isNotEmpty ? backups.first : null;
  }

  /// Delete the cloud backup for the current user (all slots).
  Future<void> deleteBackup() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    try {
      final snapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        await _deleteBackupDoc(doc.id);
      }
    } catch (e) {
      debugPrint('Erro ao deletar backup: $e');
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Typed exceptions for backup operations.
//
// Frontend maps these to l10n strings (no hardcoded user-visible messages).
// ---------------------------------------------------------------------------

/// Thrown when no backup is found in cloud storage.
class BackupNotFoundException implements Exception {
  @override
  String toString() => 'BackupNotFoundException';
}

/// Thrown when the requested backup slot index is invalid.
class BackupSlotInvalidException implements Exception {
  @override
  String toString() => 'BackupSlotInvalidException';
}

/// Thrown when the user is not logged in during a backup operation.
class BackupUserNotLoggedInException implements Exception {
  @override
  String toString() => 'BackupUserNotLoggedInException';
}

/// Thrown when a backup operation times out.
class BackupTimeoutException implements Exception {
  @override
  String toString() => 'BackupTimeoutException';
}

/// Thrown when backup is unavailable for anonymous accounts.
class BackupAnonymousException implements Exception {
  @override
  String toString() => 'BackupAnonymousException';
}
