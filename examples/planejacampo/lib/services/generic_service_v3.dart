import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';
import 'package:planejacampo/models/system/document_metadata.dart';
import 'package:planejacampo/services/system/data_integrity_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejacampo/utils/collection_options.dart';
import 'package:mutex/mutex.dart';

abstract class GenericService<T> {
  final AppStateManager _appStateManager = AppStateManager();
  static const Duration _defaultTimeoutOnlineWrite = Duration(seconds: 30);
  static const Duration _defaultTimeoutOnlineRead = Duration(seconds: 20);
  static const Duration _defaultTimeoutOfflineWrite = Duration(seconds: 5);
  static const Duration _defaultTimeoutOfflineRead = Duration(seconds: 3);
  String get baseCollection;

  T fromMap(Map<String, dynamic> map, String documentId);
  Map<String, dynamic> toMap(T item);

  static const int _pageSize = 20;
  DocumentSnapshot? _lastFetchedDocument;
  bool _needsReset = true;
  bool _isSyncing = false;
  DateTime? _lastCall = DateTime(2000);
  static final Map<String, DateTime> _globalLastCall = {};
  static final Map<String, Future<List<dynamic>>> _pendingGets = {};
  static final Map<String, Mutex> _mutexes = {}; // Mutex por coleção

  String get collectionPath => baseCollection;

  CollectionReference<Map<String, dynamic>> getCollectionReference() {
    return FirebaseService.firestore.collection(collectionPath);
  }

  DocumentReference<Map<String, dynamic>> getDocumentReference(String id) {
    return getCollectionReference().doc(id);
  }

  DocumentReference<Map<String, dynamic>> getNewDocumentReference() {
    return getCollectionReference().doc();
  }

  Future<T> _executeWithTimeout<T>(
      Future<T> Function() operation, [
        Duration? timeout,
        String timeoutMessage = 'Operação excedeu o timeout',
      ]) async {
    if (timeout == null || timeout == Duration.zero) {
      return await operation();
    } else {
      return await Future.any([
        operation(),
        Future.delayed(timeout, () => throw TimeoutException(timeoutMessage)),
      ]);
    }
  }

  void _handleOperationError(dynamic e, String operation) {
    if (e is TimeoutException) {
      print('Timeout ao tentar $operation item: $e');
    } else {
      print('Erro ao $operation item: $e');
    }
  }

  Future<void> _syncWithServer(String id) async {
    if (!_appStateManager.isOnline) return;
    try {
      await OfflineQueueManager.processQueue();
      final doc = await getCollectionReference().doc(id).get();
      if (doc.exists && doc.data() != null) {
        var data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        if (!DataIntegrityManager.hasValidHash(data)) {
          print('Dados do servidor sem hash válido para ID $id, adicionando metadata');
          data = await DataIntegrityManager.addFullMetadata(data);
          await getCollectionReference().doc(id).set(data, SetOptions(merge: true));
        }
        await LocalCacheManager.updateCache(baseCollection, id, data);
        print('Cache atualizado com sucesso para ID $id');
      } else {
        await LocalCacheManager.removeFromCache(baseCollection, id);
        print('Documento $id não encontrado no servidor, removido do cache');
      }
    } catch (e) {
      _handleOperationError(e, 'sincronizar com servidor para ID $id');
    }
  }


  Future<void> _syncAllWithServer({Map<String, dynamic>? attributes}) async {
    if (!_appStateManager.isOnline) return;
    if (_isSyncing) {
      print('Sincronização já em andamento para coleção $baseCollection, ignorando');
      return;
    }

    _isSyncing = true;
    try {
      await OfflineQueueManager.processQueue();
      Query<Map<String, dynamic>> query = getCollectionReference();
      if (attributes != null) {
        attributes.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }
      final querySnapshot = await query.get();
      for (var doc in querySnapshot.docs) {
        var data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        if (!DataIntegrityManager.hasValidHash(data)) {
          print('Dados do servidor sem hash válido para ID ${doc.id}, adicionando metadata');
          data = await DataIntegrityManager.addFullMetadata(data);
        }
        await LocalCacheManager.updateCache(baseCollection, doc.id, data);
      }
      print('Sincronização completa para coleção $baseCollection, ${querySnapshot.docs.length} itens atualizados');
    } catch (e) {
      _handleOperationError(e, 'sincronizar todos com servidor');
    } finally {
      _isSyncing = false;
    }
  }

