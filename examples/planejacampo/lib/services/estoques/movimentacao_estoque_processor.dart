// V02
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mutex/mutex.dart';
import 'package:planejacampo/models/movimentacao_estoque.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_service.dart';
import 'package:planejacampo/services/estoques/processamento_status_service.dart';
import 'package:planejacampo/services/estoques/retry_handler_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';

class MovimentacaoEstoqueProcessor {
  static final MovimentacaoEstoqueProcessor _instance = MovimentacaoEstoqueProcessor._internal();

  // Serviços
  final MovimentacaoEstoqueProjetadaService _movimentacaoProjetadaService = MovimentacaoEstoqueProjetadaService();
  final MovimentacaoEstoqueService _movimentacaoEstoqueService = MovimentacaoEstoqueService();
  final ProcessamentoStatusService _processamentoStatusService = ProcessamentoStatusService();
  final AppStateManager _appStateManager = AppStateManager();
  final EstoqueService _estoqueService = EstoqueService();

  // Controle de concorrência
  final Mutex _processingMutex = Mutex();
  bool _isProcessing = false;

  // Timers e controle de retry
  Timer? _retryTimer;
  Timer? _processingTimeoutTimer;
  static const Duration _maxRetryInterval = Duration(minutes: 1);
  static const Duration _processingTimeout = Duration(minutes: 5);
  static const double _backoffMultiplier = 1.5;
  int _currentRetryMs = 1000;
  int _successfulOperations = 0;

  // Cache de movimentações em processamento para evitar duplicação
  final Set<String> _movimentacoesEmProcessamento = {};

  MovimentacaoEstoqueProcessor._internal();

  factory MovimentacaoEstoqueProcessor() {
    return _instance;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();

    // Reset do backoff após um número de operações bem-sucedidas
    if (_successfulOperations > 5) {
      _currentRetryMs = 1000;
      _successfulOperations = 0;
    } else {
      _currentRetryMs = min(
          (_currentRetryMs * _backoffMultiplier).toInt(),
          _maxRetryInterval.inMilliseconds
      );
    }

    // Jitter para evitar thundering herd
    final jitter = (_currentRetryMs * 0.1 * (Random().nextDouble() - 0.5)).toInt();
    final nextRetryMs = _currentRetryMs + jitter;

    print('Agendando próxima tentativa em ${nextRetryMs}ms');

    _retryTimer = Timer(Duration(milliseconds: nextRetryMs), () {
      processarMovimentacoesPendentes();
    });
  }

  Future<void> processarMovimentacoesPendentes() async {
    print('Verificando movimentações pendentes');

    // Adquirir mutex para garantir execução thread-safe
    if (_processingMutex.isLocked) {
      print("Processador em uso por outra thread, agendando retry");
      _scheduleRetry();
      return;
    }

    await _processingMutex.acquire();

    try {
      // Verificar se já está processando com proteção para timeout
      if (_isProcessing) {
        print("Já está processando, agendando retry");
        _scheduleRetry();
        return;
      }

      _isProcessing = true;

      // Configurar timer de segurança para resetar flag de processamento
      _processingTimeoutTimer?.cancel();
      _processingTimeoutTimer = Timer(_processingTimeout, () {
        print("Timeout de processamento atingido, resetando flag");
        _isProcessing = false;
      });

      // Verificar modo de operação e conectividade
      final bool isOfflineFirst = _appStateManager.isOfflineFirstEnabled;
      final bool isOnline = _appStateManager.isOnline;

      // Comportamento adaptado ao modo offline-first
      if (!isOnline && !isOfflineFirst) {
        print('Dispositivo offline e modo offline-first desativado, agendando retry');
        _scheduleRetry();
        return;
      }

      String deviceId = _appStateManager.deviceId;
      print("Buscando movimentações pendentes para device: $deviceId");

      // Buscar movimentações pendentes
      List<MovimentacaoEstoqueProjetada> movimentacoesPendentes;
      try {
        movimentacoesPendentes = await _movimentacaoProjetadaService.getByAttributes({
          'statusProcessamento': 'pendente',
          'deviceId': deviceId,
        });
      } catch (e) {
        print('Erro ao buscar movimentações pendentes: $e');
        _scheduleRetry();
        return;
      }

      if (movimentacoesPendentes.isEmpty) {
        print("Nenhuma movimentação pendente, resetando retry interval");
        _currentRetryMs = 1000;
        return;
      }

      // Agrupar movimentações por item/propriedade para processamento em lote
      Map<String, List<MovimentacaoEstoqueProjetada>> movimentacoesPorChave = {};

      for (var mov in movimentacoesPendentes) {
        // Pular movimentações que já estão em processamento
        if (_movimentacoesEmProcessamento.contains(mov.id)) {
          continue;
        }

        String key = '${mov.produtorId}-${mov.itemId}-${mov.propriedadeId}';
        movimentacoesPorChave.putIfAbsent(key, () => []).add(mov);
      }

      bool hasError = false;
      bool hasUnprocessed = false;
      int processadosNesteCiclo = 0;

      for (String key in movimentacoesPorChave.keys) {
        List<String> keyParts = key.split('-');
        print('Processando movimentações para produtor: ${keyParts[0]}, item: ${keyParts[1]}, propriedade: ${keyParts[2]}');

        try {
          bool processed = await _processarMovimentacoesItemPropriedade(
              keyParts[0], // produtorId
              keyParts[1], // itemId
              keyParts[2], // propriedadeId
              movimentacoesPorChave[key]!
          );

          if (processed) {
            processadosNesteCiclo += movimentacoesPorChave[key]!.length;
          } else {
            hasUnprocessed = true;
          }
        } catch (e) {
          print('Erro processando movimentações: $e');
          hasError = true;
          break;
        }
      }

      // Incrementar contador de sucesso se processou alguma movimentação
      if (processadosNesteCiclo > 0) {
        _successfulOperations += processadosNesteCiclo;
      }

      if (hasError || hasUnprocessed) {
        _scheduleRetry();
      } else {
        _currentRetryMs = 1000; // Reset retry interval on success
      }

    } finally {
      _isProcessing = false;
      _processingTimeoutTimer?.cancel();
      _processingMutex.release();

      String deviceId = _appStateManager.deviceId;
      bool debugMode = AppStateManager().debugMode;
      // Remover todas as movimentações de estoque projetadas com status 'processado'
      if (!debugMode) {
        print('Removendo movimentações de estoque projetadas processadas para o deviceId: $deviceId');
        await _movimentacaoProjetadaService.deleteByAttribute({
          'statusProcessamento': 'processado',
          'deviceId': deviceId,
        });
        print('Movimentações removidas com sucesso');
      }

    }
  }

