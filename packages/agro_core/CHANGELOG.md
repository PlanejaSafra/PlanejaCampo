# CHANGELOG - agro_core

---

## Phase CORE-41: Cloud Backup UX Improvements

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔵 FIX
**Objective**: Improve Cloud Backup UX - show login prompt when not authenticated, internationalize all strings, separate cloud and local backup.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 41.1 | Add l10n strings for backup, theme, notifications | ✅ DONE |
| 41.2 | Check auth status in AgroSettingsScreen | ✅ DONE |
| 41.3 | Show "Sign in with Google" prompt if not logged in | ✅ DONE |
| 41.4 | Separate Cloud Backup (prominent) and Local Backup (smaller) | ✅ DONE |
| 41.5 | Add callbacks: onSignInWithGoogle, onExportLocalBackup, onImportLocalBackup | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add ~25 backup/settings strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add ~25 backup/settings strings |
| `lib/screens/agro_settings_screen.dart` | MODIFY | Complete rewrite with auth check, l10n, separated backup sections |

---

## Phase CORE-40: Hail Detection Alert

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Add specific hail detection using WMO weather codes 96 and 99.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 40.1 | Add `hail` type to WeatherAlertType enum | ✅ DONE |
| 40.2 | Add hail detection in analyzeForecasts() | ✅ DONE |
| 40.3 | Add l10n strings for hail alert | ✅ DONE |
| 40.4 | Update WeatherCard/DetailScreen to display hail alert | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/weather_alert.dart` | MODIFY | Add hail enum value, color (indigo), icon (grain) |
| `lib/services/weather_service.dart` | MODIFY | Detect codes 96 (medium), 99 (high severity) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add alertHailTitle/Message |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add alertHailTitle/Message |
| `lib/widgets/weather_card.dart` | MODIFY | Handle hail alert display |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Handle hail alert in alerts list |

---

## Phase CORE-33: Cloud Backup Integration

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 MEDIUM
**Objective**: Unified cloud backup system for all apps provided by agro_core.

### Implementation Summary
*   **Service**: `CloudBackupService` in `agro_core` manages Firebase Storage uploads/downloads.
*   **Provider**: `ChuvaBackupProvider` implements data serialization for PlanejaChuva.
*   **UI**: Backup controls added to `AgroSettingsScreen`.

---

## Phase CORE-34: Data Migration & UI Polish

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Allow seamless migration from anonymous to authenticated accounts, preserving all user data. Conditional UI display for properties/talhões.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 34.1 | Implement `linkWithCredential` for anonymous → Google | ✅ DONE |
| 34.2 | Handle `credential-already-in-use` error (merge conflict) | ✅ DONE |
| 34.3 | Create `DataMigrationService.transferAllData(oldUid, newUid)` | ✅ DONE |
| 34.4 | Add migration UI flow with progress indicator | ✅ DONE |
| 34.5 | UI: Show Property Name only if user has > 1 property | ✅ DONE |
| 34.6 | UI: Show Talhão Name only if > 1 talhão exists | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/auth_service.dart` | EXISTS | linkAnonymousToGoogle() already implemented |
| `lib/services/data_migration_service.dart` | MODIFY | Added transferAllData() with progress callbacks |
| `lib/services/property_service.dart` | EXISTS | transferData() already implemented |
| `lib/services/talhao_service.dart` | MODIFY | Added transferData() method |
| `lib/screens/login_screen.dart` | EXISTS | _handleMergeConflict() already implemented |
| `lib/widgets/weather_card.dart` | MODIFY | 34.5: Property label only if > 1 property |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 10 migration strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 10 migration strings |

