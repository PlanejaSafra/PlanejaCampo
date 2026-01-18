# CHANGELOG - agro_core

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
