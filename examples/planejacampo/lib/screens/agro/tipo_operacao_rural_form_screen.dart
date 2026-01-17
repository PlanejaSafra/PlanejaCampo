import 'package:flutter/material.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/utils/estados_options.dart'; // Importando EstadosOptions

class TipoOperacaoRuralFormScreen extends StatefulWidget {
  final TipoOperacaoRural? tipoOperacaoRural;

  const TipoOperacaoRuralFormScreen({Key? key, this.tipoOperacaoRural}) : super(key: key);

  @override
  _TipoOperacaoRuralFormScreenState createState() => _TipoOperacaoRuralFormScreenState();
}

class _TipoOperacaoRuralFormScreenState extends State<TipoOperacaoRuralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TipoOperacaoRural _currentTipoOperacaoRural;
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  Object _returnObject = false;

  String? _selectedCountrySigla;

  final GlobalKey _tipoOperacaoRuralFormKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('tiposOperacoesRurais');
    _canDelete = appStateManager.canDelete('tiposOperacoesRurais');
    _showTutorial = appStateManager.showTutorial('tipoOperacaoRuralFormScreen');
    appStateManager.setShowTutorial('tipoOperacaoRuralFormScreen', false);

    _currentTipoOperacaoRural = widget.tipoOperacaoRural ??
        TipoOperacaoRural(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId ?? '',
          siglaPais: appStateManager.appLocale.countryCode ?? '',
          nome: '',
          descricao: '',
        );

    _nomeController = TextEditingController(text: _currentTipoOperacaoRural.nome);
    _descricaoController = TextEditingController(text: _currentTipoOperacaoRural.descricao);
    _selectedCountrySigla = _currentTipoOperacaoRural.siglaPais;
  }

  Future<void> _saveTipoOperacaoRural() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          _currentTipoOperacaoRural = _currentTipoOperacaoRural.copyWith(
            nome: _nomeController.text,
            descricao: _descricaoController.text,
            siglaPais: _selectedCountrySigla ?? '',
          );

          if (widget.tipoOperacaoRural == null) {
            final newTipoOperacaoId = await _tipoOperacaoRuralService.add(_currentTipoOperacaoRural, returnId: true);
            _currentTipoOperacaoRural = _currentTipoOperacaoRural.copyWith(id: newTipoOperacaoId);
          } else {
            await _tipoOperacaoRuralService.update(_currentTipoOperacaoRural.id, _currentTipoOperacaoRural);
          }
          _returnObject = widget.tipoOperacaoRural == null ? true : _currentTipoOperacaoRural;
          if (!mounted) return;
          Navigator.of(context).pop(_returnObject);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_tipo_operacao_rural(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).tipo_operacao_rural)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obter a lista de países localizados
    final Map<String, String> paisesMap = EstadosOptions.getLocalizedPaises(context);

    // Mapear a lista de países para DropdownMenuItems
    final List<DropdownMenuItem<String>> paisesDropdownItems = EstadosOptions.paises.map((pais) {
      String nomeLocalizado = paisesMap[pais['nome']!] ?? pais['nome']!;
      return DropdownMenuItem<String>(
        value: pais['sigla']!,
        child: Text(nomeLocalizado),
      );
    }).toList();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentTipoOperacaoRural : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.tipoOperacaoRural == null
            ? S.of(context).add_tipo_operacao
            : S.of(context).edit_tipo_operacao,
        formKey: _formKey,
        onSave: _saveTipoOperacaoRural,
        moduleName: 'tiposOperacoesRurais',
        isNewItem: widget.tipoOperacaoRural == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        customTutorialSteps: {
          'customTipoOperacaoRuralForm': {
            'key': _tipoOperacaoRuralFormKey,
            'message': S.of(context).edit_tipo_operacao_info,
            'shape': 'RRect',
            'align': 'ContentAlign.bottom',
          },
        },
        returnObject: _returnObject,
        onWillPop: () async {
          return true;
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              key: _tipoOperacaoRuralFormKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho da seção
                Row(
                  children: [
                    Icon(Icons.assignment, color: theme.colorScheme.primary),
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

                // Campos de Identificação
                TextFormField(
                  controller: _nomeController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).name,
                    suffixIcon: Icon(Icons.edit),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return S.of(context).enter_name;
                    }
                    return null;
                  },
                  onChanged: (value) => _hasChanges = true,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                ObjectTemplate.getDropdownButtonFormField(
                  context: context,
                  labelText: S.of(context).country,
                  value: _selectedCountrySigla ?? '',
                  dropdownItems: paisesDropdownItems,  // Lista de DropdownMenuItem já preparada
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCountrySigla = newValue;
                      _hasChanges = true;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).select_country;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Cabeçalho da seção de descrição
                Row(
                  children: [
                    Icon(Icons.description, color: theme.colorScheme.primary),
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

                // Campo de descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).description,
                    suffixIcon: Icon(Icons.text_fields),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return S.of(context).enter_description;
                    }
                    return null;
                  },
                  onChanged: (value) => _hasChanges = true,
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}