# PLANEJASAFRA — RULES (Flutter Monorepo)

## 1) Before touching anything (mandatory)

* Read `README.md` (root) to understand structure and rules.
* Confirm target app in `apps\<app>\` and core in `packages\agro_core\`.
* `examples\planejacampo` is **reference only** (copy files, never import). Do not modify anything here.

## 2) Monorepo structure (fixed)

PlanejaSafra\

* apps\

  * planeja_chuva\
  * planeja_diesel\
  * planeja_borracha\
  * planeja_vaca\
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

## 5) Privacy and Consent (mandatory in every app)

* Screen 1: Terms + Policy (if declined, cannot enter)
* Screen 2: Optional consents (accept or decline both enter the app)
* Implement once in `agro_core` and plug in all apps via `main.dart`

## 6) l10n mandatory (pt-BR + en)

* No hardcoded text in screens
* Strings via l10n: pt_BR + en

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

Each project (`packages/agro_core` and each app in `apps/*`) must have a `CHANGELOG.md` following this pattern:

### Phase Structure

```markdown
## Phase X.Y: Phase Name

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
* **No empty phases**: Only create phase when starting work
* **Granularity**: Sub-phases (X.Y.1, X.Y.2) for large tasks
* **Files modified**: Always list with action (CREATE/MODIFY/DELETE)
