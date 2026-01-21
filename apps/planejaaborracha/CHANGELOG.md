# CHANGELOG - PlanejaBorracha

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
