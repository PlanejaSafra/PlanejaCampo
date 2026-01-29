import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'models/lancamento.dart';
import 'models/centro_custo.dart';
import 'services/lancamento_service.dart';
import 'services/centro_custo_service.dart';
import 'services/cash_backup_provider.dart';
import 'services/cash_deletion_provider.dart';
import 'screens/home_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/centro_custo_screen.dart';
import 'screens/dre_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'screens/conta_pagar_screen.dart';
import 'screens/orcamento_screen.dart';
import 'screens/balanco_screen.dart';
import 'screens/fluxo_caixa_screen.dart';

import 'models/conta_pagar.dart';
import 'models/conta_receber.dart';
import 'models/orcamento.dart';
import 'models/conta.dart';
import 'models/receita.dart';
import 'models/transferencia.dart';
import 'services/conta_pagamento_service.dart';
import 'services/conta_recebimento_service.dart';
import 'services/orcamento_service.dart';
import 'services/conta_service.dart';
import 'services/receita_service.dart';
import 'services/transferencia_service.dart';
import 'screens/categorias_screen.dart';
import 'screens/contas_screen.dart';
import 'screens/receitas_screen.dart';
import 'screens/reconciliacao_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/premium_service.dart';
import 'theme/cash_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize App Check (Safe for Debug)
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    } else {
      // Debug provider for emulator/dev
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters - agro_core (Models)
  Hive.registerAdapter(PropertyAdapter());
  Hive.registerAdapter(TalhaoAdapter());
  Hive.registerAdapter(FarmAdapter());
  Hive.registerAdapter(FarmTypeAdapter());
  Hive.registerAdapter(SafraAdapter());

  // Register Hive Adapters - agro_core (Sync/Cloud/Privacy)
  Hive.registerAdapter(DependencyManifestAdapter()); // TypeId 22
  Hive.registerAdapter(OfflineOperationAdapter()); // TypeId 20
  Hive.registerAdapter(OperationTypeAdapter()); // TypeId 21
  Hive.registerAdapter(OperationPriorityAdapter()); // TypeId 100+ check core
  Hive.registerAdapter(DeviceInfoAdapter()); // TypeId ? Check core
  Hive.registerAdapter(ConsentDataAdapter()); // TypeId ? Check core
  Hive.registerAdapter(UserCloudDataAdapter()); // TypeId ? Check core

  // Register Hive Adapters - RuraCash
  Hive.registerAdapter(LancamentoAdapter());
  Hive.registerAdapter(CentroCustoAdapter());
  // CASH-26, 27
  Hive.registerAdapter(ContaPagarAdapter());
  Hive.registerAdapter(ContaReceberAdapter());
  Hive.registerAdapter(OrcamentoAdapter());
  Hive.registerAdapter(TipoPeriodoOrcamentoAdapter());
  // CASH-23, 24, 25
  Hive.registerAdapter(ContaAdapter());
  Hive.registerAdapter(TipoContaAdapter());
  Hive.registerAdapter(ReceitaAdapter());
  Hive.registerAdapter(TransferenciaAdapter());
  // CORE-96
  Hive.registerAdapter(CategoriaAdapter());

  // Initialize agro_core services
  await AgroPrivacyStore.init();

  // Register Backup & Deletion Providers (Before UserCloudService init)
  CloudBackupService.instance.registerProvider(CashBackupProvider());
  DataDeletionService.instance.registerDeletionProvider(CashDeletionProvider());

  // Initialize Cloud Services
  try {
    await UserCloudService.instance.init();
    await DataMigrationService.instance.runMigrations(); 
  } catch (e) {
    debugPrint('Cloud Services initialization failed: $e');
  }

  try {
    await PropertyService().init();
  } catch (e) {
    debugPrint('PropertyService initialization failed: $e');
  }

  try {
    await TalhaoService().init();
  } catch (e) {
    debugPrint('TalhaoService initialization failed: $e');
  }

  try {
    await SafraService.instance.init();
  } catch (e) {
    debugPrint('SafraService initialization failed: $e');
  }

  try {
    await FarmService.instance.init();
  } catch (e) {
    debugPrint('FarmService initialization failed: $e');
  }

  try {
    await DependencyService.instance.init();
  } catch (e) {
    debugPrint('DependencyService initialization failed: $e');
  }

  // Initialize RuraCash services
  try {
    await LancamentoService.instance.init();
    await CentroCustoService.instance.init();
    
    // Roadmap Services Initialization
    await CategoriaService().init();
    await CategoriaService().ensureDefaultCategorias(); // Ensure Core Categories
    
    await ContaPagamentoService().init();
    await ContaRecebimentoService().init();
    await OrcamentoService().init();
    // CASH-23, 24, 25
    await ContaService.instance.init();
    await ContaService.instance.ensureDefaultConta();
    await ReceitaService.instance.init();
    await TransferenciaService.instance.init();
    // CASH-30: Premium
    await PremiumService.instance.init();

  } catch (e) {
    debugPrint('RuraCash/Roadmap Services initialization failed: $e');
  }

  // Initialize AdMob
  try {
    await AgroAdService.instance.initialize();
  } catch (e) {
    debugPrint('AgroAdService initialization failed: $e');
  }

  runApp(const RuraCashApp());
}

