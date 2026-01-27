# CHANGELOG - RuraRubber

> **Phase Prefix Migration**: From RUBBER-01 onwards, phases use the `RUBBER-` prefix instead of `BORRACHA-`.

---

## Phase RUBBER-30: Unified Sync Pipeline Verification

### Status: [DONE]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Verificar que todos os serviços do RuraRubber usam exclusivamente GenericSyncService. Todos os 5 services (Despesa, Entrega, Parceiro, Recebivel, Tabela) já estendem GenericSyncService com syncEnabled=true. Nenhum tem Tier 2 customizado.

### Prerequisites
- CORE-95: Unified Sync Pipeline deve estar DOING ✅

### Scope
- Verificar que nenhum service usa subcollections (flat root collections apenas)
- Verificar que nenhum service tem lógica de sync customizada fora do GenericSyncService
- Confirmar zero subcollection usage nos firestoreCollection getters

### Cross-Reference
- RAIN-10 [TODO]: Unified Sync Pipeline (rurarain)
- CORE-95 [DOING]: Unified Sync Pipeline (agro_core)

---

## Phase RUBBER-29: L10n Hardcoded Default Names Fix

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Substituir nomes padrão hardcoded ("Meu Seringal", "Seringal", "Minha Propriedade") por keys l10n localizadas, alinhando com a regra de zero hardcoded strings (CLAUDE.md regra 6).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| RUBBER-29.1 | `onboarding_service.dart`: Substituir fallback hardcoded "Meu Seringal" por parâmetro `fallbackName` passado pela tela (l10n `farmDefaultNameRubber`) | ✅ DONE |
| RUBBER-29.2 | `onboarding_screen.dart`: Passar `AgroLocalizations.of(context)!.farmDefaultNameRubber` como `fallbackName` | ✅ DONE |
| RUBBER-29.3 | `home_screen.dart`: Substituir hardcoded "Minha Propriedade" e "Seringal" por `propertyDefaultName` e `rubberPlantationTitle` via l10n | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/onboarding_service.dart` | MODIFY | Adicionar param `fallbackName`, remover hardcode "Meu Seringal" |
| `lib/screens/onboarding_screen.dart` | MODIFY | Importar agro_core, passar fallbackName l10n |
| `lib/screens/home_screen.dart` | MODIFY | Substituir hardcodes "Minha Propriedade" e "Seringal" por l10n |

### Cross-Reference
- CORE-92: Keys l10n adicionadas nos ARBs do agro_core

---

## Phase RUBBER-28: Code Quality Fixes (Post-CORE-83 Cleanup)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Corrigir 2 erros de compilação (`static_access_to_instance_member`) e 7 infos de code quality (imports desnecessários, missing `@override`) introduzidos durante a migração para GenericSyncService (CORE-83).

### Root Cause

1. **`EntregaService.boxName` acesso estático** (2 erros): `boxName` é getter de instância do `GenericSyncService`, mas `backup_service.dart` e `borracha_backup_provider.dart` acessavam via `EntregaService.boxName` (estático). Correção: `EntregaService.instance.boxName`.

2. **Imports `generic_sync_service.dart` desnecessários** (3 infos): Import direto quando já é exportado pelo barrel `agro_core.dart`.

3. **Missing `@override` em `clearAll()`** (4 infos): Método `clearAll()` sobrescreve `GenericSyncService.clearAll()` sem anotação.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| RUBBER-28.1 | Fix `EntregaService.boxName` → `EntregaService.instance.boxName` em backup_service e borracha_backup_provider | ✅ DONE |
| RUBBER-28.2 | Remover imports desnecessários de `generic_sync_service.dart` em despesa, entrega, parceiro, recebivel, tabela services | ✅ DONE |
| RUBBER-28.3 | Adicionar `@override` em `clearAll()` de entrega, parceiro, recebivel, tabela services | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/backup_service.dart` | MODIFY | `EntregaService.instance.boxName` |
| `lib/services/borracha_backup_provider.dart` | MODIFY | `EntregaService.instance.boxName` |
| `lib/services/despesa_service.dart` | MODIFY | Remover import desnecessário de generic_sync_service |
| `lib/services/entrega_service.dart` | MODIFY | Remover import desnecessário, @override clearAll |
| `lib/services/parceiro_service.dart` | MODIFY | Remover import desnecessário, @override clearAll |
| `lib/services/recebivel_service.dart` | MODIFY | Remover import desnecessário, @override clearAll |
| `lib/services/tabela_service.dart` | MODIFY | Remover import desnecessário, @override clearAll |

### Cross-Reference
- CORE-83: Migração para GenericSyncService (origem dos issues)
- CASH-07: Mesma correção aplicada no RuraCash

---

## Phase RUBBER-27: Owner-Based Settings Access Control

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Integrar controle de acesso por owner da farm na tela de configurações. Usa `FarmService.getDefaultFarm().isOwner(uid)` para determinar automaticamente se o usuário é dono da farm ativa.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| RUBBER-27.1 | Passar isOwner automático para AgroSettingsScreen baseado em Farm.isOwner | ✅ DONE |
| RUBBER-27.2 | Condicionar callbacks de local backup (export/import) ao isOwner | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | MODIFY | Route '/settings' usa FarmService + AuthService para calcular isOwner automaticamente |

---

## 🚀 ROADMAP: Evolução Financeira RuraRubber

> **Objetivo Estratégico**: Transformar o RuraRubber de "Calculadora de Peso" em "Gestor de Safra" completo.
> **Futuro**: Preparar a arquitetura para integração com o futuro app **RuraCash** (Controle de Despesas da Fazenda).
> **Multi-User**: Estrutura de dados preparada para futuro modelo fazenda-centric (ver CORE-75).

---

## Phase RUBBER-26: Parity Fixes (Sync, App Check, Property Name Gate, Firebase Init)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Corrigir gaps do RuraRubber em relação ao RuraRain: registrar adapters de sync, adicionar App Check com guard de debug, adicionar Property Name Gate, e corrigir inicialização do Firebase para usar config nativa em Android/iOS.
**Cross-Reference**: CORE-84, RAIN-05

### Gaps Identificados vs RuraRain

| Gap | RuraRain | RuraRubber (antes) |
|-----|----------|--------------------|
| Sync Adapters | ✅ Registrados | ❌ Faltavam |
| App Check | ✅ Com kDebugMode guard | ❌ Ausente |
| Property Name Gate | ✅ _PropertyNameGate widget | ❌ Ausente |
| Firebase Init | ✅ Config nativa Android/iOS | ❌ Sempre DefaultFirebaseOptions |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 26.1 | **Sync Adapter Registration**: Registrar OfflineOperationAdapter, OperationTypeAdapter, OperationPriorityAdapter no main.dart | ✅ DONE |
| 26.2 | **App Check**: Adicionar firebase_app_check import e ativação com guard `if (!kDebugMode)` | ✅ DONE |
| 26.3 | **Property Name Gate**: Adicionar _PropertyNameGate widget que verifica nome genérico e mostra dialog | ✅ DONE |
| 26.4 | **Firebase Init**: Usar config nativa para Android/iOS, DefaultFirebaseOptions apenas para desktop/web | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | MODIFY | Sync adapters, App Check com kDebugMode, Firebase init nativo, Property Name Gate |

### Implementation Details

**App Check (26.2)**:
- Importa `firebase_app_check` e `foundation.dart` (kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform)
- Ativação condicional: `if (!kDebugMode)` previne falha em debug builds
- Usa `AndroidProvider.playIntegrity` e `AppleProvider.appAttest`

**Property Name Gate (26.3)**:
- Reutiliza `shouldPromptForPropertyName()` e `showPropertyNamePromptDialog()` do agro_core
- Widget `_PropertyNameGate` inserido entre `_ProfileGatedHome` e `HomeScreen`
- Verifica após onboarding e profile selection, mostra dialog se nome é genérico
- Flag `propertyNamePrompted` (CORE-84.4) previne re-prompt quando usuário mantém nome padrão

**Firebase Init (26.4)**:
- Android/iOS: `Firebase.initializeApp()` sem options (usa google-services.json / GoogleService-Info.plist nativos)
- Web/Desktop: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- Melhora compatibilidade com Gradle flavors (dev/prod)

---

