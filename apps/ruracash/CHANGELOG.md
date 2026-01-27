# CHANGELOG - RuraCash

> **Phase Prefix**: Phases use the `CASH-` prefix.
> Core infrastructure phases are documented in `packages/agro_core/CHANGELOG.md`.

---

## Phase CASH-09: Personal Finance Mode [LOCKED]

### Status: [LOCKED]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir alternância entre contexto Rural e Pessoal para sanear o DRE da fazenda. Usar o modelo Farm-Centric para criar uma "Fazenda Pessoal" com categorias domésticas, isolando gastos pessoais (supermercado, farmácia, lazer) dos custos operacionais da fazenda (adubo, mão de obra, combustível).
**Prerequisite**: CORE-91 (FarmType enum no Farm model)

### Why LOCKED

- Requer CORE-91 (FarmType) implementado primeiro
- Requer decisão de UX: dropdown no AppBar? Bottom sheet? Chips?
- Requer decisão sobre categorias pessoais: quantas? quais? configuráveis?
- Requer strings l10n para todas as categorias novas (pt-BR + en)

### Licensing Rule

A farm pessoal é **FREE** — o usuário pode ter 2 farms sem assinatura/compra:
- 1 farm `FarmType.agro` (criada no onboarding normal)
- 1 farm `FarmType.personal` (criada automaticamente pelo CASH-09)

Não é necessário licença, assinatura ou compra para habilitar o modo pessoal. O `subscriptionTier` do modelo Farm controla apenas farms **agro** adicionais (futuro multi-fazenda). A farm pessoal é uma feature do app, não um recurso premium.

O `FarmService` deve permitir esta exceção:
- `getFarmLimit(tier)` retorna o limite de farms **agro** (free=1, basic=3, premium=ilimitado)
- Farms `FarmType.personal` **NÃO** contam para o limite
- Regra: `countFarms(FarmType.agro) <= farmLimit` + `countFarms(FarmType.personal) <= 1`

### Problem Statement

A maioria dos produtores rurais mistura gastos da fazenda com gastos pessoais no mesmo controle financeiro. Isso resulta em:
- **DRE poluído**: O relatório da fazenda inclui conta de luz de casa, feira, farmácia
- **Falsa sensação de prejuízo**: A fazenda pode dar lucro, mas aparenta dar prejuízo porque os gastos pessoais estão somados
- **Nenhuma visibilidade doméstica**: O produtor não sabe quanto gasta com a família por mês
- **O app "perde utilidade" fora de safra**: Se só registra custos rurais, fica sem uso nos meses de entre-safra

### Solution: "Farm as Context"

Tratar a "Vida Pessoal" como se fosse uma Farm:
- `Farm A`: "Seringal Santa Fé" (`type: FarmType.agro`) — categorias rurais
- `Farm B`: "Minhas Finanças" (`type: FarmType.personal`) — categorias domésticas

Ao trocar o contexto, o `farmId` muda. Todos os filtros, DRE, queries e backups funcionam automaticamente.

### Architecture Overview

```
Usuário abre RuraCash:
  ┌──────────────────────────────────────────┐
  │ Header: [ 🚜 Seringal Sta Fé  ▼ ]       │  ← Context Switcher
  │                                          │
  │  Total do Mês: R$ 3.200,00              │
  │  ├─ Mão de Obra: R$ 1.500               │
  │  ├─ Combustível: R$ 800                  │
  │  └─ Adubo: R$ 900                        │
  └──────────────────────────────────────────┘

Ao trocar para "Pessoal":
  ┌──────────────────────────────────────────┐
  │ Header: [ 🏠 Minhas Finanças  ▼ ]       │  ← Context Switcher
  │                                          │
  │  Total do Mês: R$ 2.100,00              │
  │  ├─ Mercado: R$ 800                      │
  │  ├─ Farmácia: R$ 300                     │
  │  ├─ Educação: R$ 500                     │
  │  └─ Casa: R$ 500                         │
  └──────────────────────────────────────────┘

Dados NUNCA se misturam — farmId diferente.
DRE da fazenda mostra apenas custos operacionais.
DRE pessoal mostra apenas gastos domésticos.
```

### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-09.1 | **CashCategoriaPersonal Enum**: Criar enum com categorias domésticas: mercado, farmacia, lazer, casa, educacao, saude, transporte, vestuario, outros. HiveType typeId 73, com icon/color/localizedName | ⏳ TODO |
| CASH-09.2 | **Lancamento model update**: Adicionar campo `categoriaPersonal` (HiveField novo, nullable). Se farm é personal, usa categoriaPersonal; se agro, usa categoria | ⏳ TODO |
| CASH-09.3 | **Auto-create personal farm**: No `main.dart`, após init do FarmService, verificar se existe farm `FarmType.personal`. Se não, criar "Minhas Finanças" automaticamente | ⏳ TODO |
| CASH-09.4 | **Context Switcher Widget**: Dropdown no AppBar do CashHomeScreen que lista farms do usuário (agro + personal). Ao trocar, armazenar `activeFarmId` e recarregar dados | ⏳ TODO |
| CASH-09.5 | **Category Context**: CalculatorScreen mostra categorias agro ou pessoais conforme o tipo da farm ativa. Usar `if (activeFarm.type == FarmType.personal)` para decidir qual enum usar | ⏳ TODO |
| CASH-09.6 | **DRE Filtering**: DreScreen já filtra por farmId via LancamentoService. Validar que o relatório mostra apenas dados do contexto ativo. Ajustar título: "DRE — Seringal" vs "DRE — Pessoal" | ⏳ TODO |
| CASH-09.7 | **HomeScreen Context**: CashHomeScreen mostra total e lista filtrados pela farm ativa. Ícone/cor do header muda conforme contexto (🚜 verde vs 🏠 azul) | ⏳ TODO |
| CASH-09.8 | **L10n strings**: Adicionar strings para todas as categorias pessoais + labels de contexto (pt-BR + en). Mínimo 20 novas chaves | ⏳ TODO |
| CASH-09.9 | **Cross-app guard**: Garantir que RuraRubber/RuraRain/etc filtram farms por `FarmType.agro` e NUNCA mostram a farm pessoal em seus contextos | ⏳ TODO |

### Categorias Pessoais (Planned)

| Enum Value | Icon | Color | pt-BR | en |
|------------|------|-------|-------|-----|
| `mercado` | shopping_cart | green | Mercado | Groceries |
| `farmacia` | medical_services | red | Farmácia | Pharmacy |
| `lazer` | sports_esports | purple | Lazer | Leisure |
| `casa` | home | brown | Casa | Home |
| `educacao` | school | blue | Educação | Education |
| `saude` | health_and_safety | pink | Saúde | Health |
| `transporte` | directions_car | orange | Transporte | Transport |
| `vestuario` | checkroom | teal | Vestuário | Clothing |
| `outros` | category | grey | Outros | Other |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/cash_categoria_personal.dart` | CREATE | Enum com 9 categorias pessoais, HiveType typeId 73 |
| `lib/models/lancamento.dart` | MODIFY | Adicionar HiveField para categoriaPersonal (nullable) |
| `lib/models/lancamento.g.dart` | REGENERATE | build_runner com novo campo |
| `lib/screens/cash_home_screen.dart` | MODIFY | Adicionar context switcher, filtrar por farm ativa |
| `lib/screens/calculator_screen.dart` | MODIFY | Mostrar categorias conforme contexto (agro vs personal) |
| `lib/screens/dre_screen.dart` | MODIFY | Título contextual, validar filtro por farmId |
| `lib/widgets/context_switcher.dart` | CREATE | Dropdown widget de seleção de contexto |
| `lib/l10n/arb/app_pt.arb` | MODIFY | ~20 novas chaves para categorias pessoais |
| `lib/l10n/arb/app_en.arb` | MODIFY | ~20 novas chaves para categorias pessoais |
| `lib/main.dart` | MODIFY | Auto-create farm pessoal, registrar novo adapter |

### Strategic Value

- **Diferencial competitivo**: Nenhum app agro separa finanças rural/pessoal de forma simples
- **Retenção o ano todo**: Fora de safra, o produtor continua usando para gastos domésticos
- **Educação financeira**: O produtor finalmente vê que a fazenda dá lucro — o problema é o gasto pessoal
- **Base para DRE consolidado** (futuro): "Resultado Geral = Receita Fazenda - Custos Fazenda - Gastos Pessoais"

### Cross-Reference
- CORE-91: FarmType enum (prerequisite)
- CORE-75: Farm-Centric Model (base)
- CASH-01: MVP Lançamento de Despesas (base de categorias e models)
- CASH-04: DRE (consumidor de dados filtrados por farm)

---

## Phase CASH-08: Firebase & Auth Integration [LOCKED]

### Status: [LOCKED]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Integrar Firebase, autenticação Google, CloudBackupService, DataDeletionService, e fluxo de login completo ao RuraCash. Alinhar com RuraRubber/RuraRain que já possuem esses recursos.
**Prerequisite**: CASH-07 (corrigir erros e alinhar base)

### Why LOCKED

RuraCash atualmente opera 100% offline sem Firebase. Para ativar:
- Criar projeto Firebase para RuraCash (ou usar projeto compartilhado)
- Gerar `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
- Gerar `firebase_options.dart` via FlutterFire CLI
- Configurar flavors se necessário

### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-08.1 | Criar projeto Firebase, gerar configs (google-services.json, firebase_options.dart) | ⏳ TODO |
| CASH-08.2 | Inicializar Firebase no main.dart (pattern nativo Android/iOS + DefaultFirebaseOptions desktop) | ⏳ TODO |
| CASH-08.3 | Adicionar App Check com guard `if (!kDebugMode)` | ⏳ TODO |
| CASH-08.4 | Registrar Hive adapters: DeviceInfoAdapter, ConsentDataAdapter, UserCloudDataAdapter | ⏳ TODO |
| CASH-08.5 | Inicializar UserCloudService, DataMigrationService no main.dart | ⏳ TODO |
| CASH-08.6 | Criar AuthGate com LoginScreen e fluxo de login Google/Anônimo | ⏳ TODO |
| CASH-08.7 | Criar CashBackupProvider (implements EnhancedBackupProvider) para Lancamento + CentroCusto | ⏳ TODO |
| CASH-08.8 | Criar CashDeletionProvider (implements AppDeletionProvider) para LGPD | ⏳ TODO |
| CASH-08.9 | Registrar backup/deletion providers no main.dart | ⏳ TODO |
| CASH-08.10 | Criar ConfiguracoesScreen app-specific com isOwner, locale, theme, backup callbacks | ⏳ TODO |
| CASH-08.11 | Re-habilitar `syncEnabled => true` nos services (após Firebase estar ativo) | ⏳ TODO |
| CASH-08.12 | Adicionar Property Name Gate no fluxo de navegação | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/firebase_options.dart` | CREATE | Gerado pelo FlutterFire CLI |
| `lib/main.dart` | MODIFY | Firebase init, App Check, adapters, services, AuthGate |
| `lib/screens/configuracoes_screen.dart` | CREATE | Settings wrapper com isOwner, locale, theme |
| `lib/services/cash_backup_provider.dart` | CREATE | EnhancedBackupProvider para backup/restore |
| `lib/services/cash_deletion_provider.dart` | CREATE | AppDeletionProvider para LGPD |
| `android/app/src/main/google-services.json` | CREATE | Firebase config Android |

### Cross-Reference
- CORE-84: Firebase init pattern, App Check, Sync adapters
- CORE-86/87: Owner-based settings, auto-backup
- RUBBER-26/27: Referência de implementação completa
- RAIN-06/07: Referência de implementação completa

---

## Phase CASH-07: Architecture Alignment & Error Fixes

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Corrigir 17 erros de compilação (CashLocalizations), prevenir crash de runtime (syncEnabled sem Firebase), e alinhar code quality com padrões do monorepo.

### Root Cause Analysis

1. **CashLocalizations não gerado** (17 erros): `l10n.yaml` existe, ARB files existem, `flutter: generate: true` está no pubspec — mas `flutter gen-l10n` nunca foi executado. Resultado: todas as telas que importam `package:flutter_gen/gen_l10n/app_localizations.dart` falham.

2. **syncEnabled => true sem Firebase** (crash em runtime): Ambos services (LancamentoService, CentroCustoService) declaram `syncEnabled => true`, mas o app NÃO inicializa Firebase. Quando `getById()` é chamado, `scheduleSyncInBackground()` → `syncWithServer()` → `FirebaseFirestore.instance` → crash. Solução: `syncEnabled => false` até Firebase ser configurado (CASH-08).

3. **Dead code**: `CentroCustoService.defaultCentroCusto` tem `return list.first;` seguido de `return list.firstWhere(...)` — segunda linha é inalcançável.

4. **Imports não utilizados**: `uuid` importado em ambos services mas não usado diretamente (GenericSyncService cuida de IDs).

5. **Missing @override**: `clearAll()` em ambos services sobrescreve método do GenericSyncService sem anotação.

6. **Imports desnecessários**: `generic_sync_service.dart` importado diretamente quando já está no barrel `agro_core.dart`.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-07.1 | Gerar CashLocalizations via `flutter gen-l10n` no diretório ruracash | ✅ DONE |
| CASH-07.2 | Alterar `syncEnabled => false` em LancamentoService e CentroCustoService | ✅ DONE |
| CASH-07.3 | Corrigir dead code em `CentroCustoService.defaultCentroCusto` — remover `return list.first;` inalcançável | ✅ DONE |
| CASH-07.4 | Remover imports `package:uuid/uuid.dart` não utilizados em ambos services | ✅ DONE |
| CASH-07.5 | Adicionar `@override` em `clearAll()` de ambos services, remover imports desnecessários de `generic_sync_service.dart` | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/lancamento_service.dart` | MODIFY | syncEnabled=false, remover uuid import, remover generic_sync_service import, @override clearAll |
| `lib/services/centro_custo_service.dart` | MODIFY | syncEnabled=false, remover uuid import, remover generic_sync_service import, @override clearAll, fix dead code |
| `.dart_tool/flutter_gen/` | GENERATE | CashLocalizations gerado por flutter gen-l10n |