  Future<String?> add(T item, {bool returnId = false, Duration? timeout}) async {
    final docRef = getCollectionReference().doc();
    final itemWithId = (item as dynamic).copyWith(id: docRef.id);
    var itemMap = toMap(itemWithId);
    itemMap = await DataIntegrityManager.addFullMetadata(itemMap);
    final isOnline = _appStateManager.isOnline;

    try {
      print('Antes de gravar no cache local: _metadata = ${itemMap['_metadata']}');
      await LocalCacheManager.updateCache(baseCollection, docRef.id, itemMap);
      print('Cache atualizado localmente para novo item ID ${docRef.id}');

      if (!isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'add',
          docId: docRef.id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
        return returnId ? docRef.id : null;
      }

      await _executeWithTimeout(
            () => docRef.set(itemMap, SetOptions(merge: true)),
        timeout ?? _defaultTimeoutOnlineWrite,
      );
      print('Item gravado no Firestore com metadata para ID ${docRef.id}');

      itemMap['_metadata'] = {...itemMap['_metadata'], 'syncStatus': 'synced'};
      print('Enviando _metadata atualizado para Firestore: ${itemMap['_metadata']}');
      await docRef.update({'_metadata': itemMap['_metadata']});

      // Verificação pós-gravação
      final serverDoc = await docRef.get();
      if (serverDoc.exists && serverDoc.data() != null) {
        final serverData = serverDoc.data()!;
        print('Dados retornados do Firestore após gravação: _metadata = ${serverData['_metadata']}');
        if (!serverData.containsKey('_metadata') || !DataIntegrityManager.hasValidHash(serverData)) {
          print('Erro: _metadata não salvo corretamente no Firestore, corrigindo');
          await docRef.set(itemMap, SetOptions(merge: true));
        }
      }

      await LocalCacheManager.updateCache(baseCollection, docRef.id, itemMap);
      print('Item sincronizado com servidor e cache para ID ${docRef.id}');

      return returnId ? docRef.id : null;
    } catch (e) {
      _handleOperationError(e, 'adicionar');
      if (isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'add',
          docId: docRef.id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
      }
      return returnId ? docRef.id : null;
    }
  }

  Future<void> update(String id, T item, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    var itemMap = toMap(item);
    final isOnline = _appStateManager.isOnline;

    try {
      itemMap = await DataIntegrityManager.addFullMetadata(itemMap);
      print('Antes de gravar no cache local: _metadata = ${itemMap['_metadata']}');
      await LocalCacheManager.updateCache(baseCollection, id, itemMap);

      if (!isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'update',
          docId: id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.MEDIUM,
        ));
        return;
      }

      if (await DataIntegrityManager.hasConflict(baseCollection, id, itemMap)) {
        print('Conflito detectado para documento $id - resolvendo');
        final serverDoc = await docRef.get();
        if (serverDoc.exists && serverDoc.data() != null) {
          final serverData = Map<String, dynamic>.from(serverDoc.data()!);
          itemMap = await DataIntegrityManager.resolveConflict(baseCollection, id, itemMap, serverData);
          _notifyConflictResolution(id, itemMap);
        }
      }

      if (itemMap.containsKey('cargaInicial')) {
        await _executeWithTimeout(
              () => docRef.set(itemMap, SetOptions(merge: true)),
          timeout ?? _defaultTimeoutOnlineWrite,
        );
      } else {
        await _executeWithTimeout(
              () => docRef.update(itemMap),
          timeout ?? _defaultTimeoutOnlineWrite,
        );
      }
      print('Item atualizado no Firestore com metadata para ID $id');

      itemMap['_metadata'] = {...itemMap['_metadata'], 'syncStatus': 'synced'};
      print('Enviando _metadata atualizado para Firestore: ${itemMap['_metadata']}');
      await docRef.update({'_metadata': itemMap['_metadata']});

      // Verificação pós-gravação
      final serverDoc = await docRef.get();
      if (serverDoc.exists && serverDoc.data() != null) {
        final serverData = serverDoc.data()!;
        print('Dados retornados do Firestore após atualização: _metadata = ${serverData['_metadata']}');
        if (!serverData.containsKey('_metadata') || !DataIntegrityManager.hasValidHash(serverData)) {
          print('Erro: _metadata não salvo corretamente no Firestore, corrigindo');
          await docRef.set(itemMap, SetOptions(merge: true));
        }
      }

