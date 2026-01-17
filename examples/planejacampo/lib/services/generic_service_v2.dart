//genericServiceV2
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';
import 'dart:async';
import 'package:planejacampo/utils/collection_options.dart';

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
  bool _needsReset = true; // Nova variável para controlar o reset

  String get collectionPath {
    return baseCollection;
  }

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

  Future<String?> add(T item, {bool returnId = false, Duration? timeout}) async {
    final collectionRef = getCollectionReference();
    final docRef = collectionRef.doc();
    final itemWithId = (item as dynamic).copyWith(id: docRef.id);
    final itemMap = toMap(itemWithId);
    bool isOnline = _appStateManager.isOnline;

    try {
      if (!isOnline) {
        // Salva operação na fila
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: baseCollection,
            operationType: 'add',
            docId: docRef.id,
            data: itemMap,
            timestamp: DateTime.now(),
            produtorId: _appStateManager.activeProdutorId
        ));

        // Atualiza cache local
        await LocalCacheManager.updateCache(
            baseCollection,
            docRef.id,
            itemMap
        );

        return returnId ? docRef.id : null;
      }

      await _executeWithTimeout(
              () => docRef.set(itemMap, SetOptions(merge: true)),
          timeout ?? _defaultTimeoutOnlineWrite,
          'Operação de set excedeu o timeout'
      );

      return returnId ? docRef.id : null;
    } catch (e) {
      _handleOperationError(e, 'adicionar');
      return returnId ? docRef.id : null;
    }
  }

  // Update
  Future<void> update(String id, T item, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    final itemMap = toMap(item);
    bool isOnline = _appStateManager.isOnline;

    try {
      if (!isOnline) {
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: baseCollection,
            operationType: 'update',
            docId: id,
            data: itemMap,
            timestamp: DateTime.now(),
            produtorId: _appStateManager.activeProdutorId
        ));

        // Atualiza cache local
        await LocalCacheManager.updateCache(
            baseCollection,
            id,
            itemMap
        );
        return;
      }

      await _executeWithTimeout(
              () => docRef.update(itemMap),
          timeout ?? _defaultTimeoutOnlineWrite,
          'Operação de update excedeu o timeout'
      );
    } catch (e) {
      _handleOperationError(e, 'atualizar');
    }
  }

// Delete
  Future<void> delete(String id, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    bool isOnline = _appStateManager.isOnline;

    try {
      if (!isOnline) {
        // 1. OFFLINE: Adiciona a operação de exclusão à fila offline.
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: baseCollection,
            operationType: 'delete',
            docId: id,
            data: {}, // Para delete, não precisamos de dados.
            timestamp: DateTime.now(),
            produtorId: _appStateManager.activeProdutorId // Importante para saber qual produtor.
        ));

        // 2. OFFLINE: Remove o item do cache local.
        await LocalCacheManager.removeFromCache(baseCollection, id);
        return; // IMPORTANTE:  Retorna após as operações offline.
      }

      // 3. ONLINE: Tenta deletar diretamente no Firestore.
      await _executeWithTimeout(
              () => docRef.delete(),
          timeout ?? _defaultTimeoutOnlineWrite,
          'Operação de delete excedeu o timeout'
      );

    } catch (e) {
      _handleOperationError(e, 'deletar');
      // NÃO relança a exceção.  A operação offline já foi enfileirada.
    }
  }