### Notes

- `syncEnabled => false` é temporário — será re-habilitado em CASH-08 quando Firebase estiver configurado
- CashLocalizations é app-level l10n (strings específicas do RuraCash), separado do AgroLocalizations do core
- isOwner não precisa ser wired agora — sem Auth, o default `true` é correto para uso single-user offline

### Cross-Reference
- CORE-83: Migração para GenericSyncService (origem do syncEnabled=true prematuro)
- CORE-88: Data Tier Architecture (GenericSyncService Tier 3 gate via farm.isShared)

---

## Phase CASH-06: Fix Sync Adapter Registration

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Registrar adapters Hive da infraestrutura de sync (OfflineOperation, OperationType, OperationPriority) no main.dart para evitar `HiveError: Cannot write, unknown type: OfflineOperation` quando GenericSyncService tenta enfileirar operações offline.
**Cross-Reference**: CORE-84

### Root Cause
Os services LancamentoService e CentroCustoService usam `GenericSyncService` com `syncEnabled => true`, que enfileira operações no `OfflineQueueManager`. O OfflineQueueManager persiste objetos `OfflineOperation` no Hive, mas os adapters nunca foram registrados no `main.dart` do RuraCash.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1 | Registrar OfflineOperationAdapter, OperationTypeAdapter, OperationPriorityAdapter no main.dart | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | MODIFY | Adicionar 3 registros de adapter após adapters existentes |

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
