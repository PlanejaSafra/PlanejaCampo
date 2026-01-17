import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mutex/mutex.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil_projetado.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/estoques/retry_handler_service.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_service.dart';
import 'package:planejacampo/services/contabil/processamento_contabil_status_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';
import 'package:planejacampo/utils/finances/lancamento_contabil_options.dart';
import 'package:planejacampo/utils/finances/natureza_conta_config.dart';

class LancamentoContabilProcessor {
  // Singleton pattern
  static final LancamentoContabilProcessor _instance = LancamentoContabilProcessor._internal();

  // Serviços
  final LancamentoContabilProjetadoService _lancamentoProjetadoService = LancamentoContabilProjetadoService();
  final LancamentoContabilService _lancamentoContabilService = LancamentoContabilService();
  final ProcessamentoContabilStatusService _processamentoStatusService = ProcessamentoContabilStatusService();
  final AppStateManager _appStateManager = AppStateManager();
  final ContaContabilService _contaContabilService = ContaContabilService();

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

  // Cache de contas contábeis para evitar repetidas consultas
  final Map<String, ContaContabil> _cacheConta = {};

  // Cache de lançamentos em processamento para evitar duplicação
  final Set<String> _lancamentosEmProcessamento = {};

  // Construtor privado
  LancamentoContabilProcessor._internal();

  // Factory para obter a instância singleton
  factory LancamentoContabilProcessor() {
    return _instance;
  }