      await LocalCacheManager.updateCache(baseCollection, id, itemMap);
    } catch (e) {
      _handleOperationError(e, 'atualizar');
      if (isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'update',
          docId: id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.MEDIUM,
        ));
      }
      throw e;
    }
  }


  void _notifyConflictResolution(String id, Map<String, dynamic> resolvedData) {
    print('Conflito resolvido para documento $id');
    print('Campos merged: ${resolvedData.keys.where((k) => k != '_metadata')}');
  }

  Future<void> delete(String id, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    final isOnline = _appStateManager.isOnline;
    Map<String, dynamic>? existingData;

    try {
      existingData = await LocalCacheManager.readFromCache(baseCollection, id);
      if (existingData == null && isOnline) {
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          existingData = Map<String, dynamic>.from(doc.data()!);
        }
      }

      if (existingData?.containsKey('cargaInicial') ?? false) {
        print('Aviso: Tentativa de deletar documento crítico (cargaInicial) interrompida: $id');
        return;
      }

      await LocalCacheManager.removeFromCache(baseCollection, id);

      if (!isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'delete',
          docId: id,
          data: existingData ?? {},
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
        return;
      }

      await _executeWithTimeout(
            () => docRef.delete(),
        timeout ?? _defaultTimeoutOnlineWrite,
      );
    } catch (e) {
      _handleOperationError(e, 'deletar');
      if (isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'delete',
          docId: id,
          data: existingData ?? {},
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
        await LocalCacheManager.removeFromCache(baseCollection, id);
      }
    }
  }

  Future<void> deleteByAttribute(Map<String, dynamic> attributes, {Duration? timeout}) async {
    Query<Map<String, dynamic>> query = getCollectionReference();
    final isOnline = _appStateManager.isOnline;

    if (!attributes.containsKey('produtorId') && baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return;
      }
    }

    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    try {
      final cachedDocs = await LocalCacheManager.queryCache(baseCollection, attributes);
      final criticalDocsSkipped = <String>[];

      for (var doc in cachedDocs) {
        if (!DataIntegrityManager.validateDataIntegrity(doc)) {
          print('Dados corrompidos detectados para documento ${doc['id']}');
        }
        if (doc.containsKey('cargaInicial')) {
          print('Aviso: Pulando deleção de documento com campo crítico (cargaInicial): ${doc['id']}');
          criticalDocsSkipped.add(doc['id']);
          continue;
        }

        await LocalCacheManager.removeFromCache(baseCollection, doc['id']);
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'delete',
          docId: doc['id'],
          data: doc,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
      }

      if (!isOnline) {
        if (criticalDocsSkipped.isNotEmpty) {
          print('Aviso: ${criticalDocsSkipped.length} documentos críticos não foram deletados');
        }
        return;
      }

      final querySnapshot = await _executeWithTimeout(() => query.get(), timeout ?? _defaultTimeoutOnlineWrite);
      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseService.firestore.batch();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('cargaInicial')) {
            criticalDocsSkipped.add(doc.id);
            continue;
          }
          if (DataIntegrityManager.hasStoredConflict(data)) {
            print('Aviso: Deletando documento ${doc.id} com conflitos não resolvidos');
          }
          batch.delete(doc.reference);
        }
        if (querySnapshot.docs.length > criticalDocsSkipped.length) {
          await _executeWithTimeout(() => batch.commit(), timeout ?? _defaultTimeoutOnlineWrite);
        }
      }

      if (criticalDocsSkipped.isNotEmpty) {
        print('Aviso: ${criticalDocsSkipped.length} documentos críticos não foram deletados');
      }
    } catch (e) {
      _handleOperationError(e, 'deletar por atributo');
    }
  }

  Future<void> _deleteAll({Duration? timeout}) async {
    final collectionRef = getCollectionReference();
    final isOnline = _appStateManager.isOnline;

    try {
      final docsToDelete = await LocalCacheManager.getAllFromCache(baseCollection);
      final criticalDocsSkipped = <String>[];

      for (var doc in docsToDelete) {
        if (doc.containsKey('cargaInicial')) {
          criticalDocsSkipped.add(doc['id']);
          continue;
        }
        if (!DataIntegrityManager.validateDataIntegrity(doc)) {
          print('Dados corrompidos detectados para documento ${doc['id']}');
        }

        await LocalCacheManager.removeFromCache(baseCollection, doc['id']);
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'delete',
          docId: doc['id'],
          data: doc,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
      }

      if (!isOnline) {
        if (criticalDocsSkipped.isNotEmpty) {
          print('Aviso: ${criticalDocsSkipped.length} documentos críticos não foram deletados');
        }
        return;
      }

      final querySnapshot = await _executeWithTimeout(() => collectionRef.get(), timeout ?? _defaultTimeoutOnlineWrite);
      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseService.firestore.batch();
        for (var doc in querySnapshot.docs) {
          if (doc.data().containsKey('cargaInicial')) {
            criticalDocsSkipped.add(doc.id);
            continue;
          }
          batch.delete(doc.reference);
        }
        if (querySnapshot.docs.length > criticalDocsSkipped.length) {
          await _executeWithTimeout(() => batch.commit(), timeout ?? _defaultTimeoutOnlineWrite);
        }
      }

      if (criticalDocsSkipped.isNotEmpty) {
        print('Aviso: ${criticalDocsSkipped.length} documentos críticos não foram deletados');
      }
    } catch (e) {
      _handleOperationError(e, 'deletar todos');
    }
  }

  // No GenericService, implemente timeouts mais inteligentes:
  Future<T?> getById(String id, {Duration? timeout}) async {
    // Verificar cache primeiro, usando uma versão simplificada de validação
    final cachedData = await LocalCacheManager.readFromCache(baseCollection, id);
    final hasCachedData = cachedData != null && cachedData.containsKey('_metadata');

    // Se temos dados em cache, usá-los imediatamente
    if (hasCachedData) {
      // Programar uma atualização em background apenas se online
      if (_appStateManager.isOnline) {
        _scheduleSyncInBackground(id);
      }

      return fromMap(cachedData, id);
    }

    // Se não temos cache e estamos offline, retornar null
    if (!_appStateManager.isOnline) return null;

    // Tentativa com timeout adaptativo - mais curto no início, aumenta se necessário
    try {
      final doc = await _executeWithAdaptiveTimeout(
            () => getCollectionReference().doc(id).get(),
        timeout ?? _defaultTimeoutOnlineRead,
      );

      if (doc.exists && doc.data() != null) {
        var data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;

        // Garantir metadados mesmo se Firestore retornar sem
        if (!DataIntegrityManager.hasValidHash(data)) {
          data = await DataIntegrityManager.addFullMetadata(data);
        }

        // Atualizar cache local
        await LocalCacheManager.updateCache(baseCollection, id, data);
        return fromMap(data, id);
      }

      return null;
    } catch (e) {
      _handleOperationError(e, 'obter');

      // Em caso de erro, ainda usamos o cache se disponível
      if (hasCachedData) {
        return fromMap(cachedData!, id);
      }

      return null;
    }
  }

  Future<T> _executeWithAdaptiveTimeout<T>(
      Future<T> Function() operation,
      Duration initialTimeout,
      {int maxRetries = 2}
      ) async {
    Duration currentTimeout = initialTimeout;
    int retries = 0;

    while (true) {
      try {
        return await _executeWithTimeout(
          operation,
          currentTimeout,
        );
      } catch (e) {
        if (e is TimeoutException && retries < maxRetries) {
          // Aumentar o timeout em 50% a cada tentativa
          currentTimeout = Duration(milliseconds: (currentTimeout.inMilliseconds * 1.5).toInt());
          retries++;

          // Log para depuração
          print('Timeout excedido, aumentando para ${currentTimeout.inMilliseconds}ms. Tentativa ${retries + 1} de ${maxRetries + 1}');

          // Breve pausa antes de tentar novamente
          await Future.delayed(Duration(milliseconds: 100));
        } else {
          // Propagar erro se excedeu número de tentativas ou não for timeout
          rethrow;
        }
      }
    }
  }

