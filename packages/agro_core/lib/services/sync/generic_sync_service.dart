import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sync_models.dart';
import 'sync_config.dart';
import 'local_cache_manager.dart';
import 'offline_queue_manager.dart';
import 'data_integrity_manager.dart';
import 'tier2_pipeline.dart';
import '../farm_service.dart';

/// Classe base para serviços com suporte a offline-first e sincronização.
///
/// T deve implementar [SyncableEntity] ou ser compatível com os métodos abstratos.
///
/// Funcionalidades:
/// - CRUD local (Hive) — Tier 1
/// - Tier 2: Anonymous aggregate upload (consent-gated, rate-limited)
/// - Tier 3: Full data sync with Firestore (farm.isShared gated)
/// - Fila de operações offline
/// - Resolução de conflitos
/// - Cache com validação de integridade
///
/// Data Tier Architecture (CORE-88/95):
/// - Tier 1: Local only (default). No cloud sync.
/// - Tier 2: Anonymized aggregate data (opt-in via [tier2Enabled]).
///   Consent-gated via [AgroPrivacyStore.consentAggregateMetrics],
///   rate-limited, exponential backoff retry.
/// - Tier 3: Full cloud sync (opt-in via [syncEnabled]).
///   Gated by [Farm.isShared] (multi-user license).
abstract class GenericSyncService<T> extends ChangeNotifier {
  // --- Configurações Abstratas ---

  /// Nome do Box no Hive (deve ser único)
  String get boxName;

  /// Se deve sincronizar com Firestore (Tier 3: full data sync)
  bool get syncEnabled => false;

  /// Nome da coleção no Firestore (default: boxName).
  /// MUST be a flat root collection — subcollections are FORBIDDEN.
  String get firestoreCollection => boxName;

  /// Tag para logs e metadados
  String get sourceApp;

  // --- Tier 2 Configuration (CORE-95) ---

  /// Whether Tier 2 (anonymous aggregate) sync is enabled.
  /// Override to `true` in subclasses that upload anonymized data.
  bool get tier2Enabled => false;

  /// Build anonymized Tier 2 data for an item.
  /// Return null if this item should not be queued for Tier 2
  /// (e.g., missing location data, no property assigned).
  ///
  /// The returned [Tier2UploadItem.data] must contain only
  /// Hive-serializable types (String, int, double, bool, DateTime,
  /// List, Map). DateTime values are automatically converted to
  /// Firestore Timestamps at upload time.
  ///
  /// Override in subclasses that enable Tier 2.
  Tier2UploadItem? buildTier2Data(T item) => null;