  Future<bool> _processarMovimentacoesItemPropriedade(
      String produtorId,
      String itemId,
      String propriedadeId,
      List<MovimentacaoEstoqueProjetada> movimentacoes) async {

    String deviceId = _appStateManager.deviceId;

    // Tenta obter o lock com retry simples
    bool lockObtido = false;
    int tentativasLock = 0;

    while (!lockObtido && tentativasLock < 3) {
      lockObtido = await _processamentoStatusService.obterLockProcessamento(
          produtorId, itemId, propriedadeId, deviceId);

      if (!lockObtido) {
        tentativasLock++;
        if (tentativasLock < 3) {
          print('Tentativa $tentativasLock: Não foi possível obter o lock para produtor $produtorId, item $itemId e propriedade $propriedadeId, tentando novamente...');
          await Future.delayed(Duration(milliseconds: 500 * tentativasLock));
        }
      }
    }

    if (!lockObtido) {
      print('Não foi possível obter o lock para produtor $produtorId, item $itemId e propriedade $propriedadeId após $tentativasLock tentativas');
      return false;
    }

    try {
      // Filtrar movimentações nulas/inválidas primeiro
      movimentacoes = movimentacoes.where((m) =>
      m != null &&
          m.deviceId == deviceId &&
          m.statusProcessamento != 'processado' &&
          !_movimentacoesEmProcessamento.contains(m.id)
      ).toList();

      if (movimentacoes.isEmpty) {
        print('Nenhuma movimentação pendente para processar após filtragem');
        return true;
      }

      // Marcar movimentações como em processamento
      for (var mov in movimentacoes) {
        _movimentacoesEmProcessamento.add(mov.id);
      }

      // Ordenar as movimentações
      movimentacoes = _ordenarMovimentacoes(movimentacoes);

      // Verificar modo offline-first
      final bool isOfflineFirst = _appStateManager.isOfflineFirstEnabled;
      final bool isOnline = _appStateManager.isOnline;

      // Se offline-first e offline, enfileirar para processamento posterior
      if (isOfflineFirst && !isOnline) {
        return await _processarOfflineFirst(movimentacoes);
      }

      // Processar as movimentações
      bool todosSucesso = true;
      for (MovimentacaoEstoqueProjetada movProj in movimentacoes) {
        try {
          bool sucesso = await _processarMovimentacaoAtomica(movProj);
          if (!sucesso) {
            todosSucesso = false;
          }
        } catch (e) {
          print('Erro processando movimentação ${movProj.id}: $e');
          todosSucesso = false;
          // Continuar processando outras movimentações mesmo que uma falhe
        } finally {
          // Remover da lista de em processamento mesmo em caso de erro
          _movimentacoesEmProcessamento.remove(movProj.id);
        }
      }

      return todosSucesso;
    } finally {
      try {
        // Garantir liberação do lock mesmo em caso de erro
        await _processamentoStatusService.liberarProcessamento(produtorId, itemId, propriedadeId);

        // Garantir remoção de todas as movimentações da lista de processamento
        for (var mov in movimentacoes) {
          _movimentacoesEmProcessamento.remove(mov.id);
        }
      } catch (e) {
        print('Erro ao liberar processamento: $e');
      }
    }
  }

  List<MovimentacaoEstoqueProjetada> _ordenarMovimentacoes(List<MovimentacaoEstoqueProjetada> movimentacoes) {
    // Primeiro separar estornos de operações normais
    final estornos = movimentacoes.where((m) => m.categoria.startsWith('Estorno')).toList();
    final operacoesNormais = movimentacoes.where((m) => !m.categoria.startsWith('Estorno')).toList();

    // Ordenar operações normais
    operacoesNormais.sort((a, b) {
      int compareData = a.data.compareTo(b.data);
      if (compareData == 0) {
        // Se mesma data, entrada vem antes de saída
        int compareTipo = (a.tipo == 'Entrada' ? 0 : 1).compareTo(b.tipo == 'Entrada' ? 0 : 1);
        if (compareTipo == 0) {
          return a.timestampLocal.compareTo(b.timestampLocal);
        }
        return compareTipo;
      }
      return compareData;
    });

    // Ordenar estornos - ordem inversa das operações normais!
    estornos.sort((a, b) {
      int compareData = a.data.compareTo(b.data);
      if (compareData == 0) {
        // Para estornos, saída (EstornoConsumo) vem antes de entrada (EstornoCompra)
        int compareTipo = (a.tipo == 'Saida' ? 0 : 1).compareTo(b.tipo == 'Saida' ? 0 : 1);
        if (compareTipo == 0) {
          return a.timestampLocal.compareTo(b.timestampLocal);
        }
        return compareTipo;
      }
      return compareData;
    });

    // Combinar processando as operações normais e depois os estornos
    return [...operacoesNormais, ...estornos];
  }

