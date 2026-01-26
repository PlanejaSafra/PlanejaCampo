# CHANGELOG - agro_core

---

## Phase CORE-77: Arquitetura de Backup Dependency-Aware

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Arquitetura de backup/restore que protege integridade cross-app, verifica dependências antes de deletar, e prepara para multi-user.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 77.1 | sourceApp no FarmOwnedMixin (nullable, retrocompat) | ✅ DONE |
| 77.2 | DependencyService + DependencyManifest (Hive typeId 30) | ✅ DONE |
| 77.3 | RestoreAnalysis + RestoreFarmAccess (ownership check) | ✅ DONE |
| 77.4 | BackupMeta model (plain Dart) | ✅ DONE |
| 77.5 | EnhancedBackupProvider (3-phase restore) | ✅ DONE |
| 77.6 | RestoreConfirmationDialog (l10n, farm access block) | ✅ DONE |
| 77.7 | CloudBackupService refactor (_loadBackupData, prepareRestore, executeRestoreSession) | ✅ DONE |
| 77.8 | SourceAppMigrationHelper + Farm transfer | ✅ DONE |
| 77.9 | LGPD Delete multi-app (AppDeletionProvider, ownership) | ✅ DONE |
| 77.10 | LGPD Export (farms, crossAppReferences, owner-only) | ✅ DONE |
| 77.11 | Farm Limit (subscriptionTier, FarmLimitException) | ✅ DONE |

### App Integration

| App | Phase | Status |
|-----|-------|--------|
| RuraRubber | RUBBER-24 | ⏳ TODO |
| RuraRain | RAIN-03 | ⏳ TODO |

### Architecture Highlights

- **3-Layer Restore**: Farm (immutable) → Shared Structures (append-only) → Movements (replace by sourceApp + scope)
- **sourceApp field**: Immutable origin tracking on all FarmOwned entities, enabling surgical restore per app
- **DependencyManifest**: Hive-persisted manifest (typeId: 30) solves "blind spot" when dependent apps are not installed
- **Restore in 3 phases**: Analysis (read-only) → Confirmation (UI report) → Execution (transactional)
- **LGPD compliance**: Delete always executes (legal right prevails), but informs about cross-app dependencies kept
- **Ownership model**: Only Farm owner can perform full-scope restore or LGPD delete on farm data; non-owners can only manage personal data

### Files Created

| File | Description |
|------|-------------|
| `lib/models/backup_meta.dart` | Backup metadata (appId, farmId, scope, schema) |
| `lib/models/dependency_check_result.dart` | Cross-app dependency check result |
| `lib/models/dependency_manifest.dart` | Hive-persisted dependency manifest (typeId: 30) |
| `lib/models/dependency_manifest.g.dart` | Generated Hive adapter |
| `lib/models/restore_analysis.dart` | 3-phase restore analysis + RestoreFarmAccess |
| `lib/models/lgpd_deletion_result.dart` | LGPD deletion operation result |
| `lib/services/dependency_service.dart` | Cross-app dependency service (live + manifest) |
| `lib/widgets/restore_confirmation_dialog.dart` | Restore confirmation UI with farm access block |

### Files Modified

| File | Changes |
|------|---------|
| `lib/models/farm_owned_mixin.dart` | Added sourceApp (nullable), extension methods |
| `lib/models/farm.dart` | Added subscriptionTier (HiveField 8) |
| `lib/services/farm_service.dart` | Added canCreateFarm(), FarmLimitException |
| `lib/services/cloud_backup_service.dart` | Added EnhancedBackupProvider, RestoreSession, prepareRestore(), executeRestoreSession(), typed exceptions |
| `lib/services/data_deletion_service.dart` | Added AppDeletionProvider, deleteAppDataForFarm(), deletePersonalDataOnly() |
| `lib/services/data_export_service.dart` | Added farms, crossAppReferences, owner-only export |
| `lib/services/data_migration_service.dart` | Added Farm transfer, SourceAppMigrationHelper |
| `lib/agro_core.dart` | Added all new exports |
| `lib/l10n/arb/app_pt.arb` | Added 20+ restore/backup/farm l10n strings |
| `lib/l10n/arb/app_en.arb` | Added 20+ restore/backup/farm l10n strings |

