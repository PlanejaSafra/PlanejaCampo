import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/models/frota_operacao_rural.dart';
import 'package:planejacampo/screens/agro/operacao_rural_form_screen.dart';
import 'package:planejacampo/screens/agro/operacao_rural_screen.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/services/frota_operacao_rural_service.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/operacao_rural_options.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class OperacoesRuraisListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;
  final String atividadeId;

  const OperacoesRuraisListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
    required this.atividadeId,
  }) : super(key: key);

  @override
  _OperacoesRuraisListScreenState createState() => _OperacoesRuraisListScreenState();
}

class _OperacoesRuraisListScreenState extends State<OperacoesRuraisListScreen> {
  final String _moduleName = 'operacoesRurais';
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  final FrotaOperacaoRuralService _frotaOperacaoRuralService = FrotaOperacaoRuralService();
  late Future<Map<String, TipoOperacaoRural>> _operacaoETiposFuture;
  late Future<Map<String, List<FrotaOperacaoRural>>> _operacoesEFrotasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _operacaoETiposFuture = _loadOperacaoETipos();
    _operacoesEFrotasFuture = _loadOperacoesEFrotas();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('operacoesRuraisListScreen');
    appStateManager.setShowTutorial('operacoesRuraisListScreen', false);
  }

  Future<Map<String, TipoOperacaoRural>> _loadOperacaoETipos() async {
    try {
      final Map<String, TipoOperacaoRural> tiposMap = {};
      final operacoes = await _operacaoRuralService.getByAttributes({
        'atividadeId': widget.atividadeId
      });

      for (var operacao in operacoes) {
        if (operacao.tipoOperacaoRuralId.isNotEmpty) {
          final tipo = await _tipoOperacaoRuralService.getById(operacao.tipoOperacaoRuralId);
          if (tipo != null) {
            tiposMap[operacao.id] = tipo;
          }
        }
      }

      return tiposMap;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, List<FrotaOperacaoRural>>> _loadOperacoesEFrotas() async {
    try {
      final Map<String, List<FrotaOperacaoRural>> frotasMap = {};
      final operacoes = await _operacaoRuralService.getByAttributes({
        'atividadeId': widget.atividadeId
      });

      for (var operacao in operacoes) {
        final frotasOperacao = await _frotaOperacaoRuralService.getByAttributes({
          'operacaoRuralId': operacao.id
        });
        frotasMap[operacao.id] = frotasOperacao;
      }

      return frotasMap;
    } catch (e) {
      throw e;
    }
  }

  void _refreshOperacoes() {
    _returnObject = true;
    setState(() {
      _operacaoETiposFuture = _loadOperacaoETipos();
      _operacoesEFrotasFuture = _loadOperacoesEFrotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Map<String, TipoOperacaoRural>, Map<String, List<FrotaOperacaoRural>>)>(
      future: Future.wait([_operacaoETiposFuture, _operacoesEFrotasFuture])
          .then((results) => (results[0] as Map<String, TipoOperacaoRural>,
      results[1] as Map<String, List<FrotaOperacaoRural>>)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        }

        final tiposMap = snapshot.data?.$1 ?? {};
        final frotasMap = snapshot.data?.$2 ?? {};

        return ListTemplate<OperacaoRural>(
          icon: CustomIcons.trator_operacao_2,
          future: _operacaoRuralService.getByAttributes({
            'atividadeId': widget.atividadeId
          }),
          serviceName: _operacaoRuralService,
          moduleName: _moduleName,
          title: widget.isSelectMode ? S.of(context).select_operation : S.of(context).rural_operations,
          itemTitleBuilder: (operacao) {
            final tipo = tiposMap[operacao.id];
            return tipo?.nome ?? S.of(context).unknown_type;
          },
          itemSubtitleBuilder: (operacao) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).fase}: ${OperacaoRuralOptions.getLocalizedFasesOperacoes(context)[operacao.fase] ?? operacao.fase}',
              ),
              Text(
                '${S.of(context).start_date}: ${FormatacaoUtil.formatDate(operacao.dataInicio)}',
              ),
              if (operacao.dataFim != null)
                Text(
                  '${S.of(context).end_date}: ${FormatacaoUtil.formatDate(operacao.dataFim!)}',
                ),
            ],
          ),
          itemExpandedContentWidgets: (operacao) {
            final List<Widget> widgets = [];

            if (operacao.area != null) {
              widgets.add(Text(
                  '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(operacao.area!)} ha'
              ));
            }

            if (operacao.talhoes?.isNotEmpty ?? false) {
              widgets.add(Text(
                  '${S.of(context).plots}: ${operacao.talhoes!.length}'
              ));
            }

            if (operacao.descricao != null && operacao.descricao!.isNotEmpty) {
              widgets.add(Text(
                  '${S.of(context).description}: ${operacao.descricao}'
              ));
            }

            final frotas = frotasMap[operacao.id] ?? [];

            if (frotas.isNotEmpty) {
              widgets.add(const SizedBox(height: 16));
              widgets.add(
                ObjectTemplate.buildCardSection(
                  CardSection(
                    title: S.of(context).fleets,
                    icon: Icons.agriculture,
                    cards: frotas.map((frota) {
                      return ListTile(
                        title: Text(
                          frota.frotaId,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${S.of(context).hour_meter_odometer}: ${frota.horimetroInicial} - ${frota.horimetroFinal}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horasUtilizadas)} h',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Theme.of(context),
                ),
              );
            }

            return widgets;
          },
          errorText: S.of(context).error_loading,
          formScreenBuilder: (operacao) => OperacaoRuralFormScreen(
            atividadeId: widget.atividadeId,
            operacaoRural: operacao,
          ),
          isSelectMode: widget.isSelectMode,
          isSetMode: widget.isSetMode,
          itemLeadingIcon: CustomIcons.trator_operacao_2,
          loadingText: S.of(context).loading,
          nomeTutorial: S.of(context).rural_operation,
          nomeTutorialPlural: S.of(context).rural_operations,
          notFoundText: S.of(context).not_found,
          onRefresh: _refreshOperacoes,
          showTutorial: _showTutorial,
          viewScreenBuilder: (operacao) => OperacaoRuralScreen(operacaoRural: operacao!),
          onWillPop: () async => true,
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}