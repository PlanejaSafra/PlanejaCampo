import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';
import 'package:planejacampo/services/system/data_integrity_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejacampo/utils/collection_options.dart';
import 'package:mutex/mutex.dart';

/// Classe para gerenciar acesso a dados com suporte a operações online e offline
class GenericService<T> {
  final String baseCollection;
  final AppStateManager _appStateManager = AppStateManager();
  bool _initialized = false;
  bool _offlineFirstMode = false;

  // Cache para evitar verificações repetitivas
  static final Map<String, bool> _offlineFirstModeCache = {};
  static bool _verboseLogging = false; // Desativado por padrão

  // Configurações de timeout
  static const Duration _defaultTimeoutOnlineWrite = Duration(seconds: 30);
  static const Duration _defaultTimeoutOnlineRead = Duration(seconds: 20);
  static const Duration _defaultTimeoutOfflineWrite = Duration(seconds: 1);
  static const Duration _defaultTimeoutOfflineRead = Duration(seconds: 2);

  // Configurações para paginação
  static const int _pageSize = 20;
  DocumentSnapshot? _lastFetchedDocument;
  bool _needsReset = true;
  bool _isSyncing = false;
  DateTime? _lastCall = DateTime(2000);
  static final Map<String, DateTime> _globalLastCall = {};
  static final Map<String, Future<List<dynamic>>> _pendingGets = {};
  static final Map<String, Mutex> _mutexes = {}; // Mutex por coleção

  /// Construtor principal
  GenericService(this.baseCollection) {
    _initialize();
  }

  /// Ativa ou desativa logs detalhados
  static void setVerboseLogging(bool verbose) {
    _verboseLogging = verbose;
  }

  /// Limpa o cache das configurações de modo offline-first quando o produtor muda
  static void clearOfflineFirstModeCache() {
    _offlineFirstModeCache.clear();
  }

  /// Inicialização assíncrona
  Future<void> _initialize() async {
    try {
      await _checkOfflineFirstMode();
      _initialized = true;
    } catch (e) {
      print('Erro ao inicializar GenericService para $baseCollection: $e');
      _initialized = true; // Marcar como inicializado mesmo com erro para evitar bloqueios
    }
  }

  /// Verifica e define o modo de operação (offline-first ou não)
  Future<void> _checkOfflineFirstMode() async {
    try {
      final String? produtorId = _appStateManager.activeProdutorId;
      if (produtorId == null) {
        _offlineFirstMode = false;
        return;
      }

      // Verifica se já está no cache para evitar operações desnecessárias
      final cacheKey = '${produtorId}_$baseCollection';
      if (_offlineFirstModeCache.containsKey(cacheKey)) {
        _offlineFirstMode = _offlineFirstModeCache[cacheKey] ?? false;
        return;
      }

      // Usa o método do AppStateManager para verificar a configuração
      // Acesso direto à propriedade, sem chamar método async
      _offlineFirstMode = _appStateManager.isOfflineFirstEnabled;

      // Armazena no cache
      _offlineFirstModeCache[cacheKey] = _offlineFirstMode ?? false;

      // Log apenas se for a primeira vez para esta coleção
      if (_verboseLogging) {
        print('Modo offline-first para $baseCollection: $_offlineFirstMode');
      }
    } catch (e) {
      print('Erro ao verificar modo offline-first: $e');
      _offlineFirstMode = false;
    }
  }

