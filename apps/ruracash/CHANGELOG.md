# CHANGELOG - RuraCash

> **Objetivo**: Controle de Despesas centralizado para toda a fazenda, integrando com todos os apps RuraCamp.

---

## Phase CASH-04: DRE Simplificado

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Demonstrativo do Resultado do Exercício da fazenda inteira.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **DreScreen**: Dashboard visual com receitas x despesas por centro de custo | ✅ DONE |
| 4.2 | **Filtro por Período**: SegmentedButton com Mês, Trimestre, Safra, Ano | ✅ DONE |
| 4.3 | **Category Breakdown**: Percentuais por categoria de despesa | ✅ DONE |
| 4.4 | **Result Card**: Margem de lucro com cores (verde/vermelho) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/dre_screen.dart` | CREATE | DRE dashboard com filtro de período, receitas, despesas por centro, resultado |

### Notes
- Receitas mostram R$ 0,00 até CASH-03 (Integração Ecossistema) ser implementado
- Despesas já funcionam com dados reais do LancamentoService

---

## Phase CASH-03: Integração com Ecossistema RuraCamp

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Sincronizar receitas e custos com os outros apps.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | **API de Receitas**: Endpoint para buscar receitas dos outros apps | ⏳ TODO |
| 3.2 | **Listener de Entregas**: Quando RuraRubber fecha entrega, notificar RuraCash | ⏳ TODO |
| 3.3 | **Push de Custos**: Enviar custo/kg para RuraRubber calcular margem | ⏳ TODO |
| 3.4 | **Sincronização Cloud**: Usar Firestore para sincronizar entre apps | ⏳ TODO |

---

## Phase CASH-02: Centro de Custo

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir alocar despesas para diferentes áreas da fazenda.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Modelo CentroCusto**: Hive typeId 72, FarmOwnedEntity, nome, icone, cor, appVinculado | ✅ DONE |
| 2.2 | **CentroCustoService**: Singleton ChangeNotifier com CRUD e default "Geral" | ✅ DONE |
| 2.3 | **CentroCustoScreen**: Tela de gerenciamento com lista, add bottom sheet, delete dialog | ✅ DONE |
| 2.4 | **Seletor in Calculator**: Dropdown de centro de custo na tela calculadora (quando >1 centro) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/centro_custo.dart` | CREATE | Modelo Hive typeId 72, FarmOwnedEntity, create/toJson/fromJson |
| `lib/models/centro_custo.g.dart` | GENERATE | build_runner adapter |
| `lib/services/centro_custo_service.dart` | CREATE | Singleton service com CRUD e default "Geral" |
| `lib/screens/centro_custo_screen.dart` | CREATE | Tela com lista, add bottom sheet, delete dialog |

---

## Phase CASH-01: MVP - Lançamento Rápido

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Permitir lançamento ultra-rápido de despesas com UX de calculadora.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | **Scaffold do App**: Criar estrutura com Hive, agro_core, l10n, main.dart | ✅ DONE |
| 1.2 | **Modelo Lancamento**: Hive typeId 71, FarmOwnedEntity, valor, categoria, data, centroCusto | ✅ DONE |
| 1.3 | **CashCategoria Enum**: Hive typeId 70, 7 categorias com ícones e cores | ✅ DONE |
| 1.4 | **Calculator Keypad**: Teclado numérico grande (7-8-9 / 4-5-6 / 1-2-3 / ,-0-⌫) | ✅ DONE |
| 1.5 | **Category Chips**: ChoiceChip com ícones coloridos, smart default (mais usada) | ✅ DONE |
| 1.6 | **Quick Save Flow**: Salvar com haptic feedback + toast, tela limpa para próximo | ✅ DONE |
| 1.7 | **Home Screen**: Lista de despesas do mês com total no topo, swipe-to-delete | ✅ DONE |
| 1.8 | **LancamentoService**: Singleton ChangeNotifier com CRUD, queries por período/categoria/centro | ✅ DONE |
| 1.9 | **L10n Setup**: ARB files pt/en com ~80 keys, CashLocalizations gerado | ✅ DONE |
| 1.10 | **Drawer**: buildCashDrawer() com navegação para calculator, centros, dre, settings | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | CREATE | Dependencies: agro_core, hive, provider, intl, pdf, printing |
| `l10n.yaml` | CREATE | Config output-class: CashLocalizations |
| `lib/l10n/arb/app_pt.arb` | CREATE | ~80 Portuguese l10n keys |
| `lib/l10n/arb/app_en.arb` | CREATE | ~80 English l10n keys |
| `lib/models/cash_categoria.dart` | CREATE | Enum Hive typeId 70, 7 categorias com ícone/cor/localizedName |
| `lib/models/cash_categoria.g.dart` | GENERATE | build_runner adapter |
| `lib/models/lancamento.dart` | CREATE | Modelo Hive typeId 71, FarmOwnedEntity, create/toJson/fromJson |
| `lib/models/lancamento.g.dart` | GENERATE | build_runner adapter |
| `lib/services/lancamento_service.dart` | CREATE | Singleton com CRUD, queries mês/período/categoria/centro, quickAdd, smart defaults |
| `lib/screens/calculator_screen.dart` | CREATE | Calculator-style keypad, category chips, centro dropdown, haptic save |
| `lib/screens/home_screen.dart` | CREATE | Monthly total card, expense list, swipe-to-delete, FAB |
| `lib/widgets/cash_drawer.dart` | CREATE | Standardized AgroDrawer helper |
| `lib/main.dart` | CREATE | Hive adapters, service init, MultiProvider, MaterialApp with routes |
| `analysis_options.yaml` | CREATE | Standard Flutter lints |
| `test/widget_test.dart` | MODIFY | Smoke test placeholder |

### Hive TypeIds

| TypeId | Model | Description |
|--------|-------|-------------|
| 70 | CashCategoria | Enum com 7 categorias de despesa |
| 71 | Lancamento | Lançamento financeiro com FarmOwnedEntity |
| 72 | CentroCusto | Centro de custo com FarmOwnedEntity |

### Categories

| Category | Icon | Color |
|----------|------|-------|
| Mão de Obra | people | blue |
| Adubo/Fertilizante | eco | green |
| Defensivos/Veneno | science | purple |
| Combustível/Diesel | local_gas_station | orange |
| Manutenção | build | grey |
| Energia/Água | bolt | amber |
| Outros | more_horiz | brown |

---

## Dependências

### De agro_core
- `PropertyService` (propriedades)
- `FarmService` (CORE-75) - Farm-centric model
- `SafraService` (CORE-76) - Janela temporal da safra
- `DependencyService` (CORE-77) - Dependency tracking
- `AgroOnboardingGate` (privacy/consent)
- `AppTheme` (visual consistente)
- `AgroLocalizations` (l10n compartilhado)
- `AgroAdService` (AdMob)

---

## Cross-Reference

| App | Integração |
|-----|------------|
| **RuraRubber** | CASH-03: Recebe entregas → Gera receitas no RuraCash |
| **RuraCattle** | CASH-03: Recebe vendas → Gera receitas no RuraCash |
| **CORE-75** | Farm model para dados vinculados à fazenda |
| **CORE-76** | Safra para DRE por período |
