# CHANGELOG - agro_core

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
