import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/system/data_integrity_manager.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'generic_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ProdutorService extends GenericService<Produtor> {

  AppStateManager _appStateManager = AppStateManager();

  ProdutorService() : super('produtores');

  @override
  Produtor fromMap(Map<String, dynamic> map, String documentId) {
    return Produtor.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Produtor produtor) {
    return produtor.toMap();
  }

  @override
  Future<String?> add(Produtor produtor, {bool returnId = false, Duration? timeout}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final adminPermission = {
        'usuarioId': currentUser.uid,
        'email': currentUser.email ?? '',
        'role': 'Admin',
      };

      // Criar lista de usuariosPermitidos
      final List<String> usuariosPermitidos = [currentUser.uid];

      // Adicionar email à lista de usuários permitidos se disponível
      if (currentUser.email != null && currentUser.email!.isNotEmpty) {
        usuariosPermitidos.add('email:${currentUser.email}');
      }

      // Adiciona as permissões e usuários permitidos
      produtor = produtor.copyWith(
        permissoes: List<Map<String, String>>.from(produtor.permissoes)..add(adminPermission),
        usuariosPermitidos: [...produtor.usuariosPermitidos, ...usuariosPermitidos],
        criadorId: currentUser.uid,
      );
    }

    // Usar a implementação da classe pai para gerenciar cache/offline
    return super.add(produtor, returnId: returnId, timeout: timeout);
  }

  Future<List<Produtor>> getProdutores() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    print('Usuário atual: uid=${currentUser.uid}, email=${currentUser.email}');

    try {
      // Abordagem otimizada para quando está online
      if (_appStateManager.isOnline) {
        final queries = <Query<Map<String, dynamic>>>[];

        // Consulta por ID do usuário
        queries.add(getCollectionReference()
            .where('usuariosPermitidos', arrayContains: currentUser.uid));

        // Consulta adicional por email, se disponível
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          queries.add(getCollectionReference()
              .where('usuariosPermitidos', arrayContains: 'email:${currentUser.email}'));
        }

        // Executar consultas em paralelo
        final results = await Future.wait(queries.map((query) => query.get()));

        // Consolidar resultados evitando duplicatas
        final Map<String, Produtor> uniqueProducers = {};
        for (var querySnapshot in results) {
          for (var doc in querySnapshot.docs) {
            if (!uniqueProducers.containsKey(doc.id)) {
              final data = doc.data();
              data['id'] = doc.id;

              // Garantir integridade dos dados
              if (!DataIntegrityManager.hasValidHash(data)) {
                // Adicionar metadados se necessário
                final updatedData = await DataIntegrityManager.addFullMetadata(data);
                await LocalCacheManager.updateCache(baseCollection, doc.id, updatedData);
                uniqueProducers[doc.id] = fromMap(updatedData, doc.id);
              } else {
                await LocalCacheManager.updateCache(baseCollection, doc.id, data);
                uniqueProducers[doc.id] = fromMap(data, doc.id);
              }
            }
          }
        }

        final produtores = uniqueProducers.values.toList();
        print('Produtores encontrados via consulta otimizada: ${produtores.length}');
        return produtores;
      } else {
        // Fallback para abordagem anterior quando offline
        final List<Produtor> allProdutores = await getAll();
        print('Todos os produtores retornados por getAll: ${allProdutores.length}');

        final filteredProdutores = allProdutores.where((produtor) {
          print('Verificando produtor: ${produtor.id}');
          print('Permissões: ${produtor.permissoes}');

          final hasPermission = produtor.permissoes.any((permissao) {
            final usuarioIdMatch = permissao['usuarioId'] == currentUser.uid;
            final emailMatch = currentUser.email != null && permissao['email'] == currentUser.email;
            print('Permissão: $permissao, usuarioIdMatch: $usuarioIdMatch, emailMatch: $emailMatch');
            return usuarioIdMatch || emailMatch;
          });

          print('Produtor ${produtor.id}: hasPermission = $hasPermission');
          return hasPermission;
        }).toList();

        print('Produtores filtrados: ${filteredProdutores.length}');
        return filteredProdutores;
      }
    } catch (e) {
      print("Erro ao buscar produtores: $e");
      rethrow;
    }
  }

  Future<Produtor?> getProdutorById(String id) async {
    final doc = await getCollectionReference().doc(id).get();
    if (doc.exists) {
      return fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Propriedade>> getPropriedades(String produtorId) async {
    final propriedadesCollection =
    getCollectionReference().doc(produtorId).collection('propriedades');
    final querySnapshot = await propriedadesCollection.get();
    return querySnapshot.docs
        .map((doc) => Propriedade.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<bool> hasRelatedData(String produtorId) async {
    final List<Propriedade> propriedades = await getPropriedades(produtorId);
    return propriedades.isNotEmpty;
  }

  Future<void> deleteProdutor(String produtorId) async {
    final List<Propriedade> propriedades = await getPropriedades(produtorId);
    for (Propriedade propriedade in propriedades) {
      await deletePropriedade(produtorId, propriedade.id);
    }
    await delete(produtorId);
  }

  Future<void> deletePropriedade(
      String produtorId, String propriedadeId) async {
    final propriedadesCollection =
    getCollectionReference().doc(produtorId).collection('propriedades');
    await propriedadesCollection.doc(propriedadeId).delete();
  }

  bool canEditPermissions(String userId, String userEmail, Produtor produtor) {
    for (var permissao in produtor.permissoes) {
      if ((permissao['usuarioId'] == userId ||
          permissao['email'] == userEmail) &&
          (permissao['role'] == 'Admin' ||
              permissao['role'] == 'Produtor' ||
              permissao['role'] == 'Gerente')) {
        return true;
      }
    }
    return false;
  }

  Future<void> addPermission(
      String produtorId, String email, String role) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
    await getCollectionReference().doc(produtorId).get();
    if (!doc.exists) {
      throw Exception('Produtor não encontrado');
    }

    final Produtor produtor =
    fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (!canEditPermissions(currentUser.uid, currentUser.email!, produtor)) {
      throw Exception('Permissão negada');
    }

    // Nova permissão a ser adicionada
    final Map<String, String> newPermission = {
      'usuarioId': '',
      'email': email,
      'role': role,
    };

    // Adicionar à lista de permissões
    final updatedPermissoes = List<Map<String, String>>.from(produtor.permissoes)..add(newPermission);

    // Atualizar usuariosPermitidos para incluir o novo email
    final updatedUsuariosPermitidos = List<String>.from(produtor.usuariosPermitidos);
    if (!updatedUsuariosPermitidos.contains('email:$email')) {
      updatedUsuariosPermitidos.add('email:$email');
    }

    // Criar produtor atualizado
    final updatedProdutor = produtor.copyWith(
        permissoes: updatedPermissoes,
        usuariosPermitidos: updatedUsuariosPermitidos
    );

    await getCollectionReference().doc(produtorId).update(toMap(updatedProdutor));
  }

  Future<void> updatePermission(
      String produtorId, String usuarioId, String newRole) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
    await getCollectionReference().doc(produtorId).get();
    if (!doc.exists) {
      throw Exception('Produtor não encontrado');
    }

    final Produtor produtor =
    fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (!canEditPermissions(currentUser.uid, currentUser.email!, produtor)) {
      throw Exception('Permissão negada');
    }

    // Encontrar a permissão para o usuário especificado e atualizar a role
    final List<Map<String, String>> updatedPermissoes =
    produtor.permissoes.map((Map<String, String> permissao) {
      if (permissao['usuarioId'] == usuarioId) {
        return {
          'usuarioId': usuarioId,
          'email': permissao['email']!,
          'role': newRole
        };
      }
      return permissao;
    }).toList();

    final Produtor updatedProdutor =
    produtor.copyWith(permissoes: updatedPermissoes);
    await getCollectionReference()
        .doc(produtorId)
        .update(toMap(updatedProdutor));
  }

  Future<void> deletePermission(String produtorId, String usuarioId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
    await getCollectionReference().doc(produtorId).get();
    if (!doc.exists) {
      throw Exception('Produtor não encontrado');
    }

    final Produtor produtor =
    fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (!canEditPermissions(currentUser.uid, currentUser.email!, produtor)) {
      throw Exception('Permissão negada');
    }

    // Encontrar email do usuário a ser removido (se existir)
    String? emailToRemove;
    for (var permissao in produtor.permissoes) {
      if (permissao['usuarioId'] == usuarioId) {
        emailToRemove = permissao['email'];
        break;
      }
    }

    // Remover a permissão para o usuário especificado
    final List<Map<String, String>> updatedPermissoes =
    produtor.permissoes.where((Map<String, String> permissao) {
      return permissao['usuarioId'] != usuarioId;
    }).toList();

    // Atualizar usuariosPermitidos para remover o ID e possivelmente o email
    final List<String> updatedUsuariosPermitidos =
    produtor.usuariosPermitidos.where((String id) {
      // Remover o ID de usuário
      if (id == usuarioId) return false;

      // Remover o email relacionado, se encontrado
      if (emailToRemove != null && id == 'email:$emailToRemove') return false;

      return true;
    }).toList();

    // Criar produtor atualizado
    final Produtor updatedProdutor = produtor.copyWith(
        permissoes: updatedPermissoes,
        usuariosPermitidos: updatedUsuariosPermitidos
    );

    await getCollectionReference()
        .doc(produtorId)
        .update(toMap(updatedProdutor));
  }

  Future<int> getNumberOfProdutoresCriados() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('Usuário não autenticado.');
      return 0;
    }

    try {
      // Busca todos os produtores onde o usuário atual é o criador
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('produtores')
          .where('criadorId', isEqualTo: currentUser.uid)
          .get();
      // Retorna o número de documentos (produtores) que o usuário criou
      return snapshot.docs.length;
    } catch (e) {
      print('Erro ao contar produtores criados: $e');
      return 0;
    }
  }

  Future<void> regenerateUserIdsIndex(String produtorId) async {
    // Método utilitário para regenerar o campo usuariosPermitidos caso necessário
    try {
      final doc = await getCollectionReference().doc(produtorId).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final produtor = fromMap(data, doc.id);
      if (produtor.permissoes.isEmpty) return;

      // Extrair todos os IDs e emails das permissões
      final Set<String> userIds = {};
      for (var permissao in produtor.permissoes) {
        if (permissao['usuarioId'] != null && permissao['usuarioId']!.isNotEmpty) {
          userIds.add(permissao['usuarioId']!);
        }
        if (permissao['email'] != null && permissao['email']!.isNotEmpty) {
          userIds.add('email:${permissao['email']!}');
        }
      }

      // Atualizar o documento se os IDs de usuário mudaram
      if (produtor.usuariosPermitidos.length != userIds.length ||
          !produtor.usuariosPermitidos.toSet().containsAll(userIds)) {
        await getCollectionReference().doc(produtorId).update({
          'usuariosPermitidos': userIds.toList()
        });
        print('Índice usuariosPermitidos regenerado para produtor $produtorId');
      }
    } catch (e) {
      print('Erro ao regenerar índice usuariosPermitidos: $e');
    }
  }

  bool isLicencaValida(Produtor produtor, String tipoLicenca) {
    if (produtor.licencas == null || produtor.licencas!.isEmpty) {
      return false;  // Não há licenças, portanto, a licença não é válida
    }

    final licenca = produtor.licencas!.firstWhere(
          (l) => l['tipo'] == tipoLicenca,
      orElse: () => {},
    );

    if (licenca.isEmpty) {
      return false;  // Não possui a licença
    }

    final dataExpiracao = licenca['dataExpiracao'] != null
        ? DateTime.tryParse(licenca['dataExpiracao'])
        : null;

    if (dataExpiracao == null) {
      return true;  // Licença vitalícia ou sem data de expiração
    }

    return dataExpiracao.isAfter(DateTime.now());  // Verifica se a licença ainda é válida
  }

  // Migrar produtores existentes para o novo formato
  Future<void> migrateProducerPermissions() async {
    try {
      final snapshot = await getCollectionReference().get();
      int migrated = 0;

      for (final doc in snapshot.docs) {
        if (!doc.data().containsKey('usuariosPermitidos')) {
          await regenerateUserIdsIndex(doc.id);
          migrated++;
        }
      }

      if (migrated > 0) {
        print('Migrados $migrated produtores para o novo formato com usuariosPermitidos');
      }
    } catch (e) {
      print('Erro durante migração de produtores: $e');
    }
  }
}