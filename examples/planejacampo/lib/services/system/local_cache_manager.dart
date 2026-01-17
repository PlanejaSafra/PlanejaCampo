import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:planejacampo/services/system/data_integrity_manager.dart';

class LocalCacheManager {
  static const String CACHE_BOX = 'local_cache';

  // Método base para abrir box
  static Future<Box> _openBox() async {
    return await Hive.openBox(CACHE_BOX);
  }

  // Atualiza um item no cache
  // Em LocalCacheManager, melhore o armazenamento de metadados:
  // Manter um registro de documentos já processados nesta sessão
  static final Map<String, bool> _processedMetadata = {};

  static Future<void> updateCache(String collection, String id, Map<String, dynamic> data) async {
    final box = await _openBox();
    Map<String, dynamic> dataToStore = Map<String, dynamic>.from(data);
    final cacheKey = '$collection:$id';

    // Garantir que _metadata existe
    if (!dataToStore.containsKey('_metadata')) {
      dataToStore['_metadata'] = {
        'version': 1,
        'lastModified': DateTime.now().toIso8601String(),
        'syncStatus': 'cached'
      };
    } else if (!(dataToStore['_metadata'] is Map)) {
      dataToStore['_metadata'] = {
        'version': 1,
        'lastModified': DateTime.now().toIso8601String(),
        'syncStatus': 'cached'
      };
    }

    // Adicionar ou atualizar informações de cache
    dataToStore['_metadata']['cached_at'] = DateTime.now().toIso8601String();
    dataToStore['id'] = id;

    // Verificar se o hash está presente e é válido
    if (!DataIntegrityManager.hasValidHash(dataToStore) && !_processedMetadata.containsKey(cacheKey)) {
      // Marcar este documento como processado para evitar processamento repetido
      _processedMetadata[cacheKey] = true;

      // Usar a versão atualizada que também atualiza o Firestore
      try {
        final dataWithMetadata = await DataIntegrityManager.addFullMetadata(
            dataToStore,
            updateFirestore: true,
            collectionPath: collection,
            docId: id
        );
        dataToStore = dataWithMetadata;

        print('Metadados adicionados e atualizados para $collection/$id');
      } catch (e) {
        print('Erro ao adicionar metadados para $collection/$id: $e');
      }
    }

    // Converter Timestamps e outros tipos para formato armazenável
    final convertedData = _convertDataForStorage(dataToStore);

    // Atualizar o cache local
    await box.put(cacheKey, convertedData);
  }


  // NOVO: Método dedicado para converter valores individuais
  // Em LocalCacheManager, modifique o método _convertValueForStorage:

  static dynamic _convertValueForStorage(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is Timestamp) {
      return {
        '_type': 'timestamp',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds
      };
    } else if (value is DateTime) {
      return {
        '_type': 'datetime',
        'value': value.toIso8601String()
      };
    } else if (value is Map) {
      // Aqui está o problema! Precisamos converter Map<dynamic, dynamic> em Map<String, dynamic>
      // de forma segura, sem fazer cast direto
      final Map<String, dynamic> convertedMap = {};

      value.forEach((key, val) {
        // Garantir que a chave seja sempre String
        String stringKey = key.toString();
        // Converter o valor recursivamente
        convertedMap[stringKey] = _convertValueForStorage(val);
      });

      return convertedMap;
    } else if (value is List) {
      return value.map((item) => _convertValueForStorage(item)).toList();
    }
    return value;
  }

// O método _convertDataForStorage também precisa ser ajustado:

  static Map<String, dynamic> _convertDataForStorage(Map<String, dynamic>? data) {
    if (data == null) return {};

    final Map<String, dynamic> result = {};

    // Usar a abordagem segura, não confiar em cast direto
    data.forEach((key, value) {
      result[key] = _convertValueForStorage(value);
    });

    return result;
  }

