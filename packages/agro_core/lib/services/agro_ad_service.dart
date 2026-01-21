import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../privacy/agro_privacy_store.dart';

/// Serviço centralizado para gerenciar anúncios AdMob.
/// Integra com AgroPrivacyStore para respeitar consentimento LGPD.
class AgroAdService {
  AgroAdService._();
  static final instance = AgroAdService._();

  bool _initialized = false;

  /// IDs de teste do Google (para desenvolvimento)
  static const String testBannerIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIdIOS =
      'ca-app-pub-3940256099942544/2934735716';

  /// Inicializa o SDK de Mobile Ads.
  /// Deve ser chamado uma vez no main.dart após Firebase.initializeApp().
  Future<void> initialize() async {
    if (_initialized) return;

    await MobileAds.instance.initialize();

    // Configura se ads são personalizados ou não baseado no consentimento
    await _updateConsentStatus();

    _initialized = true;
    debugPrint('[AgroAdService] Initialized');
  }

  /// Atualiza o status de consentimento para ads personalizados.
  Future<void> _updateConsentStatus() async {
    final canPersonalize = AgroPrivacyStore.canShowPersonalizedAds;

    // Configura NonPersonalizedAds se usuário não consentiu
    final requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    debugPrint('[AgroAdService] Personalized ads: $canPersonalize');
  }

  /// Cria um AdRequest respeitando o consentimento do usuário.
  AdRequest createAdRequest() {
    final canPersonalize = AgroPrivacyStore.canShowPersonalizedAds;

    if (canPersonalize) {
      return const AdRequest();
    } else {
      // Anúncios não personalizados
      return const AdRequest(
        nonPersonalizedAds: true,
      );
    }
  }

  /// Cria um BannerAd com configuração padrão.
  ///
  /// [adUnitId] - ID da unidade de anúncio (use null para ID de teste).
  /// [size] - Tamanho do banner (padrão: AdSize.banner = 320x50).
  /// [onLoaded] - Callback quando o banner carrega.
  /// [onFailed] - Callback quando falha.
  BannerAd createBanner({
    String? adUnitId,
    AdSize size = AdSize.banner,
    VoidCallback? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) {
    final effectiveAdUnitId = adUnitId ??
        (Platform.isAndroid ? testBannerIdAndroid : testBannerIdIOS);

    return BannerAd(
      adUnitId: effectiveAdUnitId,
      size: size,
      request: createAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AgroAdService] Banner loaded: ${ad.adUnitId}');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AgroAdService] Banner failed: ${error.message}');
          ad.dispose();
          onFailed?.call(error);
        },
        onAdOpened: (ad) {
          debugPrint('[AgroAdService] Banner opened');
        },
        onAdClosed: (ad) {
          debugPrint('[AgroAdService] Banner closed');
        },
      ),
    );
  }

  /// Retorna o ID de teste apropriado para a plataforma.
  String get testBannerId =>
      Platform.isAndroid ? testBannerIdAndroid : testBannerIdIOS;
}
