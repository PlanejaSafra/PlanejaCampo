import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sync_models.g.dart';

const String kServerTimestampMarker = '___SERVER_TIMESTAMP___';

/// Status da sincronização de um documento
enum SyncStatus {
  pending, // Aguardando sync
  syncing, // Em processo de sync
  synced, // Sincronizado com sucesso
  failed, // Falhou (vai retentar)
  conflict // Conflito detectado
}

/// Prioridade da operação de sincronização
@HiveType(typeId: 31)
enum OperationPriority {
  @HiveField(0)
  critical, // Deletes (ex: apagar conta)
  @HiveField(1)
  high, // Creates (ex: novo registro)
  @HiveField(2)
  medium, // Updates (ex: editar registro)
  @HiveField(3)
  low // Reads/Syncs (ex: background sync)
}

/// Tipo da operação de sincronização
@HiveType(typeId: 32)
enum OperationType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete
}

/// Representa uma operação offline que precisa ser sincronizada
@HiveType(typeId: 33)
class OfflineOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String collection;

  @HiveField(2)
  final OperationType operationType;

  @HiveField(3)
  final String docId;

  @HiveField(4)
  final Map<String, dynamic>? data;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final OperationPriority priority;

  @HiveField(7)
  int retryCount;

  @HiveField(8)
  String? lastError;

  @HiveField(9)
  final String? sourceApp;

  @HiveField(10)
  final String? farmId;

  OfflineOperation({
    required this.id,
    required this.collection,
    required this.operationType,
    required this.docId,
    this.data,
    required this.timestamp,
    required this.priority,
    this.retryCount = 0,
    this.lastError,
    this.sourceApp,
    this.farmId,
  });

  factory OfflineOperation.create({
    required String collection,
    required OperationType operationType,
    required String docId,
    Map<String, dynamic>? data,
    OperationPriority priority = OperationPriority.medium,
    String? sourceApp,
    String? farmId,
  }) {
    return OfflineOperation(
      id: const Uuid().v4(),
      collection: collection,
      operationType: operationType,
      docId: docId,
      data: data,
      timestamp: DateTime.now(),
      priority: priority,
      sourceApp: sourceApp,
      farmId: farmId,
    );
  }

  void recordFailure(String error) {
    retryCount++;
    lastError = error;
    // Não precisa chamar save() aqui pois o queue manager gerencia isso
  }

  bool get hasExceededRetries => retryCount >= 5;

  /// Comparação para ordenação na fila:
  /// 1. Prioridade (critical < high < medium < low) - enum index ordena assim
  /// 2. Timestamp (mais antigo primeiro)
  int compareTo(OfflineOperation other) {
    final priorityInfo = priority.index.compareTo(other.priority.index);
    if (priorityInfo != 0) return priorityInfo;

    return timestamp.compareTo(other.timestamp);
  }
}

/// Metadados de sincronização anexados a cada documento
class SyncMetadata {
  final int version;
  final String? hash;
  final DateTime? lastSyncAt;
  final SyncStatus syncStatus;
  final String? lastModifiedBy; // sourceApp
  final String? lastModifiedDevice;

  SyncMetadata({
    required this.version,
    this.hash,
    this.lastSyncAt,
    this.syncStatus = SyncStatus.pending,
    this.lastModifiedBy,
    this.lastModifiedDevice,
  });

  factory SyncMetadata.create({String? sourceApp, String? deviceId}) {
    return SyncMetadata(
      version: 1,
      syncStatus: SyncStatus.pending,
      lastModifiedBy: sourceApp,
      lastModifiedDevice: deviceId,
    );
  }

  SyncMetadata copyWithUpdate({
    String? hash,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? sourceApp,
    String? deviceId,
  }) {
    return SyncMetadata(
      version: version + 1,
      hash: hash ?? this.hash,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastModifiedBy: sourceApp ?? lastModifiedBy,
      lastModifiedDevice: deviceId ?? lastModifiedDevice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'hash': hash,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDevice': lastModifiedDevice,
    };
  }

  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      version: map['version'] as int? ?? 1,
      hash: map['hash'] as String?,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.tryParse(map['lastSyncAt'] as String)
          : null,
      syncStatus: map['syncStatus'] != null
          ? SyncStatus.values.firstWhere(
              (e) => e.name == map['syncStatus'],
              orElse: () => SyncStatus.pending,
            )
          : SyncStatus.pending,
      lastModifiedBy: map['lastModifiedBy'] as String?,
      lastModifiedDevice: map['lastModifiedDevice'] as String?,
    );
  }
}

/// Resultado de uma operação de sincronização
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final int conflictCount;
  final String? error;
  final DateTime completedAt;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.error,
    required this.completedAt,
  });

  factory SyncResult.success({int count = 1}) {
    return SyncResult(
      success: true,
      syncedCount: count,
      completedAt: DateTime.now(),
    );
  }

  factory SyncResult.failure(String error) {
    return SyncResult(
      success: false,
      failedCount: 1,
      error: error,
      completedAt: DateTime.now(),
    );
  }
}

/// Interface para entidades sincronizáveis
abstract class SyncableEntity {
  String get id;
  DateTime? get updatedAt;
  Map<String, dynamic> toMap();
}
