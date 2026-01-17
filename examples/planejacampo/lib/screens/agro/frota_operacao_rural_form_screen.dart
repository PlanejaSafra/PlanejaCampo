import 'package:flutter/material.dart';
import 'package:planejacampo/models/frota_operacao_rural.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/screens/agro/frotas_list_screen.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/services/frota_operacao_rural_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';

class FrotaOperacaoRuralFormScreen extends StatefulWidget {
  final FrotaOperacaoRural? frotaOperacaoRural;
  final OperacaoRural operacaoRural;

  const FrotaOperacaoRuralFormScreen({
    Key? key,
    this.frotaOperacaoRural,
    required this.operacaoRural,
  }) : super(key: key);

  @override
  _FrotaOperacaoRuralFormScreenState createState() =>
      _FrotaOperacaoRuralFormScreenState();
}

class _FrotaOperacaoRuralFormScreenState
    extends State<FrotaOperacaoRuralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late FrotaOperacaoRural _currentFrotaOperacao;

  final TextEditingController _frotaController = TextEditingController();
  late TextEditingController _horasUtilizadasController;
  late TextEditingController _horimetroInicialController;
  late TextEditingController _horimetroFinalController;

  final FrotaService _frotaService = FrotaService();
  final FrotaOperacaoRuralService _frotaOperacaoRuralService =
  FrotaOperacaoRuralService();

  String? _selectedFrotaId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Adicionar listeners
    _horasUtilizadasController.addListener(_updateHorimetroFinal);
    _horimetroInicialController.addListener(_updateHorimetroFinal);
  }

  void _updateHorimetroFinal() {
    double horas = double.tryParse(_horasUtilizadasController.text.trim()) ?? 0.0;
    double inicial = double.tryParse(_horimetroInicialController.text.trim()) ?? 0.0;
    double finalHorimetro = horas + inicial;

    // Atualizar horimetroFinal apenas se não estiver sendo editado manualmente
    if (!_horimetroFinalController.text.contains(finalHorimetro.toString())) {
      _horimetroFinalController.text = finalHorimetro.toString();
    }
  }


  void _initializeData() {
    final appStateManager =
    Provider.of<AppStateManager>(context, listen: false);

    _initializeControllers();

    if (widget.frotaOperacaoRural != null) {
      _initializeExistingFrotaOperacao();
    } else {
      _initializeNewFrotaOperacao(appStateManager);
    }

    _loadInitialData();
  }

  void _initializeControllers() {
    _horasUtilizadasController = TextEditingController();
    _horimetroInicialController = TextEditingController();
    _horimetroFinalController = TextEditingController();
  }

  void _initializeExistingFrotaOperacao() {
    _currentFrotaOperacao = widget.frotaOperacaoRural!;

    setState(() {
      _selectedFrotaId = _currentFrotaOperacao.frotaId;
      _horasUtilizadasController.text =
          _currentFrotaOperacao.horasUtilizadas.toString();
      _horimetroInicialController.text =
          _currentFrotaOperacao.horimetroInicial.toString();
      _horimetroFinalController.text =
          _currentFrotaOperacao.horimetroFinal.toString();
      _loadFrotaDetails();
    });
  }

  void _initializeNewFrotaOperacao(AppStateManager appStateManager) {
    _currentFrotaOperacao = FrotaOperacaoRural(
      id: DateTime.now().toString(),
      operacaoRuralId: widget.operacaoRural.id,
      atividadeId: widget.operacaoRural.atividadeId,
      produtorId: widget.operacaoRural.produtorId,
      frotaId: '',
      horasUtilizadas: 0.0,
      horimetroInicial: 0.0,
      horimetroFinal: 0.0,
    );

    setState(() {
      // Inicializar campos com valores padrão, se necessário
    });
  }

  void _loadInitialData() {
    _loadFrotaDetails();
  }

  void _loadFrotaDetails() async {
    if (_selectedFrotaId != null && _selectedFrotaId!.isNotEmpty) {
      final frota = await _frotaService.getById(_selectedFrotaId!);
      if (frota != null && mounted) {
        setState(() {
          _frotaController.text = frota.nome;
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _selectFrota() async {
    final selectedFrota = await Navigator.push<Frota>(
      context,
      MaterialPageRoute(
        builder: (context) => FrotasListScreen(isSelectMode: true),
      ),
    );

    if (selectedFrota != null && mounted) {
      setState(() {
        _selectedFrotaId = selectedFrota.id;
        _frotaController.text = selectedFrota.nome;
        _horimetroInicialController.text = selectedFrota.horimetroOdometro.toString();
        _horasUtilizadasController.text = '0';
        _horimetroFinalController.text = selectedFrota.horimetroOdometro.toString();
        _hasChanges = true;
      });
    }
  }


  Future<void> _salvarFrotaOperacao() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final updatedFrotaOperacao = _currentFrotaOperacao.copyWith(
          id: widget.frotaOperacaoRural?.id ?? DateTime.now().toString(),
          frotaId: _selectedFrotaId ?? '',
          horasUtilizadas:
          double.parse(_horasUtilizadasController.text.trim()),
          horimetroInicial:
          double.parse(_horimetroInicialController.text.trim()),
          horimetroFinal:
          double.parse(_horimetroFinalController.text.trim()),
        );

        Navigator.of(context).pop(updatedFrotaOperacao); // Retorna o objeto atualizado

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context)
                  .error_saving_operation(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(null); // Retorna null ao cancelar
        return false;
      },
      child: FormTemplate(
        title: widget.frotaOperacaoRural == null
            ? S.of(context).add_fleet_operation
            : S.of(context).edit_fleet_operation,
        formKey: _formKey,
        onSave: _salvarFrotaOperacao,
        moduleName: 'operacoesRurais',
        body: _buildFormBody(context),
        isNewItem: widget.frotaOperacaoRural == null,
        returnObject: false, // Pode ser ajustado conforme necessário
        onWillPop: () async => true,
      ),
    );
  }

  @override
  Widget _buildFormBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFrotaSelectionSection(theme),
            SizedBox(height: 24),
            _buildHorasUtilizadasSection(theme),
            SizedBox(height: 24),
            _buildHorimetrosSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHorimetrosSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.speed, S.of(context).odometer),
        SizedBox(height: 16),
        _buildHorimetroInicialField(),
        SizedBox(height: 16),
        _buildHorimetroFinalField(),
      ],
    );
  }

  Widget _buildHorimetroFinalField() {
    return TextFormField(
      controller: _horimetroFinalController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).final_odometer,
        suffixIcon: Icon(Icons.speed),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _hasChanges = true;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).please_enter_final_horimeter;
        }
        final horimetro = double.tryParse(value.trim());
        if (horimetro == null || horimetro < 0) {
          return S.of(context).please_enter_valid_hours;
        }
        final inicial = double.tryParse(_horimetroInicialController.text.trim());
        if (inicial != null && horimetro < inicial) {
          return S.of(context).final_horimeter_must_be_greater;
        }
        return null;
      },
    );
  }


  Widget _buildFrotaSelectionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            theme, Icons.directions_car, S.of(context).fleet),
        SizedBox(height: 16),
        _buildFrotaSelectionField(),
      ],
    );
  }

  Widget _buildHorasUtilizadasSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            theme, Icons.timer, S.of(context).hours_used),
        SizedBox(height: 16),
        _buildHorasUtilizadasField(),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFrotaSelectionField() {
    return TextFormField(
      controller: _frotaController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).fleet,
        suffixIcon: Icon(Icons.search),
      ),
      readOnly: true,
      onTap: _selectFrota,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return S.of(context).please_select_fleet;
        }
        return null;
      },
    );
  }

  Widget _buildHorasUtilizadasField() {
    return TextFormField(
      controller: _horasUtilizadasController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).hours_used,
        suffixIcon: Icon(Icons.timer),
      ),
      keyboardType:
      TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _hasChanges = true;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).please_enter_utilized_hours;
        }
        final horas = double.tryParse(value.trim());
        if (horas == null || horas < 0) {
          return S.of(context).please_enter_valid_hours;
        }
        return null;
      },
    );
  }

  Widget _buildHorimetroInicialField() {
    return TextFormField(
      controller: _horimetroInicialController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).initial_odometer,
        suffixIcon: Icon(Icons.speed),
      ),
      keyboardType:
      TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _hasChanges = true;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).please_enter_initial_horimeter;
        }
        final horimetro = double.tryParse(value.trim());
        if (horimetro == null || horimetro < 0) {
          return S.of(context).please_enter_valid_hours; // Reutilização
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _frotaController.dispose();
    _horasUtilizadasController.dispose();
    _horimetroInicialController.dispose();
    _horimetroFinalController.dispose();
    super.dispose();
  }
}

