import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/agro_ad_service.dart';

/// Widget que exibe um banner de anúncio AdMob.
/// Gerencia automaticamente o ciclo de vida do banner.
///
/// Uso:
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: AgroBannerWidget(
///     adUnitId: 'ca-app-pub-XXX/YYY', // opcional, usa teste se null
///   ),
/// )
/// ```
class AgroBannerWidget extends StatefulWidget {
  const AgroBannerWidget({
    super.key,
    this.adUnitId,
    this.size = AdSize.banner,
  });

  /// ID da unidade de anúncio. Se null, usa ID de teste.
  final String? adUnitId;

  /// Tamanho do banner. Padrão: 320x50 (AdSize.banner).
  final AdSize size;

  @override
  State<AgroBannerWidget> createState() => _AgroBannerWidgetState();
}

class _AgroBannerWidgetState extends State<AgroBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = AgroAdService.instance.createBanner(
      adUnitId: widget.adUnitId,
      size: widget.size,
      onLoaded: () {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onFailed: (error) {
        if (mounted) {
          setState(() => _isLoaded = false);
        }
      },
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Espaço reservado para evitar layout shift
      return SizedBox(
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
      );
    }

    return SizedBox(
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
