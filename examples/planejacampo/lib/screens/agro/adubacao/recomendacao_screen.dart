// V02
import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/aplicacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_form_screen.dart';
import 'package:planejacampo/services/agro/adubacao/aplicacao_nutriente_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_calagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_gessagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_nutriente_service.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class RecomendacaoScreen extends StatefulWidget {
  final Recomendacao recomendacao;
  final Map<String, RecomendacaoNutriente>? nutrientes;
  final Map<String, dynamic>? correcoes;
  final Map<String, List<AplicacaoNutriente>>? aplicacoes;

  const RecomendacaoScreen({
    Key? key,
    required this.recomendacao,
    this.nutrientes,
    this.correcoes,
    this.aplicacoes,
  }) : super(key: key);

  @override
  _RecomendacaoScreenState createState() => _RecomendacaoScreenState();
}

class _RecomendacaoScreenState extends State<RecomendacaoScreen> {
  final RecomendacaoService _recomendacaoService = RecomendacaoService();
  final RecomendacaoNutrienteService _recomendacaoNutrienteService = RecomendacaoNutrienteService();
  final RecomendacaoCalagemService _recomendacaoCalagemService = RecomendacaoCalagemService();
  final RecomendacaoGessagemService _recomendacaoGessagemService = RecomendacaoGessagemService();
  final AplicacaoNutrienteService _aplicacaoNutrienteService = AplicacaoNutrienteService();

  late Future<Map<String, dynamic>> _dataFuture;
  late Recomendacao _recomendacao;
  Object _returnObject = '';
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;

  // Tutorial keys
  final GlobalKey _infoGeralKey = GlobalKey();
  final GlobalKey _correcaoSoloKey = GlobalKey(); // Nova chave para Correção de Solo
  final GlobalKey _nutrientesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _recomendacao = widget.recomendacao;
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('recomendacoesAdubacao');
    _canDelete = appStateManager.canDelete('recomendacoesAdubacao');
    _showTutorial = appStateManager.showTutorial('recomendacaoScreen');
    appStateManager.setShowTutorial('recomendacaoScreen', false);

