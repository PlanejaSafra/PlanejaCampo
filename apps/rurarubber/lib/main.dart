import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agro_core/agro_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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
import 'services/borracha_deletion_provider.dart';
import 'screens/parceiros_list_screen.dart';
import 'screens/pesagem_screen.dart';
import 'screens/mercado_screen.dart';
import 'screens/criar_oferta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/lista_entregas_screen.dart';
import 'screens/job_list_screen.dart';
import 'screens/criar_vaga_screen.dart';
import 'models/recebivel.dart';
import 'models/conta_pagar.dart';
import 'models/despesa.dart';
import 'models/tabela_sangria.dart';
import 'services/recebivel_service.dart';
import 'services/conta_pagar_service.dart';
import 'services/despesa_service.dart';
import 'services/tabela_service.dart';
import 'services/onboarding_service.dart';
import 'screens/recebiveis_screen.dart';
import 'screens/contas_pagar_screen.dart';
import 'screens/break_even_screen.dart';
import 'screens/onboarding_screen.dart';

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
  // CORE-76: Safra adapter
  Hive.registerAdapter(SafraAdapter());
  // CORE-77 / RUBBER-24: Farm and Dependency adapters
  Hive.registerAdapter(FarmAdapter());
  Hive.registerAdapter(FarmTypeAdapter());
  Hive.registerAdapter(DependencyManifestAdapter());

  // Sync infrastructure adapters (required for OfflineQueueManager)
  Hive.registerAdapter(OfflineOperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(OperationPriorityAdapter());
  // RUBBER-18: Recebivel adapter
  Hive.registerAdapter(RecebivelAdapter());
  // RUBBER-19: ContaPagar adapters
  Hive.registerAdapter(FormaPagamentoAdapter());
  Hive.registerAdapter(ContaPagarAdapter());
  // RUBBER-20: Despesa adapters (Break-even)
  Hive.registerAdapter(CategoriaDespesaAdapter());
  Hive.registerAdapter(DespesaAdapter());
  // RUBBER-23: TabelaSangria adapter
  Hive.registerAdapter(TabelaSangriaAdapter());

  // RUBBER-26: Initialize Firebase (native config for Android/iOS)
  try {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Android and iOS rely on native configuration (google-services.json / GoogleService-Info.plist)
      // which are swapped by Gradle flavors.
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // RUBBER-26: App Check - only activate in release builds.
  // Debug builds skip App Check to avoid needing debug tokens during development.
  if (!kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint('App Check activation failed: $e');
    }
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

  // CORE-76: Initialize SafraService
  try {
    await SafraService.instance.init();
  } catch (e) {
    debugPrint('SafraService initialization failed: $e');
  }

  // CORE-77 / RUBBER-24: Initialize FarmService
  try {
    await FarmService.instance.init();
  } catch (e) {
    debugPrint('FarmService initialization failed: $e');
  }

  // CORE-77 / RUBBER-24: Initialize DependencyService
  try {
    await DependencyService.instance.init();
  } catch (e) {
    debugPrint('DependencyService initialization failed: $e');
  }

  // Initialize UserProfileService
  try {
    await UserProfileService.instance.init();
  } catch (e) {
    debugPrint('UserProfileService initialization failed: $e');
  }

  // RUBBER-18: Initialize RecebivelService
  try {
    await RecebivelService.instance.init();
  } catch (e) {
    debugPrint('RecebivelService initialization failed: $e');
  }

  // RUBBER-19: Initialize ContaPagarService
  try {
    await ContaPagarService.instance.init();
  } catch (e) {
    debugPrint('ContaPagarService initialization failed: $e');
  }

  // RUBBER-20: Initialize DespesaService (Break-even)
  try {
    await DespesaService.instance.init();
  } catch (e) {
    debugPrint('DespesaService initialization failed: $e');
  }

  // RUBBER-23: Initialize TabelaService
  try {
    await TabelaService.instance.init();
  } catch (e) {
    debugPrint('TabelaService initialization failed: $e');
  }

  // RUBBER-22: Initialize OnboardingService
  try {
    await OnboardingService.instance.init();
  } catch (e) {
    debugPrint('OnboardingService initialization failed: $e');
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

  // CORE-77 / RUBBER-24: Register deletion provider for LGPD
  try {
    DataDeletionService.instance
        .registerDeletionProvider(BorrachaDeletionProvider());
  } catch (e) {
    debugPrint('Failed to register BorrachaDeletionProvider: $e');
  }

  runApp(const RuraRubberApp());
}

class RuraRubberApp extends StatelessWidget {
  const RuraRubberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParceiroService()..init()),
        ChangeNotifierProvider(create: (_) => EntregaService()..init()),
        ChangeNotifierProvider.value(value: UserProfileService.instance),
        ChangeNotifierProvider.value(value: RecebivelService.instance),
        ChangeNotifierProvider.value(value: ContaPagarService.instance),
        ChangeNotifierProvider.value(value: DespesaService.instance),
        ChangeNotifierProvider.value(value: TabelaService.instance),
      ],
      child: MaterialApp(
        title: 'RuraRubber',
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
          appName: 'RuraRubber',
          appDescription:
              'Gerencie suas entregas e acompanhe a produção de borracha',
          appIcon: Icons.forest,
          appLogoLightPath: 'assets/images/rurarubber-icon.png',
          appLogoDarkPath: 'assets/images/rurarubber-icon.png',
          home: _ProfileGatedHome(),
        ),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/parceiros': (context) => const ParceirosListScreen(),
          '/pesagem': (context) => const PesagemScreen(),
          '/mercado': (context) => const MercadoScreen(),
          '/criar-oferta': (context) => const CriarOfertaScreen(),
          '/entregas': (context) => const ListaEntregasScreen(),
          '/jobs': (context) => const JobListScreen(),
          '/criar-vaga': (context) => const CriarVagaScreen(),
          '/recebiveis': (context) => const RecebiveisScreen(),
          '/contas-pagar': (context) => const ContasPagarScreen(),
          '/break-even': (context) => const BreakEvenScreen(),
          '/settings': (context) {
            final farm = FarmService.instance.getDefaultFarm();
            final uid = AuthService.currentUser?.uid ?? '';
            final isOwner = farm?.isOwner(uid) ?? true;
            return AgroSettingsScreen(
              isOwner: isOwner,
              onExportLocalBackup:
                  isOwner ? () => _handleExportLocalBackup(context) : null,
              onImportLocalBackup:
                  isOwner ? () => _handleImportLocalBackup(context) : null,
              onResetProfile: () async {
                await UserProfileService.instance.clearProfile();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            );
          },
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

/// Wrapper that checks onboarding and profile state.
/// If onboarding not complete, shows OnboardingScreen.
/// If profile not set, shows ProfileSelectionScreen.
/// Otherwise, shows HomeScreen.
class _ProfileGatedHome extends StatefulWidget {
  const _ProfileGatedHome();

  @override
  State<_ProfileGatedHome> createState() => _ProfileGatedHomeState();
}

class _ProfileGatedHomeState extends State<_ProfileGatedHome> {
  @override
  Widget build(BuildContext context) {
    // RUBBER-22: Check onboarding first
    if (!OnboardingService.instance.isOnboardingComplete) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {});
        },
      );
    }

    return Consumer<UserProfileService>(
      builder: (context, profileService, child) {
        if (!profileService.hasProfile) {
          return ProfileSelectionScreen(
            onProfileSelected: () {
              setState(() {});
            },
          );
        }

        // RUBBER-26: Property Name Gate (parity with RuraRain)
        return const _PropertyNameGate(
          child: HomeScreen(),
        );
      },
    );
  }
}

/// RUBBER-26: Gate that prompts for property name if using generic default name.
/// Parity with RuraRain's _PropertyNameGate.
class _PropertyNameGate extends StatefulWidget {
  final Widget child;

  const _PropertyNameGate({required this.child});

  @override
  State<_PropertyNameGate> createState() => _PropertyNameGateState();
}

class _PropertyNameGateState extends State<_PropertyNameGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Defer check to after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPrompt();
    });
  }

  Future<void> _checkAndPrompt() async {
    if (_hasChecked) return;

    if (shouldPromptForPropertyName()) {
      final defaultProperty = PropertyService().getDefaultProperty();
      if (defaultProperty != null && mounted) {
        await showPropertyNamePromptDialog(
          context,
          currentName: defaultProperty.name,
        );
      }
    }

    if (mounted) {
      setState(() {
        _hasChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