### Cross-Reference
- CORE-75: Farm model, FarmOwnedMixin (base for sourceApp)
- CORE-76: Safra global (period totals)
- CORE-33: CloudBackupService (original implementation)
- CORE-36/37: DataDeletionService/DataExportService (updated for multi-app)

---

## Phase CORE-76: Safra Global + Ciclos de Cultura (Suporte RuraCrop)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implementar modelo de Safra como "Ano Agrícola" global e Ciclos para agricultura anual.

### Key Concepts

- **Safra**: Ano agrícola (Set-Ago), janela temporal global usada por todos os apps
- **Ciclo**: Instância de cultura em um talhão, apenas para RuraCrop (futuro)
- **Query-Based**: Totais são calculados via query, nunca armazenados

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 76.1 | Modelo Safra: HiveType(typeId: 21), 7 campos, shortLabel, containsDate(), toJson/fromJson, helpers | ✅ DONE |
| 76.2 | SafraService: Singleton CRUD, auto-criação por mês, ensureAtivaSafra(), backup helpers | ✅ DONE |
| 76.3 | SafraChip Widget: ActionChip "25/26" com ícone, abre SafraBottomSheet | ✅ DONE |
| 76.4 | Encerrar Safra: BottomSheet com confirmação, encerrarSafra() cria próxima automaticamente | ✅ DONE |
| 76.5 | Query Helpers: filterBySafra<T>(), sumBySafra<T>(), countBySafra<T>() genéricos | ✅ DONE |

### Files Created

| File | Description |
|------|-------------|
| `lib/models/safra.dart` | Modelo Safra @HiveType(typeId: 21) |
| `lib/models/safra.g.dart` | Generated Hive TypeAdapter |
| `lib/services/safra_service.dart` | SafraService singleton |
| `lib/widgets/safra_chip.dart` | SafraChip ActionChip widget |
| `lib/widgets/safra_bottom_sheet.dart` | Bottom sheet com safra ativa e anteriores |

### Files Modified

| File | Changes |
|------|---------|
| `lib/agro_core.dart` | Added 4 exports |
| `lib/l10n/arb/app_pt.arb` | 9 chaves adicionadas (safraGlobal, safraAtiva, etc.) |
| `lib/l10n/arb/app_en.arb` | 9 chaves adicionadas |

### Cross-Reference
- RUBBER-17: Usa Safra para controle de produção
- CROP-01: Ciclos vinculados à Safra (futuro)
- CASH-04: DRE por Safra (futuro)

---

## Phase CORE-75: Preparação Multi-User (Farm-Centric Model)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Preparar estrutura de dados para futuro modelo multi-user sem implementar UI de convites/permissões.

### Key Decisions

- **Farm-Centric**: Dados vinculados à farmId (não userId), preparando para múltiplos usuários por fazenda
- **UUID Independente**: farmId usa UUID separado do userId, permitindo múltiplas fazendas por usuário
- **Farm no Backup**: Entidade Farm incluída obrigatoriamente no backup/restore (dados ficam órfãos sem ela)
- **Firestore não impactado**: Farm armazenada localmente (Hive), backup manual inclui no JSON

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 75.1 | Modelo Farm: Hive adapter (typeId: 20), 7 campos | ✅ DONE |
| 75.2 | FarmService: CRUD + auto-criar no primeiro uso + getDefaultFarm() | ✅ DONE |
| 75.3 | Mixin FarmOwned: Campos farmId + createdBy para modelos | ✅ DONE |
| 75.4 | L10n Strings: Strings para Farm (PT-BR + EN) | ✅ DONE |
| 75.5 | Export: Atualizar agro_core.dart | ✅ DONE |

### Files Created

| File | Description |
|------|-------------|
| `lib/models/farm.dart` | Modelo Farm com Hive adapter (typeId: 20) |
| `lib/models/farm.g.dart` | Generated Hive adapter |
| `lib/services/farm_service.dart` | Gestão de fazendas |
| `lib/models/farm_owned_mixin.dart` | Mixin para entidades com farmId |

### Files Modified

| File | Changes |
|------|---------|
| `lib/l10n/arb/app_pt.arb` | Strings PT-BR |
| `lib/l10n/arb/app_en.arb` | Strings EN |
| `lib/agro_core.dart` | Exports |

