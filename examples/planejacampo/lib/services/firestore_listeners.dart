import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/utils/collection_options.dart';
import 'package:planejacampo/services/system/data_integrity_manager.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreListeners {
  final AppStateManager _appStateManager;
  final Map<String, StreamSubscription<QuerySnapshot>> _subscriptions = {};
  ListenerState _state = ListenerState.IDLE;
  final ProdutorService _produtorService = ProdutorService();
  bool? _isOfflineFirst;
  Set<String> _processedSetups = {};

  FirestoreListeners(this._appStateManager);

  // Método atualizado para evitar duplicação de listeners
  void updateProdutoresListeners(List<Produtor> newProdutores) {
    if (_state != ListenerState.ACTIVE) return;

    final oldProdutores = _appStateManager.produtoresCache;

    // Produtores a adicionar - verificar se já não temos listeners
    final produtoresToAdd = newProdutores.where((p) =>
    !oldProdutores.any((op) => op.id == p.id) &&
        !_processedSetups.contains(p.id)
    ).toList();

    // Produtores a remover
    final produtoresToRemove = oldProdutores.where((op) =>
    !newProdutores.any((np) => np.id == op.id)
    ).toList();

    // Remover listeners
    for (var produtor in produtoresToRemove) {
      _removeCollectionListenersForProdutor(produtor);
      _processedSetups.remove(produtor.id);
    }

    // Adicionar listeners apenas se offline-first estiver ativado
    if (_isOfflineFirst == true) {
      for (var produtor in produtoresToAdd) {
        _setupCollectionListenersForProdutor(produtor);
        _processedSetups.add(produtor.id);
      }
      print('Listeners de produtores atualizados. Total: ${_subscriptions.length}');
    }
  }

  Future<void> startListening() async {
    // Verificar estado atual para evitar múltiplas inicializações
    if (_state == ListenerState.ACTIVE || _state == ListenerState.INITIALIZING) {
      print('Listeners já estão sendo inicializados ou ativos. Ignorando solicitação.');
      return;
    }

    // Não iniciar listeners se estivermos offline
    if (!_appStateManager.isOnline) {
      print('Dispositivo offline. Não iniciando Firestore listeners.');
      return;
    }

    _state = ListenerState.INITIALIZING;
    print('Starting firestore listeners (estado: $_state)');

    try {
      // Verificar modo offline-first
      _isOfflineFirst = _appStateManager.isOfflineFirstEnabled;
      print('Modo offline-first para FirestoreListeners: $_isOfflineFirst');

      // Obter produtores primeiro
      List<Produtor> produtores = await _getProdutores();
      if (produtores.isEmpty) {
        print('Nenhum produtor encontrado, listeners não iniciados.');
        _state = ListenerState.IDLE;
        return;
      }

      _processedSetups.clear();

      // ABORDAGEM BINÁRIA VERDADEIRA:
      // Se offline-first está ativo: configura TODOS os listeners
      // Se offline-first está desativado: NÃO configura NENHUM listener
      if (_isOfflineFirst == true) {
        print('Modo offline-first ativado: configurando TODOS os listeners');

        // Configurar listener de produtores
        _setupProdutoresListener();

        // Configurar todos os listeners para cada produtor
        for (Produtor produtor in produtores) {
          await _setupCollectionListenersForProdutor(produtor);
          _processedSetups.add(produtor.id);
        }

        _state = ListenerState.ACTIVE;
        print('Listeners iniciados: ${_subscriptions.length} subscrições ativas');
      } else {
        print('Modo offline-first desativado: sem listeners ativos, usando apenas o SDK do Firestore');
        // Não configura NENHUM listener quando offline-first está desativado
        _state = ListenerState.IDLE;
      }
    } catch (e) {
      print('Erro ao iniciar listeners: $e');
      await _cancelAllSubscriptions();
      _state = ListenerState.IDLE;
    }
  }

  // Método auxiliar para cancelar todas as subscrições
  Future<void> _cancelAllSubscriptions() async {
    for (var key in _subscriptions.keys) {
      try {
        await _subscriptions[key]?.cancel();
      } catch (e) {
        print('Erro ao cancelar subscription $key: $e');
      }
    }
    _subscriptions.clear();
  }

  // Método para obter produtores de maneira adequada ao modo de operação
  Future<List<Produtor>> _getProdutores() async {
    // Usar a fonte apropriada com cache primeiro
    if (_appStateManager.produtoresCache.isNotEmpty) {
      return _appStateManager.produtoresCache;
    } else {
      return await _produtorService.getProdutores();
    }
  }

  void _setupProdutoresListener() {
    final currentUser = _appStateManager.authenticatedUser;
    if (currentUser == null) return;

    // Verifica se a inscrição já existe
    if (_subscriptions.containsKey('produtores')) {
      try {
        _subscriptions['produtores']?.cancel();
        _subscriptions.remove('produtores');
        print('Listener de produtores existente cancelado para recriação.');
      } catch (e) {
        print('Erro ao cancelar listener de produtores: $e');
      }
    }

    // Cria novo listener com ID do usuário
    _subscriptions['produtores'] = FirebaseFirestore.instance
        .collection('produtores')
        .where('usuariosPermitidos', arrayContains: currentUser.uid)
        .snapshots()
        .debounceTime(Duration(milliseconds: 500))
        .listen(
          (querySnapshot) => _handleDocumentChanges(querySnapshot, 'produtores'),
      onError: (error) => print("Erro no listener de produtores: $error"),
    );
    print('Listener de produtores configurado.');
  }

  Future<void> _setupCollectionListenersForProdutor(Produtor produtor) async {
    final collectionsWithProdutorId = CollectionOptions.collectionRelations.entries
        .where((entry) => entry.value.containsKey('produtorId'))
        .map((entry) => entry.key)
        .toList();

    for (var collection in collectionsWithProdutorId) {
      final subscriptionKey = '${collection}_${produtor.id}'; // Chave única

      // Cancelar inscrição existente para garantir limpeza adequada
      if (_subscriptions.containsKey(subscriptionKey)) {
        try {
          await _subscriptions[subscriptionKey]?.cancel();
          _subscriptions.remove(subscriptionKey);
          print('Listener existente para $subscriptionKey cancelado para recriação.');
        } catch (e) {
          print('Erro ao cancelar listener para $subscriptionKey: $e');
        }
      }

      // Criar nova subscription com debounce
      final subscription = FirebaseFirestore.instance
          .collection(collection)
          .where('produtorId', isEqualTo: produtor.id)
          .snapshots()
          .debounceTime(Duration(milliseconds: 500))
          .listen(
            (querySnapshot) => _handleDocumentChanges(querySnapshot, collection, produtor.id),
        onError: (error) => print("Erro no listener de $collection para produtor ${produtor.id}: $error"),
      );

      _subscriptions[subscriptionKey] = subscription;
    }
    print('Listeners de coleção para produtor ${produtor.id} configurados.');
  }

  void _removeCollectionListenersForProdutor(Produtor produtor) {
    final collectionsWithProdutorId = CollectionOptions.collectionRelations.entries
        .where((entry) => entry.value.containsKey('produtorId'))
        .map((entry) => entry.key)
        .toList();

    for (var collection in collectionsWithProdutorId) {
      final key = '${collection}_${produtor.id}';
      try {
        _subscriptions[key]?.cancel();
        _subscriptions.remove(key);
      } catch (e) {
        print('Erro ao remover listener para $key: $e');
      }
    }
    print('Listeners do produtor ${produtor.id} removidos.');
  }

  void _handleDocumentChanges(
      QuerySnapshot querySnapshot,
      String collection, [
        String? produtorId,
      ]) async {
    // Verificar estado atual para evitar processamento desnecessário
    if (_state != ListenerState.ACTIVE) {
      print('Listener ativo mas estado é $_state, ignorando alterações para $collection');
      return;
    }

    for (var change in querySnapshot.docChanges) {
      final docId = change.doc.id;
      final data = change.doc.data();
      if (data == null || data is! Map<String, dynamic>) continue;

      Map<String, dynamic> documentData = Map<String, dynamic>.from(data);
      documentData['id'] = docId; // Garante que o ID está presente

      // Em modo offline-first, processamos todas as alterações com verificação de integridade
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
        // Verificação de hash e atualização de cache
          try {
            if (!DataIntegrityManager.hasValidHash(documentData)) {
              print('Dados do servidor sem hash válido para ID $docId, adicionando metadata');
              final correctedData = await DataIntegrityManager.addFullMetadata(
                  documentData,
                  updateFirestore: true,
                  collectionPath: collection,
                  docId: docId
              );
              if (correctedData != null) {
                await LocalCacheManager.updateCache(collection, docId, correctedData);
              } else {
                print('Falha ao corrigir metadados para $collection/$docId');
              }
            } else {
              await LocalCacheManager.updateCache(collection, docId, documentData);
            }
          } catch (e) {
            print('Erro ao processar alteração para $collection/$docId: $e');
          }
          break;

        case DocumentChangeType.removed:
          try {
            await _handleDocumentRemoval(collection, docId);
          } catch (e) {
            print('Erro ao remover documento do cache $collection/$docId: $e');
          }
          break;
      }
    }
  }

  Future<void> _handleDocumentRemoval(String collection, String docId) async {
    // Remove o documento principal
    await LocalCacheManager.removeFromCache(collection, docId);

    // Usa CollectionOptions.getDependentCollections para encontrar documentos relacionados
    final dependentCollections =
    CollectionOptions.getDependentCollections(collection, '${_getSingular(collection)}Id');

    for (var dependentCollection in dependentCollections) {
      if(CollectionOptions.collectionRelations[dependentCollection]?.containsKey('${_getSingular(collection)}Id') ?? false){
        try {
          final docs = await LocalCacheManager.queryCache(
            dependentCollection,
            {'${_getSingular(collection)}Id': docId},
          );

          for (var doc in docs) {
            if (doc['id'] != null) {
              await LocalCacheManager.removeFromCache(
                dependentCollection,
                doc['id'].toString(),
              );
            }
          }
        } catch (e) {
          print('Erro ao processar documentos dependentes para $collection/$docId: $e');
        }
      }
    }
  }

  String _getSingular(String collection) {
    if (collection.endsWith('ies')) {
      return collection.substring(0, collection.length - 3) + 'y'; // Ex: categories -> category
    } else if (collection.endsWith('s')) {
      return collection.substring(0, collection.length - 1); // Ex: users -> user
    }
    return collection; //Caso base, se a palavra não termina em 's'
  }

  Future<void> stopListening() async {
    if (_state == ListenerState.STOPPING || _state == ListenerState.IDLE) {
      print('Listeners já parados ou sendo parados. Estado: $_state');
      return;
    }

    _state = ListenerState.STOPPING;

    try {
      await _cancelAllSubscriptions();
      _processedSetups.clear();
    } catch (e) {
      print('Erro ao parar listeners: $e');
    } finally {
      _state = ListenerState.IDLE;
      print('Todos os listeners do Firestore foram parados.');
    }
  }

  // Método para verificar se os listeners estão ativos
  bool isListening() {
    return _state == ListenerState.ACTIVE;
  }

  // Novo método para atualizar o modo offline-first
  Future<void> updateOfflineFirstMode(bool newMode) async {
    // Se o estado não é ativo e o novo modo é true, precisamos iniciar os listeners
    if (_state != ListenerState.ACTIVE && newMode) {
      print('Iniciando listeners para o modo offline-first');
      await startListening();
      return;
    }

    // Se o estado é ativo mas o modo não mudou, não fazemos nada
    if (_isOfflineFirst == newMode) {
      print('Modo offline-first já está configurado para $newMode');
      return;
    }

    print('Atualizando modo offline-first de $_isOfflineFirst para $newMode');

    if (newMode) {
      // LIGANDO modo offline-first: configura todos os listeners
      _isOfflineFirst = true;

      // Obter produtores
      List<Produtor> produtores = await _getProdutores();

      // Configurar listener de produtores primeiro
      _setupProdutoresListener();

      // Configurar listeners para todas as coleções
      for (Produtor produtor in produtores) {
        await _setupCollectionListenersForProdutor(produtor);
        _processedSetups.add(produtor.id);
      }

      _state = ListenerState.ACTIVE;
      print('Modo offline-first ativado: ${_subscriptions.length} listeners configurados');
    } else {
      // DESLIGANDO modo offline-first: cancela TODOS os listeners
      _isOfflineFirst = false;

      // Cancelar todos os listeners
      await _cancelAllSubscriptions();
      _processedSetups.clear();

      _state = ListenerState.IDLE;
      print('Modo offline-first desativado: todos os listeners cancelados');
    }
  }
}