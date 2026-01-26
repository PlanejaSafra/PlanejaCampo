# CHANGELOG - RuraCash

> **Phase Prefix**: Phases use the `CASH-` prefix.
> Core infrastructure phases are documented in `packages/agro_core/CHANGELOG.md`.

---

## Phase CASH-05: Migração para GenericSyncService

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Migrar todos os services para `GenericSyncService` do agro_core, habilitando sync Firestore.
**Cross-Reference**: CORE-83

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | **CentroCustoService**: Migração para `GenericSyncService<CentroCusto>` com auto-create "Geral" | ✅ DONE |
| 5.2 | **LancamentoService**: Migração para `GenericSyncService<Lancamento>` com queries complexas | ✅ DONE |
| 5.3 | **Data Migration**: Lógica de migração de dados antigos (Adapter → Map) em ambos services | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/centro_custo_service.dart` | REFACTOR | Estende GenericSyncService, remove CRUD manual, mantém auto-create "Geral" |
| `lib/services/lancamento_service.dart` | REFACTOR | Estende GenericSyncService, remove CRUD manual, mantém queries de agregação |

---

## Phase CASH-04: Relatório Financeiro (DRE)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Demonstrativo de Resultados com filtros de período e exportação PDF.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **DreScreen**: Tela com filtros Mês/Trimestre/Safra/Ano | ✅ DONE |
| 4.2 | **Agregações**: totalPorMes, totalPorCategoria, totalPorCentroCusto, totalMensalAno | ✅ DONE |
| 4.3 | **PDF Export**: Exportação de relatório via pdf + printing | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/dre_screen.dart` | CREATE | Tela DRE com 4 filtros de período, gráfico receitas vs despesas |
| `lib/services/lancamento_service.dart` | MODIFY | Métodos de agregação por período, categoria e centro de custo |

---

## Phase CASH-03: Integração Cross-App (Firestore Sync)

### Status: [BLOCKED]
**Priority**: 🔴 CRITICAL
**Objective**: Permitir que despesas do RuraCash apareçam no break-even do RuraRubber.
**Blocker**: Requer que ambos apps usem GenericSyncService com syncEnabled=true e Firestore como meio de troca. Infraestrutura pronta (CORE-78), falta implementar a leitura cross-app no RuraRubber.

### Cross-Reference
- CORE-78: GenericSyncService (infraestrutura pronta)
- RUBBER-20: Break-even (consumidor dos dados)

---

## Phase CASH-02: Centros de Custo

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir alocação de despesas por centro de custo (seringal, pasto, geral).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Modelo CentroCusto**: Hive typeId 72, FarmOwnedEntity, nome, ícone, cor, appVinculado | ✅ DONE |
| 2.2 | **CentroCustoService**: Singleton com CRUD, auto-create "Geral", defaultCentroCusto | ✅ DONE |
| 2.3 | **CentroCustoScreen**: Tela CRUD com lista, add, edit, delete | ✅ DONE |
| 2.4 | **Integração Lançamento**: Campo centroCustoId no modelo Lancamento | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/centro_custo.dart` | CREATE | Modelo Hive typeId 72, FarmOwnedEntity, create/toJson/fromJson |
| `lib/services/centro_custo_service.dart` | CREATE | Singleton com CRUD, auto-create "Geral" |
| `lib/screens/centro_custo_screen.dart` | CREATE | Tela CRUD para centros de custo |

---

## Phase CASH-01: MVP Lançamento de Despesas

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Entrada rápida de despesas com categorização e visualização mensal.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | **Modelo Lancamento**: Hive typeId 71, FarmOwnedEntity, valor, categoria, data, descrição | ✅ DONE |
| 1.2 | **CashCategoria Enum**: Hive typeId 70, 7 categorias com ícone e cor | ✅ DONE |
| 1.3 | **LancamentoService**: Singleton com CRUD, queries por mês/categoria/período, totais | ✅ DONE |
| 1.4 | **CashHomeScreen**: Dashboard com card de total mensal e lista de lançamentos | ✅ DONE |
| 1.5 | **CalculatorScreen**: Entrada rápida estilo calculadora com smart defaults | ✅ DONE |
| 1.6 | **CashDrawer**: Navegação com drawer padronizado (Calculator, Centros, DRE) | ✅ DONE |
| 1.7 | **Main.dart Integration**: Adapters Hive, providers, rotas, l10n, AdMob | ✅ DONE |
| 1.8 | **L10n Strings**: 55 chaves em pt-BR e en | ✅ DONE |

### Hive TypeIds

| TypeId | Modelo |
|--------|--------|
| 70 | CashCategoria (enum) |
| 71 | Lancamento (class) |
| 72 | CentroCusto (class) |

### Files Created

| File | Action | Description |
|------|--------|-------------|
| `lib/models/cash_categoria.dart` | CREATE | Enum com 7 categorias, ícone, cor, localizedName |
| `lib/models/lancamento.dart` | CREATE | Modelo Hive typeId 71, FarmOwnedEntity, toJson/fromJson |
| `lib/models/centro_custo.dart` | CREATE | Modelo Hive typeId 72, FarmOwnedEntity |
| `lib/services/lancamento_service.dart` | CREATE | Service com CRUD + agregações por mês/categoria/centro |
| `lib/services/centro_custo_service.dart` | CREATE | Service com CRUD + auto-create "Geral" |
| `lib/screens/cash_home_screen.dart` | CREATE | Dashboard com total mensal e lista |
| `lib/screens/calculator_screen.dart` | CREATE | Entrada rápida de despesa |
| `lib/screens/centro_custo_screen.dart` | CREATE | CRUD de centros de custo |
| `lib/screens/dre_screen.dart` | CREATE | Relatório financeiro com filtros |
| `lib/widgets/cash_drawer.dart` | CREATE | Drawer padronizado com navegação |
| `lib/l10n/arb/app_pt.arb` | CREATE | 55 strings pt-BR |
| `lib/l10n/arb/app_en.arb` | CREATE | 55 strings en |
| `lib/main.dart` | CREATE | App entry point com rotas, providers, adapters |

### Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/home` | CashHomeScreen | Dashboard principal |
| `/calculator` | CalculatorScreen | Entrada de despesa |
| `/centros` | CentroCustoScreen | Gestão de centros de custo |
| `/dre` | DreScreen | Relatório financeiro |
| `/settings` | AgroSettingsScreen | Configurações (agro_core) |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `hive` | 2.2.3 | Armazenamento local |
| `hive_flutter` | 1.1.0 | Hive integration |
| `provider` | 6.1.2 | State management |
| `firebase_core` | 3.15.2 | Firebase init |
| `pdf` | 3.10.8 | PDF generation |
| `printing` | 5.11.1 | PDF export/print |
| `file_picker` | 8.1.6 | File import |
| `share_plus` | 10.1.4 | Sharing |
| `uuid` | 4.5.1 | ID generation |

### Cross-Reference
- CORE-78: GenericSyncService (base para services)
- CORE-75: Farm model (FarmOwnedEntity)
- CORE-77: Backup infrastructure
- RUBBER-20: Break-even consome dados de despesas (futuro CASH-03)
