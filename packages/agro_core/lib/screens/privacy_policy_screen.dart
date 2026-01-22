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
            'Para operar o Ecossistema Digital, coletamos:\n\n'
                '**Dados de Conta e Perfil:**\n'
                '• Nome, email, telefone e foto (login Google)\n'
                '• ID único de usuário e credenciais de acesso\n'
                '• Outros dados que você optar por preencher (endereço, bio, qualificações)\n\n'
                '**Dados Agronômicos e de Negócios:**\n'
                '• Inventário, chuvas, produção, rebanho e tarefas\n'
                '• Ofertas de compras, vendas e serviços\n'
                '• Localização das propriedades (GPS)\n\n'
                '**Dados Técnicos e de Comportamento:**\n'
                '• Modelo do dispositivo, IP e sistema operacional\n'
                '• Interações com anúncios e funcionalidades do app',
          ),
          _buildSection(
            context,
            '3. Uso Comercial e Inteligência (Modelo de Negócio)',
            'Ao utilizar o aplicativo gratuitamente, você concorda que sustentamos a plataforma através de:\n\n'
                '**1. Geração de Inteligência de Mercado:**\n'
                'Processamos seus dados agronômicos de forma AGREGADA ou ANONIMIZADA para criar relatórios, estatísticas e índices de mercado que podem ser comercializados com parceiros do setor.\n\n'
                '**2. Conexão de Negócios (Matchmaking):**\n'
                'Utilizamos seus dados de perfil e ofertas para conectar você a potenciais compradores, vendedores ou prestadores de serviço.\n\n'
                '**3. Melhoria do Serviço:**\n'
                'Para aprimorar algoritmos de previsão climática, diagnóstico de pragas e recomendações de manejo.',
          ),
          _buildSection(
            context,
            '4. Compartilhamento de Dados',
            'Seus dados pessoais NÃO são compartilhados, EXCETO nas seguintes situações que você optou por ativar:\n\n'
                '**Rede de Negócios (Classificados):**\n'
                '• Seu Nome e WhatsApp tornam-se públicos para outros usuários da plataforma ao criar um anúncio\n\n'
                '**Inteligência Agronômica:**\n'
                '• Seus dados de produção e clima são compartilhados de forma ANONIMIZADA ou AGREGADA para compor estatísticas de mercado\n\n'
                '**Operadores Legais:**\n'
                '• Para cumprir ordens judiciais ou prevenir fraudes\n'
                '• Com provedores de infraestrutura (Google Cloud/Firebase) sob contrato de sigilo',
          ),
          _buildSection(
            context,
            '5. Armazenamento e Transferência Internacional',
            'Seus dados podem ser armazenados e processados no Brasil ou em qualquer outro país onde nós ou nossos parceiros (como Google/Firebase) mantenham servidores.\n\n'
                '**Modo Visitante (Sem Login):**\n'
                'Os dados agronômicos ficam prioritariamente no seu dispositivo, mas metadados técnicos (IP, logs) podem ser enviados para servidores para controle de segurança e anúncios.\n\n'
                '**Modo Conectado:**\n'
                'Dados são sincronizados na nuvem para backup e acesso multidispositivo, protegidos por criptografia em trânsito e repouso.',
          ),
          _buildSection(
            context,
            '6. Direitos do Usuário',
            'Você mantém controle sobre seus dados pessoais diretos (Nome/Email) e pode solicitar exclusão ou portabilidade a qualquer momento. Dados já anonimizados ou agregados em relatórios de inteligência não podem ser removidos, pois deixaram de ser pessoais.',
          ),
          _buildSection(
            context,
            '7. Termos Específicos (Nuclear Shield)',
            'Ao ativar funcionalidades específicas, você concorda com termos estendidos:\n\n'
                '**7.1. Rede de Negócios:**\n'
                'Você autoriza a exibição pública do seu perfil e ofertas. A plataforma não modera antecipadamente o conteúdo e não se responsabiliza por negociações.\n\n'
                '**7.2. Inteligência Agronômica:**\n'
                'Você concede licença perpétua e irrevogável para uso dos seus dados técnicos (clima, solo, produção) de forma anonimizada para composição de produtos de inteligência.',
          ),
          _buildSection(
            context,
            '8. Segurança',
            'Utilizamos criptografia padrão de mercado e autenticação segura. No entanto, nenhum sistema é infalível. Você é responsável por proteger suas credenciais de acesso.',
          ),
          _buildSection(
            context,
            '9. Uso Profissional e Restrição de Idade',
            'Este aplicativo é destinado exclusivamente a USO PROFISSIONAL por produtores rurais, técnicos e trabalhadores do setor agropecuário.\n\n'
                'Não é permitido o uso por menores de 18 anos. Não coletamos intencionalmente dados de crianças. Se identificarmos uma conta de menor, ela será encerrada.',
          ),
          _buildSection(
            context,
            '10. Alterações',
            'Podemos alterar esta política a qualquer momento para refletir novos modelos de negócio. O uso continuado do app implica aceitação das mudanças.',
          ),
          _buildSection(
            context,
            '11. Tecnologias de Armazenamento',
            'Utilizamos bancos de dados locais seguros e tecnologias de cache para garantir o funcionamento offline-first.',
          ),
          _buildSection(
            context,
            '12. Contato',
            'Dúvidas? Acesse Configurações > Sobre.',
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
