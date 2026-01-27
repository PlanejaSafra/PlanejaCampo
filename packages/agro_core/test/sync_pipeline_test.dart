import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:agro_core/services/sync/sync_models.dart';
import 'package:agro_core/services/sync/data_integrity_manager.dart';


/// Concrete implementation of a sync service for testing.
/// Simulates what ChuvaService, LancamentoService, etc. do.
class TestItem {
  final String id;
  final String nome;
  final double valor;
  final String farmId;
  final DateTime criadoEm;

  TestItem({
    required this.id,
    required this.nome,
    required this.valor,
    required this.farmId,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'valor': valor,
        'farmId': farmId,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'] as String,
        nome: json['nome'] as String,
        valor: (json['valor'] as num).toDouble(),
        farmId: json['farmId'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    // Register Hive adapters for sync infrastructure
    Hive.registerAdapter(OfflineOperationAdapter());
    Hive.registerAdapter(OperationTypeAdapter());
    Hive.registerAdapter(OperationPriorityAdapter());
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Ignore cleanup errors on Windows
    }
  });

  group('Hive Adapter Serialization', () {
    test('OfflineOperation survives Hive put/get roundtrip', () async {
      final box = await Hive.openBox<OfflineOperation>('test_queue');

      final original = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'rain_001',
        data: {
          'milimetros': 25.5,
          'data': '2026-01-15',
          'observacao': 'chuva forte',
          'farmId': 'farm_123',
          '_metadata': {
            'version': 1,
            'hash': 'abc123',
            'syncStatus': 'pending',
            'lastModifiedBy': 'rurarain',
          },
        },
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
        farmId: 'farm_123',
      );

      await box.put(original.id, original);

      // Read back from Hive
      final restored = box.get(original.id)!;

      expect(restored.id, original.id);
      expect(restored.collection, 'registros_chuva');
      expect(restored.operationType, OperationType.create);
      expect(restored.docId, 'rain_001');
      expect(restored.priority, OperationPriority.high);
      expect(restored.sourceApp, 'rurarain');
      expect(restored.farmId, 'farm_123');
      expect(restored.retryCount, 0);

      // Verify nested data survived
      expect(restored.data, isNotNull);
      expect(restored.data!['milimetros'], 25.5);
      expect(restored.data!['observacao'], 'chuva forte');
      expect(restored.data!['_metadata']['version'], 1);

      await box.close();
    });

    test('OperationType enum values survive Hive roundtrip', () async {
      final box = await Hive.openBox<OfflineOperation>('test_enum');

      for (final opType in OperationType.values) {
        final op = OfflineOperation.create(
          collection: 'test',
          operationType: opType,
          docId: 'doc_${opType.name}',
        );
        await box.put(op.id, op);

        final restored = box.get(op.id)!;
        expect(restored.operationType, opType,
            reason: 'OperationType.${opType.name} failed roundtrip');
      }

      await box.close();
    });

    test('OperationPriority enum values survive Hive roundtrip', () async {
      final box = await Hive.openBox<OfflineOperation>('test_priority');

      for (final priority in OperationPriority.values) {
        final op = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc_${priority.name}',
          priority: priority,
        );
        await box.put(op.id, op);

        final restored = box.get(op.id)!;
        expect(restored.priority, priority,
            reason: 'OperationPriority.${priority.name} failed roundtrip');
      }

      await box.close();
    });