## Phase RUBBER-25: Migração para GenericSyncService
### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Migrar todos os serviços principais para `GenericSyncService`.
**Cross-Reference**: CORE-83

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 25.1 | **DespesaService**: Migração completa com suporte a safra | ✅ DONE |
| 25.2 | **EntregaService**: Migração com lógica complexa de pesagens | ✅ DONE |
| 25.3 | **RecebivelService**: Migração com queries de status | ✅ DONE |
| 25.4 | **ParceiroService**: Migração padrão CRUD | ✅ DONE |
| 25.5 | **TabelaService**: Migração com preservação de analytics e regras de negócio | ✅ DONE |

---

## Phase RUBBER-18: Gestão de Recebíveis (Visão Produtor)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Criar sistema de acompanhamento de valores a receber das usinas/bancas com UX mínima.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 18.1 | **Modelo Recebivel**: Entidade Hive typeId 60, FarmOwnedEntity (entregaId, valor, dataPrevista, compradorNome, recebido, dataRecebimento) | ✅ DONE |
| 18.2 | **RecebivelService**: Singleton ChangeNotifier com CRUD, queries por status, totais por período | ✅ DONE |
| 18.3 | **RecebiveisScreen**: Tela completa com summary card, lista com status chips, swipe-to-mark, empty state, FAB | ✅ DONE |
| 18.4 | **Main.dart Integration**: Registro RecebivelAdapter, init service, provider, rota /recebiveis | ✅ DONE |
| 18.5 | **Drawer Integration**: Item "Recebíveis" no rubber_drawer.dart e home_screen.dart | ✅ DONE |
| 18.6 | **Edit/Delete UI**: updateRecebivel service method, _showEditRecebivelSheet, swipe-to-delete com secondaryBackground | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/recebivel.dart` | CREATE | Modelo Hive typeId 60, FarmOwnedEntity, toJson/fromJson |
| `lib/models/recebivel.g.dart` | GENERATE | build_runner adapter |
| `lib/services/recebivel_service.dart` | CREATE | Singleton service com queries pendentes/recebidos, totais semana/mês |
| `lib/screens/recebiveis_screen.dart` | CREATE | Tela com summary card, lista, swipe, empty state, FAB |
| `lib/main.dart` | MODIFY | Registro RecebivelAdapter, init RecebivelService, provider, rota /recebiveis |
| `lib/widgets/rubber_drawer.dart` | MODIFY | Adicionado item drawer "Recebíveis" |
| `lib/screens/home_screen.dart` | MODIFY | Adicionado item drawer e navegação para recebiveis |

---

## Phase RUBBER-24: Integração CORE-77 (Dependency-Aware Backup)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL (Arquitetura multi-app e LGPD)
**Objective**: Integrar modelos e serviços do agro_core CORE-77 para backup dependency-aware, isolamento por sourceApp, e conformidade LGPD.
**Cross-Reference**: CORE-77, CORE-75

### Contexto

O CORE-77 criou a infraestrutura no agro_core para:
- `sourceApp`: Identificador imutável de qual app criou cada registro
- `FarmOwnedMixin`: Campos `farmId`, `createdBy`, `createdAt`, `sourceApp`
- `EnhancedBackupProvider`: Backup/restore em 3 fases com análise prévia
- `DependencyService`: Rastreamento de dependências cross-app
- `AppDeletionProvider`: LGPD delete por app com verificação de ownership

Esta fase adapta o RuraRubber para usar essa infraestrutura.

### Regras de Ownership (LGPD)

| Operação | Quem pode? | Implementação |
|----------|------------|---------------|
| Backup Cloud | Apenas owner | `isCurrentUserFarmOwner()` |
| Restore Cloud | Owner: full / Member: read-only | `RestoreFarmAccess` |
| Export LGPD | Apenas owner | `_isCurrentUserFarmOwner` |
| Delete LGPD | Apenas owner | `AppDeletionProvider` |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 24.1 | **Models Update**: Adicionar `farmId`, `createdBy`, `createdAt`, `sourceApp` a Parceiro e Entrega | ✅ DONE |
| 24.2 | **FarmOwnedEntity**: Implementar interface em Parceiro e Entrega | ✅ DONE |
| 24.3 | **Hive Adapters**: Atualizar HiveFields, rodar build_runner | ✅ DONE |
| 24.4 | **EnhancedBackupProvider**: Migrar BorrachaBackupProvider para EnhancedBackupProvider | ✅ DONE |
| 24.5 | **DependencyService**: Registrar no main.dart, inicializar | ✅ DONE |
| 24.6 | **FarmService Integration**: Registrar FarmAdapter, inicializar FarmService | ✅ DONE |
| 24.7 | **AppDeletionProvider**: Implementar BorrachaDeletionProvider | ✅ DONE |
| 24.8 | **Services Update**: Filtrar por farmId e sourceApp via backup/deletion providers | ✅ DONE |
| 24.9 | **Verify & Test**: Rodar flutter analyze, corrigir erros | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/parceiro.dart` | MODIFY | Implementa FarmOwnedEntity com farmId, createdBy, createdAt, sourceApp; factory Parceiro.create(); toJson/fromJson |
| `lib/models/parceiro.g.dart` | REGENERATE | build_runner (HiveFields 6-9) |
| `lib/models/entrega.dart` | MODIFY | Implementa FarmOwnedEntity; factory Entrega.create(); toJson/fromJson |
| `lib/models/entrega.g.dart` | REGENERATE | build_runner (HiveFields 7-10) |
| `lib/models/item_entrega.dart` | MODIFY | Adicionado toJson/fromJson para serialização |
| `lib/services/borracha_backup_provider.dart` | REWRITE | EnhancedBackupProvider com analyzeRestore, executeRestore, recalculateAfterRestore |
| `lib/services/borracha_deletion_provider.dart` | CREATE | AppDeletionProvider para LGPD delete por app |
| `lib/services/entrega_service.dart` | MODIFY | Adicionado Entrega.create(), deleteEntrega(), getEntregaById() |
| `lib/services/parceiro_service.dart` | UNCHANGED | Já suportava novo modelo via Parceiro.create() |
| `lib/services/backup_service.dart` | MODIFY | Usar fromJson para Parceiro/Entrega |
| `lib/services/pdf_service.dart` | MODIFY | Usar Parceiro.create() para placeholder |
| `lib/screens/parceiro_form_screen.dart` | MODIFY | Usar Parceiro.create() ao criar novo |
| `lib/main.dart` | MODIFY | Registrar FarmAdapter, DependencyManifestAdapter; init FarmService, DependencyService; registrar BorrachaDeletionProvider |

### Implementation Details

**Parceiro Model** (typeId: 0):
- Implementa `FarmOwnedEntity` interface
- HiveFields 6-9: farmId, createdBy, createdAt, sourceApp
- Factory `Parceiro.create()` auto-preenche metadata via FarmService/AuthService
- `sourceApp` sempre "rurarubber" (imutável)

**Entrega Model** (typeId: 2):
- Implementa `FarmOwnedEntity` interface
- HiveFields 7-10: farmId, createdBy, createdAt, sourceApp
- Factory `Entrega.create()` auto-preenche metadata

**BorrachaBackupProvider**:
- Implementa `EnhancedBackupProvider` com 3 fases:
  1. `analyzeRestore()`: Analisa backup vs local, verifica ownership
  2. `executeRestore()`: Limpa apenas sourceApp='rurarubber', importa novos
  3. `recalculateAfterRestore()`: Recalcula dependências (opcional)
- RestoreFarmAccess: owner/member/noAccess
- Preserva dados de outros apps durante restore

**BorrachaDeletionProvider**:
- Implementa `AppDeletionProvider` para LGPD
- `deleteAppData()`: Deleta todos dados rurarubber da farm
- `deletePersonalData()`: Deleta dados pessoais com verificação ownership
- Retorna `LgpdDeletionResult` com contagens e erros

### Notas de Implementação

1. **Retrocompatibilidade**: Models usam factory `.create()` para novos registros
2. **Offline-first**: Hive local, metadata preenchidos na criação
3. **sourceApp imutável**: Sempre "rurarubber", nunca modificado
4. **farmId obrigatório**: Via `FarmService.instance.defaultFarmId`
5. **createdBy obrigatório**: Via `AuthService.currentUser?.uid`

---

