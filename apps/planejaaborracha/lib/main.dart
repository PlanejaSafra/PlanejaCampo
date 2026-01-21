import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agro_core/agro_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'models/parceiro.dart';
import 'models/entrega.dart';
import 'models/item_entrega.dart';
import 'services/parceiro_service.dart';
import 'screens/parceiros_list_screen.dart';

import 'services/entrega_service.dart';
import 'screens/pesagem_screen.dart';
import 'screens/mercado_screen.dart';
import 'screens/criar_oferta_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ParceiroAdapter());
  Hive.registerAdapter(ItemEntregaAdapter());
  Hive.registerAdapter(EntregaAdapter());

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const PlanejaBorrachaApp());
}

class PlanejaBorrachaApp extends StatelessWidget {
  const PlanejaBorrachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParceiroService()..init()),
        ChangeNotifierProvider(create: (_) => EntregaService()..init()),
      ],
      child: MaterialApp(
        title: 'PlanejaBorracha',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AgroLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AgroLocalizations.supportedLocales,
        home: const AgroOnboardingGate(
          home: PesagemScreen(),
        ),
        routes: {
          '/parceiros': (context) => const ParceirosListScreen(),
          '/pesagem': (context) => const PesagemScreen(),
          '/mercado': (context) => const MercadoScreen(),
          '/criar-oferta': (context) => const CriarOfertaScreen(),
        },
      ),
    );
  }
}