  /// Garante que o serviço está inicializado antes de usar
  /// Garante que o serviço está inicializado antes de usar
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }

    // Verificar modo apenas quando o produtor mudar
    if (_appStateManager.producerChanged) {
      // Limpar o cache de modo quando o produtor muda
      clearOfflineFirstModeCache();
      await _checkOfflineFirstMode();
      _appStateManager.resetProducerChanged();
    }

    // Sempre verificar se estamos em modo offline e offline-first está ativado
    if (!_appStateManager.isOnline && _offlineFirstMode == true) {
      // Forçar uso do cache local quando offline com offline-first
      // Não precisa fazer mais nada aqui, os métodos de obtenção de dados
      // já devem preferir o cache local
      if (_verboseLogging) {
        print('Offline com offline-first ativado para $baseCollection: usando cache local');
      }
    }
  }

  /// Implementação de fromMap (deve ser sobrescrita nas subclasses)
  T fromMap(Map<String, dynamic> map, String documentId) {
    throw UnimplementedError("fromMap deve ser implementado pelas subclasses");
  }

  /// Implementação de toMap (deve ser sobrescrita nas subclasses)
  Map<String, dynamic> toMap(T item) {
    throw UnimplementedError("toMap deve ser implementado pelas subclasses");
  }

  /// Retorna a referência para a coleção no Firestore
  CollectionReference<Map<String, dynamic>> getCollectionReference() {
    return FirebaseService.firestore.collection(baseCollection);
  }

  /// Retorna a referência para um documento específico na coleção
  DocumentReference<Map<String, dynamic>> getDocumentReference(String id) {
    return getCollectionReference().doc(id);
  }

  /// Retorna uma nova referência de documento (com ID gerado)
  DocumentReference<Map<String, dynamic>> getNewDocumentReference() {
    return getCollectionReference().doc();
  }

  /// Executa uma operação com timeout
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

  /// Trata erros de operação com log padronizado
  void _handleOperationError(dynamic e, String operation) {
    if (e is TimeoutException) {
      print('Timeout ao tentar $operation item: $e');
    } else {
      print('Erro ao $operation item: $e');
    }
  }

  /// Adiciona um item à coleção
  Future<String?> add(T item, {bool returnId = false, Duration? timeout}) async {
    await _ensureInitialized();
    final docRef = getCollectionReference().doc();
    final itemWithId = (item as dynamic).copyWith(id: docRef.id);
    var itemMap = toMap(itemWithId);
    final isOnline = _appStateManager.isOnline;

    try {
      if (_offlineFirstMode == true) {
        // Adicionar metadados completos
        itemMap = await DataIntegrityManager.addFullMetadata(itemMap);

        // Atualizar cache local
        await LocalCacheManager.updateCache(baseCollection, docRef.id, itemMap);

        // Enfileirar a operação para sincronização futura
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'add',
          docId: docRef.id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));

        // Se online, tentar processar a fila em background
        if (isOnline) {
          unawaited(OfflineQueueManager.processQueue());
        }

        return returnId ? docRef.id : null;
      } else {
        // Modo Firestore puro
        Duration timeoutToUse = isOnline ? (timeout ?? _defaultTimeoutOnlineWrite) : _defaultTimeoutOfflineWrite;

        await _executeWithTimeout(
          () => docRef.set(itemMap),
          timeoutToUse,
        );

        return returnId ? docRef.id : null;
      }
    } catch (e) {
      _handleOperationError(e, 'adicionar');
      return returnId ? docRef.id : null;
    }
  }

  /// Atualiza um item existente na coleção
  /// Atualiza um item existente na coleção
  Future<void> update(String id, T item, {Duration? timeout}) async {
    await _ensureInitialized();
    final docRef = getCollectionReference().doc(id);
    var itemMap = toMap(item);
    final isOnline = _appStateManager.isOnline;

    try {
      // Modo offline-first com Hive
      if (_offlineFirstMode == true) {
        // Adicionar metadados e atualizar cache local
        itemMap = await DataIntegrityManager.addFullMetadata(itemMap);
        await LocalCacheManager.updateCache(baseCollection, id, itemMap);

        // Enfileirar a operação para sincronização futura
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'update',
          docId: id,
          data: itemMap,
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.MEDIUM,
        ));

        // Se online, tentar processar a fila em background
        if (isOnline) {
          unawaited(OfflineQueueManager.processQueue());
        }
      }
      // Modo Firestore nativo - tentar mesmo offline, deixar o Firestore lidar com o enfileiramento
      else {
        try {
          // Definir método de update baseado na presença de campos críticos
          Duration timeoutToUse = isOnline ? (timeout ?? _defaultTimeoutOnlineWrite) : _defaultTimeoutOfflineWrite;

          if (itemMap.containsKey('cargaInicial')) {
            await _executeWithTimeout(
              () => docRef.set(itemMap, SetOptions(merge: true)),
              timeoutToUse,
            );
          } else {
            await _executeWithTimeout(
              () => docRef.update(itemMap),
              timeoutToUse,
            );
          }

          print('Documento $id atualizado com sucesso ou enfileirado para sincronização.');
        } catch (e) {
          // Se for timeout, apenas registrar mas não tratar como erro crítico
          if (e is TimeoutException) {
            print('Operação de atualização enfileirada para $id. Será sincronizada quando online.');
          } else {
            // Outros erros ainda devem ser reportados
            _handleOperationError(e, 'atualizar');
            throw e; // Propagar o erro para tratamento superior se não for timeout
          }
        }
      }
    } catch (e) {
      if (e is TimeoutException) {
        print('Operação de atualização enfileirada para $id. Será sincronizada quando online.');
      } else {
        _handleOperationError(e, 'atualizar');
        throw e; // Propagar o erro para tratamento superior
      }
    }
  }

  /// Remove um item da coleção
  Future<void> delete(String id, {Duration? timeout}) async {
    await _ensureInitialized();
    final docRef = getCollectionReference().doc(id);
    final isOnline = _appStateManager.isOnline;
    Map<String, dynamic>? existingData;

    try {
      // Primeiro verificar se existem dados críticos
      if (_offlineFirstMode == true) {
        existingData = await LocalCacheManager.readFromCache(baseCollection, id);
      } else if (isOnline) {
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          existingData = Map<String, dynamic>.from(doc.data()!);
        }
      }

      // Proteção contra deleção de dados críticos
      if (existingData?.containsKey('cargaInicial') ?? false) {
        print('Aviso: Tentativa de deletar documento crítico (cargaInicial) interrompida: $id');
        return;
      }

      // Modo offline-first
      if (_offlineFirstMode == true) {
        await LocalCacheManager.removeFromCache(baseCollection, id);
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: baseCollection,
          operationType: 'delete',
          docId: id,
          data: existingData ?? {},
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));

        if (isOnline) {
          unawaited(OfflineQueueManager.processQueue());
        }
      }
      // Modo Firestore nativo - tentar mesmo offline, deixar o Firestore lidar com o enfileiramento
      else {
        try {
          // Modo Firestore puro
          Duration timeoutToUse = isOnline ? (timeout ?? _defaultTimeoutOnlineWrite) : _defaultTimeoutOfflineWrite;

          await _executeWithTimeout(
            () => docRef.delete(),
            timeoutToUse,
          );

          //await docRef.delete();
          print('Documento $id excluído com sucesso ou enfileirado para sincronização.');
        } catch (e) {
          // Se for timeout, apenas registrar mas não tratar como erro crítico
          if (e is TimeoutException) {
            print('Operação de exclusão enfileirada para $id. Será sincronizada quando online.');
          } else {
            // Outros erros ainda devem ser reportados
            _handleOperationError(e, 'deletar');
          }
        }
      }
    } catch (e) {
      if (e is TimeoutException) {
        print('Operação de exclusão enfileirada para $id. Será sincronizada quando online.');
      } else {
        _handleOperationError(e, 'deletar');
      }
    }
  }

  /// Remove itens com base em atributos
  /// Remove itens com base em atributos
  Future<void> deleteByAttribute(Map<String, dynamic> attributes, {Duration? timeout}) async {
    await _ensureInitialized();
    Query<Map<String, dynamic>> query = getCollectionReference();
    final isOnline = _appStateManager.isOnline;

    // Adicionar produtorId se não for fornecido (exceto para a coleção produtores)
    if (!attributes.containsKey('produtorId') && CollectionOptions.requiresProducerId(baseCollection)) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributes['produtorId'] = activeProdutorId;
      } else {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return;
      }
    }

    try {
      // Construir query básica
      attributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      // Lista para armazenar documentos a serem processados
      List<Map<String, dynamic>> docsToProcess = [];

      // FASE 1: BUSCAR DOCUMENTOS

      // Se online, sempre buscar documentos do Firestore primeiro, independente do modo
      if (isOnline) {
        Duration timeoutToUse = timeout ?? _defaultTimeoutOnlineWrite;
        try {
          final querySnapshot = await _executeWithTimeout(() => query.get(), timeoutToUse);
          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              docsToProcess.add(data);
            }
          }
          print('Encontrados ${docsToProcess.length} documentos no Firestore para exclusão: $attributes');
        } catch (e) {
          _handleOperationError(e, 'buscar documentos do Firestore para deletar');
          // Não retornar aqui, continuar para tentar usar o cache como fallback
        }
      }

      // Se estiver em modo offline-first e não encontrou documentos no Firestore (ou está offline)
      // Consultar o cache local como fallback ou fonte primária
      if ((docsToProcess.isEmpty || !isOnline) && _offlineFirstMode == true) {
        final cachedDocs = await LocalCacheManager.queryCache(baseCollection, attributes);
        if (cachedDocs.isNotEmpty) {
          // Se já tem documentos do Firestore, apenas adicionar novos documentos do cache
          if (docsToProcess.isNotEmpty) {
            final existingIds = docsToProcess.map((d) => d['id'] as String).toSet();
            for (var doc in cachedDocs) {
              if (!existingIds.contains(doc['id'])) {
                docsToProcess.add(doc);
              }
            }
          } else {
            docsToProcess = cachedDocs;
          }
          print('Usando ${cachedDocs.length} documentos do cache local para exclusão');
        }
      }

      // Se offline sem modo offline-first, informar sobre enfileiramento
      if (!isOnline && !_offlineFirstMode && docsToProcess.isEmpty) {
        print('Dispositivo offline e modo offline-first desativado. A operação será enfileirada pelo Firestore.');
      }

      // FASE 2: PROCESSAR E EXCLUIR DOCUMENTOS

      final criticalDocsSkipped = <String>[];
      int processedCount = 0;

      // Modo offline-first
      if (_offlineFirstMode == true) {
        for (var doc in docsToProcess) {
          final String docId = doc['id'] as String;

          // Verificar integridade dos dados
          if (!DataIntegrityManager.validateDataIntegrity(doc)) {
            print('Dados corrompidos detectados para documento $docId');
          }

          // Verificar se é documento crítico
          if (doc.containsKey('cargaInicial')) {
            print('Aviso: Pulando deleção de documento com campo crítico (cargaInicial): $docId');
            criticalDocsSkipped.add(docId);
            continue;
          }

          // Atualizar cache e enfileirar operação
          await LocalCacheManager.removeFromCache(baseCollection, docId);
          await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: baseCollection,
            operationType: 'delete',
            docId: docId,
            data: doc,
            timestamp: DateTime.now(),
            produtorId: _appStateManager.activeProdutorId,
            priority: OperationPriority.HIGH,
          ));

          processedCount++;
          print('Documento $docId marcado para exclusão e removido do cache');
        }

        // Processar fila se online
        if (isOnline) {
          unawaited(OfflineQueueManager.processQueue());
        }
      }
      // Modo Firestore nativo
      else {
        // Se online, usar batch para melhor performance
        if (isOnline && docsToProcess.isNotEmpty) {
          final batch = FirebaseService.firestore.batch();
          int docsAddedToBatch = 0;

          for (var doc in docsToProcess) {
            final String docId = doc['id'] as String;

            // Verificar se é documento crítico
            if (doc.containsKey('cargaInicial')) {
              criticalDocsSkipped.add(docId);
              continue;
            }

            // Adicionar ao batch
            batch.delete(getDocumentReference(docId));
            docsAddedToBatch++;
          }

          // Commit do batch se há documentos
          if (docsAddedToBatch > 0) {
            try {
              Duration timeoutToUse = timeout ?? _defaultTimeoutOnlineWrite;
              await _executeWithTimeout(() => batch.commit(), timeoutToUse);
              processedCount = docsAddedToBatch;
              print('Batch com $docsAddedToBatch documentos excluídos com sucesso');
            } catch (e) {
              if (e is TimeoutException) {
                print('Operação de exclusão em batch enfileirada. Será sincronizada quando online.');
              } else {
                _handleOperationError(e, 'executar batch de exclusão');
              }
            }
          }
        }
        // Se offline, tentar exclusão individual deixando o Firestore lidar com o enfileiramento
        else if (!isOnline) {
          if (docsToProcess.isEmpty) {
            print('Sem documentos em cache para excluir. A operação será tentada quando online.');
          } else {
            for (var doc in docsToProcess) {
              final String docId = doc['id'] as String;

              try {
                Duration timeoutToUse = _defaultTimeoutOfflineWrite;
                await _executeWithTimeout(() => getDocumentReference(docId).delete(), timeoutToUse);
                processedCount++;
                print('Documento $docId marcado para exclusão quando online');
              } catch (e) {
                if (e is TimeoutException) {
                  print('Operação de exclusão enfileirada para $docId. Será sincronizada quando online.');
                } else {
                  _handleOperationError(e, 'deletar documento $docId');
                }
              }
            }
          }
        }
      }

      // Reportar documentos críticos pulados
      if (criticalDocsSkipped.isNotEmpty) {
        print('Aviso: ${criticalDocsSkipped.length} documentos críticos não foram deletados');
      }

      // Resumo da operação
      if (processedCount > 0) {
        print('deleteByAttribute concluído: $processedCount documentos de $baseCollection marcados para exclusão');
      } else if (docsToProcess.isEmpty) {
        print('deleteByAttribute: Nenhum documento encontrado para exclusão com atributos: $attributes');
      }
    } catch (e) {
      print('Erro ao executar deleteByAttribute: $e');
    }
  }

  /// Obtém um item pelo seu ID
  Future<T?> getById(String id, {Duration? timeout}) async {
    await _ensureInitialized();

    if (_offlineFirstMode == true) {
      // Verificar cache primeiro (Hive)
      final cachedData = await LocalCacheManager.readFromCache(baseCollection, id);
      final hasCachedData = cachedData != null && cachedData.containsKey('_metadata');

      // Se temos dados em cache e estamos offline ou em modo offline-first, usar o cache
      if (hasCachedData && (!_appStateManager.isOnline || _offlineFirstMode)) {
        return fromMap(cachedData, id);
      }

      // Se temos dados em cache em modo online normal, usar cache e atualizar em background
      if (hasCachedData) {
        if (_appStateManager.isOnline) {
          _scheduleSyncInBackground(id);
        }
        return fromMap(cachedData, id);
      }

      // Se não temos cache e estamos offline, retornar null
      if (!_appStateManager.isOnline) {
        print('Dispositivo offline e sem cache para $baseCollection:$id');
        return null;
      }

      // Tentar obter do servidor com timeout adaptativo
      try {
        final doc = await _executeWithAdaptiveTimeout(
          () => getCollectionReference().doc(id).get(),
          timeout ?? _defaultTimeoutOnlineRead,
        );

        if (doc.exists && doc.data() != null) {
          var data = Map<String, dynamic>.from(doc.data()!)..['id'] = doc.id;
          if (!DataIntegrityManager.hasValidHash(data)) {
            data = await DataIntegrityManager.addFullMetadata(data);
          }
          await LocalCacheManager.updateCache(baseCollection, id, data);
          return fromMap(data, id);
        }
        return null;
      } catch (e) {
        _handleOperationError(e, 'obter');
        if (hasCachedData) {
          return fromMap(cachedData!, id);
        }
        return null;
      }
    } else {
      // Modo Firestore puro
      try {
        bool isOnline = _appStateManager.isOnline;
        final effectiveTimeout = timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead);

        final doc = await _executeWithTimeout<DocumentSnapshot<Map<String, dynamic>>>(
          () => getCollectionReference().doc(id).get(GetOptions(
                source: isOnline ? Source.serverAndCache : Source.cache,
              )),
          effectiveTimeout,
          'Operação de getById excedeu o timeout para $baseCollection:$id',
        );

        if (doc.exists && doc.data() != null) {
          return fromMap(doc.data()!, doc.id);
        }
        return null;
      } catch (e) {
        _handleOperationError(e, 'obter');
        return null;
      }
    }
  }

  /// Executa uma operação com timeout adaptativo
  Future<T> _executeWithAdaptiveTimeout<T>(Future<T> Function() operation, Duration initialTimeout, {int maxRetries = 2}) async {
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

  /// Programa sincronização em background com debounce (apenas para modo offline-first)
  final Map<String, DateTime> _lastSyncScheduled = {};

  void _scheduleSyncInBackground(String id) {
    if (_offlineFirstMode != true) return; // Não executar fora do modo offline-first

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
        final doc = await _executeWithTimeout(
          () => getCollectionReference().doc(id).get(),
          _defaultTimeoutOnlineRead,
        );
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

  /// Compara versões de documentos (usado apenas no modo offline-first)
  bool _isDifferentVersion(Map<String, dynamic> cachedData, Map<String, dynamic> serverData) {
    final cachedVersion = cachedData['_metadata']?['version'] ?? 0;
    final serverVersion = serverData['_metadata']?['version'] ?? 0;

    if (cachedVersion != serverVersion) return true;

    final cachedHash = cachedData['_metadata']?['hash'];
    final serverHash = serverData['_metadata']?['hash'];

    if (cachedHash != null && serverHash != null && cachedHash != serverHash) return true;

    return false;
  }

  /// Obtém múltiplos itens pelos seus IDs
  Future<List<T>> getByIds(List<String> ids, {Duration? timeout}) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    // NOVA VALIDAÇÃO: Filtrar IDs vazios e retornar se lista vazia
    ids = ids.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      return [];
    }

    if (CollectionOptions.requiresProducerId(baseCollection)) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado.');
        return [];
      }
    }

    if (_offlineFirstMode == true) {
      // Tentar cache local primeiro
      final cachedData = await LocalCacheManager.readManyFromCache(baseCollection, ids);
      final items = cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'] as String)).toList();

      // Programar sincronização em background se online
      if (isOnline) {
        unawaited(Future.wait(ids.map((id) => _syncWithServer(id))));
      }

      // Retornar cache se offline ou se todos os dados foram encontrados
      if (!isOnline || items.length == ids.length) {
        return items;
      }
    }

    // Modo Firestore (com ou sem offline-first, se necessário)
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    List<T> result = [];

    for (var chunk in chunks) {
      try {
        Query<Map<String, dynamic>> query = getCollectionReference().where(FieldPath.documentId, whereIn: chunk);

        // Adicionar filtro de produtorId, se aplicável
        if (CollectionOptions.requiresProducerId(baseCollection)) {
          query = query.where('produtorId', isEqualTo: _appStateManager.activeProdutorId);
        }

        // Definir timeout e source
        final effectiveTimeout = timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead);
        final source = isOnline ? Source.serverAndCache : Source.cache;

        final querySnapshot = await _executeWithTimeout(
          () => query.get(GetOptions(source: source)),
          effectiveTimeout,
          'Operação de getByIds excedeu o timeout para $baseCollection',
        );

        for (var doc in querySnapshot.docs) {
          var data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;

          // Atualizar cache se em modo offline-first
          if (_offlineFirstMode == true && isOnline) {
            if (!DataIntegrityManager.hasValidHash(data)) {
              data = await DataIntegrityManager.addFullMetadata(data);
            }
            await LocalCacheManager.updateCache(baseCollection, doc.id, data);
          }

          result.add(fromMap(data, doc.id));
        }
      } catch (e) {
        _handleOperationError(e, 'obter por IDs');
        if (!isOnline && _offlineFirstMode == true) {
          final cachedData = await LocalCacheManager.readManyFromCache(baseCollection, chunk);
          result.addAll(
            cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'] as String)),
          );
        }
      }
    }

    return result;
  }

  /// Sincroniza um documento específico com o servidor e atualiza o cache local
  Future<void> _syncWithServer(String id) async {
    if (!_appStateManager.isOnline || _offlineFirstMode != true) return;

    try {
      // Obter o documento do Firestore
      final doc = await _executeWithTimeout(
        () => getCollectionReference().doc(id).get(),
        _defaultTimeoutOnlineRead,
      );
      if (doc.exists && doc.data() != null) {
        var data = Map<String, dynamic>.from(doc.data()!)..['id'] = doc.id;
        // Verificar integridade dos dados
        if (!DataIntegrityManager.hasValidHash(data)) {
          data = await DataIntegrityManager.addFullMetadata(data);
        }
        // Atualizar o cache local
        await LocalCacheManager.updateCache(baseCollection, id, data);
      } else {
        // Se o documento não existe no servidor, removê-lo do cache
        await LocalCacheManager.removeFromCache(baseCollection, id);
      }
    } catch (e) {
      _handleOperationError(e, 'sincronizar com servidor');
    }
  }

  /// Sincroniza um documento específico com o servidor (apenas para modo offline-first)
  Future<void> _syncAllWithServer({
    Map<String, dynamic>? attributes,
    Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
  }) async {
    if (!_appStateManager.isOnline || _offlineFirstMode != true) return;

    if (_isSyncing) {
      print('Sincronização já em andamento para $baseCollection, ignorando');
      return;
    }

    _isSyncing = true;

    try {
      await OfflineQueueManager.processQueue();

      Query<Map<String, dynamic>> query = getCollectionReference();

      // Adicionar filtros simples
      attributes?.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      // Adicionar filtros com operadores
      attributesWithOperators?.forEach((key, conditions) {
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

      final querySnapshot = await query.get();

      for (var doc in querySnapshot.docs) {
        var data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;
        if (!DataIntegrityManager.hasValidHash(data)) {
          print('Dados do servidor sem hash válido para ID ${doc.id}, adicionando metadata');
          data = await DataIntegrityManager.addFullMetadata(data);
        }
        await LocalCacheManager.updateCache(baseCollection, doc.id, data);
      }

      print('Sincronização completa para $baseCollection, ${querySnapshot.docs.length} itens atualizados');
    } catch (e) {
      _handleOperationError(e, 'sincronizar por atributos com servidor');
    } finally {
      _isSyncing = false;
    }
  }

  /// Obtém itens associados a um produtor
  Future<List<T>> getByProdutorId(String produtorId) async {
    await _ensureInitialized();
    return getByAttributes({'produtorId': produtorId});
  }

  /// Obtém itens associados a uma propriedade
  Future<List<T>> getByPropriedadeId(String propriedadeId) async {
    await _ensureInitialized();
    return getByAttributes({'propriedadeId': propriedadeId});
  }

  /// Executa uma sequência de operações
  Future<void> executeSequentially(List<Future<void> Function()> operations) async {
    await _ensureInitialized();
    for (var operation in operations) {
      await operation();
    }
  }

  /// Obtém todos os itens da coleção
  Future<List<T>> getAll({Duration? timeout}) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

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

      // Verificar debounce global
      _globalLastCall[collectionKey] ??= DateTime(2000);
      final now = DateTime.now();
      final timeSinceLastCall = now.difference(_globalLastCall[collectionKey]!);

      // Se uma chamada recente aconteceu, usar cache (se disponível) ou retornar vazio
      if (timeSinceLastCall < debounceDuration) {
        print('Chamada a getAll para $collectionKey ignorada por debounce global');
        return _offlineFirstMode == true ? await _getFilteredCacheData() : [];
      }

      // Se chegou aqui, executaremos uma nova consulta
      Future<List<T>> future;

      if (_offlineFirstMode == true) {
        // Modo offline-first com Hive
        future = _executeGetAllWithHive(timeout);
      } else {
        // Modo Firestore direto
        future = _executeGetAllQueryDirect(timeout);
      }

      _pendingGets[collectionKey] = future;
      _globalLastCall[collectionKey] = now;

      return await future;
    } finally {
      _mutexes[collectionKey]!.release();
      _pendingGets.remove(collectionKey);
    }
  }

  /// Filtra dados do cache para retornar resultados apropriados (apenas para modo offline-first)
  Future<List<T>> _getFilteredCacheData() async {
    final cachedData = await LocalCacheManager.getAllFromCache(baseCollection);
    final List<Map<String, dynamic>> correctedData = [];

    // Corrigir metadados se necessário
    for (var data in cachedData) {
      if (!DataIntegrityManager.validateDataIntegrity(data)) {
        print('Dados do cache sem hash válido para ID ${data['id']}, corrigindo localmente');
        final corrected = await DataIntegrityManager.addFullMetadata(data);
        await LocalCacheManager.updateCache(baseCollection, data['id'] as String, corrected);
        correctedData.add(corrected);
      } else {
        correctedData.add(data);
      }
    }

    // Aplicar filtros específicos
    if (baseCollection == 'produtores') {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      return correctedData
          .where((data) {
            final List<dynamic> rawPermissoes = data['permissoes'] ?? [];
            bool hasPermission = false;
            for (var perm in rawPermissoes) {
              if (perm is Map) {
                final Map<String, dynamic> permissao = Map<String, dynamic>.from(perm);
                if (permissao['usuarioId'] == currentUser.uid || (currentUser.email != null && permissao['email'] == currentUser.email)) {
                  hasPermission = true;
                  break;
                }
              }
            }
            return hasPermission;
          })
          .map((data) => fromMap(data, data['id'] as String))
          .toList();
    } else if (CollectionOptions.requiresProducerId(baseCollection)) {
      // Usa o método proposto para verificar se a coleção requer filtro por produtor
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) return [];
      return correctedData.where((data) => data['produtorId'] == activeProdutorId).map((data) => fromMap(data, data['id'] as String)).toList();
    } else {
      // Nenhum filtro específico para coleções que não requerem produtorId
      return correctedData.map((data) => fromMap(data, data['id'] as String)).toList();
    }
  }

  /// Executa consulta para obter todos os itens usando Hive (modo offline-first)
  Future<List<T>> _executeGetAllWithHive(Duration? timeout) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOnline = _appStateManager.isOnline;

    if (currentUser == null) {
      print('Erro: Nenhum usuário autenticado encontrado.');
      return [];
    }

    // Obter dados do cache
    final cachedItems = await _getFilteredCacheData();

    // Se offline, retornar apenas dados do cache
    if (!isOnline) {
      print('Dispositivo offline, retornando ${cachedItems.length} itens do cache para $baseCollection');
      return cachedItems;
    }

    // Tratamento especial para coleção de produtores
    if (baseCollection == 'produtores') {
      try {
        final queries = <Query<Map<String, dynamic>>>[];
        queries.add(getCollectionReference().where('usuariosPermitidos', arrayContains: currentUser.uid));
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          queries.add(getCollectionReference().where('usuariosPermitidos', arrayContains: 'email:${currentUser.email}'));
        }

        final results = await Future.wait(
          queries.map((query) => _executeWithTimeout(
                () => query.get(),
                timeout ?? _defaultTimeoutOnlineRead,
              )),
        );

        final uniqueDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (var querySnapshot in results) {
          for (var doc in querySnapshot.docs) {
            uniqueDocs[doc.id] = doc;
          }
        }

        final items = <T>[];
        for (var doc in uniqueDocs.values) {
          if (doc.data() != null) {
            var data = Map<String, dynamic>.from(doc.data()!)..['id'] = doc.id;
            bool hasPermission = data.containsKey('usuariosPermitidos') && (data['usuariosPermitidos'].contains(currentUser.uid) || (currentUser.email != null && data['usuariosPermitidos'].contains('email:${currentUser.email}')));

            if (hasPermission) {
              if (!DataIntegrityManager.hasValidHash(data)) {
                data = await DataIntegrityManager.addFullMetadata(data);
              }
              await LocalCacheManager.updateCache(baseCollection, doc.id, data);
              items.add(fromMap(data, doc.id));
            }
          }
        }

        print('Consultados produtores do Firestore, encontrados ${items.length} com permissões');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter produtores');
        return cachedItems; // Fallback para cache em caso de erro
      }
    } else {
      // Outras coleções
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado para $baseCollection.');
        return [];
      }

      if (cachedItems.isNotEmpty) {
        if (CollectionOptions.requiresProducerId(baseCollection)) {
          unawaited(_syncAllWithServer(attributes: {'produtorId': activeProdutorId}));
        } else {
          unawaited(_syncAllWithServer(attributes: {})); // Sem filtro por produtor
        }
        return cachedItems;
      }

      try {
        Query<Map<String, dynamic>> query = getCollectionReference();
        if (CollectionOptions.requiresProducerId(baseCollection)) {
          query = query.where('produtorId', isEqualTo: activeProdutorId);
        }

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

        print('Lidos ${items.length} itens do Firestore para $baseCollection');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter todos para $baseCollection');
        return cachedItems;
      }
    }
  }

  /// Executa consulta para obter todos os itens diretamente do Firestore (sem Hive)
  Future<List<T>> _executeGetAllQueryDirect(Duration? timeout) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOnline = _appStateManager.isOnline;

    if (currentUser == null) {
      print('Erro: Nenhum usuário autenticado encontrado.');
      return [];
    }

    final effectiveTimeout = timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead);

    if (baseCollection == 'produtores') {
      try {
        final queries = <Query<Map<String, dynamic>>>[];
        queries.add(getCollectionReference().where('usuariosPermitidos', arrayContains: currentUser.uid));
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          queries.add(getCollectionReference().where('usuariosPermitidos', arrayContains: 'email:${currentUser.email}'));
        }

        final results = await Future.wait(
          queries.map((query) => _executeWithTimeout(
                () => query.get(GetOptions(source: isOnline ? Source.serverAndCache : Source.cache)),
                effectiveTimeout,
              )),
        );

        final uniqueDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (var querySnapshot in results) {
          for (var doc in querySnapshot.docs) {
            uniqueDocs[doc.id] = doc;
          }
        }

        final items = <T>[];
        for (var doc in uniqueDocs.values) {
          if (doc.data() != null) {
            var data = Map<String, dynamic>.from(doc.data()!)..['id'] = doc.id;
            bool hasPermission = data.containsKey('usuariosPermitidos') && (data['usuariosPermitidos'].contains(currentUser.uid) || (currentUser.email != null && data['usuariosPermitidos'].contains('email:${currentUser.email}')));

            if (hasPermission) {
              items.add(fromMap(data, doc.id));
            }
          }
        }

        print('Consultados produtores do Firestore, encontrados ${items.length} com permissões');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter produtores');
        return [];
      }
    } else {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId == null) {
        print('Erro: Nenhum produtorId ativo encontrado para $baseCollection.');
        return [];
      }

      try {
        // Iniciar com uma consulta base sem filtros
        Query<Map<String, dynamic>> query = getCollectionReference();

        // Adicionar o filtro de produtorId apenas para coleções que o requerem
        if (CollectionOptions.requiresProducerId(baseCollection)) {
          query = query.where('produtorId', isEqualTo: activeProdutorId);
        }

        final querySnapshot = await _executeWithTimeout(
          () => query.get(GetOptions(source: isOnline ? Source.serverAndCache : Source.cache)),
          effectiveTimeout,
        );

        final items = querySnapshot.docs.map((doc) => fromMap(Map<String, dynamic>.from(doc.data())..['id'] = doc.id, doc.id)).toList();

        print('Lidos ${items.length} itens do Firestore para $baseCollection');
        return items;
      } catch (e) {
        _handleOperationError(e, 'obter todos para $baseCollection');
        return [];
      }
    }
  }

  /// Sincroniza todos os documentos com o servidor (apenas para modo offline-first)

  /// Obtém itens por atributos, ordenação e limites
  Future<List<T>> getByAttributes(
    Map<String, dynamic> attributes, {
    Duration? timeout,
    List<Map<String, String>>? orderBy,
    int? limit,
    Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
  }) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    // Adicionar produtorId se não fornecido
    // Adicionar produtorId apenas se:
    // 1. A coleção requer este filtro
    // 2. O atributo não foi explicitamente incluído pelos parâmetros
    if (CollectionOptions.requiresProducerId(baseCollection) &&
        !attributes.containsKey('produtorId') &&
        (attributesWithOperators == null || !attributesWithOperators.containsKey('produtorId'))) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) attributes['produtorId'] = activeProdutorId;
    }
    // Modo offline-first com Hive
    if (_offlineFirstMode == true) {
      // Tentar cache local primeiro
      final cachedData = await LocalCacheManager.queryCache(
        baseCollection,
        attributes,
        attributesWithOperators,
        orderBy,
        limit,
      );

      // Se temos dados no cache e estamos offline ou em modo offline-first
      if (cachedData.isNotEmpty && (!isOnline || _offlineFirstMode)) {
        final correctedData = <Map<String, dynamic>>[];
        for (var data in cachedData) {
          if (!DataIntegrityManager.validateDataIntegrity(data)) {
            print('Dados do cache sem hash válido para ID ${data['id']}, corrigindo localmente');
            try {
              final corrected = await DataIntegrityManager.addFullMetadata(data);
              await LocalCacheManager.updateCache(baseCollection, data['id'] as String, corrected);
              correctedData.add(corrected);
            } catch (e) {
              print('Erro ao corrigir dados: $e');
              correctedData.add(data); // Usa dados originais em caso de erro
            }
          } else {
            correctedData.add(data);
          }
        }

        final items = correctedData.map((data) => fromMap(data, data['id'] as String)).toList();

        // Sincronização em background se online
        if (isOnline) {
          unawaited(_syncAllWithServer(
            attributes: attributes,
            attributesWithOperators: attributesWithOperators,
          ));
        }

        return items;
      }

      // Se offline e sem cache, retornar vazio
      if (!isOnline) {
        print('Dispositivo offline e sem cache para $baseCollection com atributos $attributes');
        return [];
      }
    }

    // Modo Firestore (com ou sem Hive, dependendo do caso)
    try {
      Query<Map<String, dynamic>> query = getCollectionReference();

      // Adicionar filtros simples
      attributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      // Adicionar filtros com operadores
      attributesWithOperators?.forEach((key, conditions) {
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

      // Adicionar ordenação
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

      // Adicionar limite
      if (limit != null) query = query.limit(limit);

      // Definir timeout e source
      final effectiveTimeout = timeout ?? (isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead);
      final source = isOnline ? Source.serverAndCache : Source.cache;

      // Executar consulta
      final querySnapshot = await _executeWithTimeout(
        () => query.get(GetOptions(source: source)),
        effectiveTimeout,
        'Operação de getByAttributes excedeu o timeout para $baseCollection',
      );

      final result = <T>[];
      for (var doc in querySnapshot.docs) {
        var data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;

        // Atualizar cache apenas se em modo offline-first e online
        if (_offlineFirstMode == true && isOnline) {
          if (!DataIntegrityManager.hasValidHash(data)) {
            data = await DataIntegrityManager.addFullMetadata(data);
          }
          await LocalCacheManager.updateCache(baseCollection, doc.id, data);
        }

        result.add(fromMap(data, doc.id));
      }

      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar por atributos');

      // Fallback para cache apenas se em modo offline-first
      if (_offlineFirstMode == true) {
        final cachedData = await LocalCacheManager.queryCache(
          baseCollection,
          attributes,
          attributesWithOperators,
          orderBy,
          limit,
        );
        if (cachedData.isNotEmpty) {
          print('Usando cache após erro para $baseCollection com atributos $attributes');
          return cachedData.map((data) => fromMap(data, data['id'] as String)).toList();
        }
      }

      return [];
    }
  }

  /// Obtém itens com base em operadores complexos
  Future<List<T>> getByAttributesWithOperators(
    Map<String, List<Map<String, dynamic>>> attributesWithOperators, {
    List<Map<String, String>>? orderBy,
    Duration? timeout,
    int? limit,
  }) async {
    await _ensureInitialized();
    return getByAttributes({}, attributesWithOperators: attributesWithOperators, orderBy: orderBy, timeout: timeout, limit: limit);
  }

  /// Verifica se um documento atende aos filtros especificados
  bool _matchesFilters(Map<String, dynamic> doc, Map<String, dynamic> filters) {
    return filters.entries.every((filter) => doc[filter.key] == filter.value);
  }

  /// Obtém itens por produtorId com paginação
  Future<List<T>> getByProdutorIdWithPagination(String produtorId) async {
    await _ensureInitialized();
    return getByAttributesWithPagination({'produtorId': produtorId});
  }

  /// Obtém itens por propriedadeId com paginação
  Future<List<T>> getByPropriedadeWithPagination(String propriedadeId) async {
    await _ensureInitialized();
    return getByAttributesWithPagination({'propriedadeId': propriedadeId});
  }

  /// Reseta o estado de paginação
  void resetPagination() {
    _needsReset = true;
  }

  /// Obtém todos os itens com paginação
  Future<List<T>> _getAllWithPagination() async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    // Construir query com produtorId
    Query<Map<String, dynamic>> query = getCollectionReference();
    // Verificar se a coleção requer filtro por produtorId
    final String? activeProdutorId = _appStateManager.activeProdutorId;
    if (CollectionOptions.requiresProducerId(baseCollection)) {
      if (activeProdutorId != null) {
        query = query.where('produtorId', isEqualTo: activeProdutorId);
      } else {
        print('Erro: Nenhum produtorId ativo encontrado para $baseCollection.');
        return [];
      }
    }
    // Se a coleção não requer filtro por produtorId, continua sem adicionar o filtro

    // Adicionar documento de início para continuação da paginação
    if (_lastFetchedDocument != null) {
      query = query.startAfterDocument(_lastFetchedDocument!);
    }

    // SE OFFLINE-FIRST ESTÁ ATIVADO: tentar cache local primeiro
    if (_offlineFirstMode == true) {
      // Obter dados do cache
      final cachedData = await LocalCacheManager.getPageFromCache(
        baseCollection,
        CollectionOptions.requiresProducerId(baseCollection) ? {'produtorId': activeProdutorId} : {},
        _pageSize,
        _lastFetchedDocument,
      );

      final items = cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'])).toList();

      // Se offline ou com dados no cache, retornar esses dados
      if (!isOnline || items.isNotEmpty) {
        if (items.isNotEmpty) {
          final lastItem = items.last;
          final lastItemMap = toMap(lastItem);
          if (lastItemMap.containsKey('id') && lastItemMap['id'] != null) {
            _lastFetchedDocument = await getCollectionReference().doc(lastItemMap['id'] as String).get();
          } else {
            _lastFetchedDocument = null;
          }
        } else {
          _lastFetchedDocument = null;
        }
        return items;
      }
    }

    // SE NÃO TEMOS CACHE ou OFFLINE-FIRST ESTÁ DESATIVADO: buscar do Firestore
    if (!isOnline) return []; // Não podemos buscar do Firestore se estamos offline

    Duration timeoutToUse = isOnline ? _defaultTimeoutOnlineRead : _defaultTimeoutOfflineRead;

    final querySnapshot = await _executeWithTimeout(() => query.limit(_pageSize).get(), timeoutToUse);

    final result = <T>[];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;

      // Se estamos no modo offline-first, atualizar o cache
      if (_offlineFirstMode == true) {
        if (!DataIntegrityManager.hasValidHash(itemData)) {
          itemData = await DataIntegrityManager.addFullMetadata(itemData);
        }

        await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
      }

      result.add(fromMap(itemData, doc.id));
    }

    _lastFetchedDocument = result.isNotEmpty ? querySnapshot.docs.last : null;
    return result;
  }

  /// Obtém itens com paginação com base em atributos
  Future<List<T>> getByAttributesWithPagination(Map<String, dynamic> attributes, {Duration? timeout}) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    if (_needsReset) {
      _lastFetchedDocument = null;
      _needsReset = false;
    }

    // Adicionar produtorId se não fornecido
    if (!attributes.containsKey('produtorId') && CollectionOptions.requiresProducerId(baseCollection)) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) attributes['produtorId'] = activeProdutorId;
    }

    // Obter dados do cache
    final cachedData = await LocalCacheManager.getPageFromCache(baseCollection, attributes, _pageSize, _lastFetchedDocument);

    // Se temos dados no cache e:
    // 1. Estamos offline OU
    // 2. Estamos no modo offline-first (independente de online/offline)
    if (cachedData.isNotEmpty && (!isOnline || _offlineFirstMode == true)) {
      final items = cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'])).toList();

      // Programar sincronização em background se online e offline-first
      if (isOnline && _offlineFirstMode == true) {
        unawaited(_syncAllWithServer(attributes: attributes));
      }

      // Atualizar documentos para paginação
      if (items.isNotEmpty) {
        try {
          final lastItem = items.last;
          final lastItemMap = toMap(lastItem);
          if (lastItemMap.containsKey('id') && lastItemMap['id'] != null) {
            if (isOnline) {
              _lastFetchedDocument = await _executeWithTimeout(
                () => getCollectionReference().doc(lastItemMap['id'] as String).get(),
                _defaultTimeoutOnlineRead,
              );
            } else {
              // Se offline, apenas guardar o ID para referência
              final String lastId = lastItemMap['id'] as String;
              print('Em modo offline, usando ID $lastId como referência para paginação');
            }
          } else {
            _lastFetchedDocument = null;
          }
        } catch (e) {
          print('Erro ao atualizar documento de paginação: $e');
          _lastFetchedDocument = null;
        }
      } else {
        _lastFetchedDocument = null;
      }

      return items;
    }

    // Se estamos offline e não temos cache, retornar lista vazia
    if (!isOnline) {
      print('Dispositivo offline e sem cache para paginação de $baseCollection');
      return [];
    }

    // Se chegamos aqui, estamos online e precisamos buscar do Firestore
    try {
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

        // Se estamos no modo offline-first, atualizar o cache
        if (_offlineFirstMode == true) {
          if (!DataIntegrityManager.hasValidHash(itemData)) {
            itemData = await DataIntegrityManager.addFullMetadata(itemData);
          }

          await LocalCacheManager.updateCache(baseCollection, doc.id, itemData);
        }

        result.add(fromMap(itemData, doc.id));
      }

      _lastFetchedDocument = result.isNotEmpty ? querySnapshot.docs.last : null;
      return result;
    } catch (e) {
      _handleOperationError(e, 'buscar com paginação');

      // Em caso de erro, tentar usar o cache se disponível
      if (cachedData.isNotEmpty) {
        print('Usando cache após erro na paginação');
        return cachedData.map((data) => fromMap(data, data['id'])).toList();
      }

      return [];
    }
  }

  /// Obtém todos os itens de subcoleções com operadores
  Future<List<T>> _getAllFromSubcollectionsWithOperators(
    String subcollection,
    Map<String, List<Map<String, dynamic>>> attributesWithOperators, {
    List<Map<String, String>>? orderBy,
    Duration? timeout,
  }) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    Query<Map<String, dynamic>> query = FirebaseService.firestore.collectionGroup(subcollection);

    // Adicionar produtorId se não fornecido
    if (!attributesWithOperators.containsKey('produtorId') && CollectionOptions.requiresProducerId(baseCollection)) {
      final String? activeProdutorId = _appStateManager.activeProdutorId;
      if (activeProdutorId != null) {
        attributesWithOperators['produtorId'] = [
          {'operator': '==', 'value': activeProdutorId}
        ];
      }
    }

    // Adicionar filtros com operadores
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

    // Adicionar ordenação
    if (orderBy != null) {
      for (var order in orderBy) {
        if (order.containsKey('field') && order.containsKey('direction')) {
          query = query.orderBy(order['field']!, descending: order['direction'] == 'desc');
        }
      }
    }

    // SE OFFLINE-FIRST ESTÁ ATIVADO: tentar cache local primeiro
    if (_offlineFirstMode == true) {
      // Obter dados do cache
      final cachedData = await LocalCacheManager.queryCache(subcollection, {}, attributesWithOperators, orderBy);
      final items = cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'])).toList();

      // Se offline ou com dados no cache, retornar esses dados
      if (!isOnline || items.isNotEmpty) {
        return items;
      }
    }

    // SE NÃO TEMOS CACHE ou OFFLINE-FIRST ESTÁ DESATIVADO: buscar do Firestore
    if (!isOnline) return []; // Não podemos buscar do Firestore se estamos offline

    // Executar consulta com timeout apropriado
    Duration timeoutToUse = isOnline ? (timeout ?? _defaultTimeoutOnlineRead) : _defaultTimeoutOfflineRead;

    final querySnapshot = await _executeWithTimeout(
      () => query.get(),
      timeoutToUse,
    );

    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;

      // Se estamos no modo offline-first, atualizar o cache
      if (_offlineFirstMode == true) {
        if (!DataIntegrityManager.hasValidHash(itemData)) {
          itemData = await DataIntegrityManager.addFullMetadata(itemData);
        }

        await LocalCacheManager.updateCache(subcollection, doc.id, itemData);
      }

      result.add(fromMap(itemData, doc.id));
    }

    return result;
  }

  /// Obtém todos os itens de subcoleções
  Future<List<T>> _getAllFromSubcollections(String subcollection, {Duration? timeout}) async {
    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;

    Query<Map<String, dynamic>> query = FirebaseService.firestore.collectionGroup(subcollection);

    // Adicionar produtorId
    final String? activeProdutorId = _appStateManager.activeProdutorId;
    if (activeProdutorId != null && CollectionOptions.requiresProducerId(baseCollection)) {
      query = query.where('produtorId', isEqualTo: activeProdutorId);
    }

    // SE OFFLINE-FIRST ESTÁ ATIVADO: tentar cache local primeiro
    if (_offlineFirstMode == true) {
      // Obter dados do cache
      final cachedData = await LocalCacheManager.getAllFromCache(subcollection);
      final items = cachedData.where((data) => DataIntegrityManager.validateDataIntegrity(data)).map((data) => fromMap(data, data['id'])).toList();

      // Se offline ou com dados no cache, retornar esses dados
      if (!isOnline || items.isNotEmpty) {
        return items;
      }
    }

    // SE NÃO TEMOS CACHE ou OFFLINE-FIRST ESTÁ DESATIVADO: buscar do Firestore
    if (!isOnline) return []; // Não podemos buscar do Firestore se estamos offline

    // Executar consulta com timeout apropriado
    Duration timeoutToUse = isOnline ? (timeout ?? _defaultTimeoutOnlineRead) : _defaultTimeoutOfflineRead;

    final querySnapshot = await _executeWithTimeout(
      () => query.get(),
      timeoutToUse,
    );

    final result = <T>[];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      var itemData = Map<String, dynamic>.from(data);
      itemData['id'] = doc.id;

      // Se estamos no modo offline-first, atualizar o cache
      if (_offlineFirstMode == true) {
        if (!DataIntegrityManager.hasValidHash(itemData)) {
          itemData = await DataIntegrityManager.addFullMetadata(itemData);
        }

        await LocalCacheManager.updateCache(subcollection, doc.id, itemData);
      }

      result.add(fromMap(itemData, doc.id));
    }

    return result;
  }

  /// Verifica dependências para um item específico
  /// Verifica dependências para um item específico, incluindo dependências recursivas
  Future<Map<String, List<Map<String, dynamic>>>> verificarDependencias(
      String id,
      String collection,
      {Set<String>? processedIds,
        Map<String, List<Map<String, dynamic>>>? acumulador}) async {

    // Inicialização
    processedIds = processedIds ?? <String>{};
    acumulador = acumulador ?? <String, List<Map<String, dynamic>>>{};

    final documentKey = '$collection:$id';
    if (processedIds.contains(documentKey)) {
      return acumulador;
    }
    processedIds.add(documentKey);

    await _ensureInitialized();

    //print("Verificando dependências diretas de $collection:$id");

    // Parte 1: Encontrar todas as coleções que podem depender desta
    List<String> dependentCollections = CollectionOptions.getDependentCollections(collection, '${collection}Id');

    // Parte 2: Buscar documentos dependentes em cada coleção
    for (var dependentCollection in dependentCollections) {
      // Encontrar o nome do campo que faz referência à coleção atual
      String referenceField = '${collection}Id'; // Valor padrão

      // Verificar todos os campos da coleção dependente que apontam para a coleção atual
      final relationMap = CollectionOptions.collectionRelations[dependentCollection];
      if (relationMap != null) {
        for (var entry in relationMap.entries) {
          if (entry.value == collection) {
            referenceField = entry.key;
            break;
          }
        }
      }

      //print("Buscando em $dependentCollection documentos onde $referenceField == $id");

      // Tentar buscar no cache ou Firestore
      List<Map<String, dynamic>> dependentDocs = [];

      if (_offlineFirstMode == true) {
        // Buscar no cache
        dependentDocs = await LocalCacheManager.queryCache(dependentCollection, {referenceField: id});
      }

      if (_appStateManager.isOnline && (dependentDocs.isEmpty || !_offlineFirstMode)) {
        // Buscar no Firestore
        try {
          final querySnapshot = await _executeWithTimeout(
                  () => FirebaseService.firestore.collection(dependentCollection)
                  .where(referenceField, isEqualTo: id).get(),
              _defaultTimeoutOnlineRead
          );

          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              dependentDocs.add(data);

              // Atualizar cache se necessário
              if (_offlineFirstMode == true) {
                await LocalCacheManager.updateCache(dependentCollection, doc.id, data);
              }
            }
          }
        } catch (e) {
          print("Erro ao buscar dependências em $dependentCollection: $e");
        }
      }

      // Adicionar ao acumulador
      if (dependentDocs.isNotEmpty) {
        acumulador[dependentCollection] = acumulador[dependentCollection] ?? [];
        acumulador[dependentCollection]!.addAll(dependentDocs);

        //print("Encontrados ${dependentDocs.length} documentos em $dependentCollection");

        // PARTE 3: CHAMADA RECURSIVA - como no excluirComDependencias
        for (var doc in dependentDocs) {
          final docId = doc['id'] as String;
          final docKey = '$dependentCollection:$docId';

          if (!processedIds.contains(docKey)) {
            // Aqui está a chave - chamar recursivamente para cada dependência encontrada
            //print("Verificando recursivamente dependências de $dependentCollection:$docId");
            await verificarDependencias(
                docId,
                dependentCollection,
                processedIds: processedIds,
                acumulador: acumulador
            );
          }
        }
      }
    }

    //print("Concluída verificação de $collection:$id, total acumulado: ${acumulador.entries.map((e) => '${e.key}:${e.value.length}').join(', ')}");
    return acumulador;
  }

  /// Verifica dependências offline (apenas para modo offline-first)
  /// Verifica dependências offline (apenas para modo offline-first)
  Future<Map<String, List<Map<String, dynamic>>>> _verificarDependenciasOffline(
      String id,
      String collection,
      {Set<String>? processedIds,
        Map<String, List<Map<String, dynamic>>>? acumulador}) async {

    if (_offlineFirstMode != true) {
      return {}; // Se não estamos no modo offline-first, retornar vazio
    }

    // Inicialização
    processedIds = processedIds ?? <String>{};
    acumulador = acumulador ?? <String, List<Map<String, dynamic>>>{};

    final documentKey = '$collection:$id';
    if (processedIds.contains(documentKey)) {
      return acumulador;
    }
    processedIds.add(documentKey);

    // Encontrar todas as coleções que podem depender desta
    List<String> dependentCollections = CollectionOptions.getDependentCollections(collection, '${collection}Id');

    for (var dependentCollection in dependentCollections) {
      // Encontrar o nome do campo que faz referência à coleção atual
      String referenceField = '${collection}Id'; // Valor padrão

      // Verificar todos os campos da coleção dependente que apontam para a coleção atual
      final relationMap = CollectionOptions.collectionRelations[dependentCollection];
      if (relationMap != null) {
        for (var entry in relationMap.entries) {
          if (entry.value == collection) {
            referenceField = entry.key;
            break;
          }
        }
      }

      // Buscar no cache
      final cachedDocs = await LocalCacheManager.queryCache(dependentCollection, {referenceField: id});

      if (cachedDocs.isNotEmpty) {
        // Adicionar ao acumulador
        acumulador[dependentCollection] = acumulador[dependentCollection] ?? [];
        acumulador[dependentCollection]!.addAll(cachedDocs);

        // PARTE IMPORTANTE: Chamada recursiva para cada documento encontrado
        for (var doc in cachedDocs) {
          final docId = doc['id'] as String;
          final docKey = '$dependentCollection:$docId';

          if (!processedIds.contains(docKey)) {
            // Verificar recursivamente as dependências desta dependência
            await _verificarDependenciasOffline(
                docId,
                dependentCollection,
                processedIds: processedIds,
                acumulador: acumulador
            );
          }
        }
      }
    }

    return acumulador;
  }

  /// Exclui um item e todas as suas dependências
  /// Exclui um item e todas as suas dependências
  /// Exclui um item e todas as suas dependências recursivamente
  Future<void> excluirComDependencias(String id, String collection, {Set<String>? processedIds}) async {
    // Inicializar conjunto de IDs já processados se for a primeira chamada
    processedIds = processedIds ?? <String>{};

    // Evitar processamento duplicado
    final documentKey = '$collection:$id';
    if (processedIds.contains(documentKey)) {
      return;
    }
    processedIds.add(documentKey);

    await _ensureInitialized();
    final isOnline = _appStateManager.isOnline;
    Map<String, dynamic>? mainDocData;

    try {
      // Primeiro verificar dados críticos, quando possível
      if (_offlineFirstMode == true) {
        mainDocData = await LocalCacheManager.readFromCache(collection, id);
      } else if (isOnline) {
        try {
          final mainDoc = await _executeWithTimeout(
                () => FirebaseService.firestore.collection(collection).doc(id).get(),
            _defaultTimeoutOnlineRead,
          );
          if (mainDoc.exists && mainDoc.data() != null) {
            mainDocData = Map<String, dynamic>.from(mainDoc.data()!);
          }
        } catch (e) {
          if (e is TimeoutException) {
            print('Documento $id não pôde ser verificado, mas a exclusão será enfileirada.');
          } else {
            print('Erro ao buscar documento para exclusão: $e');
            return;
          }
        }
      }

      // Verificação de documento crítico quando temos os dados
      if (mainDocData != null && mainDocData.containsKey('cargaInicial')) {
        print('Aviso: Tentativa de excluir documento crítico (cargaInicial) com dependências interrompida: $id');
        return;
      }

      // Verificar dependências se possível
      Map<String, List<Map<String, dynamic>>> dependencias = {};
      try {
        dependencias = _offlineFirstMode == true || !isOnline ?
        await _verificarDependenciasOffline(id, collection) :
        await verificarDependencias(id, collection);

        // Verificar campos críticos nas dependências
        for (var entry in dependencias.entries) {
          for (var docData in entry.value) {
            if (docData.containsKey('cargaInicial')) {
              print('Aviso: Dependência contém campo crítico (cargaInicial), operação interrompida: ${docData['id']}');
              return;
            }
          }
        }
      } catch (e) {
        if (e is TimeoutException) {
          print('Não foi possível verificar dependências, mas a exclusão será enfileirada.');
        } else {
          print('Erro ao verificar dependências: $e');
          return;
        }
      }

      // Executar a exclusão
      if (_offlineFirstMode == true) {
        // Modo offline-first com Hive
        await LocalCacheManager.removeFromCache(collection, id);
        await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: collection,
          operationType: 'delete',
          docId: id,
          data: mainDocData ?? {},
          timestamp: DateTime.now(),
          produtorId: _appStateManager.activeProdutorId,
          priority: OperationPriority.HIGH,
        ));

        // Processar dependências recursivamente
        for (var entry in dependencias.entries) {
          final dependentCollection = entry.key;
          for (var docData in entry.value) {
            final docId = docData['id'] as String;

            // Chamar recursivamente para processar as dependências dessa dependência
            await excluirComDependencias(docId, dependentCollection, processedIds: processedIds);
          }
        }

        if (isOnline) {
          unawaited(OfflineQueueManager.processQueue());
        }
      } else {
        // Modo Firestore nativo - tentar mesmo offline, permitindo enfileiramento nativo
        try {
          // Excluir documento principal
          await _executeWithTimeout(
                () => FirebaseService.firestore.collection(collection).doc(id).delete(),
            isOnline ? _defaultTimeoutOnlineWrite : _defaultTimeoutOfflineWrite,
          );

          // Processar dependências recursivamente
          if (dependencias.isNotEmpty) {
            for (var entry in dependencias.entries) {
              final dependentCollection = entry.key;
              for (var docData in entry.value) {
                final docId = docData['id'] as String;

                // Chamar recursivamente para processar as dependências dessa dependência
                await excluirComDependencias(docId, dependentCollection, processedIds: processedIds);
              }
            }
          }

          print('Documento $id e suas dependências excluídos com sucesso ou enfileirados para sincronização.');
        } catch (e) {
          if (e is TimeoutException) {
            print('Operação de exclusão com dependências enfileirada para $id. Será sincronizada quando online.');
          } else {
            _handleOperationError(e, 'excluir com dependências');
          }
        }
      }
    } catch (e) {
      if (e is TimeoutException) {
        print('Operação de exclusão com dependências enfileirada para $id. Será sincronizada quando online.');
      } else {
        _handleOperationError(e, 'excluir com dependências');
      }
    }
  }
}
