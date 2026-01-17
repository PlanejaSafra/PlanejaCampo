// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `PlanejaCampo`
  String get app_title {
    return Intl.message('PlanejaCampo', name: 'app_title', desc: '', args: []);
  }

  /// `Modo Escuro`
  String get dark_mode {
    return Intl.message('Modo Escuro', name: 'dark_mode', desc: '', args: []);
  }

  /// `Idioma`
  String get language {
    return Intl.message('Idioma', name: 'language', desc: '', args: []);
  }

  /// `Escolher Idioma`
  String get choose_language {
    return Intl.message(
      'Escolher Idioma',
      name: 'choose_language',
      desc: '',
      args: [],
    );
  }

  /// `Acesso Básico`
  String get acesso_basico {
    return Intl.message(
      'Acesso Básico',
      name: 'acesso_basico',
      desc: '',
      args: [],
    );
  }

  /// `Acesso Completo para Pequeno Produtor`
  String get acesso_completo_pequeno_produtor {
    return Intl.message(
      'Acesso Completo para Pequeno Produtor',
      name: 'acesso_completo_pequeno_produtor',
      desc: '',
      args: [],
    );
  }

  /// `Acesso Completo para Médio Produtor`
  String get acesso_completo_medio_produtor {
    return Intl.message(
      'Acesso Completo para Médio Produtor',
      name: 'acesso_completo_medio_produtor',
      desc: '',
      args: [],
    );
  }

  /// `Acesso Completo para Grande Produtor`
  String get acesso_completo_grande_produtor {
    return Intl.message(
      'Acesso Completo para Grande Produtor',
      name: 'acesso_completo_grande_produtor',
      desc: '',
      args: [],
    );
  }

  /// `Licença Permanente`
  String get licenca_permanente {
    return Intl.message(
      'Licença Permanente',
      name: 'licenca_permanente',
      desc: '',
      args: [],
    );
  }

  /// `Não é permitido adicionar mais produtores. O limite da sua licença foi atingido.`
  String get no_more_producers_allowed {
    return Intl.message(
      'Não é permitido adicionar mais produtores. O limite da sua licença foi atingido.',
      name: 'no_more_producers_allowed',
      desc: '',
      args: [],
    );
  }

  /// `Não é permitido adicionar mais propriedades agrícolas. O limite da sua licença foi atingido.`
  String get no_more_properties_allowed {
    return Intl.message(
      'Não é permitido adicionar mais propriedades agrícolas. O limite da sua licença foi atingido.',
      name: 'no_more_properties_allowed',
      desc: '',
      args: [],
    );
  }

  /// `País`
  String get country {
    return Intl.message('País', name: 'country', desc: '', args: []);
  }

  /// `Brasil`
  String get brazil {
    return Intl.message('Brasil', name: 'brazil', desc: '', args: []);
  }

  /// `Estados Unidos`
  String get united_states {
    return Intl.message(
      'Estados Unidos',
      name: 'united_states',
      desc: '',
      args: [],
    );
  }

  /// `Acre`
  String get acre {
    return Intl.message('Acre', name: 'acre', desc: '', args: []);
  }

  /// `Alagoas`
  String get alagoas {
    return Intl.message('Alagoas', name: 'alagoas', desc: '', args: []);
  }

  /// `Amapá`
  String get amapa {
    return Intl.message('Amapá', name: 'amapa', desc: '', args: []);
  }

  /// `Amazonas`
  String get amazonas {
    return Intl.message('Amazonas', name: 'amazonas', desc: '', args: []);
  }

  /// `Bahia`
  String get bahia {
    return Intl.message('Bahia', name: 'bahia', desc: '', args: []);
  }

  /// `Ceará`
  String get ceara {
    return Intl.message('Ceará', name: 'ceara', desc: '', args: []);
  }

  /// `Distrito Federal`
  String get distrito_federal {
    return Intl.message(
      'Distrito Federal',
      name: 'distrito_federal',
      desc: '',
      args: [],
    );
  }

  /// `Espírito Santo`
  String get espirito_santo {
    return Intl.message(
      'Espírito Santo',
      name: 'espirito_santo',
      desc: '',
      args: [],
    );
  }

  /// `Goiás`
  String get goias {
    return Intl.message('Goiás', name: 'goias', desc: '', args: []);
  }

  /// `Maranhão`
  String get maranhao {
    return Intl.message('Maranhão', name: 'maranhao', desc: '', args: []);
  }

  /// `Mato Grosso`
  String get mato_grosso {
    return Intl.message('Mato Grosso', name: 'mato_grosso', desc: '', args: []);
  }

  /// `Mato Grosso do Sul`
  String get mato_grosso_do_sul {
    return Intl.message(
      'Mato Grosso do Sul',
      name: 'mato_grosso_do_sul',
      desc: '',
      args: [],
    );
  }

  /// `Minas Gerais`
  String get minas_gerais {
    return Intl.message(
      'Minas Gerais',
      name: 'minas_gerais',
      desc: '',
      args: [],
    );
  }

  /// `Pará`
  String get para {
    return Intl.message('Pará', name: 'para', desc: '', args: []);
  }

  /// `Paraíba`
  String get paraiba {
    return Intl.message('Paraíba', name: 'paraiba', desc: '', args: []);
  }

  /// `Paraná`
  String get parana {
    return Intl.message('Paraná', name: 'parana', desc: '', args: []);
  }

  /// `Pernambuco`
  String get pernambuco {
    return Intl.message('Pernambuco', name: 'pernambuco', desc: '', args: []);
  }

  /// `Piauí`
  String get piaui {
    return Intl.message('Piauí', name: 'piaui', desc: '', args: []);
  }

  /// `Rio de Janeiro`
  String get rio_de_janeiro {
    return Intl.message(
      'Rio de Janeiro',
      name: 'rio_de_janeiro',
      desc: '',
      args: [],
    );
  }

  /// `Rio Grande do Norte`
  String get rio_grande_do_norte {
    return Intl.message(
      'Rio Grande do Norte',
      name: 'rio_grande_do_norte',
      desc: '',
      args: [],
    );
  }

  /// `Rio Grande do Sul`
  String get rio_grande_do_sul {
    return Intl.message(
      'Rio Grande do Sul',
      name: 'rio_grande_do_sul',
      desc: '',
      args: [],
    );
  }

  /// `Rondônia`
  String get rondonia {
    return Intl.message('Rondônia', name: 'rondonia', desc: '', args: []);
  }

  /// `Roraima`
  String get roraima {
    return Intl.message('Roraima', name: 'roraima', desc: '', args: []);
  }

  /// `Santa Catarina`
  String get santa_catarina {
    return Intl.message(
      'Santa Catarina',
      name: 'santa_catarina',
      desc: '',
      args: [],
    );
  }

  /// `São Paulo`
  String get sao_paulo {
    return Intl.message('São Paulo', name: 'sao_paulo', desc: '', args: []);
  }

  /// `Sergipe`
  String get sergipe {
    return Intl.message('Sergipe', name: 'sergipe', desc: '', args: []);
  }

  /// `Tocantins`
  String get tocantins {
    return Intl.message('Tocantins', name: 'tocantins', desc: '', args: []);
  }

  /// `Alabama`
  String get alabama {
    return Intl.message('Alabama', name: 'alabama', desc: '', args: []);
  }

  /// `Alasca`
  String get alaska {
    return Intl.message('Alasca', name: 'alaska', desc: '', args: []);
  }

  /// `Arizona`
  String get arizona {
    return Intl.message('Arizona', name: 'arizona', desc: '', args: []);
  }

  /// `Arkansas`
  String get arkansas {
    return Intl.message('Arkansas', name: 'arkansas', desc: '', args: []);
  }

  /// `Califórnia`
  String get california {
    return Intl.message('Califórnia', name: 'california', desc: '', args: []);
  }

  /// `Colorado`
  String get colorado {
    return Intl.message('Colorado', name: 'colorado', desc: '', args: []);
  }

  /// `Connecticut`
  String get connecticut {
    return Intl.message('Connecticut', name: 'connecticut', desc: '', args: []);
  }

  /// `Delaware`
  String get delaware {
    return Intl.message('Delaware', name: 'delaware', desc: '', args: []);
  }

  /// `Flórida`
  String get florida {
    return Intl.message('Flórida', name: 'florida', desc: '', args: []);
  }

  /// `Geórgia`
  String get georgia {
    return Intl.message('Geórgia', name: 'georgia', desc: '', args: []);
  }

  /// `Havaí`
  String get hawaii {
    return Intl.message('Havaí', name: 'hawaii', desc: '', args: []);
  }

  /// `Idaho`
  String get idaho {
    return Intl.message('Idaho', name: 'idaho', desc: '', args: []);
  }

  /// `Illinois`
  String get illinois {
    return Intl.message('Illinois', name: 'illinois', desc: '', args: []);
  }

  /// `Indiana`
  String get indiana {
    return Intl.message('Indiana', name: 'indiana', desc: '', args: []);
  }

  /// `Iowa`
  String get iowa {
    return Intl.message('Iowa', name: 'iowa', desc: '', args: []);
  }

  /// `Kansas`
  String get kansas {
    return Intl.message('Kansas', name: 'kansas', desc: '', args: []);
  }

  /// `Kentucky`
  String get kentucky {
    return Intl.message('Kentucky', name: 'kentucky', desc: '', args: []);
  }

  /// `Louisiana`
  String get louisiana {
    return Intl.message('Louisiana', name: 'louisiana', desc: '', args: []);
  }

  /// `Maine`
  String get maine {
    return Intl.message('Maine', name: 'maine', desc: '', args: []);
  }

  /// `Maryland`
  String get maryland {
    return Intl.message('Maryland', name: 'maryland', desc: '', args: []);
  }

  /// `Massachusetts`
  String get massachusetts {
    return Intl.message(
      'Massachusetts',
      name: 'massachusetts',
      desc: '',
      args: [],
    );
  }

  /// `Michigan`
  String get michigan {
    return Intl.message('Michigan', name: 'michigan', desc: '', args: []);
  }

  /// `Minnesota`
  String get minnesota {
    return Intl.message('Minnesota', name: 'minnesota', desc: '', args: []);
  }

  /// `Mississippi`
  String get mississippi {
    return Intl.message('Mississippi', name: 'mississippi', desc: '', args: []);
  }

  /// `Missouri`
  String get missouri {
    return Intl.message('Missouri', name: 'missouri', desc: '', args: []);
  }

  /// `Montana`
  String get montana {
    return Intl.message('Montana', name: 'montana', desc: '', args: []);
  }

  /// `Nebraska`
  String get nebraska {
    return Intl.message('Nebraska', name: 'nebraska', desc: '', args: []);
  }

  /// `Nevada`
  String get nevada {
    return Intl.message('Nevada', name: 'nevada', desc: '', args: []);
  }

  /// `New Hampshire`
  String get new_hampshire {
    return Intl.message(
      'New Hampshire',
      name: 'new_hampshire',
      desc: '',
      args: [],
    );
  }

  /// `New Jersey`
  String get new_jersey {
    return Intl.message('New Jersey', name: 'new_jersey', desc: '', args: []);
  }

  /// `Novo México`
  String get new_mexico {
    return Intl.message('Novo México', name: 'new_mexico', desc: '', args: []);
  }

  /// `Nova York`
  String get new_york {
    return Intl.message('Nova York', name: 'new_york', desc: '', args: []);
  }

  /// `Carolina do Norte`
  String get north_carolina {
    return Intl.message(
      'Carolina do Norte',
      name: 'north_carolina',
      desc: '',
      args: [],
    );
  }

  /// `Dakota do Norte`
  String get north_dakota {
    return Intl.message(
      'Dakota do Norte',
      name: 'north_dakota',
      desc: '',
      args: [],
    );
  }

  /// `Ohio`
  String get ohio {
    return Intl.message('Ohio', name: 'ohio', desc: '', args: []);
  }

  /// `Oklahoma`
  String get oklahoma {
    return Intl.message('Oklahoma', name: 'oklahoma', desc: '', args: []);
  }

  /// `Oregon`
  String get oregon {
    return Intl.message('Oregon', name: 'oregon', desc: '', args: []);
  }

  /// `Pensilvânia`
  String get pennsylvania {
    return Intl.message(
      'Pensilvânia',
      name: 'pennsylvania',
      desc: '',
      args: [],
    );
  }

  /// `Rhode Island`
  String get rhode_island {
    return Intl.message(
      'Rhode Island',
      name: 'rhode_island',
      desc: '',
      args: [],
    );
  }

  /// `Carolina do Sul`
  String get south_carolina {
    return Intl.message(
      'Carolina do Sul',
      name: 'south_carolina',
      desc: '',
      args: [],
    );
  }

  /// `Dakota do Sul`
  String get south_dakota {
    return Intl.message(
      'Dakota do Sul',
      name: 'south_dakota',
      desc: '',
      args: [],
    );
  }

  /// `Tennessee`
  String get tennessee {
    return Intl.message('Tennessee', name: 'tennessee', desc: '', args: []);
  }

  /// `Texas`
  String get texas {
    return Intl.message('Texas', name: 'texas', desc: '', args: []);
  }

  /// `Utah`
  String get utah {
    return Intl.message('Utah', name: 'utah', desc: '', args: []);
  }

  /// `Vermont`
  String get vermont {
    return Intl.message('Vermont', name: 'vermont', desc: '', args: []);
  }

  /// `Virgínia`
  String get virginia {
    return Intl.message('Virgínia', name: 'virginia', desc: '', args: []);
  }

  /// `Washington`
  String get washington {
    return Intl.message('Washington', name: 'washington', desc: '', args: []);
  }

  /// `West Virginia`
  String get west_virginia {
    return Intl.message(
      'West Virginia',
      name: 'west_virginia',
      desc: '',
      args: [],
    );
  }

  /// `Wisconsin`
  String get wisconsin {
    return Intl.message('Wisconsin', name: 'wisconsin', desc: '', args: []);
  }

  /// `Wyoming`
  String get wyoming {
    return Intl.message('Wyoming', name: 'wyoming', desc: '', args: []);
  }

  /// `Selecione o país`
  String get select_country {
    return Intl.message(
      'Selecione o país',
      name: 'select_country',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o estado`
  String get select_state {
    return Intl.message(
      'Selecione o estado',
      name: 'select_state',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a cidade`
  String get select_city {
    return Intl.message(
      'Selecione a cidade',
      name: 'select_city',
      desc: '',
      args: [],
    );
  }

  /// `Propriedades Agrícolas`
  String get agricultural_properties {
    return Intl.message(
      'Propriedades Agrícolas',
      name: 'agricultural_properties',
      desc: '',
      args: [],
    );
  }

  /// `Compras`
  String get purchases {
    return Intl.message('Compras', name: 'purchases', desc: '', args: []);
  }

  /// `Itens da Compra`
  String get purchase_items {
    return Intl.message(
      'Itens da Compra',
      name: 'purchase_items',
      desc: '',
      args: [],
    );
  }

  /// `Pagamentos da Compra`
  String get purchase_payments {
    return Intl.message(
      'Pagamentos da Compra',
      name: 'purchase_payments',
      desc: '',
      args: [],
    );
  }

  /// `Estoque`
  String get stock {
    return Intl.message('Estoque', name: 'stock', desc: '', args: []);
  }

  /// `Movimentações de Estoque`
  String get stock_movements {
    return Intl.message(
      'Movimentações de Estoque',
      name: 'stock_movements',
      desc: '',
      args: [],
    );
  }

  /// `Pessoas`
  String get people {
    return Intl.message('Pessoas', name: 'people', desc: '', args: []);
  }

  /// `Talhões`
  String get plots {
    return Intl.message('Talhões', name: 'plots', desc: '', args: []);
  }

  /// `ID do Produtor`
  String get producer_id {
    return Intl.message(
      'ID do Produtor',
      name: 'producer_id',
      desc: '',
      args: [],
    );
  }

  /// `ID da Propriedade`
  String get property_id {
    return Intl.message(
      'ID da Propriedade',
      name: 'property_id',
      desc: '',
      args: [],
    );
  }

  /// `ID da Compra`
  String get purchase_id {
    return Intl.message(
      'ID da Compra',
      name: 'purchase_id',
      desc: '',
      args: [],
    );
  }

  /// `ID do Estoque`
  String get stock_id {
    return Intl.message('ID do Estoque', name: 'stock_id', desc: '', args: []);
  }

  /// `Cancelar`
  String get cancel {
    return Intl.message('Cancelar', name: 'cancel', desc: '', args: []);
  }

  /// `Excluir`
  String get delete {
    return Intl.message('Excluir', name: 'delete', desc: '', args: []);
  }

  /// `Remover`
  String get remove {
    return Intl.message('Remover', name: 'remove', desc: '', args: []);
  }

  /// `Salvar`
  String get save {
    return Intl.message('Salvar', name: 'save', desc: '', args: []);
  }

  /// `Adicionar`
  String get add {
    return Intl.message('Adicionar', name: 'add', desc: '', args: []);
  }

  /// `Adicionar {description}`
  String add_description(Object description) {
    return Intl.message(
      'Adicionar $description',
      name: 'add_description',
      desc: '',
      args: [description],
    );
  }

  /// `Editar {description}`
  String edit_description(Object description) {
    return Intl.message(
      'Editar $description',
      name: 'edit_description',
      desc: '',
      args: [description],
    );
  }

  /// `Erro`
  String get error {
    return Intl.message('Erro', name: 'error', desc: '', args: []);
  }

  /// `Ok`
  String get ok {
    return Intl.message('Ok', name: 'ok', desc: '', args: []);
  }

  /// `Pular`
  String get skip {
    return Intl.message('Pular', name: 'skip', desc: '', args: []);
  }

  /// `Ajuda`
  String get help {
    return Intl.message('Ajuda', name: 'help', desc: '', args: []);
  }

  /// `Voltar`
  String get back {
    return Intl.message('Voltar', name: 'back', desc: '', args: []);
  }

  /// `Finalizar`
  String get finalize {
    return Intl.message('Finalizar', name: 'finalize', desc: '', args: []);
  }

  /// `Avançar`
  String get next {
    return Intl.message('Avançar', name: 'next', desc: '', args: []);
  }

  /// `Alterar`
  String get edit {
    return Intl.message('Alterar', name: 'edit', desc: '', args: []);
  }

  /// `Não`
  String get no {
    return Intl.message('Não', name: 'no', desc: '', args: []);
  }

  /// `Sim`
  String get yes {
    return Intl.message('Sim', name: 'yes', desc: '', args: []);
  }

  /// `Clique para selecionar este(a) {nomeTutorial}.`
  String click_to_select_generic(Object nomeTutorial) {
    return Intl.message(
      'Clique para selecionar este(a) $nomeTutorial.',
      name: 'click_to_select_generic',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Clique para ver os detalhes`
  String get click_to_view_details {
    return Intl.message(
      'Clique para ver os detalhes',
      name: 'click_to_view_details',
      desc: '',
      args: [],
    );
  }

  /// `Clique para editar`
  String get click_to_edit_simple {
    return Intl.message(
      'Clique para editar',
      name: 'click_to_edit_simple',
      desc: '',
      args: [],
    );
  }

  /// `Clique para excluir`
  String get click_to_delete {
    return Intl.message(
      'Clique para excluir',
      name: 'click_to_delete',
      desc: '',
      args: [],
    );
  }

  /// `Insumo ou Produto`
  String get input {
    return Intl.message('Insumo ou Produto', name: 'input', desc: '', args: []);
  }

  /// `Produto`
  String get product {
    return Intl.message('Produto', name: 'product', desc: '', args: []);
  }

  /// `Diversos`
  String get various {
    return Intl.message('Diversos', name: 'various', desc: '', args: []);
  }

  /// `Fertilizante`
  String get fertilizer {
    return Intl.message('Fertilizante', name: 'fertilizer', desc: '', args: []);
  }

  /// `Semente`
  String get seed {
    return Intl.message('Semente', name: 'seed', desc: '', args: []);
  }

  /// `Grão`
  String get grain {
    return Intl.message('Grão', name: 'grain', desc: '', args: []);
  }

  /// `Fruto`
  String get fruit {
    return Intl.message('Fruto', name: 'fruit', desc: '', args: []);
  }

  /// `Medicamento Veterinário`
  String get veterinary_medicine {
    return Intl.message(
      'Medicamento Veterinário',
      name: 'veterinary_medicine',
      desc: '',
      args: [],
    );
  }

  /// `Ferramentas`
  String get tools {
    return Intl.message('Ferramentas', name: 'tools', desc: '', args: []);
  }

  /// `Combustível`
  String get fuel {
    return Intl.message('Combustível', name: 'fuel', desc: '', args: []);
  }

  /// `Ração`
  String get feed {
    return Intl.message('Ração', name: 'feed', desc: '', args: []);
  }

  /// `Animal`
  String get animal {
    return Intl.message('Animal', name: 'animal', desc: '', args: []);
  }

  /// `Animais`
  String get animals {
    return Intl.message('Animais', name: 'animals', desc: '', args: []);
  }

  /// `Equipamento`
  String get equipment {
    return Intl.message('Equipamento', name: 'equipment', desc: '', args: []);
  }

  /// `Imóvel`
  String get real_estate {
    return Intl.message('Imóvel', name: 'real_estate', desc: '', args: []);
  }

  /// `Maquinário`
  String get machinery {
    return Intl.message('Maquinário', name: 'machinery', desc: '', args: []);
  }

  /// `Serviço`
  String get service {
    return Intl.message('Serviço', name: 'service', desc: '', args: []);
  }

  /// `Veículo`
  String get vehicle {
    return Intl.message('Veículo', name: 'vehicle', desc: '', args: []);
  }

  /// `Defensivos Agrícolas`
  String get agricultural_chemicals {
    return Intl.message(
      'Defensivos Agrícolas',
      name: 'agricultural_chemicals',
      desc: '',
      args: [],
    );
  }

  /// `Embalagens`
  String get packaging {
    return Intl.message('Embalagens', name: 'packaging', desc: '', args: []);
  }

  /// `Ferragens`
  String get hardware {
    return Intl.message('Ferragens', name: 'hardware', desc: '', args: []);
  }

  /// `Implementos Agrícolas`
  String get agricultural_implements {
    return Intl.message(
      'Implementos Agrícolas',
      name: 'agricultural_implements',
      desc: '',
      args: [],
    );
  }

  /// `Lubrificantes e Óleos`
  String get lubricants_and_oils {
    return Intl.message(
      'Lubrificantes e Óleos',
      name: 'lubricants_and_oils',
      desc: '',
      args: [],
    );
  }

  /// `Material de Construção`
  String get building_materials {
    return Intl.message(
      'Material de Construção',
      name: 'building_materials',
      desc: '',
      args: [],
    );
  }

  /// `Mudas`
  String get seedlings {
    return Intl.message('Mudas', name: 'seedlings', desc: '', args: []);
  }

  /// `Peças de Reposição`
  String get replacement_parts {
    return Intl.message(
      'Peças de Reposição',
      name: 'replacement_parts',
      desc: '',
      args: [],
    );
  }

  /// `Produtos de Higiene e Limpeza`
  String get hygiene_and_cleaning_products {
    return Intl.message(
      'Produtos de Higiene e Limpeza',
      name: 'hygiene_and_cleaning_products',
      desc: '',
      args: [],
    );
  }

  /// `Produtos Veterinários`
  String get veterinary_products {
    return Intl.message(
      'Produtos Veterinários',
      name: 'veterinary_products',
      desc: '',
      args: [],
    );
  }

  /// `Serviços`
  String get services {
    return Intl.message('Serviços', name: 'services', desc: '', args: []);
  }

  /// `Crédito Próprio`
  String get own_credit {
    return Intl.message(
      'Crédito Próprio',
      name: 'own_credit',
      desc: '',
      args: [],
    );
  }

  /// `Crédito de Terceiros`
  String get third_party_credit {
    return Intl.message(
      'Crédito de Terceiros',
      name: 'third_party_credit',
      desc: '',
      args: [],
    );
  }

  /// `Metro quadrado (m²)`
  String get square_meter {
    return Intl.message(
      'Metro quadrado (m²)',
      name: 'square_meter',
      desc: '',
      args: [],
    );
  }

  /// `Quilograma (kg)`
  String get kilogram {
    return Intl.message(
      'Quilograma (kg)',
      name: 'kilogram',
      desc: '',
      args: [],
    );
  }

  /// `Grama (g)`
  String get gram {
    return Intl.message('Grama (g)', name: 'gram', desc: '', args: []);
  }

  /// `Tonelada (t)`
  String get ton {
    return Intl.message('Tonelada (t)', name: 'ton', desc: '', args: []);
  }

  /// `Miligrama (mg)`
  String get milligram {
    return Intl.message(
      'Miligrama (mg)',
      name: 'milligram',
      desc: '',
      args: [],
    );
  }

  /// `Arroba (@)`
  String get arroba {
    return Intl.message('Arroba (@)', name: 'arroba', desc: '', args: []);
  }

  /// `Metro (m)`
  String get meter {
    return Intl.message('Metro (m)', name: 'meter', desc: '', args: []);
  }

  /// `Centímetro (cm)`
  String get centimeter {
    return Intl.message(
      'Centímetro (cm)',
      name: 'centimeter',
      desc: '',
      args: [],
    );
  }

  /// `Milímetro (mm)`
  String get millimeter {
    return Intl.message(
      'Milímetro (mm)',
      name: 'millimeter',
      desc: '',
      args: [],
    );
  }

  /// `Quilômetro (km)`
  String get kilometer {
    return Intl.message(
      'Quilômetro (km)',
      name: 'kilometer',
      desc: '',
      args: [],
    );
  }

  /// `Litro (L)`
  String get liter {
    return Intl.message('Litro (L)', name: 'liter', desc: '', args: []);
  }

  /// `Mililitro (mL)`
  String get milliliter {
    return Intl.message(
      'Mililitro (mL)',
      name: 'milliliter',
      desc: '',
      args: [],
    );
  }

  /// `Metro cúbico (m³)`
  String get cubic_meter {
    return Intl.message(
      'Metro cúbico (m³)',
      name: 'cubic_meter',
      desc: '',
      args: [],
    );
  }

  /// `Centímetro cúbico (cm³)`
  String get cubic_centimeter {
    return Intl.message(
      'Centímetro cúbico (cm³)',
      name: 'cubic_centimeter',
      desc: '',
      args: [],
    );
  }

  /// `Unidade`
  String get unit {
    return Intl.message('Unidade', name: 'unit', desc: '', args: []);
  }

  /// `Hora (h)`
  String get hour {
    return Intl.message('Hora (h)', name: 'hour', desc: '', args: []);
  }

  /// `Minuto (min)`
  String get minute {
    return Intl.message('Minuto (min)', name: 'minute', desc: '', args: []);
  }

  /// `Dia (d)`
  String get day {
    return Intl.message('Dia (d)', name: 'day', desc: '', args: []);
  }

  /// `Alqueire`
  String get alqueire {
    return Intl.message('Alqueire', name: 'alqueire', desc: '', args: []);
  }

  /// `Caixa`
  String get box {
    return Intl.message('Caixa', name: 'box', desc: '', args: []);
  }

  /// `Dúzia`
  String get dozen {
    return Intl.message('Dúzia', name: 'dozen', desc: '', args: []);
  }

  /// `Fardo`
  String get bale {
    return Intl.message('Fardo', name: 'bale', desc: '', args: []);
  }

  /// `Hectare`
  String get hectare {
    return Intl.message('Hectare', name: 'hectare', desc: '', args: []);
  }

  /// `Pacote`
  String get package {
    return Intl.message('Pacote', name: 'package', desc: '', args: []);
  }

  /// `Peça`
  String get piece {
    return Intl.message('Peça', name: 'piece', desc: '', args: []);
  }

  /// `Saco 20kg`
  String get bag_20kg {
    return Intl.message('Saco 20kg', name: 'bag_20kg', desc: '', args: []);
  }

  /// `Saco 25kg`
  String get bag_25kg {
    return Intl.message('Saco 25kg', name: 'bag_25kg', desc: '', args: []);
  }

  /// `Saco 30kg`
  String get bag_30kg {
    return Intl.message('Saco 30kg', name: 'bag_30kg', desc: '', args: []);
  }

  /// `Saco 40kg`
  String get bag_40kg {
    return Intl.message('Saco 40kg', name: 'bag_40kg', desc: '', args: []);
  }

  /// `Saco 50kg`
  String get bag_50kg {
    return Intl.message('Saco 50kg', name: 'bag_50kg', desc: '', args: []);
  }

  /// `Saco 60kg`
  String get bag_60kg {
    return Intl.message('Saco 60kg', name: 'bag_60kg', desc: '', args: []);
  }

  /// `Lançamento`
  String get entry {
    return Intl.message('Lançamento', name: 'entry', desc: '', args: []);
  }

  /// `Saída`
  String get exit {
    return Intl.message('Saída', name: 'exit', desc: '', args: []);
  }

  /// `Compra`
  String get purchase {
    return Intl.message('Compra', name: 'purchase', desc: '', args: []);
  }

  /// `Ajuste`
  String get adjustment {
    return Intl.message('Ajuste', name: 'adjustment', desc: '', args: []);
  }

  /// `Transferência`
  String get transfer {
    return Intl.message('Transferência', name: 'transfer', desc: '', args: []);
  }

  /// `Estorno de Compra`
  String get purchase_reversal {
    return Intl.message(
      'Estorno de Compra',
      name: 'purchase_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Estorno de Consumo`
  String get consumption_reversal {
    return Intl.message(
      'Estorno de Consumo',
      name: 'consumption_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Estorno de Venda`
  String get sales_reversal {
    return Intl.message(
      'Estorno de Venda',
      name: 'sales_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Estorno de Devolução`
  String get return_reversal {
    return Intl.message(
      'Estorno de Devolução',
      name: 'return_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Consumo`
  String get consumption {
    return Intl.message('Consumo', name: 'consumption', desc: '', args: []);
  }

  /// `Venda`
  String get sale {
    return Intl.message('Venda', name: 'sale', desc: '', args: []);
  }

  /// `Devolução de Compra`
  String get purchase_return {
    return Intl.message(
      'Devolução de Compra',
      name: 'purchase_return',
      desc: '',
      args: [],
    );
  }

  /// `Devolução de Venda`
  String get sales_return {
    return Intl.message(
      'Devolução de Venda',
      name: 'sales_return',
      desc: '',
      args: [],
    );
  }

  /// `Devolução de Consumo`
  String get consumption_return {
    return Intl.message(
      'Devolução de Consumo',
      name: 'consumption_return',
      desc: '',
      args: [],
    );
  }

  /// `Perda`
  String get loss {
    return Intl.message(
      'Perda',
      name: 'loss',
      desc: 'Rótulo para lançamentos de perda',
      args: [],
    );
  }

  /// `Doação`
  String get donation {
    return Intl.message('Doação', name: 'donation', desc: '', args: []);
  }

  /// `Bonificação`
  String get bonus {
    return Intl.message('Bonificação', name: 'bonus', desc: '', args: []);
  }

  /// `Estorno de Transferência`
  String get transfer_reversal {
    return Intl.message(
      'Estorno de Transferência',
      name: 'transfer_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Devolução de Transferência`
  String get transfer_return {
    return Intl.message(
      'Devolução de Transferência',
      name: 'transfer_return',
      desc: '',
      args: [],
    );
  }

  /// `Processando...`
  String get processing {
    return Intl.message(
      'Processando...',
      name: 'processing',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Compra`
  String get select_purchase {
    return Intl.message(
      'Selecionar Compra',
      name: 'select_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Pessoa Física`
  String get individual {
    return Intl.message(
      'Pessoa Física',
      name: 'individual',
      desc: '',
      args: [],
    );
  }

  /// `Pessoa Jurídica`
  String get legal_entity {
    return Intl.message(
      'Pessoa Jurídica',
      name: 'legal_entity',
      desc: '',
      args: [],
    );
  }

  /// `Cliente`
  String get client {
    return Intl.message('Cliente', name: 'client', desc: '', args: []);
  }

  /// `Fornecedor`
  String get supplier {
    return Intl.message('Fornecedor', name: 'supplier', desc: '', args: []);
  }

  /// `Funcionário`
  String get employee {
    return Intl.message('Funcionário', name: 'employee', desc: '', args: []);
  }

  /// `Parceiro`
  String get partner {
    return Intl.message('Parceiro', name: 'partner', desc: '', args: []);
  }

  /// `Ativo`
  String get active {
    return Intl.message('Ativo', name: 'active', desc: '', args: []);
  }

  /// `Inativo`
  String get inactive {
    return Intl.message('Inativo', name: 'inactive', desc: '', args: []);
  }

  /// `Admin`
  String get admin {
    return Intl.message('Admin', name: 'admin', desc: '', args: []);
  }

  /// `Produtor`
  String get producer {
    return Intl.message('Produtor', name: 'producer', desc: '', args: []);
  }

  /// `Gerente`
  String get manager {
    return Intl.message('Gerente', name: 'manager', desc: '', args: []);
  }

  /// `Operador`
  String get operator {
    return Intl.message('Operador', name: 'operator', desc: '', args: []);
  }

  /// `Curioso`
  String get curious {
    return Intl.message('Curioso', name: 'curious', desc: '', args: []);
  }

  /// `Auto`
  String get auto {
    return Intl.message('Auto', name: 'auto', desc: '', args: []);
  }

  /// `Manual`
  String get manual {
    return Intl.message('Manual', name: 'manual', desc: '', args: []);
  }

  /// `Desativado`
  String get disabled {
    return Intl.message('Desativado', name: 'disabled', desc: '', args: []);
  }

  /// `Por favor, preencha o email e a senha para continuar.`
  String get msg_error_preencher_email_senha {
    return Intl.message(
      'Por favor, preencha o email e a senha para continuar.',
      name: 'msg_error_preencher_email_senha',
      desc: '',
      args: [],
    );
  }

  /// `Conta já existe com uma credencial diferente.`
  String get error_account_exists_different_credential {
    return Intl.message(
      'Conta já existe com uma credencial diferente.',
      name: 'error_account_exists_different_credential',
      desc: '',
      args: [],
    );
  }

  /// `A credencial fornecida é inválida ou expirou.`
  String get error_invalid_credential {
    return Intl.message(
      'A credencial fornecida é inválida ou expirou.',
      name: 'error_invalid_credential',
      desc: '',
      args: [],
    );
  }

  /// `Operação não permitida. Entre em contato com o suporte.`
  String get error_operation_not_allowed {
    return Intl.message(
      'Operação não permitida. Entre em contato com o suporte.',
      name: 'error_operation_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `O usuário com este email foi desativado.`
  String get error_user_disabled {
    return Intl.message(
      'O usuário com este email foi desativado.',
      name: 'error_user_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum usuário encontrado com este email.`
  String get error_user_not_found {
    return Intl.message(
      'Nenhum usuário encontrado com este email.',
      name: 'error_user_not_found',
      desc: '',
      args: [],
    );
  }

  /// `A senha fornecida está incorreta.`
  String get error_wrong_password {
    return Intl.message(
      'A senha fornecida está incorreta.',
      name: 'error_wrong_password',
      desc: '',
      args: [],
    );
  }

  /// `O código de verificação fornecido é inválido.`
  String get error_invalid_verification_code {
    return Intl.message(
      'O código de verificação fornecido é inválido.',
      name: 'error_invalid_verification_code',
      desc: '',
      args: [],
    );
  }

  /// `O ID de verificação fornecido é inválido.`
  String get error_invalid_verification_id {
    return Intl.message(
      'O ID de verificação fornecido é inválido.',
      name: 'error_invalid_verification_id',
      desc: '',
      args: [],
    );
  }

  /// `Erro desconhecido`
  String get error_unknown {
    return Intl.message(
      'Erro desconhecido',
      name: 'error_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Um erro ocorreu. Tente novamente mais tarde.`
  String get error_generic {
    return Intl.message(
      'Um erro ocorreu. Tente novamente mais tarde.',
      name: 'error_generic',
      desc: '',
      args: [],
    );
  }

  /// `Erro original`
  String get error_original {
    return Intl.message(
      'Erro original',
      name: 'error_original',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Senha`
  String get password {
    return Intl.message('Senha', name: 'password', desc: '', args: []);
  }

  /// `Continuar com Email/Senha`
  String get continuar_email_senha {
    return Intl.message(
      'Continuar com Email/Senha',
      name: 'continuar_email_senha',
      desc: '',
      args: [],
    );
  }

  /// `Registrar com Email/Senha`
  String get registrar_email_senha {
    return Intl.message(
      'Registrar com Email/Senha',
      name: 'registrar_email_senha',
      desc: '',
      args: [],
    );
  }

  /// `Não tem uma conta? Registre-se`
  String get register_prompt {
    return Intl.message(
      'Não tem uma conta? Registre-se',
      name: 'register_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Já tem uma conta? Faça login`
  String get login_prompt {
    return Intl.message(
      'Já tem uma conta? Faça login',
      name: 'login_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Continuar com o Google`
  String get continue_with_google {
    return Intl.message(
      'Continuar com o Google',
      name: 'continue_with_google',
      desc: '',
      args: [],
    );
  }

  /// `Bem-vindo, amigo produtor!`
  String get welcome_producer {
    return Intl.message(
      'Bem-vindo, amigo produtor!',
      name: 'welcome_producer',
      desc: '',
      args: [],
    );
  }

  /// `Vamos começar criando seu cadastro de produtor rural ou selecionando um já existente.`
  String get start_producer_registration {
    return Intl.message(
      'Vamos começar criando seu cadastro de produtor rural ou selecionando um já existente.',
      name: 'start_producer_registration',
      desc: '',
      args: [],
    );
  }

  /// `Selecione um Produtor`
  String get select_producer {
    return Intl.message(
      'Selecione um Produtor',
      name: 'select_producer',
      desc: '',
      args: [],
    );
  }

  /// `Escolha ou cadastre um produtor rural para continuar.`
  String get choose_or_register_producer {
    return Intl.message(
      'Escolha ou cadastre um produtor rural para continuar.',
      name: 'choose_or_register_producer',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Produtor`
  String get select_producer_button {
    return Intl.message(
      'Selecionar Produtor',
      name: 'select_producer_button',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Propriedade`
  String get select_property {
    return Intl.message(
      'Selecionar Propriedade',
      name: 'select_property',
      desc: '',
      args: [],
    );
  }

  /// `Selecione ou cadastre uma propriedade rural para registrar suas atividades e movimentações.`
  String get select_or_register_property {
    return Intl.message(
      'Selecione ou cadastre uma propriedade rural para registrar suas atividades e movimentações.',
      name: 'select_or_register_property',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Propriedade`
  String get select_property_button {
    return Intl.message(
      'Selecionar Propriedade',
      name: 'select_property_button',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para incluir {nomeTutorial}.`
  String click_to_add(Object nomeTutorial) {
    return Intl.message(
      'Clique aqui para incluir $nomeTutorial.',
      name: 'click_to_add',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Clique aqui para voltar à tela anterior.`
  String get click_to_go_back {
    return Intl.message(
      'Clique aqui para voltar à tela anterior.',
      name: 'click_to_go_back',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver mais opções.`
  String get click_to_see_more_options {
    return Intl.message(
      'Clique aqui para ver mais opções.',
      name: 'click_to_see_more_options',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver mais opções. Não é possível remover o Produtor ou a Propriedade Rural ativos na aplicação.`
  String get click_to_see_more_options_restricted {
    return Intl.message(
      'Clique aqui para ver mais opções. Não é possível remover o Produtor ou a Propriedade Rural ativos na aplicação.',
      name: 'click_to_see_more_options_restricted',
      desc: '',
      args: [],
    );
  }

  /// `Neste quadro está a lista de {nomeTutorialPlural} existentes.`
  String list_of_existing(Object nomeTutorialPlural) {
    return Intl.message(
      'Neste quadro está a lista de $nomeTutorialPlural existentes.',
      name: 'list_of_existing',
      desc: '',
      args: [nomeTutorialPlural],
    );
  }

  /// `Clique aqui para salvar as alterações.`
  String get click_to_save_changes {
    return Intl.message(
      'Clique aqui para salvar as alterações.',
      name: 'click_to_save_changes',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para outras funcionalidades.`
  String get click_for_other_features {
    return Intl.message(
      'Clique aqui para outras funcionalidades.',
      name: 'click_for_other_features',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Exclusão`
  String get confirm_deletion {
    return Intl.message(
      'Confirmar Exclusão',
      name: 'confirm_deletion',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta {nomeTutorial}?`
  String confirm_deletion_message(Object nomeTutorial) {
    return Intl.message(
      'Deseja realmente excluir esta $nomeTutorial?',
      name: 'confirm_deletion_message',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Aqui você pode ver um resumo das informações do {nomeTutorial}.`
  String summary_of_information(Object nomeTutorial) {
    return Intl.message(
      'Aqui você pode ver um resumo das informações do $nomeTutorial.',
      name: 'summary_of_information',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Clique aqui apresentar o tutorial de ajuda.`
  String get click_to_show_help_tutorial {
    return Intl.message(
      'Clique aqui apresentar o tutorial de ajuda.',
      name: 'click_to_show_help_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui alterar as informações deste(a) {nomeTutorial}.`
  String click_to_edit(Object nomeTutorial) {
    return Intl.message(
      'Clique aqui alterar as informações deste(a) $nomeTutorial.',
      name: 'click_to_edit',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Clique aqui remover este(a) {nomeTutorial}.`
  String click_to_remove(Object nomeTutorial) {
    return Intl.message(
      'Clique aqui remover este(a) $nomeTutorial.',
      name: 'click_to_remove',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Carregando Produtores`
  String get loading_producers {
    return Intl.message(
      'Carregando Produtores',
      name: 'loading_producers',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar produtores`
  String get error_loading_producers {
    return Intl.message(
      'Erro ao carregar produtores',
      name: 'error_loading_producers',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar o produtor: {error}`
  String error_saving_producer(Object error) {
    return Intl.message(
      'Erro ao salvar o produtor: $error',
      name: 'error_saving_producer',
      desc: '',
      args: [error],
    );
  }

  /// `Nenhum produtor encontrado`
  String get no_producers_found {
    return Intl.message(
      'Nenhum produtor encontrado',
      name: 'no_producers_found',
      desc: '',
      args: [],
    );
  }

  /// `Produtores Rurais`
  String get rural_producers {
    return Intl.message(
      'Produtores Rurais',
      name: 'rural_producers',
      desc: '',
      args: [],
    );
  }

  /// `Produtor Rural`
  String get rural_producer {
    return Intl.message(
      'Produtor Rural',
      name: 'rural_producer',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Produtor`
  String get click_to_select_producer {
    return Intl.message(
      'Clique aqui para selecionar o Produtor',
      name: 'click_to_select_producer',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para exibir detalhes do Produtor`
  String get click_to_view_producer_details {
    return Intl.message(
      'Clique aqui para exibir detalhes do Produtor',
      name: 'click_to_view_producer_details',
      desc: '',
      args: [],
    );
  }

  /// `Selecione ou cadastre um produtor rural para registrar suas atividades e movimentações.`
  String get select_or_register_farmer {
    return Intl.message(
      'Selecione ou cadastre um produtor rural para registrar suas atividades e movimentações.',
      name: 'select_or_register_farmer',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Produtor`
  String get add_producer {
    return Intl.message(
      'Adicionar Produtor',
      name: 'add_producer',
      desc: '',
      args: [],
    );
  }

  /// `Editar Produtor Rural`
  String get edit_rural_producer {
    return Intl.message(
      'Editar Produtor Rural',
      name: 'edit_rural_producer',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados do Produtor Rural.`
  String get edit_rural_producer_info {
    return Intl.message(
      'Aqui você pode alterar dados do Produtor Rural.',
      name: 'edit_rural_producer_info',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode permitir acesso de outros usuários a este Produtor Rural.`
  String get grant_access_other_users {
    return Intl.message(
      'Aqui você pode permitir acesso de outros usuários a este Produtor Rural.',
      name: 'grant_access_other_users',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para conceder acesso a outros usuários para este Produtor Rural.`
  String get click_to_grant_access {
    return Intl.message(
      'Clique aqui para conceder acesso a outros usuários para este Produtor Rural.',
      name: 'click_to_grant_access',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Produtor`
  String get producer_type {
    return Intl.message(
      'Tipo de Produtor',
      name: 'producer_type',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message('Status', name: 'status', desc: '', args: []);
  }

  /// `Pessoas com Acesso`
  String get people_with_access {
    return Intl.message(
      'Pessoas com Acesso',
      name: 'people_with_access',
      desc: '',
      args: [],
    );
  }

  /// `Nome`
  String get name {
    return Intl.message('Nome', name: 'name', desc: '', args: []);
  }

  /// `Por favor, insira o nome`
  String get enter_name {
    return Intl.message(
      'Por favor, insira o nome',
      name: 'enter_name',
      desc: '',
      args: [],
    );
  }

  /// `CPF`
  String get cpf {
    return Intl.message('CPF', name: 'cpf', desc: '', args: []);
  }

  /// `CNPJ`
  String get cnpj {
    return Intl.message('CNPJ', name: 'cnpj', desc: '', args: []);
  }

  /// `Por favor, insira o CPF`
  String get enter_cpf {
    return Intl.message(
      'Por favor, insira o CPF',
      name: 'enter_cpf',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o CNPJ`
  String get enter_cnpj {
    return Intl.message(
      'Por favor, insira o CNPJ',
      name: 'enter_cnpj',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Produtor`
  String get producer_details {
    return Intl.message(
      'Detalhes do Produtor',
      name: 'producer_details',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode ver as permissões dos usuários.`
  String get view_user_permissions {
    return Intl.message(
      'Aqui você pode ver as permissões dos usuários.',
      name: 'view_user_permissions',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão listadas as propriedades do produtor.`
  String get producer_properties_listed {
    return Intl.message(
      'Aqui estão listadas as propriedades do produtor.',
      name: 'producer_properties_listed',
      desc: '',
      args: [],
    );
  }

  /// `Carregando...`
  String get loading {
    return Intl.message('Carregando...', name: 'loading', desc: '', args: []);
  }

  /// `Erro ao carregar dados`
  String get error_loading {
    return Intl.message(
      'Erro ao carregar dados',
      name: 'error_loading',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar informações {description}`
  String error_loading_description(Object description) {
    return Intl.message(
      'Erro ao carregar informações $description',
      name: 'error_loading_description',
      desc: '',
      args: [description],
    );
  }

  /// `Nenhuma informação encontrada`
  String get not_found {
    return Intl.message(
      'Nenhuma informação encontrada',
      name: 'not_found',
      desc: '',
      args: [],
    );
  }

  /// `Área`
  String get area {
    return Intl.message('Área', name: 'area', desc: '', args: []);
  }

  /// `Hectares (ha)`
  String get hectares {
    return Intl.message('Hectares (ha)', name: 'hectares', desc: '', args: []);
  }

  /// `Permissão`
  String get permissao {
    return Intl.message('Permissão', name: 'permissao', desc: '', args: []);
  }

  /// `Clique aqui para selecionar a Propriedade`
  String get click_to_select_property {
    return Intl.message(
      'Clique aqui para selecionar a Propriedade',
      name: 'click_to_select_property',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para exibir detalhes da Propriedade`
  String get click_to_view_property_details {
    return Intl.message(
      'Clique aqui para exibir detalhes da Propriedade',
      name: 'click_to_view_property_details',
      desc: '',
      args: [],
    );
  }

  /// `Propriedade Agrícola`
  String get agricultural_property {
    return Intl.message(
      'Propriedade Agrícola',
      name: 'agricultural_property',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Item`
  String get select_item {
    return Intl.message(
      'Selecionar Item',
      name: 'select_item',
      desc: '',
      args: [],
    );
  }

  /// `Itens`
  String get items {
    return Intl.message('Itens', name: 'items', desc: '', args: []);
  }

  /// `Clique aqui para selecionar o Item`
  String get click_to_select_item {
    return Intl.message(
      'Clique aqui para selecionar o Item',
      name: 'click_to_select_item',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para exibir detalhes do Item`
  String get click_to_view_item_details {
    return Intl.message(
      'Clique aqui para exibir detalhes do Item',
      name: 'click_to_view_item_details',
      desc: '',
      args: [],
    );
  }

  /// `Tipo`
  String get type {
    return Intl.message('Tipo', name: 'type', desc: '', args: []);
  }

  /// `Item`
  String get item {
    return Intl.message('Item', name: 'item', desc: '', args: []);
  }

  /// `Pessoa`
  String get person {
    return Intl.message('Pessoa', name: 'person', desc: '', args: []);
  }

  /// `Pessoas & Entidades`
  String get people_entities {
    return Intl.message(
      'Pessoas & Entidades',
      name: 'people_entities',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar a Pessoa Física ou Jurídica`
  String get click_to_select_person {
    return Intl.message(
      'Clique aqui para selecionar a Pessoa Física ou Jurídica',
      name: 'click_to_select_person',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para exibir detalhes da Pessoa`
  String get click_to_view_person_details {
    return Intl.message(
      'Clique aqui para exibir detalhes da Pessoa',
      name: 'click_to_view_person_details',
      desc: '',
      args: [],
    );
  }

  /// `Sair do aplicativo`
  String get confirm_exit {
    return Intl.message(
      'Sair do aplicativo',
      name: 'confirm_exit',
      desc: '',
      args: [],
    );
  }

  /// `Você realmente quer sair do aplicativo?`
  String get confirm_exit_message {
    return Intl.message(
      'Você realmente quer sair do aplicativo?',
      name: 'confirm_exit_message',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Compras & Serviços`
  String get purchase_services {
    return Intl.message(
      'Compras & Serviços',
      name: 'purchase_services',
      desc: '',
      args: [],
    );
  }

  /// `Configurações`
  String get settings {
    return Intl.message('Configurações', name: 'settings', desc: '', args: []);
  }

  /// `Financeiro`
  String get finances {
    return Intl.message('Financeiro', name: 'finances', desc: '', args: []);
  }

  /// `Alterações não salvas`
  String get confirm_exit_whitout_save {
    return Intl.message(
      'Alterações não salvas',
      name: 'confirm_exit_whitout_save',
      desc: '',
      args: [],
    );
  }

  /// `Você tem alterações não salvas. Deseja realmente sair sem salvar?`
  String get confirm_exit_message_without_save {
    return Intl.message(
      'Você tem alterações não salvas. Deseja realmente sair sem salvar?',
      name: 'confirm_exit_message_without_save',
      desc: '',
      args: [],
    );
  }

  /// `Este ícone volta para a tela principal.`
  String get tutorial_home_button {
    return Intl.message(
      'Este ícone volta para a tela principal.',
      name: 'tutorial_home_button',
      desc: '',
      args: [],
    );
  }

  /// `Este ícone acessa opções de Finanças.`
  String get tutorial_finance_button {
    return Intl.message(
      'Este ícone acessa opções de Finanças.',
      name: 'tutorial_finance_button',
      desc: '',
      args: [],
    );
  }

  /// `Este ícone acessa opções Agro.`
  String get tutorial_agro_button {
    return Intl.message(
      'Este ícone acessa opções Agro.',
      name: 'tutorial_agro_button',
      desc: '',
      args: [],
    );
  }

  /// `Acesso ao menu lateral e ver mais opções.`
  String get tutorial_menu_button {
    return Intl.message(
      'Acesso ao menu lateral e ver mais opções.',
      name: 'tutorial_menu_button',
      desc: '',
      args: [],
    );
  }

  /// `Acesso para a tela principal.`
  String get tutorial_home_return_button {
    return Intl.message(
      'Acesso para a tela principal.',
      name: 'tutorial_home_return_button',
      desc: '',
      args: [],
    );
  }

  /// `Cadastrar ou alterar Produtores.`
  String get tutorial_producers_button {
    return Intl.message(
      'Cadastrar ou alterar Produtores.',
      name: 'tutorial_producers_button',
      desc: '',
      args: [],
    );
  }

  /// `Cadastrar ou alterar propriedades agrícolas.`
  String get tutorial_properties_button {
    return Intl.message(
      'Cadastrar ou alterar propriedades agrícolas.',
      name: 'tutorial_properties_button',
      desc: '',
      args: [],
    );
  }

  /// `Cadastrar Insumos, Produtos, Serviços e demais consumíveis.`
  String get tutorial_items_button {
    return Intl.message(
      'Cadastrar Insumos, Produtos, Serviços e demais consumíveis.',
      name: 'tutorial_items_button',
      desc: '',
      args: [],
    );
  }

  /// `Cadastrar Pessoas Físicas e Jurídicas (Fornecedores, Clientes, Parceiros, etc).`
  String get tutorial_people_button {
    return Intl.message(
      'Cadastrar Pessoas Físicas e Jurídicas (Fornecedores, Clientes, Parceiros, etc).',
      name: 'tutorial_people_button',
      desc: '',
      args: [],
    );
  }

  /// `Lançar compras de itens, produtos, insumos e serviços.`
  String get tutorial_purchases_button {
    return Intl.message(
      'Lançar compras de itens, produtos, insumos e serviços.',
      name: 'tutorial_purchases_button',
      desc: '',
      args: [],
    );
  }

  /// `Registrar de Chuvas.`
  String get tutorial_rain_quantity_button {
    return Intl.message(
      'Registrar de Chuvas.',
      name: 'tutorial_rain_quantity_button',
      desc: '',
      args: [],
    );
  }

  /// `Configurações adicionais do sistema.`
  String get tutorial_settings_button {
    return Intl.message(
      'Configurações adicionais do sistema.',
      name: 'tutorial_settings_button',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Propriedade`
  String get property_details {
    return Intl.message(
      'Detalhes da Propriedade',
      name: 'property_details',
      desc: '',
      args: [],
    );
  }

  /// `Talhões da Propriedade`
  String get property_plots {
    return Intl.message(
      'Talhões da Propriedade',
      name: 'property_plots',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão listados os talhões da propriedade.`
  String get property_plots_listed {
    return Intl.message(
      'Aqui estão listados os talhões da propriedade.',
      name: 'property_plots_listed',
      desc: '',
      args: [],
    );
  }

  /// `Modo de Movimentação`
  String get movement_mode {
    return Intl.message(
      'Modo de Movimentação',
      name: 'movement_mode',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, salve a propriedade primeiro.`
  String get please_save_property_first {
    return Intl.message(
      'Por favor, salve a propriedade primeiro.',
      name: 'please_save_property_first',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Ítem`
  String get item_details {
    return Intl.message(
      'Detalhes do Ítem',
      name: 'item_details',
      desc: '',
      args: [],
    );
  }

  /// `Insumo ou Produto`
  String get input_or_product {
    return Intl.message(
      'Insumo ou Produto',
      name: 'input_or_product',
      desc: '',
      args: [],
    );
  }

  /// `Alterar Insumo ou Produto`
  String get edit_input_or_product {
    return Intl.message(
      'Alterar Insumo ou Produto',
      name: 'edit_input_or_product',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Insumo ou Produto`
  String get select_input_or_product {
    return Intl.message(
      'Selecionar Insumo ou Produto',
      name: 'select_input_or_product',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Insumo ou Produto`
  String get add_input_or_product {
    return Intl.message(
      'Adicionar Insumo ou Produto',
      name: 'add_input_or_product',
      desc: '',
      args: [],
    );
  }

  /// `Insumos & Produtos`
  String get inputs_and_products {
    return Intl.message(
      'Insumos & Produtos',
      name: 'inputs_and_products',
      desc: '',
      args: [],
    );
  }

  /// `Estoques`
  String get stocks {
    return Intl.message('Estoques', name: 'stocks', desc: '', args: []);
  }

  /// `Aqui estão listados os estoques do item.`
  String get item_stocks_listed {
    return Intl.message(
      'Aqui estão listados os estoques do item.',
      name: 'item_stocks_listed',
      desc: '',
      args: [],
    );
  }

  /// `Categoria`
  String get category {
    return Intl.message('Categoria', name: 'category', desc: '', args: []);
  }

  /// `Unidade de Medida`
  String get unit_of_measure {
    return Intl.message(
      'Unidade de Medida',
      name: 'unit_of_measure',
      desc: '',
      args: [],
    );
  }

  /// `Fator de Decaimento`
  String get decay_factor {
    return Intl.message(
      'Fator de Decaimento',
      name: 'decay_factor',
      desc: '',
      args: [],
    );
  }

  /// `Descrição`
  String get description {
    return Intl.message('Descrição', name: 'description', desc: '', args: []);
  }

  /// `Quantidade`
  String get quantity {
    return Intl.message('Quantidade', name: 'quantity', desc: '', args: []);
  }

  /// `CMP`
  String get cmp {
    return Intl.message('CMP', name: 'cmp', desc: '', args: []);
  }

  /// `Detalhes da Pessoa`
  String get person_details {
    return Intl.message(
      'Detalhes da Pessoa',
      name: 'person_details',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão listados os detalhes da pessoa.`
  String get person_details_listed {
    return Intl.message(
      'Aqui estão listados os detalhes da pessoa.',
      name: 'person_details_listed',
      desc: '',
      args: [],
    );
  }

  /// `Vínculo`
  String get relationship {
    return Intl.message('Vínculo', name: 'relationship', desc: '', args: []);
  }

  /// `Selecione o Vínculo`
  String get select_relationship {
    return Intl.message(
      'Selecione o Vínculo',
      name: 'select_relationship',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o Tipo`
  String get select_type {
    return Intl.message(
      'Selecione o Tipo',
      name: 'select_type',
      desc: '',
      args: [],
    );
  }

  /// `Documento`
  String get document {
    return Intl.message('Documento', name: 'document', desc: '', args: []);
  }

  /// `Telefone`
  String get phone {
    return Intl.message('Telefone', name: 'phone', desc: '', args: []);
  }

  /// `Endereço`
  String get address {
    return Intl.message('Endereço', name: 'address', desc: '', args: []);
  }

  /// `Observações`
  String get notes {
    return Intl.message('Observações', name: 'notes', desc: '', args: []);
  }

  /// `Existem propriedades e outros lançamentos para este produtor. Deseja realmente excluir?`
  String get confirm_deletion_message_exists_properties {
    return Intl.message(
      'Existem propriedades e outros lançamentos para este produtor. Deseja realmente excluir?',
      name: 'confirm_deletion_message_exists_properties',
      desc: '',
      args: [],
    );
  }

  /// `Todos os dados relacionados a este produtor serão excluídos. Deseja realmente excluir?`
  String get confirm_final_deletion_message_producer {
    return Intl.message(
      'Todos os dados relacionados a este produtor serão excluídos. Deseja realmente excluir?',
      name: 'confirm_final_deletion_message_producer',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para excluir este {nomeTutorial}.`
  String no_permission_to_delete(Object nomeTutorial) {
    return Intl.message(
      'Você não tem permissão para excluir este $nomeTutorial.',
      name: 'no_permission_to_delete',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Você não tem permissão para adicionar ou alterar este {nomeTutorial}.`
  String no_permission_to_add_or_edit(Object nomeTutorial) {
    return Intl.message(
      'Você não tem permissão para adicionar ou alterar este $nomeTutorial.',
      name: 'no_permission_to_add_or_edit',
      desc: '',
      args: [nomeTutorial],
    );
  }

  /// `Você não tem permissão para salvar {entity}.`
  String no_permission_to_save(Object entity) {
    return Intl.message(
      'Você não tem permissão para salvar $entity.',
      name: 'no_permission_to_save',
      desc: '',
      args: [entity],
    );
  }

  /// `Você não tem permissão para adicionar usuários.`
  String get no_permission_to_add_users {
    return Intl.message(
      'Você não tem permissão para adicionar usuários.',
      name: 'no_permission_to_add_users',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para realizar esta ação.`
  String get no_permission {
    return Intl.message(
      'Você não tem permissão para realizar esta ação.',
      name: 'no_permission',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Permissão`
  String get add_permission {
    return Intl.message(
      'Adicionar Permissão',
      name: 'add_permission',
      desc: '',
      args: [],
    );
  }

  /// `Alterar Permissão`
  String get edit_permission {
    return Intl.message(
      'Alterar Permissão',
      name: 'edit_permission',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira um e-mail válido.`
  String get please_enter_valid_email {
    return Intl.message(
      'Por favor, insira um e-mail válido.',
      name: 'please_enter_valid_email',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione um perfil válido.`
  String get please_select_valid_role {
    return Intl.message(
      'Por favor, selecione um perfil válido.',
      name: 'please_select_valid_role',
      desc: '',
      args: [],
    );
  }

  /// `Permissão adicionada com sucesso.`
  String get permission_added_successfully {
    return Intl.message(
      'Permissão adicionada com sucesso.',
      name: 'permission_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao adicionar permissão: {error}`
  String error_adding_permission(Object error) {
    return Intl.message(
      'Erro ao adicionar permissão: $error',
      name: 'error_adding_permission',
      desc: '',
      args: [error],
    );
  }

  /// `Conceder Acesso`
  String get grant_access {
    return Intl.message(
      'Conceder Acesso',
      name: 'grant_access',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Talhão`
  String get add_plot {
    return Intl.message(
      'Adicionar Talhão',
      name: 'add_plot',
      desc: '',
      args: [],
    );
  }

  /// `Talhão`
  String get plot {
    return Intl.message('Talhão', name: 'plot', desc: '', args: []);
  }

  /// `Área (ha)`
  String get area_ha {
    return Intl.message('Área (ha)', name: 'area_ha', desc: '', args: []);
  }

  /// `Por favor, insira o nome da propriedade`
  String get enter_property_name {
    return Intl.message(
      'Por favor, insira o nome da propriedade',
      name: 'enter_property_name',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a área da propriedade`
  String get enter_property_area {
    return Intl.message(
      'Por favor, insira a área da propriedade',
      name: 'enter_property_area',
      desc: '',
      args: [],
    );
  }

  /// `Talhão adicionado com sucesso.`
  String get plot_added_successfully {
    return Intl.message(
      'Talhão adicionado com sucesso.',
      name: 'plot_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Talhão atualizado com sucesso.`
  String get plot_updated_successfully {
    return Intl.message(
      'Talhão atualizado com sucesso.',
      name: 'plot_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Talhão excluído com sucesso.`
  String get plot_deleted_successfully {
    return Intl.message(
      'Talhão excluído com sucesso.',
      name: 'plot_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para adicionar talhões nesta Propriedade Agrícola.`
  String get no_permission_to_add_plots {
    return Intl.message(
      'Você não tem permissão para adicionar talhões nesta Propriedade Agrícola.',
      name: 'no_permission_to_add_plots',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para editar talhões nesta Propriedade Agrícola.`
  String get no_permission_to_edit_plots {
    return Intl.message(
      'Você não tem permissão para editar talhões nesta Propriedade Agrícola.',
      name: 'no_permission_to_edit_plots',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para remover talhões nesta Propriedade Agrícola.`
  String get no_permission_to_delete_plots {
    return Intl.message(
      'Você não tem permissão para remover talhões nesta Propriedade Agrícola.',
      name: 'no_permission_to_delete_plots',
      desc: '',
      args: [],
    );
  }

  /// `Editar Talhão`
  String get edit_plot {
    return Intl.message('Editar Talhão', name: 'edit_plot', desc: '', args: []);
  }

  /// `Clique aqui para adicionar talhões à esta Propriedade Agrícola.`
  String get click_to_add_plot {
    return Intl.message(
      'Clique aqui para adicionar talhões à esta Propriedade Agrícola.',
      name: 'click_to_add_plot',
      desc: '',
      args: [],
    );
  }

  /// `Gerenciar Talhões`
  String get manage_plots {
    return Intl.message(
      'Gerenciar Talhões',
      name: 'manage_plots',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode gerenciar os talhões associados a esta atividade rural.`
  String get manage_plots_info {
    return Intl.message(
      'Aqui você pode gerenciar os talhões associados a esta atividade rural.',
      name: 'manage_plots_info',
      desc: '',
      args: [],
    );
  }

  /// `Modo de Movimentação de Estoque:\n\nAuto - Movimentação de Consumo de estoque no ato da entrada (compra).\nManual - Movimentação de consumo manual (saídas manuais).\nDesativado - Não movimenta estoque de entrada ou saída.`
  String get movement_mode_description {
    return Intl.message(
      'Modo de Movimentação de Estoque:\n\nAuto - Movimentação de Consumo de estoque no ato da entrada (compra).\nManual - Movimentação de consumo manual (saídas manuais).\nDesativado - Não movimenta estoque de entrada ou saída.',
      name: 'movement_mode_description',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Propriedade Agrícola`
  String get add_agricultural_property {
    return Intl.message(
      'Adicionar Propriedade Agrícola',
      name: 'add_agricultural_property',
      desc: '',
      args: [],
    );
  }

  /// `Editar Propriedade Agrícola`
  String get edit_agricultural_property {
    return Intl.message(
      'Editar Propriedade Agrícola',
      name: 'edit_agricultural_property',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados da Propriedade Agrícola.`
  String get edit_agricultural_property_info {
    return Intl.message(
      'Aqui você pode alterar dados da Propriedade Agrícola.',
      name: 'edit_agricultural_property_info',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira um nome válido e uma área maior que zero.`
  String get please_enter_valid_name_and_area {
    return Intl.message(
      'Por favor, insira um nome válido e uma área maior que zero.',
      name: 'please_enter_valid_name_and_area',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao adicionar talhão: {error}`
  String error_adding_plot(Object error) {
    return Intl.message(
      'Erro ao adicionar talhão: $error',
      name: 'error_adding_plot',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao atualizar talhão: {error}`
  String error_updating_plot(Object error) {
    return Intl.message(
      'Erro ao atualizar talhão: $error',
      name: 'error_updating_plot',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao excluir talhão: {error}`
  String error_deleting_plot(Object error) {
    return Intl.message(
      'Erro ao excluir talhão: $error',
      name: 'error_deleting_plot',
      desc: '',
      args: [error],
    );
  }

  /// `Importar Talhões`
  String get import_plots {
    return Intl.message(
      'Importar Talhões',
      name: 'import_plots',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar a propriedade: {error}`
  String error_saving_property(Object error) {
    return Intl.message(
      'Erro ao salvar a propriedade: $error',
      name: 'error_saving_property',
      desc: '',
      args: [error],
    );
  }

  /// `Importados {count} talhões com sucesso.`
  String plots_imported_successfully(Object count) {
    return Intl.message(
      'Importados $count talhões com sucesso.',
      name: 'plots_imported_successfully',
      desc: '',
      args: [count],
    );
  }

  /// `Nenhum talhão encontrado no arquivo selecionado.`
  String get no_plots_found_in_file {
    return Intl.message(
      'Nenhum talhão encontrado no arquivo selecionado.',
      name: 'no_plots_found_in_file',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao importar talhões: {error}`
  String error_importing_plots(Object error) {
    return Intl.message(
      'Erro ao importar talhões: $error',
      name: 'error_importing_plots',
      desc: '',
      args: [error],
    );
  }

  /// `Clique para importar talhões.`
  String get click_to_import_plots {
    return Intl.message(
      'Clique para importar talhões.',
      name: 'click_to_import_plots',
      desc: '',
      args: [],
    );
  }

  /// `Coordenadas`
  String get coordinates {
    return Intl.message('Coordenadas', name: 'coordinates', desc: '', args: []);
  }

  /// `Por favor, desenhe um polígono válido.`
  String get please_draw_a_valid_polygon {
    return Intl.message(
      'Por favor, desenhe um polígono válido.',
      name: 'please_draw_a_valid_polygon',
      desc: '',
      args: [],
    );
  }

  /// `Salvar Talhão`
  String get save_plot {
    return Intl.message('Salvar Talhão', name: 'save_plot', desc: '', args: []);
  }

  /// `Nome do Talhão`
  String get plot_name {
    return Intl.message(
      'Nome do Talhão',
      name: 'plot_name',
      desc: '',
      args: [],
    );
  }

  /// `Limpar Polígono`
  String get clear_polygon {
    return Intl.message(
      'Limpar Polígono',
      name: 'clear_polygon',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar a localização.`
  String get error_loading_location {
    return Intl.message(
      'Erro ao carregar a localização.',
      name: 'error_loading_location',
      desc: '',
      args: [],
    );
  }

  /// `Serviços de localização estão desativados.`
  String get location_services_disabled {
    return Intl.message(
      'Serviços de localização estão desativados.',
      name: 'location_services_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Permissão de localização negada.`
  String get location_permission_denied {
    return Intl.message(
      'Permissão de localização negada.',
      name: 'location_permission_denied',
      desc: '',
      args: [],
    );
  }

  /// `Permissão de localização negada permanentemente, não podemos solicitar permissões.`
  String get location_permission_denied_permanently {
    return Intl.message(
      'Permissão de localização negada permanentemente, não podemos solicitar permissões.',
      name: 'location_permission_denied_permanently',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o nome do talhão.`
  String get please_enter_plot_name {
    return Intl.message(
      'Por favor, insira o nome do talhão.',
      name: 'please_enter_plot_name',
      desc: '',
      args: [],
    );
  }

  /// `Defina o talhão no mapa.`
  String get define_plot_on_map {
    return Intl.message(
      'Defina o talhão no mapa.',
      name: 'define_plot_on_map',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira um nome, área e polígono válidos.`
  String get please_enter_valid_name_area_and_polygon {
    return Intl.message(
      'Por favor, insira um nome, área e polígono válidos.',
      name: 'please_enter_valid_name_area_and_polygon',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Item`
  String get add_item {
    return Intl.message('Adicionar Item', name: 'add_item', desc: '', args: []);
  }

  /// `Editar Item`
  String get edit_item {
    return Intl.message('Editar Item', name: 'edit_item', desc: '', args: []);
  }

  /// `Por favor, insira o Fator de Decaimento`
  String get enter_decay_factor {
    return Intl.message(
      'Por favor, insira o Fator de Decaimento',
      name: 'enter_decay_factor',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados do item.`
  String get edit_item_info {
    return Intl.message(
      'Aqui você pode alterar dados do item.',
      name: 'edit_item_info',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Pessoa`
  String get add_person {
    return Intl.message(
      'Adicionar Pessoa',
      name: 'add_person',
      desc: '',
      args: [],
    );
  }

  /// `Editar Pessoa`
  String get edit_person {
    return Intl.message(
      'Editar Pessoa',
      name: 'edit_person',
      desc: '',
      args: [],
    );
  }

  /// `CPF inválido`
  String get invalid_cpf {
    return Intl.message(
      'CPF inválido',
      name: 'invalid_cpf',
      desc: '',
      args: [],
    );
  }

  /// `CNPJ inválido`
  String get invalid_cnpj {
    return Intl.message(
      'CNPJ inválido',
      name: 'invalid_cnpj',
      desc: '',
      args: [],
    );
  }

  /// `Valor Total`
  String get total_value {
    return Intl.message('Valor Total', name: 'total_value', desc: '', args: []);
  }

  /// `Data`
  String get date {
    return Intl.message('Data', name: 'date', desc: '', args: []);
  }

  /// `Fornecedor Desconhecido`
  String get unknown_supplier {
    return Intl.message(
      'Fornecedor Desconhecido',
      name: 'unknown_supplier',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Compra`
  String get purchase_details {
    return Intl.message(
      'Detalhes da Compra',
      name: 'purchase_details',
      desc: '',
      args: [],
    );
  }

  /// `Itens da compra listados abaixo`
  String get purchase_items_listed {
    return Intl.message(
      'Itens da compra listados abaixo',
      name: 'purchase_items_listed',
      desc: '',
      args: [],
    );
  }

  /// `Dinheiro`
  String get cash {
    return Intl.message('Dinheiro', name: 'cash', desc: '', args: []);
  }

  /// `Cheque`
  String get check {
    return Intl.message('Cheque', name: 'check', desc: '', args: []);
  }

  /// `Pix/TED`
  String get pix {
    return Intl.message('Pix/TED', name: 'pix', desc: '', args: []);
  }

  /// `Boleto`
  String get bank_slip {
    return Intl.message('Boleto', name: 'bank_slip', desc: '', args: []);
  }

  /// `Cartão de Crédito`
  String get credit_card {
    return Intl.message(
      'Cartão de Crédito',
      name: 'credit_card',
      desc: '',
      args: [],
    );
  }

  /// `Cartão de Débito`
  String get debit_card {
    return Intl.message(
      'Cartão de Débito',
      name: 'debit_card',
      desc: '',
      args: [],
    );
  }

  /// `Outros`
  String get others {
    return Intl.message('Outros', name: 'others', desc: '', args: []);
  }

  /// `Parcelas da Compra`
  String get payment_details {
    return Intl.message(
      'Parcelas da Compra',
      name: 'payment_details',
      desc: '',
      args: [],
    );
  }

  /// `Preço Unitário`
  String get unit_price {
    return Intl.message(
      'Preço Unitário',
      name: 'unit_price',
      desc: '',
      args: [],
    );
  }

  /// `Valor da Parcela`
  String get payment_value {
    return Intl.message(
      'Valor da Parcela',
      name: 'payment_value',
      desc: '',
      args: [],
    );
  }

  /// `Vencimento`
  String get due_date {
    return Intl.message('Vencimento', name: 'due_date', desc: '', args: []);
  }

  /// `Meio de Pagamento`
  String get payment_method {
    return Intl.message(
      'Meio de Pagamento',
      name: 'payment_method',
      desc: '',
      args: [],
    );
  }

  /// `Origem do Pagamento`
  String get payment_origin {
    return Intl.message(
      'Origem do Pagamento',
      name: 'payment_origin',
      desc: '',
      args: [],
    );
  }

  /// `Parcela`
  String get payment {
    return Intl.message('Parcela', name: 'payment', desc: '', args: []);
  }

  /// `Seleção de Itens`
  String get item_selection {
    return Intl.message(
      'Seleção de Itens',
      name: 'item_selection',
      desc: '',
      args: [],
    );
  }

  /// `Pesquisar...`
  String get search_hint {
    return Intl.message(
      'Pesquisar...',
      name: 'search_hint',
      desc: '',
      args: [],
    );
  }

  /// `Ex.: 10`
  String get example_quantity_hint {
    return Intl.message(
      'Ex.: 10',
      name: 'example_quantity_hint',
      desc: '',
      args: [],
    );
  }

  /// `Ex.: 100.00`
  String get example_price_hint {
    return Intl.message(
      'Ex.: 100.00',
      name: 'example_price_hint',
      desc: '',
      args: [],
    );
  }

  /// `Número de Parcelas`
  String get number_of_installments {
    return Intl.message(
      'Número de Parcelas',
      name: 'number_of_installments',
      desc: '',
      args: [],
    );
  }

  /// `O valor total das parcelas não corresponde ao valor total da compra. Diferença identificada: {difference}. `
  String invalid_installments_total(Object difference) {
    return Intl.message(
      'O valor total das parcelas não corresponde ao valor total da compra. Diferença identificada: $difference. ',
      name: 'invalid_installments_total',
      desc: '',
      args: [difference],
    );
  }

  /// `Necessário informar um fornecedor.`
  String get supplier_required {
    return Intl.message(
      'Necessário informar um fornecedor.',
      name: 'supplier_required',
      desc: '',
      args: [],
    );
  }

  /// `Registrando compra...`
  String get registering_purchase {
    return Intl.message(
      'Registrando compra...',
      name: 'registering_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Clique para selecionar a compra`
  String get click_to_select_purchase {
    return Intl.message(
      'Clique para selecionar a compra',
      name: 'click_to_select_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver os detalhes da compra`
  String get click_to_view_purchase_details {
    return Intl.message(
      'Clique para ver os detalhes da compra',
      name: 'click_to_view_purchase_details',
      desc: '',
      args: [],
    );
  }

  /// `Clique para selecionar o fornecedor`
  String get click_to_select_supplier {
    return Intl.message(
      'Clique para selecionar o fornecedor',
      name: 'click_to_select_supplier',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a data da compra`
  String get select_purchase_date {
    return Intl.message(
      'Selecione a data da compra',
      name: 'select_purchase_date',
      desc: '',
      args: [],
    );
  }

  /// `Valor total da compra`
  String get total_value_of_purchase {
    return Intl.message(
      'Valor total da compra',
      name: 'total_value_of_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o meio de pagamento`
  String get select_payment_method {
    return Intl.message(
      'Selecione o meio de pagamento',
      name: 'select_payment_method',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a origem do recurso (próprio ou de terceiros)`
  String get select_payment_origin {
    return Intl.message(
      'Selecione a origem do recurso (próprio ou de terceiros)',
      name: 'select_payment_origin',
      desc: '',
      args: [],
    );
  }

  /// `Defina o número de parcelas`
  String get define_installments {
    return Intl.message(
      'Defina o número de parcelas',
      name: 'define_installments',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão as parcelas desta compra`
  String get manage_payments {
    return Intl.message(
      'Aqui estão as parcelas desta compra',
      name: 'manage_payments',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão os ítens desta compra`
  String get manage_items {
    return Intl.message(
      'Aqui estão os ítens desta compra',
      name: 'manage_items',
      desc: '',
      args: [],
    );
  }

  /// `Armazenar na Propriedade:`
  String get stock_property {
    return Intl.message(
      'Armazenar na Propriedade:',
      name: 'stock_property',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a unidade de medida`
  String get select_unit_measure {
    return Intl.message(
      'Selecione a unidade de medida',
      name: 'select_unit_measure',
      desc: '',
      args: [],
    );
  }

  /// `Clique para adicionar uma compra`
  String get click_to_add_purchase {
    return Intl.message(
      'Clique para adicionar uma compra',
      name: 'click_to_add_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Clique para adicionar um item`
  String get click_to_add_item {
    return Intl.message(
      'Clique para adicionar um item',
      name: 'click_to_add_item',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao registrar compra: {error}`
  String error_registering_purchase(Object error) {
    return Intl.message(
      'Erro ao registrar compra: $error',
      name: 'error_registering_purchase',
      desc: '',
      args: [error],
    );
  }

  /// `Dependências Encontradas`
  String get found_dependencies {
    return Intl.message(
      'Dependências Encontradas',
      name: 'found_dependencies',
      desc: '',
      args: [],
    );
  }

  /// `Foram encontradas dependências que serão excluídas:`
  String get found_dependencies_message {
    return Intl.message(
      'Foram encontradas dependências que serão excluídas:',
      name: 'found_dependencies_message',
      desc: '',
      args: [],
    );
  }

  /// `Tem certeza que deseja continuar? Esta ação não pode ser desfeita.`
  String get continue_deletion_warning {
    return Intl.message(
      'Tem certeza que deseja continuar? Esta ação não pode ser desfeita.',
      name: 'continue_deletion_warning',
      desc: '',
      args: [],
    );
  }

  /// `Confirmação Final`
  String get final_confirmation {
    return Intl.message(
      'Confirmação Final',
      name: 'final_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `Esta ação excluirá {collectionName} e todas as suas dependências permanentemente. Deseja continuar?`
  String final_confirmation_message(Object collectionName) {
    return Intl.message(
      'Esta ação excluirá $collectionName e todas as suas dependências permanentemente. Deseja continuar?',
      name: 'final_confirmation_message',
      desc: '',
      args: [collectionName],
    );
  }

  /// `Excluir Tudo`
  String get delete_all {
    return Intl.message('Excluir Tudo', name: 'delete_all', desc: '', args: []);
  }

  /// `{collectionName} e suas dependências excluídos com sucesso!`
  String delete_success(Object collectionName) {
    return Intl.message(
      '$collectionName e suas dependências excluídos com sucesso!',
      name: 'delete_success',
      desc: '',
      args: [collectionName],
    );
  }

  /// `Erro ao excluir {collectionName}: {error}`
  String delete_error(Object collectionName, Object error) {
    return Intl.message(
      'Erro ao excluir $collectionName: $error',
      name: 'delete_error',
      desc: '',
      args: [collectionName, error],
    );
  }

  /// `documentos`
  String get documents {
    return Intl.message('documentos', name: 'documents', desc: '', args: []);
  }

  /// `Comprado`
  String get purchased {
    return Intl.message('Comprado', name: 'purchased', desc: '', args: []);
  }

  /// `A Pagar`
  String get toPay {
    return Intl.message('A Pagar', name: 'toPay', desc: '', args: []);
  }

  /// `Valores`
  String get values {
    return Intl.message('Valores', name: 'values', desc: '', args: []);
  }

  /// `Comparativo de Gastos Mensais`
  String get comparisonOfMonthlyExpenses {
    return Intl.message(
      'Comparativo de Gastos Mensais',
      name: 'comparisonOfMonthlyExpenses',
      desc: '',
      args: [],
    );
  }

  /// `Itens Mais Comprados Este Mês`
  String get mostPurchasedItemsThisMonth {
    return Intl.message(
      'Itens Mais Comprados Este Mês',
      name: 'mostPurchasedItemsThisMonth',
      desc: '',
      args: [],
    );
  }

  /// `Total Gasto Este Mês em {currency}`
  String totalSpentThisMonth(Object currency) {
    return Intl.message(
      'Total Gasto Este Mês em $currency',
      name: 'totalSpentThisMonth',
      desc: '',
      args: [currency],
    );
  }

  /// `Nenhum registro de compra encontrado`
  String get no_purchase_records {
    return Intl.message(
      'Nenhum registro de compra encontrado',
      name: 'no_purchase_records',
      desc: '',
      args: [],
    );
  }

  /// `Talhão adicionado temporariamente.`
  String get plot_added_temporarily {
    return Intl.message(
      'Talhão adicionado temporariamente.',
      name: 'plot_added_temporarily',
      desc: '',
      args: [],
    );
  }

  /// `Talhão atualizado temporariamente.`
  String get plot_updated_temporarily {
    return Intl.message(
      'Talhão atualizado temporariamente.',
      name: 'plot_updated_temporarily',
      desc: '',
      args: [],
    );
  }

  /// `Talhão excluído temporariamente.`
  String get plot_deleted_temporarily {
    return Intl.message(
      'Talhão excluído temporariamente.',
      name: 'plot_deleted_temporarily',
      desc: '',
      args: [],
    );
  }

  /// `Talhão não encontrado.`
  String get plot_not_found {
    return Intl.message(
      'Talhão não encontrado.',
      name: 'plot_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Registros de Chuva`
  String get rain_records {
    return Intl.message(
      'Registros de Chuva',
      name: 'rain_records',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Chuva`
  String get rain_record {
    return Intl.message(
      'Registro de Chuva',
      name: 'rain_record',
      desc: '',
      args: [],
    );
  }

  /// `Propriedade Desconhecida`
  String get unknown_property {
    return Intl.message(
      'Propriedade Desconhecida',
      name: 'unknown_property',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade de Chuva`
  String get rain_quantity {
    return Intl.message(
      'Quantidade de Chuva',
      name: 'rain_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade de Chuva (mm)`
  String get rain_quantity_mm {
    return Intl.message(
      'Quantidade de Chuva (mm)',
      name: 'rain_quantity_mm',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Registro de Chuva`
  String get click_to_select_rain_record {
    return Intl.message(
      'Clique aqui para selecionar o Registro de Chuva',
      name: 'click_to_select_rain_record',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do Registro de Chuva`
  String get click_to_view_rain_record_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do Registro de Chuva',
      name: 'click_to_view_rain_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Chuva`
  String get rain_record_details {
    return Intl.message(
      'Registro de Chuva',
      name: 'rain_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Registro de Chuva`
  String get add_rain_record {
    return Intl.message(
      'Adicionar Registro de Chuva',
      name: 'add_rain_record',
      desc: '',
      args: [],
    );
  }

  /// `Editar Registro de Chuva`
  String get edit_rain_record {
    return Intl.message(
      'Editar Registro de Chuva',
      name: 'edit_rain_record',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a quantidade de chuva`
  String get enter_rain_quantity {
    return Intl.message(
      'Por favor, insira a quantidade de chuva',
      name: 'enter_rain_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade de chuva inválida`
  String get invalid_rain_quantity {
    return Intl.message(
      'Quantidade de chuva inválida',
      name: 'invalid_rain_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Data`
  String get select_date {
    return Intl.message(
      'Selecione a Data',
      name: 'select_date',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir`
  String get error_deleting {
    return Intl.message(
      'Erro ao excluir',
      name: 'error_deleting',
      desc: '',
      args: [],
    );
  }

  /// `Agro`
  String get agro {
    return Intl.message('Agro', name: 'agro', desc: '', args: []);
  }

  /// `Configurações Financeiras`
  String get financial_configurations {
    return Intl.message(
      'Configurações Financeiras',
      name: 'financial_configurations',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Configuração Financeira`
  String get add_financial_config {
    return Intl.message(
      'Adicionar Configuração Financeira',
      name: 'add_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Editar Configuração Financeira`
  String get edit_financial_config {
    return Intl.message(
      'Editar Configuração Financeira',
      name: 'edit_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Origem do Recurso`
  String get resource_origin {
    return Intl.message(
      'Origem do Recurso',
      name: 'resource_origin',
      desc: '',
      args: [],
    );
  }

  /// `Dia de Fechamento`
  String get closing_day {
    return Intl.message(
      'Dia de Fechamento',
      name: 'closing_day',
      desc: '',
      args: [],
    );
  }

  /// `Dia de Pagamento`
  String get payment_day {
    return Intl.message(
      'Dia de Pagamento',
      name: 'payment_day',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para adicionar configurações financeiras.`
  String get no_permission_to_add_financial_config {
    return Intl.message(
      'Você não tem permissão para adicionar configurações financeiras.',
      name: 'no_permission_to_add_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para editar esta configuração financeira.`
  String get no_permission_to_edit_financial_config {
    return Intl.message(
      'Você não tem permissão para editar esta configuração financeira.',
      name: 'no_permission_to_edit_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para excluir esta configuração financeira.`
  String get no_permission_to_delete_financial_config {
    return Intl.message(
      'Você não tem permissão para excluir esta configuração financeira.',
      name: 'no_permission_to_delete_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Configuração financeira adicionada com sucesso.`
  String get financial_config_added_successfully {
    return Intl.message(
      'Configuração financeira adicionada com sucesso.',
      name: 'financial_config_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Configuração financeira atualizada com sucesso.`
  String get financial_config_updated_successfully {
    return Intl.message(
      'Configuração financeira atualizada com sucesso.',
      name: 'financial_config_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Configuração financeira excluída com sucesso.`
  String get financial_config_deleted_successfully {
    return Intl.message(
      'Configuração financeira excluída com sucesso.',
      name: 'financial_config_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta configuração financeira?`
  String get confirm_delete_financial_config {
    return Intl.message(
      'Deseja realmente excluir esta configuração financeira?',
      name: 'confirm_delete_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode gerenciar as configurações financeiras para este Produtor Rural.`
  String get financial_config_tutorial {
    return Intl.message(
      'Aqui você pode gerenciar as configurações financeiras para este Produtor Rural.',
      name: 'financial_config_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para adicionar uma nova configuração financeira para este Produtor Rural.`
  String get click_to_add_financial_config {
    return Intl.message(
      'Clique aqui para adicionar uma nova configuração financeira para este Produtor Rural.',
      name: 'click_to_add_financial_config',
      desc: '',
      args: [],
    );
  }

  /// `Bancos`
  String get banks {
    return Intl.message('Bancos', name: 'banks', desc: '', args: []);
  }

  /// `Banco`
  String get bank {
    return Intl.message('Banco', name: 'bank', desc: '', args: []);
  }

  /// `Detalhes do Banco`
  String get bank_details {
    return Intl.message(
      'Detalhes do Banco',
      name: 'bank_details',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Banco`
  String get add_bank {
    return Intl.message(
      'Adicionar Banco',
      name: 'add_bank',
      desc: '',
      args: [],
    );
  }

  /// `Editar Banco`
  String get edit_bank {
    return Intl.message('Editar Banco', name: 'edit_bank', desc: '', args: []);
  }

  /// `Por favor, insira o nome do banco`
  String get enter_bank_name {
    return Intl.message(
      'Por favor, insira o nome do banco',
      name: 'enter_bank_name',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a sigla do país`
  String get enter_country_code {
    return Intl.message(
      'Por favor, insira a sigla do país',
      name: 'enter_country_code',
      desc: '',
      args: [],
    );
  }

  /// `Sigla do País`
  String get country_code {
    return Intl.message(
      'Sigla do País',
      name: 'country_code',
      desc: '',
      args: [],
    );
  }

  /// `Contas`
  String get accounts {
    return Intl.message('Contas', name: 'accounts', desc: '', args: []);
  }

  /// `Conta`
  String get account {
    return Intl.message('Conta', name: 'account', desc: '', args: []);
  }

  /// `Nome da Conta`
  String get account_name {
    return Intl.message(
      'Nome da Conta',
      name: 'account_name',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Conta`
  String get account_type {
    return Intl.message(
      'Tipo de Conta',
      name: 'account_type',
      desc: '',
      args: [],
    );
  }

  /// `Número da Conta`
  String get account_number {
    return Intl.message(
      'Número da Conta',
      name: 'account_number',
      desc: '',
      args: [],
    );
  }

  /// `Saldo Inicial`
  String get initial_balance {
    return Intl.message(
      'Saldo Inicial',
      name: 'initial_balance',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Conta`
  String get add_account {
    return Intl.message(
      'Adicionar Conta',
      name: 'add_account',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Banco`
  String get click_to_select_bank {
    return Intl.message(
      'Clique aqui para selecionar o Banco',
      name: 'click_to_select_bank',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do Banco`
  String get click_to_view_bank_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do Banco',
      name: 'click_to_view_bank_details',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão listadas as contas do banco.`
  String get bank_accounts_listed {
    return Intl.message(
      'Aqui estão listadas as contas do banco.',
      name: 'bank_accounts_listed',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados do Banco.`
  String get edit_bank_info {
    return Intl.message(
      'Aqui você pode alterar dados do Banco.',
      name: 'edit_bank_info',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode gerenciar as contas do banco.`
  String get manage_accounts_info {
    return Intl.message(
      'Aqui você pode gerenciar as contas do banco.',
      name: 'manage_accounts_info',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para adicionar contas ao Banco.`
  String get click_to_add_account {
    return Intl.message(
      'Clique aqui para adicionar contas ao Banco.',
      name: 'click_to_add_account',
      desc: '',
      args: [],
    );
  }

  /// `Contato`
  String get contact {
    return Intl.message('Contato', name: 'contact', desc: '', args: []);
  }

  /// `Conta Corrente`
  String get checking_account {
    return Intl.message(
      'Conta Corrente',
      name: 'checking_account',
      desc: '',
      args: [],
    );
  }

  /// `Conta Poupança`
  String get savings_account {
    return Intl.message(
      'Conta Poupança',
      name: 'savings_account',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver mais opções desta conta`
  String get click_to_see_more_options_on_first_account {
    return Intl.message(
      'Clique para ver mais opções desta conta',
      name: 'click_to_see_more_options_on_first_account',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Banco`
  String get select_bank {
    return Intl.message(
      'Selecionar Banco',
      name: 'select_bank',
      desc: '',
      args: [],
    );
  }

  /// `Bancos, Contas e Cartões`
  String get banks_icon {
    return Intl.message(
      'Bancos, Contas e Cartões',
      name: 'banks_icon',
      desc: '',
      args: [],
    );
  }

  /// `Conta de Pagamento`
  String get payment_account {
    return Intl.message(
      'Conta de Pagamento',
      name: 'payment_account',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Conta de Pagamento da Compra`
  String get select_payment_account {
    return Intl.message(
      'Selecione a Conta de Pagamento da Compra',
      name: 'select_payment_account',
      desc: '',
      args: [],
    );
  }

  /// `Por favor selecione o tipo de conta bancária`
  String get please_select_account_type {
    return Intl.message(
      'Por favor selecione o tipo de conta bancária',
      name: 'please_select_account_type',
      desc: '',
      args: [],
    );
  }

  /// `Número do Cartão`
  String get card_number {
    return Intl.message(
      'Número do Cartão',
      name: 'card_number',
      desc: '',
      args: [],
    );
  }

  /// `Bandeira do Cartão`
  String get card_brand {
    return Intl.message(
      'Bandeira do Cartão',
      name: 'card_brand',
      desc: '',
      args: [],
    );
  }

  /// `Limite de Crédito`
  String get credit_limit {
    return Intl.message(
      'Limite de Crédito',
      name: 'credit_limit',
      desc: '',
      args: [],
    );
  }

  /// `Data de Fechamento da Fatura`
  String get billing_closing_day {
    return Intl.message(
      'Data de Fechamento da Fatura',
      name: 'billing_closing_day',
      desc: '',
      args: [],
    );
  }

  /// `Data de Vencimento da Fatura`
  String get billing_due_day {
    return Intl.message(
      'Data de Vencimento da Fatura',
      name: 'billing_due_day',
      desc: '',
      args: [],
    );
  }

  /// `Editar Conta`
  String get edit_account {
    return Intl.message(
      'Editar Conta',
      name: 'edit_account',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para adicionar esta conta.`
  String get no_permission_to_add_accounts {
    return Intl.message(
      'Você não tem permissão para adicionar esta conta.',
      name: 'no_permission_to_add_accounts',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para editar esta conta.`
  String get no_permission_to_edit_accounts {
    return Intl.message(
      'Você não tem permissão para editar esta conta.',
      name: 'no_permission_to_edit_accounts',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para excluir esta conta.`
  String get no_permission_to_delete_accounts {
    return Intl.message(
      'Você não tem permissão para excluir esta conta.',
      name: 'no_permission_to_delete_accounts',
      desc: '',
      args: [],
    );
  }

  /// `Excluir Conta`
  String get delete_account {
    return Intl.message(
      'Excluir Conta',
      name: 'delete_account',
      desc: '',
      args: [],
    );
  }

  /// `Conta excluída temporariamente.`
  String get account_deleted_temporarily {
    return Intl.message(
      'Conta excluída temporariamente.',
      name: 'account_deleted_temporarily',
      desc: '',
      args: [],
    );
  }

  /// `Conta excluída com sucesso!`
  String get account_deleted_successfully {
    return Intl.message(
      'Conta excluída com sucesso!',
      name: 'account_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir a conta: {error}`
  String error_deleting_account(Object error) {
    return Intl.message(
      'Erro ao excluir a conta: $error',
      name: 'error_deleting_account',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao adicionar conta: {error}`
  String error_adding_account(Object error) {
    return Intl.message(
      'Erro ao adicionar conta: $error',
      name: 'error_adding_account',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao atualizar conta: {error}`
  String error_updating_account(Object error) {
    return Intl.message(
      'Erro ao atualizar conta: $error',
      name: 'error_updating_account',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para adicionar contas.`
  String get no_permission_to_add_accounts_plural {
    return Intl.message(
      'Você não tem permissão para adicionar contas.',
      name: 'no_permission_to_add_accounts_plural',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para editar contas.`
  String get no_permission_to_edit_accounts_plural {
    return Intl.message(
      'Você não tem permissão para editar contas.',
      name: 'no_permission_to_edit_accounts_plural',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para excluir contas.`
  String get no_permission_to_delete_accounts_plural {
    return Intl.message(
      'Você não tem permissão para excluir contas.',
      name: 'no_permission_to_delete_accounts_plural',
      desc: '',
      args: [],
    );
  }

  /// `O método de pagamento é obrigatório.`
  String get payment_account_required {
    return Intl.message(
      'O método de pagamento é obrigatório.',
      name: 'payment_account_required',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Coleta`
  String get collection_record_details {
    return Intl.message(
      'Registro de Coleta',
      name: 'collection_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Coleta`
  String get collection_record {
    return Intl.message(
      'Registro de Coleta',
      name: 'collection_record',
      desc: '',
      args: [],
    );
  }

  /// `Registros de Coleta`
  String get collection_records {
    return Intl.message(
      'Registros de Coleta',
      name: 'collection_records',
      desc: '',
      args: [],
    );
  }

  /// `Data da Coleta`
  String get collection_date {
    return Intl.message(
      'Data da Coleta',
      name: 'collection_date',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade de Caixas`
  String get quantity_boxes {
    return Intl.message(
      'Quantidade de Caixas',
      name: 'quantity_boxes',
      desc: '',
      args: [],
    );
  }

  /// `Peso Médio por Caixa`
  String get average_weight_box {
    return Intl.message(
      'Peso Médio por Caixa',
      name: 'average_weight_box',
      desc: '',
      args: [],
    );
  }

  /// `Peso Total`
  String get total_weight {
    return Intl.message('Peso Total', name: 'total_weight', desc: '', args: []);
  }

  /// `Registro de Entrega`
  String get delivery_record_details {
    return Intl.message(
      'Registro de Entrega',
      name: 'delivery_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Entrega`
  String get delivery_record {
    return Intl.message(
      'Registro de Entrega',
      name: 'delivery_record',
      desc: '',
      args: [],
    );
  }

  /// `Registros de Entrega`
  String get delivery_records {
    return Intl.message(
      'Registros de Entrega',
      name: 'delivery_records',
      desc: '',
      args: [],
    );
  }

  /// `Data da Entrega`
  String get delivery_date {
    return Intl.message(
      'Data da Entrega',
      name: 'delivery_date',
      desc: '',
      args: [],
    );
  }

  /// `Peso Total da Entrega`
  String get total_weight_delivery {
    return Intl.message(
      'Peso Total da Entrega',
      name: 'total_weight_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Peso do Produtor`
  String get producer_weight {
    return Intl.message(
      'Peso do Produtor',
      name: 'producer_weight',
      desc: '',
      args: [],
    );
  }

  /// `Valor Negociado por Kg`
  String get negotiated_value_per_kg {
    return Intl.message(
      'Valor Negociado por Kg',
      name: 'negotiated_value_per_kg',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Registro de Coleta`
  String get add_collection_record {
    return Intl.message(
      'Adicionar Registro de Coleta',
      name: 'add_collection_record',
      desc: '',
      args: [],
    );
  }

  /// `Editar Registro de Coleta`
  String get edit_collection_record {
    return Intl.message(
      'Editar Registro de Coleta',
      name: 'edit_collection_record',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Data da Coleta`
  String get select_collection_date {
    return Intl.message(
      'Selecione a Data da Coleta',
      name: 'select_collection_date',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a quantidade de caixas`
  String get enter_number_of_boxes {
    return Intl.message(
      'Por favor, insira a quantidade de caixas',
      name: 'enter_number_of_boxes',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o peso médio por caixa`
  String get enter_average_weight_per_box {
    return Intl.message(
      'Por favor, insira o peso médio por caixa',
      name: 'enter_average_weight_per_box',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o peso total`
  String get enter_total_weight {
    return Intl.message(
      'Por favor, insira o peso total',
      name: 'enter_total_weight',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Registro de Entrega`
  String get add_delivery_record {
    return Intl.message(
      'Adicionar Registro de Entrega',
      name: 'add_delivery_record',
      desc: '',
      args: [],
    );
  }

  /// `Editar Registro de Entrega`
  String get edit_delivery_record {
    return Intl.message(
      'Editar Registro de Entrega',
      name: 'edit_delivery_record',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Data da Entrega`
  String get select_delivery_date {
    return Intl.message(
      'Selecione a Data da Entrega',
      name: 'select_delivery_date',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o peso total da entrega`
  String get enter_total_delivery_weight {
    return Intl.message(
      'Por favor, insira o peso total da entrega',
      name: 'enter_total_delivery_weight',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o peso do produtor`
  String get enter_producer_weight {
    return Intl.message(
      'Por favor, insira o peso do produtor',
      name: 'enter_producer_weight',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o valor negociado por Kg`
  String get enter_negotiated_value_per_kg {
    return Intl.message(
      'Por favor, insira o valor negociado por Kg',
      name: 'enter_negotiated_value_per_kg',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Registro de Coleta.`
  String get click_to_select_collection_record {
    return Intl.message(
      'Clique aqui para selecionar o Registro de Coleta.',
      name: 'click_to_select_collection_record',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do Registro de Coleta.`
  String get click_to_view_collection_record_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do Registro de Coleta.',
      name: 'click_to_view_collection_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Registro de Entrega.`
  String get click_to_select_delivery_record {
    return Intl.message(
      'Clique aqui para selecionar o Registro de Entrega.',
      name: 'click_to_select_delivery_record',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do Registro de Entrega.`
  String get click_to_view_delivery_record_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do Registro de Entrega.',
      name: 'click_to_view_delivery_record_details',
      desc: '',
      args: [],
    );
  }

  /// `Coletas de Borracha`
  String get rubber_collections {
    return Intl.message(
      'Coletas de Borracha',
      name: 'rubber_collections',
      desc: '',
      args: [],
    );
  }

  /// `Entrega de Borracha`
  String get rubber_delivery {
    return Intl.message(
      'Entrega de Borracha',
      name: 'rubber_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Sangrador`
  String get bleeder {
    return Intl.message('Sangrador', name: 'bleeder', desc: '', args: []);
  }

  /// `Peso do Sangrador`
  String get bleeder_weight {
    return Intl.message(
      'Peso do Sangrador',
      name: 'bleeder_weight',
      desc: '',
      args: [],
    );
  }

  /// `Comprador`
  String get buyer {
    return Intl.message('Comprador', name: 'buyer', desc: '', args: []);
  }

  /// `Data Prevista de Recebimento`
  String get expected_receipt_date {
    return Intl.message(
      'Data Prevista de Recebimento',
      name: 'expected_receipt_date',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade Paga`
  String get quantity_already_received {
    return Intl.message(
      'Quantidade Paga',
      name: 'quantity_already_received',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver mais opções deste talhão`
  String get click_to_see_more_options_on_first_plot {
    return Intl.message(
      'Clique para ver mais opções deste talhão',
      name: 'click_to_see_more_options_on_first_plot',
      desc: '',
      args: [],
    );
  }

  /// `Clique para editar este talhão`
  String get click_to_edit_first_plot {
    return Intl.message(
      'Clique para editar este talhão',
      name: 'click_to_edit_first_plot',
      desc: '',
      args: [],
    );
  }

  /// `Clique para excluir este talhão`
  String get click_to_delete_first_plot {
    return Intl.message(
      'Clique para excluir este talhão',
      name: 'click_to_delete_first_plot',
      desc: '',
      args: [],
    );
  }

  /// `Valor do Produtor`
  String get producer_value {
    return Intl.message(
      'Valor do Produtor',
      name: 'producer_value',
      desc: '',
      args: [],
    );
  }

  /// `Relatório Financeiro`
  String get financial_report {
    return Intl.message(
      'Relatório Financeiro',
      name: 'financial_report',
      desc: '',
      args: [],
    );
  }

  /// `Despesas Mensais`
  String get monthly_expenses {
    return Intl.message(
      'Despesas Mensais',
      name: 'monthly_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Principais Itens Comprados`
  String get top_expenses {
    return Intl.message(
      'Principais Itens Comprados',
      name: 'top_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Gráfico de despesas mensais`
  String get monthly_expenses_graph {
    return Intl.message(
      'Gráfico de despesas mensais',
      name: 'monthly_expenses_graph',
      desc: '',
      args: [],
    );
  }

  /// `Gráfico de principais despesas`
  String get top_expenses_graph {
    return Intl.message(
      'Gráfico de principais despesas',
      name: 'top_expenses_graph',
      desc: '',
      args: [],
    );
  }

  /// `Mês de Referência`
  String get referenceMonth {
    return Intl.message(
      'Mês de Referência',
      name: 'referenceMonth',
      desc: '',
      args: [],
    );
  }

  /// `Alterar`
  String get change {
    return Intl.message('Alterar', name: 'change', desc: '', args: []);
  }

  /// `Selecione o Mês`
  String get selectMonth {
    return Intl.message(
      'Selecione o Mês',
      name: 'selectMonth',
      desc: '',
      args: [],
    );
  }

  /// `Total a Pagar por Conta de Pagamento`
  String get total_payments_by_account {
    return Intl.message(
      'Total a Pagar por Conta de Pagamento',
      name: 'total_payments_by_account',
      desc: '',
      args: [],
    );
  }

  /// `Conta Desconhecida`
  String get unknown_payment_account {
    return Intl.message(
      'Conta Desconhecida',
      name: 'unknown_payment_account',
      desc: '',
      args: [],
    );
  }

  /// `Total a Pagar por Conta de Pagamento`
  String get total_payments_by_account_label {
    return Intl.message(
      'Total a Pagar por Conta de Pagamento',
      name: 'total_payments_by_account_label',
      desc: '',
      args: [],
    );
  }

  /// `Esta ação irá excluir o produtor e todas as suas informações associadas. O aplicativo será encerrado. Por favor, abra novamente o aplicativo se necessário.`
  String get produtor_deletion_warning {
    return Intl.message(
      'Esta ação irá excluir o produtor e todas as suas informações associadas. O aplicativo será encerrado. Por favor, abra novamente o aplicativo se necessário.',
      name: 'produtor_deletion_warning',
      desc: '',
      args: [],
    );
  }

  /// `Carro`
  String get car {
    return Intl.message('Carro', name: 'car', desc: '', args: []);
  }

  /// `Caminhonete`
  String get pickup_truck {
    return Intl.message(
      'Caminhonete',
      name: 'pickup_truck',
      desc: '',
      args: [],
    );
  }

  /// `Caminhão`
  String get truck {
    return Intl.message('Caminhão', name: 'truck', desc: '', args: []);
  }

  /// `Trator`
  String get tractor {
    return Intl.message('Trator', name: 'tractor', desc: '', args: []);
  }

  /// `Colheitadeira`
  String get harvester {
    return Intl.message('Colheitadeira', name: 'harvester', desc: '', args: []);
  }

  /// `Pulverizador Autopropelido`
  String get self_propelled_sprayer {
    return Intl.message(
      'Pulverizador Autopropelido',
      name: 'self_propelled_sprayer',
      desc: '',
      args: [],
    );
  }

  /// `Adubador Autopropelido`
  String get self_propelled_fertilizer {
    return Intl.message(
      'Adubador Autopropelido',
      name: 'self_propelled_fertilizer',
      desc: '',
      args: [],
    );
  }

  /// `Outros`
  String get other {
    return Intl.message('Outros', name: 'other', desc: '', args: []);
  }

  /// `Preparo de Solo`
  String get soil_preparation {
    return Intl.message(
      'Preparo de Solo',
      name: 'soil_preparation',
      desc: '',
      args: [],
    );
  }

  /// `Pré-Plantio`
  String get pre_planting {
    return Intl.message(
      'Pré-Plantio',
      name: 'pre_planting',
      desc: '',
      args: [],
    );
  }

  /// `Plantio`
  String get planting {
    return Intl.message('Plantio', name: 'planting', desc: '', args: []);
  }

  /// `Pós-Plantio`
  String get post_planting {
    return Intl.message(
      'Pós-Plantio',
      name: 'post_planting',
      desc: '',
      args: [],
    );
  }

  /// `Fertilização`
  String get fertilization {
    return Intl.message(
      'Fertilização',
      name: 'fertilization',
      desc: '',
      args: [],
    );
  }

  /// `Pulverização`
  String get spraying {
    return Intl.message('Pulverização', name: 'spraying', desc: '', args: []);
  }

  /// `Safra`
  String get harvest {
    return Intl.message('Safra', name: 'harvest', desc: '', args: []);
  }

  /// `Colheita`
  String get type_harvest {
    return Intl.message('Colheita', name: 'type_harvest', desc: '', args: []);
  }

  /// `Confinamento de Gado`
  String get cattle_confinement {
    return Intl.message(
      'Confinamento de Gado',
      name: 'cattle_confinement',
      desc: '',
      args: [],
    );
  }

  /// `Engorda de Frangos`
  String get chicken_fattening {
    return Intl.message(
      'Engorda de Frangos',
      name: 'chicken_fattening',
      desc: '',
      args: [],
    );
  }

  /// `Engorda de Peixes`
  String get fish_fattening {
    return Intl.message(
      'Engorda de Peixes',
      name: 'fish_fattening',
      desc: '',
      args: [],
    );
  }

  /// `Pecuária`
  String get cattle_rearing {
    return Intl.message('Pecuária', name: 'cattle_rearing', desc: '', args: []);
  }

  /// `Produção de Leite`
  String get milk_production {
    return Intl.message(
      'Produção de Leite',
      name: 'milk_production',
      desc: '',
      args: [],
    );
  }

  /// `Outras Atividades`
  String get other_activities {
    return Intl.message(
      'Outras Atividades',
      name: 'other_activities',
      desc: '',
      args: [],
    );
  }

  /// `Atividades Rurais`
  String get rural_activities {
    return Intl.message(
      'Atividades Rurais',
      name: 'rural_activities',
      desc: '',
      args: [],
    );
  }

  /// `Atividade Rural`
  String get rural_activity {
    return Intl.message(
      'Atividade Rural',
      name: 'rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Atividade Rural`
  String get add_rural_activity {
    return Intl.message(
      'Adicionar Atividade Rural',
      name: 'add_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Editar Atividade Rural`
  String get edit_rural_activity {
    return Intl.message(
      'Editar Atividade Rural',
      name: 'edit_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a descrição`
  String get enter_description {
    return Intl.message(
      'Por favor, insira a descrição',
      name: 'enter_description',
      desc: '',
      args: [],
    );
  }

  /// `Data de Início`
  String get start_date {
    return Intl.message(
      'Data de Início',
      name: 'start_date',
      desc: '',
      args: [],
    );
  }

  /// `Data de Fim`
  String get end_date {
    return Intl.message('Data de Fim', name: 'end_date', desc: '', args: []);
  }

  /// `Tipo de Atividade`
  String get activity_type {
    return Intl.message(
      'Tipo de Atividade',
      name: 'activity_type',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione o tipo de atividade.`
  String get select_activity_type {
    return Intl.message(
      'Por favor, selecione o tipo de atividade.',
      name: 'select_activity_type',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira datas válidas`
  String get enter_valid_dates {
    return Intl.message(
      'Por favor, insira datas válidas',
      name: 'enter_valid_dates',
      desc: '',
      args: [],
    );
  }

  /// `Clique para adicionar uma Atividade Rural`
  String get click_to_add_rural_activity {
    return Intl.message(
      'Clique para adicionar uma Atividade Rural',
      name: 'click_to_add_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Clique para editar esta Atividade Rural`
  String get click_to_edit_rural_activity {
    return Intl.message(
      'Clique para editar esta Atividade Rural',
      name: 'click_to_edit_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Clique para excluir esta Atividade Rural`
  String get click_to_delete_rural_activity {
    return Intl.message(
      'Clique para excluir esta Atividade Rural',
      name: 'click_to_delete_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Atividade Rural`
  String get rural_activity_details {
    return Intl.message(
      'Detalhes da Atividade Rural',
      name: 'rural_activity_details',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para adicionar atividades rurais.`
  String get no_permission_to_add_rural_activities {
    return Intl.message(
      'Você não tem permissão para adicionar atividades rurais.',
      name: 'no_permission_to_add_rural_activities',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para editar atividades rurais.`
  String get no_permission_to_edit_rural_activities {
    return Intl.message(
      'Você não tem permissão para editar atividades rurais.',
      name: 'no_permission_to_edit_rural_activities',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para excluir atividades rurais.`
  String get no_permission_to_delete_rural_activities {
    return Intl.message(
      'Você não tem permissão para excluir atividades rurais.',
      name: 'no_permission_to_delete_rural_activities',
      desc: '',
      args: [],
    );
  }

  /// `Atividade salva com sucesso`
  String get activity_saved_successfully {
    return Intl.message(
      'Atividade salva com sucesso',
      name: 'activity_saved_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar a atividade: {error}`
  String error_saving_activity(Object error) {
    return Intl.message(
      'Erro ao salvar a atividade: $error',
      name: 'error_saving_activity',
      desc: '',
      args: [error],
    );
  }

  /// `Nenhuma atividade rural encontrada`
  String get no_rural_activities_found {
    return Intl.message(
      'Nenhuma atividade rural encontrada',
      name: 'no_rural_activities_found',
      desc: '',
      args: [],
    );
  }

  /// `Gerenciar Atividades Rurais`
  String get manage_rural_activities {
    return Intl.message(
      'Gerenciar Atividades Rurais',
      name: 'manage_rural_activities',
      desc: '',
      args: [],
    );
  }

  /// `Selecione uma Atividade Rural`
  String get select_rural_activity {
    return Intl.message(
      'Selecione uma Atividade Rural',
      name: 'select_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Ver Detalhes da Atividade Rural`
  String get view_rural_activity_details {
    return Intl.message(
      'Ver Detalhes da Atividade Rural',
      name: 'view_rural_activity_details',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta atividade rural?`
  String get confirm_deletion_of_rural_activity {
    return Intl.message(
      'Deseja realmente excluir esta atividade rural?',
      name: 'confirm_deletion_of_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Exclusão da Atividade`
  String get confirm_activity_deletion {
    return Intl.message(
      'Confirmar Exclusão da Atividade',
      name: 'confirm_activity_deletion',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver os detalhes da atividade`
  String get click_to_view_activity_details {
    return Intl.message(
      'Clique para ver os detalhes da atividade',
      name: 'click_to_view_activity_details',
      desc: '',
      args: [],
    );
  }

  /// `Selecione ou cadastre uma atividade rural`
  String get select_or_register_activity {
    return Intl.message(
      'Selecione ou cadastre uma atividade rural',
      name: 'select_or_register_activity',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes`
  String get details {
    return Intl.message('Detalhes', name: 'details', desc: '', args: []);
  }

  /// `Selecionar Atividade`
  String get select_activity {
    return Intl.message(
      'Selecionar Atividade',
      name: 'select_activity',
      desc: '',
      args: [],
    );
  }

  /// `Clique para selecionar a atividade rural`
  String get click_to_select_activity {
    return Intl.message(
      'Clique para selecionar a atividade rural',
      name: 'click_to_select_activity',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma descrição disponível`
  String get no_description {
    return Intl.message(
      'Nenhuma descrição disponível',
      name: 'no_description',
      desc: '',
      args: [],
    );
  }

  /// `Sem data de início`
  String get no_start_date {
    return Intl.message(
      'Sem data de início',
      name: 'no_start_date',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados da Atividade Rural.`
  String get edit_rural_activity_info {
    return Intl.message(
      'Aqui você pode alterar dados da Atividade Rural.',
      name: 'edit_rural_activity_info',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Talhão`
  String get add_plot_dialog_title {
    return Intl.message(
      'Adicionar Talhão',
      name: 'add_plot_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Editar Talhão`
  String get edit_plot_dialog_title {
    return Intl.message(
      'Editar Talhão',
      name: 'edit_plot_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o Talhão`
  String get select_plot {
    return Intl.message(
      'Selecione o Talhão',
      name: 'select_plot',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Talhão`
  String get click_to_select_plot {
    return Intl.message(
      'Clique aqui para selecionar o Talhão',
      name: 'click_to_select_plot',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do Talhão`
  String get click_to_view_plot_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do Talhão',
      name: 'click_to_view_plot_details',
      desc: '',
      args: [],
    );
  }

  /// `Selecione ou cadastre um talhão.`
  String get select_or_register_plot {
    return Intl.message(
      'Selecione ou cadastre um talhão.',
      name: 'select_or_register_plot',
      desc: '',
      args: [],
    );
  }

  /// `Atividade atualizada com sucesso`
  String get activity_updated_successfully {
    return Intl.message(
      'Atividade atualizada com sucesso',
      name: 'activity_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione uma data de início`
  String get select_start_date {
    return Intl.message(
      'Por favor, selecione uma data de início',
      name: 'select_start_date',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar talhões`
  String get error_loading_plots {
    return Intl.message(
      'Erro ao carregar talhões',
      name: 'error_loading_plots',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum talhão selecionado`
  String get no_plots_selected {
    return Intl.message(
      'Nenhum talhão selecionado',
      name: 'no_plots_selected',
      desc: '',
      args: [],
    );
  }

  /// `Talhões atualizados com sucesso`
  String get plots_updated_successfully {
    return Intl.message(
      'Talhões atualizados com sucesso',
      name: 'plots_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Descrição da seção de talhões.`
  String get plots_section_description {
    return Intl.message(
      'Descrição da seção de talhões.',
      name: 'plots_section_description',
      desc: '',
      args: [],
    );
  }

  /// `Lat`
  String get latitude {
    return Intl.message('Lat', name: 'latitude', desc: '', args: []);
  }

  /// `Lon`
  String get longitude {
    return Intl.message('Lon', name: 'longitude', desc: '', args: []);
  }

  /// `Gerencie seus talhões.`
  String get manage_your_plots {
    return Intl.message(
      'Gerencie seus talhões.',
      name: 'manage_your_plots',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Talhão`
  String get select_talhao {
    return Intl.message(
      'Selecionar Talhão',
      name: 'select_talhao',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o talhão.`
  String get click_to_select_talhao {
    return Intl.message(
      'Clique aqui para selecionar o talhão.',
      name: 'click_to_select_talhao',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes do talhão.`
  String get click_to_view_talhao_details {
    return Intl.message(
      'Clique aqui para ver os detalhes do talhão.',
      name: 'click_to_view_talhao_details',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Talhão`
  String get talhao_details {
    return Intl.message(
      'Detalhes do Talhão',
      name: 'talhao_details',
      desc: '',
      args: [],
    );
  }

  /// `Ver Detalhes`
  String get view_details {
    return Intl.message(
      'Ver Detalhes',
      name: 'view_details',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Seleção`
  String get confirm_selection {
    return Intl.message(
      'Confirmar Seleção',
      name: 'confirm_selection',
      desc: '',
      args: [],
    );
  }

  /// `Talhões vinculados com sucesso`
  String get plots_linked_successfully {
    return Intl.message(
      'Talhões vinculados com sucesso',
      name: 'plots_linked_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Vincular Talhão`
  String get link_plot {
    return Intl.message(
      'Vincular Talhão',
      name: 'link_plot',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum talhão vinculado`
  String get no_plots_linked {
    return Intl.message(
      'Nenhum talhão vinculado',
      name: 'no_plots_linked',
      desc: '',
      args: [],
    );
  }

  /// `Talhão removido da atividade`
  String get plot_removed_from_activity {
    return Intl.message(
      'Talhão removido da atividade',
      name: 'plot_removed_from_activity',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao vincular talhões`
  String get error_linking_plots {
    return Intl.message(
      'Erro ao vincular talhões',
      name: 'error_linking_plots',
      desc: '',
      args: [],
    );
  }

  /// `Talhão removido com sucesso`
  String get plot_removed_successfully {
    return Intl.message(
      'Talhão removido com sucesso',
      name: 'plot_removed_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover talhão`
  String get error_removing_plot {
    return Intl.message(
      'Erro ao remover talhão',
      name: 'error_removing_plot',
      desc: '',
      args: [],
    );
  }

  /// `Operações Rurais`
  String get rural_operations {
    return Intl.message(
      'Operações Rurais',
      name: 'rural_operations',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma operação rural encontrada`
  String get no_operations_found {
    return Intl.message(
      'Nenhuma operação rural encontrada',
      name: 'no_operations_found',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Operação Rural`
  String get add_rural_operation {
    return Intl.message(
      'Adicionar Operação Rural',
      name: 'add_rural_operation',
      desc: '',
      args: [],
    );
  }

  /// `Editar Operação Rural`
  String get edit_rural_operation {
    return Intl.message(
      'Editar Operação Rural',
      name: 'edit_rural_operation',
      desc: '',
      args: [],
    );
  }

  /// `Operação Rural`
  String get rural_operation {
    return Intl.message(
      'Operação Rural',
      name: 'rural_operation',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Operação`
  String get operation_type {
    return Intl.message(
      'Tipo de Operação',
      name: 'operation_type',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o tipo de operação`
  String get select_operation_type {
    return Intl.message(
      'Selecione o tipo de operação',
      name: 'select_operation_type',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a área`
  String get enter_area {
    return Intl.message(
      'Por favor, insira a área',
      name: 'enter_area',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar a operação rural: {error}`
  String error_saving_rural_operation(Object error) {
    return Intl.message(
      'Erro ao salvar a operação rural: $error',
      name: 'error_saving_rural_operation',
      desc: '',
      args: [error],
    );
  }

  /// `Aqui você pode alterar dados da Operação Rural.`
  String get edit_rural_operation_info {
    return Intl.message(
      'Aqui você pode alterar dados da Operação Rural.',
      name: 'edit_rural_operation_info',
      desc: '',
      args: [],
    );
  }

  /// `Talhão removido da operação`
  String get plot_removed_from_operation {
    return Intl.message(
      'Talhão removido da operação',
      name: 'plot_removed_from_operation',
      desc: '',
      args: [],
    );
  }

  /// `Atividade rural excluída com sucesso`
  String get activity_deleted_successfully {
    return Intl.message(
      'Atividade rural excluída com sucesso',
      name: 'activity_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir a atividade rural`
  String get error_deleting_activity {
    return Intl.message(
      'Erro ao excluir a atividade rural',
      name: 'error_deleting_activity',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta operação rural?`
  String get confirm_delete_rural_operation {
    return Intl.message(
      'Deseja realmente excluir esta operação rural?',
      name: 'confirm_delete_rural_operation',
      desc: '',
      args: [],
    );
  }

  /// `Operação rural excluída com sucesso`
  String get operation_deleted_successfully {
    return Intl.message(
      'Operação rural excluída com sucesso',
      name: 'operation_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir a operação rural`
  String get error_deleting_operation {
    return Intl.message(
      'Erro ao excluir a operação rural',
      name: 'error_deleting_operation',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver mais opções desta operação`
  String get click_to_see_more_options_on_first_operation {
    return Intl.message(
      'Clique para ver mais opções desta operação',
      name: 'click_to_see_more_options_on_first_operation',
      desc: '',
      args: [],
    );
  }

  /// `Talhões vinculados a esta atividade rural`
  String get plots_linked_to_activity {
    return Intl.message(
      'Talhões vinculados a esta atividade rural',
      name: 'plots_linked_to_activity',
      desc: '',
      args: [],
    );
  }

  /// `Operações desta atividade rural`
  String get operations_of_activity {
    return Intl.message(
      'Operações desta atividade rural',
      name: 'operations_of_activity',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma operação rural registrada`
  String get no_operations_registered {
    return Intl.message(
      'Nenhuma operação rural registrada',
      name: 'no_operations_registered',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Operação`
  String get add_operation {
    return Intl.message(
      'Adicionar Operação',
      name: 'add_operation',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta atividade rural?`
  String get confirm_delete_rural_activity {
    return Intl.message(
      'Deseja realmente excluir esta atividade rural?',
      name: 'confirm_delete_rural_activity',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Tipo de Operação Rural`
  String get tipo_operacao_rural_details {
    return Intl.message(
      'Detalhes do Tipo de Operação Rural',
      name: 'tipo_operacao_rural_details',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Operação Rural`
  String get tipo_operacao_rural {
    return Intl.message(
      'Tipo de Operação Rural',
      name: 'tipo_operacao_rural',
      desc: '',
      args: [],
    );
  }

  /// `Tipos de Operações Rurais`
  String get tipos_operacoes_rurais {
    return Intl.message(
      'Tipos de Operações Rurais',
      name: 'tipos_operacoes_rurais',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Tipo de Operação Rural`
  String get add_tipo_operacao {
    return Intl.message(
      'Adicionar Tipo de Operação Rural',
      name: 'add_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Editar Tipo de Operação Rural`
  String get edit_tipo_operacao {
    return Intl.message(
      'Editar Tipo de Operação Rural',
      name: 'edit_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Remover Tipo de Operação Rural`
  String get remove_tipo_operacao {
    return Intl.message(
      'Remover Tipo de Operação Rural',
      name: 'remove_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar o Tipo de Operação Rural.`
  String get click_to_select_tipo_operacao {
    return Intl.message(
      'Clique aqui para selecionar o Tipo de Operação Rural.',
      name: 'click_to_select_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para exibir detalhes do Tipo de Operação Rural.`
  String get click_to_view_tipo_operacao_details {
    return Intl.message(
      'Clique aqui para exibir detalhes do Tipo de Operação Rural.',
      name: 'click_to_view_tipo_operacao_details',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar tipos de operações rurais`
  String get error_loading_tipos_operacoes {
    return Intl.message(
      'Erro ao carregar tipos de operações rurais',
      name: 'error_loading_tipos_operacoes',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir este Tipo de Operação Rural?`
  String get confirm_deletion_tipo_operacao {
    return Intl.message(
      'Deseja realmente excluir este Tipo de Operação Rural?',
      name: 'confirm_deletion_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Aqui estão os dados relacionados a este Tipo de Operação Rural.`
  String get tipo_operacao_related_data {
    return Intl.message(
      'Aqui estão os dados relacionados a este Tipo de Operação Rural.',
      name: 'tipo_operacao_related_data',
      desc: '',
      args: [],
    );
  }

  /// `Dados Relacionados`
  String get related_data {
    return Intl.message(
      'Dados Relacionados',
      name: 'related_data',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum dado relacionado encontrado.`
  String get no_related_data_found {
    return Intl.message(
      'Nenhum dado relacionado encontrado.',
      name: 'no_related_data_found',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Operação Rural salvo com sucesso.`
  String get tipo_operacao_rural_saved_successfully {
    return Intl.message(
      'Tipo de Operação Rural salvo com sucesso.',
      name: 'tipo_operacao_rural_saved_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar o Tipo de Operação Rural: {error}`
  String error_saving_tipo_operacao_rural(Object error) {
    return Intl.message(
      'Erro ao salvar o Tipo de Operação Rural: $error',
      name: 'error_saving_tipo_operacao_rural',
      desc: '',
      args: [error],
    );
  }

  /// `Categoria`
  String get categoria {
    return Intl.message('Categoria', name: 'categoria', desc: '', args: []);
  }

  /// `Selecione a Categoria`
  String get select_categoria {
    return Intl.message(
      'Selecione a Categoria',
      name: 'select_categoria',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Categoria`
  String get add_categoria {
    return Intl.message(
      'Adicionar Categoria',
      name: 'add_categoria',
      desc: '',
      args: [],
    );
  }

  /// `Editar Categoria`
  String get edit_categoria {
    return Intl.message(
      'Editar Categoria',
      name: 'edit_categoria',
      desc: '',
      args: [],
    );
  }

  /// `Remover Categoria`
  String get remove_categoria {
    return Intl.message(
      'Remover Categoria',
      name: 'remove_categoria',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a categoria`
  String get enter_categoria {
    return Intl.message(
      'Por favor, insira a categoria',
      name: 'enter_categoria',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para editar o Tipo de Operação Rural.`
  String get click_to_edit_tipo_operacao {
    return Intl.message(
      'Clique aqui para editar o Tipo de Operação Rural.',
      name: 'click_to_edit_tipo_operacao',
      desc: '',
      args: [],
    );
  }

  /// `Fase`
  String get fase {
    return Intl.message('Fase', name: 'fase', desc: '', args: []);
  }

  /// `Selecione a Fase da Operação`
  String get select_operation_phase {
    return Intl.message(
      'Selecione a Fase da Operação',
      name: 'select_operation_phase',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Operação`
  String get select_operation {
    return Intl.message(
      'Selecionar Operação',
      name: 'select_operation',
      desc: '',
      args: [],
    );
  }

  /// `Clique para selecionar a operação`
  String get click_to_select_operation {
    return Intl.message(
      'Clique para selecionar a operação',
      name: 'click_to_select_operation',
      desc: '',
      args: [],
    );
  }

  /// `Clique para ver os detalhes da operação`
  String get click_to_view_operation_details {
    return Intl.message(
      'Clique para ver os detalhes da operação',
      name: 'click_to_view_operation_details',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar dados do Tipo de Operação Rural`
  String get edit_tipo_operacao_info {
    return Intl.message(
      'Aqui você pode alterar dados do Tipo de Operação Rural',
      name: 'edit_tipo_operacao_info',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Operação Rural excluído com sucesso`
  String get tipo_operacao_rural_deleted_successfully {
    return Intl.message(
      'Tipo de Operação Rural excluído com sucesso',
      name: 'tipo_operacao_rural_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir o Tipo de Operação Rural`
  String get error_deleting_tipo_operacao_rural {
    return Intl.message(
      'Erro ao excluir o Tipo de Operação Rural',
      name: 'error_deleting_tipo_operacao_rural',
      desc: '',
      args: [],
    );
  }

  /// `Agricultura`
  String get agriculture {
    return Intl.message('Agricultura', name: 'agriculture', desc: '', args: []);
  }

  /// `Avicultura`
  String get poultry_farming {
    return Intl.message(
      'Avicultura',
      name: 'poultry_farming',
      desc: '',
      args: [],
    );
  }

  /// `Suinocultura`
  String get swine_farming {
    return Intl.message(
      'Suinocultura',
      name: 'swine_farming',
      desc: '',
      args: [],
    );
  }

  /// `Silvicultura`
  String get forestry {
    return Intl.message('Silvicultura', name: 'forestry', desc: '', args: []);
  }

  /// `Aquicultura`
  String get aquaculture {
    return Intl.message('Aquicultura', name: 'aquaculture', desc: '', args: []);
  }

  /// `Apicultura`
  String get beekeeping {
    return Intl.message('Apicultura', name: 'beekeeping', desc: '', args: []);
  }

  /// `Milho`
  String get corn {
    return Intl.message('Milho', name: 'corn', desc: '', args: []);
  }

  /// `Soja`
  String get soy {
    return Intl.message('Soja', name: 'soy', desc: '', args: []);
  }

  /// `Feijão`
  String get beans {
    return Intl.message('Feijão', name: 'beans', desc: '', args: []);
  }

  /// `Trigo`
  String get wheat {
    return Intl.message('Trigo', name: 'wheat', desc: '', args: []);
  }

  /// `Cana-de-Açúcar`
  String get sugar_cane {
    return Intl.message(
      'Cana-de-Açúcar',
      name: 'sugar_cane',
      desc: '',
      args: [],
    );
  }

  /// `Arroz`
  String get rice {
    return Intl.message('Arroz', name: 'rice', desc: '', args: []);
  }

  /// `Sorgo`
  String get sorghum {
    return Intl.message('Sorgo', name: 'sorghum', desc: '', args: []);
  }

  /// `Algodão`
  String get cotton {
    return Intl.message('Algodão', name: 'cotton', desc: '', args: []);
  }

  /// `Fruticultura`
  String get fruits {
    return Intl.message('Fruticultura', name: 'fruits', desc: '', args: []);
  }

  /// `Hortaliças`
  String get vegetables {
    return Intl.message('Hortaliças', name: 'vegetables', desc: '', args: []);
  }

  /// `Bovinos de Corte`
  String get beef_cattle {
    return Intl.message(
      'Bovinos de Corte',
      name: 'beef_cattle',
      desc: '',
      args: [],
    );
  }

  /// `Bovinos de Leite`
  String get dairy_cattle {
    return Intl.message(
      'Bovinos de Leite',
      name: 'dairy_cattle',
      desc: '',
      args: [],
    );
  }

  /// `Caprinos`
  String get goats {
    return Intl.message('Caprinos', name: 'goats', desc: '', args: []);
  }

  /// `Ovinos`
  String get sheep {
    return Intl.message('Ovinos', name: 'sheep', desc: '', args: []);
  }

  /// `Frango de Corte`
  String get broiler_chickens {
    return Intl.message(
      'Frango de Corte',
      name: 'broiler_chickens',
      desc: '',
      args: [],
    );
  }

  /// `Produção de Ovos`
  String get egg_production {
    return Intl.message(
      'Produção de Ovos',
      name: 'egg_production',
      desc: '',
      args: [],
    );
  }

  /// `Frango Caipira`
  String get free_range_chickens {
    return Intl.message(
      'Frango Caipira',
      name: 'free_range_chickens',
      desc: '',
      args: [],
    );
  }

  /// `Suínos para Corte`
  String get swine_for_slaughter {
    return Intl.message(
      'Suínos para Corte',
      name: 'swine_for_slaughter',
      desc: '',
      args: [],
    );
  }

  /// `Recria de Suínos`
  String get swine_rearing {
    return Intl.message(
      'Recria de Suínos',
      name: 'swine_rearing',
      desc: '',
      args: [],
    );
  }

  /// `Seringueira`
  String get rubber_tree {
    return Intl.message('Seringueira', name: 'rubber_tree', desc: '', args: []);
  }

  /// `Eucalipto`
  String get eucalyptus {
    return Intl.message('Eucalipto', name: 'eucalyptus', desc: '', args: []);
  }

  /// `Mogno`
  String get mahogany {
    return Intl.message('Mogno', name: 'mahogany', desc: '', args: []);
  }

  /// `Tilápia`
  String get tilapia {
    return Intl.message('Tilápia', name: 'tilapia', desc: '', args: []);
  }

  /// `Tambaqui`
  String get tambaqui {
    return Intl.message('Tambaqui', name: 'tambaqui', desc: '', args: []);
  }

  /// `Pirarucu`
  String get pirarucu {
    return Intl.message('Pirarucu', name: 'pirarucu', desc: '', args: []);
  }

  /// `Produção de Mel`
  String get honey_production {
    return Intl.message(
      'Produção de Mel',
      name: 'honey_production',
      desc: '',
      args: [],
    );
  }

  /// `Produção de Própolis`
  String get propolis_production {
    return Intl.message(
      'Produção de Própolis',
      name: 'propolis_production',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Insumo ou Produto da Operação`
  String get add_operation_item {
    return Intl.message(
      'Adicionar Insumo ou Produto da Operação',
      name: 'add_operation_item',
      desc: '',
      args: [],
    );
  }

  /// `Editar Insumo ou Produto da Operação`
  String get edit_operation_item {
    return Intl.message(
      'Editar Insumo ou Produto da Operação',
      name: 'edit_operation_item',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione um Insumo ou Produto`
  String get please_select_item {
    return Intl.message(
      'Por favor, selecione um Insumo ou Produto',
      name: 'please_select_item',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a quantidade`
  String get please_enter_quantity {
    return Intl.message(
      'Por favor, insira a quantidade',
      name: 'please_enter_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira um número válido`
  String get please_enter_valid_number {
    return Intl.message(
      'Por favor, insira um número válido',
      name: 'please_enter_valid_number',
      desc: '',
      args: [],
    );
  }

  /// `Data de Utilização`
  String get usage_date {
    return Intl.message(
      'Data de Utilização',
      name: 'usage_date',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione uma data`
  String get please_select_date {
    return Intl.message(
      'Por favor, selecione uma data',
      name: 'please_select_date',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar operação: {error}`
  String error_saving_operation(Object error) {
    return Intl.message(
      'Erro ao salvar operação: $error',
      name: 'error_saving_operation',
      desc: '',
      args: [error],
    );
  }

  /// `Aqui você pode gerenciar os insumos ou Produtos utilizados nesta operação`
  String get manage_operation_items_info {
    return Intl.message(
      'Aqui você pode gerenciar os insumos ou Produtos utilizados nesta operação',
      name: 'manage_operation_items_info',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum tipo de operação encontrado`
  String get no_operation_types_found {
    return Intl.message(
      'Nenhum tipo de operação encontrado',
      name: 'no_operation_types_found',
      desc: '',
      args: [],
    );
  }

  /// `Insumos ou Produtos da Operação`
  String get operation_items {
    return Intl.message(
      'Insumos ou Produtos da Operação',
      name: 'operation_items',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum insumo ou produto lançado para esta operação`
  String get no_items_linked {
    return Intl.message(
      'Nenhum insumo ou produto lançado para esta operação',
      name: 'no_items_linked',
      desc: '',
      args: [],
    );
  }

  /// `insumo ou produto removido da operação`
  String get item_removed_from_operation {
    return Intl.message(
      'insumo ou produto removido da operação',
      name: 'item_removed_from_operation',
      desc: '',
      args: [],
    );
  }

  /// `insumo ou produto adicionado à operação`
  String get item_added_to_operation {
    return Intl.message(
      'insumo ou produto adicionado à operação',
      name: 'item_added_to_operation',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao atualizar o Insumo ou Produto {error}`
  String error_updating_item(Object error) {
    return Intl.message(
      'Erro ao atualizar o Insumo ou Produto $error',
      name: 'error_updating_item',
      desc: '',
      args: [error],
    );
  }

  /// `Máquinas e Equipamentos`
  String get fleets {
    return Intl.message(
      'Máquinas e Equipamentos',
      name: 'fleets',
      desc: '',
      args: [],
    );
  }

  /// `Insumos e Produtos`
  String get rural_operation_items {
    return Intl.message(
      'Insumos e Produtos',
      name: 'rural_operation_items',
      desc: '',
      args: [],
    );
  }

  /// `Tipos de Operações Rurais`
  String get rural_operation_types {
    return Intl.message(
      'Tipos de Operações Rurais',
      name: 'rural_operation_types',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o talhão da atividade`
  String get select_talhao_from_activity {
    return Intl.message(
      'Selecione o talhão da atividade',
      name: 'select_talhao_from_activity',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione uma atividade rural para continuar`
  String get select_activity_to_continue {
    return Intl.message(
      'Por favor, selecione uma atividade rural para continuar',
      name: 'select_activity_to_continue',
      desc: '',
      args: [],
    );
  }

  /// `Você precisa selecionar uma atividade rural antes de prosseguir. Você será redirecionado para a tela de seleção de atividades.`
  String get select_activity_instruction {
    return Intl.message(
      'Você precisa selecionar uma atividade rural antes de prosseguir. Você será redirecionado para a tela de seleção de atividades.',
      name: 'select_activity_instruction',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Pessoa`
  String get select_person {
    return Intl.message(
      'Selecionar Pessoa',
      name: 'select_person',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Remoção`
  String get confirm_removal {
    return Intl.message(
      'Confirmar Remoção',
      name: 'confirm_removal',
      desc: '',
      args: [],
    );
  }

  /// `Tem certeza de que deseja remover este talhão da atividade?`
  String get confirm_plot_removal_from_activity {
    return Intl.message(
      'Tem certeza de que deseja remover este talhão da atividade?',
      name: 'confirm_plot_removal_from_activity',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover o talhão da atividade.`
  String get error_removing_plot_from_activity {
    return Intl.message(
      'Erro ao remover o talhão da atividade.',
      name: 'error_removing_plot_from_activity',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade Utilizada`
  String get quantity_used {
    return Intl.message(
      'Quantidade Utilizada',
      name: 'quantity_used',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Propriedade de Estoque`
  String get select_stock_property {
    return Intl.message(
      'Selecione a Propriedade de Estoque',
      name: 'select_stock_property',
      desc: '',
      args: [],
    );
  }

  /// `Talhão marcado para remoção`
  String get plot_marked_for_removal {
    return Intl.message(
      'Talhão marcado para remoção',
      name: 'plot_marked_for_removal',
      desc: '',
      args: [],
    );
  }

  /// `Remoção do talhão desfeita`
  String get plot_removal_undone {
    return Intl.message(
      'Remoção do talhão desfeita',
      name: 'plot_removal_undone',
      desc: '',
      args: [],
    );
  }

  /// `Operações Vinculadas`
  String get linked_operations_warning {
    return Intl.message(
      'Operações Vinculadas',
      name: 'linked_operations_warning',
      desc: '',
      args: [],
    );
  }

  /// `Existem operações vinculadas a este talhão. Deseja realmente removê-lo?`
  String get talhao_linked_operations_confirmation {
    return Intl.message(
      'Existem operações vinculadas a este talhão. Deseja realmente removê-lo?',
      name: 'talhao_linked_operations_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `Prosseguir`
  String get proceed {
    return Intl.message('Prosseguir', name: 'proceed', desc: '', args: []);
  }

  /// `Atividade desconhecida`
  String get unknown_activity {
    return Intl.message(
      'Atividade desconhecida',
      name: 'unknown_activity',
      desc: '',
      args: [],
    );
  }

  /// `Exibido quando o nome da atividade não é encontrado.`
  String get unknown_activity_description {
    return Intl.message(
      'Exibido quando o nome da atividade não é encontrado.',
      name: 'unknown_activity_description',
      desc: '',
      args: [],
    );
  }

  /// `Tipo desconhecido`
  String get unknown_type {
    return Intl.message(
      'Tipo desconhecido',
      name: 'unknown_type',
      desc: '',
      args: [],
    );
  }

  /// `Exibido quando o tipo de operação não é reconhecido.`
  String get unknown_type_description {
    return Intl.message(
      'Exibido quando o tipo de operação não é reconhecido.',
      name: 'unknown_type_description',
      desc: '',
      args: [],
    );
  }

  /// `Operação atualizada com sucesso.`
  String get operation_updated_successfully {
    return Intl.message(
      'Operação atualizada com sucesso.',
      name: 'operation_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Mensagem exibida após atualizar uma operação com sucesso.`
  String get operation_updated_successfully_description {
    return Intl.message(
      'Mensagem exibida após atualizar uma operação com sucesso.',
      name: 'operation_updated_successfully_description',
      desc: '',
      args: [],
    );
  }

  /// `Sem data de término`
  String get no_end_date {
    return Intl.message(
      'Sem data de término',
      name: 'no_end_date',
      desc: '',
      args: [],
    );
  }

  /// `Exibido quando uma operação não possui data de término.`
  String get no_end_date_description {
    return Intl.message(
      'Exibido quando uma operação não possui data de término.',
      name: 'no_end_date_description',
      desc: '',
      args: [],
    );
  }

  /// `Nome da Atividade`
  String get activity_name {
    return Intl.message(
      'Nome da Atividade',
      name: 'activity_name',
      desc: '',
      args: [],
    );
  }

  /// `Rótulo para o campo de nome da atividade.`
  String get activity_name_description {
    return Intl.message(
      'Rótulo para o campo de nome da atividade.',
      name: 'activity_name_description',
      desc: '',
      args: [],
    );
  }

  /// `Insumos e Produtos da operação`
  String get operation_items_info {
    return Intl.message(
      'Insumos e Produtos da operação',
      name: 'operation_items_info',
      desc: '',
      args: [],
    );
  }

  /// `Insumo e Produtos da operação`
  String get operation_item {
    return Intl.message(
      'Insumo e Produtos da operação',
      name: 'operation_item',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover o insumo ou produto {error}`
  String error_removing_item(Object error) {
    return Intl.message(
      'Erro ao remover o insumo ou produto $error',
      name: 'error_removing_item',
      desc: '',
      args: [error],
    );
  }

  /// `Insumo ou produto atualizado com sucesso`
  String get item_updated_successfully {
    return Intl.message(
      'Insumo ou produto atualizado com sucesso',
      name: 'item_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Máquinas e Equipamentos`
  String get fleet {
    return Intl.message(
      'Máquinas e Equipamentos',
      name: 'fleet',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Máquinas e Equipamentos`
  String get add_fleet {
    return Intl.message(
      'Adicionar Máquinas e Equipamentos',
      name: 'add_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Editar Máquinas e Equipamentos`
  String get edit_fleet {
    return Intl.message(
      'Editar Máquinas e Equipamentos',
      name: 'edit_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar a Máquina ou Equipamento: {error}`
  String error_saving_fleet(Object error) {
    return Intl.message(
      'Erro ao salvar a Máquina ou Equipamento: $error',
      name: 'error_saving_fleet',
      desc: '',
      args: [error],
    );
  }

  /// `Tipo da Máquina ou Equipamento`
  String get fleet_type {
    return Intl.message(
      'Tipo da Máquina ou Equipamento',
      name: 'fleet_type',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o tipo da Máquina ou Equipamento`
  String get select_fleet_type {
    return Intl.message(
      'Selecione o tipo da Máquina ou Equipamento',
      name: 'select_fleet_type',
      desc: '',
      args: [],
    );
  }

  /// `Modelo`
  String get model {
    return Intl.message('Modelo', name: 'model', desc: '', args: []);
  }

  /// `Fabricação`
  String get year_of_manufacture {
    return Intl.message(
      'Fabricação',
      name: 'year_of_manufacture',
      desc: '',
      args: [],
    );
  }

  /// `Valor`
  String get value {
    return Intl.message('Valor', name: 'value', desc: '', args: []);
  }

  /// `Horímetro/Odômetro`
  String get hour_meter_odometer {
    return Intl.message(
      'Horímetro/Odômetro',
      name: 'hour_meter_odometer',
      desc: '',
      args: [],
    );
  }

  /// `Vida Útil (anos)`
  String get useful_life {
    return Intl.message(
      'Vida Útil (anos)',
      name: 'useful_life',
      desc: '',
      args: [],
    );
  }

  /// `Data de Aquisição`
  String get acquisition_date {
    return Intl.message(
      'Data de Aquisição',
      name: 'acquisition_date',
      desc: '',
      args: [],
    );
  }

  /// `Observações`
  String get observations {
    return Intl.message(
      'Observações',
      name: 'observations',
      desc: '',
      args: [],
    );
  }

  /// `Identificador`
  String get identifier {
    return Intl.message(
      'Identificador',
      name: 'identifier',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Máquina ou Equipamento`
  String get fleet_details {
    return Intl.message(
      'Detalhes da Máquina ou Equipamento',
      name: 'fleet_details',
      desc: '',
      args: [],
    );
  }

  /// `Deseja realmente excluir esta Máquina ou Equipamento?`
  String get confirm_delete_fleet {
    return Intl.message(
      'Deseja realmente excluir esta Máquina ou Equipamento?',
      name: 'confirm_delete_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Máquinas e Equipamentos excluída com sucesso!`
  String get fleet_deleted_successfully {
    return Intl.message(
      'Máquinas e Equipamentos excluída com sucesso!',
      name: 'fleet_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir a Máquina ou Equipamento: {error}`
  String error_deleting_fleet(Object error) {
    return Intl.message(
      'Erro ao excluir a Máquina ou Equipamento: $error',
      name: 'error_deleting_fleet',
      desc: '',
      args: [error],
    );
  }

  /// `Selecionar Máquinas e Equipamentos`
  String get select_fleet {
    return Intl.message(
      'Selecionar Máquinas e Equipamentos',
      name: 'select_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para selecionar a Máquina ou Equipamento`
  String get click_to_select_fleet {
    return Intl.message(
      'Clique aqui para selecionar a Máquina ou Equipamento',
      name: 'click_to_select_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para ver os detalhes da Máquina ou Equipamento`
  String get click_to_view_fleet_details {
    return Intl.message(
      'Clique aqui para ver os detalhes da Máquina ou Equipamento',
      name: 'click_to_view_fleet_details',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode alterar os dados desta Máquina ou Equipamento.`
  String get edit_fleet_info {
    return Intl.message(
      'Aqui você pode alterar os dados desta Máquina ou Equipamento.',
      name: 'edit_fleet_info',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode ver mais informações sobre esta Máquina ou Equipamento.`
  String get fleet_details_info {
    return Intl.message(
      'Aqui você pode ver mais informações sobre esta Máquina ou Equipamento.',
      name: 'fleet_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Odômetro`
  String get odometer {
    return Intl.message('Odômetro', name: 'odometer', desc: '', args: []);
  }

  /// `anos`
  String get years {
    return Intl.message('anos', name: 'years', desc: '', args: []);
  }

  /// `Confirmar Exclusão`
  String get confirm_delete {
    return Intl.message(
      'Confirmar Exclusão',
      name: 'confirm_delete',
      desc: '',
      args: [],
    );
  }

  /// `Tem certeza de que deseja excluir esta pessoa?`
  String get are_you_sure_delete_person {
    return Intl.message(
      'Tem certeza de que deseja excluir esta pessoa?',
      name: 'are_you_sure_delete_person',
      desc: '',
      args: [],
    );
  }

  /// `Pessoa excluída com sucesso.`
  String get person_deleted_successfully {
    return Intl.message(
      'Pessoa excluída com sucesso.',
      name: 'person_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir pessoa: {error}`
  String error_deleting_person(Object error) {
    return Intl.message(
      'Erro ao excluir pessoa: $error',
      name: 'error_deleting_person',
      desc: '',
      args: [error],
    );
  }

  /// `Aqui você pode visualizar e editar os detalhes da pessoa.`
  String get person_details_info {
    return Intl.message(
      'Aqui você pode visualizar e editar os detalhes da pessoa.',
      name: 'person_details_info',
      desc: '',
      args: [],
    );
  }

  /// `R$`
  String get currency_symbol {
    return Intl.message('R\$', name: 'currency_symbol', desc: '', args: []);
  }

  /// `Esta é a data em que a coleta foi realizada.`
  String get collection_date_explanation {
    return Intl.message(
      'Esta é a data em que a coleta foi realizada.',
      name: 'collection_date_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Isso representa o número de caixas coletadas.`
  String get quantity_boxes_explanation {
    return Intl.message(
      'Isso representa o número de caixas coletadas.',
      name: 'quantity_boxes_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Este é o peso médio de cada caixa.`
  String get average_weight_box_explanation {
    return Intl.message(
      'Este é o peso médio de cada caixa.',
      name: 'average_weight_box_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Este é o peso total de todas as caixas coletadas.`
  String get total_weight_explanation {
    return Intl.message(
      'Este é o peso total de todas as caixas coletadas.',
      name: 'total_weight_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para editar os detalhes do registro de coleta.`
  String get edit_collection_record_explanation {
    return Intl.message(
      'Clique aqui para editar os detalhes do registro de coleta.',
      name: 'edit_collection_record_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Esta é a data em que a entrega foi realizada.`
  String get delivery_date_explanation {
    return Intl.message(
      'Esta é a data em que a entrega foi realizada.',
      name: 'delivery_date_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Este é o peso total de todas as caixas entregues.`
  String get total_weight_delivery_explanation {
    return Intl.message(
      'Este é o peso total de todas as caixas entregues.',
      name: 'total_weight_delivery_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Este é o peso registrado pelo produtor.`
  String get producer_weight_explanation {
    return Intl.message(
      'Este é o peso registrado pelo produtor.',
      name: 'producer_weight_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Este é o preço negociado por quilograma.`
  String get negotiated_value_explanation {
    return Intl.message(
      'Este é o preço negociado por quilograma.',
      name: 'negotiated_value_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Clique aqui para editar os detalhes do registro de entrega.`
  String get edit_delivery_record_explanation {
    return Intl.message(
      'Clique aqui para editar os detalhes do registro de entrega.',
      name: 'edit_delivery_record_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Registro de coleta excluído com sucesso.`
  String get collection_record_deleted_successfully {
    return Intl.message(
      'Registro de coleta excluído com sucesso.',
      name: 'collection_record_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Visualizar`
  String get view {
    return Intl.message('Visualizar', name: 'view', desc: '', args: []);
  }

  /// `Foto`
  String get photo {
    return Intl.message('Foto', name: 'photo', desc: '', args: []);
  }

  /// `Alterar Foto`
  String get change_photo {
    return Intl.message(
      'Alterar Foto',
      name: 'change_photo',
      desc: '',
      args: [],
    );
  }

  /// `Identificação`
  String get identification {
    return Intl.message(
      'Identificação',
      name: 'identification',
      desc: '',
      args: [],
    );
  }

  /// `Características`
  String get characteristics {
    return Intl.message(
      'Características',
      name: 'characteristics',
      desc: '',
      args: [],
    );
  }

  /// `Dados Operacionais`
  String get operational_data {
    return Intl.message(
      'Dados Operacionais',
      name: 'operational_data',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade e Peso`
  String get quantity_and_weight {
    return Intl.message(
      'Quantidade e Peso',
      name: 'quantity_and_weight',
      desc: '',
      args: [],
    );
  }

  /// `Pesos`
  String get weights {
    return Intl.message('Pesos', name: 'weights', desc: '', args: []);
  }

  /// `Datas e Recebimentos`
  String get dates_and_received {
    return Intl.message(
      'Datas e Recebimentos',
      name: 'dates_and_received',
      desc: '',
      args: [],
    );
  }

  /// `Datas`
  String get dates {
    return Intl.message('Datas', name: 'dates', desc: '', args: []);
  }

  /// `Selecione a Coleta de Latex`
  String get select_collection_record {
    return Intl.message(
      'Selecione a Coleta de Latex',
      name: 'select_collection_record',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione uma frota.`
  String get please_select_a_fleet {
    return Intl.message(
      'Por favor, selecione uma frota.',
      name: 'please_select_a_fleet',
      desc: '',
      args: [],
    );
  }

  /// `O horímetro final não pode ser menor que o inicial.`
  String get horimetro_final_invalid {
    return Intl.message(
      'O horímetro final não pode ser menor que o inicial.',
      name: 'horimetro_final_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Editar Operação de Maquinário`
  String get edit_fleet_operation {
    return Intl.message(
      'Editar Operação de Maquinário',
      name: 'edit_fleet_operation',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Operação de Maquinário`
  String get add_fleet_operation {
    return Intl.message(
      'Adicionar Operação de Maquinário',
      name: 'add_fleet_operation',
      desc: '',
      args: [],
    );
  }

  /// `Horas Utilizadas`
  String get hours_used {
    return Intl.message(
      'Horas Utilizadas',
      name: 'hours_used',
      desc: '',
      args: [],
    );
  }

  /// `Horímetro Inicial`
  String get initial_odometer {
    return Intl.message(
      'Horímetro Inicial',
      name: 'initial_odometer',
      desc: '',
      args: [],
    );
  }

  /// `Horímetro Final`
  String get final_odometer {
    return Intl.message(
      'Horímetro Final',
      name: 'final_odometer',
      desc: '',
      args: [],
    );
  }

  /// `Operação Rural não informada.`
  String get operacao_rural_missing {
    return Intl.message(
      'Operação Rural não informada.',
      name: 'operacao_rural_missing',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione uma frota.`
  String get please_select_fleet {
    return Intl.message(
      'Por favor, selecione uma frota.',
      name: 'please_select_fleet',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira as horas utilizadas.`
  String get please_enter_utilized_hours {
    return Intl.message(
      'Por favor, insira as horas utilizadas.',
      name: 'please_enter_utilized_hours',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira um número válido de horas.`
  String get please_enter_valid_hours {
    return Intl.message(
      'Por favor, insira um número válido de horas.',
      name: 'please_enter_valid_hours',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o horímetro inicial.`
  String get please_enter_initial_horimeter {
    return Intl.message(
      'Por favor, insira o horímetro inicial.',
      name: 'please_enter_initial_horimeter',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o horímetro final.`
  String get please_enter_final_horimeter {
    return Intl.message(
      'Por favor, insira o horímetro final.',
      name: 'please_enter_final_horimeter',
      desc: '',
      args: [],
    );
  }

  /// `O horímetro final deve ser maior que o inicial.`
  String get final_horimeter_must_be_greater {
    return Intl.message(
      'O horímetro final deve ser maior que o inicial.',
      name: 'final_horimeter_must_be_greater',
      desc: '',
      args: [],
    );
  }

  /// `Operações de Maquinário`
  String get frota_operations {
    return Intl.message(
      'Operações de Maquinário',
      name: 'frota_operations',
      desc: '',
      args: [],
    );
  }

  /// `Operação de Maquinário não encontrada.`
  String get fleet_operation_not_found {
    return Intl.message(
      'Operação de Maquinário não encontrada.',
      name: 'fleet_operation_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma operação de maquinário encontrada.`
  String get no_fleet_operations_found {
    return Intl.message(
      'Nenhuma operação de maquinário encontrada.',
      name: 'no_fleet_operations_found',
      desc: '',
      args: [],
    );
  }

  /// `Operação de Maquinário adicionada com sucesso.`
  String get add_fleet_operation_success {
    return Intl.message(
      'Operação de Maquinário adicionada com sucesso.',
      name: 'add_fleet_operation_success',
      desc: '',
      args: [],
    );
  }

  /// `Operação de Maquinário atualizada com sucesso.`
  String get edit_fleet_operation_success {
    return Intl.message(
      'Operação de Maquinário atualizada com sucesso.',
      name: 'edit_fleet_operation_success',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar operação de Maquinário: {error}`
  String error_saving_fleet_operation(Object error) {
    return Intl.message(
      'Erro ao salvar operação de Maquinário: $error',
      name: 'error_saving_fleet_operation',
      desc: '',
      args: [error],
    );
  }

  /// `Deseja realmente excluir esta Operação de Maquinário?`
  String get confirm_deletion_fleet_operation {
    return Intl.message(
      'Deseja realmente excluir esta Operação de Maquinário?',
      name: 'confirm_deletion_fleet_operation',
      desc: '',
      args: [],
    );
  }

  /// `Operação de Maquinário removida com sucesso.`
  String get fleet_operation_removed {
    return Intl.message(
      'Operação de Maquinário removida com sucesso.',
      name: 'fleet_operation_removed',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover operação de Maquinário: {error}`
  String error_removing_fleet_operation(Object error) {
    return Intl.message(
      'Erro ao remover operação de Maquinário: $error',
      name: 'error_removing_fleet_operation',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao salvar o item: {error}`
  String error_saving_item(Object error) {
    return Intl.message(
      'Erro ao salvar o item: $error',
      name: 'error_saving_item',
      desc: '',
      args: [error],
    );
  }

  /// `Operações de Maquinário não encontradas.`
  String get fleet_operation_not_found_plural {
    return Intl.message(
      'Operações de Maquinário não encontradas.',
      name: 'fleet_operation_not_found_plural',
      desc: '',
      args: [],
    );
  }

  /// `Operações de Maquinário adicionadas com sucesso.`
  String get add_fleet_operation_success_plural {
    return Intl.message(
      'Operações de Maquinário adicionadas com sucesso.',
      name: 'add_fleet_operation_success_plural',
      desc: '',
      args: [],
    );
  }

  /// `Operações de Maquinário atualizadas com sucesso.`
  String get edit_fleet_operation_success_plural {
    return Intl.message(
      'Operações de Maquinário atualizadas com sucesso.',
      name: 'edit_fleet_operation_success_plural',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar operações de Maquinário: {error}`
  String error_saving_fleet_operation_plural(Object error) {
    return Intl.message(
      'Erro ao salvar operações de Maquinário: $error',
      name: 'error_saving_fleet_operation_plural',
      desc: '',
      args: [error],
    );
  }

  /// `Deseja realmente excluir estas Operações de Maquinário?`
  String get confirm_deletion_fleet_operation_plural {
    return Intl.message(
      'Deseja realmente excluir estas Operações de Maquinário?',
      name: 'confirm_deletion_fleet_operation_plural',
      desc: '',
      args: [],
    );
  }

  /// `Operações de Maquinário removidas com sucesso.`
  String get fleet_operation_removed_plural {
    return Intl.message(
      'Operações de Maquinário removidas com sucesso.',
      name: 'fleet_operation_removed_plural',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover operações de Maquinário: {error}`
  String error_removing_fleet_operation_plural(Object error) {
    return Intl.message(
      'Erro ao remover operações de Maquinário: $error',
      name: 'error_removing_fleet_operation_plural',
      desc: '',
      args: [error],
    );
  }

  /// `Operação de Maquinário removida com sucesso!`
  String get fleet_operation_removed_success {
    return Intl.message(
      'Operação de Maquinário removida com sucesso!',
      name: 'fleet_operation_removed_success',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar o detalhe do item: {error}`
  String error_saving_item_detail(Object error) {
    return Intl.message(
      'Erro ao salvar o detalhe do item: $error',
      name: 'error_saving_item_detail',
      desc: '',
      args: [error],
    );
  }

  /// `Detalhe da operação de Maquinário removido com sucesso!`
  String get fleet_operation_removed_detail {
    return Intl.message(
      'Detalhe da operação de Maquinário removido com sucesso!',
      name: 'fleet_operation_removed_detail',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover o detalhe da operação de Maquinário: {error}`
  String error_removing_fleet_operation_detail(Object error) {
    return Intl.message(
      'Erro ao remover o detalhe da operação de Maquinário: $error',
      name: 'error_removing_fleet_operation_detail',
      desc: '',
      args: [error],
    );
  }

  /// `Por favor, selecione um maquinário.`
  String get please_select_maquinario {
    return Intl.message(
      'Por favor, selecione um maquinário.',
      name: 'please_select_maquinario',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o odômetro inicial.`
  String get please_enter_initial_odometer {
    return Intl.message(
      'Por favor, insira o odômetro inicial.',
      name: 'please_enter_initial_odometer',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o odômetro final.`
  String get please_enter_final_odometer {
    return Intl.message(
      'Por favor, insira o odômetro final.',
      name: 'please_enter_final_odometer',
      desc: '',
      args: [],
    );
  }

  /// `O odômetro final deve ser maior que o odômetro inicial.`
  String get final_odometer_must_be_greater {
    return Intl.message(
      'O odômetro final deve ser maior que o odômetro inicial.',
      name: 'final_odometer_must_be_greater',
      desc: '',
      args: [],
    );
  }

  /// `Operação de maquinário adicionada com sucesso!`
  String get add_fleet_operation_success_message {
    return Intl.message(
      'Operação de maquinário adicionada com sucesso!',
      name: 'add_fleet_operation_success_message',
      desc: '',
      args: [],
    );
  }

  /// `Operação de maquinário atualizada com sucesso!`
  String get edit_fleet_operation_success_message {
    return Intl.message(
      'Operação de maquinário atualizada com sucesso!',
      name: 'edit_fleet_operation_success_message',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar operação de maquinário: {error}`
  String error_saving_fleet_operation_message(Object error) {
    return Intl.message(
      'Erro ao salvar operação de maquinário: $error',
      name: 'error_saving_fleet_operation_message',
      desc: '',
      args: [error],
    );
  }

  /// `Você realmente deseja excluir esta operação de maquinário?`
  String get confirm_deletion_fleet_operation_message {
    return Intl.message(
      'Você realmente deseja excluir esta operação de maquinário?',
      name: 'confirm_deletion_fleet_operation_message',
      desc: '',
      args: [],
    );
  }

  /// `Operação de maquinário removida com sucesso!`
  String get fleet_operation_removed_message {
    return Intl.message(
      'Operação de maquinário removida com sucesso!',
      name: 'fleet_operation_removed_message',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover operação de maquinário: {error}`
  String error_removing_fleet_operation_message(Object error) {
    return Intl.message(
      'Erro ao remover operação de maquinário: $error',
      name: 'error_removing_fleet_operation_message',
      desc: '',
      args: [error],
    );
  }

  /// `Operações de maquinário adicionadas com sucesso.`
  String get add_fleet_operation_success_plural_message {
    return Intl.message(
      'Operações de maquinário adicionadas com sucesso.',
      name: 'add_fleet_operation_success_plural_message',
      desc: '',
      args: [],
    );
  }

  /// `Operações de maquinário atualizadas com sucesso.`
  String get edit_fleet_operation_success_plural_message {
    return Intl.message(
      'Operações de maquinário atualizadas com sucesso.',
      name: 'edit_fleet_operation_success_plural_message',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar operações de maquinário: {error}`
  String error_saving_fleet_operation_plural_message(Object error) {
    return Intl.message(
      'Erro ao salvar operações de maquinário: $error',
      name: 'error_saving_fleet_operation_plural_message',
      desc: '',
      args: [error],
    );
  }

  /// `Você realmente deseja excluir essas operações de maquinário?`
  String get confirm_deletion_fleet_operation_plural_message {
    return Intl.message(
      'Você realmente deseja excluir essas operações de maquinário?',
      name: 'confirm_deletion_fleet_operation_plural_message',
      desc: '',
      args: [],
    );
  }

  /// `Operações de maquinário removidas com sucesso.`
  String get fleet_operation_removed_plural_message {
    return Intl.message(
      'Operações de maquinário removidas com sucesso.',
      name: 'fleet_operation_removed_plural_message',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover operações de maquinário: {error}`
  String error_removing_fleet_operation_plural_message(Object error) {
    return Intl.message(
      'Erro ao remover operações de maquinário: $error',
      name: 'error_removing_fleet_operation_plural_message',
      desc: '',
      args: [error],
    );
  }

  /// `Abastecimentos`
  String get fleet_refueling {
    return Intl.message(
      'Abastecimentos',
      name: 'fleet_refueling',
      desc: '',
      args: [],
    );
  }

  /// `Itens de Manutenção`
  String get maintenance_items {
    return Intl.message(
      'Itens de Manutenção',
      name: 'maintenance_items',
      desc: '',
      args: [],
    );
  }

  /// `Manutenções`
  String get maintenances {
    return Intl.message(
      'Manutenções',
      name: 'maintenances',
      desc: '',
      args: [],
    );
  }

  /// `Movimentações Projetadas`
  String get projected_movements {
    return Intl.message(
      'Movimentações Projetadas',
      name: 'projected_movements',
      desc: '',
      args: [],
    );
  }

  /// `Status de Processamento`
  String get processing_status {
    return Intl.message(
      'Status de Processamento',
      name: 'processing_status',
      desc: '',
      args: [],
    );
  }

  /// `Abastecimento adicionado com sucesso`
  String get refueling_added_successfully {
    return Intl.message(
      'Abastecimento adicionado com sucesso',
      name: 'refueling_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Abastecimento atualizado com sucesso`
  String get refueling_updated_successfully {
    return Intl.message(
      'Abastecimento atualizado com sucesso',
      name: 'refueling_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar abastecimento: {error}`
  String error_saving_refueling(Object error) {
    return Intl.message(
      'Erro ao salvar abastecimento: $error',
      name: 'error_saving_refueling',
      desc: '',
      args: [error],
    );
  }

  /// `Abastecimento`
  String get refueling {
    return Intl.message('Abastecimento', name: 'refueling', desc: '', args: []);
  }

  /// `Adicionar Abastecimento`
  String get add_refueling {
    return Intl.message(
      'Adicionar Abastecimento',
      name: 'add_refueling',
      desc: '',
      args: [],
    );
  }

  /// `Editar Abastecimento`
  String get edit_refueling {
    return Intl.message(
      'Editar Abastecimento',
      name: 'edit_refueling',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, edite as informações do abastecimento.`
  String get edit_refueling_info {
    return Intl.message(
      'Por favor, edite as informações do abastecimento.',
      name: 'edit_refueling_info',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos detalhes do abastecimento.`
  String get refueling_details_info {
    return Intl.message(
      'Informações dos detalhes do abastecimento.',
      name: 'refueling_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos detalhes do item.`
  String get item_details_info {
    return Intl.message(
      'Informações dos detalhes do item.',
      name: 'item_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Opções`
  String get options {
    return Intl.message('Opções', name: 'options', desc: '', args: []);
  }

  /// `Abastecimento Externo`
  String get external_refueling {
    return Intl.message(
      'Abastecimento Externo',
      name: 'external_refueling',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, edite as informações do item de manutenção.`
  String get edit_maintenance_item_info {
    return Intl.message(
      'Por favor, edite as informações do item de manutenção.',
      name: 'edit_maintenance_item_info',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos detalhes do item de manutenção.`
  String get maintenance_item_details_info {
    return Intl.message(
      'Informações dos detalhes do item de manutenção.',
      name: 'maintenance_item_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Manutenção`
  String get add_maintenance {
    return Intl.message(
      'Adicionar Manutenção',
      name: 'add_maintenance',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Item de Manutenção`
  String get add_maintenance_item {
    return Intl.message(
      'Adicionar Item de Manutenção',
      name: 'add_maintenance_item',
      desc: '',
      args: [],
    );
  }

  /// `Editar Manutenção`
  String get edit_maintenance {
    return Intl.message(
      'Editar Manutenção',
      name: 'edit_maintenance',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, edite as informações da manutenção.`
  String get edit_maintenance_info {
    return Intl.message(
      'Por favor, edite as informações da manutenção.',
      name: 'edit_maintenance_info',
      desc: '',
      args: [],
    );
  }

  /// `Editar Item de Manutenção`
  String get edit_maintenance_item {
    return Intl.message(
      'Editar Item de Manutenção',
      name: 'edit_maintenance_item',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção`
  String get maintenance {
    return Intl.message('Manutenção', name: 'maintenance', desc: '', args: []);
  }

  /// `Informações dos detalhes da manutenção.`
  String get maintenance_details_info {
    return Intl.message(
      'Informações dos detalhes da manutenção.',
      name: 'maintenance_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Item de Manutenção`
  String get maintenance_item {
    return Intl.message(
      'Item de Manutenção',
      name: 'maintenance_item',
      desc: '',
      args: [],
    );
  }

  /// `Item de manutenção removido.`
  String get maintenance_item_removed {
    return Intl.message(
      'Item de manutenção removido.',
      name: 'maintenance_item_removed',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos itens de manutenção.`
  String get maintenance_items_info {
    return Intl.message(
      'Informações dos itens de manutenção.',
      name: 'maintenance_items_info',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Manutenção`
  String get maintenance_record {
    return Intl.message(
      'Registro de Manutenção',
      name: 'maintenance_record',
      desc: '',
      args: [],
    );
  }

  /// `Registro de manutenção removido.`
  String get maintenance_record_removed {
    return Intl.message(
      'Registro de manutenção removido.',
      name: 'maintenance_record_removed',
      desc: '',
      args: [],
    );
  }

  /// `Registros de Manutenção`
  String get maintenance_records {
    return Intl.message(
      'Registros de Manutenção',
      name: 'maintenance_records',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos registros de manutenção.`
  String get maintenance_records_info {
    return Intl.message(
      'Informações dos registros de manutenção.',
      name: 'maintenance_records_info',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum item de manutenção.`
  String get no_maintenance_items {
    return Intl.message(
      'Nenhum item de manutenção.',
      name: 'no_maintenance_items',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum registro de manutenção.`
  String get no_maintenance_records {
    return Intl.message(
      'Nenhum registro de manutenção.',
      name: 'no_maintenance_records',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum registro de abastecimento.`
  String get no_refueling_records {
    return Intl.message(
      'Nenhum registro de abastecimento.',
      name: 'no_refueling_records',
      desc: '',
      args: [],
    );
  }

  /// `Registro de Abastecimento`
  String get refueling_record {
    return Intl.message(
      'Registro de Abastecimento',
      name: 'refueling_record',
      desc: '',
      args: [],
    );
  }

  /// `Registro de abastecimento removido.`
  String get refueling_record_removed {
    return Intl.message(
      'Registro de abastecimento removido.',
      name: 'refueling_record_removed',
      desc: '',
      args: [],
    );
  }

  /// `Registros de Abastecimento`
  String get refueling_records {
    return Intl.message(
      'Registros de Abastecimento',
      name: 'refueling_records',
      desc: '',
      args: [],
    );
  }

  /// `Informações dos registros de abastecimento.`
  String get refueling_records_info {
    return Intl.message(
      'Informações dos registros de abastecimento.',
      name: 'refueling_records_info',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover manutenção: {error}`
  String error_removing_maintenance(Object error) {
    return Intl.message(
      'Erro ao remover manutenção: $error',
      name: 'error_removing_maintenance',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao remover abastecimento: {error}`
  String error_removing_refueling(Object error) {
    return Intl.message(
      'Erro ao remover abastecimento: $error',
      name: 'error_removing_refueling',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao salvar manutenção: {error}`
  String error_saving_maintenance(Object error) {
    return Intl.message(
      'Erro ao salvar manutenção: $error',
      name: 'error_saving_maintenance',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao salvar item de manutenção: {error}`
  String error_saving_maintenance_item(Object error) {
    return Intl.message(
      'Erro ao salvar item de manutenção: $error',
      name: 'error_saving_maintenance_item',
      desc: '',
      args: [error],
    );
  }

  /// `Manutenção adicionada com sucesso!`
  String get maintenance_added_successfully {
    return Intl.message(
      'Manutenção adicionada com sucesso!',
      name: 'maintenance_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção atualizada com sucesso!`
  String get maintenance_updated_successfully {
    return Intl.message(
      'Manutenção atualizada com sucesso!',
      name: 'maintenance_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Manual de Adubação SP IAC 100 2022`
  String get manual_adubacao_sp_iac_100_2022 {
    return Intl.message(
      'Manual de Adubação SP IAC 100 2022',
      name: 'manual_adubacao_sp_iac_100_2022',
      desc: '',
      args: [],
    );
  }

  /// `Recomendações de Adubação`
  String get fertilization_recommendations {
    return Intl.message(
      'Recomendações de Adubação',
      name: 'fertilization_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Carregando resumo...`
  String get loading_summary {
    return Intl.message(
      'Carregando resumo...',
      name: 'loading_summary',
      desc: '',
      args: [],
    );
  }

  /// `Produtividade esperada: {value} t/ha`
  String productivity_expected(Object value) {
    return Intl.message(
      'Produtividade esperada: $value t/ha',
      name: 'productivity_expected',
      desc: '',
      args: [value],
    );
  }

  /// `Calcário: {value} t/ha`
  String limestone_dose_short(Object value) {
    return Intl.message(
      'Calcário: $value t/ha',
      name: 'limestone_dose_short',
      desc: '',
      args: [value],
    );
  }

  /// `Gesso: {value} t/ha`
  String gypsum_dose_short(Object value) {
    return Intl.message(
      'Gesso: $value t/ha',
      name: 'gypsum_dose_short',
      desc: '',
      args: [value],
    );
  }

  /// `Sistema: {value}`
  String cultivation_system_label(Object value) {
    return Intl.message(
      'Sistema: $value',
      name: 'cultivation_system_label',
      desc: '',
      args: [value],
    );
  }

  /// `Irrigação`
  String get irrigation {
    return Intl.message('Irrigação', name: 'irrigation', desc: '', args: []);
  }

  /// `Erro ao carregar detalhes da recomendação`
  String get error_loading_recommendation {
    return Intl.message(
      'Erro ao carregar detalhes da recomendação',
      name: 'error_loading_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação não encontrada`
  String get recommendation_not_found {
    return Intl.message(
      'Recomendação não encontrada',
      name: 'recommendation_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Compartilhar Recomendação`
  String get share_recommendation {
    return Intl.message(
      'Compartilhar Recomendação',
      name: 'share_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Exportar para PDF`
  String get export_to_pdf {
    return Intl.message(
      'Exportar para PDF',
      name: 'export_to_pdf',
      desc: '',
      args: [],
    );
  }

  /// `Data da recomendação`
  String get recommendation_date {
    return Intl.message(
      'Data da recomendação',
      name: 'recommendation_date',
      desc: '',
      args: [],
    );
  }

  /// `Carregando nutrientes...`
  String get loading_nutrients {
    return Intl.message(
      'Carregando nutrientes...',
      name: 'loading_nutrients',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar nutrientes`
  String get error_loading_nutrients {
    return Intl.message(
      'Erro ao carregar nutrientes',
      name: 'error_loading_nutrients',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma recomendação de nutrientes encontrada`
  String get no_nutrient_recommendations {
    return Intl.message(
      'Nenhuma recomendação de nutrientes encontrada',
      name: 'no_nutrient_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Editar Recomendação`
  String get edit_recommendation {
    return Intl.message(
      'Editar Recomendação',
      name: 'edit_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Feijão`
  String get bean {
    return Intl.message('Feijão', name: 'bean', desc: '', args: []);
  }

  /// `Café`
  String get coffee {
    return Intl.message('Café', name: 'coffee', desc: '', args: []);
  }

  /// `Soja`
  String get soybean {
    return Intl.message('Soja', name: 'soybean', desc: '', args: []);
  }

  /// `Cana-de-açúcar`
  String get sugarcane {
    return Intl.message(
      'Cana-de-açúcar',
      name: 'sugarcane',
      desc: '',
      args: [],
    );
  }

  /// `Milho (Grão)`
  String get corn_grain {
    return Intl.message('Milho (Grão)', name: 'corn_grain', desc: '', args: []);
  }

  /// `Milho (Silagem)`
  String get corn_silage {
    return Intl.message(
      'Milho (Silagem)',
      name: 'corn_silage',
      desc: '',
      args: [],
    );
  }

  /// `Milho Pipoca`
  String get popcorn {
    return Intl.message('Milho Pipoca', name: 'popcorn', desc: '', args: []);
  }

  /// `Amendoim`
  String get peanut {
    return Intl.message('Amendoim', name: 'peanut', desc: '', args: []);
  }

  /// `Safra Verão`
  String get summer_harvest {
    return Intl.message(
      'Safra Verão',
      name: 'summer_harvest',
      desc: '',
      args: [],
    );
  }

  /// `Safrinha`
  String get off_season {
    return Intl.message('Safrinha', name: 'off_season', desc: '', args: []);
  }

  /// `Ano Todo`
  String get year_round {
    return Intl.message('Ano Todo', name: 'year_round', desc: '', args: []);
  }

  /// `Arenoso`
  String get sandy_soil {
    return Intl.message('Arenoso', name: 'sandy_soil', desc: '', args: []);
  }

  /// `Médio`
  String get medium_soil {
    return Intl.message('Médio', name: 'medium_soil', desc: '', args: []);
  }

  /// `Argiloso`
  String get clay_soil {
    return Intl.message('Argiloso', name: 'clay_soil', desc: '', args: []);
  }

  /// `Alta Resposta`
  String get high_response {
    return Intl.message(
      'Alta Resposta',
      name: 'high_response',
      desc: '',
      args: [],
    );
  }

  /// `Média/Baixa Resposta`
  String get medium_low_response {
    return Intl.message(
      'Média/Baixa Resposta',
      name: 'medium_low_response',
      desc: '',
      args: [],
    );
  }

  /// `Solos corrigidos, com muitos anos de plantio contínuo de milho ou outras culturas não leguminosas; primeiros anos de plantio direto; grande quantidade de resíduos de gramíneas; solos arenosos sujeitos a altas perdas por lixiviação.`
  String get high_response_description {
    return Intl.message(
      'Solos corrigidos, com muitos anos de plantio contínuo de milho ou outras culturas não leguminosas; primeiros anos de plantio direto; grande quantidade de resíduos de gramíneas; solos arenosos sujeitos a altas perdas por lixiviação.',
      name: 'high_response_description',
      desc: '',
      args: [],
    );
  }

  /// `Plantio anterior de leguminosas; uso de adubos orgânicos, milho safrinha após soja, cultivo intenso de leguminosas ou plantio de adubos verdes antes do milho; plantio direto estabilizado em rotação com leguminosas.`
  String get medium_low_response_description {
    return Intl.message(
      'Plantio anterior de leguminosas; uso de adubos orgânicos, milho safrinha após soja, cultivo intenso de leguminosas ou plantio de adubos verdes antes do milho; plantio direto estabilizado em rotação com leguminosas.',
      name: 'medium_low_response_description',
      desc: '',
      args: [],
    );
  }

  /// `Convencional`
  String get conventional {
    return Intl.message(
      'Convencional',
      name: 'conventional',
      desc: '',
      args: [],
    );
  }

  /// `Plantio Direto`
  String get direct_sowing {
    return Intl.message(
      'Plantio Direto',
      name: 'direct_sowing',
      desc: '',
      args: [],
    );
  }

  /// `Mínimo`
  String get minimum {
    return Intl.message('Mínimo', name: 'minimum', desc: '', args: []);
  }

  /// `Solo Seco`
  String get dry_soil {
    return Intl.message('Solo Seco', name: 'dry_soil', desc: '', args: []);
  }

  /// `Solo Úmido`
  String get moist_soil {
    return Intl.message('Solo Úmido', name: 'moist_soil', desc: '', args: []);
  }

  /// `Solo Muito Úmido`
  String get very_moist_soil {
    return Intl.message(
      'Solo Muito Úmido',
      name: 'very_moist_soil',
      desc: '',
      args: [],
    );
  }

  /// `Pós Chuva`
  String get after_rain {
    return Intl.message('Pós Chuva', name: 'after_rain', desc: '', args: []);
  }

  /// `Condições Normais`
  String get normal_conditions {
    return Intl.message(
      'Condições Normais',
      name: 'normal_conditions',
      desc: '',
      args: [],
    );
  }

  /// `Safra`
  String get main_season {
    return Intl.message('Safra', name: 'main_season', desc: '', args: []);
  }

  /// `Safrinha`
  String get second_season {
    return Intl.message('Safrinha', name: 'second_season', desc: '', args: []);
  }

  /// `Cana Planta`
  String get plant_cycle {
    return Intl.message('Cana Planta', name: 'plant_cycle', desc: '', args: []);
  }

  /// `Cana Soca`
  String get ratoon_cycle {
    return Intl.message('Cana Soca', name: 'ratoon_cycle', desc: '', args: []);
  }

  /// `Erro ao salvar análise de solo: {error}`
  String error_saving_soil_analysis(Object error) {
    return Intl.message(
      'Erro ao salvar análise de solo: $error',
      name: 'error_saving_soil_analysis',
      desc: '',
      args: [error],
    );
  }

  /// `Análise de Solo`
  String get soil_analysis {
    return Intl.message(
      'Análise de Solo',
      name: 'soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Campo obrigatório`
  String get required_field {
    return Intl.message(
      'Campo obrigatório',
      name: 'required_field',
      desc: '',
      args: [],
    );
  }

  /// `O valor deve ser positivo.`
  String get value_must_be_positive {
    return Intl.message(
      'O valor deve ser positivo.',
      name: 'value_must_be_positive',
      desc: '',
      args: [],
    );
  }

  /// `Número inválido`
  String get invalid_number {
    return Intl.message(
      'Número inválido',
      name: 'invalid_number',
      desc: '',
      args: [],
    );
  }

  /// `Identificação da Análise de Solo`
  String get soil_analysis_identification {
    return Intl.message(
      'Identificação da Análise de Solo',
      name: 'soil_analysis_identification',
      desc: '',
      args: [],
    );
  }

  /// `pH e Complexo de Acidez`
  String get ph_and_acidity_complex {
    return Intl.message(
      'pH e Complexo de Acidez',
      name: 'ph_and_acidity_complex',
      desc: '',
      args: [],
    );
  }

  /// `Macronutrientes`
  String get macronutrients {
    return Intl.message(
      'Macronutrientes',
      name: 'macronutrients',
      desc: '',
      args: [],
    );
  }

  /// `Micronutrientes`
  String get micronutrients {
    return Intl.message(
      'Micronutrientes',
      name: 'micronutrients',
      desc: '',
      args: [],
    );
  }

  /// `Matéria Orgânica`
  String get organic_matter {
    return Intl.message(
      'Matéria Orgânica',
      name: 'organic_matter',
      desc: '',
      args: [],
    );
  }

  /// `Análise Granulométrica`
  String get granulometric_analysis {
    return Intl.message(
      'Análise Granulométrica',
      name: 'granulometric_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Análise de Solo`
  String get add_soil_analysis {
    return Intl.message(
      'Adicionar Análise de Solo',
      name: 'add_soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Editar Análise de Solo`
  String get edit_soil_analysis {
    return Intl.message(
      'Editar Análise de Solo',
      name: 'edit_soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Laboratório`
  String get laboratory {
    return Intl.message('Laboratório', name: 'laboratory', desc: '', args: []);
  }

  /// `Por favor, insira o laboratório.`
  String get enter_laboratory {
    return Intl.message(
      'Por favor, insira o laboratório.',
      name: 'enter_laboratory',
      desc: '',
      args: [],
    );
  }

  /// `Metodologia de Extração`
  String get extraction_methodology {
    return Intl.message(
      'Metodologia de Extração',
      name: 'extraction_methodology',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione a metodologia de extração.`
  String get select_extraction_method {
    return Intl.message(
      'Por favor, selecione a metodologia de extração.',
      name: 'select_extraction_method',
      desc: '',
      args: [],
    );
  }

  /// `Responsável pela Coleta`
  String get collection_responsible {
    return Intl.message(
      'Responsável pela Coleta',
      name: 'collection_responsible',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o responsável pela coleta.`
  String get enter_responsible {
    return Intl.message(
      'Por favor, insira o responsável pela coleta.',
      name: 'enter_responsible',
      desc: '',
      args: [],
    );
  }

  /// `Data da Análise`
  String get analysis_date {
    return Intl.message(
      'Data da Análise',
      name: 'analysis_date',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione a data da análise.`
  String get select_analysis_date {
    return Intl.message(
      'Por favor, selecione a data da análise.',
      name: 'select_analysis_date',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade da Amostra`
  String get sample_depth {
    return Intl.message(
      'Profundidade da Amostra',
      name: 'sample_depth',
      desc: '',
      args: [],
    );
  }

  /// `Fósforo P(Resina)`
  String get phosphorus_resin {
    return Intl.message(
      'Fósforo P(Resina)',
      name: 'phosphorus_resin',
      desc: '',
      args: [],
    );
  }

  /// `Fósforo P(Mehlich)`
  String get phosphorus_mehlich {
    return Intl.message(
      'Fósforo P(Mehlich)',
      name: 'phosphorus_mehlich',
      desc: '',
      args: [],
    );
  }

  /// `pH (CaCl₂)`
  String get ph_cacl2 {
    return Intl.message('pH (CaCl₂)', name: 'ph_cacl2', desc: '', args: []);
  }

  /// `S-SO₄`
  String get s_s04 {
    return Intl.message('S-SO₄', name: 's_s04', desc: '', args: []);
  }

  /// `Potássio (K₂O)`
  String get potassium {
    return Intl.message(
      'Potássio (K₂O)',
      name: 'potassium',
      desc: '',
      args: [],
    );
  }

  /// `Cálcio (Ca²⁺)`
  String get calcium {
    return Intl.message('Cálcio (Ca²⁺)', name: 'calcium', desc: '', args: []);
  }

  /// `Magnésio (Mg²⁺)`
  String get magnesium {
    return Intl.message(
      'Magnésio (Mg²⁺)',
      name: 'magnesium',
      desc: '',
      args: [],
    );
  }

  /// `Enxofre (S-SO₄)`
  String get sulfur {
    return Intl.message('Enxofre (S-SO₄)', name: 'sulfur', desc: '', args: []);
  }

  /// `Boro (B)`
  String get boron {
    return Intl.message('Boro (B)', name: 'boron', desc: '', args: []);
  }

  /// `Cobre (Cu)`
  String get copper {
    return Intl.message('Cobre (Cu)', name: 'copper', desc: '', args: []);
  }

  /// `Ferro (Fe)`
  String get iron {
    return Intl.message('Ferro (Fe)', name: 'iron', desc: '', args: []);
  }

  /// `Manganês (Mn)`
  String get manganese {
    return Intl.message('Manganês (Mn)', name: 'manganese', desc: '', args: []);
  }

  /// `Zinco (Zn)`
  String get zinc {
    return Intl.message('Zinco (Zn)', name: 'zinc', desc: '', args: []);
  }

  /// `Carbono Orgânico (CO)`
  String get organic_carbon {
    return Intl.message(
      'Carbono Orgânico (CO)',
      name: 'organic_carbon',
      desc: '',
      args: [],
    );
  }

  /// `Areia Grossa`
  String get coarse_sand {
    return Intl.message(
      'Areia Grossa',
      name: 'coarse_sand',
      desc: '',
      args: [],
    );
  }

  /// `Areia Fina`
  String get fine_sand {
    return Intl.message('Areia Fina', name: 'fine_sand', desc: '', args: []);
  }

  /// `Silte`
  String get silt {
    return Intl.message('Silte', name: 'silt', desc: '', args: []);
  }

  /// `Argila`
  String get clay {
    return Intl.message('Argila', name: 'clay', desc: '', args: []);
  }

  /// `Sódio (Na⁺)`
  String get sodium {
    return Intl.message('Sódio (Na⁺)', name: 'sodium', desc: '', args: []);
  }

  /// `Alumínio Troca (Al³⁺)`
  String get exchangeable_aluminum {
    return Intl.message(
      'Alumínio Troca (Al³⁺)',
      name: 'exchangeable_aluminum',
      desc: '',
      args: [],
    );
  }

  /// `Acidez Potencial (H⁺Al)`
  String get potential_acidity {
    return Intl.message(
      'Acidez Potencial (H⁺Al)',
      name: 'potential_acidity',
      desc: '',
      args: [],
    );
  }

  /// `MO e CO`
  String get organic_matter_carbon {
    return Intl.message(
      'MO e CO',
      name: 'organic_matter_carbon',
      desc: '',
      args: [],
    );
  }

  /// `Textura do Solo`
  String get soil_texture {
    return Intl.message(
      'Textura do Solo',
      name: 'soil_texture',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a Textura do Solo`
  String get select_soil_texture {
    return Intl.message(
      'Selecione a Textura do Solo',
      name: 'select_soil_texture',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Análise de Solo`
  String get soil_analysis_details {
    return Intl.message(
      'Detalhes da Análise de Solo',
      name: 'soil_analysis_details',
      desc: '',
      args: [],
    );
  }

  /// `Informações Básicas`
  String get basic_information {
    return Intl.message(
      'Informações Básicas',
      name: 'basic_information',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Análise de Solo`
  String get select_soil_analysis {
    return Intl.message(
      'Selecionar Análise de Solo',
      name: 'select_soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Análises de Solo`
  String get soil_analyses {
    return Intl.message(
      'Análises de Solo',
      name: 'soil_analyses',
      desc: '',
      args: [],
    );
  }

  /// `Capacidade de Troca Catiônica`
  String get cation_exchange_capacity {
    return Intl.message(
      'Capacidade de Troca Catiônica',
      name: 'cation_exchange_capacity',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma análise de solo encontrada.`
  String get no_soil_analysis_found {
    return Intl.message(
      'Nenhuma análise de solo encontrada.',
      name: 'no_soil_analysis_found',
      desc: '',
      args: [],
    );
  }

  /// `Camada de Gessagem`
  String get gypsum_layer {
    return Intl.message(
      'Camada de Gessagem',
      name: 'gypsum_layer',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione a profundidade da amostra.`
  String get select_sample_depth {
    return Intl.message(
      'Por favor, selecione a profundidade da amostra.',
      name: 'select_sample_depth',
      desc: '',
      args: [],
    );
  }

  /// `0-20 Superficial`
  String get surface_layer {
    return Intl.message(
      '0-20 Superficial',
      name: 'surface_layer',
      desc: '',
      args: [],
    );
  }

  /// `20-40 Subsuperficial`
  String get subsurface_layer {
    return Intl.message(
      '20-40 Subsuperficial',
      name: 'subsurface_layer',
      desc: '',
      args: [],
    );
  }

  /// `0-25 Superficial cana`
  String get sugarcane_surface_layer {
    return Intl.message(
      '0-25 Superficial cana',
      name: 'sugarcane_surface_layer',
      desc: '',
      args: [],
    );
  }

  /// `25-50 Subsuperficial cana`
  String get sugarcane_subsurface_layer {
    return Intl.message(
      '25-50 Subsuperficial cana',
      name: 'sugarcane_subsurface_layer',
      desc: '',
      args: [],
    );
  }

  /// `Gerar Recomendação`
  String get generate_recommendation {
    return Intl.message(
      'Gerar Recomendação',
      name: 'generate_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de Adubação`
  String get recommendation {
    return Intl.message(
      'Recomendação de Adubação',
      name: 'recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Cultura`
  String get crop {
    return Intl.message('Cultura', name: 'crop', desc: '', args: []);
  }

  /// `Tipo de Cultura`
  String get crop_type {
    return Intl.message(
      'Tipo de Cultura',
      name: 'crop_type',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o Tipo de Cultura`
  String get select_crop_type {
    return Intl.message(
      'Selecione o Tipo de Cultura',
      name: 'select_crop_type',
      desc: '',
      args: [],
    );
  }

  /// `Sistema de Cultivo`
  String get cultivation_system {
    return Intl.message(
      'Sistema de Cultivo',
      name: 'cultivation_system',
      desc: '',
      args: [],
    );
  }

  /// `Selecione o Sistema de Cultivo`
  String get select_cultivation_system {
    return Intl.message(
      'Selecione o Sistema de Cultivo',
      name: 'select_cultivation_system',
      desc: '',
      args: [],
    );
  }

  /// `Parâmetros`
  String get parameters {
    return Intl.message('Parâmetros', name: 'parameters', desc: '', args: []);
  }

  /// `Produtividade Esperada (ton/ha)`
  String get expected_yield_tons_per_hectare {
    return Intl.message(
      'Produtividade Esperada (ton/ha)',
      name: 'expected_yield_tons_per_hectare',
      desc: '',
      args: [],
    );
  }

  /// `Digite a produtividade esperada`
  String get enter_expected_yield {
    return Intl.message(
      'Digite a produtividade esperada',
      name: 'enter_expected_yield',
      desc: '',
      args: [],
    );
  }

  /// `Digite uma produtividade válida`
  String get enter_valid_yield {
    return Intl.message(
      'Digite uma produtividade válida',
      name: 'enter_valid_yield',
      desc: '',
      args: [],
    );
  }

  /// `Data de Plantio`
  String get planting_date {
    return Intl.message(
      'Data de Plantio',
      name: 'planting_date',
      desc: '',
      args: [],
    );
  }

  /// `Irrigado`
  String get irrigated {
    return Intl.message('Irrigado', name: 'irrigated', desc: '', args: []);
  }

  /// `Tutorial de seleção de análise`
  String get select_analysis_tutorial {
    return Intl.message(
      'Tutorial de seleção de análise',
      name: 'select_analysis_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de seleção de cultura`
  String get select_crop_tutorial {
    return Intl.message(
      'Tutorial de seleção de cultura',
      name: 'select_crop_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de seleção de sistema`
  String get select_system_tutorial {
    return Intl.message(
      'Tutorial de seleção de sistema',
      name: 'select_system_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de geração de recomendação`
  String get generate_recommendation_tutorial {
    return Intl.message(
      'Tutorial de geração de recomendação',
      name: 'generate_recommendation_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao gerar recomendação`
  String get recommendation_generation_error {
    return Intl.message(
      'Erro ao gerar recomendação',
      name: 'recommendation_generation_error',
      desc: '',
      args: [],
    );
  }

  /// `Erros de Validação`
  String get validation_errors {
    return Intl.message(
      'Erros de Validação',
      name: 'validation_errors',
      desc: '',
      args: [],
    );
  }

  /// `Avisos`
  String get warnings {
    return Intl.message('Avisos', name: 'warnings', desc: '', args: []);
  }

  /// `Informações Gerais`
  String get general_information {
    return Intl.message(
      'Informações Gerais',
      name: 'general_information',
      desc: '',
      args: [],
    );
  }

  /// `Produtividade Esperada`
  String get expected_yield {
    return Intl.message(
      'Produtividade Esperada',
      name: 'expected_yield',
      desc: '',
      args: [],
    );
  }

  /// `Calagem`
  String get liming {
    return Intl.message('Calagem', name: 'liming', desc: '', args: []);
  }

  /// `Dose de Calcário`
  String get limestone_dose {
    return Intl.message(
      'Dose de Calcário',
      name: 'limestone_dose',
      desc: '',
      args: [],
    );
  }

  /// `Poder Relativo de Neutralização Total (PRNT)`
  String get prnt {
    return Intl.message(
      'Poder Relativo de Neutralização Total (PRNT)',
      name: 'prnt',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade de Incorporação`
  String get incorporation_depth {
    return Intl.message(
      'Profundidade de Incorporação',
      name: 'incorporation_depth',
      desc: '',
      args: [],
    );
  }

  /// `Modo de Aplicação`
  String get application_mode {
    return Intl.message(
      'Modo de Aplicação',
      name: 'application_mode',
      desc: '',
      args: [],
    );
  }

  /// `Gesso Agrícola`
  String get gypsum {
    return Intl.message('Gesso Agrícola', name: 'gypsum', desc: '', args: []);
  }

  /// `Dose de Gesso`
  String get gypsum_dose {
    return Intl.message(
      'Dose de Gesso',
      name: 'gypsum_dose',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade de Avaliação`
  String get evaluation_depth {
    return Intl.message(
      'Profundidade de Avaliação',
      name: 'evaluation_depth',
      desc: '',
      args: [],
    );
  }

  /// `Nutrientes`
  String get nutrients {
    return Intl.message('Nutrientes', name: 'nutrients', desc: '', args: []);
  }

  /// `Fonte`
  String get source {
    return Intl.message('Fonte', name: 'source', desc: '', args: []);
  }

  /// `Tutorial de Informações Gerais`
  String get general_info_tutorial {
    return Intl.message(
      'Tutorial de Informações Gerais',
      name: 'general_info_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de Calagem`
  String get liming_tutorial {
    return Intl.message(
      'Tutorial de Calagem',
      name: 'liming_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de Gesso Agrícola`
  String get gypsum_tutorial {
    return Intl.message(
      'Tutorial de Gesso Agrícola',
      name: 'gypsum_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Tutorial de Nutrientes`
  String get nutrients_tutorial {
    return Intl.message(
      'Tutorial de Nutrientes',
      name: 'nutrients_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Recomendação`
  String get recommendation_details {
    return Intl.message(
      'Detalhes da Recomendação',
      name: 'recommendation_details',
      desc: '',
      args: [],
    );
  }

  /// `Dose Recomendada`
  String get recommended_dose {
    return Intl.message(
      'Dose Recomendada',
      name: 'recommended_dose',
      desc: '',
      args: [],
    );
  }

  /// `Recomendações e Observações`
  String get recommendations_and_notes {
    return Intl.message(
      'Recomendações e Observações',
      name: 'recommendations_and_notes',
      desc: '',
      args: [],
    );
  }

  /// `Avisos e Alertas`
  String get warnings_and_alerts {
    return Intl.message(
      'Avisos e Alertas',
      name: 'warnings_and_alerts',
      desc: '',
      args: [],
    );
  }

  /// `Nitrogênio (N)`
  String get nitrogen {
    return Intl.message('Nitrogênio (N)', name: 'nitrogen', desc: '', args: []);
  }

  /// `Fósforo (P₂O₅)`
  String get phosphorus {
    return Intl.message(
      'Fósforo (P₂O₅)',
      name: 'phosphorus',
      desc: '',
      args: [],
    );
  }

  /// `Resultados de Análises Químicas`
  String get chemical_analysis_results {
    return Intl.message(
      'Resultados de Análises Químicas',
      name: 'chemical_analysis_results',
      desc: '',
      args: [],
    );
  }

  /// `Silício`
  String get silicon {
    return Intl.message('Silício', name: 'silicon', desc: '', args: []);
  }

  /// `Resina`
  String get resin {
    return Intl.message('Resina', name: 'resin', desc: '', args: []);
  }

  /// `Água Quente`
  String get hot_water {
    return Intl.message('Água Quente', name: 'hot_water', desc: '', args: []);
  }

  /// `Informe o método de extração`
  String get enter_extraction_method {
    return Intl.message(
      'Informe o método de extração',
      name: 'enter_extraction_method',
      desc: '',
      args: [],
    );
  }

  /// `Método de Extração`
  String get extraction_method {
    return Intl.message(
      'Método de Extração',
      name: 'extraction_method',
      desc: '',
      args: [],
    );
  }

  /// `Mehlich`
  String get mehlich {
    return Intl.message('Mehlich', name: 'mehlich', desc: '', args: []);
  }

  /// `Avisos de Validação`
  String get validation_warnings {
    return Intl.message(
      'Avisos de Validação',
      name: 'validation_warnings',
      desc: '',
      args: [],
    );
  }

  /// `Erros`
  String get errors {
    return Intl.message('Erros', name: 'errors', desc: '', args: []);
  }

  /// `Deseja continuar apesar dos erros?`
  String get continue_with_errors_question {
    return Intl.message(
      'Deseja continuar apesar dos erros?',
      name: 'continue_with_errors_question',
      desc: '',
      args: [],
    );
  }

  /// `Deseja continuar apesar dos avisos?`
  String get continue_with_warnings_question {
    return Intl.message(
      'Deseja continuar apesar dos avisos?',
      name: 'continue_with_warnings_question',
      desc: '',
      args: [],
    );
  }

  /// `Continuar Mesmo Assim`
  String get continue_anyway {
    return Intl.message(
      'Continuar Mesmo Assim',
      name: 'continue_anyway',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Erro`
  String get error_details {
    return Intl.message(
      'Detalhes do Erro',
      name: 'error_details',
      desc: '',
      args: [],
    );
  }

  /// `Mensagem de Erro`
  String get error_message {
    return Intl.message(
      'Mensagem de Erro',
      name: 'error_message',
      desc: '',
      args: [],
    );
  }

  /// `Rastreamento de Pilha`
  String get stack_trace {
    return Intl.message(
      'Rastreamento de Pilha',
      name: 'stack_trace',
      desc: '',
      args: [],
    );
  }

  /// `Fechar`
  String get close {
    return Intl.message('Fechar', name: 'close', desc: '', args: []);
  }

  /// `Areia Total (g/kg)`
  String get total_sand {
    return Intl.message(
      'Areia Total (g/kg)',
      name: 'total_sand',
      desc: '',
      args: [],
    );
  }

  /// `Textura`
  String get soil_texture_label {
    return Intl.message(
      'Textura',
      name: 'soil_texture_label',
      desc: '',
      args: [],
    );
  }

  /// `Não determinada`
  String get not_determined {
    return Intl.message(
      'Não determinada',
      name: 'not_determined',
      desc: '',
      args: [],
    );
  }

  /// `Textura não determinada com base na granulometria`
  String get soil_texture_not_determined_tooltip {
    return Intl.message(
      'Textura não determinada com base na granulometria',
      name: 'soil_texture_not_determined_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `A soma de Silte e Argila não pode exceder 1000 g/kg`
  String get sum_of_silt_and_clay_cannot_exceed_1000 {
    return Intl.message(
      'A soma de Silte e Argila não pode exceder 1000 g/kg',
      name: 'sum_of_silt_and_clay_cannot_exceed_1000',
      desc: '',
      args: [],
    );
  }

  /// `Análise Física do Solo`
  String get soil_physical_analysis {
    return Intl.message(
      'Análise Física do Solo',
      name: 'soil_physical_analysis',
      desc: '',
      args: [],
    );
  }

  /// `A soma de Areia Grossa e Areia Fina deve ser igual a Areia Total ({total_areia} g/kg).`
  String sum_of_coarse_and_fine_sand_must_equal_total_areia(
    Object total_areia,
  ) {
    return Intl.message(
      'A soma de Areia Grossa e Areia Fina deve ser igual a Areia Total ($total_areia g/kg).',
      name: 'sum_of_coarse_and_fine_sand_must_equal_total_areia',
      desc: '',
      args: [total_areia],
    );
  }

  /// `Crédito`
  String get credit {
    return Intl.message(
      'Crédito',
      name: 'credit',
      desc: 'Transação de crédito',
      args: [],
    );
  }

  /// `Débito`
  String get debit {
    return Intl.message(
      'Débito',
      name: 'debit',
      desc: 'Transação de débito',
      args: [],
    );
  }

  /// `Recebimento`
  String get receivement {
    return Intl.message(
      'Recebimento',
      name: 'receivement',
      desc: 'Recebimento de valores',
      args: [],
    );
  }

  /// `Transferência Entrada`
  String get transfer_in {
    return Intl.message(
      'Transferência Entrada',
      name: 'transfer_in',
      desc: 'Transferência recebida',
      args: [],
    );
  }

  /// `Estorno de Saída`
  String get outflow_reversal {
    return Intl.message(
      'Estorno de Saída',
      name: 'outflow_reversal',
      desc: 'Estorno de uma saída',
      args: [],
    );
  }

  /// `Empréstimo`
  String get loan {
    return Intl.message(
      'Empréstimo',
      name: 'loan',
      desc: 'Empréstimo recebido',
      args: [],
    );
  }

  /// `Investimento`
  String get investment {
    return Intl.message(
      'Investimento',
      name: 'investment',
      desc: 'Investimento realizado',
      args: [],
    );
  }

  /// `Outras Entradas`
  String get other_inflows {
    return Intl.message(
      'Outras Entradas',
      name: 'other_inflows',
      desc: 'Outras entradas de dinheiro',
      args: [],
    );
  }

  /// `Transferência Saída`
  String get transfer_out {
    return Intl.message(
      'Transferência Saída',
      name: 'transfer_out',
      desc: 'Transferência enviada',
      args: [],
    );
  }

  /// `Estorno de Entrada`
  String get inflow_reversal {
    return Intl.message(
      'Estorno de Entrada',
      name: 'inflow_reversal',
      desc: 'Estorno de uma entrada',
      args: [],
    );
  }

  /// `Devolução de Empréstimo`
  String get loan_repayment {
    return Intl.message(
      'Devolução de Empréstimo',
      name: 'loan_repayment',
      desc: 'Pagamento de empréstimo',
      args: [],
    );
  }

  /// `Resgate de Dinheiro`
  String get money_withdrawal {
    return Intl.message(
      'Resgate de Dinheiro',
      name: 'money_withdrawal',
      desc: 'Resgate de investimento',
      args: [],
    );
  }

  /// `Outras Saídas`
  String get other_outflows {
    return Intl.message(
      'Outras Saídas',
      name: 'other_outflows',
      desc: 'Outras saídas de dinheiro',
      args: [],
    );
  }

  /// `Pix/TED`
  String get instant_transfer {
    return Intl.message(
      'Pix/TED',
      name: 'instant_transfer',
      desc: 'Transferência instantânea ou eletrônica',
      args: [],
    );
  }

  /// `Receita`
  String get revenue {
    return Intl.message('Receita', name: 'revenue', desc: '', args: []);
  }

  /// `Despesa`
  String get expense {
    return Intl.message('Despesa', name: 'expense', desc: '', args: []);
  }

  /// `Produção Agrícola`
  String get agricultural_production {
    return Intl.message(
      'Produção Agrícola',
      name: 'agricultural_production',
      desc: '',
      args: [],
    );
  }

  /// `Produção Pecuária`
  String get livestock_production {
    return Intl.message(
      'Produção Pecuária',
      name: 'livestock_production',
      desc: '',
      args: [],
    );
  }

  /// `Venda de Produtos`
  String get product_sales {
    return Intl.message(
      'Venda de Produtos',
      name: 'product_sales',
      desc: '',
      args: [],
    );
  }

  /// `Prestação de Serviços`
  String get service_provision {
    return Intl.message(
      'Prestação de Serviços',
      name: 'service_provision',
      desc: '',
      args: [],
    );
  }

  /// `Rendimentos Financeiros`
  String get financial_income {
    return Intl.message(
      'Rendimentos Financeiros',
      name: 'financial_income',
      desc: '',
      args: [],
    );
  }

  /// `Outras Receitas`
  String get other_revenues {
    return Intl.message(
      'Outras Receitas',
      name: 'other_revenues',
      desc: '',
      args: [],
    );
  }

  /// `Insumos Agrícolas`
  String get agricultural_inputs {
    return Intl.message(
      'Insumos Agrícolas',
      name: 'agricultural_inputs',
      desc: '',
      args: [],
    );
  }

  /// `Insumos Pecuários`
  String get livestock_inputs {
    return Intl.message(
      'Insumos Pecuários',
      name: 'livestock_inputs',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção de Máquinas`
  String get machinery_maintenance {
    return Intl.message(
      'Manutenção de Máquinas',
      name: 'machinery_maintenance',
      desc: '',
      args: [],
    );
  }

  /// `Mão de Obra`
  String get labor {
    return Intl.message('Mão de Obra', name: 'labor', desc: '', args: []);
  }

  /// `Arrendamento`
  String get lease {
    return Intl.message('Arrendamento', name: 'lease', desc: '', args: []);
  }

  /// `Despesas Financeiras`
  String get financial_expenses {
    return Intl.message(
      'Despesas Financeiras',
      name: 'financial_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Despesas Administrativas`
  String get administrative_expenses {
    return Intl.message(
      'Despesas Administrativas',
      name: 'administrative_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Outras Despesas`
  String get other_expenses {
    return Intl.message(
      'Outras Despesas',
      name: 'other_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Em Aberto`
  String get open {
    return Intl.message('Em Aberto', name: 'open', desc: '', args: []);
  }

  /// `Parcial`
  String get partial {
    return Intl.message('Parcial', name: 'partial', desc: '', args: []);
  }

  /// `Pago`
  String get paid {
    return Intl.message('Pago', name: 'paid', desc: '', args: []);
  }

  /// `Vencido`
  String get overdue {
    return Intl.message('Vencido', name: 'overdue', desc: '', args: []);
  }

  /// `Cancelado`
  String get canceled {
    return Intl.message('Cancelado', name: 'canceled', desc: '', args: []);
  }

  /// `Pagamento à Vista`
  String get cash_payment {
    return Intl.message(
      'Pagamento à Vista',
      name: 'cash_payment',
      desc: '',
      args: [],
    );
  }

  /// `Pagamento Parcelado`
  String get installment_payment {
    return Intl.message(
      'Pagamento Parcelado',
      name: 'installment_payment',
      desc: '',
      args: [],
    );
  }

  /// `Pagamento a Prazo`
  String get term_payment {
    return Intl.message(
      'Pagamento a Prazo',
      name: 'term_payment',
      desc: '',
      args: [],
    );
  }

  /// `Compra de Insumos`
  String get input_purchase {
    return Intl.message(
      'Compra de Insumos',
      name: 'input_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Compra de Equipamentos`
  String get equipment_purchase {
    return Intl.message(
      'Compra de Equipamentos',
      name: 'equipment_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Serviços Prestados`
  String get services_rendered {
    return Intl.message(
      'Serviços Prestados',
      name: 'services_rendered',
      desc: '',
      args: [],
    );
  }

  /// `Despesas Operacionais`
  String get operational_expenses {
    return Intl.message(
      'Despesas Operacionais',
      name: 'operational_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Impostos e Taxas`
  String get taxes_and_fees {
    return Intl.message(
      'Impostos e Taxas',
      name: 'taxes_and_fees',
      desc: '',
      args: [],
    );
  }

  /// `Arrendamentos`
  String get leases {
    return Intl.message('Arrendamentos', name: 'leases', desc: '', args: []);
  }

  /// `Inicializando a aplicação...`
  String get loading_app {
    return Intl.message(
      'Inicializando a aplicação...',
      name: 'loading_app',
      desc: '',
      args: [],
    );
  }

  /// `Ocorreu um erro ao carregar a aplicação.`
  String get error_loading_app {
    return Intl.message(
      'Ocorreu um erro ao carregar a aplicação.',
      name: 'error_loading_app',
      desc: '',
      args: [],
    );
  }

  /// `Tentar novamente`
  String get retry {
    return Intl.message('Tentar novamente', name: 'retry', desc: '', args: []);
  }

  /// `Estorno de`
  String get reversal_of {
    return Intl.message(
      'Estorno de',
      name: 'reversal_of',
      desc: 'Rótulo para lançamentos de estorno',
      args: [],
    );
  }

  /// `Documento Original`
  String get original_document {
    return Intl.message(
      'Documento Original',
      name: 'original_document',
      desc: 'Rótulo para referência de documento original',
      args: [],
    );
  }

  /// `Transferência entre Contas`
  String get transfer_between_accounts {
    return Intl.message(
      'Transferência entre Contas',
      name: 'transfer_between_accounts',
      desc: 'Rótulo para transferências entre contas',
      args: [],
    );
  }

  /// `De`
  String get from {
    return Intl.message(
      'De',
      name: 'from',
      desc: 'Rótulo indicando origem',
      args: [],
    );
  }

  /// `Para`
  String get to {
    return Intl.message(
      'Para',
      name: 'to',
      desc: 'Rótulo indicando destino',
      args: [],
    );
  }

  /// `Reclassificação de Conta`
  String get account_reclassification {
    return Intl.message(
      'Reclassificação de Conta',
      name: 'account_reclassification',
      desc: 'Rótulo para reclassificação de contas',
      args: [],
    );
  }

  /// `Motivo`
  String get reason {
    return Intl.message(
      'Motivo',
      name: 'reason',
      desc: 'Rótulo para motivo ou justificativa',
      args: [],
    );
  }

  /// `Apropriação de`
  String get appropriation_of {
    return Intl.message(
      'Apropriação de',
      name: 'appropriation_of',
      desc: 'Rótulo para lançamentos de apropriação',
      args: [],
    );
  }

  /// `Período`
  String get period {
    return Intl.message(
      'Período',
      name: 'period',
      desc: 'Rótulo para referência de período',
      args: [],
    );
  }

  /// `Ajuste de Inventário`
  String get inventory_adjustment {
    return Intl.message(
      'Ajuste de Inventário',
      name: 'inventory_adjustment',
      desc: 'Rótulo para ajustes de inventário',
      args: [],
    );
  }

  /// `Venda de Produção`
  String get production_sale {
    return Intl.message(
      'Venda de Produção',
      name: 'production_sale',
      desc: 'Rótulo para vendas de produção',
      args: [],
    );
  }

  /// `Pagamento a Fornecedor`
  String get supplier_payment {
    return Intl.message(
      'Pagamento a Fornecedor',
      name: 'supplier_payment',
      desc: 'Rótulo para pagamentos a fornecedores',
      args: [],
    );
  }

  /// `Recebimento de Cliente`
  String get customer_receipt {
    return Intl.message(
      'Recebimento de Cliente',
      name: 'customer_receipt',
      desc: 'Rótulo para recebimentos de clientes',
      args: [],
    );
  }

  /// `Depreciação`
  String get depreciation {
    return Intl.message(
      'Depreciação',
      name: 'depreciation',
      desc: 'Rótulo para lançamentos de depreciação',
      args: [],
    );
  }

  /// `Amortização`
  String get amortization {
    return Intl.message(
      'Amortização',
      name: 'amortization',
      desc: 'Rótulo para lançamentos de amortização',
      args: [],
    );
  }

  /// `Custos`
  String get costs {
    return Intl.message(
      'Custos',
      name: 'costs',
      desc: 'Rótulo para lançamentos de custos',
      args: [],
    );
  }

  /// `Quebra`
  String get breakage {
    return Intl.message(
      'Quebra',
      name: 'breakage',
      desc: 'Rótulo para ajustes de quebra',
      args: [],
    );
  }

  /// `Sobra`
  String get surplus {
    return Intl.message(
      'Sobra',
      name: 'surplus',
      desc: 'Rótulo para lançamentos de sobra',
      args: [],
    );
  }

  /// `Impostos`
  String get taxes {
    return Intl.message('Impostos', name: 'taxes', desc: '', args: []);
  }

  /// `Editar Pagamento`
  String get edit_payment {
    return Intl.message(
      'Editar Pagamento',
      name: 'edit_payment',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Pagamento`
  String get add_payment {
    return Intl.message(
      'Adicionar Pagamento',
      name: 'add_payment',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma conta válida encontrada`
  String get no_valid_account_found {
    return Intl.message(
      'Nenhuma conta válida encontrada',
      name: 'no_valid_account_found',
      desc: '',
      args: [],
    );
  }

  /// `Contas Contábeis`
  String get accounting_accounts {
    return Intl.message(
      'Contas Contábeis',
      name: 'accounting_accounts',
      desc: '',
      args: [],
    );
  }

  /// `Contas a Pagar`
  String get accounts_payable {
    return Intl.message(
      'Contas a Pagar',
      name: 'accounts_payable',
      desc: '',
      args: [],
    );
  }

  /// `Lançamentos Contábeis`
  String get accounting_entries {
    return Intl.message(
      'Lançamentos Contábeis',
      name: 'accounting_entries',
      desc: '',
      args: [],
    );
  }

  /// `Lançamentos Contábeis Projetados`
  String get projected_accounting_entries {
    return Intl.message(
      'Lançamentos Contábeis Projetados',
      name: 'projected_accounting_entries',
      desc: '',
      args: [],
    );
  }

  /// `Status de Processamento Contábil`
  String get accounting_processing_status {
    return Intl.message(
      'Status de Processamento Contábil',
      name: 'accounting_processing_status',
      desc: '',
      args: [],
    );
  }

  /// `Produções Rurais`
  String get rural_productions {
    return Intl.message(
      'Produções Rurais',
      name: 'rural_productions',
      desc: '',
      args: [],
    );
  }

  /// `Modo Offline-First`
  String get offline_first_mode {
    return Intl.message(
      'Modo Offline-First',
      name: 'offline_first_mode',
      desc: '',
      args: [],
    );
  }

  /// `Ative para melhor desempenho offline`
  String get offline_first_mode_description {
    return Intl.message(
      'Ative para melhor desempenho offline',
      name: 'offline_first_mode_description',
      desc: '',
      args: [],
    );
  }

  /// `Esta configuração requer uma licença avançada`
  String get offline_first_mode_locked_description {
    return Intl.message(
      'Esta configuração requer uma licença avançada',
      name: 'offline_first_mode_locked_description',
      desc: '',
      args: [],
    );
  }

  /// `Ativado`
  String get offline_first_enabled {
    return Intl.message(
      'Ativado',
      name: 'offline_first_enabled',
      desc: '',
      args: [],
    );
  }

  /// `Desativado`
  String get offline_first_disabled {
    return Intl.message(
      'Desativado',
      name: 'offline_first_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Os dados são armazenados localmente para acesso mais rápido e serão sincronizados quando online.`
  String get offline_first_enabled_info {
    return Intl.message(
      'Os dados são armazenados localmente para acesso mais rápido e serão sincronizados quando online.',
      name: 'offline_first_enabled_info',
      desc: '',
      args: [],
    );
  }

  /// `Os dados são sempre recuperados do servidor quando online.`
  String get offline_first_disabled_info {
    return Intl.message(
      'Os dados são sempre recuperados do servidor quando online.',
      name: 'offline_first_disabled_info',
      desc: '',
      args: [],
    );
  }

  /// `Falha ao alterar configuração`
  String get failed_to_change_setting {
    return Intl.message(
      'Falha ao alterar configuração',
      name: 'failed_to_change_setting',
      desc: '',
      args: [],
    );
  }

  /// `Processando, por favor aguarde...`
  String get processing_please_wait {
    return Intl.message(
      'Processando, por favor aguarde...',
      name: 'processing_please_wait',
      desc: '',
      args: [],
    );
  }

  /// `Sincronizando dados`
  String get synchronizing_data {
    return Intl.message(
      'Sincronizando dados',
      name: 'synchronizing_data',
      desc: '',
      args: [],
    );
  }

  /// `Esse processo pode levar um minuto para ser concluído.`
  String get this_may_take_a_minute {
    return Intl.message(
      'Esse processo pode levar um minuto para ser concluído.',
      name: 'this_may_take_a_minute',
      desc: '',
      args: [],
    );
  }

  /// `Modo offline-first ativado com sucesso`
  String get offline_first_enabled_success {
    return Intl.message(
      'Modo offline-first ativado com sucesso',
      name: 'offline_first_enabled_success',
      desc: '',
      args: [],
    );
  }

  /// `Modo offline-first desativado com sucesso`
  String get offline_first_disabled_success {
    return Intl.message(
      'Modo offline-first desativado com sucesso',
      name: 'offline_first_disabled_success',
      desc: '',
      args: [],
    );
  }

  /// `Não é possível alterar o modo offline enquanto o dispositivo está sem conexão. Por favor, conecte-se à internet e tente novamente.`
  String get device_offline_cant_change_mode {
    return Intl.message(
      'Não é possível alterar o modo offline enquanto o dispositivo está sem conexão. Por favor, conecte-se à internet e tente novamente.',
      name: 'device_offline_cant_change_mode',
      desc: '',
      args: [],
    );
  }

  /// `Esta configuração não pode ser alterada enquanto estiver offline. Por favor, conecte-se à internet primeiro.`
  String get device_offline_mode_unavailable {
    return Intl.message(
      'Esta configuração não pode ser alterada enquanto estiver offline. Por favor, conecte-se à internet primeiro.',
      name: 'device_offline_mode_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Conta a Pagar`
  String get account_payable {
    return Intl.message(
      'Conta a Pagar',
      name: 'account_payable',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes da Conta a Pagar`
  String get account_payable_details {
    return Intl.message(
      'Detalhes da Conta a Pagar',
      name: 'account_payable_details',
      desc: '',
      args: [],
    );
  }

  /// `Nova Conta a Pagar`
  String get new_account_payable {
    return Intl.message(
      'Nova Conta a Pagar',
      name: 'new_account_payable',
      desc: '',
      args: [],
    );
  }

  /// `Editar Conta a Pagar`
  String get edit_account_payable {
    return Intl.message(
      'Editar Conta a Pagar',
      name: 'edit_account_payable',
      desc: '',
      args: [],
    );
  }

  /// `Parcialmente Pago`
  String get partially_paid {
    return Intl.message(
      'Parcialmente Pago',
      name: 'partially_paid',
      desc: '',
      args: [],
    );
  }

  /// `Todos`
  String get all {
    return Intl.message('Todos', name: 'all', desc: '', args: []);
  }

  /// `Valor`
  String get amount {
    return Intl.message('Valor', name: 'amount', desc: '', args: []);
  }

  /// `Data de Emissão`
  String get issue_date {
    return Intl.message(
      'Data de Emissão',
      name: 'issue_date',
      desc: '',
      args: [],
    );
  }

  /// `Data de Pagamento`
  String get payment_date {
    return Intl.message(
      'Data de Pagamento',
      name: 'payment_date',
      desc: '',
      args: [],
    );
  }

  /// `Número do Documento`
  String get document_number {
    return Intl.message(
      'Número do Documento',
      name: 'document_number',
      desc: '',
      args: [],
    );
  }

  /// `Informações de Pagamento`
  String get payment_information {
    return Intl.message(
      'Informações de Pagamento',
      name: 'payment_information',
      desc: '',
      args: [],
    );
  }

  /// `Informações Relacionadas`
  String get related_information {
    return Intl.message(
      'Informações Relacionadas',
      name: 'related_information',
      desc: '',
      args: [],
    );
  }

  /// `Categorização`
  String get categorization {
    return Intl.message(
      'Categorização',
      name: 'categorization',
      desc: '',
      args: [],
    );
  }

  /// `Restante`
  String get remaining {
    return Intl.message('Restante', name: 'remaining', desc: '', args: []);
  }

  /// `Valor Restante`
  String get remaining_amount {
    return Intl.message(
      'Valor Restante',
      name: 'remaining_amount',
      desc: '',
      args: [],
    );
  }

  /// `Valor do Pagamento`
  String get payment_amount {
    return Intl.message(
      'Valor do Pagamento',
      name: 'payment_amount',
      desc: '',
      args: [],
    );
  }

  /// `Valor Pago`
  String get paid_amount {
    return Intl.message('Valor Pago', name: 'paid_amount', desc: '', args: []);
  }

  /// `Origem`
  String get origin {
    return Intl.message('Origem', name: 'origin', desc: '', args: []);
  }

  /// `Parcela`
  String get installment {
    return Intl.message('Parcela', name: 'installment', desc: '', args: []);
  }

  /// `Número da Parcela`
  String get installment_number {
    return Intl.message(
      'Número da Parcela',
      name: 'installment_number',
      desc: '',
      args: [],
    );
  }

  /// `Total de Parcelas`
  String get total_installments {
    return Intl.message(
      'Total de Parcelas',
      name: 'total_installments',
      desc: '',
      args: [],
    );
  }

  /// `Registrar Pagamento`
  String get register_payment {
    return Intl.message(
      'Registrar Pagamento',
      name: 'register_payment',
      desc: '',
      args: [],
    );
  }

  /// `Cancelar Conta`
  String get cancel_account {
    return Intl.message(
      'Cancelar Conta',
      name: 'cancel_account',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Pagamento`
  String get confirm_payment {
    return Intl.message(
      'Confirmar Pagamento',
      name: 'confirm_payment',
      desc: '',
      args: [],
    );
  }

  /// `Deseja registrar o pagamento total desta conta?`
  String get confirm_full_payment_question {
    return Intl.message(
      'Deseja registrar o pagamento total desta conta?',
      name: 'confirm_full_payment_question',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar`
  String get confirm {
    return Intl.message('Confirmar', name: 'confirm', desc: '', args: []);
  }

  /// `Esta conta já está paga`
  String get account_already_paid {
    return Intl.message(
      'Esta conta já está paga',
      name: 'account_already_paid',
      desc: '',
      args: [],
    );
  }

  /// `Pagamento registrado com sucesso`
  String get payment_registered_successfully {
    return Intl.message(
      'Pagamento registrado com sucesso',
      name: 'payment_registered_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Conta a pagar criada com sucesso`
  String get account_payable_created_successfully {
    return Intl.message(
      'Conta a pagar criada com sucesso',
      name: 'account_payable_created_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Conta a pagar atualizada com sucesso`
  String get account_payable_updated_successfully {
    return Intl.message(
      'Conta a pagar atualizada com sucesso',
      name: 'account_payable_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Conta a pagar cancelada com sucesso`
  String get account_payable_cancelled_successfully {
    return Intl.message(
      'Conta a pagar cancelada com sucesso',
      name: 'account_payable_cancelled_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma conta a pagar encontrada`
  String get no_accounts_payable_found {
    return Intl.message(
      'Nenhuma conta a pagar encontrada',
      name: 'no_accounts_payable_found',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode ver os detalhes do pagamento e registrar pagamentos`
  String get payment_details_info {
    return Intl.message(
      'Aqui você pode ver os detalhes do pagamento e registrar pagamentos',
      name: 'payment_details_info',
      desc: '',
      args: [],
    );
  }

  /// `Use este botão para registrar um pagamento`
  String get register_payment_with_this_button {
    return Intl.message(
      'Use este botão para registrar um pagamento',
      name: 'register_payment_with_this_button',
      desc: '',
      args: [],
    );
  }

  /// `Ex: Dinheiro, PIX, Transferência`
  String get example_cash_pix {
    return Intl.message(
      'Ex: Dinheiro, PIX, Transferência',
      name: 'example_cash_pix',
      desc: '',
      args: [],
    );
  }

  /// `Selecione uma opção`
  String get select_an_option {
    return Intl.message(
      'Selecione uma opção',
      name: 'select_an_option',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar Cancelamento`
  String get confirm_cancellation {
    return Intl.message(
      'Confirmar Cancelamento',
      name: 'confirm_cancellation',
      desc: '',
      args: [],
    );
  }

  /// `Tem certeza que deseja cancelar esta conta a pagar? Esta ação não pode ser desfeita.`
  String get confirm_account_payable_cancellation {
    return Intl.message(
      'Tem certeza que deseja cancelar esta conta a pagar? Esta ação não pode ser desfeita.',
      name: 'confirm_account_payable_cancellation',
      desc: '',
      args: [],
    );
  }

  /// `O valor deve ser maior que zero`
  String get value_must_be_greater_than_zero {
    return Intl.message(
      'O valor deve ser maior que zero',
      name: 'value_must_be_greater_than_zero',
      desc: '',
      args: [],
    );
  }

  /// `Valor de pagamento inválido`
  String get invalid_payment_amount {
    return Intl.message(
      'Valor de pagamento inválido',
      name: 'invalid_payment_amount',
      desc: '',
      args: [],
    );
  }

  /// `Alterações não Salvas`
  String get unsaved_changes {
    return Intl.message(
      'Alterações não Salvas',
      name: 'unsaved_changes',
      desc: '',
      args: [],
    );
  }

  /// `Deseja descartar suas alterações?`
  String get discard_changes_question {
    return Intl.message(
      'Deseja descartar suas alterações?',
      name: 'discard_changes_question',
      desc: '',
      args: [],
    );
  }

  /// `Descartar`
  String get discard {
    return Intl.message('Descartar', name: 'discard', desc: '', args: []);
  }

  /// `Erro ao carregar dados`
  String get error_loading_data {
    return Intl.message(
      'Erro ao carregar dados',
      name: 'error_loading_data',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar conta a pagar: {error}`
  String error_saving_account_payable(Object error) {
    return Intl.message(
      'Erro ao salvar conta a pagar: $error',
      name: 'error_saving_account_payable',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao registrar pagamento: {error}`
  String error_registering_payment(Object error) {
    return Intl.message(
      'Erro ao registrar pagamento: $error',
      name: 'error_registering_payment',
      desc: '',
      args: [error],
    );
  }

  /// `Erro ao cancelar conta a pagar: {error}`
  String error_cancelling_account_payable(Object error) {
    return Intl.message(
      'Erro ao cancelar conta a pagar: $error',
      name: 'error_cancelling_account_payable',
      desc: '',
      args: [error],
    );
  }

  /// `Relatório de Compras`
  String get purchase_report {
    return Intl.message(
      'Relatório de Compras',
      name: 'purchase_report',
      desc: '',
      args: [],
    );
  }

  /// `Histórico de Pagamentos`
  String get payment_history {
    return Intl.message(
      'Histórico de Pagamentos',
      name: 'payment_history',
      desc: '',
      args: [],
    );
  }

  /// `O valor pago deve ser maior ou igual ao valor total.`
  String get paid_amount_must_be_greater_or_equal_to_total_amount {
    return Intl.message(
      'O valor pago deve ser maior ou igual ao valor total.',
      name: 'paid_amount_must_be_greater_or_equal_to_total_amount',
      desc: '',
      args: [],
    );
  }

  /// `Deve ser maior ou igual ao valor total.`
  String get must_be_greater_or_equal_to_total_amount {
    return Intl.message(
      'Deve ser maior ou igual ao valor total.',
      name: 'must_be_greater_or_equal_to_total_amount',
      desc: '',
      args: [],
    );
  }

  /// `O valor deve ser maior ou igual a zero.`
  String get value_must_be_greater_than_or_equal_to_zero {
    return Intl.message(
      'O valor deve ser maior ou igual a zero.',
      name: 'value_must_be_greater_than_or_equal_to_zero',
      desc: '',
      args: [],
    );
  }

  /// `Data de pagamento é obrigatória quando o valor pago é maior que zero`
  String get payment_date_required_when_paid_amount_is_greater_than_zero {
    return Intl.message(
      'Data de pagamento é obrigatória quando o valor pago é maior que zero',
      name: 'payment_date_required_when_paid_amount_is_greater_than_zero',
      desc: '',
      args: [],
    );
  }

  /// `Informe o valor pago se já foi realizado o pagamento`
  String get enter_payment_amount_if_already_paid {
    return Intl.message(
      'Informe o valor pago se já foi realizado o pagamento',
      name: 'enter_payment_amount_if_already_paid',
      desc: '',
      args: [],
    );
  }

  /// `O valor pago deve ser maior que zero para definir a data de pagamento`
  String get paid_amount_must_be_greater_than_zero_to_set_payment_date {
    return Intl.message(
      'O valor pago deve ser maior que zero para definir a data de pagamento',
      name: 'paid_amount_must_be_greater_than_zero_to_set_payment_date',
      desc: '',
      args: [],
    );
  }

  /// `Obrigatório para valor pago`
  String get required_for_paid_amount {
    return Intl.message(
      'Obrigatório para valor pago',
      name: 'required_for_paid_amount',
      desc: '',
      args: [],
    );
  }

  /// `Disponível apenas quando o valor pago for informado`
  String get only_available_when_paid_amount_is_set {
    return Intl.message(
      'Disponível apenas quando o valor pago for informado',
      name: 'only_available_when_paid_amount_is_set',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de adubação criada com sucesso`
  String get recomendation_created_successfully {
    return Intl.message(
      'Recomendação de adubação criada com sucesso',
      name: 'recomendation_created_successfully',
      desc: '',
      args: [],
    );
  }

  /// `A dose recomendada de K₂O excede o limite máximo.`
  String get warning_k2o_exceeds_limit {
    return Intl.message(
      'A dose recomendada de K₂O excede o limite máximo.',
      name: 'warning_k2o_exceeds_limit',
      desc: '',
      args: [],
    );
  }

  /// `Atenção: Dose elevada de K₂O em solo arenoso pode causar lixiviação.`
  String get warning_k2o_sandy_soil {
    return Intl.message(
      'Atenção: Dose elevada de K₂O em solo arenoso pode causar lixiviação.',
      name: 'warning_k2o_sandy_soil',
      desc: '',
      args: [],
    );
  }

  /// `Como esta é uma cultura irrigada, as doses de nutrientes podem ser otimizadas para maiores produtividades. Garanta o manejo adequado da água.`
  String get irrigated_crop_recommendation_warning {
    return Intl.message(
      'Como esta é uma cultura irrigada, as doses de nutrientes podem ser otimizadas para maiores produtividades. Garanta o manejo adequado da água.',
      name: 'irrigated_crop_recommendation_warning',
      desc: '',
      args: [],
    );
  }

  /// `Solo arenoso requer atenção especial à lixiviação de nutrientes. Considere dividir as aplicações de fertilizantes em doses menores e mais frequentes.`
  String get sandy_soil_recommendation_warning {
    return Intl.message(
      'Solo arenoso requer atenção especial à lixiviação de nutrientes. Considere dividir as aplicações de fertilizantes em doses menores e mais frequentes.',
      name: 'sandy_soil_recommendation_warning',
      desc: '',
      args: [],
    );
  }

  /// `Para cultivo em plantio direto, a aplicação superficial de certos nutrientes pode reduzir sua eficiência. Considere técnicas adequadas de posicionamento.`
  String get no_till_system_recommendation_warning {
    return Intl.message(
      'Para cultivo em plantio direto, a aplicação superficial de certos nutrientes pode reduzir sua eficiência. Considere técnicas adequadas de posicionamento.',
      name: 'no_till_system_recommendation_warning',
      desc: '',
      args: [],
    );
  }

  /// `Correção de Solo`
  String get soil_correction {
    return Intl.message(
      'Correção de Solo',
      name: 'soil_correction',
      desc: '',
      args: [],
    );
  }

  /// `Aqui você pode ver as recomendações para correção do solo, incluindo calagem e gessagem.`
  String get soil_correction_tutorial {
    return Intl.message(
      'Aqui você pode ver as recomendações para correção do solo, incluindo calagem e gessagem.',
      name: 'soil_correction_tutorial',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao calcular valor: {error}`
  String error_calculating_value(Object error) {
    return Intl.message(
      'Erro ao calcular valor: $error',
      name: 'error_calculating_value',
      desc: '',
      args: [error],
    );
  }

  /// `Por favor, insira a saturação de bases atual`
  String get enter_current_base_saturation {
    return Intl.message(
      'Por favor, insira a saturação de bases atual',
      name: 'enter_current_base_saturation',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a saturação de bases desejada`
  String get enter_desired_base_saturation {
    return Intl.message(
      'Por favor, insira a saturação de bases desejada',
      name: 'enter_desired_base_saturation',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a CTC`
  String get enter_ctc {
    return Intl.message(
      'Por favor, insira a CTC',
      name: 'enter_ctc',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o PRNT`
  String get enter_prnt {
    return Intl.message(
      'Por favor, insira o PRNT',
      name: 'enter_prnt',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o tipo de calcário`
  String get enter_limestone_type {
    return Intl.message(
      'Por favor, insira o tipo de calcário',
      name: 'enter_limestone_type',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a quantidade`
  String get enter_quantity {
    return Intl.message(
      'Por favor, insira a quantidade',
      name: 'enter_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a profundidade de incorporação`
  String get enter_incorporation_depth {
    return Intl.message(
      'Por favor, insira a profundidade de incorporação',
      name: 'enter_incorporation_depth',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o modo de aplicação`
  String get enter_application_mode {
    return Intl.message(
      'Por favor, insira o modo de aplicação',
      name: 'enter_application_mode',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o prazo de aplicação`
  String get enter_application_deadline {
    return Intl.message(
      'Por favor, insira o prazo de aplicação',
      name: 'enter_application_deadline',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Recomendação de Calagem`
  String get add_liming_recommendation {
    return Intl.message(
      'Adicionar Recomendação de Calagem',
      name: 'add_liming_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Editar Recomendação de Calagem`
  String get edit_liming_recommendation {
    return Intl.message(
      'Editar Recomendação de Calagem',
      name: 'edit_liming_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Parâmetros do Solo`
  String get soil_parameters {
    return Intl.message(
      'Parâmetros do Solo',
      name: 'soil_parameters',
      desc: '',
      args: [],
    );
  }

  /// `Saturação de Bases Atual (%)`
  String get current_base_saturation_percentage {
    return Intl.message(
      'Saturação de Bases Atual (%)',
      name: 'current_base_saturation_percentage',
      desc: '',
      args: [],
    );
  }

  /// `Valor da análise de solo`
  String get value_from_soil_analysis {
    return Intl.message(
      'Valor da análise de solo',
      name: 'value_from_soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Saturação de Bases Desejada (%)`
  String get desired_base_saturation_percentage {
    return Intl.message(
      'Saturação de Bases Desejada (%)',
      name: 'desired_base_saturation_percentage',
      desc: '',
      args: [],
    );
  }

  /// `Saturação desejada para a cultura`
  String get desired_saturation_for_crop {
    return Intl.message(
      'Saturação desejada para a cultura',
      name: 'desired_saturation_for_crop',
      desc: '',
      args: [],
    );
  }

  /// `CTC da análise de solo`
  String get ctc_from_soil_analysis {
    return Intl.message(
      'CTC da análise de solo',
      name: 'ctc_from_soil_analysis',
      desc: '',
      args: [],
    );
  }

  /// `Parâmetros do Calcário`
  String get limestone_parameters {
    return Intl.message(
      'Parâmetros do Calcário',
      name: 'limestone_parameters',
      desc: '',
      args: [],
    );
  }

  /// `PRNT (%)`
  String get prnt_percentage {
    return Intl.message(
      'PRNT (%)',
      name: 'prnt_percentage',
      desc: '',
      args: [],
    );
  }

  /// `Poder Relativo de Neutralização Total`
  String get relative_neutralizing_power {
    return Intl.message(
      'Poder Relativo de Neutralização Total',
      name: 'relative_neutralizing_power',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Calcário`
  String get limestone_type {
    return Intl.message(
      'Tipo de Calcário',
      name: 'limestone_type',
      desc: '',
      args: [],
    );
  }

  /// `Quantidade Recomendada`
  String get recommended_quantity {
    return Intl.message(
      'Quantidade Recomendada',
      name: 'recommended_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Calcário (t/ha)`
  String get limestone_tons_per_hectare {
    return Intl.message(
      'Calcário (t/ha)',
      name: 'limestone_tons_per_hectare',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade (cm)`
  String get depth_in_centimeters {
    return Intl.message(
      'Profundidade (cm)',
      name: 'depth_in_centimeters',
      desc: '',
      args: [],
    );
  }

  /// `Prazo de Aplicação`
  String get application_deadline {
    return Intl.message(
      'Prazo de Aplicação',
      name: 'application_deadline',
      desc: '',
      args: [],
    );
  }

  /// `Meses antes do plantio`
  String get months_before_planting {
    return Intl.message(
      'Meses antes do plantio',
      name: 'months_before_planting',
      desc: '',
      args: [],
    );
  }

  /// `Meses`
  String get months {
    return Intl.message('Meses', name: 'months', desc: '', args: []);
  }

  /// `Aplicação Parcelada`
  String get installment_application {
    return Intl.message(
      'Aplicação Parcelada',
      name: 'installment_application',
      desc: '',
      args: [],
    );
  }

  /// `Aplicar em múltiplas operações`
  String get apply_in_multiple_operations {
    return Intl.message(
      'Aplicar em múltiplas operações',
      name: 'apply_in_multiple_operations',
      desc: '',
      args: [],
    );
  }

  /// `Calcular Quantidade Recomendada`
  String get calculate_recommended_quantity {
    return Intl.message(
      'Calcular Quantidade Recomendada',
      name: 'calculate_recommended_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Você não tem permissão para adicionar recomendações de calagem`
  String get no_permission_to_add_liming {
    return Intl.message(
      'Você não tem permissão para adicionar recomendações de calagem',
      name: 'no_permission_to_add_liming',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, salve a recomendação primeiro`
  String get save_recommendation_first {
    return Intl.message(
      'Por favor, salve a recomendação primeiro',
      name: 'save_recommendation_first',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de calagem adicionada com sucesso`
  String get liming_recommendation_added_successfully {
    return Intl.message(
      'Recomendação de calagem adicionada com sucesso',
      name: 'liming_recommendation_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar recomendação de calagem: {error}`
  String error_saving_liming(Object error) {
    return Intl.message(
      'Erro ao salvar recomendação de calagem: $error',
      name: 'error_saving_liming',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para editar recomendações de calagem`
  String get no_permission_to_edit_liming {
    return Intl.message(
      'Você não tem permissão para editar recomendações de calagem',
      name: 'no_permission_to_edit_liming',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de calagem atualizada com sucesso`
  String get liming_recommendation_updated_successfully {
    return Intl.message(
      'Recomendação de calagem atualizada com sucesso',
      name: 'liming_recommendation_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao atualizar recomendação de calagem: {error}`
  String error_updating_liming(Object error) {
    return Intl.message(
      'Erro ao atualizar recomendação de calagem: $error',
      name: 'error_updating_liming',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para excluir recomendações de calagem`
  String get no_permission_to_delete_liming {
    return Intl.message(
      'Você não tem permissão para excluir recomendações de calagem',
      name: 'no_permission_to_delete_liming',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de Calagem`
  String get liming_recommendation {
    return Intl.message(
      'Recomendação de Calagem',
      name: 'liming_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de calagem excluída com sucesso`
  String get liming_recommendation_deleted_successfully {
    return Intl.message(
      'Recomendação de calagem excluída com sucesso',
      name: 'liming_recommendation_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir recomendação de calagem: {error}`
  String error_deleting_liming(Object error) {
    return Intl.message(
      'Erro ao excluir recomendação de calagem: $error',
      name: 'error_deleting_liming',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para adicionar recomendações de gesso`
  String get no_permission_to_add_gypsum {
    return Intl.message(
      'Você não tem permissão para adicionar recomendações de gesso',
      name: 'no_permission_to_add_gypsum',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de gesso adicionada com sucesso`
  String get gypsum_recommendation_added_successfully {
    return Intl.message(
      'Recomendação de gesso adicionada com sucesso',
      name: 'gypsum_recommendation_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar recomendação de gesso: {error}`
  String error_saving_gypsum(Object error) {
    return Intl.message(
      'Erro ao salvar recomendação de gesso: $error',
      name: 'error_saving_gypsum',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para editar recomendações de gesso`
  String get no_permission_to_edit_gypsum {
    return Intl.message(
      'Você não tem permissão para editar recomendações de gesso',
      name: 'no_permission_to_edit_gypsum',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de gesso atualizada com sucesso`
  String get gypsum_recommendation_updated_successfully {
    return Intl.message(
      'Recomendação de gesso atualizada com sucesso',
      name: 'gypsum_recommendation_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao atualizar recomendação de gesso: {error}`
  String error_updating_gypsum(Object error) {
    return Intl.message(
      'Erro ao atualizar recomendação de gesso: $error',
      name: 'error_updating_gypsum',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para excluir recomendações de gesso`
  String get no_permission_to_delete_gypsum {
    return Intl.message(
      'Você não tem permissão para excluir recomendações de gesso',
      name: 'no_permission_to_delete_gypsum',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de Gesso`
  String get gypsum_recommendation {
    return Intl.message(
      'Recomendação de Gesso',
      name: 'gypsum_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de gesso excluída com sucesso`
  String get gypsum_recommendation_deleted_successfully {
    return Intl.message(
      'Recomendação de gesso excluída com sucesso',
      name: 'gypsum_recommendation_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir recomendação de gesso: {error}`
  String error_deleting_gypsum(Object error) {
    return Intl.message(
      'Erro ao excluir recomendação de gesso: $error',
      name: 'error_deleting_gypsum',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para adicionar recomendações de nutrientes`
  String get no_permission_to_add_nutrient {
    return Intl.message(
      'Você não tem permissão para adicionar recomendações de nutrientes',
      name: 'no_permission_to_add_nutrient',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de nutriente adicionada com sucesso`
  String get nutrient_recommendation_added_successfully {
    return Intl.message(
      'Recomendação de nutriente adicionada com sucesso',
      name: 'nutrient_recommendation_added_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar recomendação de nutriente: {error}`
  String error_saving_nutrient(Object error) {
    return Intl.message(
      'Erro ao salvar recomendação de nutriente: $error',
      name: 'error_saving_nutrient',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para editar recomendações de nutrientes`
  String get no_permission_to_edit_nutrient {
    return Intl.message(
      'Você não tem permissão para editar recomendações de nutrientes',
      name: 'no_permission_to_edit_nutrient',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de nutriente atualizada com sucesso`
  String get nutrient_recommendation_updated_successfully {
    return Intl.message(
      'Recomendação de nutriente atualizada com sucesso',
      name: 'nutrient_recommendation_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao atualizar recomendação de nutriente: {error}`
  String error_updating_nutrient(Object error) {
    return Intl.message(
      'Erro ao atualizar recomendação de nutriente: $error',
      name: 'error_updating_nutrient',
      desc: '',
      args: [error],
    );
  }

  /// `Você não tem permissão para excluir recomendações de nutrientes`
  String get no_permission_to_delete_nutrient {
    return Intl.message(
      'Você não tem permissão para excluir recomendações de nutrientes',
      name: 'no_permission_to_delete_nutrient',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de Nutriente`
  String get nutrient_recommendation {
    return Intl.message(
      'Recomendação de Nutriente',
      name: 'nutrient_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação de nutriente excluída com sucesso`
  String get nutrient_recommendation_deleted_successfully {
    return Intl.message(
      'Recomendação de nutriente excluída com sucesso',
      name: 'nutrient_recommendation_deleted_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao excluir recomendação de nutriente: {error}`
  String error_deleting_nutrient(Object error) {
    return Intl.message(
      'Erro ao excluir recomendação de nutriente: $error',
      name: 'error_deleting_nutrient',
      desc: '',
      args: [error],
    );
  }

  /// `Recomendação de calagem removida`
  String get liming_recommendation_removed {
    return Intl.message(
      'Recomendação de calagem removida',
      name: 'liming_recommendation_removed',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover recomendação de calagem: {error}`
  String error_removing_liming(Object error) {
    return Intl.message(
      'Erro ao remover recomendação de calagem: $error',
      name: 'error_removing_liming',
      desc: '',
      args: [error],
    );
  }

  /// `Recomendação de gesso removida`
  String get gypsum_recommendation_removed {
    return Intl.message(
      'Recomendação de gesso removida',
      name: 'gypsum_recommendation_removed',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover recomendação de gesso: {error}`
  String error_removing_gypsum(Object error) {
    return Intl.message(
      'Erro ao remover recomendação de gesso: $error',
      name: 'error_removing_gypsum',
      desc: '',
      args: [error],
    );
  }

  /// `Recomendação de nutriente removida`
  String get nutrient_recommendation_removed {
    return Intl.message(
      'Recomendação de nutriente removida',
      name: 'nutrient_recommendation_removed',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Nutriente`
  String get add_nutrient {
    return Intl.message(
      'Adicionar Nutriente',
      name: 'add_nutrient',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Gesso`
  String get add_gypsum {
    return Intl.message(
      'Adicionar Gesso',
      name: 'add_gypsum',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Calagem`
  String get add_liming {
    return Intl.message(
      'Adicionar Calagem',
      name: 'add_liming',
      desc: '',
      args: [],
    );
  }

  /// `Recomendações de Calagem`
  String get liming_recommendations {
    return Intl.message(
      'Recomendações de Calagem',
      name: 'liming_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma recomendação de calagem encontrada`
  String get no_liming_recommendations {
    return Intl.message(
      'Nenhuma recomendação de calagem encontrada',
      name: 'no_liming_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Saturação de Bases`
  String get saturation_base {
    return Intl.message(
      'Saturação de Bases',
      name: 'saturation_base',
      desc: '',
      args: [],
    );
  }

  /// `Recomendações de Gesso`
  String get gypsum_recommendations {
    return Intl.message(
      'Recomendações de Gesso',
      name: 'gypsum_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Nenhuma recomendação de gesso encontrada`
  String get no_gypsum_recommendations {
    return Intl.message(
      'Nenhuma recomendação de gesso encontrada',
      name: 'no_gypsum_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Saturação de Alumínio`
  String get aluminum_saturation {
    return Intl.message(
      'Saturação de Alumínio',
      name: 'aluminum_saturation',
      desc: '',
      args: [],
    );
  }

  /// `Recomendações de Nutrientes`
  String get nutrient_recommendations {
    return Intl.message(
      'Recomendações de Nutrientes',
      name: 'nutrient_recommendations',
      desc: '',
      args: [],
    );
  }

  /// `Teor`
  String get content {
    return Intl.message('Teor', name: 'content', desc: '', args: []);
  }

  /// `Interpretação`
  String get interpretation {
    return Intl.message(
      'Interpretação',
      name: 'interpretation',
      desc: '',
      args: [],
    );
  }

  /// `Saturação de Bases`
  String get base_saturation {
    return Intl.message(
      'Saturação de Bases',
      name: 'base_saturation',
      desc: '',
      args: [],
    );
  }

  /// `Não é necessário gesso devido ao teor de cálcio suficiente`
  String get no_gypsum_needed_due_to_calcium_content {
    return Intl.message(
      'Não é necessário gesso devido ao teor de cálcio suficiente',
      name: 'no_gypsum_needed_due_to_calcium_content',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a dose recomendada`
  String get enter_recommended_dose {
    return Intl.message(
      'Por favor, insira a dose recomendada',
      name: 'enter_recommended_dose',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a profundidade avaliada`
  String get enter_evaluated_depth {
    return Intl.message(
      'Por favor, insira a profundidade avaliada',
      name: 'enter_evaluated_depth',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a saturação de alumínio`
  String get enter_aluminum_saturation {
    return Intl.message(
      'Por favor, insira a saturação de alumínio',
      name: 'enter_aluminum_saturation',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o teor de cálcio do subsolo`
  String get enter_subsoil_calcium {
    return Intl.message(
      'Por favor, insira o teor de cálcio do subsolo',
      name: 'enter_subsoil_calcium',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Recomendação de Gesso`
  String get add_gypsum_recommendation {
    return Intl.message(
      'Adicionar Recomendação de Gesso',
      name: 'add_gypsum_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Editar Recomendação de Gesso`
  String get edit_gypsum_recommendation {
    return Intl.message(
      'Editar Recomendação de Gesso',
      name: 'edit_gypsum_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Critérios de Recomendação`
  String get recommendation_criteria {
    return Intl.message(
      'Critérios de Recomendação',
      name: 'recommendation_criteria',
      desc: '',
      args: [],
    );
  }

  /// `Selecione os critérios de cálculo`
  String get select_calculation_criteria {
    return Intl.message(
      'Selecione os critérios de cálculo',
      name: 'select_calculation_criteria',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação baseada na saturação de alumínio`
  String get recommendation_based_on_aluminum {
    return Intl.message(
      'Recomendação baseada na saturação de alumínio',
      name: 'recommendation_based_on_aluminum',
      desc: '',
      args: [],
    );
  }

  /// `Teor de Cálcio no Subsolo`
  String get subsoil_calcium_content {
    return Intl.message(
      'Teor de Cálcio no Subsolo',
      name: 'subsoil_calcium_content',
      desc: '',
      args: [],
    );
  }

  /// `Recomendação baseada no teor de cálcio`
  String get recommendation_based_on_calcium {
    return Intl.message(
      'Recomendação baseada no teor de cálcio',
      name: 'recommendation_based_on_calcium',
      desc: '',
      args: [],
    );
  }

  /// `Teor de Sulfato`
  String get sulfate_content {
    return Intl.message(
      'Teor de Sulfato',
      name: 'sulfate_content',
      desc: '',
      args: [],
    );
  }

  /// `Teor de sulfato no solo`
  String get sulfate_soil_content {
    return Intl.message(
      'Teor de sulfato no solo',
      name: 'sulfate_soil_content',
      desc: '',
      args: [],
    );
  }

  /// `Teor de cálcio no subsolo`
  String get calcium_subsoil_content {
    return Intl.message(
      'Teor de cálcio no subsolo',
      name: 'calcium_subsoil_content',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade Avaliada`
  String get evaluated_depth {
    return Intl.message(
      'Profundidade Avaliada',
      name: 'evaluated_depth',
      desc: '',
      args: [],
    );
  }

  /// `Profundidade da amostragem de solo`
  String get depth_of_soil_sampling {
    return Intl.message(
      'Profundidade da amostragem de solo',
      name: 'depth_of_soil_sampling',
      desc: '',
      args: [],
    );
  }

  /// `Gesso (t/ha)`
  String get gypsum_tons_per_hectare {
    return Intl.message(
      'Gesso (t/ha)',
      name: 'gypsum_tons_per_hectare',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, selecione um nutriente`
  String get select_nutrient {
    return Intl.message(
      'Por favor, selecione um nutriente',
      name: 'select_nutrient',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira o teor`
  String get enter_content {
    return Intl.message(
      'Por favor, insira o teor',
      name: 'enter_content',
      desc: '',
      args: [],
    );
  }

  /// `Por favor, insira a interpretação`
  String get enter_interpretation {
    return Intl.message(
      'Por favor, insira a interpretação',
      name: 'enter_interpretation',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Restrições`
  String get select_restrictions {
    return Intl.message(
      'Selecionar Restrições',
      name: 'select_restrictions',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Recomendação de Nutriente`
  String get add_nutrient_recommendation {
    return Intl.message(
      'Adicionar Recomendação de Nutriente',
      name: 'add_nutrient_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Editar Recomendação de Nutriente`
  String get edit_nutrient_recommendation {
    return Intl.message(
      'Editar Recomendação de Nutriente',
      name: 'edit_nutrient_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `Identificação do Nutriente`
  String get nutrient_identification {
    return Intl.message(
      'Identificação do Nutriente',
      name: 'nutrient_identification',
      desc: '',
      args: [],
    );
  }

  /// `Nutriente`
  String get nutrient {
    return Intl.message('Nutriente', name: 'nutrient', desc: '', args: []);
  }

  /// `Dados da Análise`
  String get analysis_data {
    return Intl.message(
      'Dados da Análise',
      name: 'analysis_data',
      desc: '',
      args: [],
    );
  }

  /// `Teor do nutriente no solo`
  String get nutrient_content_in_soil {
    return Intl.message(
      'Teor do nutriente no solo',
      name: 'nutrient_content_in_soil',
      desc: '',
      args: [],
    );
  }

  /// `Nutriente (kg/ha)`
  String get nutrient_kilograms_per_hectare {
    return Intl.message(
      'Nutriente (kg/ha)',
      name: 'nutrient_kilograms_per_hectare',
      desc: '',
      args: [],
    );
  }

  /// `Fonte do Nutriente`
  String get nutrient_source {
    return Intl.message(
      'Fonte do Nutriente',
      name: 'nutrient_source',
      desc: '',
      args: [],
    );
  }

  /// `Eficiência de Aplicação`
  String get application_efficiency {
    return Intl.message(
      'Eficiência de Aplicação',
      name: 'application_efficiency',
      desc: '',
      args: [],
    );
  }

  /// `Percentual de utilização do nutriente`
  String get nutrient_utilization_percentage {
    return Intl.message(
      'Percentual de utilização do nutriente',
      name: 'nutrient_utilization_percentage',
      desc: '',
      args: [],
    );
  }

  /// `Restrições`
  String get restrictions {
    return Intl.message('Restrições', name: 'restrictions', desc: '', args: []);
  }

  /// `Restrições de Aplicação`
  String get application_restrictions {
    return Intl.message(
      'Restrições de Aplicação',
      name: 'application_restrictions',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar`
  String get select {
    return Intl.message('Selecionar', name: 'select', desc: '', args: []);
  }

  /// `Nenhuma restrição selecionada`
  String get no_restrictions_selected {
    return Intl.message(
      'Nenhuma restrição selecionada',
      name: 'no_restrictions_selected',
      desc: '',
      args: [],
    );
  }

  /// `Calcular Dose Recomendada`
  String get calculate_recommended_dose {
    return Intl.message(
      'Calcular Dose Recomendada',
      name: 'calculate_recommended_dose',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao remover recomendação de nutriente: {error}`
  String error_removing_nutrient(Object error) {
    return Intl.message(
      'Erro ao remover recomendação de nutriente: $error',
      name: 'error_removing_nutrient',
      desc: '',
      args: [error],
    );
  }

  /// `Muito Baixo`
  String get very_low {
    return Intl.message('Muito Baixo', name: 'very_low', desc: '', args: []);
  }

  /// `Baixo`
  String get low {
    return Intl.message('Baixo', name: 'low', desc: '', args: []);
  }

  /// `Médio`
  String get medium {
    return Intl.message('Médio', name: 'medium', desc: '', args: []);
  }

  /// `Adequado`
  String get adequate {
    return Intl.message('Adequado', name: 'adequate', desc: '', args: []);
  }

  /// `Alto`
  String get high {
    return Intl.message('Alto', name: 'high', desc: '', args: []);
  }

  /// `Muito Alto`
  String get very_high {
    return Intl.message('Muito Alto', name: 'very_high', desc: '', args: []);
  }

  /// `Movimenta Estoque`
  String get inventory_movement {
    return Intl.message(
      'Movimenta Estoque',
      name: 'inventory_movement',
      desc: '',
      args: [],
    );
  }

  /// `Cobertura 1`
  String get coverage_1 {
    return Intl.message('Cobertura 1', name: 'coverage_1', desc: '', args: []);
  }

  /// `Cobertura 2`
  String get coverage_2 {
    return Intl.message('Cobertura 2', name: 'coverage_2', desc: '', args: []);
  }

  /// `Plantio (Total)`
  String get planting_total {
    return Intl.message(
      'Plantio (Total)',
      name: 'planting_total',
      desc: '',
      args: [],
    );
  }

  /// `Plantio (Parte)`
  String get planting_partial {
    return Intl.message(
      'Plantio (Parte)',
      name: 'planting_partial',
      desc: '',
      args: [],
    );
  }

  /// `Cobertura 1 (Restante)`
  String get coverage_1_remaining {
    return Intl.message(
      'Cobertura 1 (Restante)',
      name: 'coverage_1_remaining',
      desc: '',
      args: [],
    );
  }

  /// `Plantio`
  String get planting_micro {
    return Intl.message('Plantio', name: 'planting_micro', desc: '', args: []);
  }

  /// `Fase`
  String get phase {
    return Intl.message('Fase', name: 'phase', desc: '', args: []);
  }

  /// `Dose (kg/ha)`
  String get dose_kg_ha {
    return Intl.message('Dose (kg/ha)', name: 'dose_kg_ha', desc: '', args: []);
  }

  /// `dias`
  String get days {
    return Intl.message('dias', name: 'days', desc: '', args: []);
  }

  /// `Verificando dependências...`
  String get checking_dependencies {
    return Intl.message(
      'Verificando dependências...',
      name: 'checking_dependencies',
      desc: '',
      args: [],
    );
  }

  /// `Total de itens dependentes: {count}`
  String total_dependent_items(Object count) {
    return Intl.message(
      'Total de itens dependentes: $count',
      name: 'total_dependent_items',
      desc: '',
      args: [count],
    );
  }

  /// `Detalhamento por tipo:`
  String get dependencies_breakdown {
    return Intl.message(
      'Detalhamento por tipo:',
      name: 'dependencies_breakdown',
      desc: '',
      args: [],
    );
  }

  /// `ATENÇÃO: Todos os itens listados acima e quaisquer dependências deles também serão excluídos permanentemente!`
  String get recursive_deletion_warning {
    return Intl.message(
      'ATENÇÃO: Todos os itens listados acima e quaisquer dependências deles também serão excluídos permanentemente!',
      name: 'recursive_deletion_warning',
      desc: '',
      args: [],
    );
  }

  /// `Sulco de Plantio`
  String get planting_furrow {
    return Intl.message(
      'Sulco de Plantio',
      name: 'planting_furrow',
      desc: 'Modo de aplicação: diretamente no sulco durante o plantio',
      args: [],
    );
  }

  /// `Lanço em Cobertura`
  String get broadcast_topdressing {
    return Intl.message(
      'Lanço em Cobertura',
      name: 'broadcast_topdressing',
      desc:
          'Modo de aplicação: aplicação a lanço após a emergência da planta (cobertura)',
      args: [],
    );
  }

  /// `Lanço em Pré-Plantio`
  String get broadcast_pre_planting {
    return Intl.message(
      'Lanço em Pré-Plantio',
      name: 'broadcast_pre_planting',
      desc: 'Modo de aplicação: aplicação a lanço antes do plantio',
      args: [],
    );
  }

  /// `Incorporado`
  String get incorporated {
    return Intl.message(
      'Incorporado',
      name: 'incorporated',
      desc: 'Modo de aplicação: aplicado e depois incorporado ao solo',
      args: [],
    );
  }

  /// `Aplicação Foliar`
  String get foliar_application {
    return Intl.message(
      'Aplicação Foliar',
      name: 'foliar_application',
      desc: 'Modo de aplicação: aplicado diretamente nas folhas',
      args: [],
    );
  }

  /// `Não Especificado`
  String get unspecified {
    return Intl.message(
      'Não Especificado',
      name: 'unspecified',
      desc: 'Modo ou época de aplicação padrão ou desconhecida',
      args: [],
    );
  }

  /// `Plantio`
  String get planting_epoch {
    return Intl.message(
      'Plantio',
      name: 'planting_epoch',
      desc: 'Época: Aplicação no momento do plantio',
      args: [],
    );
  }

  /// `Pré-Plantio`
  String get pre_planting_epoch {
    return Intl.message(
      'Pré-Plantio',
      name: 'pre_planting_epoch',
      desc: 'Época: Aplicação antes do plantio',
      args: [],
    );
  }

  /// `1ª Cobertura`
  String get coverage_1_epoch {
    return Intl.message(
      '1ª Cobertura',
      name: 'coverage_1_epoch',
      desc: 'Época: Primeira aplicação em cobertura',
      args: [],
    );
  }

  /// `2ª Cobertura`
  String get coverage_2_epoch {
    return Intl.message(
      '2ª Cobertura',
      name: 'coverage_2_epoch',
      desc: 'Época: Segunda aplicação em cobertura',
      args: [],
    );
  }

  /// `3ª Cobertura`
  String get coverage_3_epoch {
    return Intl.message(
      '3ª Cobertura',
      name: 'coverage_3_epoch',
      desc: 'Época: Terceira aplicação em cobertura',
      args: [],
    );
  }

  /// `Época Desconhecida`
  String get unknown_epoch {
    return Intl.message(
      'Época Desconhecida',
      name: 'unknown_epoch',
      desc: 'Época padrão ou desconhecida',
      args: [],
    );
  }

  /// `Lançamento Contábil`
  String get accounting_entry {
    return Intl.message(
      'Lançamento Contábil',
      name: 'accounting_entry',
      desc: '',
      args: [],
    );
  }

  /// `Detalhes do Lançamento Contábil`
  String get accounting_entry_details {
    return Intl.message(
      'Detalhes do Lançamento Contábil',
      name: 'accounting_entry_details',
      desc: '',
      args: [],
    );
  }

  /// `Novo Lançamento Contábil`
  String get new_accounting_entry {
    return Intl.message(
      'Novo Lançamento Contábil',
      name: 'new_accounting_entry',
      desc: '',
      args: [],
    );
  }

  /// `Editar Lançamento Contábil`
  String get edit_accounting_entry {
    return Intl.message(
      'Editar Lançamento Contábil',
      name: 'edit_accounting_entry',
      desc: '',
      args: [],
    );
  }

  /// `Filtros`
  String get filters {
    return Intl.message('Filtros', name: 'filters', desc: '', args: []);
  }

  /// `Limpar Filtros`
  String get clear_filters {
    return Intl.message(
      'Limpar Filtros',
      name: 'clear_filters',
      desc: '',
      args: [],
    );
  }

  /// `Aplicar`
  String get apply {
    return Intl.message('Aplicar', name: 'apply', desc: '', args: []);
  }

  /// `Automático`
  String get automatic {
    return Intl.message('Automático', name: 'automatic', desc: '', args: []);
  }

  /// `Saldo`
  String get balance {
    return Intl.message('Saldo', name: 'balance', desc: '', args: []);
  }

  /// `Saldo Após`
  String get balance_after {
    return Intl.message(
      'Saldo Após',
      name: 'balance_after',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum lançamento encontrado`
  String get no_entries_found {
    return Intl.message(
      'Nenhum lançamento encontrado',
      name: 'no_entries_found',
      desc: '',
      args: [],
    );
  }

  /// `Lançamento Manual`
  String get manual_entry {
    return Intl.message(
      'Lançamento Manual',
      name: 'manual_entry',
      desc: '',
      args: [],
    );
  }

  /// `Natureza da Conta`
  String get account_nature {
    return Intl.message(
      'Natureza da Conta',
      name: 'account_nature',
      desc: '',
      args: [],
    );
  }

  /// `Código da Conta`
  String get account_code {
    return Intl.message(
      'Código da Conta',
      name: 'account_code',
      desc: '',
      args: [],
    );
  }

  /// `Timestamp`
  String get timestamp {
    return Intl.message('Timestamp', name: 'timestamp', desc: '', args: []);
  }

  /// `Lote`
  String get batch {
    return Intl.message('Lote', name: 'batch', desc: '', args: []);
  }

  /// `Confirmar Estorno`
  String get confirm_reversal {
    return Intl.message(
      'Confirmar Estorno',
      name: 'confirm_reversal',
      desc: '',
      args: [],
    );
  }

  /// `Tem certeza que deseja estornar este lançamento? Esta ação criará lançamentos de estorno.`
  String get confirm_entry_reversal_message {
    return Intl.message(
      'Tem certeza que deseja estornar este lançamento? Esta ação criará lançamentos de estorno.',
      name: 'confirm_entry_reversal_message',
      desc: '',
      args: [],
    );
  }

  /// `Lançamento estornado com sucesso`
  String get entry_reversed_successfully {
    return Intl.message(
      'Lançamento estornado com sucesso',
      name: 'entry_reversed_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao estornar lançamento: {error}`
  String error_reversing_entry(Object error) {
    return Intl.message(
      'Erro ao estornar lançamento: $error',
      name: 'error_reversing_entry',
      desc: '',
      args: [error],
    );
  }

  /// `Informações da Conta`
  String get account_information {
    return Intl.message(
      'Informações da Conta',
      name: 'account_information',
      desc: '',
      args: [],
    );
  }

  /// `Informações do Lançamento`
  String get entry_information {
    return Intl.message(
      'Informações do Lançamento',
      name: 'entry_information',
      desc: '',
      args: [],
    );
  }

  /// `Tipo de Origem`
  String get origin_type {
    return Intl.message(
      'Tipo de Origem',
      name: 'origin_type',
      desc: '',
      args: [],
    );
  }

  /// `ID de Origem`
  String get origin_id {
    return Intl.message('ID de Origem', name: 'origin_id', desc: '', args: []);
  }

  /// `Lançamentos Relacionados`
  String get related_entries {
    return Intl.message(
      'Lançamentos Relacionados',
      name: 'related_entries',
      desc: '',
      args: [],
    );
  }

  /// `Estornar Lançamento`
  String get reverse_entry {
    return Intl.message(
      'Estornar Lançamento',
      name: 'reverse_entry',
      desc: '',
      args: [],
    );
  }

  /// `Modo Avançado`
  String get advanced_mode {
    return Intl.message(
      'Modo Avançado',
      name: 'advanced_mode',
      desc: '',
      args: [],
    );
  }

  /// `Partidas Dobradas`
  String get double_entry_bookkeeping {
    return Intl.message(
      'Partidas Dobradas',
      name: 'double_entry_bookkeeping',
      desc: '',
      args: [],
    );
  }

  /// `Selecione a conta para o lançamento`
  String get select_account_for_entry {
    return Intl.message(
      'Selecione a conta para o lançamento',
      name: 'select_account_for_entry',
      desc: '',
      args: [],
    );
  }

  /// `Lançamentos de Partidas Dobradas`
  String get double_entry_entries {
    return Intl.message(
      'Lançamentos de Partidas Dobradas',
      name: 'double_entry_entries',
      desc: '',
      args: [],
    );
  }

  /// `O total de débitos deve ser igual ao total de créditos`
  String get total_debits_must_equal_credits {
    return Intl.message(
      'O total de débitos deve ser igual ao total de créditos',
      name: 'total_debits_must_equal_credits',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar Lançamento`
  String get add_entry {
    return Intl.message(
      'Adicionar Lançamento',
      name: 'add_entry',
      desc: '',
      args: [],
    );
  }

  /// `Total de Débitos`
  String get total_debits {
    return Intl.message(
      'Total de Débitos',
      name: 'total_debits',
      desc: '',
      args: [],
    );
  }

  /// `Total de Créditos`
  String get total_credits {
    return Intl.message(
      'Total de Créditos',
      name: 'total_credits',
      desc: '',
      args: [],
    );
  }

  /// `Descrição Geral`
  String get general_description {
    return Intl.message(
      'Descrição Geral',
      name: 'general_description',
      desc: '',
      args: [],
    );
  }

  /// `Lançamento criado com sucesso`
  String get entry_created_successfully {
    return Intl.message(
      'Lançamento criado com sucesso',
      name: 'entry_created_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Lançamento atualizado com sucesso`
  String get entry_updated_successfully {
    return Intl.message(
      'Lançamento atualizado com sucesso',
      name: 'entry_updated_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao salvar lançamento: {error}`
  String error_saving_entry(Object error) {
    return Intl.message(
      'Erro ao salvar lançamento: $error',
      name: 'error_saving_entry',
      desc: '',
      args: [error],
    );
  }

  /// `Última Mensagem`
  String get last {
    return Intl.message('Última Mensagem', name: 'last', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      Locale.fromSubtags(languageCode: 'en', countryCode: 'US'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
