import 'package:flutter/material.dart';
import 'package:planejacampo/screens/home_screen.dart';
import 'package:planejacampo/screens/login_screen.dart';
import 'package:planejacampo/screens/finance_screen.dart';
import 'package:planejacampo/screens/appbar/settings_screen.dart';
import 'package:planejacampo/screens/teste1_screen.dart';
import 'package:planejacampo/screens/appbar/compra/compras_itens_choose_screen.dart';
import 'package:planejacampo/screens/appbar/compra/compras_checkout_form_screen.dart';
import 'package:planejacampo/auth_gate.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/screens/welcome_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case '/welcome':
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/finance':
        return MaterialPageRoute(builder: (_) => const FinanceScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/teste1':
        return MaterialPageRoute(builder: (_) => const Teste1Screen());
      /*
      case '/compras_itens_choose':
        final Map<String, dynamic>? args = settings.arguments as Map<String, dynamic>?;
        final List<ItemCompra> carrinho = args?['carrinho'] as List<ItemCompra>? ?? <ItemCompra>[];
        final void Function() onUpdate = args?['onUpdate'] as VoidCallback? ?? () {};
        return MaterialPageRoute(
          builder: (_) => ComprasItensChooseScreen(
            carrinho: carrinho,
            onUpdate: onUpdate,
          ),
        );
      case '/compras_checkout':
        final Map<String, dynamic>? args = settings.arguments as Map<String, dynamic>?;
        final List<ItemCompra> carrinho = args?['carrinho'] as List<ItemCompra>? ?? <ItemCompra>[];
        final void Function() onUpdate = args?['onUpdate'] as VoidCallback? ?? () {};
        return MaterialPageRoute(
          builder: (_) => ComprasCheckoutFormScreen(
            carrinho: carrinho,
            onUpdate: onUpdate,
          ),
        );
      */
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(
          child: Text('Rota não encontrada'),
        ),
      ),
    );
  }
}
