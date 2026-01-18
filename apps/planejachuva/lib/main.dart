import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/lista_chuvas_screen.dart';
import 'services/chuva_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize privacy store
  await AgroPrivacyStore.init();

  // Initialize chuva service (registers adapter and opens box)
  await ChuvaService().init();

  runApp(const PlanejaChuvaApp());
}

class PlanejaChuvaApp extends StatefulWidget {
  const PlanejaChuvaApp({super.key});

  @override
  State<PlanejaChuvaApp> createState() => _PlanejaChuvaAppState();
}

class _PlanejaChuvaAppState extends State<PlanejaChuvaApp> {
  Locale? _selectedLocale; // null = auto (follow system)

  void _changeLocale(Locale? newLocale) {
    setState(() {
      _selectedLocale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planeja Chuva',
      debugShowCheckedModeBanner: false,
      locale: _selectedLocale, // null = auto, otherwise force locale
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
      home: AgroOnboardingGate(
        home: ListaChuvasScreen(
          onChangeLocale: _changeLocale,
          currentLocale: _selectedLocale,
        ),
      ),
    );
  }
}
