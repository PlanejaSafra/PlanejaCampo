import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/processamento_status.dart';
import 'package:planejacampo/services/device_info_service.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class ProcessamentoStatusService extends GenericService<ProcessamentoStatus> {
  // Singleton pattern
  static final ProcessamentoStatusService _instance = ProcessamentoStatusService._internal();

  factory ProcessamentoStatusService() {
    return _instance;
  }

  // Private constructor that calls the parent constructor with the collection name
  ProcessamentoStatusService._internal() : super('processamentoStatus');

  // Constantes de configuração
  static const Duration TIMEOUT_PROCESSAMENTO = Duration(minutes: 5);
  static const Duration HEARTBEAT_INTERVAL = Duration(minutes: 1);
  static const Duration INITIAL_RETRY_DELAY = Duration(seconds: 1);
  static const int MAX_RETRY_ATTEMPTS = 3;

  // Mapa para controlar heartbeats ativos
  final Map<String, Timer> _heartbeatTimers = {};

  @override
  ProcessamentoStatus fromMap(Map<String, dynamic> map, String documentId) {
    return ProcessamentoStatus.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ProcessamentoStatus status) {
    return status.toMap();
  }

  Future<bool> obterLockProcessamento(
      String produtorId,
      String itemId,
      String propriedadeId,
      String deviceId
      ) async {
    // Se offline, não tenta obter lock
    if (!AppStateManager().isOnline) {
      return false;
    }

    int tentativa = 0;
    Duration delay = INITIAL_RETRY_DELAY;

    while (tentativa < MAX_RETRY_ATTEMPTS) {
      try {
        final bool resultado = await FirebaseService.firestore.runTransaction((transaction) async {
          final String lockId = '$produtorId-$itemId-$propriedadeId';
          final DocumentReference<Map<String, dynamic>> statusRef =
          getCollectionReference().doc(lockId);

          final DocumentSnapshot<Map<String, dynamic>> statusDoc =
          await transaction.get(statusRef);

          if (statusDoc.exists) {
            final ProcessamentoStatus status = ProcessamentoStatus.fromMap(
                statusDoc.data() as Map<String, dynamic>,
                statusDoc.id
            );

            if (status.emProcessamento) {
              // Verifica se o lock expirou
              if (DateTime.now().difference(status.ultimaAtualizacao) <= TIMEOUT_PROCESSAMENTO) {
                // Se o lock ainda é válido e pertence a outro device, não obtém
                if (status.deviceId != deviceId) {
                  return false;
                }
              }
            }
          }

          final ProcessamentoStatus novoStatus = ProcessamentoStatus(
              id: lockId,
              produtorId: produtorId,
              itemId: itemId,
              propriedadeId: propriedadeId,
              deviceId: deviceId,
              inicioProcessamento: DateTime.now(),
              ultimaAtualizacao: DateTime.now(),
              emProcessamento: true
          );

          transaction.set(
              statusRef,
              toMap(novoStatus),
              SetOptions(merge: true)
          );

          return true;
        });

        if (resultado) {
          _iniciarHeartbeat(produtorId, itemId, propriedadeId, deviceId);
          return true;
        }

        return false;

      } catch (e) {
        // Se perdeu conexão durante a tentativa
        if (!AppStateManager().isOnline) {
          return false;
        }

        tentativa++;
        if (tentativa >= MAX_RETRY_ATTEMPTS) {
          print('Erro ao obter lock após $MAX_RETRY_ATTEMPTS tentativas: $e');
          return false;
        }

        // Adiciona jitter ao delay
        final jitter = (delay.inMilliseconds * 0.2 * (Random().nextDouble() - 0.5)).toInt();
        final nextDelay = delay + Duration(milliseconds: jitter);
        await Future.delayed(nextDelay);

        // Aumenta o delay para próxima tentativa
        delay *= 2;
      }
    }

    return false;
  }

  void _iniciarHeartbeat(
      String produtorId,
      String itemId,
      String propriedadeId,
      String deviceId
      ) {
    final String lockId = '$produtorId-$itemId-$propriedadeId';
    _heartbeatTimers[lockId]?.cancel();

    _heartbeatTimers[lockId] = Timer.periodic(HEARTBEAT_INTERVAL, (_) async {
      // Verifica conexão antes de tentar heartbeat
      if (!AppStateManager().isOnline) {
        _heartbeatTimers[lockId]?.cancel();
        _heartbeatTimers.remove(lockId);
        return;
      }

      try {
        await getCollectionReference()
            .doc(lockId)
            .update({
          'ultimaAtualizacao': DateTime.now().toUtc(),
          'deviceId': deviceId,
        });
      } catch (e) {
        print('Erro ao atualizar heartbeat para $lockId: $e');
        await liberarProcessamento(produtorId, itemId, propriedadeId);
      }
    });
  }

  Future<void> liberarProcessamento(
      String produtorId,
      String itemId,
      String propriedadeId,
      ) async {
    final String lockId = '$produtorId-$itemId-$propriedadeId';

    // Cancela timers locais mesmo offline
    _heartbeatTimers[lockId]?.cancel();
    _heartbeatTimers.remove(lockId);

    // Se offline, não tenta atualizar no Firestore
    if (!AppStateManager().isOnline) {
      return;
    }

    try {
      final String deviceId = await DeviceInfoService().getDeviceId();

      final ProcessamentoStatus status = ProcessamentoStatus(
          id: lockId,
          produtorId: produtorId,
          itemId: itemId,
          propriedadeId: propriedadeId,
          deviceId: deviceId,
          inicioProcessamento: DateTime.now(),
          ultimaAtualizacao: DateTime.now(),
          emProcessamento: false
      );

      await update(status.id, status);
    } catch (e) {
      print('Erro ao liberar processamento para $lockId: $e');
      // Não relança o erro pois o timer local já foi cancelado
    }
  }

  Future<void> limparProcessamentosAntigos() async {
    if (!AppStateManager().isOnline) {
      return;
    }

    try {
      final List<ProcessamentoStatus> processamentosAntigos =
      await getByAttributesWithOperators({
        'emProcessamento': [{'operator': '==', 'value': true}],
        'ultimaAtualizacao': [{
          'operator': '<=',
          'value': DateTime.now().subtract(TIMEOUT_PROCESSAMENTO)
        }]
      });

      for (final ProcessamentoStatus processamento in processamentosAntigos) {
        await liberarProcessamento(
            processamento.produtorId,
            processamento.itemId,
            processamento.propriedadeId
        );
      }
    } catch (e) {
      print('Erro ao limpar processamentos antigos: $e');
      // Não relança o erro pois é uma operação de limpeza
    }
  }

  // Método para liberar todos os recursos ao descartar o serviço
  void dispose() {
    // Cancela todos os heartbeat timers ativos
    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();
  }
}