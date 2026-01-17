//V02
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_processor.dart';
import 'package:planejacampo/services/device_info_service.dart';
import 'package:planejacampo/services/firestore_listeners.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_processor.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/preload_all_data.dart';
import 'package:planejacampo/services/system/local_cache_manager.dart';
import 'package:planejacampo/services/system/offline_queue_manager.dart';
import 'package:planejacampo/utils/propriedade_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejacampo/utils/permissions.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/services/database_migration.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'package:planejacampo/utils/licenses.dart';
import 'package:planejacampo/services/carga_inicial.dart';
import 'package:planejacampo/utils/locale_extension.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';

// Classe para gerenciar o estado da aplicação.
class AppStateManager extends ChangeNotifier {
  late FormatacaoUtil formatacaoUtil;
  static final AppStateManager _instance = AppStateManager._internal();
  Propriedade? _activePropriedade;
  Produtor? _activeProdutor;
  AtividadeRural? _activeAtividadeRural;
  bool _producerChanged = false;
  bool _isDarkMode = false;
  User? _authenticatedUser;
  String? _currentUserRole;
  String? _currentModoMovimentacaoEstoque;
  bool _isInitialized = false;
  bool _debugMode = false;
  bool _isFirstRun = true;
  bool _canCreateMoreProdutores = false;
  bool _canCreateMorePropriedades = false;
  List<Produtor> _produtoresCache = [];
  late FirestoreListeners _firestoreListeners;
  bool _cargaInicialRunning = false;
  String _deviceId = '';
  bool _isCacheValidationInProgress = false;
  bool _isOfflineFirstEnabled = false;
  bool _canMovimentarEstoque = false;
  bool _syncInProgress = false;

  final Map<String, bool> _showTutorial = {
    'homeScreen': true,
    'produtoresListScreen': true,
    'produtorScreen': true,
    'produtorFormScreen': true,
    'propriedadeScreen': true,
    'propriedadeFormScreen': true,
    'comprasItensChooseScreen': true,
    'comprasCheckoutFormScreen': true,
    'itemCompraFormScreen': true,
  };

  Map<String, Map<String, bool>> _userPermissions = {};

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;
  bool _lastKnownRealConnection = false;
  Timer? _periodicCheckTimer;
  final Duration _checkInterval = const Duration(minutes: 5);
  Locale _appLocale = WidgetsBinding.instance.window.locale;

  // Getters
  FormatacaoUtil get formatacao => formatacaoUtil;
  Propriedade? get activePropriedade => _activePropriedade;
  String? get activePropriedadeId => _activePropriedade?.id;
  Produtor? get activeProdutor => _activeProdutor;
  String? get activeProdutorId => _activeProdutor?.id;
  int _numProdutoresCriados = 0;
  bool get canCreateMoreProdutores => _canCreateMoreProdutores;
  bool get producerChanged => _producerChanged;
  String? get currentUserId => _authenticatedUser?.uid;
  String? get currentUserEmail => _authenticatedUser?.email;
  bool get isDarkMode => _isDarkMode;
  User? get authenticatedUser => _authenticatedUser;
  String? get currentUserRole => _currentUserRole;
  String? get currentModoMovimentacaoEstoque => _currentModoMovimentacaoEstoque;
  bool get hasActiveProdutor => _activeProdutor != null;
  bool get hasActivePropriedade => _activePropriedade != null;
  bool get hasAuthenticatedUser => _authenticatedUser != null;
  bool get isInitialized => _isInitialized;
  bool get debugMode => _debugMode;
  bool get isFirstRun => _isFirstRun;
  Locale get appLocale => _appLocale;
  bool _pendingInitialDataLoad = false;
  List<Produtor> get produtoresCache => _produtoresCache;
  AtividadeRural? get activeAtividadeRural => _activeAtividadeRural;
  String get deviceId => _deviceId;
  bool get canCreateMorePropriedades => _canCreateMorePropriedades;
  bool get isOfflineFirstEnabled => _isOfflineFirstEnabled;
  bool get canMovimentarEstoque => _canMovimentarEstoque;

  bool showTutorial(String screenName) {
    if (_debugMode) return true;
    return _showTutorial[screenName] ?? false;
  }

  Map<String, Map<String, bool>> get userPermissions => _userPermissions;

  bool get isOnline {
    if (!_isOnline) return false;
    return _lastKnownRealConnection;
  }

  // Construtores e Inicialização
  factory AppStateManager() => _instance;

  AppStateManager._internal() {
    formatacaoUtil = FormatacaoUtil();
    _setCurrentUser(false);
  }

