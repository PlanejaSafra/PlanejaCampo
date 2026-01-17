import 'package:flutter/material.dart';

class Teste1Screen extends StatelessWidget {
  const Teste1Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste 1'),
      ),
      body: const Center(
        child: Text(
          'Tela de Testes 1',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
