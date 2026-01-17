//V01
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'dart:async';
import 'package:planejacampo/utils/collection_options.dart';

abstract class GenericService<T> {
  final AppStateManager _appStateManager = AppStateManager();
  static const Duration _defaultTimeoutOnlineWrite = Duration(seconds: 5);
  static const Duration _defaultTimeoutOnlineRead = Duration(seconds: 10);
  static const Duration _defaultTimeoutOfflineWrite = Duration(milliseconds: 500);
  static const Duration _defaultTimeoutOfflineRead = Duration(milliseconds: 500);
  static const Duration _defaultTimeoutOfflineWriteBatch = Duration(milliseconds: 500);
  static const Duration _defaultTimeoutOfflineReadBatch = Duration(milliseconds: 500);
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

  Future<T> _executeWithTimeout<T>(Future<T> Function() operation,
      Duration timeout, String timeoutMessage) async {
    try {
      return await Future.any([
        operation(),
        Future.delayed(timeout, () => throw TimeoutException(timeoutMessage)),
      ]);
    } on TimeoutException catch (e) {
      throw e;
    }
  }

  void _handleOperationError(dynamic e, String operation) {
    if (e is TimeoutException) {
      print('Timeout ao tentar $operation item: $e');
    } else {
      print('Erro ao $operation item: $e');
    }
  }

