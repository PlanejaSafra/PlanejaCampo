# RuraRubber

**Real-time Weighing Calculator and Rubber Farming Marketplace.**

RuraRubber removes the chaos from weighing day. Replace the field notebook and paper scraps with an app focused on agility, designed to be used with one hand in the middle of the rubber plantation. Plus, connect directly with buyers in your region.

## Fluxo do Usuário

1. **Login**: Autenticação com Google ou Anônimo
2. **Termos e Privacidade**: Aceite obrigatório dos termos
3. **Seleção de Perfil**: Escolha entre **Produtor** ou **Comprador**
4. **Dashboard (Home)**: Visão geral personalizada com resumos e ações rápidas

## Funcionalidades Principais

### 📱 Módulo 1: Romaneio Digital (Produtor/Sangrador)

Uma calculadora inteligente que substitui anotações manuais.

*   **Dashboard Personalizado**:
    *   Resumo do mês (entregas, peso total, valor)
    *   Entregas recentes com status
    *   Ações rápidas (Nova Pesagem, Parceiros, Histórico)
*   **Pesagem Rápida ("Calculadora de Padaria")**:
    *   Interface de botões grandes para digitação rápida.
    *   Modo acumulador: `120kg + 95kg + ...`
    *   Troca rápida entre parceiros (Sr. João, D. Maria).
*   **Gestão de Parceiros "Set-and-Forget"**:
    *   Configure a % do parceiro uma única vez.
    *   Vincule talhões específicos a cada sangrador.
*   **Fechamento Financeiro Automático**:
    *   Digite o preço do DRC ou Banca uma vez só.
    *   O app calcula o rateio exato (50%, 40%, etc.) instantaneamente.
    *   Gera recibo em PDF para envio via WhatsApp.

### 🤝 Módulo 2: O Mercado (Compradores e Ofertas)

Classificados geolocalizados para venda de produção.

*   **Mural de Ofertas**:
    *   Usineiros e compradores de banca publicam preços de referência.
*   **Matchmaking Inteligente**:
    *   Receba apenas ofertas relevantes para a região da sua propriedade (Raio KM).
*   **Negociação Direta**:
    *   Botão "Tenho Interesse" abre conversa direta no WhatsApp do comprador.

### 🏠 Módulo 3: Dashboard (Home)

Visão geral da operação baseada no perfil do usuário.

*   **Para Produtores**:
    *   Resumo mensal (entregas, peso, valor)
    *   Ações rápidas para pesagem e parceiros
    *   Entregas recentes
    *   Ofertas do mercado na região
*   **Para Compradores**:
    *   Minhas ofertas ativas
    *   Criar nova oferta
    *   Estatísticas de alcance

## Estrutura do Projeto

This app is part of the **RuraCamp** monorepo and uses the shared `agro_core` package.

*   **Arquitetura**: Consulte [ARCHITECTURE.md](ARCHITECTURE.md).
*   **Changelog**: Consulte [CHANGELOG.md](CHANGELOG.md).