// Método para programar sincronização em background com debounce
  final Map<String, DateTime> _lastSyncScheduled = {};

  void _scheduleSyncInBackground(String id) {
    final now = DateTime.now();
    final lastSync = _lastSyncScheduled[id];

    // Aplicar debounce de 5 minutos para o mesmo ID
    if (lastSync != null && now.difference(lastSync).inMinutes < 5) {
      return;
    }

    _lastSyncScheduled[id] = now;

    // Programar sincronização em background
    Future.delayed(Duration(seconds: 2), () async {
      try {
        final doc = await getCollectionReference().doc(id).get();
        if (doc.exists && doc.data() != null) {
          var data = Map<String, dynamic>.from(doc.data()!);
          data['id'] = doc.id;

          final cachedData = await LocalCacheManager.readFromCache(baseCollection, id);

          // Apenas atualizar se dados do servidor forem diferentes
          if (cachedData == null || _isDifferentVersion(cachedData, data)) {
            if (!DataIntegrityManager.hasValidHash(data)) {
              data = await DataIntegrityManager.addFullMetadata(data);
            }

            await LocalCacheManager.updateCache(baseCollection, id, data);
            print('Dados atualizados em background para $baseCollection:$id');
          }
        }
      } catch (e) {
        // Ignorar erros na sincronização em background
      }
    });
  }

// Método para comparar versões
  bool _isDifferentVersion(Map<String, dynamic> cachedData, Map<String, dynamic> serverData) {
    final cachedVersion = cachedData['_metadata']?['version'] ?? 0;
    final serverVersion = serverData['_metadata']?['version'] ?? 0;

    if (cachedVersion != serverVersion) return true;

    final cachedHash = cachedData['_metadata']?['hash'];
    final serverHash = serverData['_metadata']?['hash'];

    if (cachedHash != null && serverHash != null && cachedHash != serverHash) return true;

    return false;
  }

  Future<List<T>> getByIds(List<String> ids, {Duration? timeout}) async {
    if (baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    final cachedData = await LocalCacheManager.readManyFromCache(baseCollection, ids);
    final items = cachedData
        .where((data) => DataIntegrityManager.validateDataIntegrity(data))
        .map((data) => fromMap(data, data['id']))
        .toList();

    if (_appStateManager.isOnline) {
      unawaited(Future.wait(ids.map((id) => _syncWithServer(id))));
    }

    if (!_appStateManager.isOnline) return items;

    final missingIds = ids.where((id) => !cachedData.any((data) => data['id'] == id)).toList();
    if (missingIds.isEmpty) return items;

    final chunks = <List<String>>[];
    for (var i = 0; i < missingIds.length; i += 10) {
      chunks.add(missingIds.sublist(i, i + 10 > missingIds.length ? missingIds.length : i + 10));
    }

    for (var chunk in chunks) {
      try {
        Query<Map<String, dynamic>> query = getCollectionReference().where(FieldPath.documentId, whereIn: chunk);
        if (baseCollection != 'produtores') {
          query = query.where('produtorId', isEqualTo: _appStateManager.activeProdutorId);
        }

        final querySnapshot = await _executeWithTimeout(
              () => query.get(),
          timeout ?? _defaultTimeoutOnlineRead,
        );

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          var itemData = Map<String, dynamic>.from(data);
          itemData['id'] = doc.id;
          if (!DataIntegrityManager.hasValidHash(itemData)) {
            itemData = await DataIntegrityManager.addFullMetadata(itemData);
          }
          await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
          items.add(fromMap(itemData, doc.id));
        }
      } catch (e) {
        _handleOperationError(e, 'obter por IDs');
      }
    }
    return items;
  }

  Future<List<T>> getByProdutorId(String produtorId) async {
    return getByAttributes({'produtorId': produtorId});
  }

  Future<List<T>> getByPropriedadeId(String propriedadeId) async {
    return getByAttributes({'propriedadeId': propriedadeId});
  }

  Future<void> executeSequentially(List<Future<void> Function()> operations) async {
    for (var operation in operations) {
      await operation();
    }
  }

  Future<List<T>> getAll({Duration? timeout}) async {
    const debounceDuration = Duration(milliseconds: 500);
    final collectionKey = baseCollection;

    // Inicializar mutex se necessário
    _mutexes[collectionKey] ??= Mutex();

    // Adquirir mutex para esta coleção
    await _mutexes[collectionKey]!.acquire();

    try {
      // Verificar se já existe uma solicitação pendente
      if (_pendingGets.containsKey(collectionKey)) {
        print('Aguardando getAll pendente para $collectionKey');
        return await _pendingGets[collectionKey] as List<T>;
      }

      // Verificar debounce, mas com lógica melhorada
      _globalLastCall[collectionKey] ??= DateTime(2000);
      final now = DateTime.now();
      final timeSinceLastCall = now.difference(_globalLastCall[collectionKey]!);

      // Se uma chamada recente aconteceu, retornar dados do cache com filtros adequados
      if (timeSinceLastCall < debounceDuration) {
        print('Chamada a getAll para $collectionKey ignorada por debounce global');
        return _getFilteredCacheData();
      }

      // Se chegou aqui, executaremos uma nova consulta
      final future = _executeGetAllQuery(timeout);
      _pendingGets[collectionKey] = future;
      return await future;
    } finally {
      _mutexes[collectionKey]!.release();
      _pendingGets.remove(collectionKey);
    }
  }

