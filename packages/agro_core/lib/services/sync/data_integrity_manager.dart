import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'sync_models.dart';
import 'sync_config.dart';

/// Gerenciador de integridade de dados
/// Responsável por cálculo de hash e resolução de conflitos
class DataIntegrityManager {
  /// Calcula o hash SHA256 dos dados para controle de integridade
  /// Remove metadados internos antes do cálculo
  static String computeHash(Map<String, dynamic> data) {
    // Clone para não modificar original
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('_metadata'); // Remove metadados do sync

    // Ordena chaves para garantir determinismo
    final sortedKeys = cleanData.keys.toList()..sort();
    final sortedMap = {for (var key in sortedKeys) key: cleanData[key]};

    final jsonString = jsonEncode(sortedMap);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Verifica se os dados batem com o hash armazenado
  static bool validateDataIntegrity(Map<String, dynamic> data) {
    if (!data.containsKey('_metadata'))
      return true; // Sem metadata, assume válido (legado)

    final metadataMap = data['_metadata'] as Map<String, dynamic>;
    final metadata = SyncMetadata.fromMap(metadataMap);

    if (metadata.hash == null) return true;

    final currentHash = computeHash(data);
    return currentHash == metadata.hash;
  }

  /// Adiciona ou atualiza metadados nos dados
  static Map<String, dynamic> addFullMetadata(
    Map<String, dynamic> data, {
    String? sourceApp,
    String? deviceId,
    SyncStatus status = SyncStatus.pending,
  }) {
    final newData = Map<String, dynamic>.from(data);

    // Recupera metadata existente ou cria nova
    SyncMetadata metadata;
    if (newData.containsKey('_metadata')) {
      metadata = SyncMetadata.fromMap(newData['_metadata']);
    } else {
      metadata = SyncMetadata.create(sourceApp: sourceApp, deviceId: deviceId);
    }

    // Calcula novo hash
    final newHash = computeHash(data);

    // Atualiza metadata
    final updatedMetadata = metadata.copyWithUpdate(
      hash: newHash,
      syncStatus: status,
      sourceApp: sourceApp,
      deviceId: deviceId,
      lastSyncAt: DateTime.now(),
    );

    newData['_metadata'] = updatedMetadata.toMap();
    return newData;
  }

  /// Detecta se há conflito entre dados locais e remotos
  static bool hasConflict(
      Map<String, dynamic> localData, Map<String, dynamic> serverData) {
    if (!localData.containsKey('_metadata') ||
        !serverData.containsKey('_metadata')) {
      return false; // Sem metadata, servidor vence (sem conflito lógico)
    }

    final localMeta = SyncMetadata.fromMap(localData['_metadata']);
    final serverMeta = SyncMetadata.fromMap(serverData['_metadata']);

    // Se hash é igual, não tem conflito (são idênticos)
    if (localMeta.hash == serverMeta.hash) return false;

    // Se versão local > servidor, é um update pendente (não é conflito)
    if (localMeta.version > serverMeta.version) return false;

    // Se servidor > local E local tem alterações não syncadas (status pending), é conflito
    if (serverMeta.version > localMeta.version &&
        localMeta.syncStatus == SyncStatus.pending) {
      return true;
    }

    return false;
  }

  /// Resolve conflito baseado na estratégia configurada
  static Map<String, dynamic> resolveConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictStrategy.serverWins:
        return serverData;

      case ConflictStrategy.localWins:
        // Mantém local, mas atualiza versão para garantir que sobrescreva servidor no próximo sync
        final localMeta = SyncMetadata.fromMap(localData['_metadata']);
        final serverMeta = SyncMetadata.fromMap(serverData['_metadata']);

        // Incrementa versão local para ser maior que servidor
        localData['_metadata']['version'] = serverMeta.version + 1;
        return localData;

      case ConflictStrategy.merge:
        // Merge raso: chaves novas do servidor entram, chaves locais mantêm
        // Idealmente seria merge profundo ou campo a campo baseado em timestamp
        final merged = Map<String, dynamic>.from(serverData);
        merged.addAll(localData);

        // Recalcula hash e update version
        return addFullMetadata(merged,
            sourceApp: localData['_metadata']['lastModifiedBy'],
            status: SyncStatus.pending);

      // Manual removed (CORE-78)
    }
  }
}