// NOVO: Método dedicado para converter valores do storage
  static dynamic _convertValueFromStorage(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is Map) {
      if (value['_type'] == 'timestamp' || value['type'] == 'timestamp') { // Aceita ambos os padrões
        try {
          return Timestamp(
              value['seconds'] as int? ?? 0,
              value['nanoseconds'] as int? ?? 0
          );
        } catch (e) {
          print('Erro ao converter timestamp: $e');
          return Timestamp.now();
        }
      }
      return Map<String, dynamic>.from(value);
    }
    return value;
  }

  static Map<String, dynamic> _convertDataFromStorage(Map<String, dynamic>? data) {
    if (data == null) return {};

    final result = Map<String, dynamic>.from(data);
    result.forEach((key, value) {
      result[key] = _convertValueFromStorage(value);
    });
    return result;
  }




  static dynamic _convertListForStorage(List items) {
    return items.map((item) {
      if (item == null) return null;
      if (item is Timestamp) {
        return {
          '_type': 'timestamp', // CORRIGIDO: Mudando de 'type' para '_type'
          'seconds': item.seconds,
          'nanoseconds': item.nanoseconds
        };
      } else if (item is DateTime) {
        return {
          '_type': 'datetime',
          'value': item.toIso8601String()
        };
      } else if (item is Map) {
        return _convertDataForStorage(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _convertListForStorage(item);
      }
      return item;
    }).toList();
  }

  static dynamic _convertListFromStorage(List items) {
    return items.map((item) {
      if (item == null) return null;
      if (item is Map) {
        if (item['_type'] == 'timestamp') { // Mudança de 'type' para '_type'
          try {
            return Timestamp(
                item['seconds'] as int? ?? 0,
                item['nanoseconds'] as int? ?? 0
            );
          } catch (e) {
            print('Erro ao converter timestamp em lista: $e');
            return Timestamp.now();
          }
        } else if (item['_type'] == 'datetime') { // Adicionar suporte para DateTime
          try {
            return DateTime.parse(item['value'] as String);
          } catch (e) {
            print('Erro ao converter datetime em lista: $e');
            return DateTime.now();
          }
        }
        return _convertDataFromStorage(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _convertListFromStorage(item);
      }
      return item;
    }).toList();
  }

  // Remove um item do cache
  static Future<void> removeFromCache(
      String collection,
      String id
      ) async {
    final box = await _openBox();
    await box.delete('$collection:$id');
  }

  // Atualizar o método readFromCache
  static Future<Map<String, dynamic>?> readFromCache(String collection, String id) async {
    final box = await _openBox();
    final rawData = box.get('$collection:$id');
    if (rawData == null) return null;
    if (rawData is! Map) return null;

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
      data['id'] = id;
      return _convertDataFromStorage(data);
    } catch (e) {
      print('Erro ao ler do cache para $collection:$id: $e');
      return null;
    }
  }

// Método que foi removido e precisa voltar
  static Map<String, dynamic> _ensureStringKeys(Map data) {
    Map<String, dynamic> result = {};

    data.forEach((key, value) {
      String stringKey = key.toString();
      if (value is Map) {
        result[stringKey] = _ensureStringKeys(value);
      } else if (value is List) {
        result[stringKey] = _ensureListTypes(value);
      } else {
        result[stringKey] = value;
      }
    });

    return result;
  }

  static List _ensureListTypes(List items) {
    return items.map((item) {
      if (item is Map) {
        return _ensureStringKeys(item);
      } else if (item is List) {
        return _ensureListTypes(item);
      }
      return item;
    }).toList();
  }

// Atualizar o método readManyFromCache
  static Future<List<Map<String, dynamic>>> readManyFromCache(
      String collection,
      List<String> ids
      ) async {
    final box = await _openBox();
    return ids.map((id) {
      final data = box.get('$collection:$id');
      return data != null ? _convertDataFromStorage(Map<String, dynamic>.from(data)) : null;
    }).where((data) => data != null).cast<Map<String, dynamic>>().toList();
  }

// Atualizar o método getAllFromCache
  static Future<List<Map<String, dynamic>>> getAllFromCache(String collection) async {
    try {
      final box = await _openBox();
      final items = box.keys
          .where((key) => key.toString().startsWith('$collection:'))
          .map((key) {
        try {
          final rawData = box.get(key);
          if (rawData == null) return null;
          if (rawData is! Map) return null;

          // Garantir que as chaves são strings
          final Map<String, dynamic> data = _ensureStringKeys(rawData);
          final String id = key.toString().split(':')[1];
          data['id'] = id;

          return _convertDataFromStorage(data);
        } catch (e) {
          print('Erro ao converter item do cache: $e');
          return null;
        }
      })
          .where((data) => data != null)
          .cast<Map<String, dynamic>>()
          .toList();

      print('Lidos ${items.length} itens do cache para a coleção $collection');
      return items;
    } catch (e) {
      print('Erro ao ler todos os itens do cache: $e');
      return [];
    }
  }

// Atualizar o método getPageFromCache
  static Future<List<Map<String, dynamic>>> getPageFromCache(
      String collection,
      Map<String, dynamic> filters,
      int pageSize,
      DocumentSnapshot? lastDocument
      ) async {
    final box = await _openBox();

    var items = box.keys
        .where((key) => key.toString().startsWith('$collection:'))
        .map((key) => box.get(key))
        .where((data) => data != null)
        .map((data) => _convertDataFromStorage(Map<String, dynamic>.from(data)))
        .where((doc) => _matchesFilters(doc, filters))
        .toList();

    // Aplicar paginação
    if (lastDocument != null) {
      final lastDocIndex = items.indexWhere((doc) => doc['id'] == lastDocument.id);
      if (lastDocIndex != -1) {
        items = items.sublist(lastDocIndex + 1);
      }
    }

    return items.take(pageSize).toList();
  }

// Atualizar o método queryCache
  static Future<List<Map<String, dynamic>>> queryCache(
      String collection,
      Map<String, dynamic> filters,
      [Map<String, List<Map<String, dynamic>>>? attributesWithOperators,
        List<Map<String, String>>? orderBy,
        int? limit]
      ) async {
    final box = await _openBox();

    var items = box.keys
        .where((key) => key.toString().startsWith('$collection:'))
        .map((key) => box.get(key))
        .where((data) => data != null)
        .map((data) => _convertDataFromStorage(Map<String, dynamic>.from(data)))
        .where((doc) => _matchesFilters(doc, filters))
        .where((doc) => _matchesOperators(doc, attributesWithOperators))
        .toList();

    if (orderBy != null && orderBy.isNotEmpty) {
      items.sort((a, b) => _compareByOrderBy(a, b, orderBy));
    }

    if (limit != null) {
      items = items.take(limit).toList();
    }

    return items;
  }

  // Helpers privados
  static bool _matchesFilters(Map<String, dynamic> doc, Map<String, dynamic> filters) {
    return filters.entries.every((filter) => doc[filter.key] == filter.value);
  }

  static bool _matchesOperators(
      Map<String, dynamic> doc,
      Map<String, List<Map<String, dynamic>>>? operators) {
    if (operators == null) return true;

    return operators.entries.every((entry) {
      final field = entry.key;
      final conditions = entry.value;

      return conditions.every((condition) {
        final operator = condition['operator'];
        final value = condition['value'];

        // Função auxiliar para comparar, tratando Timestamp e DateTime
        int compareValues(dynamic docValue, dynamic conditionValue) {
          if (docValue is Timestamp && conditionValue is DateTime) {
            return docValue.toDate().compareTo(conditionValue);
          } else if (docValue is DateTime && conditionValue is Timestamp) {
            return docValue.compareTo(conditionValue.toDate());
          } else if (docValue is Timestamp && conditionValue is Timestamp) {
            return docValue.compareTo(conditionValue);
          }  else if (docValue is int && conditionValue is int) {
            return docValue.compareTo(conditionValue);
          } else if (docValue is double && conditionValue is double) {
            return docValue.compareTo(conditionValue);
          } else if (docValue is String && conditionValue is String) {
            return docValue.compareTo(conditionValue);
          }
          else {
            // Se os tipos não são comparáveis diretamente, retorna 0 (considera igual)
            // Você pode querer tratar isso de forma diferente (lançar exceção, etc.)
            print("Warning: Comparing incompatible types in _matchesOperators: ${docValue.runtimeType} and ${conditionValue.runtimeType}");
            return 0;
          }
        }

        switch (operator) {
          case '==':
            return doc[field] == value;
          case '>':
            return compareValues(doc[field], value) > 0;
          case '<':
            return compareValues(doc[field], value) < 0;
          case '>=':
            return compareValues(doc[field], value) >= 0;
          case '<=':
            return compareValues(doc[field], value) <= 0;
          case '!=':
            return doc[field] != value;
          default:
            return true;
        }
      });
    });
  }

  static int _compareByOrderBy(
      Map<String, dynamic> a,
      Map<String, dynamic> b,
      List<Map<String, String>> orderBy
      ) {
    for (var order in orderBy) {
      final field = order['field']!;
      final direction = order['direction']!;

      if (a[field] != b[field]) {
        if (direction == 'asc') {
          return a[field].compareTo(b[field]);
        } else {
          return b[field].compareTo(a[field]);
        }
      }
    }
    return 0;
  }
}