  Future<String?> add(T item,
      {bool returnId = false, Duration? timeout}) async {
    final collectionRef = getCollectionReference();
    final docRef = collectionRef.doc();
    final itemWithId = (item as dynamic).copyWith(id: docRef.id);
    final itemMap = toMap(itemWithId);
    bool isOnline = _appStateManager.isOnline;

    try {
      await _executeWithTimeout(
              () => docRef.set(itemMap, SetOptions(merge: true)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
          //timeout ?? _defaultTimeoutWrite,
          'Operação de set excedeu o timeout');
      return returnId ? docRef.id : null;
    } catch (e) {
      _handleOperationError(e, 'adicionar');
      return returnId ? docRef.id : null;
    }
  }

  Future<void> update(String id, T item, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    final itemMap = toMap(item);
    bool isOnline = _appStateManager.isOnline;

    try {
      await _executeWithTimeout(
              () => docRef.update(itemMap),
          timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
          'Operação de update excedeu o timeout');
    } catch (e) {
      _handleOperationError(e, 'atualizar');
    }
  }

  Future<void> delete(String id, {Duration? timeout}) async {
    final docRef = getCollectionReference().doc(id);
    bool isOnline = _appStateManager.isOnline;

    try {
      await _executeWithTimeout(
              () => docRef.delete(),
          timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
          'Operação de delete excedeu o timeout');
    } catch (e) {
      _handleOperationError(e, 'deletar');
    }
  }

  // Deleta documentos por atributos recebidos como parâmetro e adiciona o produtorId caso não tenha recebido este parâmetro, e não seja a baseCollection produtores.
  Future<void> deleteByAttribute(Map<String, dynamic> attributes, {Duration? timeout}) async {
    Query query = getCollectionReference();

    // Verifica se produtorId foi fornecido e se a baseCollection não é 'produtores'
    if (!attributes.containsKey('produtorId') && baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        // Adiciona o produtorId ativo aos atributos
        attributes['produtorId'] = activeProdutorId;
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return;
      }
    }

    // Aplicar os atributos como filtros na consulta
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    bool isOnline = _appStateManager.isOnline;

    try {
      // Executar a consulta para obter os documentos que atendem aos critérios
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
              () => query.get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
          'Operação de deleteByAttribute excedeu o timeout'
      );

      // Verificar se há documentos a serem excluídos
      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseService.firestore.batch();

        // Adicionar a exclusão de cada documento ao batch
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Executar o batch para deletar todos os documentos
        await _executeWithTimeout(
                () => batch.commit(),
            timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
            'Operação de commit do batch excedeu o timeout'
        );

        //print('${querySnapshot.docs.length} documentos deletados.');
      } else {
        //print('Nenhum documento encontrado para os atributos fornecidos.');
      }
    } catch (e) {
      _handleOperationError(e, 'deletar por atributo');
    }
  }

  Future<void> deleteAll({Duration? timeout}) async {
    final collectionRef = getCollectionReference();

    try {
      final querySnapshot = await collectionRef.get();
      final batch = FirebaseService.firestore.batch();
      bool isOnline = _appStateManager.isOnline;

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await _executeWithTimeout(
              () => batch.commit(),
          timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
          'Operação de deleteAll excedeu o timeout');
    } catch (e) {
      _handleOperationError(e, 'deletar todos os');
    }
  }

  Future<T?> getById(String id, {Duration? timeout}) async {
    try {
      bool isOnline = _appStateManager.isOnline;
      final doc =
      await _executeWithTimeout<DocumentSnapshot<Map<String, dynamic>>>(
              () => getCollectionReference().doc(id).get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
          'Operação de getById excedeu o timeout');

      if (doc.exists) {
        return fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      _handleOperationError(e, 'obter');
    }
    return null;
  }

  Future<List<T>> getByIds(List<String> ids, {Duration? timeout}) async {
    if (baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        // Adicionar filtro para produtorId
        // Isso pode variar dependendo de como você deseja combinar os filtros
        // Por exemplo, você pode precisar filtrar por produtorId e onde o documentId está em ids
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    // Firestore 'whereIn' suporta até 10 IDs por consulta
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(
        i,
        i + 10 > ids.length ? ids.length : i + 10,
      ));
    }

    List<T> items = [];
    for (var chunk in chunks) {
      Query<Map<String, dynamic>> query =
      getCollectionReference().where(FieldPath.documentId, whereIn: chunk);

      if (baseCollection != 'produtores') {
        final String? activeProdutorId = _appStateManager.activeProdutorId;
        if (activeProdutorId != null) {
          query = query.where('produtorId', isEqualTo: activeProdutorId);
        }
      }

      try {
        final querySnapshot = await _executeWithTimeout<QuerySnapshot<Map<String, dynamic>>>(
              () => query.get(GetOptions(
            source: _appStateManager.isOnline ? Source.serverAndCache : Source.cache,
          )),
          timeout ?? (_appStateManager.isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),

          'Operação de getByIds excedeu o timeout',
        );

        // **Correção Principal: Converter cada documento para T usando fromMap**
        items.addAll(querySnapshot.docs.map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
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

  Future<void> executeSequentially(
      List<Future<void> Function()> operations) async {
    for (var operation in operations) {
      await operation();
    }
  }

  // Recupera todos os documentos de uma coleção para o produtorId ativo no contexto, ou todos os produtores, caso seja a baseCollection produtores.
  Future<List<T>> getAll({Duration? timeout}) async {
    //Stopwatch totalTime = Stopwatch()..start();
    Stopwatch stepTime = Stopwatch()..start();

    bool isOnline = _appStateManager.isOnline;
    stepTime.reset();

    Query query = getCollectionReference();

    // Verifica se a baseCollection não é 'produtores' e se o produtorId foi fornecido
    if (baseCollection != 'produtores') {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        // Adiciona a filtragem por produtorId
        query = query.where('produtorId', isEqualTo: activeProdutorId);
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    try {
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
              () => query.get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
          'Operação de getAll excedeu o timeout');
      stepTime.reset();

      final result = querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      //print('Tempo total para buscar todos os itens: ${totalTime.elapsed}');
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar todos os');
      return [];
    }
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
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
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
  Future<List<T>> getByAttributesWithPagination(Map<String, dynamic> attributes,
      {Duration? timeout}) async {
    //Stopwatch totalTime = Stopwatch()..start();
    Stopwatch stepTime = Stopwatch()..start();

    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    bool isOnline = _appStateManager.isOnline;
    stepTime.reset();

    Query query = getCollectionReference();

    // Verifica se o produtorId foi passado como atributo, caso contrário, adiciona o ativo
    if (!attributes.containsKey('produtorId')) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        //print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    // Aplicar os atributos como filtros na consulta
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    if (_lastFetchedDocument != null) {
      query = query.startAfterDocument(_lastFetchedDocument!);
    }

    try {
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
              () => query.limit(_pageSize).get(GetOptions(
              source: isOnline ? Source.serverAndCache : Source.cache)),
          timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
          'Operação de getByAttributesWithPagination excedeu o timeout');
      stepTime.reset();

      final result = querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (result.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      } else {
        _lastFetchedDocument = null;
      }

      //print('Tempo total para buscar itens com paginação: ${totalTime.elapsed}');
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar itens com paginação');
      return [];
    }
  }


  Future<List<T>> getByAttributes(
      Map<String, dynamic> attributes, {
        Duration? timeout,
        List<Map<String, String>>? orderBy,
        int? limit,
        Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
      }) async {
    Query query = getCollectionReference();

    // Verifica se o produtorId foi passado como atributo, caso contrário, adiciona o ativo
    if (!attributes.containsKey('produtorId') && (attributesWithOperators == null || !attributesWithOperators.containsKey('produtorId'))) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        //print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    // Aplicar os atributos simples como filtros na consulta
    attributes.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    // Aplicar os atributos com operadores, se fornecidos
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
              default:
                throw ArgumentError('Operador desconhecido: ${condition['operator']}');
            }
          } else {
            throw ArgumentError('Cada condição deve conter um "operator" e um "value".');
          }
        }
      });
    }

    // Aplicar ordenação, se especificada
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

    // Aplicar limite, se especificado
    if (limit != null) {
      query = query.limit(limit);
    }

    try {
      bool isOnline = _appStateManager.isOnline;
      final querySnapshot = await _executeWithTimeout<QuerySnapshot>(
            () => query.get(GetOptions(
          source: isOnline ? Source.serverAndCache : Source.cache,
        )),
        timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
        'Operação de getByAttributes excedeu o timeout',
      );

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _handleOperationError(e, 'buscar itens por atributos');
      return [];
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



  // Método público mantendo a assinatura original
  Future<Map<String, List<Map<String, dynamic>>>> verificarDependencias(
      String id,
      String collection
      ) async {
    return _verificarDependenciasImpl(id, collection);
  }

// Implementação privada melhorada
  Future<Map<String, List<Map<String, dynamic>>>> _verificarDependenciasImpl(
      String id,
      String collection,
      {Duration? timeout}
      ) async {
    Map<String, List<Map<String, dynamic>>> dependencias = {};
    bool isOnline = _appStateManager.isOnline;

    try {
      List<String> dependentCollections = CollectionOptions.getDependentCollections(
          collection,
          '${collection}Id'
      );

      for (String dependentCollection in dependentCollections) {
        String fieldName = CollectionOptions.collectionRelations[dependentCollection]!
            .entries
            .firstWhere((entry) => entry.value == collection)
            .key;

        QuerySnapshot querySnapshot = await _executeWithTimeout<QuerySnapshot>(
                () => FirebaseService.firestore
                .collection(dependentCollection)
                .where(fieldName, isEqualTo: id)
                .get(GetOptions(
                source: isOnline ? Source.serverAndCache : Source.cache
            )),
            timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
            'Operação de verificação de dependências excedeu o timeout'
        );

        if (querySnapshot.docs.isNotEmpty) {
          dependencias[dependentCollection] = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        }
      }

      return dependencias;
    } catch (e) {
      _handleOperationError(e, 'verificar dependências');
      rethrow;
    }
  }

// Método público mantendo a assinatura original
  Future<void> excluirComDependencias(String id, String collection) async {
    await _excluirComDependenciasImpl(id, collection);
  }

  Future<void> _excluirComDependenciasImpl(
      String id,
      String collection,
      {Duration? timeout}
      ) async {
    bool isOnline = _appStateManager.isOnline;

    try {
      // Criar batch usando FirebaseService
      WriteBatch batch = FirebaseService.firestore.batch();

      // Deletar documento principal usando a referência do serviço
      DocumentReference mainDocRef = FirebaseService.firestore
          .collection(collection)
          .doc(id);
      batch.delete(mainDocRef);

      // Buscar documentos dependentes
      Map<String, List<Map<String, dynamic>>> dependencias;
      try {
        dependencias = await _executeWithTimeout<Map<String, List<Map<String, dynamic>>>>(
                () => _verificarDependenciasImpl(
                id,
                collection,
                timeout: timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead)
            ),
            timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead),
            'Operação de busca de dependências excedeu o timeout'
        );
      } catch (e) {
        _handleOperationError(e, 'verificar dependências');
        dependencias = {}; // Em caso de erro na busca, prossegue só com o documento principal
      }

      // Adicionar exclusões das dependências ao batch
      for (var entry in dependencias.entries) {
        String dependentCollection = entry.key;
        for (var docData in entry.value) {
          DocumentReference depDocRef = FirebaseService.firestore
              .collection(dependentCollection)
              .doc(docData['id']);
          batch.delete(depDocRef);
        }
      }

      // Executar o batch sem propagar exceção de timeout
      try {
        await _executeWithTimeout(
                () => batch.commit(),
            timeout ?? (isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite),
            'Operação de exclusão em lote excedeu o timeout'
        );
      } catch (e) {
        _handleOperationError(e, 'excluir documento e dependências');
        // Não propaga a exceção, permitindo que a operação continue no cache
      }
    } catch (e) {
      // Loga qualquer outro tipo de erro que não seja timeout
      _handleOperationError(e, 'excluir documento e dependências');
    }
  }

}
