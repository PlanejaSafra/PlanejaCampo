// V02
import 'package:planejacampo/models/estoque.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/movimentacao_estoque.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_service.dart';
import '../generic_service.dart';

class EstoqueService extends GenericService<Estoque> {
  EstoqueService() : super('estoques');

  @override
  Estoque fromMap(Map<String, dynamic> map, String documentId) {
    return Estoque.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Estoque estoque) {
    return estoque.toMap();
  }


  Future<void> ajustarEstoque(
      String produtorId, String propriedadeId, String itemId, 
      double quantidade, double custoUnitario, String unidadeMedida) async {
    
    final ItemService itemService = ItemService();
    final Item? item = await itemService.getById(itemId);

    // ID consistente para documentos de estoque
    final String estoqueId = "${produtorId}-${itemId}-${propriedadeId}";
    
    // Buscar estoque existente
    final Estoque? estoqueExistente = await getById(estoqueId);

    if (item != null) {
      // Converter a quantidade para a unidade padrão do item
      if (item.unidadeMedida != unidadeMedida) {
        quantidade = converterUnidadeMedida(quantidade, unidadeMedida, item.unidadeMedida);
      }

      if (estoqueExistente != null) {
        // Atualizar documento existente
        await update(estoqueId, estoqueExistente.copyWith(
          quantidade: quantidade, 
          cmp: custoUnitario, 
          ultimaAtualizacaoCmp: DateTime.now().toUtc(),
          emProcessamento: false // Garantir que não fique travado
        ));
      } else {
        // Criar novo documento com ID consistente
        final Estoque novoEstoque = Estoque(
          id: estoqueId,
          itemId: itemId,
          produtorId: produtorId,
          propriedadeId: propriedadeId,
          quantidade: quantidade,
          unidadeMedida: item.unidadeMedida,
          cmp: custoUnitario,
          unidadeMedidaCmp: item.unidadeMedida,
          ultimaAtualizacaoCmp: DateTime.now().toUtc(),
          emProcessamento: false
        );
        await add(novoEstoque);
      }
      
      print("Estoque ajustado: ID=$estoqueId, Quantidade=$quantidade, CMP=$custoUnitario");
    } else {
      print("Item não encontrado: $itemId");
    }
  }

  double converterUnidadeMedida(double quantidade, String unidadeAtual, String unidadePadrao) {
    const Map<String, double> conversionFactors = <String, double>{
      // Unidades de Massa
      'Quilograma (kg)': 1.0,
      'Grama (g)': 0.001,
      'Tonelada (t)': 1000.0,
      'Miligrama (mg)': 0.000001,
      'Arroba (@)': 15.0, // Aproximadamente 15 kg
      'Saco 20kg (sc20kg)': 20.0,
      'Saco 25kg (sc25kg)': 25.0,
      'Saco 30kg (sc30kg)': 30.0,
      'Saco 40kg (sc40kg)': 40.0,
      'Saco 50kg (sc50kg)': 50.0,
      'Saco 60kg (sc60kg)': 60.0,

      // Unidades de Comprimento
      'Metro (m)': 1.0,
      'Centímetro (cm)': 0.01,
      'Milímetro (mm)': 0.001,
      'Quilômetro (km)': 1000.0,

      // Unidades de Área
      'Metro quadrado (m²)': 1.0,
      'Hectare (ha)': 10000.0, // 1 ha = 10,000 m²
      'Alqueire (alq)': 24200.0, // 1 alqueire paulista ≈ 24,200 m²

      // Unidades de Volume
      'Litro (L)': 1.0,
      'Mililitro (mL)': 0.001,
      'Metro cúbico (m³)': 1000.0, // 1 m³ = 1000 L
      'Centímetro cúbico (cm³)': 0.001, // 1 cm³ = 1 mL

      // Unidades de Tempo
      'Hora (h)': 1.0,
      'Minuto (min)': 1.0 / 60.0,
      'Dia (d)': 24.0, // 1 dia = 24 horas

      // Unidades de Quantidade
      'Unidade (un)': 1.0,
      'Dúzia (dz)': 12.0,

      // Outras Unidades
      'Caixa (cx)': 1.0, // Assumir conversão 1:1
      'Fardo (fd)': 1.0, // Assumir conversão 1:1
      'Pacote (pct)': 1.0, // Assumir conversão 1:1
      'Peça (pc)': 1.0, // Assumir conversão 1:1
    };

    double fatorConversaoAtual = conversionFactors[unidadeAtual] ?? 1.0;
    double fatorConversaoPadrao = conversionFactors[unidadePadrao] ?? 1.0;

    // Verifica se as unidades são incompatíveis (por exemplo, massa vs. volume)
    bool unidadesIncompativeis = _saoUnidadesIncompativeis(unidadeAtual, unidadePadrao);

    if (unidadesIncompativeis) {
    // Assumir fator de conversão 1.0 e talvez registrar um aviso
    print('Aviso: Conversão entre unidades incompatíveis ($unidadeAtual -> $unidadePadrao). Assumindo fator 1.0.');
    fatorConversaoAtual = 1.0;
    fatorConversaoPadrao = 1.0;
    }

    return quantidade * (fatorConversaoAtual / fatorConversaoPadrao);
    }

