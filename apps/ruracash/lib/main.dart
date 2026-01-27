import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/cash_categoria.dart';
import 'models/lancamento.dart';
import 'models/centro_custo.dart';
import 'services/lancamento_service.dart';
import 'services/centro_custo_service.dart';
import 'screens/home_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/centro_custo_screen.dart';
import 'screens/dre_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters - agro_core
  Hive.registerAdapter(PropertyAdapter());
  Hive.registerAdapter(TalhaoAdapter());
  Hive.registerAdapter(FarmAdapter());
  Hive.registerAdapter(SafraAdapter());
  Hive.registerAdapter(DependencyManifestAdapter());

  // Sync infrastructure adapters (required for OfflineQueueManager)
  Hive.registerAdapter(OfflineOperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(OperationPriorityAdapter());

  // Register Hive Adapters - RuraCash
  Hive.registerAdapter(CashCategoriaAdapter());
  Hive.registerAdapter(LancamentoAdapter());
  Hive.registerAdapter(CentroCustoAdapter());

  // Initialize agro_core services
  await AgroPrivacyStore.init();

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
        home: AgroOnboardingGate(
          home: const CashHomeScreen(),
        ),
        routes: {
          '/home': (context) => const CashHomeScreen(),
          '/calculator': (context) => const CalculatorScreen(),
          '/centros': (context) => const CentroCustoScreen(),
          '/dre': (context) => const DreScreen(),
          '/settings': (context) => const AgroSettingsScreen(),
        },
      ),
    );
  }
}
