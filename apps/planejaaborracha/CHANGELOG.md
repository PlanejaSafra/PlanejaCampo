# CHANGELOG - PlanejaBorracha

---

## Phase BORRACHA-05: O Mercado (Compradores e Ofertas)
### Status: [DONE]
**Priority**: 🟡 MEDIUM
**Objective**: Conectar produtores a compradores (Usinas/Bancas) através de um mural de ofertas geolocalizado e negociação direta via WhatsApp.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | **Perfil do Comprador**: Implementar cadastro com definição de Tipo (Indústria/Banca) e Regiões de Atuação (Raio km ou Cidades). | ✅ DONE |
| 5.2 | **Mural de Ofertas (Classificados)**: Criar sistema de publicação de propostas com Título, Preço DRC (Referência), Preço Banca (Úmido), Condições de Pagamento e Validade da oferta. | ✅ DONE |
| 5.3 | **Matchmaking Simples**: Implementar filtro de ofertas baseado na localização da propriedade do usuário (GeoHash) para mostrar apenas compradores relevantes. | ✅ DONE |
| 5.4 | **Botão "Tenho Interesse"**: Integrar deeplink para WhatsApp com mensagem pré-formatada ("Olá, vi sua oferta no PlanejaBorracha...") para iniciar negociação direta. | ✅ DONE |

### Files Modified
- `lib/models/market_offer.dart`
- `lib/screens/mercado_screen.dart`
- `lib/screens/criar_oferta_screen.dart`

---

## Phase BORRACHA-04: Fechamento Financeiro (O Pagamento)
### Status: [DONE]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Automatizar o cálculo de pagamentos e gerar recibos transparentes para os parceiros.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **Input de Preço Final**: Tela para entrada do Valor de Venda (R$/kg) ou DRC Médio apurado no romaneio. | ✅ DONE |
| 4.2 | **Mágica Automática (Cálculo)**: Implementar lógica que calcula instantaneamente o Total da Venda e a Parte do Parceiro baseado na porcentagem contratada. | ✅ DONE |
| 4.3 | **Gestão de Adiantamentos**: Campo para dedução de valores/vales já pagos ao parceiro. | ✅ DONE |
| 4.4 | **Recibo Transparente**: Gerar PDF simplificado com o resumo do romaneio e cálculo financeiro para envio via WhatsApp. | ✅ DONE |

### Files Modified
- `lib/screens/fechamento_entrega_screen.dart`
- `lib/services/pdf_service.dart`
- `lib/models/financeiro_helper.dart`

---

## Phase BORRACHA-03: Pesagem Rápida (UX "Calculadora de Padaria")
### Status: [DONE]
**Priority**: 🔴 CRITICAL
**Objective**: Criar uma interface focada em agilidade e uso com uma mão para o momento caótico da pesagem.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | **Teclado Numérico Customizado**: Implementar teclado com botões GRANDES para facilitar a digitação com mãos sujas ou em movimento. | ✅ DONE |
| 3.2 | **Modo Acumulador**: Lógica de soma contínua (120kg + 95kg + ...) com visualização clara da "fita de somar" (histórico de entradas). | ✅ DONE |
| 3.3 | **Troca Rápida de Contexto**: Permitir alternar a "Etiqueta" (Talhão/Tarefa) da pesagem atual com um único toque. | ✅ DONE |
| 3.4 | **Fluxo de Salvamento**: Botão "Concluir Parceiro" que salva o total, zera o acumulador e prepara a tela instantaneamente para o próximo parceiro. | ✅ DONE |

### Files Modified
- `lib/screens/pesagem_screen.dart`
- `lib/widgets/big_calculator_keypad.dart`
- `lib/widgets/tape_view_widget.dart`
- `lib/services/entrega_service.dart`

---

## Phase BORRACHA-02: Gestão de Parceiros (Set-and-Forget)
### Status: [DONE]
**Priority**: 🔴 CRITICAL
**Objective**: Configurar a "equipe" uma única vez para automatizar todos os cálculos futuros.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Cadastro de Parceiro**: Implementar entidade (Hive) com Nome, Foto e Telefone. | ✅ DONE |
| 2.2 | **Contrato Padrão**: Campo para definir a Porcentagem padrão do parceiro (ex: 40%, 50%) para automação financeira. | ✅ DONE |
| 2.3 | **Vinculação de Tarefas**: Interface para selecionar quais Talhões (do `agro_core`) o parceiro atende, ou opção simples "Propriedade Toda". | ✅ DONE |
| 2.4 | **Sincronização**: Garantir persistência offline robusta para acesso no campo. | ✅ DONE |

### Files Modified
- `lib/models/parceiro.dart`
- `lib/screens/parceiros_list_screen.dart`
- `lib/screens/parceiro_form_screen.dart`
- `lib/services/parceiro_service.dart`

---

## Phase BORRACHA-01: Initial Documentation & Planning

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Establish the foundational documentation and architecture for the PlanejaBorracha application, focusing on the "Real-Time Weighing Calculator" and Market features.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | Create `README.md` with product vision and features | ✅ DONE |
| 1.2 | Create `ARCHITECTURE.md` with models, screens, and roadmap | ✅ DONE |
| 1.3 | Create `CHANGELOG.md` structure | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `README.md` | MODIFY | Added features (Romaneio Digital, Mercado) |
| `ARCHITECTURE.md` | CREATE | Detailed architectural plan (Phase 1 & 2) |
| `CHANGELOG.md` | CREATE | Initial changelog setup |