### Scope Exclusions (Future Work)
- Tela de convite de membros
- Sistema de permissões (Owner, Manager, Worker)
- Sincronização entre dispositivos
- UI de "Trocar de Fazenda"

### Cross-Reference
- RUBBER-22: Onboarding cria Farm automaticamente
- CORE-77: Arquitetura de Backup dependency-aware

---

## Phase CORE-67: Profile Display in AgroDrawer

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟢 ENHANCEMENT
**Objective**: Display the user's selected profile type (Producer/Tapper/Buyer) in the drawer header.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 67.1 | Add optional `profileWidget` or `profileName` parameter to `AgroDrawer` | ✅ DONE |
| 67.2 | Display profile badge/chip below app name in drawer header | ✅ DONE |
| 67.3 | Update l10n strings | ⏫ SKIPPED (not needed - profile name comes from app) |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/menu/agro_drawer.dart` | MODIFY | Added `profileName` and `profileWidget` parameters |

### Cross-Reference
- RUBBER-12 (RuraRubber integration)

---

## Phase CORE-65: Weather Details Enhancements (Humidity & Daily View)

### Status: [DONE]
**Date Completed**: 2026-01-24
**Priority**: 🟢 ENHANCEMENT
**Objective**: Improve Weather Detail Screen with humidity info and specific daily detail views.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 65.1 | Create `WeatherDayDetailScreen` | ✅ DONE |
| 65.2 | Add Relative Humidity to `WeatherDetailScreen` header | ✅ DONE |
| 65.3 | Navigate to daily detail on tap | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/weather_detail_screen.dart` | MODIFY | Add humidity, clickable daily items |
| `lib/screens/weather_day_detail_screen.dart` | CREATE | New screen for day details |

---

## Phase CORE-64: Improve Precipitation Intensity Labels

### Status: [DONE]
**Date Completed**: 2026-01-24
**Priority**: 🟢 ENHANCEMENT
**Objective**: Add proper labels for precipitation intensity (drizzle, light, moderate, heavy) instead of just "Raining now".

### Precipitation Thresholds (per 15 minutes)
- < 0.1 mm = none
- 0.1 - 0.5 mm = drizzle (garoa)
- 0.5 - 2.0 mm = light rain
- 2.0 - 5.0 mm = moderate rain
- > 5.0 mm = heavy rain

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/instant_weather_forecast.dart` | MODIFY | Added PrecipIntensity enum, intensity getter, updated getStatusMessage |
| `lib/services/weather_service.dart` | MODIFY | Added precipitation to hourly API request |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Show hourly precipitation amounts |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added intensity l10n strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added intensity l10n strings |

---

## Phase CORE-63: Fix Restore Data (Replace vs Merge)

### Status: [DONE]
**Date Completed**: 2026-01-24
**Priority**: 🔵 FIX
**Objective**: Fix cloud restore to REPLACE data instead of MERGE, and add callback to refresh UI.

### Solution
- Modified BackupProvider implementations to clear existing data before importing
- Added `onRestoreComplete` callback to `AgroSettingsScreen`

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/property_service.dart` | MODIFY | Added `clearAllForUser()` method |
| `lib/services/property_backup_provider.dart` | MODIFY | Call clear before restore |
| `lib/screens/agro_settings_screen.dart` | MODIFY | Added `onRestoreComplete` callback |

---

## Phase CORE-62: Weather Map Improvements

### Status: [DONE]
**Date Completed**: 2026-01-23
**Priority**: 🔵 FIX
**Objective**: Fix red screen crash when selecting cloud layer and improve map UX.

### Changes
1. Fixed empty frames guard to prevent crash when satellite data is unavailable
2. Changed default map type from satellite to normal (road map)
3. Reorganized layer button order: Community → Radar → Cloud → Rain/Snow → Normal → Satellite
4. Added tooltips to all layer buttons

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/weather_map_screen.dart` | MODIFY | Add empty check, reorder buttons, change default map |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add radarNoData string |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add radarNoData string |

---

## Phase CORE-61: Fix Consent Initialization Bug

### Status: [DONE]
**Date Completed**: 2026-01-23
**Priority**: 🔵 FIX
**Objective**: Fix bug where "Accept All" button in ConsentScreen was not calling acceptAllConsents() due to pre-set cloudBackup value.

### Solution
Changed ConsentScreen's initState to use `isOnboardingCompleted()` as source of truth instead of `consentTimestamp`. The key insight: `consentTimestamp` can be set by implicit consents (like cloudBackup from login), but `onboardingCompleted` is only set when user actually finishes ConsentScreen.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/consent_screen.dart` | MODIFY | Use isOnboardingCompleted() as source of truth |

