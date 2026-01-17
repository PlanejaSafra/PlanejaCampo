import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:planejacampo/models/system/offline_operation.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'dart:math' as Math;

class OfflineQueueManager {
  static const String QUEUE_BOX = 'offline_queue';
  static const String TRANSACTION_BOX = 'transaction_groups';
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_DELAY = Duration(minutes: 5);
  static bool _needsReordering = false;
  static final Mutex _mutex = Mutex();
  static String? _currentTransactionId;
  static bool _processingInProgress = false;
  static final Set<String> _processedTransactions = {};
  static bool _retryScheduled = false;
  static Timer? _retryTimer;

  // Helper para converter Map<dynamic, dynamic> para Map<String, dynamic>
  static Map<String, dynamic> _convertToStringMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertToStringMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _convertToStringList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  // Helper para converter List<dynamic> para List<String> quando necessário
  static List<dynamic> _convertToStringList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertToStringMap(item);
      } else if (item is List) {
        return _convertToStringList(item);
      }
      return item;
    }).toList();
  }

  // Inicia uma transação lógica para agrupar operações relacionadas
  static Future<String> beginTransaction() async {
    final box = await Hive.openBox<Map>(TRANSACTION_BOX);
    final transactionId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${Math.Random().nextInt(1000)}';

    await box.put(transactionId, {
      'id': transactionId,
      'status': 'pending',
      'created': DateTime.now().toIso8601String(),
      'operations': <String>[]
    });

    _currentTransactionId = transactionId;
    print('Iniciada transação lógica: $transactionId');
    return transactionId;
  }

  // Finaliza a transação lógica atual
  static Future<void> commitTransaction() async {
    if (_currentTransactionId == null) return;

    final box = await Hive.openBox<Map>(TRANSACTION_BOX);
    final txData = box.get(_currentTransactionId!);

    if (txData != null) {
      txData['status'] = 'ready';
      txData['committed'] = DateTime.now().toIso8601String();
      await box.put(_currentTransactionId!, txData);
      print('Transação finalizada e pronta para processamento: $_currentTransactionId');
    }

    _currentTransactionId = null;
  }

  // Adiciona uma operação à fila, opcionalmente associando a uma transação
  static Future<void> addToQueue(OfflineOperation operation, {String? transactionId}) async {
    // Use a transação atual se nenhuma for especificada
    final txId = transactionId ?? _currentTransactionId;
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    final operationMap = operation.toMap();
    final uniqueKey = '${operation.collection}:${operation.docId}:${operation.operationType}';

    // Associar à transação se disponível
    if (txId != null) {
      operationMap['transactionId'] = txId;

      // Adicionar à lista de operações da transação
      final txBox = await Hive.openBox<Map>(TRANSACTION_BOX);
      final txData = txBox.get(txId);

      if (txData != null) {
        final opList = List<String>.from(txData['operations'] ?? []);
        if (!opList.contains(uniqueKey)) {
          opList.add(uniqueKey);
          txData['operations'] = opList;
          await txBox.put(txId, txData);
        }
      }
    }

    // Usar uma chave composta para identificar operações únicas
    final existingOpIndex = await _findExistingOperationIndex(box, uniqueKey);

    if (existingOpIndex != null) {
      // Se a operação existente tiver prioridade maior, manter a prioridade existente
      final existingOp = box.getAt(existingOpIndex);
      if (existingOp != null) {
        final existingPriority = _getPriorityFromString(existingOp['priority'] ?? 'MEDIUM');
        final newPriority = operation.priority;

        if (existingPriority.index < newPriority.index) {
          operationMap['priority'] = existingPriority.toString();
        } else if (existingPriority.index > newPriority.index) {
          // Se a prioridade mudou para um valor mais alto, precisamos reordenar
          _needsReordering = true;
        }

        // Incrementar versão para controle
        operationMap['version'] = (existingOp['version'] ?? 0) + 1;
      }

      await box.putAt(existingOpIndex, operationMap);
      print('Operação atualizada na fila: $uniqueKey');
    } else {
      operationMap['version'] = 1;
      operationMap['timestamp'] = DateTime.now().toIso8601String();
      await box.add(operationMap);
      // Sempre que adicionar uma nova operação, habilitar reordenação
      _needsReordering = true;
      print('Nova operação adicionada à fila: $uniqueKey');
    }

    // Reordenar apenas quando necessário
    if (_needsReordering) {
      await _reorderQueue(box);
      _needsReordering = false;
    }
  }

  // Método auxiliar para encontrar operações existentes
  static Future<int?> _findExistingOperationIndex(Box<Map> box, String uniqueKey) async {
    for (var i = 0; i < box.length; i++) {
      final op = box.getAt(i);
      if (op == null) continue;

      final opKey = '${op['collection']}:${op['docId']}:${op['operationType']}';
      if (opKey == uniqueKey) {
        return i;
      }
    }
    return null;
  }

  // Verifica se existem operações pendentes na fila
  static Future<bool> hasPendingOperations() async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    return box.length > 0;
  }

  // Verifica se algum processamento está em andamento
  static bool isProcessing() {
    return _processingInProgress;
  }

  // Processa a fila de operações offline
  static Future<void> processQueue({bool forceSynchronous = false}) async {
    // Impedir processamento concorrente
    if (_processingInProgress && !forceSynchronous) {
      print('Já está processando, agendando retry genuíno');

      // Cancelar retry anterior se existir
      _retryTimer?.cancel();

      // Implementação real de retry usando um timer
      if (!_retryScheduled) {
        _retryScheduled = true;

        _retryTimer = Timer(Duration(seconds: 3), () {
          print('Executando retry agendado da fila');
          _retryScheduled = false;
          processQueue(forceSynchronous: true);
        });
      }
      return;
    }

    await _mutex.acquire(); // Garante exclusividade no processamento
    _processingInProgress = true;

    try {
      final box = await Hive.openBox<Map>(QUEUE_BOX);
      if (box.isEmpty) {
        print('Fila offline vazia.');
        return;
      }

      // Processar primeiro as transações prontas
      await _processTransactionGroups();

      print('Processando fila offline com ${box.length} operações pendentes...');

      final processedIds = <String>{};
      final failedOperations = <int>{};
      int successCount = 0;

      // Processar operações individuais que não pertencem a transações
      for (var i = 0; i < box.length; i++) {
        if (failedOperations.contains(i)) continue;

        try {
          final opMap = box.getAt(i);
          if (opMap == null) continue;

          // Pular operações que pertencem a transações (serão processadas à parte)
          if (opMap.containsKey('transactionId')) {
            continue;
          }

          final operation = OfflineOperation.fromMap(_convertToStringMap(opMap));

          if (!_canProcessOperation(operation, processedIds)) {
            failedOperations.add(i);
            print('Operação ${operation.docId} adiada por dependência.');
            continue;
          }

          if (operation.deadline != null && DateTime.now().isAfter(operation.deadline!)) {
            await box.deleteAt(i);
            i--;
            print('Operação ${operation.docId} expirada e removida.');
            continue;
          }

          if (operation.retryCount >= MAX_RETRIES) {
            print('Operação ${operation.docId} excedeu $MAX_RETRIES tentativas e foi descartada.');
            await box.deleteAt(i);
            i--;
            continue;
          }

          final success = await _executeOperation(operation);

          if (success) {
            await box.deleteAt(i);
            i--;
            successCount++;
            if (operation.docId != null) {
              processedIds.add(operation.docId!);
            }
            print('Operação ${operation.docId} concluída com sucesso.');
          } else {
            final updatedOperation = operation.copyWith(
              retryCount: operation.retryCount + 1,
            );
            await box.putAt(i, updatedOperation.toMap());
            failedOperations.add(i);

            // Implementar backoff exponencial para tentativas
            final backoffDelay = 100 * Math.pow(2, updatedOperation.retryCount).toInt();
            print('Operação ${operation.docId} falhou. Retry ${updatedOperation.retryCount} após ${backoffDelay}ms.');
            await Future.delayed(Duration(milliseconds: backoffDelay));
          }
        } catch (e) {
          print('Erro processando operação: $e');
          failedOperations.add(i);
        }
      }

      if (failedOperations.isNotEmpty) {
        await _reorderQueue(box);
      }

      print('Processamento concluído: $successCount operações bem-sucedidas, ${failedOperations.length} falhas.');
    } finally {
      _processingInProgress = false;
      _mutex.release(); // Libera o lock
    }
  }

  // Não esqueça de adicionar isso à classe para limpar o timer
  static void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryScheduled = false;
  }

  // Processa transações lógicas como unidades atômicas
  static Future<void> _processTransactionGroups() async {
    final txBox = await Hive.openBox<Map>(TRANSACTION_BOX);
    final queueBox = await Hive.openBox<Map>(QUEUE_BOX);

    // Identificar transações prontas para processamento
    final readyTransactions = <String, Map>{};

    for (var i = 0; i < txBox.length; i++) {
      final txKey = txBox.keyAt(i) as String;
      final txData = txBox.get(txKey);

      if (txData != null &&
          txData['status'] == 'ready' &&
          !_processedTransactions.contains(txKey)) {
        readyTransactions[txKey] = txData;
      }
    }

    if (readyTransactions.isEmpty) return;

    print('Processando ${readyTransactions.length} transações lógicas...');

    // Processar cada transação como uma unidade atômica
    for (var txId in readyTransactions.keys) {
      final txData = readyTransactions[txId]!;
      final operations = List<String>.from(txData['operations'] ?? []);
      final operationsToProcess = <OfflineOperation>[];
      final operationIndices = <String, int>{};

      // Coletar todas as operações desta transação
      for (var i = 0; i < queueBox.length; i++) {
        final opMap = queueBox.getAt(i);
        if (opMap != null && opMap['transactionId'] == txId) {
          final uniqueKey = '${opMap['collection']}:${opMap['docId']}:${opMap['operationType']}';
          operationIndices[uniqueKey] = i;
          operationsToProcess.add(OfflineOperation.fromMap(_convertToStringMap(opMap)));
        }
      }

      if (operationsToProcess.isEmpty) {
        // Se não há operações, marcar transação como processada
        _processedTransactions.add(txId);
        txData['status'] = 'completed';
        await txBox.put(txId, txData);
        continue;
      }

      print('Processando transação $txId com ${operationsToProcess.length} operações...');

      // Ordenar operações por prioridade e tipo
      operationsToProcess.sort((a, b) {
        // Primeiro por prioridade (HIGH > MEDIUM > LOW)
        final prioComp = b.priority.index.compareTo(a.priority.index);
        if (prioComp != 0) return prioComp;

        // Depois por tipo (add > update > delete)
        final typeA = a.operationType;
        final typeB = b.operationType;

        if (typeA == typeB) return 0;
        if (typeA == 'add') return -1;
        if (typeB == 'add') return 1;
        if (typeA == 'update') return -1;
        return 1;
      });

      // Tentar executar todas as operações desta transação
      bool allSuccessful = true;
      final processedIds = <String>{};

      for (var op in operationsToProcess) {
        if (!_canProcessOperation(op, processedIds)) {
          print('Operação ${op.docId} tem dependências não satisfeitas, adiando transação $txId');
          allSuccessful = false;
          break;
        }

        final success = await _executeOperation(op);

        if (success) {
          if (op.docId != null) {
            processedIds.add(op.docId!);
          }
          print('Operação ${op.docId} da transação $txId concluída com sucesso');
        } else {
          allSuccessful = false;
          print('Falha na operação ${op.docId} da transação $txId');

          // Incrementar contagem de tentativas
          final uniqueKey = '${op.collection}:${op.docId}:${op.operationType}';
          final index = operationIndices[uniqueKey];
          if (index != null) {
            final opMap = queueBox.getAt(index);
            if (opMap != null) {
              opMap['retryCount'] = (opMap['retryCount'] ?? 0) + 1;
              await queueBox.putAt(index, opMap);
            }
          }

          break;
        }
      }

      if (allSuccessful) {
        // Se todas as operações tiveram sucesso, remover todas da fila
        for (var uniqueKey in operationIndices.keys) {
          final index = operationIndices[uniqueKey];
          try {
            await queueBox.deleteAt(index!);
          } catch (e) {
            print('Erro ao remover operação concluída: $e');
          }
        }

        // Marcar transação como processada
        _processedTransactions.add(txId);
        txData['status'] = 'completed';
        txData['completedAt'] = DateTime.now().toIso8601String();
        await txBox.put(txId, txData);

        print('Transação $txId concluída com sucesso');
      } else {
        // Se houve falha, tentar novamente mais tarde
        txData['retryCount'] = (txData['retryCount'] ?? 0) + 1;
        await txBox.put(txId, txData);
        print('Transação $txId adiada para nova tentativa');
      }
    }

    // Limpar transações concluídas antigas
    if (_processedTransactions.length > 100) {
      final toRemove = _processedTransactions.take(_processedTransactions.length - 50).toList();
      for (var txId in toRemove) {
        _processedTransactions.remove(txId);
      }
    }
  }

  static bool _canProcessOperation(OfflineOperation operation, Set<String> processedIds) {
    if (operation.dependencies.isEmpty) return true;
    return operation.dependencies.every((depId) => processedIds.contains(depId));
  }

  static Future<bool> _executeOperation(OfflineOperation operation) async {
    try {
      final collection = FirebaseFirestore.instance.collection(operation.collection);

      // Tratamento especial para operações com campos críticos
      bool containsCriticalFields = operation.data.containsKey('cargaInicial');

      switch (operation.operationType) {
        case 'add':
          if (operation.docId != null) {
            await collection.doc(operation.docId).set(operation.data, SetOptions(merge: true));
          } else {
            await collection.add(operation.data);
          }
          break;

        case 'update':
          if (operation.docId == null) return false;

          if (containsCriticalFields) {
            await collection.doc(operation.docId).set(operation.data, SetOptions(merge: true));
          } else {
            await collection.doc(operation.docId).update(operation.data);
          }
          break;

        case 'delete':
          if (operation.docId == null) return false;

          if (containsCriticalFields) {
            print('Aviso: Pulando deleção de documento com campo crítico (cargaInicial): ${operation.docId}');
            return true; // Considerar como "bem-sucedido" para remover da fila
          }

          await collection.doc(operation.docId).delete();
          break;

        default:
          print('Operação desconhecida: ${operation.operationType}');
          return false;
      }

      if (operation.operationType != 'delete') {
        // Atualizar metadados no cache E no Firestore após sucesso
        Map<String, dynamic> updatedData = Map<String, dynamic>.from(operation.data);

        // Atualizar o status de sincronização para 'synced'
        if (updatedData.containsKey('_metadata')) {
          updatedData['_metadata'] = {
            ...updatedData['_metadata'],
            'syncStatus': 'synced'
          };

          // Atualizar apenas o campo syncStatus no Firestore
          await collection.doc(operation.docId).update({
            '_metadata.syncStatus': 'synced'
          });
        }

        await LocalCacheManager.updateCache(
            operation.collection,
            operation.docId!,
            updatedData
        );
      } else {
        await LocalCacheManager.removeFromCache(
            operation.collection,
            operation.docId!
        );
      }

      return true;
    } on FirebaseException catch (e) {
      print('Erro Firebase executando operação: ${e.code} - ${e.message}');

      if (['not-found', 'permission-denied'].contains(e.code)) {
        return true;
      }

      return false;
    } catch (e) {
      print('Erro executando operação: $e');
      return false;
    }
  }

  static Future<void> _reorderQueue(Box<Map> box) async {
    final operations = box.values.toList();
    operations.sort((a, b) {
      // Primeiro, agrupar por transação
      final txA = a['transactionId'] as String?;
      final txB = b['transactionId'] as String?;

      if (txA != null && txB == null) return -1;
      if (txA == null && txB != null) return 1;
      if (txA != null && txB != null && txA != txB) {
        return txA.compareTo(txB);
      }

      // Depois por prioridade
      final priorityA = _getPriorityFromString(a['priority'] ?? 'MEDIUM');
      final priorityB = _getPriorityFromString(b['priority'] ?? 'MEDIUM');

      if (priorityA != priorityB) {
        return priorityB.index.compareTo(priorityA.index);
      }

      // Por fim, operações com menos tentativas primeiro
      final retryA = a['retryCount'] ?? 0;
      final retryB = b['retryCount'] ?? 0;
      return retryA.compareTo(retryB);
    });

    await box.clear();
    for (var operation in operations) {
      await box.add(operation);
    }
  }

  static OperationPriority _getPriorityFromString(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH': return OperationPriority.HIGH;
      case 'LOW': return OperationPriority.LOW;
      default: return OperationPriority.MEDIUM;
    }
  }

  static Future<int> getPendingOperationsCount() async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    return box.length;
  }

  static Future<void> clearQueue() async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    await box.clear();
  }

  static Future<List<OfflineOperation>> getPendingOperations() async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    return box.values
        .map((opMap) => OfflineOperation.fromMap(_convertToStringMap(opMap)))
        .toList();
  }

  static Future<void> cancelOperation(String collection, String docId) async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);

    for (var i = 0; i < box.length; i++) {
      final opMap = box.getAt(i);
      if (opMap == null) continue;

      if (opMap['collection'] == collection && opMap['docId'] == docId) {
        await box.deleteAt(i);
        i--;
      }
    }
  }

  static Future<void> prioritizeOperation(String collection, String docId) async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);

    for (var i = 0; i < box.length; i++) {
      final opMap = box.getAt(i);
      if (opMap == null) continue;

      if (opMap['collection'] == collection && opMap['docId'] == docId) {
        opMap['priority'] = OperationPriority.HIGH.toString();
        await box.putAt(i, opMap);
        await _reorderQueue(box);
        break;
      }
    }
  }

  static Future<void> cleanupStaleOperations(Duration maxAge) async {
    final box = await Hive.openBox<Map>(QUEUE_BOX);
    final now = DateTime.now();

    for (var i = 0; i < box.length; i++) {
      final opMap = box.getAt(i);
      if (opMap == null) continue;

      if (opMap['timestamp'] != null) {
        final timestamp = DateTime.parse(opMap['timestamp']);
        if (now.difference(timestamp) > maxAge) {
          await box.deleteAt(i);
          i--;
        }
      }
    }
  }
}