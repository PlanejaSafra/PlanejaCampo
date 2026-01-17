import 'package:flutter/material.dart';
import 'package:planejacampo/models/registro_chuva.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/services/registro_chuva_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:intl/intl.dart';

class RegistroChuvaFormScreen extends StatefulWidget {
  final RegistroChuva? registroChuva;

  const RegistroChuvaFormScreen({Key? key, this.registroChuva}) : super(key: key);

  @override
  _RegistroChuvaFormScreenState createState() => _RegistroChuvaFormScreenState();
}

class _RegistroChuvaFormScreenState extends State<RegistroChuvaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _detailFormKey = GlobalKey();
  late RegistroChuva _currentRegistroChuva;
  late TextEditingController _dataController;
  late TextEditingController _quantidadeController;
  late TextEditingController _propriedadeController;
  late String _selectedPropriedadeId;
  late RegistroChuvaService _registroChuvaService;
  bool _showTutorial = false;
  Object _returnObject = '';

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final produtorId = appStateManager.activeProdutorId!;
    final propriedadeId = appStateManager.activePropriedadeId;

    _registroChuvaService = RegistroChuvaService();

    _currentRegistroChuva = widget.registroChuva ??
        RegistroChuva(
          id: '',
          produtorId: produtorId,
          propriedadeId: propriedadeId ?? '',
          data: DateTime.now(),
          quantidade: 0.0,
        );

    _dataController = TextEditingController(
      text: FormatacaoUtil.formatDate(_currentRegistroChuva.data),
    );
    _quantidadeController = FormatacaoUtil.getMaskedTextController(
      _currentRegistroChuva.quantidade,
    );
    _propriedadeController = TextEditingController();

    _selectedPropriedadeId = _currentRegistroChuva.propriedadeId;

    _loadPropriedadeName();

    _showTutorial = appStateManager.showTutorial('registroChuvaFormScreen');
    appStateManager.setShowTutorial('registroChuvaFormScreen', false);
  }

  void _loadPropriedadeName() async {
    if (_selectedPropriedadeId.isNotEmpty) {
      final propriedade = await PropriedadeService().getById(_selectedPropriedadeId);
      if (propriedade != null) {
        setState(() {
          _propriedadeController.text = propriedade.nome;
        });
      }
    }
  }

  void _selectPropriedade() async {
    final selectedPropriedade = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropriedadesListScreen(isSelectMode: true),
      ),
    );

    if (selectedPropriedade != null) {
      setState(() {
        _selectedPropriedadeId = selectedPropriedade.id;
        _propriedadeController.text = selectedPropriedade.nome;
      });
    }
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentRegistroChuva.data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _currentRegistroChuva = _currentRegistroChuva.copyWith(data: pickedDate);
        _dataController.text = FormatacaoUtil.formatDate(pickedDate);
      });
    }
  }

  Future<void> _saveRegistroChuva() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final quantidade = NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
          .parse(_quantidadeController.text)
          .toDouble();

      _currentRegistroChuva = _currentRegistroChuva.copyWith(
        propriedadeId: _selectedPropriedadeId,
        quantidade: quantidade,
      );

      try {
        if (_currentRegistroChuva.id.isEmpty) {
          await _registroChuvaService.add(_currentRegistroChuva);
        } else {
          await _registroChuvaService.update(_currentRegistroChuva.id, _currentRegistroChuva);
        }
        if (widget.registroChuva == null) {
          _returnObject = true;
        } else {
          _returnObject = _currentRegistroChuva;
        }
        Navigator.of(context).pop(_returnObject);
        
        //if (!mounted) return;
        
        //Navigator.of(context).pop(_currentRegistroChuva); // Retorna o objeto salvo e fecha a tela
      } catch (e) {
        print('Erro ao salvar registro de chuva: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar registro de chuva')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormTemplate(
      title: widget.registroChuva == null
          ? S.of(context).add_rain_record
          : S.of(context).edit_rain_record,
      formKey: _formKey,
      onSave: _saveRegistroChuva,
      moduleName: 'registrosChuvas',
      nomeTutorial: S.of(context).rain_record,
      showTutorial: _showTutorial,
      customTutorialSteps: {
        // Adicione passos do tutorial personalizados, se necessário
      },
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            key: _detailFormKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Identificação
              Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
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

              // Propriedade
              TextFormField(
                controller: _propriedadeController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).agricultural_property,
                  suffixIcon: Icon(Icons.business),
                ),
                readOnly: true,
                onTap: _selectPropriedade,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).select_property;
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Seção de Data e Quantidade
              Row(
                children: [
                  Icon(Icons.water_drop, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).details,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Data
              TextFormField(
                controller: _dataController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).date,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).select_date;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Quantidade de Chuva
              TextFormField(
                controller: _quantidadeController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).rain_quantity_mm,
                  suffixIcon: Icon(Icons.opacity),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).enter_rain_quantity;
                  }
                  try {
                    NumberFormat.decimalPattern(
                        Localizations.localeOf(context).toString()
                    ).parse(value);
                  } catch (e) {
                    return S.of(context).invalid_rain_quantity;
                  }
                  return null;
                },
                onSaved: (value) {
                  final quantidade = NumberFormat.decimalPattern(
                      Localizations.localeOf(context).toString()
                  ).parse(value!).toDouble();
                  _currentRegistroChuva = _currentRegistroChuva.copyWith(
                    quantidade: quantidade,
                  );
                },
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
