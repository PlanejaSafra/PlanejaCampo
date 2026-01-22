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
            'Termos de Uso - PlanejaCampo',
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
            'Ao utilizar os aplicativos da família PlanejaCampo (incluindo PlanejaChuva, PlanejaBorracha, PlanejaDiesel e outros), você concorda com estes Termos de Uso. Se você não concorda com alguma parte destes termos, não deve utilizar nossos serviços.',
          ),
          _buildSection(
            context,
            '2. Descrição do Serviço',
            'Os aplicativos PlanejaCampo são ferramentas de gestão agrícola que permitem:\n\n'
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
            '4. Propriedade e Uso de Dados (Modelo Híbrido)',
            'Os dados inseridos pertencem a você e permanecem armazenados localmente no seu dispositivo por padrão (Offline-First).\n\n'
                'Nós NÃO acessamos, vendemos ou compartilhamos seus dados, EXCETO se você optar explicitamente por ativar as funcionalidades de:\n'
                '• Backup em Nuvem (armazenamento seguro vinculado à sua conta)\n'
                '• Rede de Negócios (dados de contato tornam-se públicos para ofertas)\n'
                '• Inteligência Agronômica (dados anonimizados compõem estatísticas de mercado)\n\n'
                'Ao ativar essas funções, você nos concede uma licença para processar e utilizar os dados conforme necessário para a prestação do serviço e geração de inteligência, conforme detalhado na Política de Privacidade.',
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
            '6. Limitação de Responsabilidade (Simulação e Apoio)',
            'ISENÇÃO TOTAL DE RESPONSABILIDADE:\n'
                'Os aplicativos são ferramentas de SIMULAÇÃO MATEMÁTICA e APOIO À DECISÃO. Eles NÃO substituem o julgamento profissional de um Engenheiro Agrônomo, Técnico, Veterinário ou Consultor Financeiro.\n\n'
                'Nós NÃO nos responsabilizamos, em nenhuma hipótese, por:\n'
                '• Perda de safra, morte de animais ou prejuízos financeiros\n'
                '• Erros de cálculo, dosagem, diagnóstico ou previsão meteorológica\n'
                '• Falhas em negociações, inadimplência ou qualidade de serviços contratados via Rede de Negócios\n'
                '• Ações de terceiros, acidentes ou eventos ocorridos no mundo físico (offline)\n\n'
                'O uso das informações fornecidas pelo aplicativo para tomada de decisão é de risco exclusivo e integral do usuário.',
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
            'Todo o conteúdo, design, código e funcionalidades dos aplicativos PlanejaCampo são protegidos por direitos autorais e outras leis de propriedade intelectual. Você não pode copiar, modificar ou distribuir nosso software sem autorização.',
          ),
          _buildSection(
            context,
            '9. Lei Aplicável',
            'Estes termos são regidos pelas leis do Brasil. Quaisquer disputas serão resolvidas nos tribunais competentes do Brasil.',
          ),
          _buildSection(
            context,
            '10. Coleta de Localização',
            'O aplicativo pode coletar sua localização aproximada ou precisa (GPS) para funcionalidades específicas, como previsão do tempo e estatísticas regionais. Ao utilizar esses recursos, você autoriza a coleta e uso desses dados. Você pode revogar o acesso à localização nas configurações do seu dispositivo a qualquer momento.',
          ),
          _buildSection(
            context,
            '11. Contato',
            'Para questões sobre estes Termos de Uso, entre em contato através do menu Configurações > Sobre no aplicativo.',
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2026 PlanejaCampo. Todos os direitos reservados.',
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
