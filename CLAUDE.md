# RURACAMP — RULES (Flutter Monorepo)

## 1) Before touching anything (mandatory)

* Read `README.md` (root) to understand structure and rules.
* Confirm target app in `apps\<app>\` and core in `packages\agro_core\`.
* `examples\planejacampo` is **reference only** (copy files, never import). Do not modify anything here.

## 2) Monorepo structure (fixed)

RuraCamp\

* apps\

* apps\

  * rurarain\      (formerly planejachuva) - com.ruracamp.rain
  * rurarubber\    (formerly planejaaborracha) - com.ruracamp.rubber
  * ruracattle\    (formerly planejavavaca) - com.ruracamp.cattle
  * rurafuel\      (formerly planejadiesel) - com.ruracamp.fuel
* packages\

  * agro_core\
* examples\

  * planejacampo\  (legacy, reference only)

## 3) Where things go

* Everything reusable goes in core: `packages\agro_core\lib\`

  * theme, widgets, utils, l10n, privacy/consent screens
* Each app has only its own stuff: `apps\<app>\lib\`

  * models, screens, specific logic

## 4) Database and default mode

* Default: Hive (offline-first)
* No login, sync, Firebase, multi-user, mandatory online (only if you request)
* **Never use subcollections** (always use root collections/boxes or flat structures).

## 5) Privacy and Consent (mandatory in every app)

* Screen 1: Terms + Policy (if declined, cannot enter)
* Screen 2: Optional consents (accept or decline both enter the app)
* Implement once in `agro_core` and plug in all apps via `main.dart`

## 6) l10n mandatory (pt-BR + en)

* **ZERO hardcoded strings** in any Dart file (screens, widgets, services, dialogs, snackbars, etc.)
* ALL user-visible text MUST use l10n: `AgroLocalizations.of(context)!.stringKey`
* Strings go in ARB files: `packages/agro_core/lib/l10n/arb/app_pt.arb` and `app_en.arb`
* After adding/modifying ARB files, run: `flutter gen-l10n` in agro_core
* Examples of what MUST be localized:
  * Dialog titles and messages
  * Button labels
  * Snackbar messages
  * Error messages
  * Placeholder/hint texts
  * Weather descriptions
  * Any text the user sees

## 7) Hive always with build_runner

* When creating/modifying Hive model, generate adapters with build_runner
* Standard command: dart run build_runner build --delete-conflicting-outputs

## 8) Code rules

* No "...", no omitting code in requested files
* Null-safety and input validation (especially numbers and dates)
* Small change: show only line/method; large change: complete file

## 9) Language

* Code and names: English
* Explanation to user: PT-BR (with technical terms in English when needed)

## 10) CHANGELOG.md (mandatory in each project)

Each project (`packages/agro_core` and each app in `apps/*`) must have its own `CHANGELOG.md`.

### Monorepo CHANGELOG Structure

```
RuraCamp/
├── packages/
│   └── agro_core/
│       └── CHANGELOG.md    ← Core changes (services, widgets, privacy, l10n)
│
└── apps/
    ├── rurarain/
    │   └── CHANGELOG.md    ← App-specific changes (rainfall screens, reports)
    │
    ├── rurarubber/
    │   └── CHANGELOG.md    ← App-specific changes (rubber weighing, market)
    │
    ├── ruracattle/
    │   └── CHANGELOG.md    ← App-specific changes (cattle management)
    │
    ├── rurafuel/
    │   └── CHANGELOG.md    ← App-specific changes (fuel consumption)
    │
    └── ...
```

### What Goes Where

| CHANGELOG | Content |
|-----------|---------|
| `agro_core` | Services, widgets, privacy screens, l10n strings, shared models, core infrastructure |
| `apps/<app>` | App-specific screens, logic, providers, main.dart integrations |

### Phase Naming Convention

Each project uses a **prefix** to identify phases:

| Project | Prefix | Example |
|---------|--------|---------|
| `agro_core` | `CORE-` | `CORE-33`, `CORE-70` |
| `rurarain` | `RAIN-` | `RAIN-01` |
| `rurarubber` | `RUBBER-` | `RUBBER-01` |
| `ruracattle` | `CATTLE-` | `CATTLE-01` |
| `rurafuel` | `FUEL-` | `FUEL-01` |

### Cross-Reference Example

When a feature spans both core and app:

**Phase CORE-70 (Internationalization Rebranding)**:
- `agro_core/CHANGELOG.md`: Umbrella phase documenting the PlanejaCampo → RuraCamp migration
- `rurarain/CHANGELOG.md`: RAIN-01 - App-specific migration implementation

### Phase Structure

```markdown
## Phase PREFIX-X.Y: Phase Name

### Status: [TODO] | [DOING] | [DONE]
**Date Completed**: YYYY-MM-DD (when DONE)
**Priority**: 🔴 CRITICAL | 🟡 ARCHITECTURAL | 🟢 ENHANCEMENT | 🔵 FIX
**Objective**: Brief description of objective.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| X.Y.1 | Description | ✅ DONE / 🔄 DOING / ⏳ TODO |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `path/to/file.dart` | CREATE/MODIFY/DELETE | Description |
```

### Rules

* **Descending order**: Most recent phases (higher numbers) go at the TOP of the file
* **Mandatory status**: TODO → DOING → DONE
* **Mandatory status**: TODO → DOING → DONE
* **Create Phase FIRST**: You MUST create the phase in `CHANGELOG.md` **before** writing any code.
* **NO CODE in Changelog**: Never paste code snippets in `CHANGELOG.md`. Use descriptions only.
* **No empty phases**: Only create phase when starting work
* **Granularity**: Sub-phases (X.Y.1, X.Y.2) for large tasks
* **Files modified**: Always list with action (CREATE/MODIFY/DELETE)
* **Cross-reference**: When a phase affects multiple projects, document in both CHANGELOGs with cross-reference

## 11) Build & Configuration Rules (Mandatory)

* **minSdk**: Must be set to **23** or higher (required by `flutter_local_notifications` and modern AGP).
* **Kotlin**: Use version **2.0.0** or higher in `android/settings.gradle`.
* **Desugaring**: 
  * Must enable `coreLibraryDesugaringEnabled true` in `android/app/build.gradle`.
  * Must add `com.android.tools:desugar_jdk_libs` dependency (version 2.1.5+).
* **Gradle**: Use compatible AGP (8.6.0+) and Gradle Wrapper (8.10.2+).

## 12) AgroSettingsScreen — Features & Activation

The `AgroSettingsScreen` in `agro_core` provides common settings functionality. Some features work automatically, others require callbacks to activate.

### Features That Work Automatically (No Callbacks Needed)

| Feature | Description |
|---------|-------------|
| Idioma (Language) | Switch between pt-BR and English |
| Tema (Theme) | Light, Dark, or System |
| Sign-in com Google | Uses `AuthService.signInWithGoogle()` |
| Backup Nuvem | Uses `CloudBackupService` |
| Restaurar Nuvem | Uses `CloudBackupService` |
| Sincronizar Preferências | Uses `UserCloudService` |
| Exportar Dados (LGPD) | Uses `DataExportService` |
| Deletar Dados Nuvem | Uses `UserCloudService` |
| Privacidade | Navigates to `AgroPrivacyScreen` |
| Sobre | Navigates to `AgroAboutScreen` |

### Features That Require Callbacks (App-Specific)

| Feature | Callback(s) Required | Description |
|---------|---------------------|-------------|
| Backup Local (Export) | `onExportLocalBackup` | App-specific JSON export |
| Backup Local (Import) | `onImportLocalBackup` | App-specific JSON import |
| Lembretes Diários | `onReminderChanged` | Daily notification reminders |
| Alertas de Chuva | `onToggleRainAlerts` | Weather-based alerts (rurarain) |

### Usage Examples

**Minimal (all automatic features):**
```dart
'/settings': (context) => const AgroSettingsScreen(),
```

**With app-specific features:**
```dart
AgroSettingsScreen(
  onReminderChanged: (enabled, time) async { /* ... */ },
  reminderEnabled: _reminderEnabled,
  reminderTime: _reminderTime,
  onExportLocalBackup: () async { /* ... */ },
  onImportLocalBackup: () async { /* ... */ },
)
```

### AdMob Integration

To enable AdMob ads in an app:

1. Add to `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXX~YYYYY" />
```

2. Initialize in `main.dart`:
```dart
await AgroAdService.instance.initialize();
```

3. Add to screen:
```dart
bottomNavigationBar: const AgroBannerWidget(),
```