### App-Specific Files (planejachuva)

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/registro_chuva_tile.dart` | MODIFY | 34.6: Talhão label only if > 1 talhão |

---

## Phase CORE-35: Privacy & Consent Updates

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL (LGPD)
**Objective**: Granular consent management and "Revoke All" functionality.

### Implementation Summary
*   **Granular Getters**: Added specific getters in `AgroPrivacyStore` for Analytics, Location, Ads, and Partners.
*   **Revoke All**: Implemented functionality to revoke all consents and sign out.
*   **UI**: Updated `AgroPrivacyScreen` to reflect granular consents.

---

## Phase CORE-39: Weather Alerts & Critical Conditions

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL (Risk Management)
**Objective**: Proactively notify users of critical weather conditions (Frost, Drought, Heat Wave, Storms) based on forecast analysis.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 39.1 | Define `WeatherAlert` model (Enums, Severity, Class) | ✅ DONE |
| 39.2 | Implement `WeatherService.analyzeForecasts` logic | ✅ DONE |
| 39.3 | Add localization strings for alerts | ✅ DONE |
| 39.4 | Update `WeatherCard` to show active alert badges | ✅ DONE |
| 39.5 | Update `WeatherDetailScreen` to list detailed alerts | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/weather_alert.dart` | CREATE | Model definition for alerts |
| `lib/services/weather_service.dart` | MODIFY | Logic to generate alerts from forecast |
| `lib/widgets/weather_card.dart` | MODIFY | UI: Alert badge/banner |
| `lib/screens/weather_detail_screen.dart` | MODIFY | UI: Detailed alert list |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Alert strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Alert strings |

---

## Phase CORE-38: Weather Enhancements (Wind & UI)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Add wind speed/direction to weather forecast and improve UI to indicate property-specific data.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 38.1 | Add `windSpeed` and `windDirection` to `WeatherForecast` model | ✅ DONE |
| 38.2 | Update `WeatherService` to fetch/parse wind attributes | ✅ DONE |
| 38.3 | Update `WeatherCard` (Home) with wind info & property label | ✅ DONE |
| 38.4 | Update `WeatherDetailScreen` with wind info (Header, Hourly, Daily) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/weather_forecast.dart` | MODIFY | Added wind fields & helper |
| `lib/services/weather_service.dart` | MODIFY | Fetch wind metrics from Open-Meteo |
| `lib/widgets/weather_card.dart` | MODIFY | UI: Wind info & Property name label |
| `lib/screens/weather_detail_screen.dart` | MODIFY | UI: Wind info in all sections |

---

## Phase CORE-37: LGPD Data Portability (Right to Data Portability)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 IMPORTANT (LGPD Art. 18, V)
**Objective**: Allow users to export their data in a standard, machine-readable format.

### LGPD Requirement

> **Art. 18, V** - O titular dos dados pessoais tem direito a obter do controlador:
> "portabilidade dos dados a outro fornecedor de serviço ou produto"

### Difference from Backup

| Feature | Backup (atual) | Portabilidade (novo) |
|---------|----------------|----------------------|
| Formato | Interno (Hive/JSON proprietário) | JSON/CSV padrão |
| Legibilidade | Só funciona no mesmo app | Legível por humanos e sistemas |
| Propósito | Restaurar dados | Levar dados para outro serviço |
| LGPD | Não obrigatório | **Obrigatório (Art. 18, V)** |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 37.1 | Create `DataExportService` in agro_core | ✅ DONE |
| 37.2 | Implement JSON export (human-readable) | ✅ DONE |
| 37.3 | Implement CSV export (spreadsheet-compatible) | ✅ DONE |
| 37.4 | Add l10n strings for export UI | ✅ DONE |
| 37.5 | Integrate with Share Sheet (share_plus) | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_export_service.dart` | CREATE | Service com exportToJson, exportToCsv, shareExport |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Adicionadas 7 strings de exportação |
| `lib/l10n/arb/app_en.arb` | MODIFY | Adicionadas 7 strings de exportação |
| `lib/agro_core.dart` | MODIFY | Export data_export_service.dart |

### Data to Export

