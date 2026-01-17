import 'package:flutter/material.dart';

class CardSection {
  final String? title;
  final List<Widget> cards;
  final GlobalKey? key;
  final IconData? icon; // Novo parâmetro opcional

  CardSection({this.title, required this.cards, this.key, this.icon});
}
