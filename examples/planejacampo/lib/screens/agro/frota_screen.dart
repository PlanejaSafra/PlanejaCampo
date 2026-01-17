import 'package:flutter/material.dart';
import 'package:planejacampo/models/abastecimento_frota.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/manutencao_frota.dart';
import 'package:planejacampo/screens/agro/abastecimento_frota_form_screen.dart';
import 'package:planejacampo/screens/agro/frota_form_screen.dart';
import 'package:planejacampo/screens/agro/manutencao_frota_form_screen.dart';
import 'package:planejacampo/services/abastecimento_frota_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/manutencao_frota_service.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/frota_options.dart';

class FrotaScreen extends StatefulWidget {
  final Frota frota;

  const FrotaScreen({
    Key? key,
    required this.frota,
  }) : super(key: key);

  @override
  _FrotaScreenState createState() => _FrotaScreenState();
}

class _FrotaScreenState extends State<FrotaScreen> {
  final String _moduleName = 'frotas';
  final FrotaService _frotaService = FrotaService();
  final AbastecimentoFrotaService _abastecimentoService = AbastecimentoFrotaService();
  final ManutencaoFrotaService _manutencaoService = ManutencaoFrotaService();
  final ItemService _itemService = ItemService();

  late Future<Frota?> _futureFrota;
  late Future<List<AbastecimentoFrota>> _futureAbastecimentos;
  late Future<List<ManutencaoFrota>> _futureManutencoes;
  Map<String, String> _itemNames = {};

  late bool _canEdit;
  late bool _canDelete;
  late Frota _currentFrota;
  Object _returnObject = '';
  bool _showTutorial = false;
  bool _isExpanded = false;

  // Keys para tutorial
  final GlobalKey _abastecimentosKey = GlobalKey();
  final GlobalKey _addAbastecimentoKey = GlobalKey();
  final GlobalKey _firstAbastecimentoMoreOptionsKey = GlobalKey();

