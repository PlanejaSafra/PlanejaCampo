import 'package:flutter/material.dart';

enum MessagePosition { above, below, left, right, aboveLeft, aboveRight, belowLeft, belowRight, center }

class TutorialStep {
  final String message;
  final Offset position;
  final Size size;
  final MessagePosition messagePosition;
  final double messageDistance;
  final VoidCallback? onStepShow;

  TutorialStep({
    required this.message,
    required this.position,
    required this.size,
    required this.messagePosition,
    required this.messageDistance,
    this.onStepShow,
  });
}