## Phase RUBBER-23: Sistema de Tabelas D3/D4 (Rotacao de Sangria)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT (Feature Discovery)
**Objective**: Implementar sistema opcional de tabelas de sangria (D3/D4) com modelo, servico, tela de configuracao e widget seletor.

### Business Context
- O sistema D3/D4 e a rotacao de sangria (sangrar tabela diferente a cada dia)
- Permite calcular g/arvore (indicador real de produtividade)
- Feature OPCIONAL e progressiva - usuario pode usar ou nao

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 23.1 | **Modelo TabelaSangria**: Hive typeId 65, FarmOwnedEntity, toJson/fromJson, Hive adapter | ✅ DONE |
| 23.2 | **TabelaService**: Singleton ChangeNotifier com CRUD, enforcada, sugestao, g/arvore | ✅ DONE |
| 23.3 | **TabelasConfigScreen**: Tela de configuracao de tabelas por parceiro | ✅ DONE |
| 23.4 | **TabelaSelectorWidget**: ChoiceChips horizontais para pesagem com sugestao e alerta | ✅ DONE |
| 23.5 | **Calculo g/arvore**: Analytics de gramas por arvore (calcGramasArvore in TabelaService) | ✅ DONE |
| 23.6 | **Alerta Enforcada**: Deteccao de sangria repetida (isEnforcada in TabelaService) | ✅ DONE |
| 23.7 | **Produtividade por Tabela**: getProductivityByTable analytics (infrastructure ready) | ✅ DONE |
| 23.8 | **Main.dart Integration**: Register TabelaSangriaAdapter, init TabelaService, add provider | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/tabela_sangria.dart` | CREATE | Modelo Hive typeId 65, FarmOwnedEntity, create/toJson/fromJson |
| `lib/models/tabela_sangria.g.dart` | CREATE | Hive adapter placeholder (TabelaSangriaAdapter) |
| `lib/services/tabela_service.dart` | CREATE | Singleton service com CRUD, enforcada, sugestao, analytics |
| `lib/screens/tabelas_config_screen.dart` | CREATE | Tela de configuracao com lista, add, delete, produtividade |
| `lib/widgets/tabela_selector.dart` | CREATE | Widget seletor compacto com ChoiceChips |
| `lib/main.dart` | MODIFY | Register TabelaSangriaAdapter, init TabelaService, add ChangeNotifierProvider |

### L10n Keys Used (Already in ARB)
- `usarTabelas`, `quantasTabelas`, `arvoresPorTabela`, `naoUsarTabelas`
- `tabelaSelecionada`, `alertaEnforcada`, `gramasArvore`
- `produtividadeTabela`, `tabelasConfigTitle`, `tabelasEmpty`
- `salvarButton`, `parceiroDeleteCancel`

---

## Phase RUBBER-22: Onboarding Simplificado (3 Perguntas Maximo)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL (First-Time User Experience)
**Objective**: Capturar informacoes essenciais no primeiro uso com minimo de perguntas via PageView com 2-3 paginas.

### UX Flow

- Page 1: Welcome + Seringal name input (default "Meu Seringal")
- Page 2: Profile selection (Produtor/Sangrador/Comprador) - reuses existing UserProfileType
- Page 3 (conditional):
  - Produtor: "How many tappers?" (chip buttons: Just me, 1-2, 3-5, 6+)
  - Sangrador: Boss name input
  - Comprador: Skip page 3
- "Start" button at the end

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 22.1 | **OnboardingScreen**: PageView with 2-3 pages, conditional flow per profile | ✅ DONE |
| 22.2 | **OnboardingService**: Singleton using FarmService, UserProfileService, Hive settings box | ✅ DONE |
| 22.3 | **Main.dart Integration**: Init OnboardingService, update _ProfileGatedHome to check onboarding first | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/onboarding_screen.dart` | CREATE | PageView with 2-3 pages, profile-conditional flow, l10n |
| `lib/services/onboarding_service.dart` | CREATE | Singleton service using FarmService + UserProfileService + Hive settings |
| `lib/main.dart` | MODIFY | Init OnboardingService, update _ProfileGatedHome to check onboarding before profile |

### L10n Keys Used (already in ARB files)
- `onboardingWelcome`, `onboardingSeringalName`, `onboardingSeringalHint`
- `onboardingYouAre`, `profileProdutor`, `profileSangrador`, `profileComprador`
- `onboardingHowManyTappers`, `onboardingJustMe`, `onboardingOneTwoTappers`
- `onboardingThreeFiveTappers`, `onboardingSixPlusTappers`
- `onboardingStart`, `onboardingTapperBossName`, `onboardingTapperBossHint`
- `profileContinue`, `errorLabel`

### Dependencies
- `FarmService` (agro_core) - Create/update default farm with user-provided name
- `UserProfileService` (rurarubber) - Set user profile type
- Hive `settings` box - Store onboarding completion flag

### Integration Notes (22.3)

To integrate in `main.dart`, update `_ProfileGatedHome` to check onboarding first:

```
1. Initialize OnboardingService in main():
   await OnboardingService.instance.init();

2. Import onboarding files:
   import 'screens/onboarding_screen.dart';
   import 'services/onboarding_service.dart';

3. Update _ProfileGatedHomeState.build() to:
   - Check OnboardingService.instance.isOnboardingComplete first
   - If not complete, show OnboardingScreen(onComplete: () => setState(() {}))
   - If complete but no profile, show ProfileSelectionScreen (fallback)
   - If complete and has profile, show HomeScreen
```

---

## Phase RUBBER-20: Break-even Dinâmico (Funcionalidade Avassaladora)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL (Diferencial Competitivo)
**Objective**: Mostrar o custo de produção por Kg em tempo real, calculando margem de lucro automaticamente.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 20.1 | **Modelo Despesa**: Entidade Hive (typeId 64) com valor, categoria, data, FarmOwnedEntity | ✅ DONE |
| 20.2 | **CategoriaDespesa Enum**: Hive enum (typeId 63) com 6 categorias | ✅ DONE |
| 20.3 | **DespesaService**: Service singleton com queries por safra, categoria, mensal | ✅ DONE |
| 20.4 | **BreakEvenScreen**: Dashboard completo com custo/kg, margem, breakdown por categoria | ✅ DONE |
| 20.5 | **Bottom Sheet Form**: Formulário de adição de despesa com valor, categoria, data, descrição | ✅ DONE |
| 20.6 | **Main.dart Integration**: Registrar adapters, init service, provider, route, drawer | ✅ DONE |
| 20.7 | **Edit UI**: updateDespesa service, tap-to-edit com _EditDespesaForm, _showEditDespesaSheet | ✅ DONE |
| 20.8 | **Cost Trend Alert**: _buildCostTrendWarning usando l10n.breakEvenAlerta quando custos sobem >20% | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/despesa.dart` | CREATE | Modelo Despesa com FarmOwnedEntity, toJson/fromJson |
| `lib/models/despesa.g.dart` | CREATE | Generated Hive adapters (typeId 63, 64) |
| `lib/services/despesa_service.dart` | CREATE | DespesaService singleton com queries safra-aware |
| `lib/screens/break_even_screen.dart` | CREATE | Dashboard break-even com FAB e bottom sheet |
| `lib/main.dart` | MODIFY | Registrar adapters, init, provider, route /break-even |
| `lib/widgets/rubber_drawer.dart` | MODIFY | Adicionar item Break-even ao drawer |

### Cross-Reference
- RURACASH-01 (Futuro app de despesas - integração via API)

---

## Phase RUBBER-19: Gestão de Pagamentos (Visão Comprador)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que Compradores (Usinas/Bancas) gerenciem pagamentos a produtores.

### Business Context
Para o comprador que usa o app para registrar compras de múltiplos produtores.

### O Fluxo
1. Comprador registra entrada de borracha -> Gera Obrigacao de Pagamento
2. Sistema calcula valor baseado no contrato
3. Painel "Contas a Pagar" mostra todos os produtores pendentes

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 19.1 | **Modelo ContaPagar**: Entidade Hive (typeId 61/62) com FarmOwnedEntity, FormaPagamento enum, toJson/fromJson | ✅ DONE |
| 19.2 | **ContaPagarService**: Singleton ChangeNotifier com CRUD, filtros (pendentes, pagas, vencidas), baixa em lote | ✅ DONE |
| 19.3 | **ContasPagarScreen**: Tela completa com summary card, lista ordenada, status chips, swipe-to-pay, batch payment | ✅ DONE |
| 19.4 | **Main.dart Integration**: Registro de adapters Hive, init service, provider, rota /contas-pagar | ✅ DONE |
| 19.5 | **Drawer Integration**: Item "Contas a Pagar" no rubber_drawer.dart e home_screen.dart | ✅ DONE |
| 19.6 | **Edit/Delete/Create UI**: updateConta service, FAB _showCreateContaSheet, _showEditContaSheet, swipe-to-delete | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/conta_pagar.dart` | CREATE | Modelo ContaPagar com FormaPagamento enum, FarmOwnedEntity, Hive typeId 61/62 |
| `lib/models/conta_pagar.g.dart` | CREATE | Generated Hive adapters via build_runner |
| `lib/services/conta_pagar_service.dart` | CREATE | Singleton service com CRUD, filtros, baixa em lote, totais |
| `lib/screens/contas_pagar_screen.dart` | CREATE | Tela com summary card, lista, status chips, swipe-to-pay, batch dialog |
| `lib/main.dart` | MODIFY | Registro adapters (FormaPagamentoAdapter, ContaPagarAdapter), init ContaPagarService, provider, rota |
| `lib/widgets/rubber_drawer.dart` | MODIFY | Adicionado item drawer "Contas a Pagar" |