// Método auxiliar para filtrar dados do cache corretamente
  Future<List<T>> _getFilteredCacheData() async {
    final cachedData = await LocalCacheManager.getAllFromCache(baseCollection);
    final List<Map<String, dynamic>> correctedData = [];

    // Corrigir metadados se necessário
    for (var data in cachedData) {
      if (!DataIntegrityManager.validateDataIntegrity(data)) {
        print('Dados do cache sem hash válido para ID ${data['id']}, corrigindo localmente');
        final corrected = await DataIntegrityManager.addFullMetadata(data);
        await LocalCacheManager.updateCache(baseCollection, data['id'], corrected);
        correctedData.add(corrected);
      } else {
        correctedData.add(data);
      }
    }

    // Aplicar filtros específicos para produtores
    if (baseCollection == 'produtores') {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      return correctedData
          .where((data) {
        // Garantir que permissões sejam tratadas como lista
        final List<dynamic> rawPermissoes = data['permissoes'] ?? [];

        // Verificação mais segura do tipo de dados
        bool hasPermission = false;
        for (var perm in rawPermissoes) {
          if (perm is Map) {
            final Map<String, dynamic> permissao = Map<String, dynamic>.from(perm);
            if (permissao['usuarioId'] == currentUser.uid ||
                (currentUser.email != null && permissao['email'] == currentUser.email)) {
              hasPermission = true;
              break;
            }
          }
        }
        return hasPermission;
      })
          .map((data) => fromMap(data, data['id']))
          .toList();
    } else {
      // Para outras coleções, filtrar pelo produtorId ativo
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) return [];

      return correctedData
          .where((data) => data['produtorId'] == activeProdutorId)
          .map((data) => fromMap(data, data['id']))
          .toList();
    }
  }

  // Método para executar a consulta real
  Future<List<T>> _executeGetAllQuery(Duration? timeout) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('Erro: Nenhum usuário autenticado encontrado.');
      return [];
    }

    if (baseCollection == 'produtores') {
      try {
        final queries = <Query<Map<String, dynamic>>>[];

        // Consulta pelo UID do usuário - usando o campo otimizado
        queries.add(getCollectionReference()
            .where('usuariosPermitidos', arrayContains: currentUser.uid));

        // Consulta pelo email do usuário se disponível
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          queries.add(getCollectionReference()
              .where('usuariosPermitidos', arrayContains: 'email:${currentUser.email}'));
        }

        // Executar consultas em paralelo
        final results = await Future.wait(
            queries.map((query) => _executeWithTimeout(
                    () => query.get(),
                timeout ?? _defaultTimeoutOnlineRead
            ))
        );

        // Mesclar resultados e eliminar duplicatas
        final uniqueDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (var querySnapshot in results) {
          for (var doc in querySnapshot.docs) {
            uniqueDocs[doc.id] = doc;
          }
        }

        // Processar documentos
        final items = <T>[];
        for (var doc in uniqueDocs.values) {
          if (doc.data() != null) {
            var data = Map<String, dynamic>.from(doc.data()!);
            data['id'] = doc.id;

            // Verificar permissões (validação adicional)
            bool hasPermission = data.containsKey('usuariosPermitidos') &&
                (data['usuariosPermitidos'].contains(currentUser.uid) ||
                    (currentUser.email != null && data['usuariosPermitidos'].contains('email:${currentUser.email}')));

            if (hasPermission) {
              if (!DataIntegrityManager.hasValidHash(data)) {
                data = await DataIntegrityManager.addFullMetadata(data);
              }

              await LocalCacheManager.updateCache(baseCollection, doc.id, data);
              items.add(fromMap(data, doc.id));
            }
          }
        }

        print('Consultados produtores do Firestore, encontrados ${items.length} com permissões para o usuário');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter produtores');
        return await _getFilteredCacheData();
      }

    } else {
      // O restante do código para outras coleções permanece inalterado
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado para $baseCollection.');
        return [];
      }

      // Obter dados filtrados do cache
      final cachedItems = await _getFilteredCacheData();

      // Se offline ou com dados no cache, retornar esses dados
      if (!_appStateManager.isOnline || cachedItems.isNotEmpty) {
        if (_appStateManager.isOnline) {
          unawaited(_syncAllWithServer(attributes: {'produtorId': activeProdutorId}));
        }
        return cachedItems;
      }

      // Se online e sem dados no cache, buscar do Firestore
      try {
        Query<Map<String, dynamic>> query = getCollectionReference()
            .where('produtorId', isEqualTo: activeProdutorId);

        final querySnapshot = await _executeWithTimeout(
              () => query.get(),
          timeout ?? _defaultTimeoutOnlineRead,
        );

        final items = <T>[];
        for (var doc in querySnapshot.docs) {
          var data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;
          if (!DataIntegrityManager.hasValidHash(data)) {
            data = await DataIntegrityManager.addFullMetadata(data);
          }
          await LocalCacheManager.updateCache(baseCollection, doc.id, data);
          items.add(fromMap(data, doc.id));
        }

        print('Lidos ${items.length} itens do Firestore para a coleção $baseCollection');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter todos para $baseCollection');
        return cachedItems; // Retorna o cache em caso de erro
      }
    }
  }

  bool _matchesFilters(Map<String, dynamic> doc, Map<String, dynamic> filters) {
    return filters.entries.every((filter) => doc[filter.key] == filter.value);
  }

  Future<List<T>> getByProdutorIdWithPagination(String produtorId) async {
    return getByAttributesWithPagination({'produtorId': produtorId});
  }

  Future<List<T>> getByPropriedadeWithPagination(String propriedadeId) async {
    return getByAttributesWithPagination({'propriedadeId': propriedadeId});
  }

  Future<List<T>> _getAllWithPagination() async {
    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    Query<Map<String, dynamic>> query = getCollectionReference();
    final String? activeProdutorId = _appStateManager.activeProdutorId;
    if (activeProdutorId != null) {
      query = query.where('produtorId', isEqualTo: activeProdutorId);
    } else {
      print('Erro: Nenhum produtorId ativo encontrado.');
      return [];
    }
    if (_lastFetchedDocument != null) {
      query = query.startAfterDocument(_lastFetchedDocument!);
    }

    final cachedData = await LocalCacheManager.getPageFromCache(
      baseCollection,
      baseCollection != 'produtores' ? {'produtorId': activeProdutorId} : {},
      _pageSize,
      _lastFetchedDocument,
    );
    final items = cachedData
        .where((data) => DataIntegrityManager.validateDataIntegrity(data))
        .map((data) => fromMap(data, data['id']))
        .toList();


    if (!_appStateManager.isOnline || items.isNotEmpty) {
      if (items.isNotEmpty) {
        final lastItem = items.last;
        final lastItemMap = toMap(lastItem); // Converte o último item para Map
        if (lastItemMap.containsKey('id') && lastItemMap['id'] != null) {
          _lastFetchedDocument = await getCollectionReference().doc(lastItemMap['id'] as String).get();
        } else {
          _lastFetchedDocument = null; // Se id não estiver disponível, seta como null
        }
      } else {
        _lastFetchedDocument = null;
      }
      return items;
    }

    final querySnapshot = await query.limit(_pageSize).get();
    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;
      if (!DataIntegrityManager.hasValidHash(itemData)) {
        itemData = await DataIntegrityManager.addFullMetadata(itemData);
      }
      await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
      result.add(fromMap(itemData, doc.id));
    }

    _lastFetchedDocument = result.isNotEmpty ? querySnapshot.docs.last : null;
    return result;
  }

  void resetPagination() {
    _needsReset = true;
  }

  Future<List<T>> getByAttributesWithPagination(Map<String, dynamic> attributes, {Duration? timeout}) async {
    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    if (!attributes.containsKey('produtorId')) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) attributes['produtorId'] = activeProdutorId;
    }

    final cachedData = await LocalCacheManager.getPageFromCache(baseCollection, attributes, _pageSize, _lastFetchedDocument);
    final items = cachedData
        .where((data) => DataIntegrityManager.validateDataIntegrity(data))
        .map((data) => fromMap(data, data['id']))
        .toList();

    if (_appStateManager.isOnline) {
      unawaited(_syncAllWithServer(attributes: attributes));
    }

    if (!_appStateManager.isOnline || items.isNotEmpty) {
      if (items.isNotEmpty) {
        final lastItem = items.last;
        final lastItemMap = toMap(lastItem); // Converte o último item para Map
        if (lastItemMap.containsKey('id') && lastItemMap['id'] != null) {
          _lastFetchedDocument = await getCollectionReference().doc(lastItemMap['id'] as String).get();
        } else {
          _lastFetchedDocument = null; // Se id não estiver disponível, seta como null
        }
      } else {
        _lastFetchedDocument = null;
      }
      return items;
    }

    Query<Map<String, dynamic>> query = getCollectionReference();
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });
    if (_lastFetchedDocument != null) {
      query = query.startAfterDocument(_lastFetchedDocument!);
    }

    final querySnapshot = await _executeWithTimeout(() => query.limit(_pageSize).get(), timeout ?? _defaultTimeoutOnlineRead);
    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;
      if (!DataIntegrityManager.hasValidHash(itemData)) {
        itemData = await DataIntegrityManager.addFullMetadata(itemData);
      }
      await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
      result.add(fromMap(itemData, doc.id));
    }

    _lastFetchedDocument = result.isNotEmpty ? querySnapshot.docs.last : null;
    return result;
  }

  Future<List<T>> getByAttributes(
      Map<String, dynamic> attributes, {
        Duration? timeout,
        List<Map<String, String>>? orderBy,
        int? limit,
        Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
      }) async {
    if (!attributes.containsKey('produtorId') && (attributesWithOperators == null || !attributesWithOperators.containsKey('produtorId'))) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) attributes['produtorId'] = activeProdutorId;
    }

    final cachedData = await LocalCacheManager.queryCache(baseCollection, attributes, attributesWithOperators, orderBy, limit);
    final correctedData = <Map<String, dynamic>>[];
    for (var data in cachedData) {
      //print('Validando integridade do dado no cache ID ${data['id']}: ${data['_metadata']}');
      if (!DataIntegrityManager.validateDataIntegrity(data)) {
        print('Dados do cache sem hash válido para ID ${data['id']}, corrigindo localmente');
        final corrected = await DataIntegrityManager.addFullMetadata(data);
        print('Dado corrigido para ID ${data['id']}: ${corrected['_metadata']}');
        await LocalCacheManager.updateCache(baseCollection, data['id'], corrected);
        correctedData.add(corrected);
      } else {
        correctedData.add(data);
      }
    }
    final items = correctedData
        .map((data) => fromMap(data, data['id']))
        .toList();

    if (_appStateManager.isOnline) {
      unawaited(_syncAllWithServer(attributes: attributes));
    }

    if (!_appStateManager.isOnline || items.isNotEmpty) return items;

    Query<Map<String, dynamic>> query = getCollectionReference();
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });
    attributesWithOperators?.forEach((key, conditions) {
      for (var condition in conditions) {
        if (condition.containsKey('operator') && condition.containsKey('value')) {
          switch (condition['operator']) {
            case '==': query = query.where(key, isEqualTo: condition['value']); break;
            case '>': query = query.where(key, isGreaterThan: condition['value']); break;
            case '<': query = query.where(key, isLessThan: condition['value']); break;
            case '>=': query = query.where(key, isGreaterThanOrEqualTo: condition['value']); break;
            case '<=': query = query.where(key, isLessThanOrEqualTo: condition['value']); break;
            case '!=': query = query.where(key, isNotEqualTo: condition['value']); break;
          }
        }
      }
    });

    if (orderBy != null) {
      for (var order in orderBy) {
        if (order.containsKey('field') && order.containsKey('direction')) {
          query = query.orderBy(order['field']!, descending: order['direction']?.toLowerCase() == 'desc');
        }
      }
    }
    if (limit != null) query = query.limit(limit);

    try {
      final querySnapshot = await _executeWithTimeout(() => query.get(), timeout ?? _defaultTimeoutOnlineRead);
      final result = <T>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        var itemData = Map<String, dynamic>.from(data);
        itemData['id'] = doc.id;
        if (!DataIntegrityManager.hasValidHash(itemData)) {
          itemData = await DataIntegrityManager.addFullMetadata(itemData);
        }
        await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
        result.add(fromMap(itemData, doc.id));
      }
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar por atributos');
      return items;
    }
  }

  Future<List<T>> getByAttributesWithOperators(
      Map<String, List<Map<String, dynamic>>> attributesWithOperators, {
        List<Map<String, String>>? orderBy,
        Duration? timeout,
        int? limit,
      }) async {
    return getByAttributes({}, attributesWithOperators: attributesWithOperators, orderBy: orderBy, timeout: timeout, limit: limit);
  }

  Future<List<T>> _getAllFromSubcollectionsWithOperators(
      String subcollection,
      Map<String, List<Map<String, dynamic>>> attributesWithOperators, { // Tipo corrigido
        List<Map<String, String>>? orderBy,
        Duration? timeout,
      }) async {
    Query<Map<String, dynamic>> query = FirebaseService.firestore.collectionGroup(subcollection);
    if (!attributesWithOperators.containsKey('produtorId')) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributesWithOperators['produtorId'] = [{'operator': '==', 'value': activeProdutorId}];
      }
    }

    attributesWithOperators.forEach((key, conditions) {
      for (var condition in conditions) {
        if (condition.containsKey('operator') && condition.containsKey('value')) {
          switch (condition['operator']) {
            case '==': query = query.where(key, isEqualTo: condition['value']); break;
            case '>': query = query.where(key, isGreaterThan: condition['value']); break;
            case '<': query = query.where(key, isLessThan: condition['value']); break;
            case '>=': query = query.where(key, isGreaterThanOrEqualTo: condition['value']); break;
            case '<=': query = query.where(key, isLessThanOrEqualTo: condition['value']); break;
            case '!=': query = query.where(key, isNotEqualTo: condition['value']); break;
          }
        }
      }
    });

    if (orderBy != null) {
      for (var order in orderBy) {
        if (order.containsKey('field') && order.containsKey('direction')) {
          query = query.orderBy(order['field']!, descending: order['direction'] == 'desc');
        }
      }
    }

    final cachedData = await LocalCacheManager.queryCache(subcollection, {}, attributesWithOperators, orderBy);
    final items = cachedData
        .where((data) => DataIntegrityManager.validateDataIntegrity(data))
        .map((data) => fromMap(data, data['id']))
        .toList();


    if (!_appStateManager.isOnline || items.isNotEmpty) return items;

    final querySnapshot = await _executeWithTimeout(
          () => query.get(),
      timeout ?? (_appStateManager.isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
    );

    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;
      if (!DataIntegrityManager.hasValidHash(itemData)) {
        itemData = await DataIntegrityManager.addFullMetadata(itemData);
      }
      await LocalCacheManager.updateCache(subcollection, doc.id, itemData);
      result.add(fromMap(itemData, doc.id));
    }
    return result;
  }

  Future<List<T>> _getAllFromSubcollections(String subcollection, {Duration? timeout}) async {
    Query<Map<String, dynamic>> query = FirebaseService.firestore.collectionGroup(subcollection);
    final String? activeProdutorId = _appStateManager.activeProdutorId;
    if (activeProdutorId != null) {
      query = query.where('produtorId', isEqualTo: activeProdutorId);
    }

    final cachedData = await LocalCacheManager.getAllFromCache(subcollection);
    final items = cachedData
        .where((data) => DataIntegrityManager.validateDataIntegrity(data))
        .map((data) => fromMap(data, data['id']))
        .toList();


    if (!_appStateManager.isOnline || items.isNotEmpty) return items;

    final querySnapshot = await _executeWithTimeout(
          () => query.get(),
      timeout ?? (_appStateManager.isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
    );

    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;
      if (!DataIntegrityManager.hasValidHash(itemData)) {
        itemData = await DataIntegrityManager.addFullMetadata(itemData);
      }
      await LocalCacheManager.updateCache(subcollection, doc.id, itemData);
      result.add(fromMap(itemData, doc.id));
    }
    return result;
  }

  Future<Map<String, List<Map<String, dynamic>>>> verificarDependencias(String id, String collection) async {
    final isOnline = _appStateManager.isOnline;
    final dependencias = <String, List<Map<String, dynamic>>>{};
    final dependentCollections = CollectionOptions.getDependentCollections(collection, '${collection}Id');

    for (var dependentCollection in dependentCollections) {
      final fieldName = CollectionOptions.collectionRelations[dependentCollection]?.entries
          .firstWhere((entry) => entry.value == collection, orElse: () => const MapEntry('', ''))?.key ??
          '';
      if (fieldName.isEmpty) continue;

      final cachedDocs = await LocalCacheManager.queryCache(dependentCollection, {fieldName: id});
      if (cachedDocs.isNotEmpty) {
        dependencias[dependentCollection] = cachedDocs;
      }

      if (isOnline) {
        try {
          final querySnapshot = await FirebaseService.firestore
              .collection(dependentCollection)
              .where(fieldName, isEqualTo: id)
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            dependencias[dependentCollection] = querySnapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return data;
            }).toList();
            for (var doc in dependencias[dependentCollection]!) {
              await LocalCacheManager.updateCache(dependentCollection, doc['id'], doc);
            }
          }
        } catch (e) {
          _handleOperationError(e, 'verificar dependências');
        }
      }
    }
    return dependencias;
  }

  Future<void> excluirComDependencias(String id, String collection) async {
    final isOnline = _appStateManager.isOnline;
    Map<String, dynamic>? mainDocData = await LocalCacheManager.readFromCache(collection, id);

    if (mainDocData == null && isOnline) {
      final mainDoc = await FirebaseService.firestore.collection(collection).doc(id).get();
      if (mainDoc.exists && mainDoc.data() != null) {
        mainDocData = Map<String, dynamic>.from(mainDoc.data()!);
      }
    }

    if (mainDocData == null) {
      print('Documento $id não encontrado, operação interrompida');
      return;
    }

    if (mainDocData.containsKey('cargaInicial')) {
      print('Aviso: Tentativa de excluir documento crítico (cargaInicial) com dependências interrompida: $id');
      return;
    }

    final dependencias = isOnline ? await verificarDependencias(id, collection) : await _verificarDependenciasOffline(id, collection);

    for (var entry in dependencias.entries) {
      for (var docData in entry.value) {
        if (docData.containsKey('cargaInicial')) {
          print('Aviso: Dependência contém campo crítico (cargaInicial), operação interrompida: ${docData['id']}');
          return;
        }
      }
    }

    await LocalCacheManager.removeFromCache(collection, id);
    await OfflineQueueManager.addToQueue(OfflineOperation(
      collection: collection,
      operationType: 'delete',
      docId: id,
      data: mainDocData,
      timestamp: DateTime.now(),
      produtorId: _appStateManager.activeProdutorId,
      priority: OperationPriority.HIGH,
    ));

    for (var entry in dependencias.entries) {
      final dependentCollection = entry.key;
      for (var docData in entry.value) {
        final docId = docData['id'];
        await LocalCacheManager.removeFromCache(dependentCollection, docId);
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: dependentCollection,
          operationType: 'delete',
          docId: docId,
          data: docData,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));
      }
    }

    if (isOnline) {
      try {
        await OfflineQueueManager.processQueue();
        await FirebaseService.firestore.collection(collection).doc(id).delete();
        for (var entry in dependencias.entries) {
          final batch = FirebaseService.firestore.batch();
          for (var docData in entry.value) {
            batch.delete(FirebaseService.firestore.collection(entry.key).doc(docData['id']));
          }
          await batch.commit();
        }
      } catch (e) {
        _handleOperationError(e, 'excluir com dependências online');
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _verificarDependenciasOffline(String id, String collection) async {
    final dependencias = <String, List<Map<String, dynamic>>>{};
    final dependentCollections = CollectionOptions.getDependentCollections(collection, '${collection}Id');

    if (dependentCollections.isEmpty) {
      print('Nenhuma coleção dependente encontrada para $collection');
      return dependencias;
    }

    for (var dependentCollection in dependentCollections) {
      if (!CollectionOptions.collectionRelations.containsKey(dependentCollection)) {
        print('Coleção dependente $dependentCollection não encontrada em collectionRelations');
        continue;
      }

      final fieldName = CollectionOptions.collectionRelations[dependentCollection]!
          .entries
          .firstWhere((entry) => entry.value == collection, orElse: () => const MapEntry('', ''))
          .key;

      if (fieldName.isEmpty) {
        print('Nenhum campo de relação encontrado para $dependentCollection apontando para $collection');
        continue;
      }

      final cachedData = await LocalCacheManager.queryCache(dependentCollection, {fieldName: id});
      if (cachedData.isNotEmpty) {
        dependencias[dependentCollection] = cachedData;
      } else {
        print('Nenhum dado encontrado no cache para $dependentCollection com $fieldName = $id');
      }
    }
    return dependencias;
  }
}