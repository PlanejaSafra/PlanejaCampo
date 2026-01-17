import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AgroLocalizationsPt extends AgroLocalizations {
  AgroLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'PlanejaSafra';

  @override
  String get continueLabel => 'CONTINUAR';

  @override
  String get acceptAndContinueLabel => 'ACEITAR E CONTINUAR';

  @override
  String get declineLabel => 'NÃO ACEITAR';

  @override
  String get declineAndExitLabel => 'NÃO ACEITAR (SAIR)';

  @override
  String get privacySettingsHint => 'Você pode consultar os documentos completos em Configurações → Privacidade.';

  @override
  String get termsTitle => 'Termos de Uso e Privacidade';

  @override
  String get termsBodyIntro => 'Ao tocar em \"Aceitar e continuar\", você concorda com os Termos de Uso e com a Política de Privacidade dos apps PlanejaSafra/PlanejaCampo.';

  @override
  String get termsSummaryTitle => 'Resumo do que acontece:';

  @override
  String get termsSummaryItem1 => 'Você registra informações como chuvas, preços, pesagens, anotações e lançamentos.';

  @override
  String get termsSummaryItem2 => 'Esses dados ficam armazenados no seu dispositivo para o app funcionar.';

  @override
  String get termsSummaryItem3 => 'O app pode exibir anúncios na versão gratuita.';

  @override
  String get termsSummaryItem4 => 'Podemos coletar informações técnicas mínimas (ex.: falhas e desempenho) para melhorar o app.';

  @override
  String get termsFooter => 'Você pode consultar os documentos completos em Configurações → Privacidade.';

  @override
  String get consentTitle => 'Recursos e compartilhamento (opcional)';

  @override
  String get consentIntro => 'Você pode usar o app em modo privado (offline), ou ativar recursos extras baseados em dados agregados da comunidade.\n\nMarque o que você autoriza:';

  @override
  String get consentOption1Title => 'Dados agregados para métricas regionais';

  @override
  String get consentOption1Desc => 'Usar seus registros de forma agregada e estatística para gerar indicadores como chuva por região, preço médio regional, tendências e comparativos.';

  @override
  String get consentOption2Title => 'Compartilhamento com parceiros (agregado)';

  @override
  String get consentOption2Desc => 'Compartilhar somente dados agregados/estatísticos com terceiros para relatórios, inteligência regional e melhorias.';

  @override
  String get consentOption3Title => 'Anúncios e ofertas mais relevantes';

  @override
  String get consentOption3Desc => 'Usar dados de uso para melhorar anúncios, promoções e sugestões (quando houver).';

  @override
  String get consentSmallNoteUnderDecline => 'Sem aceitar, você pode usar o app normalmente no modo privado (funções básicas offline).';
}