  /// Prepare Tier 2 data for Firestore upload (called at sync time).
  /// Default: converts DateTime → Firestore Timestamp, adds `uploaded_at`.
  /// Override for custom type conversions.
  Map<String, dynamic> prepareTier2ForUpload(Map<String, dynamic> data) {
    final upload = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is DateTime) {
        upload[entry.key] = Timestamp.fromDate(entry.value as DateTime);
      } else {
        upload[entry.key] = entry.value;
      }
    }
    upload['uploaded_at'] = FieldValue.serverTimestamp();
    return upload;
  }

  // --- Métodos de Serialização Abstratos ---

  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getId(T item);

  // --- Estado Interno ---

  Box<dynamic>? _box; // Box é dinâmico internamente, convertido para T na saída
  bool _initialized = false;
  final Map<String, Timer?> _debounceTimers = {};
  bool _isSyncing = false;
  Tier2Pipeline? _tier2Pipeline;

  /// Inicializa o serviço (abre box)
  @mustCallSuper
  Future<void> init() async {
    if (_initialized) return;

    // Inicializa dependências
    await LocalCacheManager.instance.init();
    if (syncEnabled) {
      await OfflineQueueManager.instance.init();
    }

    // Abre box local
    _box = await LocalCacheManager.instance.openBox(boxName);

    // Constrói índices em memória
    _buildIndices();

    // Subcollection detection guard (CORE-95)
    if (syncEnabled && firestoreCollection.contains('/')) {
      debugPrint('[GenericSyncService] ERROR: Subcollection detected in '
          'firestoreCollection "$firestoreCollection" for service "$boxName". '
          'RULE VIOLATION: Use flat root collections only!');
    }

    // Initialize Tier 2 pipeline (CORE-95)
    if (tier2Enabled) {
      _tier2Pipeline = Tier2Pipeline(
        serviceName: boxName,
        dataConverter: prepareTier2ForUpload,
      );
      await _tier2Pipeline!.init();
      debugPrint('[GenericSyncService] Tier 2 pipeline initialized '
          'for "$boxName"');
    }

    _initialized = true;
  }

  /// Dispose resources (Tier 2 pipeline timer, debounce timers).
  @override
  void dispose() {
    _tier2Pipeline?.dispose();
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
    super.dispose();
  }

  // --- Indexação em Memória (Otimização) ---
  final Map<String, Set<String>> _farmIdIndex = {}; // farmId -> Set<itemId>

  void _buildIndices() {
    _farmIdIndex.clear();
    if (_box == null) return;

    for (var key in _box!.keys) {
      final item = _box!.get(key);
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final farmId = map['farmId'] as String?;
        if (farmId != null) {
          _farmIdIndex.putIfAbsent(farmId, () => {}).add(key.toString());
        }
      }
    }
  }

  void _updateIndices(String id, T item, {bool isDelete = false}) {
    // Remove do índice antigo (se necessário) - simplificado: reconstrói ou varre
    // Para performance real em updates frequentes, precisaríamos saber o estado anterior
    // Como simplificação para MVP: Add/Update apenas adiciona. Delete remove.
    // O ideal seria: GenericSyncService guardar estado prévio ou passar oldItem no update.

    final map = toMap(item);
    final farmId = map['farmId'] as String?;

    if (isDelete) {
      // Remove de todos os índices (caro se não souber o farmId anterior)
      // Iteração em _farmIdIndex é melhor que no Box inteiro
      _farmIdIndex.forEach((key, set) => set.remove(id));
    } else {
      if (farmId != null) {
        _farmIdIndex.putIfAbsent(farmId, () => {}).add(id);
      }
    }
  }

  // --- CRUD ---

  /// Retorna todos os itens locais
  List<T> getAll() {
    if (!_initialized || _box == null) return [];

    // Filtra e converte, ignorando se falhar cast
    return _box!.values
        .map((e) {
          try {
            final map = Map<String, dynamic>.from(e as Map);
            return fromMap(map);
          } catch (e) {
            debugPrint('Error parsing item in $boxName: $e');
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  /// Busca item por ID e agenda sync background se necessário
  T? getById(String id) {
    if (!_initialized) return null;

    final data = _box!.get(id);
    if (data == null) return null;

    try {
      final map = Map<String, dynamic>.from(data as Map);

      // Agenda sync se online e habilitado
      if (syncEnabled) {
        scheduleSyncInBackground(id);
      }

      return fromMap(map);
    } catch (e) {
      debugPrint('Error getting item $id in $boxName: $e');
      return null;
    }
  }

  /// Adiciona novo item
  Future<void> add(T item) async {
    await _save(item, isNew: true);
    _updateIndices(getId(item), item, isDelete: false);
  }

  /// Atualiza item existente
  Future<void> update(String id, T item) async {
    // Garante que ID bate
    if (getId(item) != id) {
      throw ArgumentError('Item ID mismatch');
    }
    await _save(item, isNew: false);
    _updateIndices(id, item, isDelete: false);
  }

  /// Remove item
  Future<void> delete(String id) async {
    if (!_initialized) await init();

    // 0. Remove do índice (antes de perder os dados, idealmente, mas aqui simplificado)
    // Como não temos o item antigo facilmente aqui sem ler do box...
    // Vamos ler antes de deletar para limpar o índice corretamente?
    // Ou usar a varredura "cara" do _updateIndices(isDelete: true).

    // Melhor approach para MVP: varrer índice é rápido pois é em memória
    _updateIndices(id, (null as T), isDelete: true);

    // 1. Remove local
    await _box!.delete(id);
    notifyListeners();

    // 2. Sync / Queue (Tier 3: only if farm is in shared/multi-user mode)
    if (_shouldSyncToCloud()) {
      try {
        // Tenta deletar no server se online (otimista)
        // Implementação simplificada: Põe na fila sempre para garantir ordem
        final op = OfflineOperation.create(
          collection: firestoreCollection,
          operationType: OperationType.delete,
          docId: id,
          priority: OperationPriority.critical,
          sourceApp: sourceApp,
        );

        await OfflineQueueManager.instance.addToQueue(op);
      } catch (e) {
        debugPrint('Error queuing delete for $id: $e');
      }
    }
  }

  /// Limpa tudo (Cuidado!)
  Future<void> clearAll() async {
    if (!_initialized) await init();
    await _box!.clear();
    notifyListeners();
  }

  // --- Lógica Interna de Save ---

  Future<void> _save(T item, {required bool isNew}) async {
    if (!_initialized) await init();

    final id = getId(item);
    final data = toMap(item);

    // 1. Adiciona metadados
    final dataWithMeta = DataIntegrityManager.addFullMetadata(
      data,
      sourceApp: sourceApp,
      status: SyncStatus.pending,
    );

    // 2. Salva local (UI update imediato)
    await _box!.put(id, dataWithMeta);
    notifyListeners();

    // 3. Sync / Queue (non-fatal: local save already succeeded)
    // Tier 3: only queue for cloud sync if farm is in shared/multi-user mode
    if (_shouldSyncToCloud()) {
      try {
        // Cria versão para upload com marker de timestamp do servidor
        final uploadData = Map<String, dynamic>.from(dataWithMeta);
        final meta = Map<String, dynamic>.from(uploadData['_metadata']);

        // O servidor vai colocar a hora real aqui
        meta['lastSyncAt'] = kServerTimestampMarker;
        uploadData['_metadata'] = meta;

        final op = OfflineOperation.create(
          collection: firestoreCollection,
          operationType: isNew ? OperationType.create : OperationType.update,
          docId: id,
          data: uploadData,
          priority: isNew ? OperationPriority.high : OperationPriority.medium,
          sourceApp: sourceApp,
        );

        await OfflineQueueManager.instance.addToQueue(op);
      } catch (e) {
        debugPrint('[GenericSyncService] Queue operation failed (non-fatal): $e');
      }
    }

    // 4. Tier 2: Queue for anonymous aggregate upload (CORE-95)
    if (tier2Enabled && _tier2Pipeline != null) {
      try {
        final tier2Data = buildTier2Data(item);
        if (tier2Data != null) {
          if (isNew) {
            await _tier2Pipeline!.queue(tier2Data);
          } else {
            await _tier2Pipeline!.reQueue(tier2Data);
          }
          // Fire-and-forget sync attempt
          _tier2Pipeline!.syncPending().then((result) {
            if (result.itemsSynced > 0) {
              debugPrint('[GenericSyncService/$boxName] '
                  'Tier 2 synced ${result.itemsSynced} items');
            }
          }).catchError((e) {
            debugPrint('[GenericSyncService/$boxName] '
                'Tier 2 sync failed (non-fatal): $e');
          });
        }
      } catch (e) {
        debugPrint('[GenericSyncService/$boxName] '
            'Tier 2 queue failed (non-fatal): $e');
      }
    }
  }

  // --- Sincronização ---

  /// Agenda sync de um item específico (debounce)
  void scheduleSyncInBackground(String id) {
    if (_debounceTimers[id]?.isActive ?? false) return;

    _debounceTimers[id] = Timer(SyncConfig.instance.syncDebounce, () {
      _debounceTimers.remove(id);
      syncWithServer(id);
    });
  }

  /// Sincroniza um único documento com o servidor (Data Integrity Check)
  Future<void> syncWithServer(String id) async {
    if (!syncEnabled || _isSyncing) return;

    try {
      // 1. Busca Local
      final localRaw = _box!.get(id);
      if (localRaw == null)
        return; // Se não tem local, ignora (ou deveria buscar do server?)

      final localMap = Map<String, dynamic>.from(localRaw as Map);

      // 2. Busca Remoto
      final docRef =
          FirebaseFirestore.instance.collection(firestoreCollection).doc(id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // Se existe local mas não remoto e status é synced, foi deletado no server -> deleta local
        final meta = SyncMetadata.fromMap(localMap['_metadata'] ?? {});
        if (meta.syncStatus == SyncStatus.synced) {
          await _box!.delete(id);
          notifyListeners();
        }
        return;
      }

      final serverMap = docSnap.data()!;

      // 3. Verifica Conflito
      if (DataIntegrityManager.hasConflict(localMap, serverMap)) {
        final resolved = DataIntegrityManager.resolveConflict(
            localMap, serverMap, SyncConfig.instance.conflictStrategy);

        await _box!.put(id, resolved);
        notifyListeners();
      } else {
        // Se servidor é mais novo, atualiza local
        final serverMeta = SyncMetadata.fromMap(serverMap['_metadata'] ?? {});
        final localMeta = SyncMetadata.fromMap(localMap['_metadata'] ?? {});

        if (serverMeta.version > localMeta.version) {
          await _box!.put(id, serverMap);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing item $id: $e');
    }
  }

  /// Sincroniza todos os itens (Delta Sync)
  /// Deve ser chamado periodicamente ou no app start
  Future<void> syncAllWithServer({Map<String, dynamic>? filters}) async {
    if (!syncEnabled || _isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Pega timestamp do último sync bem sucedido
      final lastSync = LocalCacheManager.instance.getLastSyncTimestamp(boxName);

      Query query = FirebaseFirestore.instance.collection(firestoreCollection);

      // 2. Aplica filtro de Delta (se tiver lastSync)
      if (lastSync != null) {
        // Assume que os docs têm campo '_metadata.lastSyncAt' ou 'updatedAt' ou similar indexado
        // Como _metadata é map, firestore indexa _metadata.lastSyncAt
        query = query.where('_metadata.lastSyncAt',
            isGreaterThan: lastSync.toIso8601String());
      }

      // Aplica filtros adicionais
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }

      final snapshot = await query.get();

      // 3. Processa updates
      for (var doc in snapshot.docs) {
        final serverData = doc.data() as Map<String, dynamic>;
        await _box!.put(doc.id, serverData);
      }

      if (snapshot.docs.isNotEmpty) {
        notifyListeners();
      }

      // 4. Atualiza timestamp
      await LocalCacheManager.instance
          .setLastSyncTimestamp(boxName, DateTime.now());
    } catch (e) {
      debugPrint('Error syncing collection $boxName: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // --- Tier 3 Gate ---

  /// Determines whether data should be synced to Firestore.
  ///
  /// Data Tier Architecture — Tier 3 (Full Data Sync):
  /// Only syncs when BOTH conditions are met:
  /// 1. The subclass has `syncEnabled = true` (service-level opt-in)
  /// 2. The active farm has `isShared = true` (multi-user license activated)
  ///
  /// This ensures that GenericSyncService NEVER sends data to Firestore
  /// unless the farm owner has explicitly activated multi-user collaboration
  /// through a license purchase.
  ///
  /// See also: [Farm.isShared], [FarmService.isActiveFarmShared]
  bool _shouldSyncToCloud() {
    if (!syncEnabled) return false;
    return FarmService.instance.isActiveFarmShared();
  }

  // --- Helpers e Queries Locais ---

  /// Busca por ID da fazenda (assumindo que T tem farmId ou metadata)
  /// Caso T não tenha farmId direto, deve ser sobrescrito ou usado getByAttributes
  ///
  /// OTIMIZAÇÃO (CORE-78): Usa índice em memória se disponível.
  List<T> getByFarmId(String farmId) {
    // 1. Tenta usar índice (O(1))
    if (_farmIdIndex.containsKey(farmId)) {
      final ids = _farmIdIndex[farmId]!;
      return LocalCacheManager.instance
          .readManyFromCache<T>(boxName, ids.toList());
    }

    // 2. Fallback para varredura completa (O(N)) caso índice falhe ou esteja vazio
    // (Isso acontece se _buildIndices não achou farmId nos itens)
    return getAll().where((item) {
      final map = toMap(item);
      if (map['farmId'] == farmId) return true;
      return false;
    }).toList();
  }

  /// Query local genérica
  List<T> getByAttributes(Map<String, dynamic> filters) {
    return getAll().where((item) {
      final map = toMap(item);
      for (final entry in filters.entries) {
        if (map[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }
}