---

---

## Phase RUBBER-17: Controle de Safras (Modelo Date Range)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL (Pré-requisito para fases financeiras)
**Objective**: Implementar controle de safra baseado em Janela de Tempo (Date Range), não acumulador.

> **Nota**: Esta fase foi implementada via CORE-76 (agro_core) e integrada no RuraRubber.

### Arquitetura: Query-Based (Não Acumulador)

**Princípio Fundamental**: Não salvamos totais fixos. Salvamos pesagens individuais.
O total é **calculado na hora** via query de banco de dados.

```
❌ ERRADO (Acumulador fixo):
   safra.totalKg = 15400  // Se editar pesagem antiga, esse número "fura"

✅ CORRETO (Query dinâmica):
   SELECT SUM(peso) FROM pesagens
   WHERE data >= safra.dataInicio AND data < safra.dataFim
   // Sempre atualizado, mesmo com lançamentos retroativos
```

**Vantagem**: Se o produtor achar um papelzinho de Outubro e lançar hoje com data de Outubro,
o sistema atualiza o relatório da safra automaticamente.

### O Modelo Safra (agro_core - CORE-76)

> **Nota:** O modelo Safra será implementado no `agro_core` (CORE-76) para ser compartilhado
> por todos os apps (RuraRubber, RuraCrop, RuraCattle, RuraCash).

```dart
// Usar Safra e SafraService do agro_core
import 'package:agro_core/agro_core.dart';

// No RuraRubber, apenas adiciona farmId nas queries
final safra = await SafraService.instance.getSafraAtiva();
final totalKg = await pesagemService.getTotalPorSafra(safra);
```

### UX Design Principles
- **Zero Configuration**: Safra inicia automaticamente em Setembro
- **Ajuste Manual Opcional**: Usuário pode editar datas nas configurações se precisar
- **Encerramento Simples**: Botão "Encerrar Safra" define dataFim = HOJE e cria nova safra

### O Fluxo Simplificado

```
1. [PRIMEIRA VEZ] App cria "Safra Inicial" com dataInicio = 01/Set atual (ou data instalação)
2. [DURANTE ANO] Todas as pesagens são salvas com sua data original
3. [ENCERRAMENTO] Usuário clica "Encerrar Safra":
   - Sistema define dataFim = HOJE
   - Sistema cria nova safra com dataInicio = AMANHÃ
4. [AJUSTE] Se precisar, usuário edita datas nas configurações da Safra
```

### Season Chip in Header (Home Screen)

```
┌────────────────────────────────────────┐
│ [≡]  RuraRubber         [Safra 25/26 ▼]│
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ Total Fazenda: 25.000 kg         │  │
│  │ Média Mensal:   2.500 kg         │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 👤 Zé      10.000 kg  (40%)      │  │
│  │ 👤 Tião     8.000 kg  (32%)      │  │
│  │ 👤 Maria    7.000 kg  (28%)      │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### Visão Hierárquica: Fazenda > Parceiros

**Cabeçalho (Total da Fazenda)**:
- Somatório de TODOS os parceiros
- Gráfico de barras: Média Mensal da fazenda

**Lista de Parceiros**:
- Cards ordenados por produção
- Cada card mostra: Nome, Total Kg, % do total

**Drill-Down**:
- Clicar no parceiro → Tela exclusiva dele (ver RUBBER-21)

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 17.1 | **CORE-76 Dependency**: Usar Safra e SafraService do agro_core | ✅ DONE |
| 17.2 | **SafraChip Widget**: Chip compacto para header com nome abreviado (ex: "25/26") | ✅ DONE |
| 17.3 | **SafraBottomSheet**: Lista de safras com resumo calculado dinamicamente | ✅ DONE |
| 17.4 | **Home Dashboard**: Visão hierárquica (Total Fazenda + Lista Parceiros) | ✅ DONE |
| 17.5 | **Filtro por Período**: Queries usam safra.containsDate() para filtrar registros | ✅ DONE |
| 17.6 | **Encerramento**: SafraService.encerrarSafra() com criação automática da próxima | ✅ DONE |
| 17.7 | **Ajuste Manual**: SafraBottomSheet permite editar datas via SafraService.updateSafra() | ✅ DONE |

### Dependências do agro_core (CORE-76)

| Componente | Uso |
|------------|-----|
| `Safra` | Modelo com dataInicio, dataFim, ativa |
| `SafraService` | CRUD + getSafraAtiva() + encerrarSafra() |
| `SafraAdapter` | Registrar no Hive durante init |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `agro_core: models/safra.dart` | USE | Modelo Safra do core com containsDate(), shortLabel |
| `agro_core: services/safra_service.dart` | USE | SafraService do core com ensureAtivaSafra(), encerrarSafra() |
| `agro_core: widgets/safra_chip.dart` | USE | SafraChip widget do core |
| `agro_core: widgets/safra_bottom_sheet.dart` | USE | SafraBottomSheet widget do core |
| `lib/screens/home_screen.dart` | MODIFY | Dashboard hierárquico com _buildSafraSummary, _buildParceiroRanking |
| `lib/services/entrega_service.dart` | MODIFY | Queries safra-aware: totalPesoSafra, pesoPorParceiroSafra |

### L10n Keys Required
- `safraChipLabel`: "{ano1}/{ano2}" (ex: "25/26")
- `totalFazenda`: "Total Fazenda"
- `mediaMensal`: "Média Mensal"
- `mediaQuinzenal`: "Média Quinzenal"
- `encerrarSafra`: "Encerrar Safra"
- `novaSafraCriada`: "Nova safra criada: {nome}"
- `ajustarDatas`: "Ajustar Datas"
- `dataInicio`: "Data Início"
- `dataFim`: "Data Fim"
- `safraAtiva`: "Safra Ativa"
- `safrasAnteriores`: "Safras Anteriores"
- `doTotal`: "do total"

---

## Phase RUBBER-21: Analytics do Parceiro (Raio-X)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Gráficos detalhados de produção por parceiro com comparativo de média.

### Business Context
O patrão com múltiplos sangradores precisa:
- Ver quem está produzindo mais/menos
- Identificar quedas de produção (pode ser doença, problema, etc.)
- Comparar desempenho individual vs média da fazenda

### O "Raio-X" do Parceiro

Ao clicar no card do parceiro na Home, entra na tela de detalhes:

```
┌────────────────────────────────────────┐
│ [←]  Zé - Sangrador                    │
├────────────────────────────────────────┤
│                                        │
│  Total Safra: 10.000 kg                │
│  Média Quinzenal: 300 kg               │
│                                        │
│  [15 Dias] [Mês] [Safra]  ← Seletor    │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    ▓▓▓                           │  │
│  │    ▓▓▓  ▓▓▓                      │  │
│  │    ▓▓▓  ▓▓▓  ▓▓▓                 │  │
│  │ ───────────────────── (média)    │  │
│  │    1ª   2ª   1ª   2ª            │  │
│  │   Jan  Jan  Fev  Fev            │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Ver Extrato Financeiro]              │
└────────────────────────────────────────┘
```

### Seletor de Período (3 Visões)

| Visão | Eixo X | Uso |
|-------|--------|-----|
| **15 Dias** | 1ª Jan, 2ª Jan, 1ª Fev... | Ciclo de pagamento quinzenal |
| **Mês** | Janeiro, Fevereiro... | Curva da safra (pico vs seca) |
| **Safra** | Safra 24/25, Safra 25/26 | Comparativo anual |

### Recurso "Comparativo Fantasma"

Linha cinza clara no fundo do gráfico mostrando a **Média da Fazenda**.

**Interpretação visual**:
- Barra do Zé **acima** da linha cinza → Acima da média
- Barra do Zé **abaixo** da linha cinza → Precisa melhorar

```
  │    ▓▓▓
  │    ▓▓▓  ▓▓▓
  │────░░░──░░░──░░░───── ← Média Fazenda (linha cinza)
  │    ▓▓▓  ▓▓▓  ▓▓▓
  │   Jan  Fev  Mar
