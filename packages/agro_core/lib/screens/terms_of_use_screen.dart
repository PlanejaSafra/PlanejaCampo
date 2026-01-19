import 'package:flutter/material.dart';

/// Full Terms of Use screen with complete legal text.
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Termos de Uso - PlanejaSafra',
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
            '1. Aceitação dos Termos',
            'Ao utilizar os aplicativos da família PlanejaSafra (incluindo PlanejaChuva, PlanejaBorracha, PlanejaDiesel e outros), você concorda com estes Termos de Uso. Se você não concorda com alguma parte destes termos, não deve utilizar nossos serviços.',
          ),

          _buildSection(
            context,
            '2. Descrição do Serviço',
            'Os aplicativos PlanejaSafra são ferramentas de gestão agrícola que permitem:\n\n'
                '• Registro e acompanhamento de dados agrícolas (chuvas, produção, etc.)\n'
                '• Gerenciamento de propriedades rurais\n'
                '• Visualização de estatísticas e métricas\n'
                '• Backup e sincronização de dados na nuvem (opcional)\n'
                '• Compartilhamento de dados agregados para pesquisa (opcional)',
          ),

          _buildSection(
            context,
            '3. Conta de Usuário',
            'Você pode utilizar nossos aplicativos de duas formas:\n\n'
                '• Modo anônimo: sem criar conta, com dados armazenados apenas localmente\n'
                '• Com login Google: permite sincronização entre dispositivos e backup na nuvem\n\n'
                'Você é responsável por manter a confidencialidade de sua conta e por todas as atividades que ocorram sob sua conta.',
          ),

          _buildSection(
            context,
            '4. Propriedade de Dados',
            'Todos os dados que você insere nos aplicativos PlanejaSafra pertencem a você. Nós:\n\n'
                '• NÃO vendemos seus dados pessoais\n'
                '• NÃO compartilhamos dados identificáveis sem seu consentimento\n'
                '• Utilizamos dados agregados e anonimizados apenas se você consentir\n'
                '• Permitimos que você exporte ou delete seus dados a qualquer momento',
          ),

          _buildSection(
            context,
            '5. Uso Aceitável',
            'Ao usar nossos serviços, você concorda em NÃO:\n\n'
                '• Violar leis ou regulamentos aplicáveis\n'
                '• Tentar acessar ou interferir com sistemas de outros usuários\n'
                '• Usar o serviço para atividades fraudulentas ou enganosas\n'
                '• Sobrecarregar ou danificar a infraestrutura do serviço\n'
                '• Fazer engenharia reversa ou tentar extrair código-fonte',
          ),

          _buildSection(
            context,
            '6. Limitação de Responsabilidade',
            'Os aplicativos PlanejaSafra são fornecidos "como estão". Não garantimos:\n\n'
                '• Precisão absoluta de previsões ou métricas\n'
                '• Disponibilidade ininterrupta do serviço\n'
                '• Adequação para fins específicos\n\n'
                'Não somos responsáveis por perdas ou danos decorrentes do uso dos aplicativos, incluindo perda de dados ou lucros cessantes.',
          ),

          _buildSection(
            context,
            '7. Modificações do Serviço',
            'Reservamos o direito de:\n\n'
                '• Modificar ou descontinuar recursos a qualquer momento\n'
                '• Atualizar estes Termos de Uso\n'
                '• Suspender ou encerrar contas que violem os termos\n\n'
                'Notificaremos sobre mudanças significativas através do aplicativo.',
          ),

          _buildSection(
            context,
            '8. Propriedade Intelectual',
            'Todo o conteúdo, design, código e funcionalidades dos aplicativos PlanejaSafra são protegidos por direitos autorais e outras leis de propriedade intelectual. Você não pode copiar, modificar ou distribuir nosso software sem autorização.',
          ),

          _buildSection(
            context,
            '9. Lei Aplicável',
            'Estes termos são regidos pelas leis do Brasil. Quaisquer disputas serão resolvidas nos tribunais competentes do Brasil.',
          ),

          _buildSection(
            context,
            '10. Contato',
            'Para questões sobre estes Termos de Use, entre em contato através do menu Configurações > Sobre no aplicativo.',
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Center(
            child: Text(
              '© 2026 PlanejaSafra. Todos os direitos reservados.',
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
