import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/share_service.dart';

/// Visual card widget for sharing weight information.
/// Designed to be captured as an image for social sharing.
class WeightCardWidget extends StatelessWidget {
  final String partnerName;
  final double totalWeight;
  final String propertyName;
  final DateTime date;
  final List<double>? weighings;
  final GlobalKey? repaintKey;

  const WeightCardWidget({
    super.key,
    required this.partnerName,
    required this.totalWeight,
    required this.propertyName,
    required this.date,
    this.weighings,
    this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Widget card = Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32), // Dark green
            Color(0xFF4CAF50), // Light green
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with app branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forest,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Partner name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.fechamentoPartner,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main weight display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (weighings != null && weighings!.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${weighings!.length} ${l10n.pesagemTitle.toLowerCase()}s',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Property and date info
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  propertyName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'RuraCamp',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap with RepaintBoundary if key is provided
    if (repaintKey != null) {
      return RepaintBoundary(
        key: repaintKey,
        child: Material(
          color: Colors.transparent,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Dialog to preview and share the weight card.
/// Uses native system share (like WhatsApp, Teams, Drive, etc.)
class ShareWeightDialog extends StatefulWidget {
  final String partnerName;
  final double totalWeight;
  final String propertyName;
  final DateTime date;
  final List<double>? weighings;

  const ShareWeightDialog({
    super.key,
    required this.partnerName,
    required this.totalWeight,
    required this.propertyName,
    required this.date,
    this.weighings,
  });

  @override
  State<ShareWeightDialog> createState() => _ShareWeightDialogState();
}

class _ShareWeightDialogState extends State<ShareWeightDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    // Auto-share after a short delay to allow the widget to render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareCard();
    });
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    // Small delay to ensure the card is fully rendered
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final shareService = ShareService.instance;

      final imageBytes = await shareService.captureWidgetAsImage(_cardKey);
      if (imageBytes == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(BorrachaLocalizations.of(context)!.shareWeightError),
            ),
          );
        }
        return;
      }

      final fileName =
          'rurarubber_peso_${widget.date.millisecondsSinceEpoch}.png';
      final message = shareService.generateQuickShareText(
        partnerName: widget.partnerName,
        totalWeight: widget.totalWeight,
        propertyName: widget.propertyName,
        date: widget.date,
      );

      await shareService.shareImage(
        imageBytes: imageBytes,
        fileName: fileName,
        text: message,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BorrachaLocalizations.of(context)!.shareWeightError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The card to capture (hidden but rendered)
            WeightCardWidget(
              repaintKey: _cardKey,
              partnerName: widget.partnerName,
              totalWeight: widget.totalWeight,
              propertyName: widget.propertyName,
              date: widget.date,
              weighings: widget.weighings,
            ),

            const SizedBox(height: 16),

            // Loading indicator while sharing
            if (_isSharing)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.shareTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Utility function to show the share dialog.
Future<void> showShareWeightDialog(
  BuildContext context, {
  required String partnerName,
  required double totalWeight,
  required String propertyName,
  required DateTime date,
  List<double>? weighings,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ShareWeightDialog(
      partnerName: partnerName,
      totalWeight: totalWeight,
      propertyName: propertyName,
      date: date,
      weighings: weighings,
    ),
  );
}