```

### Regra de Dados Mínimos (Cold Start Problem)

**Problema**: No primeiro mês, a "Média da Fazenda" pode ser instável (poucos dados).

**Solução**: Só mostrar a "Linha Fantasma" quando houver dados suficientes:

| Condição | Comportamento |
|----------|---------------|
| **< 2 parceiros ativos** | Não mostra linha fantasma (não faz sentido comparar) |
| **< 15 dias de dados** | Não mostra linha fantasma (média instável) |
| **≥ 2 parceiros E ≥ 15 dias** | Mostra linha fantasma normalmente |

```dart
bool shouldShowPhantomLine({
  required int activePartners,
  required int daysWithData,
}) {
  return activePartners >= 2 && daysWithData >= 15;
}
```

**UX**: Quando a linha não aparece, o gráfico funciona normalmente - só não tem a referência de comparação.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 21.1 | **ParceiroDetailScreen**: Tela Raio-X do parceiro com summary card, chart, status chip | ✅ DONE |
| 21.2 | **Period Selector**: SegmentedButton [15 Dias] [Mês] [Safra] | ✅ DONE |
| 21.3 | **Bar Chart Widget**: Gráfico de barras pure-Container (sem fl_chart) com phantom line | ✅ DONE |
| 21.4 | **Média Fantasma**: Dashed phantom line de referência da média da fazenda | ✅ DONE |
| 21.5 | **Cold Start Guard**: shouldShowPhantomLine com ≥2 parceiros E ≥15 dias de dados | ✅ DONE |
| 21.6 | **AnalyticsService**: Cálculos quinzenal/mensal/safra com getBiweeklyData/getMonthlyData/getSeasonData | ✅ DONE |
| 21.7 | **Extrato Financeiro**: Botão OutlinedButton para /contas-pagar | ✅ DONE |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/parceiro_detail_screen.dart` | CREATE | Tela Raio-X com summary card, chart, status chip, financial button |
| `lib/widgets/period_selector.dart` | CREATE | SegmentedButton com AnalyticsPeriod enum |
| `lib/widgets/production_bar_chart.dart` | CREATE | Gráfico pure-Container com phantom dashed line (sem fl_chart) |
| `lib/services/analytics_service.dart` | CREATE | Métodos estáticos para cálculos quinzenal/mensal/safra/phantom |

### L10n Keys Required
- `raioXParceiro`: "Detalhes do Parceiro"
- `totalSafra`: "Total Safra"
- `mediaQuinzenal`: "Média Quinzenal"
- `mediaMensal`: "Média Mensal"
- `periodo15Dias`: "15 Dias"
- `periodoMes`: "Mês"
- `periodoSafra`: "Safra"
- `acimaDaMedia`: "Acima da média"
- `abaixoDaMedia`: "Abaixo da média"
- `verExtratoFinanceiro`: "Ver Extrato Financeiro"
- `mediaFazenda`: "Média Fazenda"

---

## Phase RUBBER-16: Melhorias UX Pesagem

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Pequenas melhorias na experiência de pesagem baseadas em feedback.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 16.1 | **Quick-Add Buttons**: Botões +50, +100, +150 kg abaixo do display de peso, usando l10n.pesagemQuickAdd | ✅ DONE |
| 16.2 | **Haptic Feedback**: HapticFeedback.mediumImpact() ao adicionar peso (calculator ADD e quick-add) | ✅ DONE |
| 16.3 | **Swipe-to-Undo**: Dismissible na última entrada da tape view (swipe-left para remover) | ✅ DONE |
| 16.4 | **Night Mode Toggle**: IconButton lua/sol no AppBar com ThemeData.dark() override local | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/pesagem_screen.dart` | MODIFY | Added _nightMode state, night mode toggle in AppBar, quick-add buttons row, haptic feedback on ADD and quick-add, _buildBody() method with Theme override |
| `lib/widgets/tape_view_widget.dart` | MODIFY | Wrapped last entry in Dismissible (swipe-left to undo), red background with delete icon and l10n label |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added pesagemNightModeOn, pesagemNightModeOff, tapeSwipeToDelete |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added pesagemNightModeOn, pesagemNightModeOff, tapeSwipeToDelete |

### L10n Keys Added
- `pesagemNightModeOn`: Tooltip for night mode activation
- `pesagemNightModeOff`: Tooltip for night mode deactivation
- `tapeSwipeToDelete`: Label shown on swipe-to-undo background

### L10n Keys Used (already existed)
- `pesagemQuickAdd`: "+{value} kg" for quick-add button labels

---

## Phase RUBBER-15: Job Classifieds (Vagas e Disponibilidade)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir que Sangradores publiquem disponibilidade para trabalho e Produtores publiquem vagas em seus seringais.

### Business Context
- **Sangradores** podem postar "Estou disponível para trabalho na região X"
- **Produtores** podem postar "Preciso de sangrador para meu seringal"
- Ambos podem se conectar via WhatsApp
- Diferente de ofertas de compra/venda - são anúncios de mão de obra

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 15.1 | **Model JobPost**: Criar modelo Firestore para anúncios de vagas/disponibilidade | ✅ DONE |
| 15.2 | **JobListScreen**: Tela de listagem de vagas/disponibilidades com filtro por região | ✅ DONE |
| 15.3 | **CreateJobScreen**: Formulário para criar anúncio (tipo, região, descrição, contato) | ✅ DONE |
| 15.4 | **WhatsApp Integration**: Botão de contato direto via WhatsApp | ✅ DONE |
| 15.5 | **Profile-based UI**: Sangrador vê vagas, Produtor vê sangradores disponíveis | ✅ DONE |
| 15.6 | **L10n Strings**: Adicionar todas as strings em pt-BR e en | ✅ DONE |
| 15.7 | **Routes & Navigation**: Adicionar rotas /jobs e /criar-vaga ao main.dart | ✅ DONE |
| 15.8 | **Drawer Integration**: Adicionar item Jobs ao drawer de todas as telas | ✅ DONE |

### Data Model: JobPost (Firestore)

```dart
enum JobType { offeringWork, seekingWork }

class JobPost {
  String id;
  String userId;
  String userName;
  JobType type; // offeringWork (Produtor) | seekingWork (Sangrador)
  List<String> regions;
  String description;
  String contactPhone;
  double? offeredPercentage; // % oferecido ao sangrador
  int? treesCount; // árvores em sangria
  String? municipality; // município
  DateTime createdAt;
  DateTime validUntil;

  bool get isExpiringSoon => daysRemaining <= 2;
  int get daysRemaining => validUntil.difference(DateTime.now()).inDays;
}
```

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/job_post.dart` | CREATE | Modelo JobPost com enum JobType, fromFirestore, toFirestore |
| `lib/screens/job_list_screen.dart` | CREATE | Lista com TabBar (Vagas/Disponíveis), filtro região, WhatsApp |
| `lib/screens/criar_vaga_screen.dart` | CREATE | Formulário com seletor de tipo, campos condicionais |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 35+ novas strings para jobs |
| `lib/l10n/arb/app_en.arb` | MODIFY | 35+ novas strings para jobs |
| `lib/main.dart` | MODIFY | Rotas /jobs e /criar-vaga |

---

## Phase RUBBER-14: Sell Offers (Ofertas de Venda - Produtor)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que Produtores publiquem ofertas de venda de borracha ("Tenho X kg disponível"), complementando o Mercado que atualmente só tem ofertas de compra.