  // Agenda próxima retry com backoff exponencial e jitter
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
      processarLancamentosPendentes();
    });
  }

  // Obtém conta contábil do cache ou do servidor
  Future<ContaContabil?> _getContaContabil(String contaContabilId) async {
    if (_cacheConta.containsKey(contaContabilId)) {
      return _cacheConta[contaContabilId];
    }

    try {
      final conta = await _contaContabilService.getById(contaContabilId);
      if (conta != null) {
        _cacheConta[contaContabilId] = conta;
        return conta;
      }

      print('Alerta: Conta contábil $contaContabilId não encontrada');
      return null;
    } catch (e) {
      print('Erro ao buscar conta contábil $contaContabilId: $e');
      return null;
    }
  }

  // Método principal para processar lançamentos pendentes
  Future<void> processarLancamentosPendentes() async {
    print('Verificando lançamentos contábeis pendentes');

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
      print("Buscando lançamentos pendentes para device: $deviceId");

      // Buscar lançamentos pendentes
      List<LancamentoContabilProjetado> lancamentosPendentes;
      try {
        lancamentosPendentes = await _lancamentoProjetadoService.getByAttributes({
          'statusProcessamento': 'pendente',
          'deviceId': deviceId,
        });
      } catch (e) {
        print('Erro ao buscar lançamentos pendentes: $e');
        _scheduleRetry();
        return;
      }

      if (lancamentosPendentes.isEmpty) {
        print("Nenhum lançamento pendente, resetando retry interval");
        _currentRetryMs = 1000;
        return;
      }

      // Agrupar lançamentos por chave (produtor-conta) para processamento em lote
      Map<String, List<LancamentoContabilProjetado>> lancamentosPorChave = {};

      for (var lanc in lancamentosPendentes) {
        // Pular lançamentos que já estão em processamento
        if (_lancamentosEmProcessamento.contains(lanc.id)) {
          continue;
        }

        String key = '${lanc.produtorId}-${lanc.contaContabilId}';
        lancamentosPorChave.putIfAbsent(key, () => []).add(lanc);
      }

      bool hasError = false;
      bool hasUnprocessed = false;
      int processadosNesteCiclo = 0;

      for (String key in lancamentosPorChave.keys) {
        List<String> keyParts = key.split('-');
        print('Processando lançamentos para produtor: ${keyParts[0]}, conta: ${keyParts[1]}');

        try {
          bool processed = await _processarLancamentosChave(
              keyParts[0], // produtorId
              keyParts[1], // contaId
              lancamentosPorChave[key]!
          );

          if (processed) {
            processadosNesteCiclo += lancamentosPorChave[key]!.length;
          } else {
            hasUnprocessed = true;
          }
        } catch (e) {
          print('Erro processando lançamentos: $e');
          hasError = true;
          break;
        }
      }

      // Incrementar contador de sucesso se processou algum lançamento
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

      // Remover lançamentos contábeis projetados com status 'processado'
      if (!debugMode) {
        print('Removendo lançamentos contábeis projetados processados para o deviceId: $deviceId');
        await _lancamentoProjetadoService.deleteByAttribute({
          'statusProcessamento': 'processado',
          'deviceId': deviceId,
        });
        print('Lançamentos projetados removidos com sucesso');
      }
    }
  }

  // Processa lançamentos contábeis para uma chave específica - processamento em grupo
  Future<bool> _processarLancamentosChave(
      String produtorId,
      String contaContabilId,
      List<LancamentoContabilProjetado> lancamentos) async {

    String deviceId = _appStateManager.deviceId;

    // Tenta obter o lock com retry simples
    bool lockObtido = false;
    int tentativasLock = 0;

    while (!lockObtido && tentativasLock < 3) {
      lockObtido = await _processamentoStatusService.obterLockProcessamento(
          produtorId, contaContabilId, deviceId);

      if (!lockObtido) {
        tentativasLock++;
        if (tentativasLock < 3) {
          print('Tentativa $tentativasLock: Não foi possível obter o lock para produtor $produtorId e conta $contaContabilId, tentando novamente...');
          await Future.delayed(Duration(milliseconds: 500 * tentativasLock));
        }
      }
    }

    if (!lockObtido) {
      print('Não foi possível obter o lock para produtor $produtorId e conta $contaContabilId após $tentativasLock tentativas');
      return false;
    }

    try {
      // Filtrar lançamentos nulos/inválidos primeiro
      lancamentos = lancamentos.where((l) =>
      l != null &&
          l.deviceId == deviceId &&
          l.statusProcessamento != 'processado' &&
          !_lancamentosEmProcessamento.contains(l.id)
      ).toList();

      if (lancamentos.isEmpty) {
        print('Nenhum lançamento pendente para processar após filtragem');
        return true;
      }

      // Marcar lançamentos como em processamento
      for (var lanc in lancamentos) {
        _lancamentosEmProcessamento.add(lanc.id);
      }

      // Ordenar os lançamentos por data e timestamp
      lancamentos.sort((a, b) {
        int compareData = a.data.compareTo(b.data);
        if (compareData == 0) {
          return a.timestampLocal.compareTo(b.timestampLocal);
        }
        return compareData;
      });

      // Verificar modo offline-first
      final bool isOfflineFirst = _appStateManager.isOfflineFirstEnabled;
      final bool isOnline = _appStateManager.isOnline;

      // Se offline-first e offline, enfileirar para processamento posterior
      if (isOfflineFirst && !isOnline) {
        bool sucessoOffline = true;
        for (var lancamento in lancamentos) {
          try {
            bool resultado = await _processarLancamentoOfflineFirst(lancamento);
            if (!resultado) {
              sucessoOffline = false;
            }
          } catch (e) {
            print('Erro ao processar lançamento ${lancamento.id} offline: $e');
            sucessoOffline = false;
          } finally {
            // Remover da lista de em processamento
            _lancamentosEmProcessamento.remove(lancamento.id);
          }
        }
        return sucessoOffline;
      }

      // Processar cada lançamento
      bool todosSucesso = true;
      for (LancamentoContabilProjetado lancProj in lancamentos) {
        try {
          bool sucesso = await _processarLancamentoAtomico(lancProj);
          if (!sucesso) {
            todosSucesso = false;
          }
        } catch (e) {
          print('Erro processando lançamento ${lancProj.id}: $e');
          todosSucesso = false;
          // Continuar processando outros lançamentos mesmo que um falhe
        } finally {
          // Remover da lista de em processamento mesmo em caso de erro
          _lancamentosEmProcessamento.remove(lancProj.id);
        }
      }

      return todosSucesso;
    } finally {
      try {
        // Garantir liberação do lock mesmo em caso de erro
        await _processamentoStatusService.liberarProcessamento(produtorId, contaContabilId);

        // Garantir remoção de todos os lançamentos da lista de processamento
        for (var lanc in lancamentos) {
          _lancamentosEmProcessamento.remove(lanc.id);
        }
      } catch (e) {
        print('Erro ao liberar processamento: $e');
      }
    }
  }

  // Processa um único lançamento contábil projetado
  Future<bool> _processarLancamentoAtomico(LancamentoContabilProjetado lancProj) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> lancProjRef =
    _lancamentoProjetadoService.getDocumentReference(lancProj.id);
    final stopwatch = Stopwatch()..start();
    bool processamentoSucesso = false;

    // Variáveis para armazenar valores calculados para uso fora da transação
    double novoSaldoFinal = 0.0;

    try {
      bool transactionResult = await RetryHandlerService.run(
          operation: () async {
            return await firestore.runTransaction((transaction) async {
              try {
                //-----------------------------------------------------
                // FASE 1: TODAS AS LEITURAS (GET)
                //-----------------------------------------------------

                // Leitura 1: Verificar o lançamento projetado
                final DocumentSnapshot<Map<String, dynamic>> lancProjSnapshot =
                await transaction.get(lancProjRef);

                if (!lancProjSnapshot.exists) {
                  throw Exception('Lançamento contábil projetado não encontrado: ${lancProj.id}');
                }

                LancamentoContabilProjetado lancProjTrans =
                LancamentoContabilProjetado.fromMap(lancProjSnapshot.data()!, lancProjSnapshot.id);

                // Verificar se já foi processado
                if (lancProjTrans.statusProcessamento == 'processado' ||
                    lancProjTrans.idLancamentoReal != null) {
                  return true;
                }

                // Leitura 2: Obter a conta contábil para determinar a natureza
                final ContaContabil? conta = await _getContaContabil(lancProjTrans.contaContabilId);
                if (conta == null) {
                  throw Exception('Conta contábil não encontrada: ${lancProjTrans.contaContabilId}');
                }

                final String naturezaConta = NaturezaContaConfig.getNaturezaConta(conta.codigo);

                // Leitura 3: Buscar lançamentos originais para estornos
                bool isEstorno = lancProjTrans.categoria.startsWith('Estorno');
                List<DocumentSnapshot<Map<String, dynamic>>> lancsOriginaisDocs = [];
                String? idLancamentoAnterior = lancProjTrans.idLancamentoAnterior;

                if (isEstorno) {
                  if (idLancamentoAnterior != null && idLancamentoAnterior.isNotEmpty) {
                    // Se temos o ID específico do lançamento a estornar
                    DocumentReference<Map<String, dynamic>> lancAnteriorRef =
                    _lancamentoContabilService.getDocumentReference(idLancamentoAnterior);

                    DocumentSnapshot<Map<String, dynamic>> lancAnteriorDoc =
                    await transaction.get(lancAnteriorRef);

                    if (lancAnteriorDoc.exists) {
                      lancsOriginaisDocs.add(lancAnteriorDoc);
                    }
                  } else {
                    // Buscar pelo origemId e tipo
                    final QuerySnapshot<Map<String, dynamic>> lancsOriginaisQuery = await firestore
                        .collection('lancamentosContabeis')
                        .where('origemId', isEqualTo: lancProjTrans.origemId)
                        .where('origemTipo', isEqualTo: lancProjTrans.origemTipo)
                        .where('contaContabilId', isEqualTo: lancProjTrans.contaContabilId)
                        .where('tipo', isEqualTo: lancProjTrans.tipo == 'Credito' ? 'Debito' : 'Credito')
                        .where('ativo', isEqualTo: true)
                        .get();

                    lancsOriginaisDocs = lancsOriginaisQuery.docs;
                  }

                  if (lancsOriginaisDocs.isEmpty) {
                    print('Nenhum lançamento original encontrado para estorno: ${lancProjTrans.id}');
                    // Não falhar, apenas continuar
                  }
                }

                // Leitura 4: Buscar TODOS os lançamentos ativos da conta para recálculo dos saldos
                List<DocumentSnapshot<Map<String, dynamic>>> todosLancamentosDocs = [];

                final QuerySnapshot<Map<String, dynamic>> todosLancamentosQuery = await firestore
                    .collection('lancamentosContabeis')
                    .where('contaContabilId', isEqualTo: lancProjTrans.contaContabilId)
                    .where('ativo', isEqualTo: true)
                    .orderBy('data')
                    .orderBy('timestamp')
                    .get();

                todosLancamentosDocs = todosLancamentosQuery.docs;

                //-----------------------------------------------------
                // FASE 2: CÁLCULOS E PREPARAÇÃO (SEM LEITURAS OU ESCRITAS)
                //-----------------------------------------------------

                // Obter o saldo anterior
                double saldoAnterior = 0.0;

                for (var doc in todosLancamentosDocs.reversed) {
                  Map<String, dynamic>? data = doc.data();
                  if (data == null) continue;

                  Timestamp docData = data['data'] as Timestamp;
                  Timestamp docTimestamp = data['timestamp'] as Timestamp;

                  // Encontrar o lançamento anterior à data/hora do lançamento atual
                  if (docData.toDate().isBefore(lancProjTrans.data) ||
                      (docData.toDate().isAtSameMomentAs(lancProjTrans.data) &&
                          docTimestamp.toDate().isBefore(lancProjTrans.timestampLocal))) {
                    saldoAnterior = (data['saldoAtual'] as num).toDouble();
                    break;
                  }
                }

                // Preparar listas para operações
                List<Map<String, dynamic>> lancamentosParaRecalcular = [];
                DocumentReference? novoLancamentoRef;
                Map<String, dynamic>? novoLancamentoMap;
                List<DocumentReference> refsParaRemover = [];

                // Cálculo de saldo e preparação de operações
                // Correção para a parte de processamento de estornos no método _processarLancamentoAtomico

// Localizar este trecho no método _processarLancamentoAtomico:
                if (isEstorno) {
                  // PROCESSAMENTO DE ESTORNOS
                  // Em lançamentos contábeis, removemos os lançamentos originais

                  // Identificar lançamentos a remover
                  for (var doc in lancsOriginaisDocs) {
                    refsParaRemover.add(doc.reference);
                    print('Lançamento a remover: ${doc.id}');
                  }

                  // Registrar o saldo anterior para referência
                  print('Saldo anterior ao estorno: $saldoAnterior');

                  // Recalcular saldos para lançamentos após o estorno
                  double saldoAtualRecalc = saldoAnterior;
                  int lancamentosAfetados = 0;

                  // Registrar todos os lançamentos encontrados
                  print('Total de lançamentos para possível recálculo: ${todosLancamentosDocs.length}');

                  // Primeiro, vamos determinar a data do lançamento sendo estornado para referenciar corretamente
                  DateTime? dataLancamentoEstornado;
                  Timestamp? timestampLancamentoEstornado;

                  if (lancsOriginaisDocs.isNotEmpty) {
                    Map<String, dynamic>? dados = lancsOriginaisDocs[0].data();
                    if (dados != null) {
                      dataLancamentoEstornado = (dados['data'] as Timestamp).toDate();
                      timestampLancamentoEstornado = dados['timestamp'] as Timestamp;
                      print('Data do lançamento sendo estornado: $dataLancamentoEstornado');
                    }
                  }

                  // Se não encontramos a data do lançamento original, usamos a data do estorno
                  if (dataLancamentoEstornado == null) {
                    dataLancamentoEstornado = lancProjTrans.data;
                    print('Usando data do estorno como referência: $dataLancamentoEstornado');
                  }

                  // Agora, ordenamos todos os lançamentos pela data e timestamp
                  todosLancamentosDocs.sort((a, b) {
                    Map<String, dynamic>? dataA = a.data();
                    Map<String, dynamic>? dataB = b.data();

                    if (dataA == null || dataB == null) return 0;

                    Timestamp timestampA = dataA['data'] as Timestamp;
                    Timestamp timestampB = dataB['data'] as Timestamp;

                    int compareData = timestampA.compareTo(timestampB);
                    if (compareData != 0) return compareData;

                    Timestamp tsA = dataA['timestamp'] as Timestamp;
                    Timestamp tsB = dataB['timestamp'] as Timestamp;
                    return tsA.compareTo(tsB);
                  });

                  // Vamos encontrar o saldo ANTERIOR ao lançamento estornado
                  double saldoAntesDoEstornado = saldoAnterior;
                  for (var doc in todosLancamentosDocs) {
                    Map<String, dynamic>? data = doc.data();
                    if (data == null) continue;

                    // Pular se este é um dos lançamentos a serem removidos
                    if (refsParaRemover.contains(doc.reference)) continue;

                    Timestamp docData = data['data'] as Timestamp;
                    Timestamp docTimestamp = data['timestamp'] as Timestamp;

                    // Se for anterior ao lançamento estornado
                    if (docData.toDate().isBefore(dataLancamentoEstornado!) ||
                        (docData.toDate().isAtSameMomentAs(dataLancamentoEstornado!) &&
                            docTimestamp.compareTo(timestampLancamentoEstornado!) < 0)) {

                      saldoAntesDoEstornado = (data['saldoAtual'] as num).toDouble();
                    }
                  }

                  print('Saldo antes do lançamento estornado: $saldoAntesDoEstornado');
                  saldoAtualRecalc = saldoAntesDoEstornado;

                  // Agora, recalcular todos os lançamentos a partir deste ponto, ignorando os removidos
                  for (var doc in todosLancamentosDocs) {
                    Map<String, dynamic>? data = doc.data();
                    if (data == null) continue;

                    // Verificar se o lançamento não será removido
                    bool seraRemovido = refsParaRemover.contains(doc.reference);
                    if (seraRemovido) {
                      print('Ignorando lançamento a ser removido: ${doc.id}');
                      continue;
                    }

                    Timestamp docData = data['data'] as Timestamp;
                    Timestamp docTimestamp = data['timestamp'] as Timestamp;

                    // Incluir todos os lançamentos a partir do estornado (incluindo os que estão na mesma data)
                    if (docData.toDate().isAfter(dataLancamentoEstornado!) ||
                        (docData.toDate().isAtSameMomentAs(dataLancamentoEstornado!))) {

                      String tipo = data['tipo'] as String;
                      double valor = (data['valor'] as num).toDouble();
                      double saldoAtual = (data['saldoAtual'] as num).toDouble();

                      final resultado = LancamentoContabilOptions.calcularSaldo(
                        tipo: tipo,
                        categoria: 'Normal',
                        valor: valor,
                        saldoAtual: saldoAtualRecalc,
                        naturezaConta: naturezaConta,
                      );

                      if (resultado['novoSaldo'] != null) {
                        double novoSaldo = resultado['novoSaldo'];
                        if (saldoAtual != novoSaldo) {
                          lancamentosAfetados++;
                          print('Recalculando lançamento ${doc.id}: de $saldoAtual para $novoSaldo');

                          saldoAtualRecalc = novoSaldo;
                          lancamentosParaRecalcular.add({
                            'ref': doc.reference,
                            'saldoAtual': saldoAtualRecalc
                          });
                        }
                      }
                    }
                  }

                  print('Total de lançamentos afetados pelo recálculo: $lancamentosAfetados');

                  // Salvar saldo final
                  novoSaldoFinal = saldoAtualRecalc;
                } else {
                  // PROCESSAMENTO DE LANÇAMENTOS NORMAIS
                  // Calcular novo saldo para o lançamento
                  final resultadoCalculo = LancamentoContabilOptions.calcularSaldo(
                    tipo: lancProjTrans.tipo,
                    categoria: lancProjTrans.categoria,
                    valor: lancProjTrans.valor,
                    saldoAtual: saldoAnterior,
                    naturezaConta: naturezaConta,
                  );

                  if (resultadoCalculo['novoSaldo'] == null) {
                    throw Exception('Erro no cálculo do saldo');
                  }

                  double novoSaldo = resultadoCalculo['novoSaldo'];

                  // Criar novo lançamento real
                  String idLancamentoReal = _lancamentoContabilService.getNewDocumentReference().id;
                  novoLancamentoRef = _lancamentoContabilService.getDocumentReference(idLancamentoReal);

                  LancamentoContabil lancamentoReal = LancamentoContabil(
                    id: idLancamentoReal,
                    produtorId: lancProjTrans.produtorId,
                    data: lancProjTrans.data,
                    contaContabilId: lancProjTrans.contaContabilId,
                    tipo: lancProjTrans.tipo,
                    valor: lancProjTrans.valor,
                    saldoAtual: novoSaldo,
                    origemId: lancProjTrans.origemId,
                    origemTipo: lancProjTrans.origemTipo,
                    descricao: lancProjTrans.descricao,
                    ativo: true,
                    estornoId: null,
                    loteId: lancProjTrans.loteId,
                    timestamp: DateTime.now().toUtc(),
                  );

                  novoLancamentoMap = _lancamentoContabilService.toMap(lancamentoReal);

                  // Recalcular saldos para lançamentos posteriores
                  double saldoAtualRecalc = novoSaldo;

                  for (var doc in todosLancamentosDocs) {
                    Map<String, dynamic>? data = doc.data();
                    if (data == null) continue;

                    Timestamp docData = data['data'] as Timestamp;
                    Timestamp docTimestamp = data['timestamp'] as Timestamp;

                    if (docData.toDate().isAfter(lancProjTrans.data) ||
                        (docData.toDate().isAtSameMomentAs(lancProjTrans.data) &&
                            docTimestamp.toDate().isAfter(lancProjTrans.timestampLocal))) {

                      String tipo = data['tipo'] as String;
                      double valor = (data['valor'] as num).toDouble();

                      final resultado = LancamentoContabilOptions.calcularSaldo(
                        tipo: tipo,
                        categoria: 'Normal',
                        valor: valor,
                        saldoAtual: saldoAtualRecalc,
                        naturezaConta: naturezaConta,
                      );

                      if (resultado['novoSaldo'] != null) {
                        saldoAtualRecalc = resultado['novoSaldo'];
                        lancamentosParaRecalcular.add({
                          'ref': doc.reference,
                          'saldoAtual': saldoAtualRecalc
                        });
                      }
                    }
                  }

                  // Salvar saldo final
                  novoSaldoFinal = saldoAtualRecalc;
                }

                //-----------------------------------------------------
                // FASE 3: TODAS AS ESCRITAS (UPDATE/SET)
                //-----------------------------------------------------

                // Escrita 1: Atualizar status do lançamento projetado para "processando"
                transaction.update(lancProjRef, {
                  'statusProcessamento': 'em_processamento',
                });

                // Escrita 2: REMOVER lançamentos originais em caso de estorno
                // (não apenas inativá-los, como no caso de movimentações de estoque)
                for (var ref in refsParaRemover) {
                  transaction.delete(ref);
                }

                // Escrita 3: Criar novo lançamento real (se não for estorno)
                if (novoLancamentoRef != null && novoLancamentoMap != null) {
                  transaction.set(novoLancamentoRef, novoLancamentoMap);
                }

                // Escrita 4: Atualizar saldos de lançamentos posteriores
                for (var lancamento in lancamentosParaRecalcular) {
                  transaction.update(
                      lancamento['ref'],
                      {'saldoAtual': lancamento['saldoAtual']}
                  );
                }

                // Escrita 5: Finalizar processamento do lançamento projetado
                Map<String, dynamic> updateData = {
                  'statusProcessamento': 'processado',
                  'dataProcessamento': FieldValue.serverTimestamp(),
                };

                if (novoLancamentoRef != null) {
                  updateData['idLancamentoReal'] = novoLancamentoRef.id;
                }

                transaction.update(lancProjRef, updateData);

                return true; // Transação bem-sucedida
              } catch (error) {
                // Registrar erro no processamento
                print('Erro durante transação: ${error.toString()}');

                // Atualizar status do lançamento para erro
                transaction.update(lancProjRef, {
                  'statusProcessamento': 'erro',
                  'erroProcessamento': error.toString(),
                });

                return false; // Transação falhou
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

      return processamentoSucesso;
    } catch (finalError) {
      print('Erro final após todas as tentativas no processamento do lançamento ${lancProj.id}: $finalError');

      // Tentar atualizar o status para erro, fora da transação
      try {
        await _atualizarStatusLancamento(lancProj.id, 'erro', finalError.toString());
      } catch (e) {
        print('Erro ao atualizar status de erro para lançamento ${lancProj.id}: $e');
      }

      return false;
    } finally {
      final processingTime = stopwatch.elapsedMilliseconds;
      print('Processamento do lançamento ${lancProj.id} finalizado em ${processingTime}ms');

      // Atualizar cache local se processamento foi bem-sucedido
      if (processamentoSucesso) {
        unawaited(_atualizarCacheAposProcessamento(lancProj));
      }
    }
  }

  // Implementação para offline-first
  Future<bool> _processarLancamentoOfflineFirst(LancamentoContabilProjetado lancProj) async {
    print('Processando ${lancProj.id} em modo offline-first');

    String? transactionId;
    try {
      // Iniciar transação lógica para garantir atomicidade
      transactionId = await OfflineQueueManager.beginTransaction();

      // 1. Atualizar status para em_processamento
      await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: 'lancamentosContabeisProjetados',
          operationType: 'update',
          docId: lancProj.id,
          data: {
            'statusProcessamento': 'em_processamento',
            'transacaoId': transactionId
          },
          timestamp: DateTime.now(),
          produtorId: lancProj.produtorId,
          priority: OperationPriority.HIGH
      ));

      // 2. Determinar se é estorno e como processar
      bool isEstorno = lancProj.categoria.startsWith('Estorno');

      if (isEstorno) {
        // Estorno: marcar lançamentos originais para remoção
        if (lancProj.idLancamentoAnterior != null) {
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'lancamentosContabeis',
              operationType: 'delete',  // REMOVER em vez de inativar
              docId: lancProj.idLancamentoAnterior!,
              data: {},
              timestamp: DateTime.now(),
              produtorId: lancProj.produtorId,
              priority: OperationPriority.HIGH
          ));
        } else {
          // Quando não temos o ID específico, usamos filtros para marcar para remoção quando online
          await OfflineQueueManager.addToQueue(OfflineOperation(
              collection: 'system_operations',
              operationType: 'estornar_lancamentos',
              docId: DateTime.now().millisecondsSinceEpoch.toString(),
              data: {
                'origemId': lancProj.origemId,
                'origemTipo': lancProj.origemTipo,
                'contaContabilId': lancProj.contaContabilId,
                'tipo': lancProj.tipo == 'Credito' ? 'Debito' : 'Credito',
              },
              timestamp: DateTime.now(),
              produtorId: lancProj.produtorId,
              priority: OperationPriority.HIGH
          ));
        }
      } else {
        // Normal: criar novo lançamento contábil
        final idLancamentoReal = DateTime.now().millisecondsSinceEpoch.toString() + '_' + lancProj.id;

        // Calcular saldo estimado
        final ContaContabil? conta = await _getContaContabil(lancProj.contaContabilId);
        if (conta == null) {
          throw Exception('Conta contábil não encontrada');
        }

        final naturezaConta = NaturezaContaConfig.getNaturezaConta(conta.codigo);
        final resultadoCalculo = LancamentoContabilOptions.calcularSaldo(
          tipo: lancProj.tipo,
          categoria: lancProj.categoria,
          valor: lancProj.valor,
          saldoAtual: lancProj.saldoProjetado,
          naturezaConta: naturezaConta,
        );

        if (resultadoCalculo['novoSaldo'] == null) {
          throw Exception('Erro no cálculo do saldo');
        }

        final novoSaldo = resultadoCalculo['novoSaldo'];

        // Criar lançamento real
        LancamentoContabil lancamentoReal = LancamentoContabil(
          id: idLancamentoReal,
          produtorId: lancProj.produtorId,
          data: lancProj.data,
          contaContabilId: lancProj.contaContabilId,
          tipo: lancProj.tipo,
          valor: lancProj.valor,
          saldoAtual: novoSaldo,
          origemId: lancProj.origemId,
          origemTipo: lancProj.origemTipo,
          descricao: lancProj.descricao,
          ativo: true,
          estornoId: null,
          loteId: lancProj.loteId,
          timestamp: DateTime.now().toUtc(),
        );

        // Enfileirar criação do lançamento real
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: 'lancamentosContabeis',
            operationType: 'add',
            docId: idLancamentoReal,
            data: _lancamentoContabilService.toMap(lancamentoReal),
            timestamp: DateTime.now(),
            produtorId: lancProj.produtorId,
            priority: OperationPriority.HIGH
        ));

        // Marcar lançamento projetado como processado
        await OfflineQueueManager.addToQueue(OfflineOperation(
            collection: 'lancamentosContabeisProjetados',
            operationType: 'update',
            docId: lancProj.id,
            data: {
              'statusProcessamento': 'processado',
              'dataProcessamento': DateTime.now().toIso8601String(),
              'idLancamentoReal': idLancamentoReal,
            },
            timestamp: DateTime.now(),
            produtorId: lancProj.produtorId,
            priority: OperationPriority.HIGH
        ));

        // Atualizar cache local
        await _atualizarCacheOffline(lancProj, idLancamentoReal);
      }

      // Finalizar transação lógica
      if (transactionId != null) {
        await OfflineQueueManager.commitTransaction();
      }

      return true;
    } catch (e) {
      print('Erro geral no processamento offline-first: $e');

      // Marcar lançamento com erro
      await OfflineQueueManager.addToQueue(OfflineOperation(
          collection: 'lancamentosContabeisProjetados',
          operationType: 'update',
          docId: lancProj.id,
          data: {
            'statusProcessamento': 'erro',
            'erroProcessamento': e.toString(),
          },
          timestamp: DateTime.now(),
          produtorId: lancProj.produtorId,
          priority: OperationPriority.HIGH
      ));

      return false;
    }
  }

  // Atualizar o cache em modo offline
  Future<void> _atualizarCacheOffline(LancamentoContabilProjetado lancProj, String idLancamentoReal) async {
    try {
      // 1. Atualizar cache do lançamento projetado
      final dadosAtualizadosProj = {
        'id': lancProj.id,
        'statusProcessamento': 'processado',
        'dataProcessamento': DateTime.now().toIso8601String(),
        'idLancamentoReal': idLancamentoReal,
        // Outros campos do lançamento original mantidos no cache
        'produtorId': lancProj.produtorId,
        'data': Timestamp.fromDate(lancProj.data),
        'contaContabilId': lancProj.contaContabilId,
        'tipo': lancProj.tipo,
        'valor': lancProj.valor,
        'categoria': lancProj.categoria,
        'origemId': lancProj.origemId,
        'origemTipo': lancProj.origemTipo,
        'descricao': lancProj.descricao,
        'ativo': lancProj.ativo,
        'saldoProjetado': lancProj.saldoProjetado,
        'timestampLocal': Timestamp.fromDate(lancProj.timestampLocal),
        'deviceId': lancProj.deviceId,
        'loteId': lancProj.loteId,
      };

      await LocalCacheManager.updateCache(
          'lancamentosContabeisProjetados',
          lancProj.id,
          dadosAtualizadosProj
      );

      print('Cache offline atualizado para lançamento projetado ${lancProj.id}');

      // 2. Criar entrada no cache para o lançamento real
      final lancReal = {
        'id': idLancamentoReal,
        'produtorId': lancProj.produtorId,
        'data': Timestamp.fromDate(lancProj.data),
        'contaContabilId': lancProj.contaContabilId,
        'tipo': lancProj.tipo,
        'valor': lancProj.valor,
        'saldoAtual': lancProj.saldoProjetado,
        'origemId': lancProj.origemId,
        'origemTipo': lancProj.origemTipo,
        'descricao': lancProj.descricao,
        'ativo': true,
        'loteId': lancProj.loteId,
        'timestamp': Timestamp.fromDate(DateTime.now().toUtc()),
      };

      await LocalCacheManager.updateCache(
          'lancamentosContabeis',
          idLancamentoReal,
          lancReal
      );

      print('Cache offline criado para lançamento real $idLancamentoReal');
    } catch (e) {
      print('Erro ao atualizar cache offline: $e');
    }
  }

  // Atualizar o cache após processamento online
  Future<void> _atualizarCacheAposProcessamento(LancamentoContabilProjetado lancProj) async {
    try {
      // 1. Buscar o lancamentoContabilProjetado atualizado
      final lancProjRef = _lancamentoProjetadoService.getDocumentReference(lancProj.id);
      final docSnapshotProj = await lancProjRef.get();

      if (docSnapshotProj.exists) {
        final dadosAtualizadosProj = docSnapshotProj.data()!;

        // 2. Verificar se foi processado com sucesso e tem ID do lançamento real
        if (dadosAtualizadosProj['statusProcessamento'] == 'processado' &&
            dadosAtualizadosProj['idLancamentoReal'] != null) {

          // 3. Atualizar LancamentoContabilProjetado no cache
          await LocalCacheManager.updateCache(
              'lancamentosContabeisProjetados',
              lancProj.id,
              dadosAtualizadosProj
          );

          print('Cache local atualizado para lançamento projetado ${lancProj.id}');

          // 4. Buscar e atualizar o LancamentoContabil correspondente
          final idLancamentoReal = dadosAtualizadosProj['idLancamentoReal'];

          if (idLancamentoReal != null) {
            try {
              final docRefLancReal = _lancamentoContabilService.getDocumentReference(idLancamentoReal);
              final docSnapshotReal = await docRefLancReal.get();

              if (docSnapshotReal.exists) {
                // 5. Atualizar LancamentoContabil no cache
                await LocalCacheManager.updateCache(
                    'lancamentosContabeis',
                    idLancamentoReal,
                    docSnapshotReal.data()!
                );

                print('Cache local atualizado para lançamento real $idLancamentoReal');
              }
            } catch (innerError) {
              print('Erro ao atualizar cache do lançamento real: $innerError');
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao atualizar cache local: $e');
    }
  }

  // Helper para atualizar o status do lançamento de forma segura
  Future<void> _atualizarStatusLancamento(String lancamentoId, String status, [String? erro]) async {
    try {
      final lancProjRef = _lancamentoProjetadoService.getDocumentReference(lancamentoId);
      final Map<String, dynamic> updateData = {
        'statusProcessamento': status,
      };

      if (status == 'processado') {
        updateData['dataProcessamento'] = FieldValue.serverTimestamp();
      } else if (status == 'erro' && erro != null) {
        updateData['erroProcessamento'] = erro;
      }

      await lancProjRef.update(updateData);
    } catch (e) {
      print('Erro ao atualizar status do lançamento $lancamentoId: $e');
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _processingTimeoutTimer?.cancel();
  }
}