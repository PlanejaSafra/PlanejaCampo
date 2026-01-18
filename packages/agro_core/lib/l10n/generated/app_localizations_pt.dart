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

  @override
  String get drawerHome => 'Início';

  @override
  String get drawerSettings => 'Configurações';

  @override
  String get drawerPrivacy => 'Privacidade e Consentimentos';

  @override
  String get drawerAbout => 'Sobre';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageAuto => 'Automático';

  @override
  String get settingsAboutApp => 'Sobre o App';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutDescription => 'Este app faz parte da suíte PlanejaSafra, projetada para ajudar produtores rurais a gerenciar suas atividades no campo.';

  @override
  String get aboutOfflineFirst => '100% Offline-First: todos os seus dados ficam no seu dispositivo.';

  @override
  String get aboutSuite => 'Suíte PlanejaSafra';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get privacyTitle => 'Privacidade e Consentimentos';

  @override
  String get privacyTermsSection => 'Termos de Uso e Política de Privacidade';

  @override
  String get privacyTermsSummary => 'Ao usar este app, você concorda com nossos Termos de Uso e Política de Privacidade. Você pode consultar os documentos completos a qualquer momento.';

  @override
  String get privacyConsentsSection => 'Consentimentos de Compartilhamento';

  @override
  String get privacyConsentsDescription => 'Gerencie como seus dados podem ser usados. Todas as opções são opcionais.';

  @override
  String get consentShareAggregated => 'Compartilhar dados agregados';

  @override
  String get consentShareAggregatedDesc => 'Permitir que seus registros sejam usados anonimamente para estatísticas regionais.';

  @override
  String get consentReceiveRegionalMetrics => 'Receber métricas regionais';

  @override
  String get consentReceiveRegionalMetricsDesc => 'Receber insights baseados em dados agregados da comunidade.';

  @override
  String get consentPersonalizedAds => 'Anúncios personalizados';

  @override
  String get consentPersonalizedAdsDesc => 'Ver anúncios mais relevantes com base no seu uso.';

  @override
  String get privacySaved => 'Preferências salvas';

  @override
  String get chuvaAppTitle => 'Planeja Chuva';

  @override
  String get chuvaListaVaziaTitle => 'Nenhuma chuva registrada';

  @override
  String get chuvaListaVaziaSubtitle => 'Toque no + para registrar sua primeira chuva';

  @override
  String get chuvaAdicionarTitle => 'Registrar Chuva';

  @override
  String get chuvaEditarTitle => 'Editar Registro';

  @override
  String get chuvaCampoMilimetros => 'Milímetros (mm)';

  @override
  String get chuvaCampoMilimetrosHint => 'Ex: 25.5';

  @override
  String get chuvaCampoData => 'Data';

  @override
  String get chuvaCampoObservacao => 'Observação (opcional)';

  @override
  String get chuvaCampoObservacaoHint => 'Ex: Chuva forte à tarde';

  @override
  String get chuvaBotaoSalvar => 'SALVAR';

  @override
  String get chuvaBotaoCancelar => 'CANCELAR';

  @override
  String get chuvaBotaoExcluir => 'EXCLUIR';

  @override
  String get chuvaConfirmarExclusaoTitle => 'Excluir registro?';

  @override
  String get chuvaConfirmarExclusaoMsg => 'Tem certeza que deseja excluir este registro de chuva?';

  @override
  String chuvaRegistrada(String mm) {
    return 'Chuva de ${mm}mm registrada!';
  }

  @override
  String get chuvaAtualizada => 'Registro atualizado!';

  @override
  String get chuvaExcluida => 'Registro excluído';

  @override
  String get chuvaDesfazer => 'DESFAZER';

  @override
  String get chuvaTotalDoMes => 'Total do mês';

  @override
  String get chuvaMesAnterior => 'Mês anterior';

  @override
  String get chuvaEstatisticas => 'Estatísticas';

  @override
  String get chuvaEstatisticasTitle => 'Estatísticas de Chuva';

  @override
  String get chuvaTotalAno => 'Total do ano';

  @override
  String get chuvaMediaPorChuva => 'Média por chuva';

  @override
  String get chuvaMaiorRegistro => 'Maior registro';

  @override
  String get chuvaTotalRegistros => 'Total de registros';

  @override
  String get chuvaBackup => 'Backup';

  @override
  String get chuvaBackupTitle => 'Backup de Dados';

  @override
  String get chuvaExportarDados => 'Exportar dados';

  @override
  String get chuvaExportarDescricao => 'Gere um arquivo com todos os seus registros para guardar ou enviar.';

  @override
  String get chuvaImportarDados => 'Importar dados';

  @override
  String get chuvaImportarDescricao => 'Restaure registros a partir de um arquivo de backup.';

  @override
  String get chuvaExportarSucesso => 'Backup exportado com sucesso!';

  @override
  String chuvaImportarSucesso(int count) {
    return '$count registros importados!';
  }

  @override
  String chuvaImportarDuplicados(int count, int duplicados) {
    return '$count registros importados ($duplicados duplicados ignorados)';
  }

  @override
  String get chuvaErroValorInvalido => 'Digite um valor entre 0.1 e 500 mm';

  @override
  String get chuvaErroDataObrigatoria => 'Selecione uma data';

  @override
  String get chuvaErroArquivoInvalido => 'Arquivo de backup inválido';

  @override
  String get chuvaIntensidadeLeve => 'Chuva leve';

  @override
  String get chuvaIntensidadeModerada => 'Chuva moderada';

  @override
  String get chuvaIntensidadeForte => 'Chuva forte';

  @override
  String get chuvaSemRegistrosMes => 'Sem registros este mês';

  @override
  String get chuvaHoje => 'Hoje';

  @override
  String get chuvaOntem => 'Ontem';

  @override
  String get chuvaMm => 'mm';

  @override
  String chuvaRegistrosEncontrados(int count) {
    return '$count registros encontrados';
  }

  @override
  String chuvaConfirmarImportacao(int count) {
    return 'Importar $count registros?';
  }

  @override
  String get chuvaNenhumRegistroBackup => 'Nenhum registro para exportar';

  @override
  String get chuvaComparacaoMesAcima => 'Acima do mês anterior';

  @override
  String get chuvaComparacaoMesAbaixo => 'Abaixo do mês anterior';
}