  // Implementação para offline-first
  Future<bool> _processarOfflineFirst(List<MovimentacaoEstoqueProjetada> movimentacoes) async {
    print('Processando ${movimentacoes.length} movimentações em modo offline-first');

    String? transactionId;
    try {
      // Iniciar transação lógica para garantir atomicidade
      transactionId = await OfflineQueueManager.beginTransaction();

      for (var movProj in movimentacoes) {
        try {
          // 1. Atualizar status para em_processamento
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'movimentacoesEstoqueProjetadas',
              operationType: 'update',
              docId: movProj.id,
              data: {
                'statusProcessamento': 'em_processamento',
                'transacaoId': transactionId
              },
              timestamp: DateTime.now(),
              produtorId: movProj.produtorId,
              priority: OperationPriority.HIGH
          ));

          // 2. Simular a criação de uma movimentação real
          String idMovimentacaoReal = DateTime.now().millisecondsSinceEpoch.toString() + '_' + movProj.id;
          MovimentacaoEstoque movimentacaoReal = MovimentacaoEstoque(
            id: idMovimentacaoReal,
            propriedadeId: movProj.propriedadeId,
            itemId: movProj.itemId,
            produtorId: movProj.produtorId,
            quantidade: movProj.quantidade,
            valorUnitario: movProj.valorUnitario,
            tipo: movProj.tipo,
            categoria: movProj.categoria,
            data: movProj.data,
            timestamp: DateTime.now().toUtc(),
            unidadeMedida: movProj.unidadeMedida,
            estoqueAtual: 0, // Será calculado quando online
            cmpAtual: movProj.valorUnitario, // Valor estimado
            unidadeMedidaCMP: movProj.unidadeMedidaCMP,
            origemId: movProj.origemId,
            origemTipo: movProj.origemTipo,
            ativo: movProj.ativo,
          );

          // 3. Enfileirar operação para criar movimentação real quando online
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'movimentacoesEstoque',
              operationType: 'add',
              docId: idMovimentacaoReal,
              data: movimentacaoReal.toMap(),
              timestamp: DateTime.now(),
              produtorId: movProj.produtorId,
              priority: OperationPriority.HIGH
          ));

