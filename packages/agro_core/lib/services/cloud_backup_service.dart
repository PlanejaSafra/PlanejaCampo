import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

/// Metadata about a cloud backup.
class CloudBackupMetadata {
  final DateTime? updated;
  final int appCount;
  final int chunkCount;

  CloudBackupMetadata({
    required this.updated,
    required this.appCount,
    this.chunkCount = 1,
  });

  factory CloudBackupMetadata.fromMap(Map<String, dynamic> map) {
    DateTime? timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    }
    return CloudBackupMetadata(
      updated: timestamp,
      appCount: map['appCount'] as int? ?? 0,
      chunkCount: map['chunkCount'] as int? ?? 1,
    );
  }
}

/// Service that manages cloud backups for all PlanejaCampo apps.
/// Stores backup data in Firestore (free tier) instead of Firebase Storage.
/// Supports chunking for backups larger than 900KB (leaving margin for 1MB limit).
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService _instance = CloudBackupService._();
  static CloudBackupService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<BackupProvider> _providers = [];

  /// Collection path for user backups
  static const String _backupsCollection = 'user_backups';

  /// Maximum size per chunk (900KB to leave margin for Firestore's 1MB limit)
  static const int _maxChunkSize = 900 * 1024;

  /// Register a provider (app) to participate in backup.
  void registerProvider(BackupProvider provider) {
    // Avoid duplicates
    if (!_providers.any((p) => p.key == provider.key)) {
      _providers.add(provider);
    }
  }

  /// Perform a full backup of all registered apps.
  /// Returns the document ID of the backup or null if failed.
  /// Automatically chunks data if it exceeds 900KB.
  Future<String?> backupAll() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    if (user.isAnonymous) {
      throw Exception('Backup indisponível para contas anônimas');
    }

    final appsData = <String, dynamic>{};

    // Collect data from all providers
    for (final provider in _providers) {
      try {
        final data = await provider.getData();
        appsData[provider.key] = data;
      } catch (e) {
        debugPrint('Erro ao obter dados para backup de ${provider.key}: $e');
        // Continue backing up other apps even if one fails
      }
    }

    try {
      final userDocRef =
          _firestore.collection(_backupsCollection).doc(user.uid);

      // Check size of full backup
      final jsonString = jsonEncode(appsData);
      final dataSize = utf8.encode(jsonString).length;

      if (dataSize <= _maxChunkSize) {
        // Single document backup (most common case)
        await _deleteExistingChunks(userDocRef);

        await userDocRef.set({
          'userId': user.uid,
          'version': 1,
          'timestamp': FieldValue.serverTimestamp(),
          'appCount': _providers.length,
          'chunkCount': 1,
          'apps': appsData,
        });

        debugPrint('Backup salvo (${(dataSize / 1024).toStringAsFixed(1)}KB)');
      } else {
        // Need to chunk the data
        await _saveChunkedBackup(userDocRef, appsData);
      }

      return user.uid;
    } catch (e) {
      debugPrint('Erro ao salvar backup no Firestore: $e');
      rethrow;
    }
  }

  /// Delete existing chunk documents
  Future<void> _deleteExistingChunks(DocumentReference userDocRef) async {
    final chunksSnapshot = await userDocRef.collection('chunks').get();
    for (final doc in chunksSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Save backup in multiple chunks
  Future<void> _saveChunkedBackup(
    DocumentReference userDocRef,
    Map<String, dynamic> appsData,
  ) async {
    // Delete any existing chunks first
    await _deleteExistingChunks(userDocRef);

    // Split apps into chunks
    final chunks = <Map<String, dynamic>>[];
    var currentChunk = <String, dynamic>{};
    var currentChunkSize = 0;

    for (final entry in appsData.entries) {
      final entryJson = jsonEncode({entry.key: entry.value});
      final entrySize = utf8.encode(entryJson).length;

      if (currentChunkSize + entrySize > _maxChunkSize &&
          currentChunk.isNotEmpty) {
        // Save current chunk and start new one
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
    // Extract userId from the document reference path
    final userId = userDocRef.id;
    await userDocRef.set({
      'userId': userId,
      'version': 1,
      'timestamp': FieldValue.serverTimestamp(),
      'appCount': _providers.length,
      'chunkCount': chunks.length,
      'chunked': true,
    });

    // Save each chunk as a subcollection document
    for (var i = 0; i < chunks.length; i++) {
      await userDocRef.collection('chunks').doc('chunk_$i').set({
        'index': i,
        'apps': chunks[i],
      });
    }

    debugPrint('Backup salvo em ${chunks.length} chunks');
  }

  /// Restore data from cloud backup.
  Future<void> restoreAll() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    try {
      final userDocRef =
          _firestore.collection(_backupsCollection).doc(user.uid);
      final snapshot = await userDocRef.get();

      if (!snapshot.exists) {
        throw Exception('Nenhum backup encontrado na nuvem.');
      }

      final backupData = snapshot.data()!;
      Map<String, dynamic> appsData;

      if (backupData['chunked'] == true) {
        // Load chunked backup
        appsData = await _loadChunkedBackup(
            userDocRef, backupData['chunkCount'] as int);
      } else {
        // Single document backup
        appsData = backupData['apps'] as Map<String, dynamic>? ?? {};
      }

      // Restore for each registered provider
      for (final provider in _providers) {
        if (appsData.containsKey(provider.key)) {
          try {
            await provider
                .restoreData(appsData[provider.key] as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar dados de ${provider.key}: $e');
            // Continue restoring others
          }
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('Erro do Firebase ao restaurar: ${e.code} - ${e.message}');
      if (e.code == 'not-found') {
        throw Exception('Nenhum backup encontrado na nuvem.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Load chunked backup from subcollection
  Future<Map<String, dynamic>> _loadChunkedBackup(
    DocumentReference userDocRef,
    int chunkCount,
  ) async {
    final appsData = <String, dynamic>{};

    for (var i = 0; i < chunkCount; i++) {
      final chunkDoc =
          await userDocRef.collection('chunks').doc('chunk_$i').get();
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
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final docRef = _firestore.collection(_backupsCollection).doc(user.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      return CloudBackupMetadata.fromMap(snapshot.data()!);
    } catch (e) {
      debugPrint('Erro ao obter metadados do backup: $e');
      return null;
    }
  }

  /// Delete the cloud backup for the current user.
  Future<void> deleteBackup() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    try {
      final userDocRef =
          _firestore.collection(_backupsCollection).doc(user.uid);

      // Delete chunks first
      await _deleteExistingChunks(userDocRef);

      // Delete main document
      await userDocRef.delete();
    } catch (e) {
      debugPrint('Erro ao deletar backup: $e');
      rethrow;
    }
  }
}