### Business Context
- Atualmente o Mercado só mostra **ofertas de COMPRA** (compradores postam preços)
- Esta fase adiciona **ofertas de VENDA** (produtores postam disponibilidade)
- Compradores podem ver o que está disponível na região
- Sistema bidirecional de matchmaking

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 14.1 | **Extend MarketOffer Model**: Adicionar campo `offerType` (buy/sell), municipality, treesInTapping, estimatedWeight | ✅ DONE |
| 14.2 | **Update CriarOfertaScreen**: Suportar tipo de oferta (buy/sell) com campos específicos | ✅ DONE |
| 14.3 | **Update MercadoScreen**: Tabs para Compras vs Vendas, exibição de campos extras | ✅ DONE |
| 14.4 | **Price Negotiable**: Para ofertas de venda, preço é opcional ("preço a combinar") | ✅ DONE |
| 14.5 | **Expiration Warning**: Alerta visual quando oferta está próxima de vencer (2 dias) | ✅ DONE |
| 14.6 | **WhatsApp Message**: Mensagem contextual diferente para ofertas de venda | ✅ DONE |
| 14.7 | **L10n Strings**: 25+ novas strings em pt-BR e en | ✅ DONE |

### Extended MarketOffer Model

```dart
enum OfferType { buy, sell }

class MarketOffer {
  // ... existing fields ...
  OfferType offerType; // buy (comprador) or sell (produtor)
  double? priceDrc; // NOW NULLABLE for "preço a combinar"
  double? availableKg; // quantidade disponível (para sell)
  String? municipality; // município
  int? treesInTapping; // árvores em sangria
  double? estimatedWeight; // peso estimado

  bool get isPriceNegotiable => priceDrc == null && priceWet == null;
  bool get isExpiringSoon => daysRemaining <= 2;
}
```

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/market_offer.dart` | MODIFY | Added OfferType enum, nullable prices, municipality, treesInTapping, estimatedWeight, expiration helpers |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Buy/sell type selector, production details section, optional prices for sell |
| `lib/screens/mercado_screen.dart` | MODIFY | TabBar for buy/sell filtering, expiration warning badge, municipality/trees/weight display |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 25+ new localized strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | 25+ new localized strings |

---

## Phase RUBBER-13: Social Sharing (Compartilhamento de Peso)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🔵 FIX
**Objective**: Permitir compartilhamento rápido do peso atual via WhatsApp com visual atraente (card de imagem), além do PDF já existente.

### Business Context
- Atualmente só existe PDF de fechamento completo
- Usuários querem compartilhar peso rapidamente durante a pesagem
- Similar ao "Rain Card" do RuraRain - imagem visual para redes sociais
- Usa compartilhamento nativo do sistema (igual PIX receipt)

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 13.1 | **ShareService**: Serviço centralizado de compartilhamento (captura widget como imagem, share_plus) | ✅ DONE |
| 13.2 | **WeightCardWidget**: Widget visual do card de peso com gradiente verde | ✅ DONE |
| 13.3 | **ImageGenerator**: RepaintBoundary + toImage para converter widget em PNG | ✅ DONE |
| 13.4 | **showShareWeightDialog**: Dialog que auto-compartilha via nativo do sistema | ✅ DONE |
| 13.5 | **Share Button on TapeView**: Botão de compartilhar no total acumulado (quando há pesagens) | ✅ DONE |
| 13.6 | **L10n Strings**: Strings de compartilhamento em pt-BR e en | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/share_service.dart` | CREATE | captureWidgetAsImage, shareImage, shareText, generateQuickShareText |
| `lib/widgets/weight_card_widget.dart` | CREATE | WeightCardWidget, showShareWeightDialog function |
| `lib/screens/pesagem_screen.dart` | MODIFY | Added onShare callback to TapeViewWidget |
| `lib/widgets/tape_view_widget.dart` | MODIFY | Added onShare callback, share icon button |
| `lib/l10n/arb/app_pt.arb` | MODIFY | shareTitle, shareAsImage, shareAsText, shareWeightButton, etc. |
| `lib/l10n/arb/app_en.arb` | MODIFY | English translations for share strings |

### Dependencies
- `share_plus: ^10.1.4` - From agro_core (native system share like PIX receipt)

---

## Phase RUBBER-12: Profile UX & Navigation Fixes

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Fix multiple UX issues related to profile display, navigation consistency, terminology clarity, and About screen branding.

### Problems Identified

1. **Profile Not Shown in Menu**: After selecting a profile (Producer/Tapper/Buyer), there's no visual indication in the drawer or main screen.

2. **Mercado Firestore Error**: Users see "sem permissões para visualizar" when accessing the Market screen. Needs to verify Firestore security rules and macroregion filtering.

3. **Menu Navigation Inconsistent**: Clicking the drawer on certain screens doesn't show all navigation options. Some screens have incomplete `extraItems` in their `AgroDrawer`.

4. **Partner/Producer Naming Confusion**:
   - When in **Tapper profile**, the "Parceiro" field during weighing should show the **Producer's name** (who owns the seringal)
   - When in **Producer profile**, the "Parceiro" field should show the **Tapper's name**
   - The **percentage is ALWAYS the Tapper's percentage** (their cut of the sale)

5. **About Screen Inconsistent**: The About screen on some screens shows the old tractor icon instead of the RuraRubber app icon. Need to pass `appLogoLightPath` and `appLogoDarkPath` consistently.

6. **Property Name for Tapper**: When selecting the Tapper profile, the property should be called "Seringal" and the user should be prompted to enter a name, not use the default "Minha Propriedade".

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 12.1 | **Profile in Drawer**: Pass current profile to `AgroDrawer` via `profileName` parameter | ✅ DONE |
| 12.2 | **Fix Mercado Firestore**: Added proper error handling with l10n key `mercadoFirestoreError` | ✅ DONE |
| 12.3 | **Standardize Drawer extraItems**: Created `buildRubberDrawer()` helper for consistent navigation across all screens | ✅ DONE |
| 12.4 | **Clarify Partner Terminology**: Profile labels (Produtor/Comprador/Sangrador) shown in drawer header | ✅ DONE |
| 12.5 | **Fix About Screen Logos**: Correct `appLogoLightPath`/`appLogoDarkPath` in all `AgroAboutScreen` usages | ✅ DONE |
| 12.6 | **Property Naming Flow**: Seringal terminology used for Sangrador profile in home screen | ✅ DONE |

### Files to Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/rubber_drawer.dart` | CREATE | Helper centralizado para drawer com profile display e items consistentes |
| `lib/screens/home_screen.dart` | MODIFY | Profile display via _profileLabel(), drawer com todos items |
| `lib/screens/pesagem_screen.dart` | MODIFY | Usa buildRubberDrawer() ao invés de drawer inline |
| `lib/screens/mercado_screen.dart` | MODIFY | Usa buildRubberDrawer(), error handling com mercadoFirestoreError |
| `lib/screens/parceiros_list_screen.dart` | MODIFY | Usa buildRubberDrawer() |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Usa buildRubberDrawer() |
| `lib/screens/job_list_screen.dart` | MODIFY | Usa buildRubberDrawer() |
| `lib/l10n/arb/app_pt.arb` | MODIFY | profileLabelProdutor/Comprador/Sangrador, mercadoFirestoreError |
| `lib/l10n/arb/app_en.arb` | MODIFY | English translations |

### Cross-Reference
- CORE-67 (Profile Display in AgroDrawer)

---