---

## Phase CORE-60: Fix Location Prompt Recursion Bug

### Status: [DONE]
**Date Completed**: 2026-01-23
**Priority**: 🔵 FIX
**Objective**: Fix broken location flow where "Are you here?" dialog was not showing due to recursion between LocationHelper and ConsentScreen.

### Solution
Added `skipLocationPrompt` parameter to ConsentScreen. When opened by LocationHelper, this flag prevents ConsentScreen from calling LocationHelper again, avoiding recursion.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/consent_screen.dart` | MODIFY | Add skipLocationPrompt parameter, add debug logs |
| `lib/utils/location_helper.dart` | MODIFY | Pass skipLocationPrompt, fix print statements |
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Add debug logs |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add debug log |

---

## Phase CORE-59: Notification Intensity & Weather UI Polish

### Status: [DONE]
**Date Completed**: 2026-01-22
**Priority**: 🟢 ENHANCEMENT
**Objective**: Improve rain alert clarity with explicit intensity levels, ensure clicking alerts opens the app, and add humidity data to weather cards.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 59.1 | Expose Notification Click Stream in `AgroNotificationService` | ✅ DONE |
| 59.2 | Update `BackgroundService` to use explicit intensity text | ✅ DONE |
| 59.3 | Add `relativeHumidity` to `WeatherForecast` model & Hive Adapter | ✅ DONE |
| 59.4 | Update `WeatherService` to fetch and parse humidity | ✅ DONE |
| 59.5 | Add Humidity Widget to `WeatherCard` | ✅ DONE |
| 59.6 | Handle Notification Click in App (Navigation) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/notification_service.dart` | MODIFY | Add click stream |
| `lib/services/background_service.dart` | MODIFY | Update alert text |
| `lib/models/weather_forecast.dart` | MODIFY | Add humidity field |
| `lib/services/weather_service.dart` | MODIFY | Fetch humidity |
| `lib/widgets/weather_card.dart` | MODIFY | Add humidity UI |

---

## Phase CORE-58: Map Bug Fixes (Camera & Tiles)

### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🔵 FIX
**Objective**: Fix critical usability regressions in the Weather Map (Camera resetting on play, Tiles not loading in new regions).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 58.1 | Fix Camera Reset: Track `onCameraMove` and preserve position | ✅ DONE |
| 58.2 | Fix Tile Caching: Add Region Hash to `TileOverlayId` | ✅ DONE |
| 58.3 | Logging: Add `debugPrint` for RadarTileProvider errors | ✅ DONE |
| 58.4 | Fix Tile Host: Use dynamic `host` from API response | ✅ DONE |
| 58.5 | Fix Nowcast URLs: Use `path` from API instead of timestamp | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/weather_map_screen.dart` | MODIFY | Camera tracking, region hash, pass host |
| `lib/services/radar_service.dart` | MODIFY | Dynamic host in getTileUrlTemplate |

---

## Phase CORE-57: Enhanced Rain Alerts (Precision & Metadata)

### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🔴 CRITICAL
**Objective**: Improve background rain alerts to provide exact start time, estimated duration, intensity, and total volume, avoiding false positives.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 57.1 | Update `WeatherService` to fetch `minutely_1` data | ✅ DONE |
| 57.2 | Implement `RainAlertAnalyzer` logic (Start/Duration/Volume) | ✅ DONE |
| 57.3 | Refactor `BackgroundService` for Rich Notifications | ✅ DONE |
| 57.4 | Add Intensity Classification Logic | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/weather_service.dart` | MODIFY | Add `minutely_1` support |
| `lib/services/background_service.dart` | MODIFY | Rich notification format |
| `lib/models/rain_alert_metadata.dart` | CREATE | Model for analysis results |

---

## Phase CORE-56: Real-Time Radar Integration (RainViewer)

### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟢 ENHANCEMENT
**Objective**: Integrate real-time weather radar (RainViewer) into the map to visualize actual precipitation and cloud movement (Past/Present/Future).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 56.1 | Create `RadarService` to fetch timestamps | ✅ DONE |
| 56.2 | Rename `RainHeatmapScreen` to `WeatherMapScreen` | ✅ DONE |
| 56.3 | Implement `TileOverlay` for Radar Layers | ✅ DONE |
| 56.4 | Implement Animation Player (Play/Pause, Loop) | ✅ DONE |
| 56.5 | Add Layer Switching (Heatmap vs Radar) | ✅ DONE |
| 56.6 | Add RainViewer Attribution | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/radar_service.dart` | CREATE | Fetch/parse RainViewer API |
| `lib/screens/weather_map_screen.dart` | CREATE | Renamed from rain_heatmap_screen |
| `lib/screens/rain_heatmap_screen.dart` | DELETE | Replaced by WeatherMapScreen |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add radar strings |

---

## Phase CORE-55: Autonomous AgroSettingsScreen

### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🔵 FIX
**Objective**: Make AgroSettingsScreen work without callbacks - all common features functional out-of-the-box.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 55.1 | Add default Sign-In with Google handler | ✅ DONE |
| 55.2 | Add default Privacy navigation | ✅ DONE |
| 55.3 | Add default About navigation | ✅ DONE |
| 55.4 | Add default Export data handler | ✅ DONE |
| 55.5 | Add default Delete cloud data handler | ✅ DONE |
| 55.6 | Add default Cloud sync toggle handler | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/agro_settings_screen.dart` | MODIFY | Added default implementations for all callbacks |

---

## Phase CORE-54: AdMob Banner Ads

### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟢 ENHANCEMENT
**Objective**: Monetization with non-intrusive banner ads, integrated with LGPD consent.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 54.1 | Add `google_mobile_ads` dependency | ✅ DONE |
| 54.2 | Create `AgroAdService` (SDK init, consent integration) | ✅ DONE |
| 54.3 | Create `AgroBannerWidget` (reusable widget) | ✅ DONE |
| 54.4 | Export in agro_core.dart | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Added google_mobile_ads: ^5.3.0 |
| `lib/services/agro_ad_service.dart` | CREATE | AdMob service with consent check |
| `lib/widgets/agro_banner_widget.dart` | CREATE | Reusable banner widget |
| `lib/agro_core.dart` | MODIFY | Export new files |

---

## Phase CORE-53: Comparative Charts (Safra x Safra)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Enable year-over-year rainfall comparison to support seasonal analysis and decision making.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/comparacao_anual_chart.dart` | CREATE | Bar chart widget using fl_chart |
| `lib/services/comparative_stats_helper.dart` | CREATE | Logic to aggregate monthly data |
| `lib/screens/estatisticas_screen.dart` | MODIFY | Added Comparison tab |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added chart strings |

---

## Phase CORE-52: Social Sharing (Rain Card)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Boost user engagement by enabling sharing of rainfall data on social networks via screenshot capture.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/rain_card_widget.dart` | CREATE | Invisible widget for image generation |
| `lib/services/share_service.dart` | CREATE | Captures widget and shares via share_plus |
| `lib/widgets/registro_chuva_tile.dart` | MODIFY | Added share icon |
| `lib/screens/editar_chuva_screen.dart` | MODIFY | Added share action in AppBar |

---

## Phase CORE-51: Native Home Widgets

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Provide quick access to critical information directly from the Android Home Screen.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/app/src/main/res/layout/widget_layout.xml` | CREATE | Native XML layout |
| `android/app/src/main/java/.../RainWidgetProvider.kt` | CREATE | Kotlin Widget Provider |
| `packages/agro_core/lib/services/home_widget_service.dart` | CREATE | Dart service for data sync |
| `lib/services/chuva_service.dart` | MODIFY | Auto-update widget on data changes |

---

## Phase CORE-46: Rain Alerts Notification (Background)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Notify users about incoming rain (minutely forecast) even when the app is closed.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 46.1 | Add `workmanager` & `flutter_local_notifications` | ✅ DONE |
| 46.2 | Implement `AgroNotificationService` (Local Notifications) | ✅ DONE |
| 46.3 | Implement `BackgroundService` (WorkManager Task) | ✅ DONE |
| 46.4 | Integrate "Rain Alerts" toggle in Settings | ✅ DONE |
| 46.5 | Add permissions (POST_NOTIFICATIONS, WAKE_LOCK) in consuming apps | ✅ DONE |
| 46.6 | Logic: Check rain every 15 min & Debounce alerts | ✅ DONE |
| 46.7 | Fix null safety: skip properties without location | ✅ DONE |
| 46.8 | Request Notification Permission in `ConsentScreen` (Onboarding) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/notification_service.dart` | CREATE | AgroNotificationService |
| `lib/services/background_service.dart` | CREATE | Background logic (Hive/Weather check) |
| `lib/screens/agro_settings_screen.dart` | MODIFY | Add Rain Alerts toggle |
| `lib/privacy/consent_screen.dart` | MODIFY | Request permissions after consent |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add Alert strings |
| `pubspec.yaml` | MODIFY | Add workmanager dependency |

