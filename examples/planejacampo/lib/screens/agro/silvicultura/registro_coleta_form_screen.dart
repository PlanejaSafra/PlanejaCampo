import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/models/registro_coleta.dart';
import 'package:planejacampo/services/registro_coleta_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class RegistroColetaFormScreen extends StatefulWidget {
  final RegistroColeta? registroColeta;

  const RegistroColetaFormScreen({Key? key, this.registroColeta}) : super(key: key);

  @override
  _RegistroColetaFormScreenState createState() => _RegistroColetaFormScreenState();
}

class _RegistroColetaFormScreenState extends State<RegistroColetaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late RegistroColeta _currentRegistroColeta;
  late TextEditingController _dataColetaController;
  late MoneyMaskedTextController _quantidadeCaixaController;
  late MoneyMaskedTextController _pesoMedioCaixaController;
  late MoneyMaskedTextController _pesoTotalController;

  final RegistroColetaService _registroColetaService = RegistroColetaService();
  final String moduleName = 'registrosColetas';

  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  Object _returnObject = false;

  final GlobalKey _dataColetaKey = GlobalKey();
  final GlobalKey _quantidadeCaixaKey = GlobalKey();
  final GlobalKey _pesoMedioCaixaKey = GlobalKey();
  final GlobalKey _pesoTotalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit(moduleName);
    _canDelete = appStateManager.canDelete(moduleName);

    _showTutorial = appStateManager.showTutorial('registroColetaFormScreen');
    appStateManager.setShowTutorial('registroColetaFormScreen', false);

    _currentRegistroColeta = widget.registroColeta ??
        RegistroColeta(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId ?? '',
          propriedadeId: appStateManager.activePropriedadeId ?? '',
          atividadeId: appStateManager.activeAtividadeRural?.id ?? '',
          dataColeta: DateTime.now(),
          quantidadeCaixa: 0,
          pesoMedioCaixa: 0.0,
          pesoTotal: 0.0,
        );

    _dataColetaController = TextEditingController(text: DateFormat.yMd().format(_currentRegistroColeta.dataColeta));
    _quantidadeCaixaController = FormatacaoUtil.getMaskedTextController(_currentRegistroColeta.quantidadeCaixa?.toDouble() ?? 0.0);
    _pesoMedioCaixaController = FormatacaoUtil.getMaskedTextController(_currentRegistroColeta.pesoMedioCaixa ?? 0.0);
    _pesoTotalController = FormatacaoUtil.getMaskedTextController(_currentRegistroColeta.pesoTotal ?? 0.0);

    _quantidadeCaixaController.addListener(_updatePesoTotal);
    _pesoMedioCaixaController.addListener(_updatePesoTotal);
  }

  void _updatePesoTotal() {
    double quantidadeCaixa = _quantidadeCaixaController.numberValue;
    double pesoMedioCaixa = _pesoMedioCaixaController.numberValue;
    double pesoTotal = quantidadeCaixa * pesoMedioCaixa;

    setState(() {
      _pesoTotalController.updateValue(pesoTotal);
      _currentRegistroColeta = _currentRegistroColeta.copyWith(pesoTotal: pesoTotal);
    });
  }

  Future<void> _saveRegistroColeta() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        if (widget.registroColeta == null) {
          await _registroColetaService.add(_currentRegistroColeta);
        } else {
          await _registroColetaService.update(_currentRegistroColeta.id, _currentRegistroColeta);
        }
        _returnObject = widget.registroColeta == null ? true : _currentRegistroColeta;
        Navigator.of(context).pop(_returnObject);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).collection_record)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormTemplate(
      title: widget.registroColeta == null
          ? S.of(context).add_collection_record
          : S.of(context).edit_collection_record,
      formKey: _formKey,
      onSave: _saveRegistroColeta,
      moduleName: moduleName,
      isNewItem: widget.registroColeta == null,
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      returnObject: _returnObject,
      onWillPop: () async {
        Navigator.of(context).pop(_currentRegistroColeta);
        return false;
      },
      customTutorialSteps: {
        'dataColeta': {
          'key': _dataColetaKey,
          'message': S.of(context).collection_date_explanation,
          'shape': 'RRect',
          'align': 'ContentAlign.bottom',
        },
        'quantidadeCaixa': {
          'key': _quantidadeCaixaKey,
          'message': S.of(context).quantity_boxes_explanation,
          'shape': 'RRect',
          'align': 'ContentAlign.bottom',
        },
        'pesoMedioCaixa': {
          'key': _pesoMedioCaixaKey,
          'message': S.of(context).average_weight_box_explanation,
          'shape': 'RRect',
          'align': 'ContentAlign.bottom',
        },
        'pesoTotal': {
          'key': _pesoTotalKey,
          'message': S.of(context).total_weight_explanation,
          'shape': 'RRect',
          'align': 'ContentAlign.bottom',
        },
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Identificação
              Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).identification,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Data da Coleta
              TextFormField(
                key: _dataColetaKey,
                controller: _dataColetaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).collection_date,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _currentRegistroColeta.dataColeta,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dataColetaController.text = FormatacaoUtil.formatDate(pickedDate);
                      _currentRegistroColeta = _currentRegistroColeta.copyWith(dataColeta: pickedDate);
                    });
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).select_collection_date;
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Seção de Quantidade e Peso
              Row(
                children: [
                  Icon(Icons.scale, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).quantity_and_weight,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Quantidade de Caixas
              TextFormField(
                key: _quantidadeCaixaKey,
                controller: _quantidadeCaixaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).quantity_boxes,
                  suffixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).enter_number_of_boxes;
                  }
                  return null;
                },
                onSaved: (value) {
                  final quantidadeCaixa = _quantidadeCaixaController.numberValue;
                  _currentRegistroColeta = _currentRegistroColeta.copyWith(
                      quantidadeCaixa: quantidadeCaixa.toDouble()
                  );
                },
              ),
              SizedBox(height: 16),

              // Peso Médio por Caixa
              TextFormField(
                key: _pesoMedioCaixaKey,
                controller: _pesoMedioCaixaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  '${S.of(context).average_weight_box} (kg)',
                  suffixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).enter_average_weight_per_box;
                  }
                  return null;
                },
                onSaved: (value) {
                  final pesoMedioCaixa = _pesoMedioCaixaController.numberValue;
                  _currentRegistroColeta = _currentRegistroColeta.copyWith(
                      pesoMedioCaixa: pesoMedioCaixa
                  );
                },
              ),
              SizedBox(height: 16),

              // Peso Total
              TextFormField(
                key: _pesoTotalKey,
                controller: _pesoTotalController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  '${S.of(context).total_weight} (kg)',
                  suffixIcon: Icon(Icons.scale),
                ),
                readOnly: true,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantidadeCaixaController.removeListener(_updatePesoTotal);
    _pesoMedioCaixaController.removeListener(_updatePesoTotal);
    super.dispose();
  }
}