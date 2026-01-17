import 'package:flutter/material.dart';
import 'tutorial_step.dart';

class TutorialTemplate extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onClose;

  const TutorialTemplate({
    Key? key,
    required this.steps,
    this.onClose,
  }) : super(key: key);

  @override
  TutorialTemplateState createState() => TutorialTemplateState();

  // Método estático para expandir o tamanho
  static Size expandSize(Size originalSize, double expansionFactor) {
    return Size(
      originalSize.width * expansionFactor,
      originalSize.height * expansionFactor,
    );
  }

  // Método estático para ajustar a posição
  static Offset adjustPosition(Offset originalPosition, Size originalSize, double expansionFactor) {
    double expandedWidth = originalSize.width * expansionFactor;
    double expandedHeight = originalSize.height * expansionFactor;
    return Offset(
      originalPosition.dx - (expandedWidth - originalSize.width) / 2,
      originalPosition.dy - (expandedHeight - originalSize.height) / 2,
    );
  }
}

class TutorialTemplateState extends State<TutorialTemplate> {
  int _currentStep = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeOverlay(); // Garante a remoção do overlay existente
      if (_overlayEntry == null) {
        _showTutorial();
      }
    });
  }

  void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTutorial() {
    //print('showTutorial called');
    
    // Força a remoção do OverlayEntry existente antes de criar um novo
    removeOverlay();

    if (!mounted || _overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildTutorialOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _invokeOnStepShow();
  }

  @override
  void dispose() {
    removeOverlay();
    super.dispose();
  }

  void _nextTutorialStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
        _overlayEntry?.markNeedsBuild();
        Future.delayed(Duration(milliseconds: 100), _invokeOnStepShow);
      });
    } else {
      removeOverlay();
      widget.onClose?.call();
    }
  }

  void _invokeOnStepShow() {
    if (!mounted) return;
    final currentStep = widget.steps[_currentStep];
    currentStep.onStepShow?.call();
  }

  Widget _buildTutorialOverlay() {
    //print('Building tutorial overlay for step $_currentStep');
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          //print('LayoutBuilder called for step $_currentStep');
          final step = widget.steps[_currentStep];
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

          // Calcular a altura e largura da mensagem
          final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: step.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: 200); // Largura máxima da mensagem

          double messageHeight = textPainter.height + 16; // Altura do texto + padding
          double messageWidth = 200;  // Largura padrão da mensagem

          Offset messagePosition = _calculateMessagePosition(step, screenSize, messageWidth, messageHeight);

          return GestureDetector(
            onTap: _nextTutorialStep,
            child: Container(
              color: Colors.black54,
              child: Stack(
                children: [
                  Positioned(
                    left: step.position.dx,
                    top: step.position.dy,
                    child: Container(
                      width: step.size.width,
                      height: step.size.height,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    left: messagePosition.dx,
                    top: messagePosition.dy,
                    child: Container(
                      width: messageWidth,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _calculateMessagePosition(TutorialStep step, Size screenSize, double messageWidth, double messageHeight) {
    Offset messagePosition;

    switch (step.messagePosition) {
      case MessagePosition.center:
        messagePosition = Offset(
          step.position.dx + (step.size.width - messageWidth) / 2,
          step.position.dy + (step.size.height - messageHeight) / 2,
        );
        break;
      case MessagePosition.above:
      case MessagePosition.aboveLeft:
      case MessagePosition.aboveRight:
        messagePosition = Offset(
          step.position.dx,
          step.position.dy - step.messageDistance - messageHeight,
        );
        break;
      case MessagePosition.below:
      case MessagePosition.belowLeft:
      case MessagePosition.belowRight:
        messagePosition = Offset(
          step.position.dx,
          step.position.dy + step.size.height + step.messageDistance,
        );
        break;
      case MessagePosition.left:
        messagePosition = Offset(
          step.position.dx - messageWidth - step.messageDistance,
          step.position.dy,
        );
        break;
      case MessagePosition.right:
        messagePosition = Offset(
          step.position.dx + step.size.width + step.messageDistance,
          step.position.dy,
        );
        break;
    }

    // Ajuste horizontal para aboveRight e belowRight
    if (step.messagePosition == MessagePosition.aboveRight ||
        step.messagePosition == MessagePosition.belowRight) {
      messagePosition = Offset(
        messagePosition.dx + step.size.width - messageWidth,
        messagePosition.dy,
      );
    }

    // Garante que a mensagem não saia da tela
    messagePosition = Offset(
      messagePosition.dx.clamp(0, screenSize.width - messageWidth),
      messagePosition.dy.clamp(0, screenSize.height - messageHeight),
    );

    return messagePosition;
  }

  @override
  Widget build(BuildContext context) {
    //print("TutorialTemplate is being rebuilt");
    return _buildTutorialOverlay();
  }
}