  Future<void> initializeApp() async {
    try {
      await _init();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Erro durante a inicialização do app: $e');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeProdutorId');
      await prefs.remove('activePropriedadeId');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _init() async {
    try {
      _firestoreListeners = FirestoreListeners(this);

      // Configura conectividade primeiro
      _setupConnectivityListener();
      await _checkRealConnection(false);

      // Carrega preferências e dados iniciais do cache
      await _loadPreferences();

      // Carrega produtores do cache primeiro para inicialização mais rápida
      await _loadAllAccessibleProdutores();

      _deviceId = await DeviceInfoService().getDeviceId();
      _isInitialized = true;

      // Sequência otimizada para inicialização quando online
      // Sequência otimizada para inicialização quando online
      if (_isOnline && _lastKnownRealConnection) {
        // Primeiro processamos as operações offline pendentes
        try {
          await OfflineQueueManager.processQueue();

          // Iniciar os listeners com base no modo
          await _firestoreListeners.startListening();

          // Realizar sincronização completa com o modo atual
          await _performModeTransitionSync(_isOfflineFirstEnabled);
        } catch (e) {
          print('Erro durante inicialização online: $e');
        }
      } else {
        print('Dispositivo offline: usando apenas dados do cache local');
      }

      _startPeriodicCheck();
      notifyListeners();
    } catch (e) {
      print('Erro durante _init: $e');
      throw e;
    }
  }

  Future<void> setActiveAtividadeRural(AtividadeRural? atividadeRural) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _activeAtividadeRural = atividadeRural;
    if (atividadeRural != null) {
      await prefs.setString('activeAtividadeRuralId', atividadeRural.id);
    } else {
      await prefs.remove('activeAtividadeRuralId');
    }
    notifyListeners();
  }

  // Métodos de Inicialização e Pré-Carregamento
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _loadActiveProdutor(prefs);
    await _loadActivePropriedade(prefs);
    await _loadActiveAtividadeRural(prefs);
    await _loadIsOffllineFirstEnabled(prefs);
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    String? savedLocale = prefs.getString('appLocale');
    if (savedLocale != null) {
      _appLocale = LocaleExtension.fromString(savedLocale);
      Intl.defaultLocale = _appLocale.toLanguageTag();
      formatacaoUtil.updateLocale(_appLocale);
      if (_isOnline && _lastKnownRealConnection) {
        await _carregarDadosIniciais();
      }
    } else {
      setLocale(WidgetsBinding.instance.window.locale, false);
    }

    await _initializeShowTutorial(false);