| Category | Fields | Format |
|----------|--------|--------|
| **Registros de Chuva** | data, mm, observação, propriedade, talhão | JSON array / CSV |
| **Propriedades** | nome, área, latitude, longitude | JSON array / CSV |
| **Talhões** | nome, área, cultura, propriedade | JSON array / CSV |
| **Configurações** | idioma, horário notificação | JSON object |
| **Consentimentos** | timestamps, valores | JSON object |

### Export Format Structure
The export format is a JSON object containing:
- Metadata (exportedAt, appVersion)
- User info (id, email)
- Data (properties, rainfall_records, field_plots, settings)
- Consents (timestamps, values)

### Proposed Service Logic
The `DataExportService` handles:
1. Fetching all user data (Firestore + Hive)
2. Formatting as JSON structure
3. Converting to CSV (flattened)
4. Sharing file via system share sheet

### UI Flow
AgroPrivacyScreen -> "Exportar meus dados" button -> Bottom Sheet -> Choose Format (JSON/CSV) -> Native Share Sheet

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_export_service.dart` | CREATE | Service para exportar dados |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add export button and bottom sheet |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add export-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add export-related strings |
| `pubspec.yaml` | MODIFY | Add share_plus dependency (if not present) |

### Dependencies
- `share_plus` (native share sheet)
- `path_provider` (temp file storage)

---

## Phase CORE-36: LGPD Data Deletion (Right to Erasure)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL (LGPD Art. 18, VI)
**Objective**: Implement complete user data deletion to comply with LGPD "right to erasure" requirement.

### LGPD Requirement
Users have the right to request deletion of personal data treated with consent.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 36.1 | Create `DataDeletionService` in agro_core | ✅ DONE |
| 36.2 | Implement Firestore user data deletion | ✅ DONE |
| 36.3 | Implement Firebase Auth account deletion | ✅ DONE |
| 36.4 | Implement local Hive data cleanup | ✅ DONE |
| 36.5 | Add l10n strings for deletion UI | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_deletion_service.dart` | CREATE | Service com deleteAllUserData, Hive box registration |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Adicionadas 9 strings de deleção |
| `lib/l10n/arb/app_en.arb` | MODIFY | Adicionadas 9 strings de deleção |
| `lib/agro_core.dart` | MODIFY | Export data_deletion_service.dart |

### Data to Delete
- **Firestore**: User document and all subcollections (consents, properties, etc.)
- **Firebase Auth**: User account
- **Hive (Local)**: All user-related boxes (settings, chuvas, properties, talhoes, cache)

### What is NOT Deleted

| Data | Reason |
|------|--------|
| Dados agregados/estatísticos | LGPD Art. 12 - Dados anonimizados não são dados pessoais |
| Métricas regionais | Não identificam o usuário individual |
| Logs de servidor (se houver) | Retenção mínima para segurança (30 dias) |

### Proposed Service Logic
The `DataDeletionService` orchestrates:
1. Deleting Firestore subcollections and documents
2. Deleting Firebase Auth account
3. Clearing local Hive boxes
4. Resetting privacy store

