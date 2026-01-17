import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planejacampo/services/system/timestamp_adapter.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/firebase_service.dart';
import 'routes.dart';
import 'themes.dart';
import 'package:planejacampo/l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive
  await Hive.initFlutter();

  // Registra o adaptador do Timestamp
  Hive.registerAdapter(TimestampAdapter());

  // Inicializa o Firebase
  await FirebaseService.initializeFirebase();

  // Inicializa o gerenciador de estado do aplicativo
  final appStateManager = AppStateManager();
  await appStateManager.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appStateManager),
      ],
      child: const PlanejaCampo(),
    ),
  );
}

class PlanejaCampo extends StatelessWidget {
  const PlanejaCampo({super.key});

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);

    return MaterialApp(
      title: 'PlanejaCampo',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: appStateManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: appStateManager.appLocale ??
          WidgetsBinding.instance.window.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null || !supportedLocales.contains(locale)) {
          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return const Locale('en', 'US');
        }
        return locale;
      },
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return _buildErrorWidget(errorDetails);
        };
        return widget!;
      },
    );
  }

  // Widget personalizado para erros inesperados
  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ocorreu um erro inesperado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              errorDetails.exception.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