  bool _saoUnidadesIncompativeis(String unidade1, String unidade2) {
    // Categorias de unidades
    final Map<String, String> categorias = {
      // Massa
      'Quilograma (kg)': 'massa',
      'Grama (g)': 'massa',
      'Tonelada (t)': 'massa',
      'Miligrama (mg)': 'massa',
      'Arroba (@)': 'massa',
      'Saco 20kg (sc20kg)': 'massa',
      'Saco 25kg (sc25kg)': 'massa',
      'Saco 30kg (sc30kg)': 'massa',
      'Saco 40kg (sc40kg)': 'massa',
      'Saco 50kg (sc50kg)': 'massa',
      'Saco 60kg (sc60kg)': 'massa',

      // Volume
      'Litro (L)': 'volume',
      'Mililitro (mL)': 'volume',
      'Metro cúbico (m³)': 'volume',
      'Centímetro cúbico (cm³)': 'volume',

      // Comprimento
      'Metro (m)': 'comprimento',
      'Centímetro (cm)': 'comprimento',
      'Milímetro (mm)': 'comprimento',
      'Quilômetro (km)': 'comprimento',

      // Área
      'Metro quadrado (m²)': 'área',
      'Hectare (ha)': 'área',
      'Alqueire (alq)': 'área',

      // Tempo
      'Hora (h)': 'tempo',
      'Minuto (min)': 'tempo',
      'Dia (d)': 'tempo',

      // Quantidade
      'Unidade (un)': 'quantidade',
      'Dúzia (dz)': 'quantidade',
      'Caixa (cx)': 'quantidade',
      'Fardo (fd)': 'quantidade',
      'Pacote (pct)': 'quantidade',
      'Peça (pc)': 'quantidade',
    };

    String? categoria1 = categorias[unidade1];
    String? categoria2 = categorias[unidade2];

    if (categoria1 == null || categoria2 == null) {
      // Se a categoria não foi encontrada, considerar incompatível
      return true;
    }

    return categoria1 != categoria2;
  }


  /*
  Future<void> recalcularEstoqueParaNovaUnidadeMedida(Item item, String novaUnidadeMedida) async {
    final List<Estoque> estoques = await getByAttributes({
      'itemId': item.id,
    });

    for (Estoque estoque in estoques) {
      double novaQuantidade = converterUnidadeMedida(estoque.quantidade, estoque.unidadeMedida, novaUnidadeMedida);
      double novoCMP = estoque.cmp; // Calcular o novo CMP conforme necessário
      estoque = estoque.copyWith(quantidade: novaQuantidade, unidadeMedida: novaUnidadeMedida, cmp: novoCMP);
      await update(estoque.id, estoque);
    }
  }
  */

  Future<String?> getItemUnidadeMedidaPadrao(String itemId) async {
    final ItemService itemService = ItemService();
    final Item? item = await itemService.getById(itemId);
    return item?.unidadeMedida;
  }

