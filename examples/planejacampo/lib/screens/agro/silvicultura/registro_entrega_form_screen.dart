import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/models/registro_entrega.dart';
import 'package:planejacampo/models/registro_coleta.dart';
import 'package:planejacampo/services/registro_entrega_service.dart';
import 'package:planejacampo/services/registro_coleta_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class RegistroEntregaFormScreen extends StatefulWidget {
  final RegistroEntrega? registroEntrega;

  const RegistroEntregaFormScreen({Key? key, this.registroEntrega}) : super(key: key);

  @override
  _RegistroEntregaFormScreenState createState() => _RegistroEntregaFormScreenState();
}

class _RegistroEntregaFormScreenState extends State<RegistroEntregaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late RegistroEntrega _currentRegistroEntrega;
  late TextEditingController _dataEntregaController;
  late MoneyMaskedTextController _quantidadeCaixasController;
  late MoneyMaskedTextController _pesoTotalEntregaController;
  late MoneyMaskedTextController _pesoProdutorController;
  late MoneyMaskedTextController _valorNegociadoPorKgController;
  late TextEditingController _sangradorController;
  late MoneyMaskedTextController _pesoSangradorController;
  late TextEditingController _compradorController;
  late TextEditingController _dataPrevistaRecebimentoController;
  late MoneyMaskedTextController _quantidadeJaRecebidaController;
  late MoneyMaskedTextController _valorProdutorController;
  late MoneyMaskedTextController _valorTotalController;

  final RegistroEntregaService _registroEntregaService = RegistroEntregaService();
  final String moduleName = 'registrosEntregas';

  double? _razaoPesoProdutor;
  final RegistroColetaService _registroColetaService = RegistroColetaService();

  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  Object _returnObject = false;

  String? _sangradorId;
  String? _compradorId;

  int? _diasEntreDatas;

  final GlobalKey _dataEntregaKey = GlobalKey();
  final GlobalKey _quantidadeCaixasKey = GlobalKey();
  final GlobalKey _pesoTotalEntregaKey = GlobalKey();
  final GlobalKey _pesoProdutorKey = GlobalKey();
  final GlobalKey _valorNegociadoPorKgKey = GlobalKey();
  final GlobalKey _pesoSangradorKey = GlobalKey();

  @override
  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit(moduleName);
    _canDelete = appStateManager.canDelete(moduleName);

    _showTutorial = appStateManager.showTutorial('registroEntregaFormScreen');
    appStateManager.setShowTutorial('registroEntregaFormScreen', false);

    // Inicializa os controllers com valores padrão
    _dataEntregaController = TextEditingController();
    _quantidadeCaixasController = FormatacaoUtil.getMaskedTextController(0.0);
    _pesoTotalEntregaController = FormatacaoUtil.getMaskedTextController(0.0);
    _pesoProdutorController = FormatacaoUtil.getMaskedTextController(0.0);
    _valorNegociadoPorKgController = FormatacaoUtil.getMaskedTextController(0.0);
    _sangradorController = TextEditingController();
    _pesoSangradorController = FormatacaoUtil.getMaskedTextController(0.0);
    _compradorController = TextEditingController();
    _dataPrevistaRecebimentoController = TextEditingController();
    _quantidadeJaRecebidaController = FormatacaoUtil.getMaskedTextController(0.0);
    _valorProdutorController = FormatacaoUtil.getMaskedTextController(0.0);
    _valorTotalController = FormatacaoUtil.getMaskedTextController(0.0);

    _initializeRegistroEntrega(appStateManager);
  }

  void _initializeRegistroEntrega(AppStateManager appStateManager) async {
    if (widget.registroEntrega == null) {
      // Novo registro
      RegistroEntrega? ultimoRegistro = (await _registroEntregaService.getByAttributes(
        {},
        orderBy: [
          {'field': 'dataEntrega', 'direction': 'desc'}
        ],
        limit: 1,
      ))
          .firstOrNull;

      DateTime dataEntrega = DateTime.now();
      RegistroColeta? ultimaColeta = await _buscarColetaAnterior(dataEntrega);

      _currentRegistroEntrega = RegistroEntrega(
        id: DateTime.now().toString(),
        produtorId: appStateManager.activeProdutorId ?? '',
        propriedadeId: appStateManager.activePropriedadeId ?? '',
        atividadeId: appStateManager.activeAtividadeRural?.id ?? '',
        dataEntrega: dataEntrega,
        quantidadeCaixas: ultimaColeta?.quantidadeCaixa ?? 0.0,
        pesoTotalEntrega: ultimaColeta?.pesoTotal ?? 0.0,
        pesoProdutor: 0.0,
        valorNegociadoPorKg: 0.0,
      );

      if (ultimoRegistro != null) {
        _diasEntreDatas = ultimoRegistro.dataPrevistaRecebimento?.difference(ultimoRegistro.dataEntrega).inDays;
        _razaoPesoProdutor = ultimoRegistro.pesoProdutor / ultimoRegistro.pesoTotalEntrega;
        _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
          sangradorId: ultimoRegistro.sangradorId,
          compradorId: ultimoRegistro.compradorId,
          dataPrevistaRecebimento: _calcularDataPrevistaRecebimento(_currentRegistroEntrega.dataEntrega),
          pesoProdutor: _calcularPesoProdutor(_currentRegistroEntrega.pesoTotalEntrega),
        );
      }
    } else {
      // Edição de registro existente
      _currentRegistroEntrega = widget.registroEntrega!;
    }

    _initializeControllers();
    _loadSangradorName();
    _loadCompradorName();
    _updatePesoSangrador();
  }

  Future<RegistroColeta?> _buscarColetaAnterior(DateTime dataEntrega) async {
    return (await _registroColetaService.getByAttributesWithOperators({
      'dataColeta': [
        {'operator': '<=', 'value': Timestamp.fromDate(dataEntrega)}
      ]
    }, orderBy: [
      {'field': 'dataColeta', 'direction': 'desc'}
    ], limit: 1))
        .firstOrNull;
  }

  void _atualizarDadosColeta(DateTime novaData) async {
    RegistroColeta? coletaAnterior = await _buscarColetaAnterior(novaData);
    if (coletaAnterior != null) {
      setState(() {
        _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
          quantidadeCaixas: coletaAnterior.quantidadeCaixa ?? 0.0,
          pesoTotalEntrega: coletaAnterior.pesoTotal ?? 0.0,
        );
        _quantidadeCaixasController.updateValue(_currentRegistroEntrega.quantidadeCaixas);
        _pesoTotalEntregaController.updateValue(_currentRegistroEntrega.pesoTotalEntrega);
        _pesoProdutorController.updateValue(_calcularPesoProdutor(_currentRegistroEntrega.pesoTotalEntrega));
      });
      _updatePesoSangrador();
    }
  }

  double _calcularPesoProdutor(double pesoTotal) {
    return _razaoPesoProdutor != null ? pesoTotal * _razaoPesoProdutor! : 0.0;
  }

  void _updatePesoSangrador() {
    double pesoTotalEntrega = _pesoTotalEntregaController.numberValue;
    double pesoProdutor = _pesoProdutorController.numberValue;
    double pesoSangrador = pesoTotalEntrega - pesoProdutor;

    if (pesoSangrador < 0) pesoSangrador = 0;

    setState(() {
      _pesoSangradorController.updateValue(pesoSangrador);
      _currentRegistroEntrega = _currentRegistroEntrega.copyWith(pesoSangrador: pesoSangrador.toString(), pesoTotalEntrega: pesoTotalEntrega, pesoProdutor: pesoProdutor);
    });
  }

  void _initializeControllers() {
    _dataEntregaController.text = DateFormat.yMd().format(_currentRegistroEntrega.dataEntrega);
    _quantidadeCaixasController.updateValue(_currentRegistroEntrega.quantidadeCaixas);
    _pesoTotalEntregaController.updateValue(_currentRegistroEntrega.pesoTotalEntrega);
    _pesoProdutorController.updateValue(_currentRegistroEntrega.pesoProdutor);
    _valorNegociadoPorKgController.updateValue(_currentRegistroEntrega.valorNegociadoPorKg ?? 0.0);
    _pesoSangradorController.updateValue(_currentRegistroEntrega.pesoSangrador != null ? double.parse(_currentRegistroEntrega.pesoSangrador!) : 0.0);
    _dataPrevistaRecebimentoController.text = _currentRegistroEntrega.dataPrevistaRecebimento != null ? DateFormat.yMd().format(_currentRegistroEntrega.dataPrevistaRecebimento!) : '';
    _quantidadeJaRecebidaController.updateValue(_currentRegistroEntrega.quantidadeJaRecebida ?? 0.0);

    _valorProdutorController.updateValue(_currentRegistroEntrega.valorProdutor ?? 0.0);
    _valorTotalController.updateValue(_currentRegistroEntrega.valorTotal ?? 0.0);

    _pesoTotalEntregaController.addListener(_updateValores);
    _pesoProdutorController.addListener(_updateValores);
    _valorNegociadoPorKgController.addListener(_updateValores);

    _pesoTotalEntregaController.addListener(() {
      double novoPesoTotal = _pesoTotalEntregaController.numberValue;
      double novoPesoProdutor = _calcularPesoProdutor(novoPesoTotal);
      _pesoProdutorController.updateValue(novoPesoProdutor);
      _updatePesoSangrador();
    });
    _pesoProdutorController.addListener(_updatePesoSangrador);
  }

  DateTime? _calcularDataPrevistaRecebimento(DateTime dataEntrega) {
    if (_diasEntreDatas != null) {
      return dataEntrega.add(Duration(days: _diasEntreDatas!));
    }
    return null;
  }

  void _updateValores() {
    double pesoTotalEntrega = _pesoTotalEntregaController.numberValue;
    double pesoProdutor = _pesoProdutorController.numberValue;
    double valorNegociadoPorKg = _valorNegociadoPorKgController.numberValue;

    double valorProdutor = pesoProdutor * valorNegociadoPorKg;
    double valorTotal = pesoTotalEntrega * valorNegociadoPorKg;

    setState(() {
      _valorProdutorController.updateValue(valorProdutor);
      _valorTotalController.updateValue(valorTotal);
      _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
        valorProdutor: valorProdutor,
        valorTotal: valorTotal,
      );
    });

    _updatePesoSangrador();
  }

  void _loadSangradorName() async {
    if (_currentRegistroEntrega.sangradorId != null && _currentRegistroEntrega.sangradorId!.isNotEmpty) {
      final sangrador = await PessoaService().getById(_currentRegistroEntrega.sangradorId!);
      if (sangrador != null) {
        setState(() {
          _sangradorController.text = sangrador.nome;
          _sangradorId = sangrador.id;
        });
      }
    }
  }

  void _loadCompradorName() async {
    if (_currentRegistroEntrega.compradorId != null && _currentRegistroEntrega.compradorId!.isNotEmpty) {
      final comprador = await PessoaService().getById(_currentRegistroEntrega.compradorId!);
      if (comprador != null) {
        setState(() {
          _compradorController.text = comprador.nome;
          _compradorId = comprador.id;
        });
      }
    }
  }

  void _selecionarSangrador() async {
    final parceiro = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(isSelectMode: true, vinculos: ['Parceiro']),
        //builder: (context) => PessoasListScreen(isSelectMode: true),
      ),
    );
    if (parceiro != null && parceiro is Pessoa) {
      setState(() {
        _sangradorId = parceiro.id;
        _sangradorController.text = parceiro.nome;
      });
    }
  }

  void _selecionarComprador() async {
    final parceiro = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(isSelectMode: true, vinculos: ['Fornecedor']),
      ),
    );
    if (parceiro != null && parceiro is Pessoa) {
      setState(() {
        _compradorId = parceiro.id;
        _compradorController.text = parceiro.nome;
      });
    }
  }

  Future<void> _saveRegistroEntrega() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();

        _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
          sangradorId: _sangradorId,
          compradorId: _compradorId,
        );

        if (widget.registroEntrega == null) {
          await _registroEntregaService.add(_currentRegistroEntrega);
        } else {
          await _registroEntregaService.update(_currentRegistroEntrega.id, _currentRegistroEntrega);
        }
        _returnObject = widget.registroEntrega == null ? true : _currentRegistroEntrega;
        Navigator.of(context).pop(_returnObject);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).delivery_record)),
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
      title: widget.registroEntrega == null ? S.of(context).add_delivery_record : S.of(context).edit_delivery_record,
      formKey: _formKey,
      onSave: _saveRegistroEntrega,
      moduleName: moduleName,
      isNewItem: widget.registroEntrega == null,
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      returnObject: _returnObject,
      onWillPop: () async {
        Navigator.of(context).pop(_currentRegistroEntrega);
        return false;
      },
      customTutorialSteps: {
        'dataEntrega': {
          'key': _dataEntregaKey,
          'message': S.of(context).select_delivery_date,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        'pesoSangrador': {
          'key': _pesoSangradorKey,
          'message': S.of(context).bleeder_weight,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
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

              // Data de Entrega
              TextFormField(
                key: _dataEntregaKey,
                controller: _dataEntregaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).delivery_date,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _currentRegistroEntrega.dataEntrega,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dataEntregaController.text = FormatacaoUtil.formatDate(pickedDate);
                      _currentRegistroEntrega = _currentRegistroEntrega.copyWith(dataEntrega: pickedDate);
                    });
                    _atualizarDadosColeta(pickedDate);
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).select_delivery_date;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Quantidade de Caixas
              TextFormField(
                key: _quantidadeCaixasKey,
                controller: _quantidadeCaixasController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).quantity_boxes,
                  suffixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                readOnly: true,
                enabled: false,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 24),

              // Seção de Pesos
              Row(
                children: [
                  Icon(Icons.scale, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).weights,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Campos de peso
              TextFormField(
                key: _pesoTotalEntregaKey,
                controller: _pesoTotalEntregaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  '${S.of(context).total_weight_delivery} (kg)',
                  suffixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).enter_total_delivery_weight;
                  }
                  return null;
                },
                onSaved: (value) {
                  final pesoTotalEntrega = _pesoTotalEntregaController.numberValue;
                  _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
                      pesoTotalEntrega: pesoTotalEntrega
                  );
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                key: _pesoProdutorKey,
                controller: _pesoProdutorController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  '${S.of(context).producer_weight} (kg)',
                  suffixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  final pesoProdutor = _pesoProdutorController.numberValue;
                  _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
                      pesoProdutor: pesoProdutor
                  );
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                key: _pesoSangradorKey,
                controller: _pesoSangradorController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  '${S.of(context).bleeder_weight} (kg)',
                  suffixIcon: Icon(Icons.monitor_weight),
                ),
                readOnly: true,
                enabled: false,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 24),

              // Seção de Valores (em Card - dependente)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: theme.colorScheme.primary),
                          SizedBox(width: 8),
                          Text(
                            S.of(context).values,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        key: _valorNegociadoPorKgKey,
                        controller: _valorNegociadoPorKgController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          '${S.of(context).currency_symbol} ${S.of(context).negotiated_value_per_kg}',
                          suffixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          final valorNegociadoPorKg = _valorNegociadoPorKgController.numberValue;
                          _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
                              valorNegociadoPorKg: valorNegociadoPorKg
                          );
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _valorProdutorController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          '${S.of(context).currency_symbol} ${S.of(context).producer_value}',
                          suffixIcon: Icon(Icons.attach_money),
                        ),
                        readOnly: true,
                        enabled: false,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _valorTotalController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          '${S.of(context).currency_symbol} ${S.of(context).total_value}',
                          suffixIcon: Icon(Icons.attach_money),
                        ),
                        readOnly: true,
                        enabled: false,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Seção de Pessoas (em Card - dependente)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: theme.colorScheme.primary),
                          SizedBox(width: 8),
                          Text(
                            S.of(context).people,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _sangradorController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          S.of(context).bleeder,
                          suffixIcon: Icon(Icons.search),
                        ),
                        readOnly: true,
                        onTap: _selecionarSangrador,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _compradorController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          S.of(context).buyer,
                          suffixIcon: Icon(Icons.search),
                        ),
                        readOnly: true,
                        onTap: _selecionarComprador,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Seção Datas e Recebimentos (em Card - dependente)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, color: theme.colorScheme.primary),
                          SizedBox(width: 8),
                          Text(
                            S.of(context).dates_and_received,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _dataPrevistaRecebimentoController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          S.of(context).expected_receipt_date,
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _currentRegistroEntrega.dataPrevistaRecebimento ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dataPrevistaRecebimentoController.text = FormatacaoUtil.formatDate(pickedDate);
                              _currentRegistroEntrega = _currentRegistroEntrega.copyWith(dataPrevistaRecebimento: pickedDate);
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _quantidadeJaRecebidaController,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          S.of(context).quantity_already_received,
                          suffixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          final quantidadeJaRecebida = _quantidadeJaRecebidaController.numberValue;
                          _currentRegistroEntrega = _currentRegistroEntrega.copyWith(
                              quantidadeJaRecebida: quantidadeJaRecebida
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pesoTotalEntregaController.removeListener(_updatePesoSangrador);
    _pesoProdutorController.removeListener(_updatePesoSangrador);
    _dataEntregaController.dispose();
    _quantidadeCaixasController.dispose();
    _pesoTotalEntregaController.dispose();
    _pesoProdutorController.dispose();
    _valorNegociadoPorKgController.dispose();
    _sangradorController.dispose();
    _pesoSangradorController.dispose();
    _compradorController.dispose();
    _dataPrevistaRecebimentoController.dispose();
    _quantidadeJaRecebidaController.dispose();
    super.dispose();
  }
}
