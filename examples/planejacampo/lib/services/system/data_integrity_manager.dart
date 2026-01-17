import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejacampo/services/device_info_service.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';

class DataIntegrityManager {
  // Em DataIntegrityManager, modificar para armazenar o hash em cache:
  static final Map<String, String> _hashCache = {};
  static const int _maxHashCacheSize = 1000;

  static String calculateHash(Map<String, dynamic> data) {
    try {
      // Criar uma chave única para o cache
      final String cacheKey = data.containsKey('id') ? '${data['id']}:${data['_metadata']?['version'] ?? 0}' : '';

      // Verificar cache primeiro
      if (cacheKey.isNotEmpty && _hashCache.containsKey(cacheKey)) {
        return _hashCache[cacheKey]!;
      }

      final Map<String, dynamic> dataCopy = Map<String, dynamic>.from(data);
      final Map<String, dynamic> dataWithoutMetadata = Map.from(dataCopy)..remove('_metadata');
      final Map<String, dynamic> convertedData = _convertDataForHashing(dataWithoutMetadata);
      final sortedKeys = convertedData.keys.toList()..sort();
      final orderedData = Map.fromEntries(sortedKeys.map((key) => MapEntry(key, convertedData[key])));
      final jsonString = json.encode(orderedData);
      final hash = sha256.convert(utf8.encode(jsonString)).toString();

      // Armazenar no cache se tivermos uma chave
      if (cacheKey.isNotEmpty) {
        // Limitar tamanho do cache
        if (_hashCache.length > _maxHashCacheSize) {
          final keysToRemove = _hashCache.keys.take((_maxHashCacheSize * 0.2).toInt()).toList();
          for (var key in keysToRemove) {
            _hashCache.remove(key);
          }
        }

        _hashCache[cacheKey] = hash;
      }

      return hash;
    } catch (e) {
      print('Erro ao calcular hash: $e');
      return sha256.convert(utf8.encode(data.toString())).toString();
    }
  }

