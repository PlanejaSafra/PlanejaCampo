import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/screens/login_screen.dart';
import 'package:planejacampo/screens/welcome_screen.dart';
import 'package:planejacampo/screens/home_screen.dart';
import 'package:planejacampo/screens/initialization_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint("Erro na autenticação: ${snapshot.error}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text("Erro ao conectar com o servidor."),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return Consumer<AppStateManager>(
            builder: (context, appStateManager, _) {
              if (!appStateManager.isInitialized) {
                return const InitializationScreen();
              }

              if (!appStateManager.hasActiveProdutor || !appStateManager.hasActivePropriedade || appStateManager.debugMode) {
                return const WelcomeScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