          // 4. Atualizar status da movimentação projetada
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'movimentacoesEstoqueProjetadas',
              operationType: 'update',
              docId: movProj.id,
              data: {
                'statusProcessamento': 'processado',
                'dataProcessamento': DateTime.now().toIso8601String(),
                'idMovimentacaoReal': idMovimentacaoReal,
              },
              timestamp: DateTime.now(),
              produtorId: movProj.produtorId,
              priority: OperationPriority.HIGH
          ));

          // 5. Atualizar cache local para refletir o processamento
          await _atualizarCacheOffline(movProj, idMovimentacaoReal);
        } catch (e) {
          print('Erro ao processar movimentação offline ${movProj.id}: $e');

          // Marcar com erro
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'movimentacoesEstoqueProjetadas',
              operationType: 'update',
              docId: movProj.id,
              data: {
                'statusProcessamento': 'erro',
                'erroProcessamento': e.toString(),
              },
              timestamp: DateTime.now(),
              produtorId: movProj.produtorId,
              priority: OperationPriority.HIGH
          ));

          return false;
        }
      }

      // Finalizar transação lógica
      if (transactionId != null) {
        await OfflineQueueManager.commitTransaction();
      }

      return true;
    } catch (e) {
      print('Erro geral no processamento offline-first: $e');
      return false;
    }
  }

  // Atualizar o cache em modo offline
  Future<void> _atualizarCacheOffline(MovimentacaoEstoqueProjetada movProj, String idMovimentacaoReal) async {
    try {
      // 1. Atualizar cache da movimentação projetada
      final dadosAtualizadosProj = {
        'id': movProj.id,
        'statusProcessamento': 'processado',
        'dataProcessamento': DateTime.now().toIso8601String(),
        'idMovimentacaoReal': idMovimentacaoReal,
        // Outros campos da movimentação original mantidos no cache
        'produtorId': movProj.produtorId,
        'data': Timestamp.fromDate(movProj.data),
        'itemId': movProj.itemId,
        'propriedadeId': movProj.propriedadeId,
        'tipo': movProj.tipo,
        'quantidade': movProj.quantidade,
        'valorUnitario': movProj.valorUnitario,
        'categoria': movProj.categoria,
        'origemId': movProj.origemId,
        'origemTipo': movProj.origemTipo,
        'unidadeMedida': movProj.unidadeMedida,
        'ativo': movProj.ativo,
        'saldoProjetado': movProj.saldoProjetado,
        'cmpProjetado': movProj.cmpProjetado,
        'timestampLocal': Timestamp.fromDate(movProj.timestampLocal),
        'deviceId': movProj.deviceId,
      };

      await LocalCacheManager.updateCache(
          'movimentacoesEstoqueProjetadas',
          movProj.id,
          dadosAtualizadosProj
      );

      print('Cache offline atualizado para movimentação projetada ${movProj.id}');

      // 2. Criar entrada no cache para a movimentação real
      final movReal = {
        'id': idMovimentacaoReal,
        'produtorId': movProj.produtorId,
        'itemId': movProj.itemId,
        'propriedadeId': movProj.propriedadeId,
        'tipo': movProj.tipo,
        'quantidade': movProj.quantidade,
        'valorUnitario': movProj.valorUnitario,
        'categoria': movProj.categoria,
        'data': Timestamp.fromDate(movProj.data),
        'timestamp': Timestamp.fromDate(DateTime.now().toUtc()),
        'unidadeMedida': movProj.unidadeMedida,
        'estoqueAtual': movProj.saldoProjetado,
        'cmpAtual': movProj.cmpProjetado,
        'unidadeMedidaCMP': movProj.unidadeMedidaCMP,
        'origemId': movProj.origemId,
        'origemTipo': movProj.origemTipo,
        'ativo': movProj.ativo,
      };

      await LocalCacheManager.updateCache(
          'movimentacoesEstoque',
          idMovimentacaoReal,
          movReal
      );

      print('Cache offline criado para movimentação real $idMovimentacaoReal');
    } catch (e) {
      print('Erro ao atualizar cache offline: $e');
    }
  }

  // Atualizar o cache após processamento online
  Future<void> _atualizarCacheAposProcessamento(MovimentacaoEstoqueProjetada movProj) async {
    try {
      // 1. Buscar a movimentaçãoEstoqueProjetada atualizada
      final movProjRef = _movimentacaoProjetadaService.getDocumentReference(movProj.id);
      final docSnapshotProj = await movProjRef.get();

      if (docSnapshotProj.exists) {
        final dadosAtualizadosProj = docSnapshotProj.data()!;

        // 2. Verificar se foi processado com sucesso e tem ID da movimentação real
        if (dadosAtualizadosProj['statusProcessamento'] == 'processado' &&
            dadosAtualizadosProj['idMovimentacaoReal'] != null) {

          // 3. Atualizar MovimentacaoEstoqueProjetada no cache
          await LocalCacheManager.updateCache(
              'movimentacoesEstoqueProjetadas',
              movProj.id,
              dadosAtualizadosProj
          );

          print('Cache local atualizado para movimentação projetada ${movProj.id}');

          // 4. Buscar e atualizar a MovimentacaoEstoque correspondente
          final idMovimentacaoReal = dadosAtualizadosProj['idMovimentacaoReal'];
          try {
            final docRefMovReal = _movimentacaoEstoqueService.getDocumentReference(idMovimentacaoReal);
            final docSnapshotReal = await docRefMovReal.get();

            if (docSnapshotReal.exists) {
              // 5. Atualizar MovimentacaoEstoque no cache
              await LocalCacheManager.updateCache(
                  'movimentacoesEstoque',
                  idMovimentacaoReal,
                  docSnapshotReal.data()!
              );

              print('Cache local atualizado para movimentação real $idMovimentacaoReal');
            }
          } catch (innerError) {
            print('Erro ao atualizar cache da movimentação real: $innerError');
          }
        }
      }
    } catch (e) {
      print('Erro ao atualizar cache local: $e');
    }
  }

  Future<bool> _processarMovimentacaoAtomica(MovimentacaoEstoqueProjetada movProj) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> movProjRef =
    _movimentacaoProjetadaService.getDocumentReference(movProj.id);
    final stopwatch = Stopwatch()..start();
    bool processamentoSucesso = false;

    // Variáveis para armazenar valores calculados para uso fora da transação
    double novoSaldoFinal = 0.0;
    double novoCMPFinal = 0.0;

    try {
      bool transactionResult = await RetryHandlerService.run(
          operation: () async {
            return await firestore.runTransaction((transaction) async {
              try {
                //-----------------------------------------------------
                // FASE 1: TODAS AS LEITURAS (GET)
                //-----------------------------------------------------

                // Leitura 1: Verificar a movimentação projetada
                final DocumentSnapshot<Map<String, dynamic>> movProjSnapshot =
                await transaction.get(movProjRef);

                if (!movProjSnapshot.exists) {
                  throw Exception('Movimentação projetada não encontrada: ${movProj.id}');
                }

                MovimentacaoEstoqueProjetada movProjTrans =
                MovimentacaoEstoqueProjetada.fromMap(movProjSnapshot.data()!, movProjSnapshot.id);

                // Verificar se já foi processada
                if (movProjTrans.statusProcessamento == 'processado' ||
                    movProjTrans.idMovimentacaoReal != null) {
                  return true;
                }

                // Leitura 2: Buscar movimentações originais para estornos
                bool isEstorno = movProjTrans.categoria.startsWith('Estorno');
                List<DocumentSnapshot<Map<String, dynamic>>> movsOriginaisDocs = [];
                DocumentSnapshot<Map<String, dynamic>>? movimentacaoOriginalDoc;

                if (isEstorno) {
                  final QuerySnapshot<Map<String, dynamic>> movOriginaisQuery = await firestore
                      .collection('movimentacoesEstoque')
                      .where('propriedadeId', isEqualTo: movProjTrans.propriedadeId)
                      .where('itemId', isEqualTo: movProjTrans.itemId)
                      .where('origemId', isEqualTo: movProjTrans.origemId)
                      .where('origemTipo', isEqualTo: movProjTrans.origemTipo)
                      .get();

                  movsOriginaisDocs = movOriginaisQuery.docs;

                  // Guardar referência à movimentação original para uso posterior
                  if (movsOriginaisDocs.isNotEmpty) {
                    movimentacaoOriginalDoc = movsOriginaisDocs.first;
                  }
                }

                // Leitura 3: Verificar documento de estoque (leitura antecipada)
                String estoqueId = "${movProjTrans.produtorId}-${movProjTrans.itemId}-${movProjTrans.propriedadeId}";
                DocumentReference estoqueRef = firestore.collection('estoques').doc(estoqueId);
                DocumentSnapshot estoqueDoc = await transaction.get(estoqueRef);

                // Leitura 4: Buscar movimentações posteriores
                List<DocumentSnapshot<Map<String, dynamic>>> movsPosterioresDocs = [];

                // CORREÇÃO: Se for estorno, buscar movimentações posteriores à original sendo estornada
                if (isEstorno && movimentacaoOriginalDoc != null) {
                  // Usar data e timestamp da movimentação original
                  final Timestamp dataOriginalTs = movimentacaoOriginalDoc.data()!['data'] as Timestamp;
                  final Timestamp timestampOriginalTs = movimentacaoOriginalDoc.data()!['timestamp'] as Timestamp;
                  final DateTime dataOriginal = dataOriginalTs.toDate();
                  final DateTime timestampOriginal = timestampOriginalTs.toDate();

                  final QuerySnapshot<Map<String, dynamic>> movPosterioresQuery = await firestore
                      .collection('movimentacoesEstoque')
                      .where('propriedadeId', isEqualTo: movProjTrans.propriedadeId)
                      .where('itemId', isEqualTo: movProjTrans.itemId)
                      .where('ativo', isEqualTo: true)
                      .where('data', isGreaterThanOrEqualTo: dataOriginalTs)
                      .orderBy('data')
                      .orderBy('timestamp')
                      .get();

                  // Filtrar movimentações com base no timestamp da original
                  movsPosterioresDocs = movPosterioresQuery.docs.where((doc) {
                    final dataDoc = (doc.data()['data'] as Timestamp).toDate();
                    final timestampDoc = (doc.data()['timestamp'] as Timestamp).toDate();

                    // Incluir como posterior se:
                    // 1. É posterior na data
                    if (dataDoc.isAfter(dataOriginal)) return true;

                    // 2. É do mesmo dia, mas timestamp posterior
                    if (dataDoc.year == dataOriginal.year &&
                        dataDoc.month == dataOriginal.month &&
                        dataDoc.day == dataOriginal.day) {
                      return timestampDoc.isAfter(timestampOriginal);
                    }

                    return false;
                  }).toList();
                }
                // Caso não seja estorno, continua com a lógica original
                else {
                  final QuerySnapshot<Map<String, dynamic>> movPosterioresQuery = await firestore
                      .collection('movimentacoesEstoque')
                      .where('propriedadeId', isEqualTo: movProjTrans.propriedadeId)
                      .where('itemId', isEqualTo: movProjTrans.itemId)
                      .where('ativo', isEqualTo: true)
                      .where('origemId', isNotEqualTo: movProjTrans.origemId)
                      .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(movProjTrans.data))
                      .orderBy('data')
                      .orderBy('timestamp')
                      .get();

                  movsPosterioresDocs = movPosterioresQuery.docs.where((doc) {
                    final dataDoc = (doc.data()['data'] as Timestamp).toDate();
                    final timestampDoc = (doc.data()['timestamp'] as Timestamp).toDate();

                    if (dataDoc.isAfter(movProjTrans.data)) return true;
                    if (dataDoc.isAtSameMomentAs(movProjTrans.data)) {
                      return timestampDoc.isAfter(movProjTrans.timestampLocal);
                    }
                    return false;
                  }).toList();
                }

                //-----------------------------------------------------
                // FASE 2: CÁLCULOS E PREPARAÇÃO (SEM LEITURAS OU ESCRITAS)
                //-----------------------------------------------------

                // CORREÇÃO: Buscar estoque anterior apropriado
                Map<String, dynamic> estoqueAnterior;

                if (isEstorno && movimentacaoOriginalDoc != null) {
                  // Para estornos, buscar o estoque ANTERIOR à movimentação original
                  estoqueAnterior = await _buscarEstoqueAnteriorAMovimentacaoOriginal(
                      firestore, movimentacaoOriginalDoc, movProjTrans);
                } else {
                  // Buscar movimentações anteriores diretamente dentro da transação (lógica original)
                  final QuerySnapshot<Map<String, dynamic>> movAnterioresQuery = await firestore
                      .collection('movimentacoesEstoque')
                      .where('propriedadeId', isEqualTo: movProjTrans.propriedadeId)
                      .where('itemId', isEqualTo: movProjTrans.itemId)
                      .where('ativo', isEqualTo: true)
                      .where('data', isLessThanOrEqualTo: Timestamp.fromDate(movProjTrans.data))
                      .orderBy('data', descending: true)
                      .orderBy('timestamp', descending: true)
                      .limit(5) // Limitamos para aumentar a performance
                      .get();

                  // Filtramos movimentações pelo timestamp se a data for a mesma
                  List<DocumentSnapshot<Map<String, dynamic>>> movsAnteriores = movAnterioresQuery.docs
                      .where((doc) {
                    // Obter dados do documento - verificação de nulidade
                    final Map<String, dynamic>? docData = doc.data();
                    if (docData == null) return false;

                    // Ignorar movimentações da mesma origem (para estornos)
                    if (movProjTrans.origemId != null &&
                        movProjTrans.origemId == docData['origemId']) {
                      return false;
                    }

                    final Timestamp? docDataTs = docData['data'] as Timestamp?;
                    if (docDataTs == null) return false;

                    final DateTime docDate = docDataTs.toDate();

                    // Se for data anterior, sempre inclui
                    if (docDate.isBefore(movProjTrans.data)) {
                      return true;
                    }

                    // Se for a mesma data, verifica o timestamp
                    if (docDate.year == movProjTrans.data.year &&
                        docDate.month == movProjTrans.data.month &&
                        docDate.day == movProjTrans.data.day) {

                      final Timestamp? docTimestampTs = docData['timestamp'] as Timestamp?;
                      if (docTimestampTs == null) return false;

                      final DateTime docTimestamp = docTimestampTs.toDate();
                      return docTimestamp.isBefore(movProjTrans.timestampLocal);
                    }

                    return false;
                  })
                      .toList();

                  // Construir o objeto estoqueAnterior usando o formato esperado
                  estoqueAnterior = {
                    'quantidade': 0.0,
                    'unidadeMedida': '',
                    'cmp': 0.0,
                    'unidadeMedidaCMP': '',
                    'dataUltimaAtualizacao': movProjTrans.data,
                    'origem': 'novo'
                  };

                  if (movsAnteriores.isNotEmpty) {
                    final lastMov = movsAnteriores.first;
                    final Map<String, dynamic>? lastMovData = lastMov.data();

                    if (lastMovData != null) {
                      estoqueAnterior = {
                        'quantidade': lastMovData['estoqueAtual'] ?? 0.0,
                        'unidadeMedida': lastMovData['unidadeMedida'] ?? '',
                        'cmp': lastMovData['cmpAtual'] ?? 0.0,
                        'unidadeMedidaCMP': lastMovData['unidadeMedidaCMP'] ?? '',
                        'dataUltimaAtualizacao': (lastMovData['data'] as Timestamp?)?.toDate() ?? movProjTrans.data,
                        'origem': 'movimentacaoEstoque'
                      };

                      print('Encontrada movimentação anterior dentro da transação: ' +
                          'ID=${lastMov.id}, estoqueAtual=${estoqueAnterior['quantidade']}, ' +
                          'tipo=${lastMovData['tipo'] ?? 'desconhecido'}, data=${estoqueAnterior['dataUltimaAtualizacao']}');
                    }
                  }
                }

                // Cálculo de saldo e CMP
                double novoSaldo;
                double novoCMP;

                if (isEstorno) {
                  print('Calculando saldo e CMP para estorno...');

                  // CORREÇÃO: Usar saldo obtido da movimentação anterior à original para recalcular
                  if (movProjTrans.tipo == 'Entrada') { // EstornoConsumo
                    // Para EstornoConsumo, ajustar o saldo conforme necessário
                    novoSaldo = estoqueAnterior['quantidade'];
                    novoCMP = estoqueAnterior['cmp']; // Mantém o CMP anterior
                  } else { // EstornoCompra
                    // CORREÇÃO: Para EstornoCompra, usar o saldo anterior à movimentação original
                    novoSaldo = estoqueAnterior['quantidade'];
                    novoCMP = estoqueAnterior['cmp'];
                  }
                } else {
                  print('Calculando saldo e CMP para movimentação normal...');
                  if (movProjTrans.tipo == 'Entrada') {
                    novoSaldo = estoqueAnterior['quantidade'] + movProjTrans.quantidade;
                    // Evitar divisão por zero
                    if (novoSaldo > 0) {
                      novoCMP = ((estoqueAnterior['quantidade'] * estoqueAnterior['cmp']) +
                          (movProjTrans.quantidade * movProjTrans.valorUnitario)) / novoSaldo;
                    } else {
                      novoCMP = movProjTrans.valorUnitario;
                    }
                  } else { // Saída
                    novoSaldo = estoqueAnterior['quantidade'] - movProjTrans.quantidade;
                    novoCMP = estoqueAnterior['cmp']; // Mantém o CMP em saídas
                  }
                }
                print('Novo saldo: $novoSaldo, Novo CMP: $novoCMP');

                // Preparar nova movimentação real
                String idMovimentacaoReal = _movimentacaoEstoqueService.getNewDocumentReference().id;
                DocumentReference movRealRef = _movimentacaoEstoqueService.getDocumentReference(idMovimentacaoReal);

                MovimentacaoEstoque movimentacaoReal = MovimentacaoEstoque(
                  id: idMovimentacaoReal,
                  propriedadeId: movProjTrans.propriedadeId,
                  itemId: movProjTrans.itemId,
                  produtorId: movProjTrans.produtorId,
                  quantidade: movProjTrans.quantidade,
                  valorUnitario: movProjTrans.valorUnitario,
                  tipo: movProjTrans.tipo,
                  categoria: movProjTrans.categoria,
                  data: movProjTrans.data,
                  timestamp: DateTime.now().toUtc(),
                  unidadeMedida: movProjTrans.unidadeMedida,
                  estoqueAtual: novoSaldo,
                  cmpAtual: novoCMP,
                  unidadeMedidaCMP: movProjTrans.unidadeMedidaCMP,
                  origemId: movProjTrans.origemId,
                  origemTipo: movProjTrans.origemTipo,
                  ativo: isEstorno ? false : movProjTrans.ativo, // CORREÇÃO: Estornos sempre inativos
                );

                // Salvar valores para uso após a transação
                novoSaldoFinal = novoSaldo;
                novoCMPFinal = novoCMP;
                print('Novo saldo final: $novoSaldoFinal, Novo CMP final: $novoCMPFinal');

                //-----------------------------------------------------
                // FASE 3: TODAS AS ESCRITAS (UPDATE/SET)
                //-----------------------------------------------------

                // Escrita 1: Atualizar status da movimentação projetada para "processando"
                transaction.update(movProjRef, {
                  'statusProcessamento': 'em_processamento',
                });

                // Escrita 2: Inativar movimentações originais em caso de estorno
                if (isEstorno && movsOriginaisDocs.isNotEmpty) {
                  for (var doc in movsOriginaisDocs) {
                    // CORREÇÃO: Apenas marcar como inativo, SEM ALTERAR outros valores
                    transaction.update(doc.reference, {'ativo': false});
                  }
                }

                // Escrita 3: Criar a nova movimentação real
                transaction.set(movRealRef, _movimentacaoEstoqueService.toMap(movimentacaoReal));

                // Escrita 4: Atualizar/criar documento de estoque
                if (estoqueDoc.exists) {
                  transaction.update(estoqueRef, {
                    'quantidade': novoSaldo,
                    'cmp': novoCMP,
                    'ultimaAtualizacaoCmp': FieldValue.serverTimestamp(),
                  });
                } else {
                  // Criar documento se não existir
                  transaction.set(estoqueRef, {
                    'id': estoqueId,
                    'itemId': movProjTrans.itemId,
                    'produtorId': movProjTrans.produtorId,
                    'propriedadeId': movProjTrans.propriedadeId,
                    'quantidade': novoSaldo,
                    'unidadeMedida': movProjTrans.unidadeMedida,
                    'cmp': novoCMP,
                    'unidadeMedidaCmp': movProjTrans.unidadeMedidaCMP,
                    'ultimaAtualizacaoCmp': FieldValue.serverTimestamp(),
                    'emProcessamento': false,
                  });
                }

                // Escrita 5: Recalcular e atualizar movimentações posteriores
                print('Escrita 5: Recalcular e atualizar movimentações posteriores');
                if (movsPosterioresDocs.isNotEmpty) {
                  print('-------------------- Atualizando movimentações posteriores...');
                  double saldoAtual = novoSaldo;
                  double cmpAtual = novoCMP;

                  // Log detalhado para depuração
                  print('Início do recálculo com saldoAtual=$saldoAtual, cmpAtual=$cmpAtual');
                  print('Total de movimentações posteriores a processar: ${movsPosterioresDocs.length}');

                  // CORREÇÃO: Ordenar movimentações cronologicamente para garantir recálculo correto
                  movsPosterioresDocs.sort((a, b) {
                    final dataA = (a.data()!['data'] as Timestamp).toDate();
                    final dataB = (b.data()!['data'] as Timestamp).toDate();

                    int dataCompare = dataA.compareTo(dataB);
                    if (dataCompare != 0) return dataCompare;

                    final timestampA = (a.data()!['timestamp'] as Timestamp).toDate();
                    final timestampB = (b.data()!['timestamp'] as Timestamp).toDate();
                    return timestampA.compareTo(timestampB);
                  });

                  for (var doc in movsPosterioresDocs) {
                    try {
                      print('Processando movimentação posterior: ${doc.id}');

                      // Pular a movimentação que acabamos de criar
                      if (doc.id == idMovimentacaoReal) {
                        print('Pulando movimentação que acabamos de criar: ${doc.id}');
                        continue;
                      }

                      Map<String, dynamic>? data = doc.data();
                      if (data == null) {
                        print('Dados nulos para movimentação ${doc.id}, pulando...');
                        continue;
                      }

                      // Verificações adicionais para maior segurança
                      if (!data.containsKey('tipo') || !data.containsKey('quantidade') || !data.containsKey('estoqueAtual')) {
                        print('Dados incompletos para movimentação ${doc.id}, pulando...');
                        continue;
                      }

                      String tipo = data['tipo'];
                      double quantidade = (data['quantidade'] as num).toDouble();
                      double valorUnitario = (data['valorUnitario'] as num?)?.toDouble() ?? 0.0;
                      double saldoOriginal = (data['estoqueAtual'] as num).toDouble();

                      print('Movimentação ${doc.id}: tipo=$tipo, quantidade=$quantidade, saldoOriginal=$saldoOriginal');

                      // Recalcular saldo
                      if (tipo == 'Entrada') {
                        saldoAtual += quantidade;
                        if (saldoAtual > 0) {
                          cmpAtual = ((saldoAtual - quantidade) * cmpAtual + quantidade * valorUnitario) / saldoAtual;
                        }
                      } else { // Saída
                        saldoAtual -= quantidade;
                      }

                      print('Atualizando movimentação ${doc.id}: saldoOriginal=$saldoOriginal -> novo saldo=$saldoAtual');

                      // CRÍTICO: Atualizar explicitamente a movimentação e verificar
                      transaction.update(doc.reference, {
                        'estoqueAtual': saldoAtual,
                        'cmpAtual': cmpAtual
                      });

                      print('Atualização preparada para movimentação ${doc.id} com saldo=${saldoAtual}');
                    } catch (updateError) {
                      print('ERRO ao processar movimentação ${doc.id}: $updateError');
                      // Continue para não interromper outras atualizações
                    }
                  }

                  print('Recálculo finalizado: saldoFinal=$saldoAtual, cmpFinal=$cmpAtual');

                  // Atualizar as variáveis finais com os valores após recálculo
                  novoSaldoFinal = saldoAtual;
                  novoCMPFinal = cmpAtual;
                } else {
                  print('Nenhuma movimentação posterior encontrada para recalcular');
                  // Se não houver movimentações posteriores, manter os valores da movimentação atual
                  novoSaldoFinal = novoSaldo;
                  novoCMPFinal = novoCMP;
                }

                // Escrita 6: Finalizar o processamento da movimentação projetada
                transaction.update(movProjRef, {
                  'statusProcessamento': 'processado',
                  'idMovimentacaoReal': idMovimentacaoReal,
                  'dataProcessamento': FieldValue.serverTimestamp(),
                });

                return true;  // Transação bem-sucedida
              } catch (error) {
                // Registrar erro no processamento
                print('Erro durante transação: ${error.toString()}');

                // Atualizar status da movimentação para erro (última escrita)
                transaction.update(movProjRef, {
                  'statusProcessamento': 'erro',
                  'erroProcessamento': error.toString(),
                });

                return false;  // Transação falhou
              }
            });
          },
          maxAttempts: 3,
          shouldRetry: (e) {
            // Define quais exceções devem resultar em retry
            return e is TimeoutException ||
                (e is FirebaseException &&
                    (e.code == 'unavailable' ||
                        e.code == 'deadline-exceeded' ||
                        e.code == 'aborted'));
          },
          initialDelayMs: 1000,
          backoffMultiplier: 2.0
      );

      processamentoSucesso = transactionResult;

      // SOLUÇÃO CRÍTICA: Garantir a atualização do documento de estoque mesmo fora da transação
      if (processamentoSucesso) {
        try {
          // Chamar ajustarEstoque explicitamente para garantir que o documento seja criado
          await _estoqueService.ajustarEstoque(
              movProj.produtorId,
              movProj.propriedadeId,
              movProj.itemId,
              novoSaldoFinal,
              novoCMPFinal,
              movProj.unidadeMedida
          );
          print('Documento de estoque atualizado explicitamente: ' +
              '${movProj.produtorId}-${movProj.itemId}-${movProj.propriedadeId}');
        } catch (e) {
          print('Erro ao atualizar documento de estoque explicitamente: $e');
          // Não falhar o método por causa disso
        }
      }

      return processamentoSucesso;
    } catch (finalError) {
      print('Erro final após todas as tentativas no processamento da movimentação ${movProj.id}: $finalError');
      return false;  // Falha em caso de erro não recuperável
    } finally {
      final processingTime = stopwatch.elapsedMilliseconds;
      print('Processamento da movimentação ${movProj.id} finalizado em ${processingTime}ms');
    }
  }

  // Método auxiliar para buscar o estoque anterior à movimentação original sendo estornada
  Future<Map<String, dynamic>> _buscarEstoqueAnteriorAMovimentacaoOriginal(
      FirebaseFirestore firestore,
      DocumentSnapshot<Map<String, dynamic>> movimentacaoOriginalDoc,
      MovimentacaoEstoqueProjetada movProjTrans) async {

    // Extrair dados da movimentação original
    final Map<String, dynamic> movOriginalData = movimentacaoOriginalDoc.data()!;
    final DateTime dataOriginal = (movOriginalData['data'] as Timestamp).toDate();
    final DateTime timestampOriginal = (movOriginalData['timestamp'] as Timestamp).toDate();

    // Buscar movimentações anteriores à original
    final QuerySnapshot<Map<String, dynamic>> movAnteriorQuery = await firestore
        .collection('movimentacoesEstoque')
        .where('propriedadeId', isEqualTo: movProjTrans.propriedadeId)
        .where('itemId', isEqualTo: movProjTrans.itemId)
        .where('ativo', isEqualTo: true)
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(dataOriginal))
        .orderBy('data', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    // Filtrar para obter apenas as anteriores à original
    final List<DocumentSnapshot<Map<String, dynamic>>> movAnteriores = movAnteriorQuery.docs
        .where((doc) {
      if (doc.id == movimentacaoOriginalDoc.id) return false;

      final dataDoc = (doc.data()!['data'] as Timestamp).toDate();
      if (dataDoc.isBefore(dataOriginal)) return true;

      if (dataDoc.isAtSameMomentAs(dataOriginal)) {
        final timestampDoc = (doc.data()!['timestamp'] as Timestamp).toDate();
        return timestampDoc.isBefore(timestampOriginal);
      }

      return false;
    })
        .toList();

    // Construir o objeto de retorno
    Map<String, dynamic> resultado = {
      'quantidade': 0.0,
      'unidadeMedida': '',
      'cmp': 0.0,
      'unidadeMedidaCMP': '',
      'dataUltimaAtualizacao': dataOriginal,
      'origem': 'novo'
    };

    // Se encontrou movimentação anterior, usar seus dados
    if (movAnteriores.isNotEmpty) {
      final movAnterior = movAnteriores.first;
      final movAnteriorData = movAnterior.data()!;

      resultado = {
        'quantidade': movAnteriorData['estoqueAtual'] ?? 0.0,
        'unidadeMedida': movAnteriorData['unidadeMedida'] ?? '',
        'cmp': movAnteriorData['cmpAtual'] ?? 0.0,
        'unidadeMedidaCMP': movAnteriorData['unidadeMedidaCMP'] ?? '',
        'dataUltimaAtualizacao': (movAnteriorData['data'] as Timestamp).toDate(),
        'origem': 'movimentacaoEstoque'
      };

      print('Encontrada movimentação anterior à original: ' +
          'ID=${movAnterior.id}, estoqueAtual=${resultado['quantidade']}, ' +
          'tipo=${movAnteriorData['tipo']}, data=${resultado['dataUltimaAtualizacao']}');
    } else {
      // Se não encontrou movimentação anterior, o saldo inicial é zero
      print('Nenhuma movimentação anterior à original encontrada, usando saldo inicial zero');
    }

    return resultado;
  }

  // Helper para atualizar o status da movimentação de forma segura
  Future<void> _atualizarStatusMovimentacao(String movimentacaoId, String status, [String? erro]) async {
    try {
      final movProjRef = _movimentacaoProjetadaService.getDocumentReference(movimentacaoId);
      final Map<String, dynamic> updateData = {
        'statusProcessamento': status,
      };

      if (status == 'processado') {
        updateData['dataProcessamento'] = FieldValue.serverTimestamp();
      } else if (status == 'erro' && erro != null) {
        updateData['erroProcessamento'] = erro;
      }

      await movProjRef.update(updateData);
    } catch (e) {
      print('Erro ao atualizar status da movimentação $movimentacaoId: $e');
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _processingTimeoutTimer?.cancel();
  }
}