---

## Phase CORE-45: Property Location UX Polish

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 UX POLISH
**Objective**: Improve the location setup flow for properties, ensuring seamless integration with onboarding and intuitive editing.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/utils/location_helper.dart` | CREATE | Centralized location logic |
| `lib/widgets/weather_card.dart` | MODIFY | Use LocationHelper, remove dup logic |
| `lib/privacy/consent_screen.dart` | MODIFY | Trigger location check after consent |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Clickable AppBar property name |

---

## Phase CORE-44: Collaborative Rain Heatmap

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Display a visual heatmap of community-reported rain intensity on a Google Map.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/heatmap_service.dart` | CREATE | Community rain data service |
| `lib/screens/rain_heatmap_screen.dart` | CREATE | Map with Circle overlays |
| `lib/menu/agro_drawer_item.dart` | MODIFY | Add heatmap route key |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add Heatmap strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add Heatmap strings |

---

## Phase CORE-43: Advanced Weather - Nowcasting

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Provide immediate "minutely" rain forecasts (Nowcasting) for the next hour via Open-Meteo minutely_15 API.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/instant_weather_forecast.dart` | CREATE | Model for minutely data |
| `lib/services/weather_service.dart` | MODIFY | Fetch & parse minutely_15 |
| `lib/widgets/weather_card.dart` | MODIFY | Display MinutelyForecastWidget |
| `lib/widgets/minutely_forecast_widget.dart` | CREATE | Visual chart/summary for rain |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add nowcasting strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add nowcasting strings |

---

## Phase CORE-42: Google Maps Integration

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Replace OpenStreetMap with Google Maps for a premium, hybrid satellite view experience.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Switch map dependencies |
| `lib/screens/location_picker_screen.dart` | MODIFY | Full rewrite for Google Maps |
| `lib/widgets/weather_card.dart` | MODIFY | Update nav flow and imports |
| `android/app/src/main/AndroidManifest.xml` | MODIFY | Add API Key metadata placeholder |

---

## Phase CORE-41: Cloud Backup UX Improvements

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔵 FIX
**Objective**: Improve Cloud Backup UX - show login prompt when not authenticated, internationalize all strings, separate cloud and local backup.

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

## Phase CORE-39: Weather Alerts & Critical Conditions

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL
**Objective**: Proactively notify users of critical weather conditions (Frost, Drought, Heat Wave, Storms) based on forecast analysis.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/weather_alert.dart` | CREATE | Model definition for alerts |
| `lib/services/weather_service.dart` | MODIFY | Logic to generate alerts from forecast |
| `lib/widgets/weather_card.dart` | MODIFY | Alert badge/banner |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Detailed alert list |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Alert strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Alert strings |

---

## Phase CORE-38: Weather Enhancements (Wind & UI)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Add wind speed/direction to weather forecast and improve UI to indicate property-specific data.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/weather_forecast.dart` | MODIFY | Added wind fields & helper |
| `lib/services/weather_service.dart` | MODIFY | Fetch wind metrics from Open-Meteo |
| `lib/widgets/weather_card.dart` | MODIFY | Wind info & Property name label |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Wind info in all sections |

---

## Phase CORE-37: LGPD Data Portability (Right to Data Portability)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 IMPORTANT (LGPD Art. 18, V)
**Objective**: Allow users to export their data in a standard, machine-readable format (JSON/CSV).

### Difference from Backup

