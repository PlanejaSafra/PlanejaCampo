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
import 'models/cash_categoria.dart';
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
  Hive.registerAdapter(CashCategoriaAdapter());
  Hive.registerAdapter(LancamentoAdapter());
  Hive.registerAdapter(CentroCustoAdapter());

  // Initialize agro_core services
  await AgroPrivacyStore.init();

  // Register Backup & Deletion Providers (Before UserCloudService init)
  CloudBackupService.instance.registerProvider(CashBackupProvider());
  DataDeletionService.instance.registerDeletionProvider(CashDeletionProvider());

  // Initialize Cloud Services
  try {
    await UserCloudService.instance.init();
    await DataMigrationService.instance
        .runMigrations(); // Fix: runMigrations instead of init
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

  // Verify/Create Personal Farm if needed (CASH-09 logic handled in Home, but good to check here or just rely on Home)

  // Initialize RuraCash services
  try {
    await LancamentoService.instance.init();
  } catch (e) {
    debugPrint('LancamentoService initialization failed: $e');
  }

  try {
    await CentroCustoService.instance.init();
  } catch (e) {
    debugPrint('CentroCustoService initialization failed: $e');
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
      ],
      child: MaterialApp(
        title: 'RuraCash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
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
              'Gestão Financeira Rural Simples e Eficiente', // TODO: Localize
          appIcon: Icons.attach_money,
        ),
        routes: {
          '/home': (context) => const CashHomeScreen(),
          '/calculator': (context) => const CalculatorScreen(),
          '/centros': (context) => const CentroCustoScreen(),
          '/dre': (context) => const DreScreen(),
          '/settings': (context) => const ConfiguracoesScreen(),
        },
      ),
    );
  }
}