    test('OfflineOperation with null data (delete) survives roundtrip',
        () async {
      final box = await Hive.openBox<OfflineOperation>('test_delete');

      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.delete,
        docId: 'rain_to_delete',
        priority: OperationPriority.critical,
        sourceApp: 'rurarain',
      );

      await box.put(op.id, op);
      final restored = box.get(op.id)!;

      expect(restored.data, isNull);
      expect(restored.operationType, OperationType.delete);
      expect(restored.priority, OperationPriority.critical);

      await box.close();
    });
  });

  group('Queue Operations (simulating OfflineQueueManager)', () {
    late Box<OfflineOperation> queueBox;

    setUp(() async {
      queueBox = await Hive.openBox<OfflineOperation>('offline_queue_test');
    });

    tearDown(() async {
      await queueBox.clear();
      await queueBox.close();
    });

    test('addToQueue and retrieve', () async {
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'rain_001',
        data: {'milimetros': 15.0},
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
      );

      await queueBox.put(op.id, op);

      expect(queueBox.length, 1);
      expect(queueBox.get(op.id), isNotNull);
    });

    test('multiple operations in queue maintain correct count', () async {
      for (var i = 0; i < 10; i++) {
        final op = OfflineOperation.create(
          collection: 'registros_chuva',
          operationType: OperationType.create,
          docId: 'rain_$i',
          data: {'milimetros': i * 5.0},
          priority: OperationPriority.high,
          sourceApp: 'rurarain',
        );
        await queueBox.put(op.id, op);
      }

      expect(queueBox.length, 10);
    });

    test('queue sorts by priority then timestamp', () async {
      // Add in wrong order
      final low = OfflineOperation(
        id: 'op_low',
        collection: 'test',
        operationType: OperationType.update,
        docId: 'doc_low',
        timestamp: DateTime(2026, 1, 1, 10, 0),
        priority: OperationPriority.low,
      );
      final critical = OfflineOperation(
        id: 'op_critical',
        collection: 'test',
        operationType: OperationType.delete,
        docId: 'doc_critical',
        timestamp: DateTime(2026, 1, 1, 10, 5),
        priority: OperationPriority.critical,
      );
      final high = OfflineOperation(
        id: 'op_high',
        collection: 'test',
        operationType: OperationType.create,
        docId: 'doc_high',
        timestamp: DateTime(2026, 1, 1, 10, 2),
        priority: OperationPriority.high,
      );

      await queueBox.put(low.id, low);
      await queueBox.put(critical.id, critical);
      await queueBox.put(high.id, high);

      // Sort like OfflineQueueManager.getQueue() does
      final sorted = queueBox.values.toList();
      sorted.sort((a, b) => a.compareTo(b));

      expect(sorted[0].id, 'op_critical');
      expect(sorted[1].id, 'op_high');
      expect(sorted[2].id, 'op_low');
    });

    test('removeFromQueue deletes specific operation', () async {
      final op1 = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.create,
        docId: 'doc1',
      );
      final op2 = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.create,
        docId: 'doc2',
      );

      await queueBox.put(op1.id, op1);
      await queueBox.put(op2.id, op2);

      expect(queueBox.length, 2);

      await queueBox.delete(op1.id);

      expect(queueBox.length, 1);
      expect(queueBox.get(op1.id), isNull);
      expect(queueBox.get(op2.id), isNotNull);
    });

    test('clearQueue removes all operations', () async {
      for (var i = 0; i < 5; i++) {
        final op = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc_$i',
        );
        await queueBox.put(op.id, op);
      }

      expect(queueBox.length, 5);

      await queueBox.clear();

      expect(queueBox.length, 0);
    });

    test('retry state persists in queue', () async {
      final op = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.create,
        docId: 'flaky_doc',
        data: {'value': 42},
      );

      await queueBox.put(op.id, op);

      // Simulate failure
      final retrieved = queueBox.get(op.id)!;
      retrieved.recordFailure('Network error');
      await queueBox.put(retrieved.id, retrieved);

      // Verify retry state persisted
      final afterRetry = queueBox.get(op.id)!;
      expect(afterRetry.retryCount, 1);
      expect(afterRetry.lastError, 'Network error');
    });
  });

  group('LocalCacheManager (Hive-based)', () {
    test('openBox creates and returns a box', () async {
      final box = await Hive.openBox<dynamic>('test_cache');

      expect(box.isOpen, isTrue);
      expect(box.length, 0);

      await box.close();
    });

    test('stores and retrieves Map data (like GenericSyncService)', () async {
      final box = await Hive.openBox<dynamic>('registro_cache');

      final data = {
        'id': 'rain_001',
        'milimetros': 25.5,
        'data': '2026-01-15T00:00:00.000',
        'farmId': 'farm_123',
        'observacao': 'chuva forte',
      };

      // This is exactly what GenericSyncService._save() does
      final dataWithMeta = DataIntegrityManager.addFullMetadata(
        data,
        sourceApp: 'rurarain',
        status: SyncStatus.pending,
      );

      await box.put('rain_001', dataWithMeta);

      // Read back
      final restored = box.get('rain_001') as Map;
      final restoredMap = Map<String, dynamic>.from(restored);

      expect(restoredMap['id'], 'rain_001');
      expect(restoredMap['milimetros'], 25.5);
      expect(restoredMap['farmId'], 'farm_123');
      expect(restoredMap.containsKey('_metadata'), isTrue);

      final meta =
          SyncMetadata.fromMap(restoredMap['_metadata'] as Map<String, dynamic>);
      expect(meta.syncStatus, SyncStatus.pending);
      expect(meta.lastModifiedBy, 'rurarain');
      expect(meta.hash, isNotEmpty);

      // Verify integrity
      expect(DataIntegrityManager.validateDataIntegrity(restoredMap), isTrue);

      await box.close();
    });

    test('sync timestamp tracking works', () async {
      final metaBox = await Hive.openBox<dynamic>('sync_meta_test');

      final now = DateTime.now();
      await metaBox.put(
          'last_sync_registros_chuva', now.millisecondsSinceEpoch);

      final restored = metaBox.get('last_sync_registros_chuva') as int;
      final restoredDt = DateTime.fromMillisecondsSinceEpoch(restored);

      expect(restoredDt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);

      await metaBox.close();
    });
  });

  group('Full Pipeline Simulation (Local)', () {
    late Box<dynamic> dataBox;
    late Box<OfflineOperation> queueBox;

    setUp(() async {
      dataBox = await Hive.openBox<dynamic>('registros_chuva_test');
      queueBox =
          await Hive.openBox<OfflineOperation>('offline_queue_pipeline');
    });

    tearDown(() async {
      await dataBox.clear();
      await queueBox.clear();
      await dataBox.close();
      await queueBox.close();
    });

    test('simulates ChuvaService.adicionar() complete pipeline', () async {
      // 1. Create a rainfall record (like RegistroChuva.create)
      final registro = {
        'id': '1737936000000',
        'data': '2026-01-27T00:00:00.000',
        'milimetros': 32.0,
        'observacao': 'temporal forte',
        'propertyId': 'prop_fazenda_sol',
        'talhaoId': 'talhao_01',
        'criadoEm': DateTime.now().toIso8601String(),
        'createdBy': 'user_abc123',
        'sourceApp': 'rurarain',
        'farmId': 'prop_fazenda_sol',
      };

      // 2. GenericSyncService._save() adds metadata
      final dataWithMeta = DataIntegrityManager.addFullMetadata(
        registro,
        sourceApp: 'rurarain',
        status: SyncStatus.pending,
      );

      // 3. Save to local Hive box
      final id = registro['id'] as String;
      await dataBox.put(id, dataWithMeta);

      // 4. Queue operation for sync (what addToQueue does)
      final uploadData = Map<String, dynamic>.from(dataWithMeta);
      final meta =
          Map<String, dynamic>.from(uploadData['_metadata'] as Map);
      meta['lastSyncAt'] = kServerTimestampMarker;
      uploadData['_metadata'] = meta;

      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: id,
        data: uploadData,
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
        farmId: 'prop_fazenda_sol',
      );

      await queueBox.put(op.id, op);

      // VERIFY: Local data is correct
      final localData =
          Map<String, dynamic>.from(dataBox.get(id) as Map);
      expect(localData['milimetros'], 32.0);
      expect(localData['observacao'], 'temporal forte');
      expect(localData['farmId'], 'prop_fazenda_sol');
      expect(DataIntegrityManager.validateDataIntegrity(localData), isTrue);

      // VERIFY: Queue has the operation
      expect(queueBox.length, 1);
      final queuedOp = queueBox.values.first;
      expect(queuedOp.collection, 'registros_chuva');
      expect(queuedOp.operationType, OperationType.create);
      expect(queuedOp.docId, id);
      expect(queuedOp.sourceApp, 'rurarain');

      // VERIFY: Queue data has server timestamp marker
      expect(queuedOp.data!['_metadata']['lastSyncAt'],
          kServerTimestampMarker);

      // VERIFY: Queue data payload matches what Firestore would receive
      expect(queuedOp.data!['milimetros'], 32.0);
      expect(queuedOp.data!['farmId'], 'prop_fazenda_sol');
      expect(queuedOp.data!['sourceApp'], 'rurarain');

      debugPrint('✓ Pipeline simulation: local save OK, queue OK, '
          'data integrity OK');
    });

    test('simulates update flow', () async {
      // Initial save
      final original = {
        'id': 'rain_update_test',
        'milimetros': 10.0,
        'farmId': 'farm1',
      };
      final originalWithMeta = DataIntegrityManager.addFullMetadata(
        original,
        sourceApp: 'rurarain',
      );
      await dataBox.put('rain_update_test', originalWithMeta);

      // Update
      final updated = {
        'id': 'rain_update_test',
        'milimetros': 25.0, // Changed
        'farmId': 'farm1',
      };
      final updatedWithMeta = DataIntegrityManager.addFullMetadata(
        updated,
        sourceApp: 'rurarain',
      );
      await dataBox.put('rain_update_test', updatedWithMeta);

      // Queue update operation
      final uploadData = Map<String, dynamic>.from(updatedWithMeta);
      final meta =
          Map<String, dynamic>.from(uploadData['_metadata'] as Map);
      meta['lastSyncAt'] = kServerTimestampMarker;
      uploadData['_metadata'] = meta;

      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.update,
        docId: 'rain_update_test',
        data: uploadData,
        priority: OperationPriority.medium,
        sourceApp: 'rurarain',
      );
      await queueBox.put(op.id, op);

      // VERIFY
      final localData = Map<String, dynamic>.from(
          dataBox.get('rain_update_test') as Map);
      expect(localData['milimetros'], 25.0);

      final localMeta =
          SyncMetadata.fromMap(localData['_metadata'] as Map<String, dynamic>);
      expect(localMeta.version, 2); // Version bumped

      final queuedOp = queueBox.values.first;
      expect(queuedOp.operationType, OperationType.update);
      expect(queuedOp.priority, OperationPriority.medium);
    });

    test('simulates delete flow', () async {
      // Save then delete
      final data = {'id': 'rain_delete', 'milimetros': 5.0, 'farmId': 'f1'};
      final withMeta = DataIntegrityManager.addFullMetadata(
        data,
        sourceApp: 'rurarain',
      );
      await dataBox.put('rain_delete', withMeta);
      expect(dataBox.containsKey('rain_delete'), isTrue);

      // Delete from local
      await dataBox.delete('rain_delete');
      expect(dataBox.containsKey('rain_delete'), isFalse);

      // Queue delete operation
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.delete,
        docId: 'rain_delete',
        priority: OperationPriority.critical,
        sourceApp: 'rurarain',
      );
      await queueBox.put(op.id, op);

      // VERIFY
      expect(queueBox.length, 1);
      final queuedOp = queueBox.values.first;
      expect(queuedOp.operationType, OperationType.delete);
      expect(queuedOp.data, isNull);
      expect(queuedOp.priority, OperationPriority.critical);
    });

    test('simulates batch of mixed operations', () async {
      // Create 3 records, update 1, delete 1
      for (var i = 0; i < 3; i++) {
        final data = {
          'id': 'batch_$i',
          'milimetros': (i + 1) * 10.0,
          'farmId': 'farm1',
        };
        final withMeta = DataIntegrityManager.addFullMetadata(
          data,
          sourceApp: 'rurarain',
        );
        await dataBox.put('batch_$i', withMeta);

        final op = OfflineOperation.create(
          collection: 'registros_chuva',
          operationType: OperationType.create,
          docId: 'batch_$i',
          data: withMeta,
          priority: OperationPriority.high,
          sourceApp: 'rurarain',
        );
        await queueBox.put(op.id, op);
      }

      // Update batch_1
      final updated = {
        'id': 'batch_1',
        'milimetros': 99.0,
        'farmId': 'farm1',
      };
      final updatedMeta = DataIntegrityManager.addFullMetadata(
        updated,
        sourceApp: 'rurarain',
      );
      await dataBox.put('batch_1', updatedMeta);
      final updateOp = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.update,
        docId: 'batch_1',
        data: updatedMeta,
        priority: OperationPriority.medium,
        sourceApp: 'rurarain',
      );
      await queueBox.put(updateOp.id, updateOp);

      // Delete batch_2
      await dataBox.delete('batch_2');
      final deleteOp = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.delete,
        docId: 'batch_2',
        priority: OperationPriority.critical,
        sourceApp: 'rurarain',
      );
      await queueBox.put(deleteOp.id, deleteOp);

      // VERIFY local state
      expect(dataBox.length, 2); // batch_0 and batch_1 (batch_2 deleted)
      expect(dataBox.containsKey('batch_0'), isTrue);
      expect(dataBox.containsKey('batch_1'), isTrue);
      expect(dataBox.containsKey('batch_2'), isFalse);

      // VERIFY queue state
      expect(queueBox.length, 5); // 3 creates + 1 update + 1 delete

      // VERIFY queue ordering
      final sorted = queueBox.values.toList();
      sorted.sort((a, b) => a.compareTo(b));

      // Critical (delete) first, then high (creates), then medium (update)
      expect(sorted[0].operationType, OperationType.delete);
      expect(sorted[0].priority, OperationPriority.critical);

      // Next 3 should be high priority (creates)
      for (var i = 1; i <= 3; i++) {
        expect(sorted[i].priority, OperationPriority.high);
      }

      // Last should be medium priority (update)
      expect(sorted[4].priority, OperationPriority.medium);
      expect(sorted[4].operationType, OperationType.update);

      debugPrint('✓ Batch simulation: ${queueBox.length} ops queued, '
          'ordering correct, local state consistent');
    });

    test('simulates processQueue success (removes from queue)', () async {
      // Add operation to queue
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'rain_sync',
        data: {'milimetros': 10.0},
        priority: OperationPriority.high,
      );
      await queueBox.put(op.id, op);

      expect(queueBox.length, 1);

      // Simulate successful processQueue: delete from queue
      await queueBox.delete(op.id);

      expect(queueBox.length, 0);

      debugPrint('✓ Simulated processQueue success: op removed from queue');
    });

    test('simulates processQueue failure (retry persisted)', () async {
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'rain_flaky',
        data: {'milimetros': 10.0},
        priority: OperationPriority.high,
      );
      await queueBox.put(op.id, op);

      // Simulate failure
      final retrieved = queueBox.get(op.id)!;
      retrieved.recordFailure('Firestore write timeout');
      await queueBox.put(retrieved.id, retrieved);

      // Verify retry state
      final afterFail = queueBox.get(op.id)!;
      expect(afterFail.retryCount, 1);
      expect(afterFail.lastError, 'Firestore write timeout');
      expect(afterFail.hasExceededRetries, isFalse);

      // Simulate 4 more failures (total 5)
      for (var i = 0; i < 4; i++) {
        final current = queueBox.get(op.id)!;
        current.recordFailure('Retry $i');
        await queueBox.put(current.id, current);
      }

      final afterMaxRetries = queueBox.get(op.id)!;
      expect(afterMaxRetries.retryCount, 5);
      expect(afterMaxRetries.hasExceededRetries, isTrue);

      debugPrint('✓ Retry logic works: ${afterMaxRetries.retryCount} retries, '
          'exceeded=${afterMaxRetries.hasExceededRetries}');
    });
  });

  group('Cross-App Scenarios', () {
    late Box<OfflineOperation> queueBox;

    setUp(() async {
      queueBox = await Hive.openBox<OfflineOperation>('cross_app_queue');
    });

    tearDown(() async {
      await queueBox.clear();
      await queueBox.close();
    });

    test('queue handles operations from multiple apps', () async {
      // RuraRain operation
      final rainOp = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'rain_001',
        data: {'milimetros': 25.0},
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
        farmId: 'farm1',
      );

      // RuraCash operation
      final cashOp = OfflineOperation.create(
        collection: 'lancamentos',
        operationType: OperationType.create,
        docId: 'cash_001',
        data: {'valor': 1500.0, 'categoria': 'insumos'},
        priority: OperationPriority.high,
        sourceApp: 'ruracash',
        farmId: 'farm1',
      );

      // RuraRubber operation
      final rubberOp = OfflineOperation.create(
        collection: 'entregas',
        operationType: OperationType.update,
        docId: 'rubber_001',
        data: {'peso': 450.0},
        priority: OperationPriority.medium,
        sourceApp: 'rurarubber',
        farmId: 'farm1',
      );

      await queueBox.put(rainOp.id, rainOp);
      await queueBox.put(cashOp.id, cashOp);
      await queueBox.put(rubberOp.id, rubberOp);

      expect(queueBox.length, 3);

      // Verify each operation maintains its identity
      final allOps = queueBox.values.toList();

      final rainOps =
          allOps.where((op) => op.sourceApp == 'rurarain').toList();
      final cashOps =
          allOps.where((op) => op.sourceApp == 'ruracash').toList();
      final rubberOps =
          allOps.where((op) => op.sourceApp == 'rurarubber').toList();

      expect(rainOps.length, 1);
      expect(cashOps.length, 1);
      expect(rubberOps.length, 1);

      expect(rainOps.first.collection, 'registros_chuva');
      expect(cashOps.first.collection, 'lancamentos');
      expect(rubberOps.first.collection, 'entregas');
    });

    test('queue sorts cross-app operations by priority', () async {
      final deleteRubber = OfflineOperation.create(
        collection: 'entregas',
        operationType: OperationType.delete,
        docId: 'del_rubber',
        priority: OperationPriority.critical,
        sourceApp: 'rurarubber',
      );
      final createRain = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'create_rain',
        data: {'mm': 10},
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
      );
      final updateCash = OfflineOperation.create(
        collection: 'lancamentos',
        operationType: OperationType.update,
        docId: 'update_cash',
        data: {'valor': 200},
        priority: OperationPriority.medium,
        sourceApp: 'ruracash',
      );

      await queueBox.put(updateCash.id, updateCash);
      await queueBox.put(createRain.id, createRain);
      await queueBox.put(deleteRubber.id, deleteRubber);

      final sorted = queueBox.values.toList();
      sorted.sort((a, b) => a.compareTo(b));

      expect(sorted[0].sourceApp, 'rurarubber'); // critical delete
      expect(sorted[1].sourceApp, 'rurarain'); // high create
      expect(sorted[2].sourceApp, 'ruracash'); // medium update
    });
  });
}