### UI Flow
AgroPrivacyScreen -> "Excluir meus dados" button -> Confirmation Dialog (Checkbox + Red Button) -> Loading -> Success -> Restart

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_deletion_service.dart` | CREATE | Service para deletar dados |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add deletion button and dialog |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add deletion-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add deletion-related strings |

---

## Phase CORE-35: Privacy & Consent Updates (Advanced)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Enhance privacy management with granular consent controls and real-time reactive UI.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 35.1 | Add granular getters (canCollectAnalytics, canUseLocation) to AgroPrivacyStore | ✅ DONE |
| 35.2 | Add "Revogar Tudo e Sair" button to AgroPrivacyScreen | ✅ DONE |
| 35.3 | Make WeatherCard listen to consent changes reactively | ✅ DONE |
| 35.4 | Verify LGPD compliance with simplified consent flow | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Added granular getters & listenables |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Added "Revogar Tudo e Sair" button |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added revoke strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added revoke strings |
| `lib/widgets/weather_card.dart` | MODIFY | Reactive consent check |

---

## Phase CORE-16.1: UX Simplification - Consent Flow

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔵 FIX
**Objective**: Simplify consent and location permission flow for better UX and LGPD compliance.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 16.1.1 | Remove intermediate dialog in WeatherCard | ✅ DONE |
| 16.1.2 | Simplify consent screen layout (title + short intro) | ✅ DONE |
| 16.1.3 | Remove checkbox descriptions (titles only) | ✅ DONE |
| 16.1.4 | Move detailed explanations to Privacy Policy Section 7 | ✅ DONE |
| 16.1.5 | Sync AgroPrivacyScreen with same simplified labels | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/weather_card.dart` | MODIFY | Removed "Permissão Necessária" dialog - goes directly to ConsentScreen |
| `lib/privacy/consent_screen.dart` | MODIFY | Simplified layout with short intro text |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Synchronized with ConsentScreen (empty descriptions) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Simplified consent texts (titles only, empty descriptions) |
| `lib/l10n/arb/app_en.arb` | MODIFY | Simplified consent texts (titles only, empty descriptions) |
| `lib/screens/privacy_policy_screen.dart` | MODIFY | Added Section 7 with detailed consent explanations |

### Final Consent Screen Layout

```
Title: "Recursos e compartilhamento (opcional)"
Intro: "Autorize o uso de dados e recursos opcionais:"

☐ Dados e Localização
☐ Ofertas e Promoções
☐ Anúncios Personalizados

[ACEITAR TUDO E CONTINUAR] / [CONFIRMAR E CONTINUAR]
[NÃO ACEITAR]

Links: Termos de Uso | Políticas de Privacidade
```

### LGPD Compliance

✅ Títulos claros e auto-explicativos
✅ Detalhes acessíveis na Política de Privacidade (Seção 7)
✅ Consentimentos granulares e separados
✅ Opcional (usuário pode recusar e usar o app)
✅ Revogável a qualquer momento (Configurações > Privacidade)

---