// DeleteByAttribute
  Future<void> deleteByAttribute(Map<String, dynamic> attributes, {Duration? timeout}) async {
    Query query = getCollectionReference();
    bool isOnline = _appStateManager.isOnline;

    // Adiciona produtorId se necessário (e se não for a coleção 'produtores')
    if (!attributes.containsKey('produtorId') && baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return; // Importante: Retorna se não houver produtorId.
      }
    }

    // Aplica filtros
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    try {
      if (!isOnline) {
        // OFFLINE:
        // 1. Busca documentos do cache local que correspondem aos atributos.
        final cachedDocs = await LocalCacheManager.queryCache(
            baseCollection,
            attributes
        );

        // 2. Para cada documento no cache:
        for (var doc in cachedDocs) {
          // 2a. Adiciona uma operação de 'delete' à fila offline.
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: baseCollection,
              operationType: 'delete',
              docId: doc['id'], // Usa o ID do documento do cache.
              data: {}, // Dados vazios para operação de delete.
              timestamp: DateTime.now(),
              produtorId: _appStateManager.activeProdutorId
          ));

          // 2b. Remove o documento do cache local.
          await LocalCacheManager.removeFromCache(
              baseCollection,
              doc['id']
          );
        }
        return; // IMPORTANTE: Retorna após as operações offline.
      }

      // ONLINE:
      // 1. Busca documentos do Firestore que correspondem aos atributos.
      final QuerySnapshot querySnapshot = await _executeWithTimeout<QuerySnapshot>( // Removi a declaração duplicada
              () => query.get(GetOptions(source: Source.serverAndCache)),
          timeout ?? _defaultTimeoutOnlineWrite,
          'Operação de deleteByAttribute excedeu o timeout'
      );

      // 2. Se houver documentos, cria um batch para deletar todos.
      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseService.firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        // 3. Executa o batch (com timeout).
        await _executeWithTimeout(
                () => batch.commit(),
            timeout ?? _defaultTimeoutOnlineWrite,
            'Operação de commit do batch excedeu o timeout'
        );
      }

    } catch (e) {
      _handleOperationError(e, 'deletar por atributo');
      // NÃO relança a exceção.  A operação offline já foi enfileirada (se aplicável).
    }
  }


  Future<void> _deleteAll({Duration? timeout}) async {
    final collectionRef = getCollectionReference();
    bool isOnline = _appStateManager.isOnline;
    try {
      QuerySnapshot querySnapshot;
      if (isOnline) {
        querySnapshot = await _executeWithTimeout(
                () => collectionRef.get(GetOptions(source: Source.serverAndCache)),
            timeout ?? _defaultTimeoutOnlineWrite,
            'Operação de getAll excedeu o timeout'
        );
      } else {
        querySnapshot = await _executeWithTimeout(
                () => collectionRef.get(GetOptions(source: Source.cache))
        );
      }

      final batch = FirebaseService.firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (isOnline) {
        await _executeWithTimeout(
                () => batch.commit(),
            timeout ?? _defaultTimeoutOnlineWrite,
            'Operação de commit do batch excedeu o timeout'
        );
      } else {
        _executeWithTimeout(() => batch.commit());
      }
    } catch (e) {
      _handleOperationError(e, 'deletar todos os');
    }
  }


  Future<T?> getById(String id, {Duration? timeout}) async {
    try {
      bool isOnline = _appStateManager.isOnline;

      // Se offline, tenta ler apenas do cache
      if (!isOnline) {
        final cachedData = await LocalCacheManager.readFromCache(baseCollection, id);
        if (cachedData != null) {
          return fromMap(Map<String, dynamic>.from(cachedData), id);
        }
        return null;
      }

      try {
        final doc = await _executeWithTimeout<DocumentSnapshot<Map<String, dynamic>>>(
                () => getCollectionReference().doc(id).get(GetOptions(source: Source.cache)),
            timeout ?? _defaultTimeoutOnlineRead,
            'Operação de getById excedeu o timeout'
        );

        if (doc.exists) {
          final docData = doc.data();
          if (docData != null) {
            final data = Map<String, dynamic>.from(docData);
            data['id'] = doc.id;
            await LocalCacheManager.updateCache(baseCollection, doc.id, data);
            return fromMap(data, doc.id);
          }
        }
      } catch (e) {
        // Se falhar a leitura do cache do Firestore, tenta ler do cache local
        final cachedData = await LocalCacheManager.readFromCache(baseCollection, id);
        if (cachedData != null) {
          return fromMap(Map<String, dynamic>.from(cachedData), id);
        }
        rethrow;
      }
    } catch (e) {
      _handleOperationError(e, 'obter');
    }
    return null;
  }

