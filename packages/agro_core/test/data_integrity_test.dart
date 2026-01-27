import 'package:flutter_test/flutter_test.dart';
import 'package:agro_core/services/sync/data_integrity_manager.dart';
import 'package:agro_core/services/sync/sync_models.dart';
import 'package:agro_core/services/sync/sync_config.dart';

void main() {
  group('DataIntegrityManager', () {
    group('computeHash', () {
      test('produces consistent hash for same data', () {
        final data = {'nome': 'Fazenda Sol', 'area': 150.5};

        final hash1 = DataIntegrityManager.computeHash(data);
        final hash2 = DataIntegrityManager.computeHash(data);

        expect(hash1, equals(hash2));
        expect(hash1, isNotEmpty);
      });

      test('produces different hash for different data', () {
        final data1 = {'nome': 'Fazenda Sol', 'area': 150.5};
        final data2 = {'nome': 'Fazenda Lua', 'area': 200.0};

        final hash1 = DataIntegrityManager.computeHash(data1);
        final hash2 = DataIntegrityManager.computeHash(data2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('ignores key order (deterministic)', () {
        final data1 = {'a': 1, 'b': 2, 'c': 3};
        final data2 = {'c': 3, 'a': 1, 'b': 2};

        expect(
          DataIntegrityManager.computeHash(data1),
          equals(DataIntegrityManager.computeHash(data2)),
        );
      });

      test('excludes _metadata from hash calculation', () {
        final dataNoMeta = {'nome': 'Fazenda', 'area': 100};
        final dataWithMeta = {
          'nome': 'Fazenda',
          'area': 100,
          '_metadata': {
            'version': 1,
            'hash': 'old_hash',
            'syncStatus': 'pending',
          },
        };

        expect(
          DataIntegrityManager.computeHash(dataNoMeta),
          equals(DataIntegrityManager.computeHash(dataWithMeta)),
        );
      });

      test('does not modify original data', () {
        final data = {
          'nome': 'Fazenda',
          '_metadata': {'version': 1},
        };

        DataIntegrityManager.computeHash(data);

        expect(data.containsKey('_metadata'), isTrue);
        expect(data['nome'], 'Fazenda');
      });
    });

    group('validateDataIntegrity', () {
      test('returns true for data without metadata (legacy)', () {
        final data = {'nome': 'Fazenda', 'area': 100};

        expect(DataIntegrityManager.validateDataIntegrity(data), isTrue);
      });

      test('returns true for metadata without hash', () {
        final data = {
          'nome': 'Fazenda',
          '_metadata': {'version': 1, 'syncStatus': 'pending'},
        };

        expect(DataIntegrityManager.validateDataIntegrity(data), isTrue);
      });

      test('returns true when hash matches', () {
        final data = {'nome': 'Fazenda', 'area': 100};
        final hash = DataIntegrityManager.computeHash(data);

        data['_metadata'] = {'hash': hash, 'version': 1};

        expect(DataIntegrityManager.validateDataIntegrity(data), isTrue);
      });

      test('returns false when hash does not match (tampered data)', () {
        final data = {
          'nome': 'Fazenda',
          'area': 100,
          '_metadata': {
            'hash': 'wrong_hash_value',
            'version': 1,
            'syncStatus': 'synced',
          },
        };

        expect(DataIntegrityManager.validateDataIntegrity(data), isFalse);
      });
    });

    group('addFullMetadata', () {
      test('adds metadata to data without existing metadata', () {
        final data = {'nome': 'Fazenda Sol', 'milimetros': 25.0};

        final result = DataIntegrityManager.addFullMetadata(
          data,
          sourceApp: 'rurarain',
          status: SyncStatus.pending,
        );

        expect(result.containsKey('_metadata'), isTrue);
        expect(result['nome'], 'Fazenda Sol');
        expect(result['milimetros'], 25.0);

        final meta = result['_metadata'] as Map<String, dynamic>;
        expect(meta['version'], isNotNull);
        expect(meta['hash'], isNotEmpty);
        expect(meta['syncStatus'], 'pending');
        expect(meta['lastModifiedBy'], 'rurarain');
      });

      test('updates metadata on data with existing metadata', () {
        final data = {
          'nome': 'Fazenda',
          '_metadata': SyncMetadata.create(sourceApp: 'rurarain').toMap(),
        };

        final result = DataIntegrityManager.addFullMetadata(
          data,
          sourceApp: 'rurarain',
          status: SyncStatus.synced,
        );

        final meta = result['_metadata'] as Map<String, dynamic>;
        // Version should increment (was 1, copyWithUpdate makes it 2)
        expect(meta['version'], 2);
        expect(meta['syncStatus'], 'synced');
      });

      test('does not modify original data map', () {
        final data = {'nome': 'Fazenda', 'area': 100};
        final original = Map<String, dynamic>.from(data);

        DataIntegrityManager.addFullMetadata(data, sourceApp: 'test');

        expect(data, equals(original));
      });

      test('computed hash is valid for the data', () {
        final data = {'x': 1, 'y': 2, 'z': 3};

        final result = DataIntegrityManager.addFullMetadata(
          data,
          sourceApp: 'test',
        );

        expect(DataIntegrityManager.validateDataIntegrity(result), isTrue);
      });
    });

    group('hasConflict', () {
      test('no conflict when neither has metadata', () {
        final local = {'nome': 'Fazenda A'};
        final server = {'nome': 'Fazenda B'};

        expect(DataIntegrityManager.hasConflict(local, server), isFalse);
      });

      test('no conflict when only local has metadata', () {
        final local = {
          'nome': 'Fazenda',
          '_metadata': SyncMetadata.create().toMap(),
        };
        final server = {'nome': 'Fazenda'};

        expect(DataIntegrityManager.hasConflict(local, server), isFalse);
      });

      test('no conflict when hashes match', () {
        final hash = DataIntegrityManager.computeHash({'nome': 'Fazenda'});
        final meta = SyncMetadata(
          version: 1,
          hash: hash,
          syncStatus: SyncStatus.synced,
        ).toMap();

        final local = {'nome': 'Fazenda', '_metadata': meta};
        final server = {'nome': 'Fazenda', '_metadata': meta};

        expect(DataIntegrityManager.hasConflict(local, server), isFalse);
      });

      test('no conflict when local version > server version', () {
        final localMeta = SyncMetadata(
          version: 5,
          hash: 'local_hash',
          syncStatus: SyncStatus.pending,
        ).toMap();
        final serverMeta = SyncMetadata(
          version: 3,
          hash: 'server_hash',
          syncStatus: SyncStatus.synced,
        ).toMap();

        final local = {'nome': 'Local', '_metadata': localMeta};
        final server = {'nome': 'Server', '_metadata': serverMeta};

        expect(DataIntegrityManager.hasConflict(local, server), isFalse);
      });

      test('CONFLICT when server version > local AND local has pending changes',
          () {
        final localMeta = SyncMetadata(
          version: 2,
          hash: 'local_hash',
          syncStatus: SyncStatus.pending, // Has unsync'd changes
        ).toMap();
        final serverMeta = SyncMetadata(
          version: 5,
          hash: 'server_hash',
          syncStatus: SyncStatus.synced,
        ).toMap();

        final local = {'nome': 'Local Edit', '_metadata': localMeta};
        final server = {'nome': 'Server Edit', '_metadata': serverMeta};

        expect(DataIntegrityManager.hasConflict(local, server), isTrue);
      });

      test('no conflict when server > local but local is synced', () {
        final localMeta = SyncMetadata(
          version: 2,
          hash: 'local_hash',
          syncStatus: SyncStatus.synced, // Already synced, no local changes
        ).toMap();
        final serverMeta = SyncMetadata(
          version: 5,
          hash: 'server_hash',
          syncStatus: SyncStatus.synced,
        ).toMap();

        final local = {'nome': 'Old', '_metadata': localMeta};
        final server = {'nome': 'New', '_metadata': serverMeta};

        expect(DataIntegrityManager.hasConflict(local, server), isFalse);
      });
    });

    group('resolveConflict', () {
      late Map<String, dynamic> localData;
      late Map<String, dynamic> serverData;

      setUp(() {
        localData = {
          'nome': 'Local Edit',
          'area': 200,
          '_metadata': SyncMetadata(
            version: 2,
            hash: 'local_hash',
            syncStatus: SyncStatus.pending,
            lastModifiedBy: 'rurarain',
          ).toMap(),
        };
        serverData = {
          'nome': 'Server Edit',
          'area': 300,
          '_metadata': SyncMetadata(
            version: 5,
            hash: 'server_hash',
            syncStatus: SyncStatus.synced,
          ).toMap(),
        };
      });

      test('serverWins returns server data', () {
        final result = DataIntegrityManager.resolveConflict(
          localData,
          serverData,
          ConflictStrategy.serverWins,
        );

        expect(result['nome'], 'Server Edit');
        expect(result['area'], 300);
      });

      test('localWins keeps local data with bumped version', () {
        final result = DataIntegrityManager.resolveConflict(
          localData,
          serverData,
          ConflictStrategy.localWins,
        );

        expect(result['nome'], 'Local Edit');
        expect(result['area'], 200);
        // Version should be server version + 1
        expect(result['_metadata']['version'], 6);
      });

      test('merge combines both (local wins field-by-field)', () {
        final result = DataIntegrityManager.resolveConflict(
          localData,
          serverData,
          ConflictStrategy.merge,
        );

        // In merge strategy, local addAll overwrites server keys
        expect(result['nome'], 'Local Edit');
        expect(result['area'], 200);
        // Should have recalculated metadata
        expect(result.containsKey('_metadata'), isTrue);
      });
    });
  });
}