  final GlobalKey _manutencoesKey = GlobalKey();
  final GlobalKey _addManutencaoKey = GlobalKey();
  final GlobalKey _firstManutencaoMoreOptionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentFrota = widget.frota;
    _loadData();
    _checkPermissions();

    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('frotaScreen');
    appStateManager.setShowTutorial('frotaScreen', false);
  }

  void _loadData() {
    _loadFrota();
    _loadAbastecimentos();
    _loadManutencoes();
  }

  void _loadFrota() {
    setState(() {
      _futureFrota = _frotaService.getById(_currentFrota.id);
    });
  }

  void _loadAbastecimentos() {
    setState(() {
      _futureAbastecimentos = _abastecimentoService.getByAttributes({
        'frotaId': _currentFrota.id
      });
    });

    // Carrega nomes dos itens para abastecimentos
    _futureAbastecimentos.then((abastecimentos) async {
      if (abastecimentos.isNotEmpty) {
        final itemIds = abastecimentos.map((a) => a.itemId).toSet().toList();
        final items = await _itemService.getByIds(itemIds);
        if (mounted) {
          setState(() {
            _itemNames = { for (var item in items) item.id: item.nome };
          });
        }
      }
    });
  }

  void _loadManutencoes() {
    setState(() {
      _futureManutencoes = _manutencaoService.getByAttributes({
        'frotaId': _currentFrota.id
      });
    });
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  Future<void> _navigateToAbastecimentoFormScreen([AbastecimentoFrota? abastecimento]) async {
    final result = await Navigator.push<AbastecimentoFrota>(
      context,
      MaterialPageRoute(
        builder: (context) => AbastecimentoFrotaFormScreen(
          frota: _currentFrota,
          abastecimentoFrota: abastecimento,
        ),
      ),
    );

    if (result != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(S.of(context).processing),
                  ],
                ),
              ),
            );
          },
        );

        if (abastecimento == null) {
          await _abastecimentoService.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).refueling_added_successfully)),
          );
        } else {
          await _abastecimentoService.update(result.id, result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).refueling_updated_successfully)),
          );
        }

        Navigator.of(context).pop();
        setState(() {
          _returnObject = true;
        });
        _loadData();

      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_refueling(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToManutencaoFormScreen([ManutencaoFrota? manutencao]) async {
    final result = await Navigator.push<ManutencaoFrota>(
      context,
      MaterialPageRoute(
        builder: (context) => ManutencaoFrotaFormScreen(
          frota: _currentFrota,
          manutencaoFrota: manutencao,
        ),
      ),
    );

    // Se 'result' não for null, o form já fez o add/update
    if (result != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(S.of(context).processing),
                  ],
                ),
              ),
            );
          },
        );

        // Nenhuma chamada ao _manutencaoService.add / update aqui
        // pois o form já salvou no DB

        Navigator.of(context).pop();  // Fecha loading

        setState(() {
          _returnObject = true;
        });
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).maintenance_updated_successfully)),
        );

      } catch (e) {
        Navigator.of(context).pop(); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_maintenance(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _removeAbastecimento(AbastecimentoFrota abastecimento) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).refueling_record)),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(S.of(context).remove),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.of(context).processing),
                ],
              ),
            ),
          );
        },
      );

      try {
        await _abastecimentoService.delete(abastecimento.id);
        Navigator.of(context).pop();
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).refueling_record_removed)),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_removing_refueling(e.toString()))),
        );
      }
    }
  }

  void _removeManutencao(ManutencaoFrota manutencao) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).maintenance_record)),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(S.of(context).remove),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.of(context).processing),
                ],
              ),
            ),
          );
        },
      );

      try {
        await _manutencaoService.delete(manutencao.id);
        Navigator.of(context).pop();
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).maintenance_record_removed)),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_removing_maintenance(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).fleet_details,
      moduleName: _moduleName,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _frotaService,
      itemIdValue: widget.frota.id,
      itemName: S.of(context).fleet,
      fieldReference: 'frotaId',
      cardSections: [
        _buildManutencoesCards(),
        _buildAbastecimentosCards(),
      ],
      customTutorialSteps: _buildCustomTutorialSteps(),
      customActionTutorialSteps: _buildActionTutorialSteps(),
      additionalFloatingActionButtons: (BuildContext context) => [
        ObjectTemplate.buildCustomFloatingActionButton(
          context: context,
          onPressed: () {
            _toggleFloatingActionButton();
            _navigateToManutencaoFormScreen();
          },
          icon: Icons.add,
          text: S.of(context).add_maintenance,
          key: _addManutencaoKey,
          heroTag: 'addManutencao',
        ),
        ObjectTemplate.buildCustomFloatingActionButton(
          context: context,
          onPressed: () {
            _toggleFloatingActionButton();
            _navigateToAbastecimentoFormScreen();
          },
          icon: Icons.add,
          text: S.of(context).add_refueling,
          key: _addAbastecimentoKey,
          heroTag: 'addAbastecimento',
        ),
      ],
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    Map<String, Map<String, dynamic>> steps = {
      'manutencoes': {
        'key': _manutencoesKey,
        'message': S.of(context).maintenance_records_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
      'abastecimentos': {
        'key': _abastecimentosKey,
        'message': S.of(context).refueling_records_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
    };

    return steps;
  }

  Map<String, Map<String, dynamic>> _buildActionTutorialSteps() {
    return {
      'addManutencao': {
        'key': _addManutencaoKey,
        'message': S.of(context).add_maintenance,
        'shape': 'Circle',
        'align': 'ContentAlign.top',
      },
      'addAbastecimento': {
        'key': _addAbastecimentoKey,
        'message': S.of(context).add_refueling,
        'shape': 'Circle',
        'align': 'ContentAlign.top',
      },
    };
  }

  Widget _buildFrotaDetails(Frota frota) {
    final localizedTipos = FrotaOptions.getLocalizedTiposFrota(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem da Frota
                if (frota.fotoUrl != null && frota.fotoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      frota.fotoUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700]),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                  ),
                const SizedBox(width: 16),
                // Informações Básicas da Frota
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        frota.nome,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Theme.of(context).colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            localizedTipos[frota.tipo] ?? frota.tipo,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Informações de Identificação
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.badge,
              label: S.of(context).identifier,
              value: frota.identificador ?? '-',
            ),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.directions_car,
              label: S.of(context).model,
              value: frota.modelo ?? '-',
            ),
            const SizedBox(height: 24),
            // Informações de Características
            Text(
              S.of(context).characteristics,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.calendar_today,
              label: S.of(context).year_of_manufacture,
              value: frota.anoFabricacao?.toString() ?? '-',
            ),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.attach_money,
              label: S.of(context).value,
              value: frota.valor != null
                  ? '${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.valor!)}'
                  : '-',
            ),
            const SizedBox(height: 24),
            // Informações Operacionais
            Text(
              S.of(context).operational_data,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.speed,
              label: S.of(context).hour_meter_odometer,
              value: frota.horimetroOdometro != null
                  ? FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horimetroOdometro!)
                  : '-',
            ),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.hourglass_bottom,
              label: S.of(context).useful_life,
              value: frota.vidaUtil != null
                  ? '${frota.vidaUtil} ${S.of(context).years}'
                  : '-',
            ),
            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.date_range,
              label: S.of(context).acquisition_date,
              value: frota.dataAquisicao != null
                  ? FormatacaoUtil.formatDate(frota.dataAquisicao!)
                  : '-',
            ),
            if (frota.observacoes != null && frota.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              // Observações
              Text(
                S.of(context).notes,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  frota.observacoes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  CardSection _buildManutencoesCards() {
    return ObjectTemplate.buildCardSectionWithFuture<ManutencaoFrota>(
      key: _manutencoesKey,
      title: S.of(context).maintenance_records,
      iconePrincipal: Icons.build,
      future: _futureManutencoes,
      itemTitle: (manutencao) => FormatacaoUtil.formatDate(manutencao.data),
      itemSubtitle: (manutencao) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (manutencao.horimetro != null)
              Text(
                '${S.of(context).hour_meter_odometer}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(manutencao.horimetro!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (manutencao.observacoes != null)
              Text(
                manutencao.observacoes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
      onEdit: (manutencao) => _navigateToManutencaoFormScreen(manutencao),
      onDelete: (manutencao) => _removeManutencao(manutencao),
      itemLeadingIcon: Icons.build,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_maintenance_records,
      firstItemMoreOptionsKey: _firstManutencaoMoreOptionsKey,
    );
  }

  CardSection _buildAbastecimentosCards() {
    return ObjectTemplate.buildCardSectionWithFuture<AbastecimentoFrota>(
      key: _abastecimentosKey,
      title: S.of(context).refueling_records,
      iconePrincipal: Icons.local_gas_station,
      future: _futureAbastecimentos,
      itemTitle: (abastecimento) => FormatacaoUtil.formatDate(abastecimento.data),
      itemSubtitle: (abastecimento) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).item}: ${_itemNames[abastecimento.itemId] ?? S.of(context).not_found}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(abastecimento.quantidadeUtilizada)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[abastecimento.unidadeMedida] ?? abastecimento.unidadeMedida}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (abastecimento.externo) ...[
              Text(
                S.of(context).external_refueling,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (abastecimento.valorTotal != null)
                Text(
                  '${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(abastecimento.valorTotal!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (abastecimento.meioPagamento != null)
                Text(
                  '${S.of(context).payment_method}: ${abastecimento.meioPagamento}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        );
      },
      onEdit: (abastecimento) => _navigateToAbastecimentoFormScreen(abastecimento),
      onDelete: (abastecimento) => _removeAbastecimento(abastecimento),
      itemLeadingIcon: Icons.local_gas_station,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_refueling_records,
      firstItemMoreOptionsKey: _firstAbastecimentoMoreOptionsKey,
    );
  }

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FrotaFormScreen(frota: _currentFrota),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    ).then((updatedFrota) {
      if (updatedFrota != null) {
        _returnObject = true;
        if (updatedFrota is Frota) {
          setState(() {
            _currentFrota = updatedFrota;
          });
        }
        _loadData();
      }
    });
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Frota?>(
      future: _futureFrota,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final frota = snapshot.data!;
          return _buildFrotaDetails(frota);
        }
      },
    );
  }

  // [O método _buildFrotaDetails continua igual ao original]

  @override
  void dispose() {
    super.dispose();
  }
}