import 'package:flutter/material.dart';

/// Full Privacy Policy screen with complete legal text.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Política de Privacidade - PlanejaCampo',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última atualização: Janeiro de 2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            '1. Introdução',
            'A PlanejaCampo valoriza sua privacidade e está comprometida em proteger seus dados pessoais. Esta Política de Privacidade explica quais dados coletamos, como os usamos e seus direitos sobre eles.',
          ),
          _buildSection(
            context,
            '2. Dados que Coletamos',
            'Dependendo de como você usa nossos aplicativos, podemos coletar:\n\n'
                '**Dados de Conta (se você fizer login com Google):**\n'
                '• Nome e email do Google\n'
                '• ID único de usuário\n'
                '• Foto de perfil (se disponível)\n\n'
                '**Dados de Uso dos Aplicativos:**\n'
                '• Registros agrícolas (chuvas, produção, etc.)\n'
                '• Informações de propriedades rurais\n'
                '• Configurações e preferências do aplicativo\n'
                '• Dados de localização (apenas se você fornecer)\n\n'
                '**Dados Técnicos:**\n'
                '• Tipo de dispositivo e versão do sistema operacional\n'
                '• Logs de erros e falhas (para melhorar o app)\n'
                '• Informações de uso anônimas (se você consentir)',
          ),
          _buildSection(
            context,
            '3. Como Usamos Seus Dados',
            'Utilizamos seus dados para:\n\n'
                '• Fornecer e melhorar nossos serviços\n'
                '• Sincronizar dados entre seus dispositivos (se você usar login)\n'
                '• Realizar backup na nuvem (se você usar login)\n'
                '• Gerar estatísticas e métricas personalizadas\n'
                '• Corrigir bugs e melhorar a estabilidade\n'
                '• Pesquisa agrícola agregada (APENAS se você consentir)\n\n'
                'Nós NÃO usamos seus dados para:\n'
                '• Vender para terceiros\n'
                '• Publicidade direcionada sem consentimento\n'
                '• Compartilhar dados identificáveis sem permissão',
          ),
          _buildSection(
            context,
            '4. Compartilhamento de Dados',
            'Seus dados pessoais NÃO são compartilhados, exceto:\n\n'
                '**Com seu consentimento explícito:**\n'
                '• Dados agregados e anonimizados para pesquisa\n'
                '• Métricas regionais sem identificação\n\n'
                '**Para cumprir a lei:**\n'
                '• Se exigido por ordem judicial\n'
                '• Para proteger direitos legais\n\n'
                '**Prestadores de serviço:**\n'
                '• Firebase (Google) - hospedagem e autenticação\n'
                '• Servidores seguros para armazenamento de backup',
          ),
          _buildSection(
            context,
            '5. Armazenamento de Dados',
            '**Modo Anônimo (sem login):**\n'
                '• Todos os dados ficam APENAS no seu dispositivo\n'
                '• Não enviamos nada para servidores\n'
                '• Você é responsável por backups locais\n\n'
                '**Modo com Login Google:**\n'
                '• Dados sincronizados na nuvem (Firebase)\n'
                '• Criptografados em trânsito e em repouso\n'
                '• Backup automático entre dispositivos\n'
                '• Armazenados em servidores seguros do Google',
          ),
          _buildSection(
            context,
            '6. Seus Direitos (LGPD)',
            'De acordo com a Lei Geral de Proteção de Dados (LGPD), você tem direito a:\n\n'
                '• **Acesso:** Ver quais dados temos sobre você\n'
                '• **Correção:** Corrigir dados incorretos\n'
                '• **Exclusão:** Deletar sua conta e todos os dados\n'
                '• **Portabilidade:** Exportar seus dados em formato JSON\n'
                '• **Revogação:** Retirar consentimentos a qualquer momento\n'
                '• **Informação:** Saber com quem compartilhamos dados\n\n'
                'Para exercer esses direitos, acesse Configurações > Privacidade no app.',
          ),
          _buildSection(
            context,
            '7. Consentimentos Opcionais',
            'Solicitamos seu consentimento separado para três finalidades:\n\n'
                '**7.1. Dados e Localização**\n'
                'Ao aceitar, você autoriza o uso dos seus registros (chuvas, preços, etc.) e localização para:\n'
                '• Gerar inteligência de mercado e relatórios comerciais\n'
                '• Licenciamento de dados agregados para terceiros\n'
                '• Análises preditivas para o setor agrícola\n'
                '• Previsão do tempo personalizada para sua propriedade\n'
                'Seus dados podem ser comercializados de forma agregada ou individual (sem nome/CPF) para empresas de qualquer setor.\n\n'
                '**7.2. Ofertas e Promoções**\n'
                'Ao aceitar, você pode receber comunicações de parceiros comerciais via:\n'
                '• Notificações push, email, SMS ou WhatsApp\n'
                '• Banners e conteúdo patrocinado no app\n'
                'Os parceiros NÃO são curados pela PlanejaCampo e podem incluir qualquer setor (agro, finanças, varejo, entretenimento, etc.).\n\n'
                '**7.3. Anúncios Personalizados**\n'
                'Ao aceitar, seus dados de perfil e comportamento de uso são compartilhados com redes de anúncios (Google Ads, Meta, etc.) para:\n'
                '• Exibir anúncios personalizados dentro e fora do app\n'
                '• Criar audiências personalizadas (custom/lookalike audiences)\n'
                '• Rastrear conversões e eficácia de campanhas\n\n'
                'Você pode alterar esses consentimentos a qualquer momento em Configurações > Privacidade.',
          ),
          _buildSection(
            context,
            '8. Segurança',
            'Implementamos medidas de segurança para proteger seus dados:\n\n'
                '• Criptografia SSL/TLS em todas as conexões\n'
                '• Autenticação segura via Google\n'
                '• Armazenamento criptografado no Firebase\n'
                '• Acesso restrito a dados pessoais\n'
                '• Monitoramento de segurança contínuo\n\n'
                'Apesar disso, nenhum sistema é 100% seguro. Use senhas fortes e proteja seu dispositivo.',
          ),
          _buildSection(
            context,
            '9. Retenção de Dados',
            '• **Dados de conta:** Mantidos enquanto sua conta estiver ativa\n'
                '• **Dados de uso:** Excluídos quando você deletar a conta\n'
                '• **Logs técnicos:** Mantidos por até 90 dias\n'
                '• **Dados agregados:** Anonimizados permanentemente\n\n'
                'Ao deletar sua conta, todos os dados identificáveis são removidos em até 30 dias.',
          ),
          _buildSection(
            context,
            '10. Crianças',
            'Nossos aplicativos não são direcionados a menores de 13 anos. Não coletamos intencionalmente dados de crianças. Se você acredita que coletamos dados de uma criança, entre em contato para que possamos removê-los.',
          ),
          _buildSection(
            context,
            '11. Alterações nesta Política',
            'Podemos atualizar esta Política de Privacidade periodicamente. Notificaremos sobre mudanças significativas através do aplicativo. Recomendamos revisar esta política regularmente.',
          ),
          _buildSection(
            context,
            '12. Cookies e Tecnologias Similares',
            'Nossos aplicativos móveis NÃO usam cookies. Armazenamos preferências localmente no dispositivo usando tecnologias seguras (Hive). Esses dados não são acessíveis por outros aplicativos.',
          ),
          _buildSection(
            context,
            '13. Transferência Internacional',
            'Se você usa nossos serviços de fora do Brasil, seus dados podem ser transferidos e armazenados em servidores do Google em outros países. Garantimos proteção adequada em conformidade com a LGPD.',
          ),
          _buildSection(
            context,
            '14. Contato',
            'Para questões sobre privacidade ou para exercer seus direitos:\n\n'
                '• Acesse Configurações > Sobre no aplicativo\n'
                '• Ou acesse Configurações > Privacidade para gerenciar dados\n\n'
                'Responderemos todas as solicitações em até 15 dias úteis.',
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2026 PlanejaCampo. Todos os direitos reservados.\nEsta política está em conformidade com a LGPD (Lei nº 13.709/2018).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
