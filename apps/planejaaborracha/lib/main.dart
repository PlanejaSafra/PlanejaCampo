import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agro_core/agro_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'models/parceiro.dart';
import 'models/entrega.dart';
import 'models/item_entrega.dart';
import 'models/user_profile.dart';
import 'services/parceiro_service.dart';
import 'services/entrega_service.dart';
import 'services/user_profile_service.dart';
import 'services/backup_service.dart';
import 'services/borracha_backup_provider.dart';
import 'screens/parceiros_list_screen.dart';
import 'screens/pesagem_screen.dart';
import 'screens/mercado_screen.dart';
import 'screens/criar_oferta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/lista_entregas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Initialize Privacy Store
  await AgroPrivacyStore.init();

  // Register Adapters
  Hive.registerAdapter(ParceiroAdapter());
  Hive.registerAdapter(ItemEntregaAdapter());
  Hive.registerAdapter(EntregaAdapter());
  Hive.registerAdapter(UserCloudDataAdapter());
  Hive.registerAdapter(DeviceInfoAdapter());
  Hive.registerAdapter(ConsentDataAdapter());
  Hive.registerAdapter(PropertyAdapter());
  Hive.registerAdapter(TalhaoAdapter());
  Hive.registerAdapter(UserProfileTypeAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize UserCloudService (depends on Firebase)
  try {
    await UserCloudService.instance.init();
  } catch (e) {
    debugPrint('UserCloudService initialization failed: $e');
  }

  // Initialize PropertyService (Shared)
  try {
    await PropertyService().init();
  } catch (e) {
    debugPrint('PropertyService initialization failed: $e');
  }

  // Initialize TalhaoService (Shared)
  try {
    await TalhaoService().init();
  } catch (e) {
    debugPrint('TalhaoService initialization failed: $e');
  }

  // Initialize UserProfileService
  try {
    await UserProfileService.instance.init();
  } catch (e) {
    debugPrint('UserProfileService initialization failed: $e');
  }

  // Initialize AdMob Service
  try {
    await AgroAdService.instance.initialize();
  } catch (e) {
    debugPrint('AgroAdService initialization failed: $e');
  }

  // Register BorrachaBackupProvider for cloud sync
  try {
    CloudBackupService.instance.registerProvider(BorrachaBackupProvider());
  } catch (e) {
    debugPrint('Failed to register BorrachaBackupProvider: $e');
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
        ChangeNotifierProvider.value(value: UserProfileService.instance),
      ],
      child: MaterialApp(
        title: 'PlanejaBorracha',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          BorrachaLocalizations.delegate,
          AgroLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AgroLocalizations.supportedLocales,
        home: const AgroAuthGate(
          appName: 'PlanejaBorracha',
          appDescription:
              'Gerencie suas entregas e acompanhe a produção de borracha',
          appIcon: Icons.forest,
          home: _ProfileGatedHome(),
        ),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/parceiros': (context) => const ParceirosListScreen(),
          '/pesagem': (context) => const PesagemScreen(),
          '/mercado': (context) => const MercadoScreen(),
          '/criar-oferta': (context) => const CriarOfertaScreen(),
          '/entregas': (context) => const ListaEntregasScreen(),
          '/settings': (context) => AgroSettingsScreen(
                onExportLocalBackup: () => _handleExportLocalBackup(context),
                onImportLocalBackup: () => _handleImportLocalBackup(context),
              ),
          '/profile-selection': (context) => ProfileSelectionScreen(
                onProfileSelected: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
        },
      ),
    );
  }

  static Future<void> _handleExportLocalBackup(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await BackupService.exportar();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Backup exportado com sucesso!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _handleImportLocalBackup(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      // Pick JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final parsed = BackupService.parseBackup(jsonString);
      final parceiros = parsed['parceiros'] as List;
      final entregas = parsed['entregas'] as List;

      final importResult = await BackupService.importar(
        parceiros.cast<Parceiro>(),
        entregas.cast<Entrega>(),
      );

      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            'Importado: ${importResult.importedParceiros} parceiros, '
            '${importResult.importedEntregas} entregas. '
            '${importResult.duplicates} duplicatas ignoradas.',
          ),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Wrapper that checks if user has selected a profile.
/// If not, shows ProfileSelectionScreen first.
class _ProfileGatedHome extends StatefulWidget {
  const _ProfileGatedHome();

  @override
  State<_ProfileGatedHome> createState() => _ProfileGatedHomeState();
}

class _ProfileGatedHomeState extends State<_ProfileGatedHome> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileService>(
      builder: (context, profileService, child) {
        if (!profileService.hasProfile) {
          return ProfileSelectionScreen(
            onProfileSelected: () {
              setState(() {});
            },
          );
        }

        return const HomeScreen();
      },
    );
  }
}
