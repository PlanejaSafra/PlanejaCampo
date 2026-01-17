import 'package:flutter/material.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/screens/appbar/produtores_list_screen.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/preload_all_data.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Don't set initialPage yet
    _initializationFuture = _checkOnlineStatusAndInitialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkOnlineStatusAndInitialize() async {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);

    while (!appStateManager.isOnline) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
    }

    if (appStateManager.isFirstRun) {
      await PreloadAllData.loadAllData();
      await appStateManager.setIsFirstRun(false);
    }

    if (!mounted) return;

    if (!appStateManager.hasActiveProdutor) {
      _currentPage = 0;
    } else if (!appStateManager.hasActivePropriedade) {
      _currentPage = 2;
    } else {
      _navigateToHome();
      return;
    }

    _pageController = PageController(initialPage: _currentPage);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appStateManager, child) {
        return FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen(context);
            } else if (snapshot.hasError) {
              return _buildErrorScreen(context);
            } else {
              return Scaffold(
                body: SafeArea(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildWelcomePage(context),
                      _buildSelectProdutorPage(context),
                      _buildSelectPropriedadePage(context),
                    ],
                  ),
                ),
                bottomNavigationBar: _buildNavigationBar(),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(S.of(context).loading_app),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              S.of(context).error_loading_app,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializationFuture = _checkOnlineStatusAndInitialize();
                });
              },
              child: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).welcome_producer,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).start_producer_registration,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildNavigationBar() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false); // Access appStateManager here

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Text(S.of(context).back),
            ),
          const Spacer(),
          TextButton(
            onPressed: () {
              if (_currentPage < 2) {
                _nextPage();
              } else if (appStateManager.hasActivePropriedade) { // Check if propriedade is selected
                _navigateToHome();
              } // No else needed; do nothing if no propriedade selected
            },
            child: Text(_currentPage < 2 ? S.of(context).next : S.of(context).finalize),
          ),
        ],
      ),
    );
  }




  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }



  Widget _buildSelectProdutorPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).select_producer,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).choose_or_register_producer,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            child: Text(S.of(context).select_producer_button),
            onPressed: () => _selectProdutor(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPropriedadePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).select_property,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).select_or_register_property,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            child: Text(S.of(context).select_property_button),
            onPressed: () => _selectPropriedade(),
          ),
        ],
      ),
    );
  }



  void _selectProdutor() async {
    final selectedProdutor = await Navigator.push<Produtor>(
      context,
      MaterialPageRoute(builder: (context) => ProdutoresListScreen(isSelectMode: true, isSetMode: true)),
    );

    if (selectedProdutor != null) {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.setActiveProdutor(selectedProdutor);
      _nextPage();
    }
  }

  void _selectPropriedade() async {
    final selectedPropriedade = await Navigator.push<Propriedade>(
      context,
      MaterialPageRoute(builder: (context) => PropriedadesListScreen(isSelectMode: true, isSetMode: true)),
    );

    if (selectedPropriedade != null) {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.setActivePropriedade(selectedPropriedade);
      _navigateToHome();
    }
  }


  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
    );
  }
}