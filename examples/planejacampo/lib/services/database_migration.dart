import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/models/propriedade.dart';

class DatabaseMigration {
  final FirebaseFirestore _firestore;
  final String _produtorId;

  DatabaseMigration(this._firestore, this._produtorId);

  Future<void> runMigrations() async {
    int currentVersion = await _getCurrentVersion();

    if (currentVersion < 1) {
      //await _migrateToVersion1();
      //await _updateVersion(1);
    }

    if (currentVersion < 2) {
      //await _migrateToVersion2();
      //await _updateVersion(2);
    }

    if (currentVersion < 3) {
      //await _migrateToVersion3();
      //await _updateVersion(3);
    }
    
    // Adicione mais migrações conforme necessário
  }

  Future<int> _getCurrentVersion() async {
    var doc = await _firestore.collection('produtores').doc(_produtorId).get();
    if (doc.exists) {
      var data = doc.data();
      if (data != null && data.containsKey('database_version')) {
        return data['database_version'] as int;
      }
    }
    return 0;  // Retorna 0 se o documento não existir ou não tiver o campo database_version
  }

  Future<void> _updateVersion(int version) async {
    await _firestore.collection('produtores').doc(_produtorId).set({
      'database_version': version
    }, SetOptions(merge: true));
  }

  Future<void> _migrateToVersion1() async {
    final propriedadeService = PropriedadeService();
    List<Propriedade> propriedades = await propriedadeService.getByProdutorId(_produtorId);

    var batch = _firestore.batch();
    int batchSize = 0;

    for (var propriedade in propriedades) {
      var query = _firestore.collection('movimentacoesEstoque')
          .where('propriedadeId', isEqualTo: propriedade.id);

      var movimentacoesSnapshot = await query.get();

      for (var doc in movimentacoesSnapshot.docs) {
        batch.update(doc.reference, {'ativo': true});
        batchSize++;

        if (batchSize >= 400) {  // Firestore tem um limite de 500 operações por batch
          await batch.commit();
          batch = _firestore.batch();
          batchSize = 0;
        }
      }
    }

    if (batchSize > 0) {
      await batch.commit();
    }
  }

  // Migração para a versão 2 - Adicionar o campo licencas com AcessoBasico
  Future<void> _migrateToVersion2() async {
    var docRef = _firestore.collection('produtores').doc(_produtorId);
    var doc = await docRef.get();

    if (doc.exists) {
      var data = doc.data();
      if (data != null && !data.containsKey('licencas')) {
        // Se o campo 'licencas' não existir, vamos adicioná-lo com AcessoBasico
        await docRef.set({
          'licencas': [
            {
              'tipo': 'AcessoBasico',
              'dataExpiracao': null // Licença sem data de expiração
            }
          ]
        }, SetOptions(merge: true));
      }
    }
  }

  // Migração para a versão 2 - Adiciona produtorId em pagamentoCompra.
  Future<void> _migrateToVersion3() async {
    var comprasSnapshot = await _firestore
        .collection('compras')
        .where('produtorId', isEqualTo: _produtorId)
        .get();

    var batch = _firestore.batch();
    int batchSize = 0;

    for (var compraDoc in comprasSnapshot.docs) {
      var pagamentosSnapshot = await compraDoc.reference
          .collection('pagamentosCompra')
          .get();

      for (var pagamentoDoc in pagamentosSnapshot.docs) {
        batch.update(pagamentoDoc.reference, {'produtorId': _produtorId});
        batchSize++;

        // Commit a cada 400 operações
        if (batchSize >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchSize = 0;
        }
      }
    }

    // Commit final se restarem operações
    if (batchSize > 0) {
      await batch.commit();
    }
  }

}