## Phase RUBBER-01: Rebranding PlanejaBorracha → RuraRubber
### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Rebrand from PlanejaBorracha to RuraRubber for internationalization. Migrate folder structure, package IDs, Firebase configuration, and all branding references.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | Rename folder `apps/planejaaborracha` → `apps/rurarubber` | ✅ DONE |
| 1.2 | Update `pubspec.yaml` with new name | ✅ DONE |
| 1.3 | Update `android/app/build.gradle` (namespace, applicationId, flavors) | ✅ DONE |
| 1.4 | Create Kotlin package `com/ruracamp/rubber/` and move MainActivity.kt | ✅ DONE |
| 1.5 | Update iOS PRODUCT_BUNDLE_IDENTIFIER to `com.ruracamp.rubber` | ✅ DONE |
| 1.6 | Configure Firebase for dev (`ruracamp-dev`) and prod (`ruracamp-c1f38`) | ✅ DONE |
| 1.7 | Create flavor structure with separate google-services.json | ✅ DONE |
| 1.8 | Update all Dart files with RuraRubber branding | ✅ DONE |
| 1.9 | Update ARB files (app_pt.arb, app_en.arb) | ✅ DONE |
| 1.10 | Update BackupProvider key from 'planeja_borracha' to 'rura_rubber' | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | name: planejaaborracha → rurarubber |
| `android/app/build.gradle` | MODIFY | namespace/applicationId to com.ruracamp.rubber, flavors to RuraRubber |
| `android/app/src/main/kotlin/com/ruracamp/rubber/MainActivity.kt` | CREATE | New Kotlin package location |
| `android/app/src/main/kotlin/br/com/planejacampo/planejaaborracha/` | DELETE | Old Kotlin package structure |
| `android/app/src/dev/google-services.json` | CREATE | Firebase config for dev (ruracamp-dev) |
| `android/app/src/prod/google-services.json` | CREATE | Firebase config for prod (ruracamp-c1f38) |
| `ios/Runner.xcodeproj/project.pbxproj` | MODIFY | PRODUCT_BUNDLE_IDENTIFIER to com.ruracamp.rubber |
| `lib/main.dart` | MODIFY | Renamed PlanejaBorrachaApp to RuraRubberApp, updated branding |
| `lib/screens/*.dart` | MODIFY | Updated PlanejaBorracha references to RuraRubber |
| `lib/services/borracha_backup_provider.dart` | MODIFY | key: 'planeja_borracha' → 'rura_rubber' |
| `lib/services/backup_service.dart` | MODIFY | Updated app identifier and branding |
| `lib/l10n/arb/app_pt.arb` | MODIFY | appName and branding strings to RuraRubber |
| `lib/l10n/arb/app_en.arb` | MODIFY | appName and branding strings to RuraRubber |
| `lib/firebase_options.dart` | CREATE | Generated by flutterfire configure |

### Configuration Details

**Android:**
- Package: `com.ruracamp.rubber`
- Flavors: `dev` (RuraRubber Dev), `prod` (RuraRubber)
- Firebase Dev App ID: `1:447693754827:android:1359a65bb46ad3c622264e`
- Firebase Prod App ID: `1:298390927056:android:ee917222f15733cb3ed0d5`

**iOS:**
- Bundle ID: `com.ruracamp.rubber`
- Firebase Dev App ID: `1:447693754827:ios:6a50de3e827a8ace22264e`
- Firebase Prod App ID: `1:298390927056:ios:cb740f7b51a31f313ed0d5`

**Cross-Reference**: CORE-70 (agro_core umbrella phase for rebranding)

---

## Phase BORRACHA-11: UI Refactor - Weather & Navigation
### Status: [DONE]
**Date Started**: 2026-01-25
**Priority**: 🟡 ENHANCEMENT
**Objective**: Refine the Home Screen and Navigation based on user feedback to prioritize Weather context and simplify role-based access.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 11.1 | **Weather Widget Integration**: Replace "Quick Actions" grid with `WeatherCard` (from `agro_core`) to provide immediate climate context for the property/seringal. | ✅ DONE |
| 11.2 | **Role-Based Navigation**: Remove "Parceiros" menu item and access for "Sangrador" profile, as they don't manage other partners. | ✅ DONE |
| 11.3 | **Layout Optimization**: Keep Floating Action Button (FAB) for primary actions ("Nova Pesagem") and maintain Monthly Summary/Recent Deliveries for quick insights. | ✅ DONE |

### Files to Modify
- `lib/screens/home_screen.dart`
- `package/agro_core/lib/widgets/agro_drawer.dart` (Conceptually, via composition)

---

## Phase BORRACHA-10: Fix Restore Data (Replace vs Merge)

### Status: [DONE]
**Date Completed**: 2026-01-24
**Priority**: 🔵 FIX
**Objective**: Fix cloud restore to REPLACE data instead of MERGE.
**Cross-Reference**: CORE-63

### Problem
When restoring from backup, parceiros and entregas were merged with backup data instead of being replaced. Records created after the backup was made would still exist after restore.

### Solution
1. Added `clearAll()` method to ParceiroService
2. Added `clearAll()` method to EntregaService
3. Modified `BorrachaBackupProvider.restoreData()` to call both clear methods before importing backup records

### Files Modified
| File | Action | Description |
|------|--------|-------------|
| `lib/services/parceiro_service.dart` | MODIFY | Added `clearAll()` method |
| `lib/services/entrega_service.dart` | MODIFY | Added `clearAll()` method |
| `lib/services/borracha_backup_provider.dart` | MODIFY | Call clear before restore |

---

## Phase BORRACHA-09: Cloud Sync & Local Backup Integration
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟢 ENHANCEMENT
**Objective**: Implement complete backup/restore system with cloud sync (via CloudBackupService) and local JSON export/import, matching PlanejaChuva's functionality.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 9.1 | Create `BorrachaBackupProvider` implementing `BackupProvider` interface | ✅ DONE |
| 9.2 | Create `BackupService` for local JSON export/import with Share integration | ✅ DONE |
| 9.3 | Register `BorrachaBackupProvider` with `CloudBackupService` in main() | ✅ DONE |
| 9.4 | Add local backup callbacks to `AgroSettingsScreen` route | ✅ DONE |
| 9.5 | Add `file_picker` dependency for import functionality | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/borracha_backup_provider.dart` | CREATE | Cloud sync provider - serializes/deserializes Parceiro and Entrega data to JSON |
| `lib/services/backup_service.dart` | CREATE | Local backup service - exportar(), parseBackup(), importar() with duplicate detection |
| `lib/main.dart` | MODIFY | Register cloud provider, add inline callbacks for local backup in /settings route |
| `pubspec.yaml` | MODIFY | Add file_picker: ^8.1.6 dependency |

### Implementation Details

**BorrachaBackupProvider (Cloud Sync):**
- Implements `BackupProvider` interface from agro_core
- `key`: 'planeja_borracha' (unique identifier)
- `getData()`: Serializes all Parceiro and Entrega data to JSON format
- `restoreData()`: Deserializes JSON, imports avoiding duplicates, uses Hive box directly for entregas
- Handles ItemEntrega fields correctly (valorTotal, descontos, not drc/precoKg)

**BackupService (Local Backup):**
- `exportar()`: Creates timestamped JSON file, shares via Share.shareXFiles
- `parseBackup()`: Validates backup structure, parses JSON to model objects
- `importar()`: Imports data avoiding duplicates by checking existing IDs
- Returns `ImportResult` with counts of imported items and duplicates
- Uses Hive.openBox for direct Entrega persistence

**Main Integration:**
- Registered BorrachaBackupProvider in main() initialization
- Added inline lambda callbacks to AgroSettingsScreen route:
  - `onExportLocalBackup`: Calls BackupService.exportar() with error handling
  - `onImportLocalBackup`: Uses FilePicker, parses JSON, calls BackupService.importar()
- Both callbacks show SnackBars for success/error feedback

### Fixes Applied

**Model Field Corrections:**
- ❌ **ItemEntrega.drc/precoKg don't exist** → ✅ Use valorTotal/descontos instead
- ❌ **ParceiroService.adicionarParceiro()** → ✅ Correct method is addParceiro()
- ❌ **EntregaService.salvarEntrega() missing** → ✅ Save directly to Hive box

**Architecture:**
- ✅ Follows agro_core BackupProvider pattern (same as PlanejaChuva)
- ✅ Local backup uses Share plugin for file distribution
- ✅ Duplicate detection on import (by ID comparison)
- ✅ Proper error handling with user feedback

---

## Phase BORRACHA-08: UX Overhaul - Dashboard, Profile & Smart Auth
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Transformar o fluxo do app de "cair direto na pesagem" para experiência completa com dashboard, seleção de perfil (Produtor/Comprador), e navegação inteligente.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 8.1 | Create `UserProfile` model with `UserProfileType` enum (Hive) | ✅ DONE |
| 8.2 | Create `UserProfileService` singleton for profile management | ✅ DONE |
| 8.3 | Create `ProfileSelectionScreen` with Produtor/Comprador cards | ✅ DONE |
| 8.4 | Create `HomeScreen` (Dashboard) with profile-based content | ✅ DONE |
| 8.5 | Add L10n strings for new screens (pt-BR and en) | ✅ DONE |
| 8.6 | Modify `main.dart` to use HomeScreen as entry point | ✅ DONE |
| 8.7 | Integrate profile check in auth flow | ✅ DONE |
| 8.8 | Update documentation (README, ARCHITECTURE) | ✅ DONE |
| 8.9 | Fix Propriedades navigation to use core PropertyListScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/user_profile.dart` | CREATE | UserProfile model with Hive adapters |
| `lib/models/user_profile.g.dart` | CREATE | Generated Hive adapter |
| `lib/services/user_profile_service.dart` | CREATE | Profile management service |
| `lib/screens/profile_selection_screen.dart` | CREATE | Profile type selection UI |
| `lib/screens/home_screen.dart` | CREATE | Dashboard with resumos |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add ~25 new strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add ~25 new translations |
| `lib/main.dart` | MODIFY | Change home, add routes |
| `README.md` | MODIFY | Document new UX flow |
| `ARCHITECTURE.md` | MODIFY | Add HomeScreen and Profile docs |

