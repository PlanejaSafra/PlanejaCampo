import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/lista_chuvas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize privacy store
  await AgroPrivacyStore.init();

  runApp(const PlanejaChuvaApp());
}

class PlanejaChuvaApp extends StatelessWidget {
  const PlanejaChuvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planeja Chuva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AgroLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      home: const AgroOnboardingGate(
        home: ListaChuvasScreen(),
      ),
    );
  }
}