## Phase CORE-16.0: Property Management Foundation

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implement multi-property support with cross-app sharing via userId.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 16.1 | Core models and services (Property, PropertyService) | ✅ DONE |
| 16.2 | Update RegistroChuva with propertyId | ✅ DONE |
| 16.3 | Property management UI (list + form screens) | ✅ DONE |
| 16.4 | Integrate property selectors in rainfall screens | ✅ DONE |
| 16.5 | PropertyHelper (cached lookups) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/property.dart` | CREATE | Property model (Hive typeId: 10) with userId for cross-app sharing |
| `lib/models/property.g.dart` | GENERATE | Hive adapter for Property |
| `lib/services/property_service.dart` | CREATE | Property CRUD service (201 lines) |
| `lib/screens/property_list_screen.dart` | CREATE | Property list/management screen (304 lines) |
| `lib/screens/property_form_screen.dart` | CREATE | Add/edit property form (238 lines) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 35 property strings (PT-BR) |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 35 property strings (EN) |
| `lib/l10n/generated/*.dart` | GENERATE | Regenerated with new strings |
| `lib/menu/agro_drawer.dart` | MODIFY | Added Properties menu item |
| `lib/menu/agro_drawer_item.dart` | MODIFY | Added 'properties' route key |
| `lib/services/property_helper.dart` | CREATE | PropertyHelper singleton with name caching (48 lines) |
| `lib/agro_core.dart` | MODIFY | Added Property, PropertyService, PropertyHelper, and screen exports |

### Key Features

**Property Model**:
- Unique ID (timestamp-based)
- userId (Firebase Auth - enables cross-app sharing)
- Name, total area, location (lat/lng)
- isDefault flag (one per user)

**Cross-App Sharing**:
- Properties stored in agro_core (shared across PlanejaChuva, PlanejaBorracha, etc.)
- Filtered by userId (Firebase Auth)
- One property configuration, multiple app usage

**Auto-Creation**:
- Default property ("Minha Propriedade") created automatically
- Zero friction onboarding (progressive disclosure)
- User can manage properties later via Drawer → Propriedades

**Migration Strategy**:
- MigrationService links existing records to default property
- One-time migration with cached flag
- Non-destructive (preserves all existing data)

### See Also
- Detailed documentation: `CHANGELOG_PHASE_16.md`
- Architecture design: `PROPERTY_MANAGEMENT_ARCHITECTURE.md`

---

## Phase CORE-15.7: Identity-First Onboarding (Porta de Entrada)

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Replace Terms screen with Identity screen (Google Login or Anonymous) to capture emails early and reduce onboarding friction, following market standards (Uber, iFood, Nubank).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 15.7.1 | Add google_sign_in dependency to pubspec.yaml | ✅ DONE |
| 15.7.2 | Create AuthService for Google and Anonymous authentication | ✅ DONE |
| 15.7.3 | Add L10n strings for Identity screen (pt + en) | ✅ DONE |
| 15.7.4 | Create IdentityScreen widget | ✅ DONE |
| 15.7.5 | Update OnboardingGate to use IdentityScreen | ✅ DONE |
| 15.7.6 | Delete TermsPrivacyScreen (no longer needed) | ✅ DONE |
| 15.7.7 | Update agro_core.dart exports | ✅ DONE |
| 15.7.8 | Regenerate l10n and run flutter pub get | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Added google_sign_in: ^6.2.2 |
| `lib/services/auth_service.dart` | CREATE | Firebase Auth service (Google + Anonymous + Account Linking) |
| `lib/privacy/identity_screen.dart` | CREATE | New identity screen with Google and Guest buttons |
| `lib/privacy/onboarding_gate.dart` | MODIFY | Replaced TermsPrivacyScreen with IdentityScreen |
| `lib/privacy/terms_privacy_screen.dart` | DELETE | Removed (no longer used, no code ghosts) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 14 new identity-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 14 new identity-related strings |
| `lib/l10n/generated/*.dart` | GENERATE | Regenerated with new identity strings |
| `lib/agro_core.dart` | MODIFY | Updated exports (removed terms, added identity + auth_service) |

### New Onboarding Flow

**BEFORE**:
```
Splash → TermsPrivacyScreen → ConsentScreen → Home
```

**AFTER**:
```
Splash → IdentityScreen → ConsentScreen → Home
        (Google/Guest)   (3 checkboxes)
```

### UX Improvements

- **Conversion Rate**: 60-70% → 85-95% (estimated)
- **Email Capture**: 0% → 40-60% (Google login)
- **Time to Onboard**: ~30s → ~5s (1-click login)

### LGPD Compliance Maintained

- ✅ Art. 8, §4: Individualized consent
- ✅ Art. 9, §1: Inequivocal manifestation (click)
- ✅ Market precedent: Uber, iFood, Nubank

### Notes

- TermsPrivacyScreen deleted (no code ghosts)
- Terms accessible via Settings → Privacy
- Requires SHA-1 setup for Android Google Sign-In

---

## Phase CORE-15.6: Commercial Consent Language (Legal & Commercial Alignment)

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟢 ENHANCEMENT
**Objective**: Update consent language to support commercial use cases (data commercialization, partnerships, ad networks) while maintaining LGPD compliance.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 15.6.1 | Analyze current consent limitations | ✅ DONE |
| 15.6.2 | Create commercial alignment plan document | ✅ DONE |
| 15.6.3 | Update PT-BR consent texts in app_pt.arb | ✅ DONE |
| 15.6.4 | Update EN consent texts in app_en.arb | ✅ DONE |
| 15.6.5 | Add detailed "Learn More" texts for each consent | ✅ DONE |
| 15.6.6 | Update privacy keys documentation | ✅ DONE |
| 15.6.7 | Regenerate l10n files | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `CONSENT_COMMERCIAL_ALIGNMENT_PLAN.md` | CREATE | Detailed plan with legal analysis and implementation checklist |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Updated 3 consent texts + added 3 detailed "Learn More" texts (PT-BR) |
| `lib/l10n/arb/app_en.arb` | MODIFY | Updated 3 consent texts + added 3 detailed "Learn More" texts (EN) |
| `lib/privacy/agro_privacy_keys.dart` | MODIFY | Updated documentation comments for consent keys |
| `lib/l10n/generated/app_localizations.dart` | GENERATE | Added consentOption1/2/3LearnMore getters |
| `lib/l10n/generated/app_localizations_pt.dart` | GENERATE | PT translations with new commercial language |
| `lib/l10n/generated/app_localizations_en.dart` | GENERATE | EN translations with new commercial language |

### Consent Changes Summary

**Checkbox 1: "Uso de Dados e Inteligência de Mercado" (Data Usage and Market Intelligence)**
- ✅ Authorizes data commercialization, sale, and licensing
- ✅ Covers individual AND aggregated data
- ✅ Partners in ANY sector (agribusiness, finance, retail, digital entertainment)
- 📊 Learn More: Detailed examples of data monetization use cases

**Checkbox 2: "Receber Ofertas e Oportunidades" (Receive Offers and Opportunities)**
- ✅ Authorizes direct communication from partners (app, email, SMS, WhatsApp)
- ✅ Explicitly includes controversial sectors (gaming, betting)
- ⚠️ Disclaimer: Partners are NOT curated by PlanejaCampo
- ⚠️ Disclaimer: Ad platforms (Google, Meta) control advertisements
- 📢 Learn More: List of all possible partner types and communication channels

**Checkbox 3: "Publicidade Personalizada" (Personalized Advertising)**
- ✅ Authorizes third-party ad networks (Google Ads, Meta)
- ✅ Explicitly mentions data sharing for ad targeting
- ✅ Includes lookalike audiences and behavioral profiling
- 🎯 Learn More: Detailed explanation of how ad tracking works, shadow profiles, and cross-platform targeting

### Legal Compliance

- ✅ LGPD Art. 7, IX - Explicit consent maintained
- ✅ LGPD Art. 9, §3 - Specific purposes clearly stated
- ✅ LGPD Art. 9, §4 - Language is clear (enhanced with "Learn More")
- ✅ No re-consent required (no existing users yet)
- ✅ Google Play Data Safety compatible (requires disclosure in app store listing)

### Key Features

- **Transparency**: "Learn More" texts explain in detail what each consent means
- **User Control**: Users can still use app 100% offline without accepting any consent
- **Commercial Flexibility**: Enables data monetization, partnerships, and ad networks
- **Legal Safety**: Explicit mentions of commercialization, sale, and third-party sharing

### Notes

- Privacy keys remain unchanged (backwards compatible)
- Consent screen code requires NO changes (UI is driven by l10n)
- Phase 15.0 (Regional Statistics) and 14.0 (Weather Forecast) are NOT affected

---

## Phase CORE-02.0: Standard Menu and Base Screens

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Create reusable drawer menu (AgroDrawer) and base screens (Settings, About, Privacy) with l10n support.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.0.1 | Update ARB files with new l10n keys | ✅ DONE |
| 2.0.2 | Create AgroDrawer and AgroDrawerItem | ✅ DONE |
| 2.0.3 | Create AgroSettingsScreen | ✅ DONE |
| 2.0.4 | Create AgroAboutScreen | ✅ DONE |
| 2.0.5 | Create AgroPrivacyScreen (with consents management) | ✅ DONE |
| 2.0.6 | Update agro_core.dart exports | ✅ DONE |
| 2.0.7 | Regenerate l10n | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/l10n/arb/app_en.arb` | MODIFY | Added drawer, settings, about, privacy l10n keys |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added drawer, settings, about, privacy l10n keys |
| `lib/menu/agro_drawer.dart` | CREATE | Reusable drawer widget |
| `lib/menu/agro_drawer_item.dart` | CREATE | Drawer item model and route keys |
| `lib/screens/agro_settings_screen.dart` | CREATE | Settings screen |
| `lib/screens/agro_about_screen.dart` | CREATE | About screen |
| `lib/screens/agro_privacy_screen.dart` | CREATE | Privacy and consents management screen |
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Added getBox() and setConsent() methods |
| `lib/agro_core.dart` | MODIFY | Export new menu and screens |

### Components Overview

**AgroDrawer**
- Reusable drawer with header (app name, version)
- Standard items: Home, Settings, Privacy, About
- Supports extra app-specific items via `extraItems`
- Navigation via `onNavigate(routeKey)` callback

**AgroRouteKeys**
- `home`, `settings`, `privacy`, `about`

**Base Screens**
- `AgroSettingsScreen`: Language placeholder, navigate to About
- `AgroAboutScreen`: App info, version, offline-first badge
- `AgroPrivacyScreen`: Terms summary, consent toggles (persisted in Hive)

---

## Phase CORE-01.0: Privacy Onboarding Flow

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Create reusable privacy onboarding screens with l10n support (pt-BR + en) for all PlanejaSafra apps.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.0.1 | Update pubspec.yaml with dependencies (hive, hive_flutter, flutter_localizations) | ✅ DONE |
| 1.0.2 | Create l10n.yaml and ARB files (pt-BR, en) | ✅ DONE |
| 1.0.3 | Create agro_privacy_keys.dart | ✅ DONE |
| 1.0.4 | Create agro_privacy_store.dart | ✅ DONE |
| 1.0.5 | Create terms_privacy_screen.dart | ✅ DONE |
| 1.0.6 | Create consent_screen.dart | ✅ DONE |
| 1.0.7 | Create onboarding_gate.dart | ✅ DONE |
| 1.0.8 | Update agro_core.dart exports | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Added hive, hive_flutter, flutter_localizations dependencies |
| `l10n.yaml` | CREATE | l10n configuration file |
| `lib/l10n/arb/app_pt.arb` | CREATE | Portuguese (Brazil) translations |
| `lib/l10n/arb/app_en.arb` | CREATE | English translations |
| `lib/l10n/generated/app_localizations.dart` | GENERATE | Generated l10n class |
| `lib/l10n/generated/app_localizations_pt.dart` | GENERATE | PT translations |
| `lib/l10n/generated/app_localizations_en.dart` | GENERATE | EN translations |
| `lib/privacy/agro_privacy_keys.dart` | CREATE | Centralized Hive box keys |
| `lib/privacy/agro_privacy_store.dart` | CREATE | Static privacy store with Hive persistence |
| `lib/privacy/terms_privacy_screen.dart` | CREATE | Terms of Use + Privacy Policy screen |
| `lib/privacy/consent_screen.dart` | CREATE | Optional consents screen |
| `lib/privacy/onboarding_gate.dart` | CREATE | Gate widget that controls onboarding flow |
| `lib/agro_core.dart` | MODIFY | Export new privacy and l10n modules |

### Screens Overview

**Screen 1 - Terms & Privacy (Mandatory)**
- User must accept to enter the app
- "Accept and Continue" → saves acceptance, navigates to Screen 2
- "Decline (Exit)" → closes app via SystemNavigator.pop()

**Screen 2 - Consents (Optional)**
- 3 toggle options (all OFF by default):
  1. Aggregate data for regional metrics
  2. Share with partners (aggregated)
  3. Personalized ads/offers
- "Accept and Continue" → enables all, enters app
- "Decline" → keeps all OFF, enters app (private mode)

---
