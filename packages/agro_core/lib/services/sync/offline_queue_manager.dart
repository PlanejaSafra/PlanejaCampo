import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:agro_core/services/sync/sync_models.dart';
import 'package:agro_core/services/sync/sync_config.dart';

/// Gerencia a fila de operações offline
/// Persiste operações pendentes e as processa quando online
class OfflineQueueManager {
  static final OfflineQueueManager instance = OfflineQueueManager._();

  OfflineQueueManager._();

  Box<OfflineOperation>? _queueBox;
  static const String _queueBoxName = 'offline_operations_queue';
  bool _initialized = false;
  bool _isProcessing = false;

  // Stream de conectividade
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;

  final _syncResultController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get onSyncComplete => _syncResultController.stream;

  Future<void> init() async {
    if (_initialized) return;

    debugPrint('[OfflineQueue] Initializing...');

    if (!Hive.isBoxOpen(_queueBoxName)) {
      _queueBox = await Hive.openBox<OfflineOperation>(_queueBoxName);
    } else {
      _queueBox = Hive.box<OfflineOperation>(_queueBoxName);
    }

    debugPrint('[OfflineQueue] Queue box opened '
        '(${_queueBox!.length} pending operations)');

    // Configura listener de rede
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      final wasOnline = _isOnline;
      _isOnline = hasNet;

      if (hasNet && !wasOnline) {
        debugPrint('[OfflineQueue] Network restored! '
            'Pending: ${getPendingCount()}');
      } else if (!hasNet && wasOnline) {
        debugPrint('[OfflineQueue] Network lost');
      }

      if (hasNet && getPendingCount() > 0) {
        // Debounce leve para evitar oscilações
        Future.delayed(const Duration(seconds: 2), () {
          processQueue();
        });
      }
    });

    // Checagem inicial
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    debugPrint('[OfflineQueue] Initialized '
        '(online: $_isOnline, pending: ${_queueBox!.length})');

    _initialized = true;
  }

  /// Adiciona uma operação à fila
  Future<void> addToQueue(OfflineOperation op) async {
    if (!_initialized) await init();
    await _queueBox!.put(op.id, op);
    debugPrint('[OfflineQueue] Added: ${op.operationType.name} '
        '${op.collection}/${op.docId} (priority: ${op.priority.name}, '
        'queue size: ${_queueBox!.length})');

    // Tenta processar imediatamente se possível (fire and forget)
    processQueue();
  }

  /// Retorna operações ordenadas por prioridade
  List<OfflineOperation> getQueue() {
    if (_queueBox == null) return [];

    final ops = _queueBox!.values.toList();
    ops.sort((a, b) => a.compareTo(b));
    return ops;
  }

  int getPendingCount() => _queueBox?.length ?? 0;

  /// Processa a fila de operações (envia para Firestore)
  Future<void> processQueue() async {
    final hasNet = await _checkConnection();
    if (_isProcessing) {
      debugPrint('[OfflineQueue] processQueue skipped: already processing');
      return;
    }
    if (!hasNet) {
      debugPrint('[OfflineQueue] processQueue skipped: offline '
          '(pending: ${getPendingCount()})');
      return;
    }

    _isProcessing = true;
    int successCount = 0;
    int failCount = 0;

    try {
      final queue = getQueue();
      if (queue.isEmpty) {
        debugPrint('[OfflineQueue] processQueue: queue is empty, nothing to do');
        _isProcessing = false;
        return;
      }

      debugPrint('[OfflineQueue] processQueue START: ${queue.length} operations pending');
      for (var op in queue) {
        debugPrint('[OfflineQueue]   → ${op.operationType.name} '
            '${op.collection}/${op.docId} '
            '(priority: ${op.priority.name}, retries: ${op.retryCount})');
      }

      // Processa em batches para eficiência
      final batchSize = SyncConfig.instance.batchSize;
      final batches = _chunkList(queue, batchSize);

      for (var i = 0; i < batches.length; i++) {
        final batchOps = batches[i];
        debugPrint('[OfflineQueue] Processing batch ${i + 1}/${batches.length} '
            '(${batchOps.length} ops)');

        final batch = FirebaseFirestore.instance.batch();
        final processedOps = <OfflineOperation>[];

        for (var op in batchOps) {
          final ref = FirebaseFirestore.instance
              .collection(op.collection)
              .doc(op.docId);

          try {
            switch (op.operationType) {
              case OperationType.create:
              case OperationType.update:
                if (op.data != null) {
                  // Processa dados para substituir markers
                  final data = _processDataForUpload(op.data!);

                  // Merge true para updates parciais
                  batch.set(ref, data, SetOptions(merge: true));
                  processedOps.add(op);
                  debugPrint('[OfflineQueue]   ✓ Staged ${op.operationType.name}: '
                      '${op.collection}/${op.docId}');
                } else {
                  debugPrint('[OfflineQueue]   ✗ Skipped ${op.operationType.name}: '
                      '${op.collection}/${op.docId} (data is null)');
                }
                break;
              case OperationType.delete:
                batch.delete(ref);
                processedOps.add(op);
                debugPrint('[OfflineQueue]   ✓ Staged delete: '
                    '${op.collection}/${op.docId}');
                break;
            }
          } catch (e) {
            debugPrint('[OfflineQueue]   ✗ Error staging ${op.collection}/${op.docId}: $e');
            op.recordFailure(e.toString());
            op.save();
            failCount++;
          }
        }

        if (processedOps.isNotEmpty) {
          debugPrint('[OfflineQueue] Committing batch ${i + 1} '
              '(${processedOps.length} ops to Firestore)...');
          try {
            await batch
                .commit()
                .timeout(SyncConfig.instance.timeoutOnlineWrite);

            debugPrint('[OfflineQueue] ✓ Batch ${i + 1} committed successfully!');
            for (var op in processedOps) {
              await op.delete();
              successCount++;
            }
          } catch (e) {
            debugPrint('[OfflineQueue] ✗ Batch ${i + 1} FAILED: $e');
            for (var op in processedOps) {
              op.recordFailure(e.toString());
              await op.save();
              failCount++;
            }
          }
        }
      }

      debugPrint('[OfflineQueue] processQueue DONE: '
          '$successCount synced, $failCount failed, '
          '${getPendingCount()} remaining');

      if (successCount > 0 || failCount > 0) {
        _syncResultController.add(SyncResult(
          success: failCount == 0,
          syncedCount: successCount,
          failedCount: failCount,
          completedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('[OfflineQueue] processQueue ERROR: $e');
      _syncResultController.add(SyncResult.failure(e.toString()));
    } finally {
      _isProcessing = false;
    }
  }

  /// Helper para dividir lista em chunks
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<void> clearQueue() async {
    await _queueBox?.clear();
  }

  /// Remove uma operação específica da fila
  Future<void> removeFromQueue(String operationId) async {
    if (!_initialized) await init();
    if (_queueBox!.containsKey(operationId)) {
      await _queueBox!.delete(operationId);
    }
  }

  /// Reprocessa operações que falharam
  Future<void> retryFailed() async {
    await processQueue();
  }

  /// Processa dados para upload, substituindo markers por valores reais do Firestore
  Map<String, dynamic> _processDataForUpload(Map<String, dynamic> data) {
    if (!data.containsKey('_metadata')) return data;

    final processed = Map<String, dynamic>.from(data);
    final metadata = Map<String, dynamic>.from(processed['_metadata'] as Map);

    // Substitui marker de timestamp
    if (metadata['lastSyncAt'] == kServerTimestampMarker) {
      metadata['lastSyncAt'] = FieldValue.serverTimestamp();
    }

    processed['_metadata'] = metadata;
    return processed;
  }

  /// Verifica conexão com cache
  Future<bool> _checkConnection() async {
    if (!_isOnline) {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    }
    return _isOnline;
  }

  /// Helper público para verificar conexão
  Future<bool> hasNetworkConnection() => _checkConnection();
}
