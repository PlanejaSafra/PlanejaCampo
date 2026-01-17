import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/screens/welcome_screen.dart';
import 'package:planejacampo/screens/home_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  _InitializationScreenState createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeAppState();
  }

  Future<void> _initializeAppState() async {
    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.initializeApp();

      if (!mounted) return;

      if (appStateManager.hasActiveProdutor && appStateManager.hasActivePropriedade) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const WelcomeScreen()));
      }
    } catch (e) {
      debugPrint("Erro ao inicializar o aplicativo: $e");
      rethrow; // Permite que o erro seja capturado no FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text(
                  "Inicializando a aplicação...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Erro ao carregar a aplicação.",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializationFuture = _initializeAppState();
                    });
                  },
                  child: const Text("Tentar novamente"),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
