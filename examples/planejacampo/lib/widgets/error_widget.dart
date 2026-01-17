import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({Key? key, required this.errorDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Text(
          'Oops! Algo deu errado.\nPor favor, reinicie o aplicativo.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}