| Feature | Backup | Portability |
|---------|--------|-------------|
| Format | Internal (Hive/JSON) | Standard JSON/CSV |
| Readability | App-only | Human & machine readable |
| Purpose | Restore data | Transfer to another service |
| LGPD | Optional | **Mandatory (Art. 18, V)** |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_export_service.dart` | CREATE | exportToJson, exportToCsv, shareExport |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 7 export strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | 7 export strings |
| `lib/agro_core.dart` | MODIFY | Export data_export_service.dart |

---

## Phase CORE-36: LGPD Data Deletion (Right to Erasure)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL (LGPD Art. 18, VI)
**Objective**: Implement complete user data deletion to comply with LGPD "right to erasure" requirement.

### Data Deleted
- **Firestore**: User document and all subcollections
- **Firebase Auth**: User account
- **Hive (Local)**: All user-related boxes

### What is NOT Deleted
- Anonymized/aggregated data (LGPD Art. 12)
- Regional metrics (non-identifiable)

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_deletion_service.dart` | CREATE | Orchestrates Firestore, Auth, and Hive deletion |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 9 deletion strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | 9 deletion strings |
| `lib/agro_core.dart` | MODIFY | Export data_deletion_service.dart |

---

## Phase CORE-35: Privacy & Consent Updates (Advanced)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Enhance privacy management with granular consent controls, "Revoke All" button, and reactive UI.

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
| 34.5 | Show Property Name only if user has > 1 property | ✅ DONE |
| 34.6 | Show Talhão Name only if > 1 talhão exists | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_migration_service.dart` | MODIFY | Added transferAllData() with progress callbacks |
| `lib/services/talhao_service.dart` | MODIFY | Added transferData() method |
| `lib/widgets/weather_card.dart` | MODIFY | Property label only if > 1 property |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 10 migration strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 10 migration strings |

---

## Phase CORE-33: Cloud Backup Integration

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 MEDIUM
**Objective**: Unified cloud backup system for all apps provided by agro_core.

### Implementation Summary
- **Service**: `CloudBackupService` manages Firebase Storage uploads/downloads
- **Provider**: `BackupProvider` interface for app-specific data serialization
- **UI**: Backup controls in `AgroSettingsScreen`

---

## Phase CORE-16.1: UX Simplification - Consent Flow

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔵 FIX
**Objective**: Simplify consent and location permission flow for better UX and LGPD compliance.

### Changes
- Removed intermediate dialog in WeatherCard (goes directly to ConsentScreen)
- Simplified consent screen layout (title + short intro, no checkbox descriptions)
- Moved detailed explanations to Privacy Policy Section 7

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/weather_card.dart` | MODIFY | Removed "Permissão Necessária" dialog |
| `lib/privacy/consent_screen.dart` | MODIFY | Simplified layout with short intro text |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Synchronized with ConsentScreen |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Simplified consent texts |
| `lib/l10n/arb/app_en.arb` | MODIFY | Simplified consent texts |
| `lib/screens/privacy_policy_screen.dart` | MODIFY | Added Section 7 with detailed consent explanations |

---

## Phase CORE-16.0: Property Management Foundation

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implement multi-property support with cross-app sharing via userId.