class RuraCashApp extends StatelessWidget {
  const RuraCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: LancamentoService.instance),
        ChangeNotifierProvider.value(value: CentroCustoService.instance),
        ChangeNotifierProvider<CategoriaService>.value(value: CategoriaService()),
        ChangeNotifierProvider<ContaPagamentoService>.value(value: ContaPagamentoService()),
        ChangeNotifierProvider<ContaRecebimentoService>.value(value: ContaRecebimentoService()),
        ChangeNotifierProvider<OrcamentoService>.value(value: OrcamentoService()),
        ChangeNotifierProvider<ContaService>.value(value: ContaService()),
        ChangeNotifierProvider<ReceitaService>.value(value: ReceitaService()),
        ChangeNotifierProvider<TransferenciaService>.value(value: TransferenciaService()),
        ChangeNotifierProvider<PremiumService>.value(value: PremiumService()),
      ],
      child: _CashMaterialApp(),
    );
  }
}

/// CASH-31: Reactive MaterialApp that rebuilds theme on FarmType change.
class _CashMaterialApp extends StatefulWidget {
  @override
  State<_CashMaterialApp> createState() => _CashMaterialAppState();
}

class _CashMaterialAppState extends State<_CashMaterialApp> with WidgetsBindingObserver {
  FarmType? _currentType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentType = FarmService.instance.getDefaultFarm()?.type;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshType();
    }
  }

  void _refreshType() {
    final newType = FarmService.instance.getDefaultFarm()?.type;
    if (newType != _currentType) {
      setState(() => _currentType = newType);
    }
  }

  /// Called by context switcher widgets to update the theme.
  static void refreshTheme(BuildContext context) {
    context.findAncestorStateOfType<_CashMaterialAppState>()?._refreshType();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuraCash',
      debugShowCheckedModeBanner: false,
      theme: CashTheme.light(farmType: _currentType),
      darkTheme: CashTheme.dark(farmType: _currentType),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        CashLocalizations.delegate,
        AgroLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: CashLocalizations.supportedLocales,
      home: AgroAuthGate(
        home: const CashHomeScreen(),
        appName: 'RuraCash',
        appDescription:
            'Gestão Financeira Rural Simples e Eficiente',
        appIcon: Icons.attach_money,
      ),
      routes: {
        '/home': (context) => const CashHomeScreen(),
        '/calculator': (context) => const CalculatorScreen(),
        '/centros': (context) => const CentroCustoScreen(),
        '/dre': (context) => const DreScreen(),
        '/settings': (context) => const ConfiguracoesScreen(),
        '/contas_pagar': (context) => const ContaPagarScreen(),
        '/orcamentos': (context) => const OrcamentoScreen(),
        '/relatorios/balanco': (context) => const BalancoScreen(),
        '/relatorios/fluxo': (context) => const FluxoCaixaScreen(),
        '/categorias': (context) => const CategoriasScreen(),
        '/contas': (context) => const ContasScreen(),
        '/receitas': (context) => const ReceitasScreen(),
        '/reconciliacao': (context) => const ReconciliacaoScreen(),
        '/paywall': (context) => const PaywallScreen(),
      },
    );
  }
}
