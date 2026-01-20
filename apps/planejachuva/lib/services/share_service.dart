import 'dart:io';
import 'dart:typed_data';

import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/registro_chuva.dart';
import '../widgets/rain_card_widget.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final ScreenshotController _screenshotController = ScreenshotController();

  /// Captures and shares a branded Rain Card for a specific record.
  ///
  /// Uses [invisibleWidget] approach via [ScreenshotController.captureFromWidget].
  Future<void> shareRainRecord(
    BuildContext context, {
    required RegistroChuva registro,
    required String propertyName,
  }) async {
    // Get l10n before async operations
    final l10n = AgroLocalizations.of(context);

    try {
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;

      // 1. Create the widget to capture
      // We wrap it in a Material/Theme to ensure it has styles available
      // even when rendered off-screen.
      final widgetToCapture = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Theme.of(context),
        home: Scaffold(
          body: Center(
            child: RainCardWidget(
              registro: registro,
              propertyName: propertyName,
            ),
          ),
        ),
      );

      // 2. Capture as image
      final Uint8List? imageBytes =
          await _screenshotController.captureFromWidget(
        widgetToCapture,
        delay: const Duration(milliseconds: 100),
        pixelRatio: pixelRatio,
        context: context,
      );

      if (imageBytes == null) {
        throw Exception("Failed to capture image");
      }

      // 3. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'rain_card_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(imageBytes);

      // 4. Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n?.chuvaShareMessage(propertyName) ??
            'Chuva registrada em $propertyName! 🌧️ #PlanejaCampo',
      );
    } catch (e) {
      debugPrint('Error sharing rain card: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(l10n?.chuvaShareError ?? 'Erro ao compartilhar: $e')),
        );
      }
    }
  }
}
