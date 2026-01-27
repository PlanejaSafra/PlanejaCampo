import 'package:flutter_test/flutter_test.dart';
import 'package:agro_core/services/sync/sync_models.dart';

void main() {
  group('OfflineOperation', () {
    test('create() generates valid operation with UUID', () {
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.create,
        docId: 'doc123',
        data: {'milimetros': 25.0, 'observacao': 'chuva forte'},
        priority: OperationPriority.high,
        sourceApp: 'rurarain',
        farmId: 'farm456',
      );

      expect(op.id, isNotEmpty);
      expect(op.id.length, 36); // UUID v4 format
      expect(op.collection, 'registros_chuva');
      expect(op.operationType, OperationType.create);
      expect(op.docId, 'doc123');
      expect(op.data, isNotNull);
      expect(op.data!['milimetros'], 25.0);
      expect(op.priority, OperationPriority.high);
      expect(op.sourceApp, 'rurarain');
      expect(op.farmId, 'farm456');
      expect(op.retryCount, 0);
      expect(op.lastError, isNull);
      expect(op.timestamp, isNotNull);
    });

    test('create() for delete has null data', () {
      final op = OfflineOperation.create(
        collection: 'registros_chuva',
        operationType: OperationType.delete,
        docId: 'doc123',
        priority: OperationPriority.critical,
        sourceApp: 'rurarain',
      );

      expect(op.data, isNull);
      expect(op.operationType, OperationType.delete);
      expect(op.priority, OperationPriority.critical);
    });

    test('recordFailure() increments retryCount and sets lastError', () {
      final op = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.create,
        docId: 'doc1',
      );

      expect(op.retryCount, 0);
      expect(op.lastError, isNull);

      op.recordFailure('Connection timeout');
      expect(op.retryCount, 1);
      expect(op.lastError, 'Connection timeout');

      op.recordFailure('Server error');
      expect(op.retryCount, 2);
      expect(op.lastError, 'Server error');
    });

    test('hasExceededRetries is false before 5 retries', () {
      final op = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.update,
        docId: 'doc1',
      );

      for (var i = 0; i < 4; i++) {
        op.recordFailure('error $i');
      }
      expect(op.hasExceededRetries, isFalse);
      expect(op.retryCount, 4);
    });

    test('hasExceededRetries is true at 5 retries', () {
      final op = OfflineOperation.create(
        collection: 'test',
        operationType: OperationType.update,
        docId: 'doc1',
      );

      for (var i = 0; i < 5; i++) {
        op.recordFailure('error $i');
      }
      expect(op.hasExceededRetries, isTrue);
      expect(op.retryCount, 5);
    });

    group('compareTo (queue ordering)', () {
      test('critical operations come before high', () {
        final critical = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.delete,
          docId: 'doc1',
          priority: OperationPriority.critical,
        );
        final high = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc2',
          priority: OperationPriority.high,
        );

        expect(critical.compareTo(high), lessThan(0));
        expect(high.compareTo(critical), greaterThan(0));
      });

      test('high operations come before medium', () {
        final high = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc1',
          priority: OperationPriority.high,
        );
        final medium = OfflineOperation.create(
          collection: 'test',
          operationType: OperationType.update,
          docId: 'doc2',
          priority: OperationPriority.medium,
        );

        expect(high.compareTo(medium), lessThan(0));
      });

      test('same priority sorts by timestamp (oldest first)', () {
        final older = OfflineOperation(
          id: 'op1',
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc1',
          timestamp: DateTime(2026, 1, 1, 10, 0),
          priority: OperationPriority.high,
        );
        final newer = OfflineOperation(
          id: 'op2',
          collection: 'test',
          operationType: OperationType.create,
          docId: 'doc2',
          timestamp: DateTime(2026, 1, 1, 10, 5),
          priority: OperationPriority.high,
        );

        expect(older.compareTo(newer), lessThan(0));
        expect(newer.compareTo(older), greaterThan(0));
      });

      test('full priority ordering: critical < high < medium < low', () {
        final ops = [
          OfflineOperation.create(
            collection: 'test',
            operationType: OperationType.update,
            docId: 'low',
            priority: OperationPriority.low,
          ),
          OfflineOperation.create(
            collection: 'test',
            operationType: OperationType.create,
            docId: 'high',
            priority: OperationPriority.high,
          ),
          OfflineOperation.create(
            collection: 'test',
            operationType: OperationType.delete,
            docId: 'critical',
            priority: OperationPriority.critical,
          ),
          OfflineOperation.create(
            collection: 'test',
            operationType: OperationType.update,
            docId: 'medium',
            priority: OperationPriority.medium,
          ),
        ];

        ops.sort((a, b) => a.compareTo(b));

        expect(ops[0].docId, 'critical');
        expect(ops[1].docId, 'high');
        expect(ops[2].docId, 'medium');
        expect(ops[3].docId, 'low');
      });
    });
  });

  group('SyncMetadata', () {
    test('create() initializes with version 1 and pending status', () {
      final meta = SyncMetadata.create(
        sourceApp: 'rurarain',
        deviceId: 'device123',
      );

      expect(meta.version, 1);
      expect(meta.syncStatus, SyncStatus.pending);
      expect(meta.lastModifiedBy, 'rurarain');
      expect(meta.lastModifiedDevice, 'device123');
      expect(meta.hash, isNull);
      expect(meta.lastSyncAt, isNull);
    });

    test('copyWithUpdate() increments version', () {
      final meta = SyncMetadata.create(sourceApp: 'rurarain');
      final updated = meta.copyWithUpdate(
        hash: 'abc123',
        syncStatus: SyncStatus.synced,
      );

      expect(updated.version, 2);
      expect(updated.hash, 'abc123');
      expect(updated.syncStatus, SyncStatus.synced);
      expect(updated.lastModifiedBy, 'rurarain');
    });

    test('toMap/fromMap roundtrip preserves all fields', () {
      final original = SyncMetadata(
        version: 3,
        hash: 'hash_abc',
        lastSyncAt: DateTime(2026, 1, 15, 10, 30),
        syncStatus: SyncStatus.synced,
        lastModifiedBy: 'rurarain',
        lastModifiedDevice: 'pixel7',
      );

      final map = original.toMap();
      final restored = SyncMetadata.fromMap(map);

      expect(restored.version, 3);
      expect(restored.hash, 'hash_abc');
      expect(restored.lastSyncAt, DateTime(2026, 1, 15, 10, 30));
      expect(restored.syncStatus, SyncStatus.synced);
      expect(restored.lastModifiedBy, 'rurarain');
      expect(restored.lastModifiedDevice, 'pixel7');
    });

    test('fromMap() handles missing fields gracefully', () {
      final meta = SyncMetadata.fromMap({});

      expect(meta.version, 1);
      expect(meta.hash, isNull);
      expect(meta.lastSyncAt, isNull);
      expect(meta.syncStatus, SyncStatus.pending);
    });

    test('fromMap() handles invalid syncStatus gracefully', () {
      final meta = SyncMetadata.fromMap({
        'syncStatus': 'nonexistent_status',
      });

      expect(meta.syncStatus, SyncStatus.pending);
    });
  });

  group('SyncResult', () {
    test('success factory creates successful result', () {
      final result = SyncResult.success(count: 5);

      expect(result.success, isTrue);
      expect(result.syncedCount, 5);
      expect(result.failedCount, 0);
      expect(result.error, isNull);
    });

    test('failure factory creates failed result', () {
      final result = SyncResult.failure('Connection refused');

      expect(result.success, isFalse);
      expect(result.syncedCount, 0);
      expect(result.failedCount, 1);
      expect(result.error, 'Connection refused');
    });

    test('constructor allows mixed success/failure counts', () {
      final result = SyncResult(
        success: false,
        syncedCount: 3,
        failedCount: 2,
        conflictCount: 1,
        completedAt: DateTime.now(),
      );

      expect(result.syncedCount, 3);
      expect(result.failedCount, 2);
      expect(result.conflictCount, 1);
    });
  });

  group('Constants', () {
    test('kServerTimestampMarker is defined', () {
      expect(kServerTimestampMarker, isNotEmpty);
      expect(kServerTimestampMarker, '___SERVER_TIMESTAMP___');
    });
  });
}
