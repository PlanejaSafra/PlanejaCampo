import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for sharing weight data via various channels.
class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  /// Captures a widget as a PNG image using its RepaintBoundary key.
  Future<Uint8List?> captureWidgetAsImage(GlobalKey key,
      {double pixelRatio = 3.0}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Shares an image with optional text.
  Future<void> shareImage({
    required Uint8List imageBytes,
    required String fileName,
    String? text,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      rethrow;
    }
  }

  /// Shares plain text.
  Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  /// Opens WhatsApp with a pre-filled message.
  Future<bool> shareViaWhatsApp({
    required String message,
    String? phoneNumber,
  }) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final Uri whatsappUri;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Direct message to specific number
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
      } else {
        // General share (user picks contact)
        whatsappUri = Uri.parse('whatsapp://send?text=$encodedMessage');
      }

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
      return false;
    }
  }

  /// Shares weight data via WhatsApp with image.
  Future<void> shareWeightViaWhatsApp({
    required Uint8List imageBytes,
    required String partnerName,
    required double totalWeight,
    required String propertyName,
    required DateTime date,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'peso_${date.millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Format message
      final message = _formatWeightMessage(
        partnerName: partnerName,
        totalWeight: totalWeight,
        propertyName: propertyName,
        date: date,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
      );
    } catch (e) {
      debugPrint('Error sharing weight via WhatsApp: $e');
      rethrow;
    }
  }

  /// Formats weight message for sharing.
  String _formatWeightMessage({
    required String partnerName,
    required double totalWeight,
    required String propertyName,
    required DateTime date,
  }) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return '''
🌿 *RuraRubber - Pesagem*

👤 Parceiro: $partnerName
⚖️ Peso: ${totalWeight.toStringAsFixed(1)} kg
📍 Local: $propertyName
📅 Data: $dateStr $timeStr

_Enviado via RuraRubber_
''';
  }

  /// Generates a simple text summary for quick sharing.
  String generateQuickShareText({
    required String partnerName,
    required double totalWeight,
    required String propertyName,
    required DateTime date,
  }) {
    return _formatWeightMessage(
      partnerName: partnerName,
      totalWeight: totalWeight,
      propertyName: propertyName,
      date: date,
    );
  }
}