    String? isFirstRunString = prefs.getString('isFirstRun');
    if (isFirstRunString != null) {
      _isFirstRun = isFirstRunString.toLowerCase() == 'true';
    } else {
      _isFirstRun = true;
    }
  }

  Future<void> _initializeShowTutorial(bool notify) async {
    await _loadShowTutorial(notify);
  }

  Future<void> _loadShowTutorial(bool notify) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var key in _showTutorial.keys) {
      _showTutorial[key] =
          prefs.getBool('tutorial_$key') ?? _showTutorial[key] ?? false;
    }
    if (notify) notifyListeners();
  }

  Future<void> _carregarDadosIniciais() async {
    if (_activeProdutor != null &&
        !_cargaInicialRunning &&
        _isOnline &&
        _lastKnownRealConnection) {
      try {
        _cargaInicialRunning = true;
        final siglaPais = _appLocale.countryCode ?? '';

        // REMOVIDA a verificação de status aqui.  A verificação agora é feita DENTRO de `CargaInicial.carregarDadosIniciaisLanguageCode`

        print('Iniciando carga inicial para siglaPais: $siglaPais');
        bool _isPessoaJuridica = _activeProdutor!.tipo == 'Pessoa Jurídica';
        await CargaInicial.carregarDadosIniciaisLanguageCode(
            _activeProdutor!.id, _isPessoaJuridica, _appLocale);
        _activeProdutor = await ProdutorService()
            .getById(_activeProdutor!.id); // Recarregar o produtor
        _pendingInitialDataLoad = false;
        notifyListeners();
      } catch (e) {
        print('Erro ao carregar dados iniciais: $e');
      } finally {
        _cargaInicialRunning = false;
      }
    } else if (!_isOnline || !_lastKnownRealConnection) {
      print('Offline: carga inicial não executada, usando cache local');
    }
  }

  bool hasCargaInicialForLocale() {
    final siglaPais = _appLocale.countryCode ?? '';
    return _activeProdutor?.cargaInicial?.any((entry) =>
            entry['siglaPais'] == siglaPais &&
            entry['status'] == 'completed') ??
        false;
  }

  Future<void> _loadAllAccessibleProdutores() async {
    try {
      final produtorService = ProdutorService();
      if (_isOnline && _lastKnownRealConnection) {
        _produtoresCache = await produtorService.getProdutores();
      } else {
        final cachedProdutores =
            await LocalCacheManager.getAllFromCache('produtores');
        _produtoresCache = cachedProdutores
            .map((data) => produtorService.fromMap(data, data['id']))
            .toList();
        print('Tentando ler do cache local');
        print(
            'Lidos ${_produtoresCache.length} itens do cache para a coleção produtores');
      }
      notifyListeners();
    } catch (e) {
      print("Erro ao carregar os produtores acessíveis: $e");
    }
  }

  Future<void> startFirestoreListeners() async {
    // MODIFICAÇÃO: Verificar se há operações offline pendentes
    if (_firestoreListeners != null && _isOnline && _lastKnownRealConnection) {
      // ADICIONADO: Processar fila offline primeiro se houver operações pendentes
      if (await OfflineQueueManager.hasPendingOperations()) {
        await OfflineQueueManager.processQueue();
      }

      _firestoreListeners.startListening();
    }
  }

  void stopFirestoreListeners() {
    if (_firestoreListeners != null) _firestoreListeners.stopListening();
  }

  Future<void> setActiveProdutor(Produtor? produtor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PropriedadeService propriedadeService = PropriedadeService();

    // Parar listeners atuais
    stopFirestoreListeners();

    _activeProdutor = produtor;

    // Adicionar após definir _activeProdutor
    await updateMovimentacaoEstoquePermissions();

    if (produtor != null) {
      prefs.setString('activeProdutorId', produtor.id);

      // Verificar e configurar modo offline
      await verificarEConfigurarModoOffline(produtor.id);

      if (_isOnline && _lastKnownRealConnection) {
        // Online: carregar dados do servidor
        await propriedadeService.getByProdutorId(produtor.id);
        await _runDatabaseMigrations(produtor.id);
        await startFirestoreListeners();
        await _carregarDadosIniciais();
      } else {
        // Offline: usar dados do cache
        print('Offline: usando cache local para produtor ${produtor.id}');
        try {
          final cachedPropriedades = await LocalCacheManager.queryCache(
              'propriedades', {'produtorId': produtor.id});
          print(
              'Propriedades carregadas do cache: ${cachedPropriedades.length}');
        } catch (e) {
          print('Erro ao carregar propriedades do cache: $e');
        }
      }
    } else {
      prefs.remove('activeProdutorId');
    }

    await setActivePropriedade(null);
    await _loadUserPermissions(false);
    _producerChanged = true;

    notifyListeners();
  }

  Future<void> setActivePropriedade(Propriedade? propriedade) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await setActiveAtividadeRural(null);
    if (_activeProdutor == null) return;

    _activePropriedade = propriedade;

    // Adicionar após definir _activePropriedade
    await validateCurrentModoMovimentacaoEstoque();

    if (propriedade != null) {
      await prefs.setString('activePropriedadeId', propriedade.id);
      _currentModoMovimentacaoEstoque =
          _activePropriedade!.modoMovimentacaoEstoque;
    } else {
      await prefs.remove('activePropriedadeId');
    }

    notifyListeners();
  }

  Future<void> _runDatabaseMigrations(String produtorId) async {
    if (_isOnline && _lastKnownRealConnection) {
      final firestore = FirebaseService.firestore;
      final migration = DatabaseMigration(firestore, produtorId);
      await migration.runMigrations();
    }
  }

  void _setCurrentUser(bool notify) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _authenticatedUser = user;
      await _loadUserPermissions(false);
      if (notify) notifyListeners();
    });
  }

  void setAuthenticatedUser(User? user) {
    _authenticatedUser = user;
    notifyListeners();
  }

  void setCurrentModoMovimentacaoEstoque(String? modo) {
    _currentModoMovimentacaoEstoque = modo;
  }

  // Método para verificar e configurar automaticamente o modo offline com base na licença
  Future<void> verificarEConfigurarModoOffline(String produtorId) async {
    try {
      // Verificar estado atual do modo offline
      final prefs = await SharedPreferences.getInstance();
      bool userDefinedSetting = prefs.containsKey('offlineFirst_$produtorId');

      // Se o usuário já configurou, respeitar a configuração
      if (userDefinedSetting) {
        _isOfflineFirstEnabled =
            prefs.getBool('offlineFirst_$produtorId') ?? false;
        print(
            'Usando configuração de modo offline-first definida pelo usuário: $_isOfflineFirstEnabled');
        return;
      }

      // Toda vez que inicializar a primeira vez o app, forço a definição false para isOfflineFirstMode
      _isOfflineFirstEnabled = false;
      return;

      // Se não tiver configuração do usuário, definir com base na licença
      final Produtor? produtor = await ProdutorService().getById(produtorId);
      if (produtor == null) return;

      bool temLicencaAvancada = produtor.licencas?.any((licenca) {
            String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
            return ProdutorService().isLicencaValida(produtor, tipoLicenca) &&
                ['AcessoCompletoMedioProdutor', 'LicencaPermanente', 'Admin']
                    .contains(tipoLicenca);
          }) ??
          false;

      // Definir configuração padrão baseada na licença
      await prefs.setBool('offlineFirst_$produtorId', temLicencaAvancada);
      _isOfflineFirstEnabled = temLicencaAvancada;

      print(
          'Modo offline-first configurado automaticamente para: $temLicencaAvancada (produtor: $produtorId)');
    } catch (e) {
      print('Erro ao configurar modo offline-first: $e');
    }
  }

  // Método para verificar se o produtor tem licença avançada
  bool _verificarLicencaAvancada(Produtor produtor) {
    return produtor.licencas?.any((licenca) {
          String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
          return ['AcessoCompletoMedioProdutor', 'LicencaPermanente', 'Admin']
              .contains(tipoLicenca);
        }) ??
        false;
  }

  // Método para definir o modo offline-first
  Future<bool> setOfflineFirstMode(String produtorId, bool enabled) async {
    try {
      // 1. Verificar se está online - só permitir mudança quando online
      if (!_isOnline || !_lastKnownRealConnection) {
        print(
            'Não é possível alterar o modo offline-first enquanto estiver offline');
        return false;
      }

      // 2. Verificar permissão
      if (!canChangeOfflineFirstMode()) {
        print('Usuário não tem permissão para alterar modo offline-first');
        return false;
      }

      // Armazenar modo anterior para comparação
      bool previousMode = _isOfflineFirstEnabled;

      // Não fazer nada se o modo não mudar
      if (previousMode == enabled) {
        return true;
      }

      // 3. Atualizar preferência
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offlineFirst_$produtorId', enabled);
      _isOfflineFirstEnabled = enabled;

      // 4. Limpar caches relacionados ao modo offline
      GenericService.clearOfflineFirstModeCache();

      // 5. Processar fila offline e atualizar listeners se online
      if (_isOnline && _lastKnownRealConnection) {
        // Processar fila offline primeiro
        await OfflineQueueManager.processQueue();

        // Atualizar FirestoreListeners para o novo modo
        if (_firestoreListeners != null) {
          await _firestoreListeners.updateOfflineFirstMode(enabled);
        }

        // Ações adicionais baseadas no modo
        // Realizar a transição de modo com sincronização apropriada
        await _performModeTransitionSync(enabled);
      }

      // 6. Notificar mudança
      notifyListeners();

      print(
          'Modo offline-first alterado com sucesso para: $enabled (produtor: $produtorId)');
      return true;
    } catch (e) {
      print('Erro ao definir modo offline-first: $e');
      return false;
    }
  }

  /// Limpa todo o cache relacionado ao produtor atual
  Future<void> _cleanAllProducerCache() async {
    if (_activeProdutor == null) return;

    try {
      print('DEBUG: Iniciando limpeza completa do cache para produtor: ${_activeProdutor!.id}');
      final box = await Hive.openBox(LocalCacheManager.CACHE_BOX);
      int removedCount = 0;

      // Identificar todas as entradas relacionadas ao produtor
      final keysToRemove = box.keys.where((key) {
        final keyStr = key.toString();
        if (!keyStr.contains(':')) return false;

        final data = box.get(key);
        if (data == null || !(data is Map)) return false;

        // Incluir o próprio produtor e todos os documentos relacionados
        return data['produtorId'] == _activeProdutor!.id ||
            (keyStr.startsWith('produtores:') && keyStr.endsWith(_activeProdutor!.id));
      }).toList();

      // Remover em lotes para melhor performance
      for (var key in keysToRemove) {
        await box.delete(key);
        removedCount++;
      }

      print('DEBUG: ${removedCount} entradas removidas do cache para o produtor ${_activeProdutor!.id}');
    } catch (e) {
      print('ERRO: Falha ao limpar cache do produtor: $e');
    }
  }

  /// Realiza a sincronização apropriada durante transição de modo offline-first
  Future<void> _performModeTransitionSync(bool newMode) async {
    // Verificar se já existe uma sincronização em andamento
    if (_syncInProgress) {
      print('DEBUG: Sincronização já em andamento, ignorando solicitação adicional');
      return;
    }

    _syncInProgress = true;
    try {
      print('DEBUG: Iniciando sincronização para transição de modo: ${newMode ? "offline-first" : "firestore-direto"}');

      if (newMode) {
        // Habilitando modo offline-first:
        // 1. Limpar todo o cache relacionado ao produtor para garantir consistência
        await _cleanAllProducerCache();

        // 2. Recarregar todos os dados no cache
        print('DEBUG: Carregando todos os dados no cache para modo offline-first');
        await PreloadAllData.loadAllData();

        // 3. Executar sincronização e processamento de movimentações
        await _performSyncAndProcessMovimentacoes();
      } else {
        // Desabilitando modo offline-first:
        // Apenas garantir que o cache esteja consistente, mas não é necessário
        // recarregar todos os dados, pois o Firestore SDK cuidará disso
        await _validateCacheConsistency();
      }

      print('DEBUG: Sincronização para transição de modo concluída');
    } catch (e) {
      print('ERRO: Falha na sincronização de transição de modo: $e');
    } finally {
      // Garantir que o flag seja sempre limpo, mesmo em caso de erro
      _syncInProgress = false;
    }
  }

  // Método para verificar se o modo está habilitado
  Future<void> _loadIsOffllineFirstEnabled(SharedPreferences prefs) async {
    final String? produtorId = _activeProdutor?.id;
    bool enabled = false;

    if (produtorId != null) {
      enabled = prefs.getBool('offlineFirst_$produtorId') ?? false;
      print('Modo offline-first: $enabled (produtor: $produtorId)');
    } else {
      print('Nenhum produtor ativo, modo offline-first desativado');
    }

    _isOfflineFirstEnabled = enabled;
  }

  Future<void> _loadUserPermissions(bool notify) async {
    if (_activeProdutor != null) {
      final userRole = _activeProdutor?.permissoes.firstWhere(
        (p) =>
            (p['usuarioId'] == currentUserId) ||
            (p['email'] != null && p['email'] == currentUserEmail),
        orElse: () => const <String, String>{},
      )['role'];

      if (userRole != null && Permissions.roles.containsKey(userRole)) {
        _userPermissions = Permissions.roles[userRole]!;
        _currentUserRole = userRole;
      } else {
        _userPermissions = {};
      }
      // Adicionar ao final do método
      await updateMovimentacaoEstoquePermissions();

      if (notify) notifyListeners();
    }
  }

  bool _hasPermission(List<String> roles) {
    if (_activeProdutor == null) return false;
    final produtor = _activeProdutor!;
    final permissao = produtor.permissoes.firstWhere(
      (p) =>
          (p['usuarioId'] == currentUserId) ||
          (p['email'] != null && p['email'] == currentUserEmail),
      orElse: () => const <String, String>{},
    );
    if (permissao.isEmpty) return false;
    return roles.contains(permissao['role']);
  }

  bool canView(String moduleName) {
    if (_activeProdutor == null) return false;
    bool roleHasPermission = _userPermissions[moduleName]?['canView'] ?? false;
    if (!roleHasPermission) return false;
    return hasModuleAccess(moduleName);
  }

  bool canEdit(String moduleName) {
    bool roleHasPermission = _userPermissions[moduleName]?['canEdit'] ?? false;
    if (!roleHasPermission) return false;
    return hasModuleAccess(moduleName);
  }

  bool canDelete(String moduleName) {
    bool roleHasPermission =
        _userPermissions[moduleName]?['canDelete'] ?? false;
    if (!roleHasPermission) return false;
    return hasModuleAccess(moduleName);
  }

  bool hasModuleAccess(String module) {
    if (_activeProdutor == null) return false;
    final produtorService = ProdutorService();
    bool hasLicense = _activeProdutor!.licencas?.any((licenca) {
          String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
          if (produtorService.isLicencaValida(_activeProdutor!, tipoLicenca)) {
            return Licenses.canAccessModule(tipoLicenca, module);
          }
          return false;
        }) ??
        false;

    if (!hasLicense) {
      hasLicense = Licenses.canAccessModule('AcessoBasico', module);
    }
    return hasLicense;
  }

  bool canEditProdutor(Produtor produtor) {
    final permissao = produtor.permissoes.firstWhere(
      (p) =>
          (p['usuarioId'] == currentUserId) ||
          (p['email'] != null && p['email'] == currentUserEmail),
      orElse: () => const <String, String>{},
    );
    return permissao.isNotEmpty &&
        permissao['role'] != null &&
        Permissions.roles[permissao['role']]?['produtores']?['canEdit'] == true;
  }

  bool canDeleteProdutor(Produtor produtor) {
    final permissao = produtor.permissoes.firstWhere(
      (p) =>
          (p['usuarioId'] == currentUserId) ||
          (p['email'] != null && p['email'] == currentUserEmail),
      orElse: () => const <String, String>{},
    );
    return permissao.isNotEmpty &&
        permissao['role'] != null &&
        Permissions.roles[permissao['role']]?['produtores']?['canDelete'] ==
            true;
  }

  Future<bool> checkCanCreateMoreProdutores() async {
    final licenca = _activeProdutor?.licencas?.firstWhere(
        (licenca) => licenca['tipo'] != null,
        orElse: () => {'tipo': 'AcessoBasico'});
    String licenseType = licenca?['tipo'] ?? 'AcessoBasico';
    int? maxProdutores = Licenses.getMaxProdutores(licenseType);

    final User? currentUser = _authenticatedUser;

    if (currentUser != null && _isOnline && _lastKnownRealConnection) {
      _numProdutoresCriados =
          await ProdutorService().getNumberOfProdutoresCriados();
    }

    if (maxProdutores != null) {
      if (_numProdutoresCriados > maxProdutores) {
        _canCreateMoreProdutores = false;
      } else {
        _canCreateMoreProdutores = true;
      }
    } else {
      _canCreateMoreProdutores = true;
    }
    return _canCreateMoreProdutores;
  }

  Future<bool> checkCanCreateMorePropriedades() async {
    if (!hasActiveProdutor) return false;

    final licenca = _activeProdutor?.licencas?.firstWhere(
        (licenca) => licenca['tipo'] != null,
        orElse: () => {'tipo': 'AcessoBasico'});

    String licenseType = licenca?['tipo'] ?? 'AcessoBasico';
    int? maxPropriedades = Licenses.getMaxPropriedades(licenseType);

    if (maxPropriedades == null) return true;

    final propriedades =
        await PropriedadeService().getByProdutorId(_activeProdutor!.id);
    int numPropriedades = propriedades.length;

    return numPropriedades < maxPropriedades;
  }

  Future<void> setShowTutorial(String screenName, bool value) async {
    _showTutorial[screenName] = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$screenName', value);
  }

  Future<void> toggleDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale, bool notify) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String localeString = newLocale.toLanguageTag();
    await prefs.setString('appLocale', localeString);
    _appLocale = LocaleExtension.fromString(localeString);

    Intl.defaultLocale = localeString;
    formatacaoUtil.updateLocale(_appLocale);

    if (notify) notifyListeners();
    if (_isOnline && _lastKnownRealConnection) {
      await _carregarDadosIniciais();
    }
  }

  Future<void> setIsFirstRun(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isFirstRun = value;
    await prefs.setString('isFirstRun', value.toString());
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasOnline = _isOnline;
    bool wasRealConnection = _lastKnownRealConnection;

    _isOnline = result != ConnectivityResult.none;

    if (_isOnline) {
      // Verifica imediatamente e agenda uma nova verificação em 3 segundos
      _checkRealConnection(false).then((_) async {
        if (_lastKnownRealConnection && !wasRealConnection) {
          // Quando voltamos a ficar online, sincronizar
          try {
            print('DEBUG: Conexão restaurada. Iniciando sincronização com servidor (modo: ${_isOfflineFirstEnabled ? "offline-first" : "firestore-direto"})');

            // Primeiro processar a fila offline completamente
            print('DEBUG: Processando fila de operações offline pendentes');
            await OfflineQueueManager.processQueue();

            // Gerenciar listeners baseado no modo
            if (_isOfflineFirstEnabled) {
              // Modo offline-first: precisamos de listeners customizados Hive+Firestore
              print('DEBUG: Atualizando listeners para modo offline-first');
              if (_firestoreListeners.isListening()) {
                await _firestoreListeners.stopListening();
                await Future.delayed(Duration(milliseconds: 200));
                await _firestoreListeners.startListening();
              } else {
                await _firestoreListeners.startListening();
              }
            } else {
              // Modo Firestore direto: apenas configura os listeners básicos se necessário
              print('DEBUG: Configurando listeners básicos para modo Firestore direto');
              if (_firestoreListeners.isListening()) {
                await _firestoreListeners.stopListening();
              }
              // No modo Firestore direto, usamos apenas configuração básica
              await _firestoreListeners.startListening();
            }

            // Usar o modo atual para sincronizar adequadamente
            await _performModeTransitionSync(_isOfflineFirstEnabled);
          } catch (e) {
            print('Erro durante sincronização online: $e');
          }
        }

        if (wasOnline != _isOnline ||
            wasRealConnection != _lastKnownRealConnection) {
          notifyListeners();
        }
      });
    } else if (wasOnline) {
      // Quando entramos em modo offline
      _lastKnownRealConnection = false;
      print('Dispositivo passou para modo offline. Usando cache local.');

      // Sempre paramos os listeners para economizar recursos
      _firestoreListeners.stopListening();

      notifyListeners();
    }
  }

  /// Método dedicado para garantir a sincronização antes de processar movimentações
  /// Método dedicado para garantir a sincronização antes de processar movimentações
  Future<void> _performSyncAndProcessMovimentacoes() async {
    try {
      print('DEBUG: Iniciando sincronização antes do processamento de movimentações');

      // Comportamento específico para cada modo
      if (_isOfflineFirstEnabled) {
        // MODO OFFLINE-FIRST:
        print('DEBUG: Executando sincronização no modo offline-first');

        // 1. Limpar cache obsoleto
        await _cleanStaleCache();

        // 2. Validar consistência do cache Hive (versão otimizada)
        final validationStart = DateTime.now();
        print('DEBUG: Iniciando validação de cache Hive com timeout de 180s');
        try {
          // CORRIGIDO: usando a sintaxe correta para o método timeout
          await _validateCacheConsistency().timeout(Duration(seconds: 180))
              .catchError((e) {
            if (e is TimeoutException) {
              print('DEBUG: Validação de cache interrompida após 180s (timeout)');
            } else {
              throw e;
            }
          });
        } catch (e) {
          print('AVISO: Erro durante validação de cache: $e - continuando com processamento');
        }
        print('DEBUG: Validação de cache finalizada em ${DateTime.now().difference(validationStart).inMilliseconds}ms');
      } else {
        // MODO FIRESTORE DIRETO:
        print('DEBUG: Executando sincronização no modo Firestore direto');

        // No modo Firestore direto, vamos aguardar um breve período para
        // permitir que o SDK do Firestore sincronize seu cache internamente
        print('DEBUG: Aguardando sincronização interna do SDK do Firestore (500ms)');
        await Future.delayed(Duration(milliseconds: 500));

        // Verificar apenas dados críticos
        if (_activeProdutor != null) {
          try {
            await FirebaseFirestore.instance
                .collection('produtores')
                .doc(_activeProdutor!.id)
                .get()
                .timeout(Duration(seconds: 3));
          } catch (e) {
            print('AVISO: Erro ao verificar produtor ativo: $e - continuando com processamento');
          }
        }
      }

      // PROCESSAMENTO DE MOVIMENTAÇÕES (comum a ambos os modos)
      // Após toda a sincronização estar completa
      print('DEBUG: Sincronização concluída, iniciando processamento de movimentações');
      await _startProcessingMovimentacoes();

    } catch (e) {
      print('Erro durante sincronização e processamento: $e');
    }
  }

  Future<void> _startProcessingMovimentacoes() async {
    if (!_isOnline || !_lastKnownRealConnection) {
      print('Dispositivo offline: processamento de movimentações suspenso');
      return;
    }

    try {
      print('Verificando operações offline antes de iniciar processamento...');

      // Verifica se há operações pendentes ou em andamento
      if (await OfflineQueueManager.hasPendingOperations() ||
          OfflineQueueManager.isProcessing()) {
        print(
            'Operações offline pendentes ou em andamento. Processando fila antes de continuar...');
        // Processa a fila offline completamente de forma síncrona
        await OfflineQueueManager.processQueue(forceSynchronous: true);
        print('Sincronização offline concluída.');
      }

      // Agora que a sincronização está concluída, processar as movimentações
      print(
          'Iniciando processamento de movimentações contábeis e de estoque...');
      MovimentacaoEstoqueProcessor processor = MovimentacaoEstoqueProcessor();
      await processor.processarMovimentacoesPendentes();
      await LancamentoContabilProcessor().processarLancamentosPendentes();
    } catch (e) {
      print('Erro ao iniciar processamento de movimentações: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  Future<void> _checkRealConnection(bool notify) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final newConnectionStatus =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (newConnectionStatus != _lastKnownRealConnection) {
        _lastKnownRealConnection = newConnectionStatus;
        print('Conexão real atualizada para $_lastKnownRealConnection');
        if (notify) notifyListeners();
      }
    } on SocketException catch (_) {
      if (_lastKnownRealConnection) {
        _lastKnownRealConnection = false;
        print('Falha na verificação de conexão real.');
        if (notify) notifyListeners();
      }
    }
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkRealConnection(true);
    });
  }

  @override
  void dispose() {
    stopFirestoreListeners();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  void resetProducerChanged() {
    _producerChanged = false;
  }

  Future<void> _loadActiveProdutor(SharedPreferences prefs) async {
    ProdutorService produtorService = ProdutorService();
    String? activeProdutorId = prefs.getString('activeProdutorId');
    if (activeProdutorId != null) {
      try {
        print(
            'appStateManager - _loadActiveProdutor - Antes de carregar produtor ativo - isOnline: $_isOnline');

        // Primeiramente, tentar do cache para ser mais rápido
        final cachedData = await LocalCacheManager.readFromCache(
            'produtores', activeProdutorId);
        if (cachedData != null) {
          _activeProdutor =
              produtorService.fromMap(cachedData, activeProdutorId);
          print('Produtor carregado do cache: $activeProdutorId');

          // Carregar as definições de modo offline
          await _loadIsOffllineFirstEnabled(prefs);

          // Se estamos online e não em modo offline-first, tentar atualizar com dados do servidor
          if (_isOnline &&
              _lastKnownRealConnection &&
              !_isOfflineFirstEnabled) {
            try {
              final serverProdutor =
                  await produtorService.getById(activeProdutorId);
              if (serverProdutor != null) {
                _activeProdutor = serverProdutor;
                print('Produtor atualizado do servidor: $activeProdutorId');
              }
            } catch (e) {
              print('Erro ao atualizar produtor do servidor: $e');
              // Já temos dados do cache, então podemos continuar
            }
          }
        } else if (_isOnline && _lastKnownRealConnection) {
          // Nenhum cache disponível, tentar do servidor se online
          _activeProdutor = await produtorService.getById(activeProdutorId);

          // Carregar as definições de modo offline
          await _loadIsOffllineFirstEnabled(prefs);
        } else {
          // Offline e sem cache
          print('Offline e sem cache para produtor $activeProdutorId');
          await prefs.remove('activeProdutorId');
          return;
        }

        if (_activeProdutor != null) {
          await _loadUserPermissions(false);
          if (_isOnline && _lastKnownRealConnection) {
            await _runDatabaseMigrations(activeProdutorId);
          }
        } else {
          await prefs.remove('activeProdutorId');
        }
      } catch (e) {
        print('Erro ao carregar produtor ativo: $e');
        await prefs.remove('activeProdutorId');
      }
    }
  }

  Future<void> _loadActivePropriedade(SharedPreferences prefs) async {
    PropriedadeService propriedadeService = PropriedadeService();
    String? activePropriedadeId = prefs.getString('activePropriedadeId');
    if (activePropriedadeId != null) {
      try {
        if (_isOnline && _lastKnownRealConnection) {
          _activePropriedade =
              await propriedadeService.getById(activePropriedadeId);
        } else {
          final cachedData = await LocalCacheManager.readFromCache(
              'propriedades', activePropriedadeId);
          if (cachedData != null) {
            _activePropriedade =
                propriedadeService.fromMap(cachedData, activePropriedadeId);
            print('Propriedade carregada do cache: $activePropriedadeId');
          }
        }

        if (_activePropriedade != null) {
          _currentModoMovimentacaoEstoque =
              _activePropriedade!.modoMovimentacaoEstoque;
        } else {
          await prefs.remove('activePropriedadeId');
        }
      } catch (e) {
        print('Erro ao carregar propriedade ativa: $e');
        await prefs.remove('activePropriedadeId');
      }
    }
  }

  Future<void> _loadActiveAtividadeRural(SharedPreferences prefs) async {
    String? activeAtividadeRuralId = prefs.getString('activeAtividadeRuralId');
    if (activeAtividadeRuralId != null && _activePropriedade != null) {
      try {
        AtividadeRuralService atividadeRuralService = AtividadeRuralService();
        if (_isOnline && _lastKnownRealConnection) {
          _activeAtividadeRural =
              await atividadeRuralService.getById(activeAtividadeRuralId);
        } else {
          final cachedData = await LocalCacheManager.readFromCache(
              'atividadesRurais', activeAtividadeRuralId);
          if (cachedData != null) {
            _activeAtividadeRural = atividadeRuralService.fromMap(
                cachedData, activeAtividadeRuralId);
            print(
                'Atividade rural carregada do cache: $activeAtividadeRuralId');
          }
        }

        if (_activeAtividadeRural == null) {
          await prefs.remove('activeAtividadeRuralId');
        }
      } catch (e) {
        print('Erro ao carregar atividade rural ativa: $e');
        await prefs.remove('activeAtividadeRuralId');
      }
    }
  }

  Future<void> _cleanStaleCache() async {
    if (!_isOnline || !_lastKnownRealConnection) return;

    final box = await Hive.openBox(LocalCacheManager.CACHE_BOX);
    final now = DateTime.now();

    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data['cached_at'] != null) {
        final cachedAt = DateTime.parse(data['cached_at']);
        if (now.difference(cachedAt).inHours > 24) {
          await box.delete(key);
        }
      }
    }
  }

  Future<void> _validateCacheConsistency() async {
    if (!_isOnline || _isCacheValidationInProgress) return;

    try {
      _isCacheValidationInProgress = true;
      final box = await Hive.openBox(LocalCacheManager.CACHE_BOX);

      if (_activeProdutor != null) {
        final validationBatchSize = 20; // Processar em lotes de 20
        final keysToProcess = box.keys.where((key) {
          final keyStr = key.toString();
          if (!keyStr.contains(':')) return false;

          final collection = keyStr.split(':')[0];
          final data = box.get(key);

          if (data == null || !(data is Map)) return false;

          return (data['produtorId'] == _activeProdutor!.id ||
              collection == 'produtores');
        }).toList();

        // Processar em lotes para não sobrecarregar
        for (int i = 0; i < keysToProcess.length; i += validationBatchSize) {
          final endIdx = (i + validationBatchSize < keysToProcess.length)
              ? i + validationBatchSize
              : keysToProcess.length;
          final batch = keysToProcess.sublist(i, endIdx);

          for (var key in batch) {
            final keyStr = key.toString();
            final collection = keyStr.split(':')[0];
            final id = keyStr.split(':')[1];

            try {
              final doc = await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(id)
                  .get();
              if (!doc.exists) {
                await box.delete(key);
                print(
                    'Documento $keyStr removido do cache por não existir no Firestore');
              }
            } catch (e) {
              print('Erro ao validar documento $key: $e');
            }

            // Pequena pausa para não sobrecarregar
            await Future.delayed(Duration(milliseconds: 10));
          }

          // Pausa entre lotes
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      print('Erro durante validação de consistência do cache: $e');
    } finally {
      _isCacheValidationInProgress = false;
    }
  }

  List<String> getAllowedModoMovimentacaoEstoqueOptions() {
    if (_activeProdutor == null) return ['Desativado'];

    bool hasAdminLicense = false;
    bool hasAdvancedLicense = false;

    for (var licenca in _activeProdutor!.licencas ?? []) {
      String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
      if (ProdutorService().isLicencaValida(_activeProdutor!, tipoLicenca)) {
        if (tipoLicenca == 'Admin') {
          hasAdminLicense = true;
          break; // Admin tem acesso máximo
        } else if (tipoLicenca != 'AcessoBasico') {
          hasAdvancedLicense = true;
        }
      }
    }

    // Todas as opções possíveis
    List<String> allOptions = PropriedadeOptions.modoMovimentacaoEstoque;

    if (hasAdminLicense) {
      return List.from(
          allOptions); // Todas as opções (Auto, Manual, Desativado)
    } else if (hasAdvancedLicense) {
      return allOptions
          .where((option) => option != 'Auto')
          .toList(); // Apenas Manual e Desativado
    } else {
      return ['Desativado']; // Apenas Desativado
    }
  }

  Future<void> updateMovimentacaoEstoquePermissions() async {
    final activeProdutor = _activeProdutor;

    if (activeProdutor == null) {
      _canMovimentarEstoque = false;
      return;
    }

    // Verifica se tem alguma licença que não seja a básica
    bool hasValidLicense = activeProdutor.licencas?.any((licenca) {
          String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
          return ProdutorService()
                  .isLicencaValida(activeProdutor, tipoLicenca) &&
              tipoLicenca != 'AcessoBasico';
        }) ??
        false;

    _canMovimentarEstoque = hasValidLicense;
    notifyListeners();
  }

  bool isModoMovimentacaoEstoqueAllowed(String modo) {
    return getAllowedModoMovimentacaoEstoqueOptions().contains(modo);
  }

  Future<void> validateCurrentModoMovimentacaoEstoque() async {
    if (_activePropriedade == null) return;

    List<String> allowedOptions = getAllowedModoMovimentacaoEstoqueOptions();

    // Se o modo atual não está permitido, mudar para Desativado
    if (!allowedOptions.contains(_activePropriedade!.modoMovimentacaoEstoque)) {
      final propriedadeService = PropriedadeService();
      final propriedade =
          _activePropriedade!.copyWith(modoMovimentacaoEstoque: 'Desativado');

      await propriedadeService.update(propriedade.id, propriedade);
      _activePropriedade = propriedade;
      _currentModoMovimentacaoEstoque = 'Desativado';
      notifyListeners();
    }
  }

  // Add this method to check if the user can change offline-first mode based on license
  bool canChangeOfflineFirstMode() {
    final activeProdutor = _activeProdutor;
    if (activeProdutor == null) return false;

    // Check if user has any license beyond basic
    bool hasValidAdvancedLicense = activeProdutor.licencas?.any((licenca) {
          String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
          return ProdutorService()
                  .isLicencaValida(activeProdutor, tipoLicenca) &&
              tipoLicenca != 'AcessoBasico';
        }) ??
        false;

    return hasValidAdvancedLicense;
  }

  List<Map<String, dynamic>> getOfflineFirstModeOptions() {
    final canChange = canChangeOfflineFirstMode();

    // If user can't change, return only the current option
    if (!canChange) {
      return [
        {'value': _isOfflineFirstEnabled, 'enabled': false}
      ];
    }

    // If user can change, return both options
    return [
      {'value': true, 'enabled': true},
      {'value': false, 'enabled': true}
    ];
  }

  // Helper method to get a localized string for the current mode
  String getLocalizedOfflineFirstMode(BuildContext context) {
    return _isOfflineFirstEnabled
        ? S.of(context).offline_first_enabled
        : S.of(context).offline_first_disabled;
  }
}