// GetByIds
  Future<List<T>> getByIds(List<String> ids, {Duration? timeout}) async {
    if (baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    bool isOnline = _appStateManager.isOnline;

    // Se offline, retorna do cache
    if (!isOnline) {
      final cachedData = await LocalCacheManager.readManyFromCache(baseCollection, ids);
      return cachedData.map((data) => fromMap(data, data['id'])).toList();
    }

    List<T> items = [];
    // Divide em chunks de 10 IDs (limite do Firestore)
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    for (var chunk in chunks) {
      try {
        Query<Map<String, dynamic>> query = getCollectionReference()
            .where(FieldPath.documentId, whereIn: chunk);

        if (baseCollection != 'produtores') {
          query = query.where('produtorId', isEqualTo: _appStateManager.activeProdutorId);
        }

        final querySnapshot = await _executeWithTimeout(
                () => query.get(GetOptions(source: Source.serverAndCache)),
            timeout ?? _defaultTimeoutOnlineRead,
            'Operação de getByIds excedeu o timeout'
        );

        for (var doc in querySnapshot.docs) {
          final docData = doc.data();
          if (docData != null) {
            final data = Map<String, dynamic>.from(docData);
            data['id'] = doc.id;
            await LocalCacheManager.updateCache(baseCollection, doc.id, data);
            items.add(fromMap(data, doc.id));
          }
        }
      } catch (e) {
        _handleOperationError(e, 'obter por IDs');
        // Em caso de erro, tenta recuperar do cache
        final cachedData = await LocalCacheManager.readManyFromCache(baseCollection, chunk);
        items.addAll(cachedData.map((data) => fromMap(data, data['id'])));
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

  Future<void> executeSequentially(
      List<Future<void> Function()> operations) async {
    for (var operation in operations) {
      await operation();
    }
  }

  // Recupera todos os documentos de uma coleção para o produtorId ativo no contexto, ou todos os produtores, caso seja a baseCollection produtores.
  Future<List<T>> getAll({Duration? timeout}) async {
    bool isOnline = _appStateManager.isOnline;
    Query query = getCollectionReference();

    if (baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        query = query.where('produtorId', isEqualTo: activeProdutorId);
      } else {
        return [];
      }
    }

    // Se offline, usar apenas cache local
    if (!isOnline) {
      try {
        print('Tentando ler do cache local');
        final cachedData = await LocalCacheManager.getAllFromCache(baseCollection);
        final filteredData = cachedData
            .where((data) => _matchesFilters(data, baseCollection != 'produtores'
            ? {'produtorId': _appStateManager.activeProdutorId}
            : {}));

        if (filteredData.isEmpty) {
          print('Nenhum dado encontrado no cache para $baseCollection');
        }

        return filteredData
            .map((data) => fromMap(data, data['id']))
            .toList();
      } catch (e) {
        print('Erro ao ler do cache local: $e');
        return [];
      }
    }

    // Se online
    try {
      final querySnapshot = await _executeWithTimeout(
              () => query.get(GetOptions(source: Source.serverAndCache)),
          timeout ?? _defaultTimeoutOnlineRead,
          'Operação de getAll excedeu o timeout'
      );

      // Atualiza cache com os dados obtidos
      List<T> items = [];
      for (var doc in querySnapshot.docs) {
        if (doc.data() != null) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          // Garantir que o ID está presente
          data['id'] = doc.id;

          try {
            // Atualizar cache de forma segura
            await LocalCacheManager.updateCache(
                baseCollection,
                doc.id,
                data
            );
            items.add(fromMap(data, doc.id));
          } catch (e) {
            print('Erro ao atualizar cache para documento ${doc.id}: $e');
            // Mesmo com erro no cache, adiciona o item à lista
            items.add(fromMap(data, doc.id));
          }
        }
      }
      return items;
    } catch (e) {
      print('Erro ao buscar do servidor, tentando cache: $e');
      try {
        final cachedData = await LocalCacheManager.getAllFromCache(baseCollection);
        return cachedData
            .where((data) => _matchesFilters(data, baseCollection != 'produtores'
            ? {'produtorId': _appStateManager.activeProdutorId}
            : {}))
            .map((data) => fromMap(data, data['id']))
            .toList();
      } catch (e) {
        print('Erro ao ler do cache: $e');
        return [];
      }
    }
  }

// Adicionar este método helper
  bool _matchesFilters(Map<String, dynamic> doc, Map<String, dynamic> filters) {
    return filters.entries.every((filter) => doc[filter.key] == filter.value);
  }


  Future<List<T>> getByProdutorIdWithPagination(String produtorId) async {
    return getByAttributesWithPagination({'produtorId': produtorId});
  }

  Future<List<T>> getByPropriedadeWithPagination(String propriedadeId) async {
    return getByAttributesWithPagination({'propriedadeId': propriedadeId});
  }

  // Recupera todos os documentos com paginação para o produtor ativo no contexto.
  Future<List<T>> _getAllWithPagination() async {
    //Stopwatch totalTime = Stopwatch()..start();
    Stopwatch stepTime = Stopwatch()..start();

    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    bool isOnline = _appStateManager.isOnline;
    stepTime.reset();

    Query query = getCollectionReference();

    // Adiciona o produtorId como filtro
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

    try {
      // Garantir que os dados sejam buscados do servidor
      final querySnapshot = await query.limit(_pageSize).get(
          GetOptions(source: isOnline ? Source.serverAndCache : Source.cache));
      stepTime.reset();

      final result = querySnapshot.docs
          .map((doc) {
        final docData = doc.data();
        if (docData != null) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id;
          return fromMap(data, doc.id);
        }
        return null;
      })
          .where((item) => item != null)
          .cast<T>()
          .toList();

      if (result.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      } else {
        _lastFetchedDocument = null;
      }

      return result;
    } catch (e) {
      print('Error getting all items with pagination: $e');
      return [];
    }
  }


  void resetPagination() {
    _needsReset = true;
  }

  // Recupera todos os registros para um produtorId, com paginação.
  Future<List<T>> getByAttributesWithPagination(
      Map<String, dynamic> attributes,
      {Duration? timeout}
      ) async {
    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    bool isOnline = _appStateManager.isOnline;

    if (!attributes.containsKey('produtorId')) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        return [];
      }
    }

    if (!isOnline) {
      final cachedData = await LocalCacheManager.getPageFromCache(
          baseCollection,
          attributes,
          _pageSize,
          _lastFetchedDocument
      );
      return cachedData.map((data) => fromMap(data, data['id'])).toList();
    }

    Query query = getCollectionReference();
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    if (_lastFetchedDocument != null) {
      query = query.startAfterDocument(_lastFetchedDocument!);
    }

    try {
      final querySnapshot = await _executeWithTimeout(
              () => query.limit(_pageSize).get(GetOptions(source: Source.serverAndCache)),
          timeout ?? _defaultTimeoutOnlineRead,
          'Operação excedeu o timeout'
      );

      List<T> items = [];
      for (var doc in querySnapshot.docs) {
        if (doc.data() != null) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          await LocalCacheManager.updateCache(baseCollection, doc.id, data);
          items.add(fromMap(data, doc.id));
        }
      }

      if (items.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      } else {
        _lastFetchedDocument = null;
      }

      return items;
    } catch (e) {
      _handleOperationError(e, 'buscar itens com paginação');
      final cachedData = await LocalCacheManager.getPageFromCache(
          baseCollection,
          attributes,
          _pageSize,
          _lastFetchedDocument
      );
      return cachedData.map((data) => fromMap(data, data['id'])).toList();
    }
  }


  Future<List<T>> getByAttributes(
      Map<String, dynamic> attributes, {
        Duration? timeout,
        List<Map<String, String>>? orderBy,
        int? limit,
        Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
      }) async {
    bool isOnline = _appStateManager.isOnline;

    if (!attributes.containsKey('produtorId') &&
        (attributesWithOperators == null || !attributesWithOperators.containsKey('produtorId'))) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        return [];
      }
    }

    if (!isOnline) {
      final cachedData = await LocalCacheManager.queryCache(
          baseCollection,
          attributes,
          attributesWithOperators,
          orderBy,
          limit
      );
      return cachedData.map((data) => fromMap(data, data['id'])).toList();
    }

    Query query = getCollectionReference();

    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    if (attributesWithOperators != null) {
      attributesWithOperators.forEach((key, conditions) {
        for (var condition in conditions) {
          if (condition.containsKey('operator') && condition.containsKey('value')) {
            switch (condition['operator']) {
              case '==':
                query = query.where(key, isEqualTo: condition['value']);
                break;
              case '>':
                query = query.where(key, isGreaterThan: condition['value']);
                break;
              case '<':
                query = query.where(key, isLessThan: condition['value']);
                break;
              case '>=':
                query = query.where(key, isGreaterThanOrEqualTo: condition['value']);
                break;
              case '<=':
                query = query.where(key, isLessThanOrEqualTo: condition['value']);
                break;
              case '!=':
                query = query.where(key, isNotEqualTo: condition['value']);
                break;
            }
          }
        }
      });
    }

    if (orderBy != null) {
      for (var order in orderBy) {
        if (order.containsKey('field') && order.containsKey('direction')) {
          query = query.orderBy(
            order['field']!,
            descending: order['direction']?.toLowerCase() == 'desc',
          );
        }
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    try {
      final querySnapshot = await _executeWithTimeout(
              () => query.get(GetOptions(source: Source.serverAndCache)),
          timeout ?? _defaultTimeoutOnlineRead,
          'Operação excedeu o timeout'
      );


      List<T> items = [];
      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        if (docData != null) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id;
          await LocalCacheManager.updateCache(baseCollection, doc.id, data);
          items.add(fromMap(data, doc.id));
        }
      }
      return items;
    } catch (e) {
      _handleOperationError(e, 'buscar por atributos');
      final cachedData = await LocalCacheManager.queryCache(
          baseCollection,
          attributes,
          attributesWithOperators,
          orderBy,
          limit
      );
      return cachedData.map((data) => fromMap(data, data['id'])).toList();
    }
  }

  // Método atualizado para usar o novo getByAttributes
  Future<List<T>> getByAttributesWithOperators(
      Map<String, List<Map<String, dynamic>>> attributesWithOperators, {
        List<Map<String, String>>? orderBy,
        Duration? timeout,
        int? limit,
      }) async {
    return getByAttributes(
      {}, // Atributos simples vazios
      attributesWithOperators: attributesWithOperators,
      orderBy: orderBy,
      timeout: timeout,
      limit: limit,
    );
  }



  // Método para obter dados com operadores e atributos em subcoleções. Insere o produtorId caso não tenha recebido este atributo como parâmetro.
  // Interno pois não é utilizado em nenhum lugar, por não haver subcoleções.
  Future<List<T>> _getAllFromSubcollectionsWithOperators(
      String subcollection,
      Map<String, Map<String, dynamic>> attributesWithOperators,
      {List<Map<String, String>>? orderBy,
        Duration? timeout}) async {

    Stopwatch totalTime = Stopwatch()..start();
    Stopwatch stepTime = Stopwatch()..start();

    bool isOnline = _appStateManager.isOnline;
    Query query = FirebaseService.firestore.collectionGroup(subcollection);

    // Verificar se o produtorId foi passado como um dos atributos
    if (!attributesWithOperators.containsKey('produtorId')) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        // Adiciona o produtorId ao conjunto de atributos com o operador '=='
        attributesWithOperators['produtorId'] = {'operator': '==', 'value': activeProdutorId};
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    // Aplicar operadores nas consultas
    attributesWithOperators.forEach((key, value) {
      if (value.containsKey('operator') && value.containsKey('value')) {
        switch (value['operator']) {
          case '==':
            query = query.where(key, isEqualTo: value['value']);
            break;
          case '>':
            query = query.where(key, isGreaterThan: value['value']);
            break;
          case '<':
            query = query.where(key, isLessThan: value['value']);
            break;
          case '>=':
            query = query.where(key, isGreaterThanOrEqualTo: value['value']);
            break;
          case '<=':
            query = query.where(key, isLessThanOrEqualTo: value['value']);
            break;
          case '!=':
            query = query.where(key, isNotEqualTo: value['value']);
            break;
          default:
            throw ArgumentError('Operador desconhecido: ${value['operator']}');
        }
      } else {
        throw ArgumentError('Cada atributo deve conter um "operator" e um "value".');
      }
    });

    // Adicionando a ordenação, se especificada
    if (orderBy != null) {
      for (var order in orderBy) {
        if (order.containsKey('field') && order.containsKey('direction')) {
          query = query.orderBy(order['field']!,
              descending: order['direction'] == 'desc');
        } else {
          throw ArgumentError(
              'Cada campo de ordenação deve conter um "field" e um "direction".');
        }
      }
    }

    try {
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
              () => query.get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
          'Operação de getAllFromSubcollectionsWithOperators excedeu o timeout');

      stepTime.reset();

      final result = querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Tempo total para buscar todos os itens das subcoleções: ${totalTime.elapsed}');
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar todos os itens das subcoleções com operadores');
      return [];
    }
  }

  // Método para buscar todos os documentos de subcoleções que adiciona o produtorId automaticamente à consulta.
  // Interno pois não é utilizado em nenhum lugar, por não haver subcoleções.
  Future<List<T>> _getAllFromSubcollections(String subcollection,
      {Duration? timeout}) async {
    Stopwatch totalTime = Stopwatch()..start();
    Stopwatch stepTime = Stopwatch()..start();

    bool isOnline = _appStateManager.isOnline;
    stepTime.reset();

    Query query = FirebaseService.firestore.collectionGroup(subcollection);

    // Verificar se o produtorId está presente, caso contrário, adicioná-lo
    final String? activeProdutorId = _appStateManager.activeProdutorId;
    if (activeProdutorId != null) {
      query = query.where('produtorId', isEqualTo: activeProdutorId);
    } else {
      print('Erro: Nenhum produtorId ativo encontrado.');
      return [];
    }

    try {
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
              () => query.get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
          'Operação de getAllFromSubcollections excedeu o timeout');

      stepTime.reset();

      final result = querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print(
          'Tempo total para buscar todos os itens das subcoleções: ${totalTime.elapsed}');
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar todos os itens das subcoleções');
      return [];
    }
  }



  Future<Map<String, List<Map<String, dynamic>>>> verificarDependencias(String id, String collection) async {
    Map<String, List<Map<String, dynamic>>> dependencias = {};
    List<String> dependentCollections = CollectionOptions.getDependentCollections(collection, '${collection}Id');

    //print("Verificando dependências para $collection com ID $id");
    //print("Coleções dependentes: $dependentCollections");

    for (String dependentCollection in dependentCollections) {
      //print("Verificando coleção: $dependentCollection");
      String fieldName = CollectionOptions.collectionRelations[dependentCollection]!.entries
          .firstWhere((entry) => entry.value == collection).key;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(dependentCollection)
          .where(fieldName, isEqualTo: id)
          .get();

      //print("Documentos encontrados em $dependentCollection: ${querySnapshot.docs.length}");

      if (querySnapshot.docs.isNotEmpty) {
        dependencias[dependentCollection] = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          //print("Documento encontrado: ${data}");
          return data;
        }).toList();
      }
    }

    //print("Dependências encontradas: $dependencias");
    return dependencias;
  }

  Future<void> excluirComDependencias(String id, String collection) async {
    bool isOnline = _appStateManager.isOnline;

    try {
      // Primeiro busca todas as dependências (do cache se estiver offline)
      Map<String, List<Map<String, dynamic>>> dependencias = await verificarDependencias(id, collection);

      if (!isOnline) {
        // Modo OFFLINE

        // 1. Adiciona operação de exclusão do documento principal à fila
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: collection,
            operationType: 'delete',
            docId: id,
            data: {},
            timestamp: DateTime.now(),
            produtorId: _appStateManager.activeProdutorId
        ));

        // 2. Remove documento principal do cache
        await LocalCacheManager.removeFromCache(collection, id);

        // 3. Para cada dependência, adiciona à fila e remove do cache
        for (var entry in dependencias.entries) {
          String dependentCollection = entry.key;
          for (var docData in entry.value) {
            String docId = docData['id'];

            // Adiciona operação de exclusão à fila
            await OfflineQueueManager.addToQueue(OfflineOperation(
                collection: dependentCollection,
                operationType: 'delete',
                docId: docId,
                data: {},
                timestamp: DateTime.now(),
                produtorId: _appStateManager.activeProdutorId
            ));

            // Remove do cache
            await LocalCacheManager.removeFromCache(dependentCollection, docId);
          }
        }

        return;
      }

      // Modo ONLINE
      WriteBatch batch = FirebaseService.firestore.batch();

      // Delete the main document
      DocumentReference mainDocRef = FirebaseService.firestore.collection(collection).doc(id);
      batch.delete(mainDocRef);

      // Delete dependent documents
      for (var entry in dependencias.entries) {
        String dependentCollection = entry.key;
        for (var docData in entry.value) {
          DocumentReference depDocRef = FirebaseService.firestore.collection(dependentCollection).doc(docData['id']);
          batch.delete(depDocRef);
        }
      }

      // Executa o batch com timeout
      await _executeWithTimeout(
              () => batch.commit(),
          _defaultTimeoutOnlineWrite,
          'Operação de exclusão em lote excedeu o timeout'
      );

      // Remove do cache após sucesso do batch
      await LocalCacheManager.removeFromCache(collection, id);
      for (var entry in dependencias.entries) {
        for (var docData in entry.value) {
          await LocalCacheManager.removeFromCache(entry.key, docData['id']);
        }
      }

      print('Documento principal e todas as dependências foram excluídos com sucesso.');
    } catch (e) {
      _handleOperationError(e, 'excluir com dependências');
      throw e;
    }
  }

}