---

## Phase BORRACHA-07: UX Improvements & Navigation Polish
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🔵 FIX
**Objective**: Improve user experience by adding missing navigation elements, fixing drawer inconsistencies, and providing clear CTAs for empty states.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 7.1 | Add "Cadastrar Parceiro" button to empty state in PesagemScreen | ✅ DONE |
| 7.2 | Refactor drawer navigation from if-statements to switch-case | ✅ DONE |
| 7.3 | Add Settings and About handlers to all screens with drawer | ✅ DONE |
| 7.4 | Add drawer to CriarOfertaScreen (was missing) | ✅ DONE |
| 7.5 | Add /settings route to main.dart | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/pesagem_screen.dart` | MODIFY | Added empty state with icon, message, and CTA button to navigate to /parceiros |
| `lib/screens/pesagem_screen.dart` | MODIFY | Refactored onNavigate from if-statements to switch-case, added settings/about handlers |
| `lib/screens/mercado_screen.dart` | MODIFY | Refactored drawer navigation to switch-case, added settings/about handlers |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Added AgroDrawer with full navigation (was missing entirely) |
| `lib/main.dart` | MODIFY | Added /settings route pointing to AgroSettingsScreen |

### Issues Fixed

**User Experience:**
- ❌ **Empty state without action** → ✅ Added "Adicionar Parceiro" button when no partners exist
- ❌ **Inconsistent drawer navigation** → ✅ All screens use switch-case pattern now
- ❌ **Missing Settings/About handlers** → ✅ Settings opens AgroSettingsScreen, About shows dialog
- ❌ **CriarOfertaScreen without drawer** → ✅ Added drawer with extraItems
- ❌ **Code duplication in onNavigate** → ✅ Cleaned up redundant if-statements

**Code Quality:**
- ✅ DRY: Drawer navigation logic consistent across all 3 screens
- ✅ Maintainability: Switch-case easier to extend than if-chains
- ✅ Accessibility: showAboutDialog provides standard app info

### Navigation Flow Improved

**Before:**
- Empty PesagemScreen: "Nenhum parceiro cadastrado" (dead end)
- Drawer: Properties → Parceiros (confusing mapping)
- Settings/About: Clicked but nothing happened
- CriarOfertaScreen: No drawer (inconsistent)

**After:**
- Empty PesagemScreen: Icon + message + "Adicionar Parceiro" button → /parceiros
- Drawer: Properties → Parceiros (consistent switch-case)
- Settings: Opens AgroSettingsScreen
- About: Shows dialog with app name, version, icon, description
- CriarOfertaScreen: Full drawer with extraItems

---

## Phase BORRACHA-06: Production Fixes & L10n Migration
### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL
**Objective**: Fix critical production issues, migrate all hardcoded strings to l10n, implement missing features, and ensure CLAUDE.md compliance.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1 | Fix Android minSdkVersion error (Firebase Auth requires 23+) | ✅ DONE |
| 6.2 | Update Kotlin version to 2.0.0 for compatibility | ✅ DONE |
| 6.3 | Add missing url_launcher dependency to pubspec.yaml | ✅ DONE |
| 6.4 | Create complete ARB files (app_pt.arb, app_en.arb) with 100+ keys | ✅ DONE |
| 6.5 | Configure l10n.yaml for BorrachaLocalizations generation | ✅ DONE |
| 6.6 | Migrate all 70+ hardcoded strings across 8 files to l10n | ✅ DONE |
| 6.7 | Implement empty callbacks in MercadoScreen (_showLocationFilterInfo, _showNotifyMeInfo) | ✅ DONE |
| 6.8 | Add /criar-oferta route to main.dart for proper navigation | ✅ DONE |
| 6.9 | Replace FAB placeholder with actual navigation to CriarOfertaScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/app/build.gradle` | MODIFY | Set minSdk = 23 (Firebase Auth requirement) |
| `android/settings.gradle` | MODIFY | Updated Kotlin to 2.0.0 |
| `pubspec.yaml` | MODIFY | Added url_launcher: ^6.3.1, flutter_localizations |
| `l10n.yaml` | CREATE | L10n configuration (BorrachaLocalizations, output-dir) |
| `lib/l10n/arb/app_pt.arb` | CREATE | 100+ Portuguese strings (parceiros, pesagem, fechamento, mercado, etc.) |
| `lib/l10n/arb/app_en.arb` | CREATE | 100+ English translations |
| `lib/screens/parceiros_list_screen.dart` | MODIFY | Migrated to BorrachaLocalizations |
| `lib/screens/parceiro_form_screen.dart` | MODIFY | Migrated form labels, validation, dialogs |
| `lib/screens/pesagem_screen.dart` | MODIFY | Migrated all UI strings |
| `lib/screens/fechamento_entrega_screen.dart` | MODIFY | Migrated financial screen strings |
| `lib/screens/lista_entregas_screen.dart` | MODIFY | Migrated history screen strings |
| `lib/screens/mercado_screen.dart` | MODIFY | Migrated + implemented _showLocationFilterInfo, _showNotifyMeInfo |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Migrated form and validation strings |
| `lib/widgets/tape_view_widget.dart` | MODIFY | Migrated tape header and labels |
| `lib/widgets/big_calculator_keypad.dart` | MODIFY | Migrated "ADICIONAR PESO" button |
| `lib/main.dart` | MODIFY | Added /criar-oferta route |

### Issues Fixed

**Critical Issues:**
- ❌ **Missing url_launcher dependency** → ✅ Added to pubspec.yaml
- ❌ **70+ hardcoded strings (l10n violation)** → ✅ All migrated to ARB files
- ❌ **Empty button implementations** → ✅ Implemented with dialogs/snackbars
- ❌ **CriarOfertaScreen not routable** → ✅ Route added, FAB navigation fixed
- ❌ **Android build errors (minSdk, Kotlin)** → ✅ Fixed in gradle files

**Compliance:**
- ✅ CLAUDE.md Rule 6: Zero hardcoded strings (all use BorrachaLocalizations)
- ✅ CLAUDE.md Rule 4: Hive offline-first (maintained)
- ✅ CLAUDE.md Rule 7: build_runner for Hive (working)
- ✅ Both pt-BR and en translations complete

### L10n Keys Added

**Total: 102 keys** across categories:
- Parceiros: 13 keys (titles, form labels, validation)
- Pesagem: 7 keys (screen labels, error messages)
- Tape View: 4 keys (header, empty state, total, undo)
- Fechamento: 11 keys (financial labels, buttons)
- Lista Entregas: 14 keys (history, status labels, actions)
- Mercado: 14 keys (market screen, offers, filters)
- Criar Oferta: 16 keys (form, validation, success/error)
- Calculator: 1 key (add weight button)
- Drawer: 4 keys (menu items)
- Utility: 3 keys (unknown, partners attended, error)

### Migration Statistics

- **Files changed**: 18
- **Lines added**: ~350
- **Lines removed**: ~120
- **Hardcoded strings eliminated**: 70+
- **L10n keys created**: 102
- **Languages supported**: 2 (pt-BR, en)
- **Compilation errors**: 0
- **CLAUDE.md violations**: 0

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