  static Map<String, dynamic> _convertDataForHashing(Map<String, dynamic> data) {
    final result = Map<String, dynamic>();
    data.forEach((key, value) {
      if (value == null) {
        result[key] = null;
      } else if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is Map) {
        result[key] = _convertDataForHashing(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = _convertListForHashing(value);
      } else if (value is num) {
        result[key] = value.toString();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static List _convertListForHashing(List items) {
    return items.map((item) {
      if (item == null) return null;
      if (item is Timestamp) return item.toDate().toIso8601String();
      if (item is DateTime) return item.toIso8601String();
      if (item is Map) return _convertDataForHashing(Map<String, dynamic>.from(item));
      if (item is List) return _convertListForHashing(item);
      if (item is num) return item.toString();
      return item;
    }).toList();
  }

  static Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    final result = Map<String, dynamic>();
    data.forEach((key, value) {
      if (value == null) {
        result[key] = null;
      } else if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is Map) {
        result[key] = _normalizeData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = _normalizeList(value);
      } else if (value is num) {
        result[key] = value.toString();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static List _normalizeList(List items) {
    return items.map((item) {
      if (item == null) return null;
      if (item is Timestamp) return item.toDate().toIso8601String();
      if (item is DateTime) return item.toIso8601String();
      if (item is Map) return _normalizeData(Map<String, dynamic>.from(item));
      if (item is List) return _normalizeList(item);
      if (item is num) return item.toString();
      return item;
    }).toList();
  }

  // Em DataIntegrityManager, melhore a verificação de hash:
  static bool validateDataIntegrity(Map<String, dynamic> data, {bool strictMode = false}) {
    try {
      // Verificação básica da estrutura de metadados antes de tentar acessar campos
      if (!data.containsKey('_metadata') || !(data['_metadata'] is Map)) {
        return false;
      }

      final metadata = data['_metadata'] as Map<String, dynamic>;
      if (!metadata.containsKey('hash') || metadata['hash'] == null) {
        return false;
      }

      // Se não for em modo estrito, considere válido se tem hash, mesmo sem verificar
      if (!strictMode) {
        return true;
      }

      // Apenas em modo estrito faz a verificação completa do hash
      final storedHash = metadata['hash'];
      final calculatedHash = calculateHash(data);
      return calculatedHash == storedHash;
    } catch (e) {
      print('Erro na validação de integridade: $e');
      return false;
    }
  }

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[key] = _convertTimestamps(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = _convertListTimestamps(value);
      }
    });
    return result;
  }

  static List _convertListTimestamps(List items) {
    return items.map((item) {
      if (item is Timestamp) return item.toDate().toIso8601String();
      if (item is Map) return _convertTimestamps(Map<String, dynamic>.from(item));
      if (item is List) return _convertListTimestamps(item);
      return item;
    }).toList();
  }

  static bool hasValidHash(Map<String, dynamic> data) {
    if (!data.containsKey('_metadata')) return false;
    return data['_metadata']['hash'] != null;
  }

  static Map<String, dynamic> addIntegrityHash(Map<String, dynamic> data) {
    final hash = calculateHash(data);
    final currentVersion = data['_metadata']?['version'] ?? 0;
    final metadata = {
      'version': currentVersion + 1,
      'lastModified': DateTime.now().toIso8601String(),
      'hash': hash,
      'syncStatus': 'pending',
    };
    return {...data, '_metadata': metadata};
  }

  static Future<Map<String, dynamic>> addFullMetadata(Map<String, dynamic> data, {bool updateFirestore = false, String? collectionPath, String? docId}) async {
    if (data.containsKey('_metadata') &&
        data['_metadata'] is Map &&
        data['_metadata'].containsKey('hash') &&
        (data['_metadata']['hash'] as String).isNotEmpty) {
      return data;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final deviceId = await DeviceInfoService().getDeviceId();

    // Criar metadados baseados nos existentes, se houver
    Map<String, dynamic> existingMetadata = {};
    if (data.containsKey('_metadata') && data['_metadata'] is Map) {
      existingMetadata = Map<String, dynamic>.from(data['_metadata']);
    }

    // Adicionar hash e outros campos necessários
    final hash = calculateHash(data);
    final metadata = {
      ...existingMetadata,
      'version': (existingMetadata['version'] ?? 0) + 1,
      'lastModified': DateTime.now().toIso8601String(),
      'hash': hash,
      'syncStatus': 'synced',
      'lastModifiedBy': currentUser?.uid ?? 'unknown',
      'deviceId': deviceId,
    };

    // Criar uma cópia com os novos metadados
    final Map<String, dynamic> dataWithMetadata = Map<String, dynamic>.from(data);
    dataWithMetadata['_metadata'] = metadata;

    // Se solicitado e se temos as informações necessárias, atualizar diretamente no Firestore
    if (updateFirestore && collectionPath != null && docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .doc(docId)
            .update({'_metadata': metadata});

        print('Metadados atualizados com sucesso no Firestore para $collectionPath/$docId');
      } catch (e) {
        print('Erro ao atualizar metadados no Firestore: $e');

        // Em caso de erro, tentar com set + merge
        try {
          await FirebaseFirestore.instance
              .collection(collectionPath)
              .doc(docId)
              .set({'_metadata': metadata}, SetOptions(merge: true));

          print('Metadados atualizados com sucesso usando set+merge para $collectionPath/$docId');
        } catch (e) {
          print('Erro ao atualizar metadados usando set+merge: $e');
        }
      }
    }

    return dataWithMetadata;
  }

  // Adicionar à classe DataIntegrityManager:
  static bool _batchMetadataFixRunning = false;
  static Set<String> _processedDocuments = {};

// Método para corrigir documentos sem hash em lote
  static Future<void> fixMetadataForCollection(String collection, List<String> docIds) async {
    if (_batchMetadataFixRunning) {
      print('Já existe uma operação de correção em lote em andamento. Ignorando.');
      return;
    }

    _batchMetadataFixRunning = true;

    try {
      print('Iniciando correção de metadados em lote para coleção $collection (${docIds.length} documentos)');
      int fixed = 0;

      // Processar em pequenos lotes para não sobrecarregar
      final chunks = <List<String>>[];
      for (var i = 0; i < docIds.length; i += 10) {
        final end = (i + 10 < docIds.length) ? i + 10 : docIds.length;
        chunks.add(docIds.sublist(i, end));
      }

      for (var chunk in chunks) {
        for (var docId in chunk) {
          final cacheKey = '$collection:$docId';

          // Pular documentos já processados
          if (_processedDocuments.contains(cacheKey)) continue;

          try {
            final doc = await FirebaseFirestore.instance.collection(collection).doc(docId).get();
            if (doc.exists && doc.data() != null) {
              var data = Map<String, dynamic>.from(doc.data()!);
              data['id'] = doc.id;

              if (!hasValidHash(data)) {
                final updatedData = await addFullMetadata(
                    data,
                    updateFirestore: true,
                    collectionPath: collection,
                    docId: docId
                );

                // Atualizar cache local
                await LocalCacheManager.updateCache(collection, docId, updatedData);

                fixed++;
                print('Metadados corrigidos para $collection/$docId');
              }

              // Marcar como processado
              _processedDocuments.add(cacheKey);
            }
          } catch (e) {
            print('Erro ao processar documento $collection/$docId: $e');
          }

          // Pequena pausa para não sobrecarregar
          await Future.delayed(Duration(milliseconds: 50));
        }
      }

      print('Correção em lote concluída: $fixed documentos foram atualizados');
    } finally {
      _batchMetadataFixRunning = false;
    }
  }


  static bool hasStoredConflict(Map<String, dynamic> data) {
    return data['_metadata']?['conflictData'] != null;
  }

  static Future<bool> hasConflict(String collection, String id, Map<String, dynamic> localData) async {
    try {
      final serverDoc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
      if (!serverDoc.exists) return false;
      final serverData = serverDoc.data()!;
      final localVersion = localData['_metadata']?['version'] ?? 0;
      final serverVersion = serverData['_metadata']?['version'] ?? 0;
      if (localVersion != serverVersion) return true;
      final localHash = localData['_metadata']?['hash'];
      final serverHash = serverData['_metadata']?['hash'];
      if (localHash != null && serverHash != null && localHash != serverHash) return true;
      return false;
    } catch (e) {
      print('Erro ao verificar conflitos: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> resolveConflict(
      String collection,
      String id,
      Map<String, dynamic> localData,
      Map<String, dynamic> serverData) async {
    final int localVersion = (localData['_metadata']?['version'] ?? 0) as int;
    final int serverVersion = (serverData['_metadata']?['version'] ?? 0) as int;
    final localTimestamp = DateTime.parse(localData['_metadata']?['lastModified'] ?? '1970-01-01');
    final serverTimestamp = DateTime.parse(serverData['_metadata']?['lastModified'] ?? '1970-01-01');

    print('Local data antes do merge: $localData');
    print('Server data antes do merge: $serverData');
    print('Local cargaInicial antes do merge: ${localData['cargaInicial']}');
    print('Server cargaInicial antes do merge: ${serverData['cargaInicial']}');

    var mergedData = Map<String, dynamic>.from(serverData);
    final nonMergeableFields = ['status', 'valor', 'saldo', 'total'];
    final preserveLocalFields = ['cargaInicial'];
    final mergedFields = <String>{};

    // Sempre realizar o merge, mesmo com diferença de versão significativa
    localData.forEach((key, localValue) {
      if (key == '_metadata') return;

      final serverValue = serverData[key];

      if (preserveLocalFields.contains(key)) {
        print('Preservando valor local para $key: $localValue');
        mergedData[key] = localValue;
        mergedFields.add(key);
      } else if (nonMergeableFields.contains(key) && localTimestamp != serverTimestamp) {
        mergedData[key] = localTimestamp.isAfter(serverTimestamp) ? localValue : serverValue;
        mergedFields.add(key);
      } else if (serverValue == null) {
        mergedData[key] = localValue;
        mergedFields.add(key);
      } else if (serverValue != localValue) {
        if (localValue is List && serverValue is List) {
          print('Mesclando array para $key - local: $localValue, server: $serverValue');
          mergedData[key] = _mergeArrays(localValue, serverValue, localTimestamp, serverTimestamp, key);
          mergedFields.add(key);
        } else if (localValue is Map && serverValue is Map) {
          mergedData[key] = _mergeObjects(
            Map<String, dynamic>.from(serverValue),
            Map<String, dynamic>.from(localValue),
            localTimestamp,
            serverTimestamp,
          );
          mergedFields.add(key);
        } else {
          mergedData[key] = localTimestamp.isAfter(serverTimestamp) ? localValue : serverValue;
          mergedFields.add(key);
        }
      }
    });

    mergedData['_metadata'] = {
      'version': max(localVersion, serverVersion) + 1,
      'lastModified': DateTime.now().toIso8601String(),
      'lastModifiedBy': localData['_metadata']?['lastModifiedBy'],
      'deviceId': localData['_metadata']?['deviceId'],
      'syncStatus': 'merged',
      'hash': calculateHash(mergedData),
      'conflictResolution': {
        'localVersion': localVersion,
        'serverVersion': serverVersion,
        'mergeTimestamp': DateTime.now().toIso8601String(),
      },
    };

    print('Merged cargaInicial após o merge: ${mergedData['cargaInicial']}');
    print('Merged data após o merge: $mergedData');
    print('Campos mesclados: ${mergedFields.toString()}');

    return mergedData;
  }

  static List<dynamic> _mergeArrays(
      List<dynamic> localArray,
      List<dynamic> serverArray,
      DateTime localTimestamp,
      DateTime serverTimestamp,
      String fieldName) {
    print('Iniciando merge de arrays para $fieldName - local: $localArray, server: $serverArray');

    if (localArray.isEmpty) {
      print('Array local vazio, retornando server: $serverArray');
      return List.from(serverArray);
    }
    if (serverArray.isEmpty) {
      print('Array server vazio, retornando local: $localArray');
      return List.from(localArray);
    }

    bool isObjectArray = localArray.isNotEmpty &&
        serverArray.isNotEmpty &&
        localArray.first is Map &&
        serverArray.first is Map;

    if (!isObjectArray) {
      var result = [...serverArray, ...localArray].toSet().toList();
      print('Array não é de objetos, união simples: $result');
      return result;
    }

    final idFieldsByArray = {
      'cargaInicial': 'siglaPais',
      'permissoes': 'usuarioId',
      'licencas': 'tipo',
    };

    String? idField = idFieldsByArray[fieldName];
    if (idField == null) {
      final knownIdFields = ['siglaPais', 'id', 'uuid', 'codigo', 'usuarioId', 'tipo'];
      for (var field in knownIdFields) {
        if (localArray.every((item) => item is Map && item.containsKey(field)) &&
            serverArray.every((item) => item is Map && item.containsKey(field))) {
          idField = field;
          break;
        }
      }
    }

    if (idField != null) {
      print('Usando $idField como chave para merge de $fieldName');
      Map<dynamic, Map<String, dynamic>> mergedById = {};
      for (var item in serverArray) {
        if (item is Map && item.containsKey(idField)) {
          mergedById[item[idField]] = Map<String, dynamic>.from(item);
        }
      }
      for (var item in localArray) {
        if (item is Map && item.containsKey(idField)) {
          final id = item[idField];
          if (mergedById.containsKey(id)) {
            mergedById[id] = _mergeObjects(
              mergedById[id]!,
              Map<String, dynamic>.from(item),
              localTimestamp,
              serverTimestamp,
            );
          } else {
            mergedById[id] = Map<String, dynamic>.from(item);
          }
        }
      }
      var result = mergedById.values.toList();
      print('Resultado do merge por $idField: $result');
      return result;
    }

    final mergedArray = <dynamic>[];
    final maxLength = max(localArray.length, serverArray.length);
    for (int i = 0; i < maxLength; i++) {
      final localItem = i < localArray.length ? localArray[i] : null;
      final serverItem = i < serverArray.length ? serverArray[i] : null;
      if (localItem == null && serverItem != null) {
        mergedArray.add(serverItem);
      } else if (serverItem == null && localItem != null) {
        mergedArray.add(localItem);
      } else if (localItem != null && serverItem != null) {
        mergedArray.add(_mergeObjects(
          Map<String, dynamic>.from(serverItem),
          Map<String, dynamic>.from(localItem),
          localTimestamp,
          serverTimestamp,
        ));
      }
    }
    print('Resultado do merge por posição: $mergedArray');
    return mergedArray;
  }

  static Map<String, dynamic> _mergeObjects(
      Map<String, dynamic> serverObj,
      Map<String, dynamic> localObj,
      DateTime localTimestamp,
      DateTime serverTimestamp) {
    var result = Map<String, dynamic>.from(serverObj);
    final priorityFields = ['status', 'syncStatus'];

    localObj.forEach((key, localValue) {
      final serverValue = serverObj[key];
      if (priorityFields.contains(key)) {
        result[key] = localValue;
      } else if (serverValue == null) {
        result[key] = localValue;
      } else if (localValue is Map && serverValue is Map) {
        result[key] = _mergeObjects(
          Map<String, dynamic>.from(serverValue),
          Map<String, dynamic>.from(localValue),
          localTimestamp,
          serverTimestamp,
        );
      } else if (localValue is List && serverValue is List) {
        result[key] = _mergeArrays(localValue, serverValue, localTimestamp, serverTimestamp, key);
      } else {
        result[key] = localTimestamp.isAfter(serverTimestamp) ? localValue : serverValue;
      }
    });

    return result;
  }
}