    // Se já temos os dados complementares, usamos eles. Caso contrário, carregamos do banco
    if (widget.nutrientes != null && widget.correcoes != null) {
      _dataFuture = Future.value({
        'nutrientes': widget.nutrientes!,
        'correcoes': widget.correcoes!,
        'aplicacoes': widget.aplicacoes!
      });
    } else {
      _dataFuture = _loadDadosComplementares();
    }
  }

  Future<Map<String, dynamic>> _loadDadosComplementares() async {
    try {
      // Obter recomendações de nutrientes
      final nutrientes = await _recomendacaoNutrienteService.getByAttributes({
        'recomendacaoId': _recomendacao.id
      });

      // Mapear para formato esperado pela tela
      final nutrientesMap = <String, RecomendacaoNutriente>{};
      final aplicacoesPorNutriente = <String, List<AplicacaoNutriente>>{};
      for (var nutriente in nutrientes) {
        nutrientesMap[nutriente.nutriente] = nutriente;
        //print('Nutriente: ${nutriente.nutriente}, Dose: ${nutriente.doseRecomendada}');

        final aplicacoes = await _aplicacaoNutrienteService.getByAttributes({'recomendacaoNutrienteId': nutriente.id});
        //print('Aplicações para ${nutriente.nutriente}: ${aplicacoes.length}');
        //print('Aplicações: $aplicacoes, Doses: ${aplicacoes.map((a) => a.dosePlanejada).toList()}');
        aplicacoesPorNutriente[nutriente.nutriente] = aplicacoes;
        //aplicacoesPorNutriente = await _aplicacaoNutrienteService.getByAttributes({'recomendacaoNutrienteId': nutriente.id});
      }

      // Obter recomendação de calagem (se existir)
      final calagemList = await _recomendacaoCalagemService.getByAttributes({
        'recomendacaoId': _recomendacao.id
      });

      // Obter recomendação de gessagem (se existir)
      final gessagemList = await _recomendacaoGessagemService.getByAttributes({
        'recomendacaoId': _recomendacao.id
      });

      // Montar o mapa de correções
      final correcoesMap = <String, dynamic>{};
      if (calagemList.isNotEmpty) {
        correcoesMap['calagem'] = calagemList.first;
      }
      if (gessagemList.isNotEmpty) {
        correcoesMap['gessagem'] = gessagemList.first;
      }

      // NOVO: Carregar aplicações para cada nutriente
      //final aplicacoesPorNutriente = <String, List<AplicacaoNutriente>>{};

      //for (var nutriente in nutrientes) {
      //  final aplicacoes = await _aplicacaoService.getByRecomendacaoNutriente(nutriente.id);
      //  if (aplicacoes.isNotEmpty) {
      //    aplicacoesPorNutriente[nutriente.nutriente] = aplicacoes;
      //  }
      //}


      return {
        'nutrientes': nutrientesMap,
        'correcoes': correcoesMap,
        'aplicacoes': aplicacoesPorNutriente, // NOVO: Incluir aplicações no retorno
      };
    } catch (e) {
      print('Erro ao carregar dados complementares: $e');
      throw e;
    }
  }

  void _navigateToFormScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecomendacaoFormScreen(
          recomendacao: _recomendacao,
        ),
      ),
    ).then((result) {
      if (result != null) {
        // Se retornou uma recomendação atualizada
        setState(() {
          _recomendacao = result;
          _returnObject = result;
        });
        _loadDadosComplementares(); // Recarregar dados relacionados
      }
    });
  }

  Widget _buildTimelineAplicacoes(List<AplicacaoNutriente> aplicacoes, Color cardColor) {
    return Container(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: aplicacoes.map((aplicacao) {
          final bool isPlantio = RegExp(r'plant', caseSensitive: false).hasMatch(aplicacao.fase);
          final IconData iconData = isPlantio ? Icons.grass : Icons.calendar_today;
          String timeInfo = isPlantio ? 'Plantio' :
          '+${aplicacao.diasAposPlantio} ${S.of(context).days}';

          return Container(
            width: 100,
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, color: cardColor),
                SizedBox(height: 4),
                Text(
                  timeInfo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${aplicacao.dosePlanejada.toStringAsFixed(1)} kg/ha',
                  style: TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(S.of(context).error_loading),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(S.of(context).not_found),
          );
        }

        final data = snapshot.data!;
        final nutrientes = data['nutrientes'] as Map<String, RecomendacaoNutriente>;
        final correcoes = data['correcoes'] as Map<String, dynamic>;
        final aplicacoes = data['aplicacoes'] as Map<String, List<AplicacaoNutriente>>? ?? {};

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildInfoGeral(),
              _buildCorrecaoSolo(correcoes),
              _buildNutrientes(nutrientes, aplicacoes),
              _buildAvisos(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoGeral() {
    return Card(
      key: _infoGeralKey,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28
                ),
                SizedBox(width: 10),
                Text(
                  S.of(context).general_information,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildInfoRowWithIcon(
                Icons.grass,
                S.of(context).crop_type,
                _recomendacao.tipoCultura.getLocalizedName(context)
            ),
            _buildInfoRowWithIcon(
                Icons.eco,
                S.of(context).expected_yield,
                '${_recomendacao.produtividadeEsperada.toStringAsFixed(1)} t/ha'
            ),
            _buildInfoRowWithIcon(
                Icons.event,
                S.of(context).planting_date,
                FormatacaoUtil.formatDate(_recomendacao.dataPlantio)
            ),
            _buildInfoRowWithIcon(
                Icons.landscape,
                S.of(context).cultivation_system,
                _recomendacao.sistemaCultivo.getLocalizedName(context)
            ),
            _buildInfoRowWithIcon(
                Icons.layers,
                S.of(context).soil_texture,
                _recomendacao.texturaSolo.getLocalizedName(context)
            ),
            _buildInfoRowWithIcon(
                Icons.water_drop,
                S.of(context).irrigated,
                _recomendacao.irrigado ? S.of(context).yes : S.of(context).no
            ),
          ],
        ),
      ),
    );
  }

  // Novo método para construir o card de Correção de Solo
  Widget _buildCorrecaoSolo(Map<String, dynamic> correcoes) {
    final hasCalagem = correcoes.containsKey('calagem');
    final hasGessagem = correcoes.containsKey('gessagem');

    // Se não tiver nem calagem nem gessagem, não mostrar o card
    if (!hasCalagem && !hasGessagem) return SizedBox.shrink();

    return Card(
      key: _correcaoSoloKey, // Adicionar chave para tutorial
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28
                ),
                SizedBox(width: 10),
                Text(
                  S.of(context).soil_correction,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),

            // Card expansível para Calagem
            if (hasCalagem)
              _buildCorrecaoDetailCard(
                'limestone',
                S.of(context).liming,
                correcoes['calagem'],
                Colors.amber,
                Icons.science,
              ),

            // Card expansível para Gessagem
            if (hasGessagem)
              _buildCorrecaoDetailCard(
                'gypsum',
                S.of(context).gypsum,
                correcoes['gessagem'],
                Colors.blue,
                Icons.blur_on,
              ),
          ],
        ),
      ),
    );
  }

  // Novo método para construir um card de detalhe de correção (calagem ou gessagem)
  Widget _buildCorrecaoDetailCard(String tipo, String titulo, dynamic correcao, Color cardColor, IconData iconData) {
    final bool temObservacoes = correcao.observacoes != null && correcao.observacoes.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: cardColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tipo == 'limestone')
                    Text(
                      '${S.of(context).limestone_dose}: ${correcao.quantidadeRecomendada.toStringAsFixed(1)} t/ha',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (tipo == 'gypsum')
                    Text(
                      '${S.of(context).gypsum_dose}: ${correcao.doseRecomendada.toStringAsFixed(1)} t/ha',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detalhes específicos de calagem
                if (tipo == 'limestone') ...[
                  _buildInfoRowWithIcon(
                      Icons.percent,
                      S.of(context).prnt,
                      '${correcao.prnt.toStringAsFixed(1)}%'
                  ),
                  _buildInfoRowWithIcon(
                      Icons.vertical_align_bottom,
                      S.of(context).incorporation_depth,
                      '${correcao.profundidadeIncorporacao.toStringAsFixed(1)} cm'
                  ),
                  _buildInfoRowWithIcon(
                      Icons.settings,
                      S.of(context).application_mode,
                      correcao.modoAplicacao
                  ),
                ],

                // Detalhes específicos de gessagem
                if (tipo == 'gypsum') ...[
                  _buildInfoRowWithIcon(
                      Icons.settings,
                      S.of(context).application_mode,
                      correcao.modoAplicacao
                  ),
                  _buildInfoRowWithIcon(
                      Icons.vertical_align_bottom,
                      S.of(context).evaluation_depth,
                      '${correcao.profundidadeAvaliada} cm'
                  ),
                ],

                // Observações (se existirem)
                if (temObservacoes)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 16),
                      Text(
                        S.of(context).recommendations_and_notes,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...correcao.observacoes.map((obs) => _buildObservationItem(obs, cardColor)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNutrientes(
      Map<String, RecomendacaoNutriente> nutrientes,
      Map<String, List<AplicacaoNutriente>> aplicacoesPorNutriente) {
    return Card(
      key: _nutrientesKey,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section unchanged...

            // Macronutrientes section
            if (nutrientes.containsKey('N') ||
                nutrientes.containsKey('P2O5') ||
                nutrientes.containsKey('K2O'))
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).macronutrients,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(height: 16, thickness: 0.5),
                    if (nutrientes.containsKey('N'))
                      _buildNutrienteDetailCard('N', nutrientes['N']!, aplicacoesPorNutriente),
                    if (nutrientes.containsKey('P2O5'))
                      _buildNutrienteDetailCard('P2O5', nutrientes['P2O5']!, aplicacoesPorNutriente),
                    if (nutrientes.containsKey('K2O'))
                      _buildNutrienteDetailCard('K2O', nutrientes['K2O']!, aplicacoesPorNutriente),
                  ],
                ),
              ),

            // Micronutrientes section
            if (nutrientes.containsKey('Zn') ||
                nutrientes.containsKey('B') ||
                nutrientes.containsKey('Cu') ||
                nutrientes.containsKey('Mn'))
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).micronutrients,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(height: 16, thickness: 0.5),
                    if (nutrientes.containsKey('Zn'))
                      _buildNutrienteDetailCard('Zn', nutrientes['Zn']!, aplicacoesPorNutriente),
                    if (nutrientes.containsKey('B'))
                      _buildNutrienteDetailCard('B', nutrientes['B']!, aplicacoesPorNutriente),
                    if (nutrientes.containsKey('Cu'))
                      _buildNutrienteDetailCard('Cu', nutrientes['Cu']!, aplicacoesPorNutriente),
                    if (nutrientes.containsKey('Mn'))
                      _buildNutrienteDetailCard('Mn', nutrientes['Mn']!, aplicacoesPorNutriente),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildNutrienteDetailCard(
      String simbolo,
      RecomendacaoNutriente nutriente,
      Map<String, List<AplicacaoNutriente>> aplicacoesPorNutriente) {
    final Color cardColor = _getNutrienteColor(simbolo);
    final bool temObservacoes = nutriente.observacoes != null && nutriente.observacoes!.isNotEmpty;

    // Get applications for this nutrient
    final List<AplicacaoNutriente> aplicacoes = aplicacoesPorNutriente[simbolo] ?? [];
    final bool temAplicacoes = aplicacoes.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                simbolo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getNutrienteName(simbolo),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${S.of(context).recommended_dose}: ${nutriente.doseRecomendada.toStringAsFixed(1)} kg/ha',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nutriente.fonte != null && nutriente.fonte!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.science_outlined, size: 20, color: cardColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).source}: ${nutriente.fonte}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Application section
                if (temAplicacoes) ...[
                  Divider(height: 16),
                  Text(
                    'Aplicações',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildAplicacoesTable(aplicacoes, cardColor),
                  SizedBox(height: 8),
                  _buildTimelineAplicacoes(aplicacoes, cardColor),
                  _buildModoAplicacaoInfo(aplicacoes, cardColor),
                ],

                // Observations section
                if (temObservacoes) ...[
                  Divider(height: 16),
                  Text(
                    S.of(context).observations,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...nutriente.observacoes!.map((obs) =>
                      _buildObservationItem(obs, cardColor)
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAplicacoesTable(List<AplicacaoNutriente> aplicacoes, Color cardColor) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
      },
      children: [
        // Cabeçalho
        TableRow(
          decoration: BoxDecoration(color: cardColor.withOpacity(0.1)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(S.of(context).phase, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(S.of(context).dose_kg_ha, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        // Linhas de dados
        ...aplicacoes.map((aplicacao) => TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(FaseAplicacao.fromString(aplicacao.fase).getLocalizedName(context)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(aplicacao.dosePlanejada.toStringAsFixed(1)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('${aplicacao.percentualDose.toStringAsFixed(0)}%'),
            ),
          ],
        )).toList(),
      ],
    );
  }

// Adicionar método para exibir detalhes de modo de aplicação
  Widget _buildModoAplicacaoInfo(List<AplicacaoNutriente> aplicacoes, Color cardColor) {
    // Se não houver aplicações, não mostrar a seção
    if (aplicacoes.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        // 1. Internacionalização do título
        Text(
          S.of(context).application_mode, // Usa a chave de tradução
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        // 2. Mapeamento para exibir a fase traduzida
        ...aplicacoes.map((aplicacao) {
          print('fase: ${aplicacao.fase}, modo: ${aplicacao.modoAplicacao}, dose: ${aplicacao.dosePlanejada}, percentual: ${aplicacao.percentualDose}, dias: ${aplicacao.diasAposPlantio}, aplicacaoId: ${aplicacao.id}, recomendacaoId: ${aplicacao.recomendacaoNutrienteId}, recomendacaoNutrienteId: ${aplicacao.recomendacaoNutrienteId}, ');
          // Converte a string da fase para o enum e pega o nome localizado
          final faseTraduzida = FaseAplicacao.fromString(aplicacao.fase).getLocalizedName(context);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.label_outlined, size: 16, color: cardColor),
                SizedBox(width: 8),
                // Exibe a fase traduzida
                Text('$faseTraduzida: ', style: TextStyle(fontWeight: FontWeight.w500)),
                // Exibe o modo de aplicação (que parece ser uma string descritiva)
                Expanded(child: Text(aplicacao.modoAplicacao)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildObservationItem(String observation, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              observation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisos() {
    // Aqui você pode criar uma seção para exibir os avisos gerais
    // Esta é uma lista estática de avisos baseada nos dados da recomendação
    final List<String> avisos = _gerarAvisos();

    if (avisos.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.amber.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 28
                ),
                SizedBox(width: 10),
                Text(
                  S.of(context).warnings_and_alerts,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...avisos.map((aviso) => _buildWarningItem(aviso)),
          ],
        ),
      ),
    );
  }

  List<String> _gerarAvisos() {
    // Este método gera avisos com base nos dados da recomendação
    // Isso pode ser melhorado para gerar avisos mais específicos
    // baseados nos dados reais

    return [
      // Exemplo de avisos que poderiam ser gerados:
      if (_recomendacao.irrigado)
        S.of(context).irrigated_crop_recommendation_warning,
      if (_recomendacao.texturaSolo == TexturaSolo.ARENOSO)
        S.of(context).sandy_soil_recommendation_warning,
      if (_recomendacao.sistemaCultivo == SistemaCultivo.PLANTIO_DIRETO)
        S.of(context).no_till_system_recommendation_warning,
    ];
  }

  Widget _buildWarningItem(String warning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservacoesSection(List<String> observacoes) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).observations,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 16),
            ...observacoes.map((observacao) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      observacao,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithHighlight(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 2),
                Container(
                  padding: isHighlight ? EdgeInsets.symmetric(horizontal: 8, vertical: 4) : null,
                  decoration: isHighlight ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ) : null,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isHighlight ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getNutrienteColor(String nutriente) {
    switch(nutriente) {
      case 'N': return Colors.green;
      case 'P2O5': return Colors.orange;
      case 'K2O': return Colors.purple;
      case 'Zn': return Colors.blue;
      case 'B': return Colors.red;
      case 'Cu': return Colors.cyan;
      case 'Mn': return Colors.amber;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  String _getNutrienteName(String nutriente) {
    switch(nutriente) {
      case 'N': return S.of(context).nitrogen;
      case 'P2O5': return S.of(context).phosphorus;
      case 'K2O': return S.of(context).potassium;
      case 'Zn': return S.of(context).zinc;
      case 'B': return S.of(context).boron;
      case 'Cu': return S.of(context).copper;
      case 'Mn': return S.of(context).manganese;
      default: return nutriente;
    }
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'infoGeral': {
        'key': _infoGeralKey,
        'message': S.of(context).general_info_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'correcaoSolo': {
        'key': _correcaoSoloKey,
        'message': S.of(context).soil_correction_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'nutrientes': {
        'key': _nutrientesKey,
        'message': S.of(context).nutrients_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).recommendation_details,
      moduleName: 'recomendacoesAdubacao',
      showTutorial: _showTutorial,
      customTutorialSteps: _buildCustomTutorialSteps(),
      returnObject: _returnObject,
      onWillPop: () async => true,
      summarySection: _buildFormSection(),
      serviceName: _recomendacaoService,
      itemIdValue: _recomendacao.id,
      itemName: S.of(context).recommendation,
      fieldReference: 'recomendacaoId',
      cardSections: [],
      isExpanded: false,
      canDelete: _canDelete,
      canEdit: _canEdit, // Mude de false para _canEdit
      onEditPressed: _navigateToFormScreen, // Adicione esta linha
    );
  }
}