### Key Features
- **Property Model**: Hive typeId 10, userId-based, with name, area, location, isDefault
- **Cross-App Sharing**: Properties stored in agro_core, filtered by userId
- **Auto-Creation**: Default property created automatically (zero friction onboarding)
- **Migration**: MigrationService links existing records to default property

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/property.dart` | CREATE | Property model (Hive typeId: 10) |
| `lib/models/property.g.dart` | GENERATE | Hive adapter |
| `lib/services/property_service.dart` | CREATE | Property CRUD service |
| `lib/screens/property_list_screen.dart` | CREATE | Property list/management screen |
| `lib/screens/property_form_screen.dart` | CREATE | Add/edit property form |
| `lib/services/property_helper.dart` | CREATE | PropertyHelper singleton with name caching |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 35 property strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 35 property strings |
| `lib/menu/agro_drawer.dart` | MODIFY | Added Properties menu item |
| `lib/agro_core.dart` | MODIFY | Added exports |

---

## Phase CORE-15.7: Identity-First Onboarding (Porta de Entrada)

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Replace Terms screen with Identity screen (Google Login or Anonymous) to capture emails early and reduce onboarding friction.

### New Onboarding Flow
Splash → IdentityScreen (Google/Guest) → ConsentScreen (3 checkboxes) → Home

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Added google_sign_in: ^6.2.2 |
| `lib/services/auth_service.dart` | CREATE | Firebase Auth service (Google + Anonymous + Account Linking) |
| `lib/privacy/identity_screen.dart` | CREATE | New identity screen with Google and Guest buttons |
| `lib/privacy/onboarding_gate.dart` | MODIFY | Replaced TermsPrivacyScreen with IdentityScreen |
| `lib/privacy/terms_privacy_screen.dart` | DELETE | Removed (replaced by IdentityScreen) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added 14 identity-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added 14 identity-related strings |
| `lib/agro_core.dart` | MODIFY | Updated exports |

---

## Phase CORE-15.6: Commercial Consent Language (Legal & Commercial Alignment)

### Status: [DONE]
**Date Completed**: 2026-01-18
**Priority**: 🟢 ENHANCEMENT
**Objective**: Update consent language to support commercial use cases (data commercialization, partnerships, ad networks) while maintaining LGPD compliance.

### Consent Changes
- **Checkbox 1** "Uso de Dados e Inteligência de Mercado": Authorizes data commercialization, sale, licensing (individual + aggregated)
- **Checkbox 2** "Receber Ofertas e Oportunidades": Authorizes direct communication from partners (app, email, SMS, WhatsApp)
- **Checkbox 3** "Publicidade Personalizada": Authorizes third-party ad networks (Google Ads, Meta), behavioral profiling

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/l10n/arb/app_pt.arb` | MODIFY | Updated 3 consent texts + added 3 "Learn More" texts |
| `lib/l10n/arb/app_en.arb` | MODIFY | Updated 3 consent texts + added 3 "Learn More" texts |
| `lib/privacy/agro_privacy_keys.dart` | MODIFY | Updated documentation comments |

---

## Phase CORE-02.0: Standard Menu and Base Screens

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Create reusable drawer menu (AgroDrawer) and base screens (Settings, About, Privacy) with l10n support.

### Components
- **AgroDrawer**: Reusable drawer with header, standard items (Home, Settings, Privacy, About), supports extra app-specific items
- **AgroSettingsScreen**: Language, About navigation
- **AgroAboutScreen**: App info, version, offline-first badge
- **AgroPrivacyScreen**: Terms summary, consent toggles (persisted in Hive)

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/menu/agro_drawer.dart` | CREATE | Reusable drawer widget |
| `lib/menu/agro_drawer_item.dart` | CREATE | Drawer item model and route keys |
| `lib/screens/agro_settings_screen.dart` | CREATE | Settings screen |
| `lib/screens/agro_about_screen.dart` | CREATE | About screen |
| `lib/screens/agro_privacy_screen.dart` | CREATE | Privacy and consents management screen |
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Added getBox() and setConsent() methods |
| `lib/agro_core.dart` | MODIFY | Export new menu and screens |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Added drawer, settings, about, privacy l10n keys |
| `lib/l10n/arb/app_en.arb` | MODIFY | Added drawer, settings, about, privacy l10n keys |

---

## Phase CORE-01.0: Privacy Onboarding Flow

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Create reusable privacy onboarding screens with l10n support (pt-BR + en) for all apps.

### Screens
- **Screen 1 - Terms & Privacy (Mandatory)**: Accept to enter, Decline exits app
- **Screen 2 - Consents (Optional)**: 3 toggles (all OFF by default), accept or decline both enter the app

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Added hive, hive_flutter, flutter_localizations |
| `l10n.yaml` | CREATE | l10n configuration file |
| `lib/l10n/arb/app_pt.arb` | CREATE | Portuguese translations |
| `lib/l10n/arb/app_en.arb` | CREATE | English translations |
| `lib/privacy/agro_privacy_keys.dart` | CREATE | Centralized Hive box keys |
| `lib/privacy/agro_privacy_store.dart` | CREATE | Static privacy store with Hive persistence |
| `lib/privacy/terms_privacy_screen.dart` | CREATE | Terms of Use + Privacy Policy screen |
| `lib/privacy/consent_screen.dart` | CREATE | Optional consents screen |
| `lib/privacy/onboarding_gate.dart` | CREATE | Gate widget that controls onboarding flow |
| `lib/agro_core.dart` | MODIFY | Export new privacy and l10n modules |