  Future<Map<String, dynamic>> getEstoqueAnterior({
    required String propriedadeId,
    required String itemId,
    required DateTime dataReferencia,
    String? origemId,
    String? deviceId,
    DateTime? timestampReferencia,
  }) async {
    final MovimentacaoEstoqueService _movimentacaoEstoqueService = MovimentacaoEstoqueService();
    final MovimentacaoEstoqueProjetadaService _movimentacaoEstoqueProjetadaService = MovimentacaoEstoqueProjetadaService();

    // Buscar movimentações reais
    final movimentacoesReais = await _movimentacaoEstoqueService.getByAttributesWithOperators(
      {
        'propriedadeId': [{'value': propriedadeId, 'operator': '=='}],
        'itemId': [{'value': itemId, 'operator': '=='}],
        'ativo': [{'value': true, 'operator': '=='}],
        'data': [{'value': dataReferencia, 'operator': '<='}],
        if (origemId != null) 'origemId': [{'value': origemId, 'operator': '!='}],
      },
      orderBy: [
        {'field': 'data', 'direction': 'desc'},
        {'field': 'timestamp', 'direction': 'desc'}
      ],
    );

    // Buscar movimentações projetadas
    final movimentacoesProjetadas = await _movimentacaoEstoqueProjetadaService.getByAttributesWithOperators(
      {
        'propriedadeId': [{'value': propriedadeId, 'operator': '=='}],
        'itemId': [{'value': itemId, 'operator': '=='}],
        'statusProcessamento': [{'value': 'pendente', 'operator': '=='}],
        'ativo': [{'value': true, 'operator': '=='}],
        'data': [{'value': dataReferencia, 'operator': '<='}],
        if (origemId != null) 'origemId': [{'value': origemId, 'operator': '!='}],
      },
      orderBy: [
        {'field': 'data', 'direction': 'desc'},
        {'field': 'timestampLocal', 'direction': 'desc'}
      ],
    );

    // Filtrar movimentações projetadas por deviceId, se informado
    final movimentacoesProjetadasFiltradas = movimentacoesProjetadas.where((movimentacao) {
      return deviceId == null || movimentacao.deviceId == deviceId;
    }).toList();

    // Combinar todas as movimentações
    final todasMovimentacoes = [...movimentacoesReais, ...movimentacoesProjetadasFiltradas];

    // Filtrar movimentações com timestamp posterior caso a data seja igual
    final movimentacoesFiltradas = todasMovimentacoes.where((mov) {
      DateTime movData;
      DateTime movTimestamp;

      if (mov is MovimentacaoEstoque) {
        movData = mov.data;
        movTimestamp = mov.timestamp;
      } else if (mov is MovimentacaoEstoqueProjetada) {
        movData = mov.data;
        movTimestamp = mov.timestampLocal;
      } else {
        return false;
      }

      if (movData.isBefore(dataReferencia)) return true;

      if (movData.isAtSameMomentAs(dataReferencia) && timestampReferencia != null) {
        return movTimestamp.isBefore(timestampReferencia);
      }

      return false;
    }).toList();

    movimentacoesFiltradas.sort((a, b) {
      DateTime dataA = (a is MovimentacaoEstoque) ? a.data : (a as MovimentacaoEstoqueProjetada).data;
      DateTime dataB = (b is MovimentacaoEstoque) ? b.data : (b as MovimentacaoEstoqueProjetada).data;

      int cmp = dataB.compareTo(dataA);
      if (cmp == 0) {
        DateTime timestampA = (a is MovimentacaoEstoque) ? a.timestamp : (a as MovimentacaoEstoqueProjetada).timestampLocal;
        DateTime timestampB = (b is MovimentacaoEstoque) ? b.timestamp : (b as MovimentacaoEstoqueProjetada).timestampLocal;
        return timestampB.compareTo(timestampA);
      }
      return cmp;
    });


    // Retornar resultado
    if (movimentacoesFiltradas.isNotEmpty) {
      final ultima = movimentacoesFiltradas.first;

      if (ultima is MovimentacaoEstoque) {
        return {
          'quantidade': ultima.estoqueAtual,
          'unidadeMedida': ultima.unidadeMedida,
          'cmp': ultima.cmpAtual,
          'unidadeMedidaCMP': ultima.unidadeMedidaCMP,
          'dataUltimaAtualizacao': ultima.data,
          'origem': 'movimentacaoEstoque'
        };
      } else if (ultima is MovimentacaoEstoqueProjetada) {
        final projetada = ultima as MovimentacaoEstoqueProjetada; // Cast explícito aqui
        return {
          'quantidade': projetada.saldoProjetado,
          'unidadeMedida': projetada.unidadeMedida,
          'cmp': projetada.cmpProjetado,
          'unidadeMedidaCMP': projetada.unidadeMedidaCMP,
          'dataUltimaAtualizacao': projetada.data,
          'origem': 'movimentacaoEstoqueProjetada'
        };
      }

    }

    return {
      'quantidade': 0.0,
      'unidadeMedida': '',
      'cmp': 0.0,
      'unidadeMedidaCMP': '',
      'dataUltimaAtualizacao': dataReferencia,
      'origem': 'novo'
    };
  }

}
