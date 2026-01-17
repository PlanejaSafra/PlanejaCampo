import 'package:planejacampo/services/abastecimento_frota_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_service.dart';
import 'package:planejacampo/services/contabil/processamento_contabil_status_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/estoques/processamento_status_service.dart';
import 'package:planejacampo/services/frota_operacao_rural_service.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/services/item_manutencao_frota_service.dart';
import 'package:planejacampo/services/item_operacao_rural_service.dart';
import 'package:planejacampo/services/manutencao_frota_service.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/registro_chuva_service.dart';
import 'package:planejacampo/services/registro_coleta_service.dart';
import 'package:planejacampo/services/registro_entrega_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_service.dart';
import 'package:planejacampo/models/produtor.dart';

class PreloadAllData {
  static Future<void> loadAllData() async {
    final appStateManager = AppStateManager();

    try {
      // 1. Buscar TODOS os produtores de uma vez.
      List<Produtor> produtores = await ProdutorService().getProdutores();

      // 2. Criar uma lista de Futures para TODAS as operações de pré-carregamento.
      List<Future<void>> futures = [];

      for (Produtor produtor in produtores) {
        // 3. Adicionar TODAS as chamadas assíncronas à lista de Futures,
        //    usando o produtor.id correto.
        futures.add(BancoService().getByProdutorId(produtor.id));
        futures.add(ContaService().getByProdutorId(produtor.id));
        futures.add(ContaContabilService().getByProdutorId(produtor.id));
        futures.add(ContaPagarService().getByProdutorId(produtor.id));
        futures.add(LancamentoContabilService().getByProdutorId(produtor.id));
        futures.add(LancamentoContabilProjetadoService().getByProdutorId(produtor.id));
        futures.add(ProcessamentoContabilStatusService().getByProdutorId(produtor.id));

        futures.add(EstoqueService().getByProdutorId(produtor.id));
        futures.add(MovimentacaoEstoqueProjetadaService().getByProdutorId(produtor.id));
        futures.add(MovimentacaoEstoqueService().getByProdutorId(produtor.id));
        futures.add(ProcessamentoStatusService().getByProdutorId(produtor.id));

        futures.add(AbastecimentoFrotaService().getByProdutorId(produtor.id));
        futures.add(AtividadeRuralService().getByProdutorId(produtor.id));
        futures.add(CompraService().getByProdutorId(produtor.id));
        futures.add(FrotaOperacaoRuralService().getByProdutorId(produtor.id));
        futures.add(FrotaService().getByProdutorId(produtor.id));
        futures.add(ItemCompraService().getByProdutorId(produtor.id));
        futures.add(ItemManutencaoFrotaService().getByProdutorId(produtor.id));
        futures.add(ItemOperacaoRuralService().getByProdutorId(produtor.id));
        futures.add(ItemService().getByProdutorId(produtor.id));
        futures.add(ManutencaoFrotaService().getByProdutorId(produtor.id));
        futures.add(OperacaoRuralService().getByProdutorId(produtor.id));
        futures.add(PessoaService().getByProdutorId(produtor.id));
        futures.add(PropriedadeService().getByProdutorId(produtor.id));
        futures.add(RegistroChuvaService().getByProdutorId(produtor.id));
        futures.add(RegistroColetaService().getByProdutorId(produtor.id));
        futures.add(RegistroEntregaService().getByProdutorId(produtor.id));
        futures.add(TalhaoService().getByProdutorId(produtor.id));
        futures.add(OperacaoRuralService().getByProdutorId(produtor.id));
      }

      // 4. Aguardar TODAS as operações terminarem.  O `Future.wait` garante
      //    que TODAS as chamadas assíncronas sejam concluídas antes de
      //    continuar.  Se QUALQUER uma delas falhar, o `catchError` será
      //    chamado.
      await Future.wait(futures);

    } catch (e) {
      print('Erro ao pré-carregar dados: $e');
      // Trate o erro aqui.  Você pode, por exemplo, registrar o erro,
      // mostrar uma mensagem para o usuário ou tentar novamente.
      // Dependendo da sua estratégia de tratamento de erros, você pode
      // querer relançar a exceção (`rethrow;`) para que ela seja tratada
      // em um nível superior.
    }
  }
}