import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/contabil/processamento_contabil_status.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/services/generic_service.dart';

class ProcessamentoContabilStatusService extends GenericService<ProcessamentoContabilStatus> {
  // Singleton pattern
  static final ProcessamentoContabilStatusService _instance = ProcessamentoContabilStatusService._internal();

  factory ProcessamentoContabilStatusService() {
    return _instance;
  }

  // Private constructor that calls the parent constructor with the collection name
  ProcessamentoContabilStatusService._internal() : super('processamentoContabilStatus');

  // Constantes de configuração
  static const Duration TIMEOUT_PROCESSAMENTO = Duration(minutes: 5);
  static const Duration HEARTBEAT_INTERVAL = Duration(minutes: 1);
  static const Duration INITIAL_RETRY_DELAY = Duration(seconds: 1);
  static const int MAX_RETRY_ATTEMPTS = 3;

  // Mapa para controlar heartbeats ativos
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, String> _activeLocks = {};

  @override
  ProcessamentoContabilStatus fromMap(Map<String, dynamic> map, String id) {
    return ProcessamentoContabilStatus.fromMap(map, id);
  }

  @override
  Map<String, dynamic> toMap(ProcessamentoContabilStatus status) {
    return status.toMap();
  }

  Future<bool> obterLockProcessamento(
      String produtorId,
      String contaId,
      String deviceId
      ) async {
    if (!AppStateManager().isOnline) {
      return false;
    }

    int tentativa = 0;
    Duration delay = INITIAL_RETRY_DELAY;
    final String lockId = '$produtorId-$contaId'; // ID composto fixo

    while (tentativa < MAX_RETRY_ATTEMPTS) {
      try {
        final bool resultado = await FirebaseService.firestore.runTransaction((transaction) async {
          final DocumentReference<Map<String, dynamic>> statusRef =
          getCollectionReference().doc(lockId);

          final DocumentSnapshot<Map<String, dynamic>> statusDoc =
          await transaction.get(statusRef);

          // Verifica lock existente
          if (statusDoc.exists) {
            final ProcessamentoContabilStatus status = ProcessamentoContabilStatus.fromMap(
                statusDoc.data()!,
                statusDoc.id
            );

            if (status.emProcessamento) {
              if (DateTime.now().difference(status.ultimaAtualizacao) <= TIMEOUT_PROCESSAMENTO) {
                if (status.deviceId != deviceId) {
                  return false;
                }
              }
            }
          }

          // Atualiza ou cria o documento com ID fixo
          final ProcessamentoContabilStatus novoStatus = ProcessamentoContabilStatus(
              id: lockId,
              produtorId: produtorId,
              contaContabilId: contaId,
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
          _activeLocks['$produtorId-$contaId'] = lockId;
          _iniciarHeartbeat(produtorId, contaId, deviceId, lockId);
        }

        return resultado;

      } catch (e) {
        if (!AppStateManager().isOnline) {
          return false;
        }

        tentativa++;
        if (tentativa >= MAX_RETRY_ATTEMPTS) {
          print('Erro ao obter lock após $MAX_RETRY_ATTEMPTS tentativas: $e');
          return false;
        }

        final jitter = (delay.inMilliseconds * 0.2 * (Random().nextDouble() - 0.5)).toInt();
        final nextDelay = delay + Duration(milliseconds: jitter);
        await Future.delayed(nextDelay);
        delay *= 2;
      }
    }

    return false;
  }

  void _iniciarHeartbeat(
      String produtorId,
      String contaId,
      String deviceId,
      String lockId
      ) {
    _heartbeatTimers[lockId]?.cancel();

    _heartbeatTimers[lockId] = Timer.periodic(HEARTBEAT_INTERVAL, (_) async {
      if (!AppStateManager().isOnline) {
        _heartbeatTimers[lockId]?.cancel();
        _heartbeatTimers.remove(lockId);
        return;
      }

      try {
        await getCollectionReference().doc(lockId).set({
          'ultimaAtualizacao': DateTime.now().toUtc(),
          'deviceId': deviceId,
          'emProcessamento': true
        }, SetOptions(merge: true));
      } catch (e) {
        print('Erro ao atualizar heartbeat para $lockId: $e');
        await liberarProcessamento(produtorId, contaId);
      }
    });
  }

  Future<void> liberarProcessamento(String produtorId, String contaId) async {
    final String lockId = '$produtorId-$contaId'; // ID composto fixo

    _heartbeatTimers[lockId]?.cancel();
    _heartbeatTimers.remove(lockId);
    _activeLocks.remove('$produtorId-$contaId');

    if (!AppStateManager().isOnline) return;

    try {
      await getCollectionReference().doc(lockId).set({
        'produtorId': produtorId,
        'contaId': contaId,
        'deviceId': AppStateManager().deviceId,
        'inicioProcessamento': DateTime.now(),
        'ultimaAtualizacao': DateTime.now(),
        'emProcessamento': false
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao liberar processamento para $lockId: $e');
    }
  }

  void dispose() {
    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();
  }
}