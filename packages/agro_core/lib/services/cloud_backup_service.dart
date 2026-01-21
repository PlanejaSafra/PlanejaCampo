import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
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

/// Service that manages cloud backups for all PlanejaCampo apps.
/// Stores a single 'backup.json' file in Firebase Storage for the user.
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService _instance = CloudBackupService._();
  static CloudBackupService get instance => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final List<BackupProvider> _providers = [];

  /// Register a provider (app) to participate in backup.
  void registerProvider(BackupProvider provider) {
    // Avoid duplicates
    if (!_providers.any((p) => p.key == provider.key)) {
      _providers.add(provider);
    }
  }

  /// Perform a full backup of all registered apps.
  /// Returns URL of the uploaded file or null if failed.
  Future<String?> backupAll() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    if (user.isAnonymous) {
      throw Exception('Backup indisponível para contas anônimas');
    }

    final backupData = <String, dynamic>{
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'apps': {},
    };

    // Collect data from all providers
    for (final provider in _providers) {
      try {
        final data = await provider.getData();
        backupData['apps'][provider.key] = data;
      } catch (e) {
        debugPrint('Erro ao obter dados de cleanup para ${provider.key}: $e');
        // Continue backing up other apps even if one fails
      }
    }

    // Convert to JSON
    final jsonString = jsonEncode(backupData);
    final data = Uint8List.fromList(utf8.encode(jsonString));

    // Upload to Firebase Storage
    final ref = _storage.ref().child('users/${user.uid}/backup.json');

    final metadata = SettableMetadata(
      contentType: 'application/json',
      customMetadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'app_count': _providers.length.toString(),
      },
    );

    try {
      await ref.putData(data, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro no upload para Firebase Storage: $e');
      rethrow;
    }
  }

  /// Restore data from cloud backup.
  /// [force] : Not used yet, could be for overwriting local conflicts.
  Future<void> restoreAll() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Usuário não logado');
    }

    final ref = _storage.ref().child('users/${user.uid}/backup.json');

    try {
      // Download data (max 10MB)
      final data = await ref.getData(10 * 1024 * 1024);
      if (data == null) {
        throw Exception('Nenhum backup encontrado');
      }

      final jsonString = utf8.decode(data);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final appsData = backupData['apps'] as Map<String, dynamic>?;
      if (appsData == null) return;

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
      if (e.code == 'object-not-found') {
        throw Exception('Nenhum backup encontrado na nuvem.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Get metadata of the last backup (timestamp, etc).
  Future<FullMetadata?> getLastBackupMetadata() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final ref = _storage.ref().child('users/${user.uid}/backup.json');
    try {
      return await ref.getMetadata();
    } catch (e) {
      return null;
    }
  }
}
