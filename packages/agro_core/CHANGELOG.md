# CHANGELOG - agro_core

---

## Phase 16.0: Property Management Foundation

### Status: [DONE] (Phases 16.1-16.3) | [PENDING] (Phases 16.4-16.5)
**Date Completed**: 2026-01-18
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implement multi-property support with cross-app sharing via userId.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 16.1 | Core models and services (Property, PropertyService) | ✅ DONE |
| 16.2 | Update RegistroChuva with propertyId | ✅ DONE |
| 16.3 | Property management UI (list + form screens) | ✅ DONE |
| 16.4 | Integrate property selectors in rainfall screens | ⏳ PENDING |
| 16.5 | First-time UX (educational tips) | ⏳ PENDING |

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
| `lib/agro_core.dart` | MODIFY | Added Property, PropertyService, and screen exports |

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

## Phase 15.7: Identity-First Onboarding (Porta de Entrada)

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

## Phase 15.6: Commercial Consent Language (Legal & Commercial Alignment)

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

## Phase 2.0: Standard Menu and Base Screens

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

## Phase 1.0: Privacy Onboarding Flow

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
