# CHANGELOG - agro_core

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

### Export Format Example

```json
{
  "exportedAt": "2026-01-20T15:30:00Z",
  "appVersion": "1.0.0",
  "user": {
    "id": "abc123",
    "email": "user@example.com"
  },
  "data": {
    "properties": [
      {
        "name": "Fazenda Primavera",
        "area_ha": 150.5,
        "latitude": -23.5505,
        "longitude": -46.6333
      }
    ],
    "rainfall_records": [
      {
        "date": "2026-01-15",
        "mm": 25.5,
        "note": "Chuva forte à tarde",
        "property": "Fazenda Primavera",
        "field_plot": "Talhão A"
      }
    ],
    "field_plots": [
      {
        "name": "Talhão A",
        "area_ha": 50.0,
        "crop": "Soja",
        "property": "Fazenda Primavera"
      }
    ]
  },
  "consents": {
    "data_location": true,
    "offers_promotions": false,
    "personalized_ads": false,
    "last_updated": "2026-01-10T10:00:00Z"
  }
}
```

### Proposed Service

```dart
// lib/services/data_export_service.dart
class DataExportService {
  static Future<String> exportToJson() async {
    final user = FirebaseAuth.instance.currentUser;

    final export = {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'user': {
        'id': user?.uid,
        'email': user?.email,
      },
      'data': {
        'properties': await _exportProperties(),
        'rainfall_records': await _exportRainfall(),
        'field_plots': await _exportTalhoes(),
      },
      'consents': _exportConsents(),
    };

    return JsonEncoder.withIndent('  ').convert(export);
  }

  static Future<String> exportToCsv() async {
    // Generate CSV with headers for spreadsheet import
    final records = await _getAllRainfallRecords();
    final csv = StringBuffer();
    csv.writeln('Data,MM,Observação,Propriedade,Talhão');
    for (final r in records) {
      csv.writeln('${r.date},${r.mm},"${r.note}","${r.property}","${r.talhao}"');
    }
    return csv.toString();
  }

  static Future<void> shareExport(BuildContext context, {bool asCsv = false}) async {
    final content = asCsv ? await exportToCsv() : await exportToJson();
    final filename = asCsv ? 'meus_dados.csv' : 'meus_dados.json';

    // Save to temp file and share
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path)]);
  }
}
```

### UI Flow

```
AgroPrivacyScreen
    │
    ├─ [Exportar meus dados] button
    │
    └─ Bottom Sheet
        ├─ Title: "Exportar dados"
        ├─ Description: "Escolha o formato..."
        │
        ├─ [📄 JSON] → Share Sheet
        └─ [📊 CSV (Excel)] → Share Sheet
```

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_export_service.dart` | CREATE | Service para exportar dados |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add export button and bottom sheet |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add export-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add export-related strings |
| `pubspec.yaml` | MODIFY | Add share_plus dependency (if not present) |

### L10n Strings Needed

```json
"exportDataButton": "Exportar meus dados",
"exportDataTitle": "Exportar dados",
"exportDataDescription": "Baixe uma cópia dos seus dados em formato padrão para usar em outros serviços.",
"exportDataJson": "JSON (completo)",
"exportDataCsv": "CSV (Excel/Planilhas)",
"exportDataSuccess": "Dados exportados com sucesso!",
"exportDataError": "Erro ao exportar dados."
```

### Dependencies

```yaml
dependencies:
  share_plus: ^7.0.0  # For native share sheet
  path_provider: ^2.0.0  # For temp file storage
```

---

## Phase CORE-36: LGPD Data Deletion (Right to Erasure)

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL (LGPD Art. 18, VI)
**Objective**: Implement complete user data deletion to comply with LGPD "right to erasure" requirement.

### LGPD Requirement

> **Art. 18, VI** - O titular dos dados pessoais tem direito a obter do controlador:
> "eliminação dos dados pessoais tratados com o consentimento do titular"

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

| Location | Data | Method |
|----------|------|--------|
| **Firestore** | `users/{uid}/*` | `doc.delete()` recursivo |
| **Firestore** | `users/{uid}/consents` | Subcollection delete |
| **Firestore** | `users/{uid}/properties` | Subcollection delete |
| **Firebase Auth** | Conta do usuário | `currentUser.delete()` |
| **Hive (local)** | `agro_settings` box | `box.clear()` |
| **Hive (local)** | `chuvas` box | `box.clear()` |
| **Hive (local)** | `properties` box | `box.clear()` |
| **Hive (local)** | `talhoes` box | `box.clear()` |
| **Hive (local)** | `weather_cache` box | `box.clear()` |

### What is NOT Deleted

| Data | Reason |
|------|--------|
| Dados agregados/estatísticos | LGPD Art. 12 - Dados anonimizados não são dados pessoais |
| Métricas regionais | Não identificam o usuário individual |
| Logs de servidor (se houver) | Retenção mínima para segurança (30 dias) |

### Proposed Service

```dart
// lib/services/data_deletion_service.dart
class DataDeletionService {
  static Future<void> deleteAllUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 1. Delete Firestore data (with subcollections)
    await _deleteFirestoreUserData(uid);

    // 2. Delete Firebase Auth account
    await user.delete();

    // 3. Clear all local Hive boxes
    await _clearAllLocalData();

    // 4. Reset privacy store
    await AgroPrivacyStore.resetAll();
  }

  static Future<void> _deleteFirestoreUserData(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    // Delete subcollections first
    await _deleteCollection(userDoc.collection('consents'));
    await _deleteCollection(userDoc.collection('properties'));
    // Add other subcollections as needed

    // Delete main document
    await userDoc.delete();
  }

  static Future<void> _clearAllLocalData() async {
    final boxes = ['agro_settings', 'chuvas', 'properties', 'talhoes', 'weather_cache'];
    for (final boxName in boxes) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }
}
```

### UI Flow

```
AgroPrivacyScreen
    │
    ├─ [Excluir meus dados] button (red, bottom)
    │
    └─ Confirmation Dialog
        ├─ Title: "Excluir todos os dados?"
        ├─ Warning: "Esta ação é irreversível..."
        ├─ Checkbox: "Entendo que perderei todos os meus registros"
        │
        ├─ [Cancelar]
        └─ [Excluir Permanentemente] (enabled only if checkbox checked)
            │
            └─ Loading → Success → Restart to IdentityScreen
```

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/data_deletion_service.dart` | CREATE | Service para deletar dados |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add deletion button and dialog |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add deletion-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add deletion-related strings |

### L10n Strings Needed

```json
"deleteDataButton": "Excluir meus dados",
"deleteDataTitle": "Excluir todos os dados?",
"deleteDataWarning": "Esta ação é IRREVERSÍVEL. Todos os seus registros de chuva, propriedades e configurações serão permanentemente excluídos do seu dispositivo e dos nossos servidores.",
"deleteDataConfirmCheckbox": "Entendo que perderei todos os meus registros",
"deleteDataCancel": "Cancelar",
"deleteDataConfirm": "Excluir Permanentemente",
"deleteDataSuccess": "Seus dados foram excluídos com sucesso.",
"deleteDataError": "Erro ao excluir dados. Tente novamente."
```

---

## Phase CORE-35: Privacy & Consent Updates (Advanced)

### Status: [PARTIAL]
**Date Updated**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Enhance privacy management with granular consent controls and real-time reactive UI.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 35.1 | Add granular getters (canCollectAnalytics, canUseLocation) to AgroPrivacyStore | ✅ DONE |
| 35.2 | Add "Revogar Tudo e Sair" button to AgroPrivacyScreen | ⏳ TODO |
| 35.3 | Make WeatherCard listen to consent changes reactively | ⏳ TODO |
| 35.4 | Verify LGPD compliance with simplified consent flow | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Added canCollectAnalytics, canUseLocation, canShowPersonalizedAds, canShareWithPartners |

### Current State Analysis

**What EXISTS:**
- `AgroPrivacyStore` has: `consentAggregateMetrics`, `consentSharePartners`, `consentAdsPersonalization`
- `AgroPrivacyStore.resetAll()` method exists but is not exposed in UI
- `AgroPrivacyScreen` has interactive switches for 3 consents
- `WeatherCard` checks consent on tap but doesn't listen to changes

**What's MISSING:**
- Granular getters for Analytics/Crashlytics/Location (currently bundled in aggregateMetrics)
- "Revogar Tudo" button in privacy screen (wipe data + restart)
- WeatherCard reactive listener (should show placeholder when consent revoked)

### Files to Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Add granular consent getters |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add "Revogar Tudo e Sair" button |
| `lib/widgets/weather_card.dart` | MODIFY | Add consent change listener |

---

## Phase CORE-34: Data Migration & UI Polish

### Status: [PLANNED]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Allow seamless migration from anonymous to authenticated accounts, preserving all user data.

### Problem Statement

When a user starts with anonymous auth and later signs in with Google:
1. Firebase creates a NEW uid for the Google account
2. All data linked to the old anonymous uid becomes orphaned
3. User loses their rainfall records, properties, settings

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 34.1 | Implement `linkWithCredential` for anonymous → Google | ⏳ TODO |
| 34.2 | Handle `credential-already-in-use` error (merge conflict) | ⏳ TODO |
| 34.3 | Create `MigrationService.transferData(oldUid, newUid)` | ⏳ TODO |
| 34.4 | Add migration UI flow with progress indicator | ⏳ TODO |
| 34.5 | UI: Show Property Name only if user has > 1 property | ⏳ TODO |
| 34.6 | UI: Show Talhão Name only if > 1 talhão exists | ⏳ TODO |

### Migration Scenarios

| Scenario | Action |
|----------|--------|
| Anonymous → Google (new account) | `linkWithCredential()` - keeps same uid |
| Anonymous → Google (existing account) | Merge conflict - transfer data then delete anonymous |
| Google → Google (re-login) | Normal sign-in, no migration needed |

### Proposed Service

```dart
// lib/services/migration_service.dart
class MigrationService {
  /// Attempt to link anonymous account with Google credential
  static Future<MigrationResult> migrateToGoogle(AuthCredential credential) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      return MigrationResult.notAnonymous;
    }

    final oldUid = currentUser.uid;

    try {
      // Try to link - this preserves the same uid
      await currentUser.linkWithCredential(credential);
      return MigrationResult.linked;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Google account already exists - need to merge data
        return await _handleMergeConflict(oldUid, credential);
      }
      rethrow;
    }
  }

  static Future<MigrationResult> _handleMergeConflict(
    String oldUid,
    AuthCredential credential,
  ) async {
    // 1. Sign in with the existing Google account
    final newCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final newUid = newCredential.user!.uid;

    // 2. Transfer data from old anonymous account to new Google account
    await transferData(oldUid, newUid);

    // 3. Delete orphaned anonymous data (optional, can keep for audit)
    // await _deleteAnonymousData(oldUid);

    return MigrationResult.merged;
  }

  /// Transfer all user data from one uid to another
  static Future<void> transferData(String fromUid, String toUid) async {
    final firestore = FirebaseFirestore.instance;

    // Transfer properties
    await _transferCollection(
      firestore.collection('users/$fromUid/properties'),
      firestore.collection('users/$toUid/properties'),
    );

    // Transfer rainfall records
    await _transferCollection(
      firestore.collection('users/$fromUid/chuvas'),
      firestore.collection('users/$toUid/chuvas'),
    );

    // Transfer talhões
    await _transferCollection(
      firestore.collection('users/$fromUid/talhoes'),
      firestore.collection('users/$toUid/talhoes'),
    );

    // Transfer consents (merge, prefer newer)
    await _mergeConsents(fromUid, toUid);
  }

  static Future<void> _transferCollection(
    CollectionReference from,
    CollectionReference to,
  ) async {
    final snapshot = await from.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.set(to.doc(doc.id), doc.data());
    }

    await batch.commit();
  }
}

enum MigrationResult {
  linked,      // Successfully linked (same uid preserved)
  merged,      // Data merged to existing Google account
  notAnonymous, // User wasn't anonymous
  error,
}
```

### UI Flow

```
LoginScreen (Anonymous user clicks "Sign in with Google")
    │
    ├─ linkWithCredential() succeeds
    │   └─ ✅ Done (same uid, no data loss)
    │
    └─ credential-already-in-use error
        │
        └─ Migration Dialog
            ├─ Title: "Conta Google já existe"
            ├─ Message: "Deseja transferir seus dados para esta conta?"
            │
            ├─ [Cancelar] → Stay anonymous
            └─ [Transferir Dados]
                │
                └─ Progress Screen
                    ├─ "Transferindo propriedades..."
                    ├─ "Transferindo registros..."
                    ├─ "Transferindo configurações..."
                    │
                    └─ ✅ "Migração concluída!"
```

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/migration_service.dart` | CREATE | Data migration logic |
| `lib/screens/login_screen.dart` | MODIFY | Handle migration flow |
| `lib/screens/migration_progress_screen.dart` | CREATE | Progress UI during migration |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Migration-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Migration-related strings |

### L10n Strings Needed

```json
"migrationTitle": "Conta já existe",
"migrationMessage": "Esta conta Google já possui dados. Deseja transferir seus registros atuais para ela?",
"migrationTransfer": "Transferir Dados",
"migrationCancel": "Cancelar",
"migrationProgress": "Migrando dados...",
"migrationProgressProperties": "Transferindo propriedades...",
"migrationProgressRecords": "Transferindo registros...",
"migrationProgressSettings": "Transferindo configurações...",
"migrationSuccess": "Migração concluída com sucesso!",
"migrationError": "Erro durante migração. Seus dados originais foram preservados."
```

---

## Phase CORE-33: Cloud Backup & Restore

### Status: [PLANNED]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Enable automatic cloud backup and restore of user data via Firebase Storage.

### Features

| Feature | Description |
|---------|-------------|
| **Auto Backup** | Periodic backup of local Hive data to Firebase Storage |
| **Manual Backup** | User-triggered backup from Settings |
| **Restore** | Download and restore from latest backup |
| **Multi-device** | Same account on multiple devices syncs via backup |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 33.1 | Add `firebase_storage` dependency to agro_core | ⏳ TODO |
| 33.2 | Create `CloudBackupService` with `BackupProvider` interface | ⏳ TODO |
| 33.3 | Implement `backupAll()` - upload JSON to Storage | ⏳ TODO |
| 33.4 | Implement `restoreAll()` - download & parse JSON | ⏳ TODO |
| 33.5 | Add Backup/Restore UI to AgroSettingsScreen | ⏳ TODO |
| 33.6 | App Integration: Create `ChuvaBackupProvider` in planejachuva | ⏳ TODO |
| 33.7 | Register provider in main.dart | ⏳ TODO |

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     agro_core                           │
├─────────────────────────────────────────────────────────┤
│  CloudBackupService                                     │
│  ├─ backupAll(List<BackupProvider>)                    │
│  ├─ restoreAll(List<BackupProvider>)                   │
│  ├─ getLastBackupDate()                                │
│  └─ deleteBackup()                                     │
├─────────────────────────────────────────────────────────┤
│  BackupProvider (interface)                            │
│  ├─ String get collectionName                          │
│  ├─ Future<Map<String, dynamic>> exportData()          │
│  └─ Future<void> importData(Map<String, dynamic>)      │
└─────────────────────────────────────────────────────────┘
          │
          │ implements
          ▼
┌─────────────────────────────────────────────────────────┐
│                    planejachuva                         │
├─────────────────────────────────────────────────────────┤
│  ChuvaBackupProvider implements BackupProvider          │
│  PropertyBackupProvider implements BackupProvider       │
│  TalhaoBackupProvider implements BackupProvider         │
└─────────────────────────────────────────────────────────┘
```

### Proposed Interface & Service

```dart
// lib/services/backup_provider.dart
abstract class BackupProvider {
  String get collectionName;
  Future<List<Map<String, dynamic>>> exportData();
  Future<void> importData(List<Map<String, dynamic>> data);
  Future<void> clearData();
}

// lib/services/cloud_backup_service.dart
class CloudBackupService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final List<BackupProvider> _providers;

  CloudBackupService(this._providers);

  String get _backupPath => 'backups/${FirebaseAuth.instance.currentUser?.uid}/backup.json';

  Future<void> backupAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final backup = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'userId': user.uid,
      'data': {},
    };

    for (final provider in _providers) {
      backup['data'][provider.collectionName] = await provider.exportData();
    }

    final json = JsonEncoder.withIndent('  ').convert(backup);
    final bytes = utf8.encode(json);

    final ref = _storage.ref(_backupPath);
    await ref.putData(Uint8List.fromList(bytes));
  }

  Future<void> restoreAll() async {
    final ref = _storage.ref(_backupPath);

    try {
      final data = await ref.getData();
      if (data == null) throw Exception('No backup found');

      final json = utf8.decode(data);
      final backup = jsonDecode(json) as Map<String, dynamic>;

      final backupData = backup['data'] as Map<String, dynamic>;

      for (final provider in _providers) {
        if (backupData.containsKey(provider.collectionName)) {
          await provider.clearData();
          await provider.importData(
            List<Map<String, dynamic>>.from(backupData[provider.collectionName]),
          );
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw Exception('No backup found for this account');
      }
      rethrow;
    }
  }

  Future<DateTime?> getLastBackupDate() async {
    try {
      final ref = _storage.ref(_backupPath);
      final metadata = await ref.getMetadata();
      return metadata.updated ?? metadata.timeCreated;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteBackup() async {
    final ref = _storage.ref(_backupPath);
    await ref.delete();
  }
}
```

### Backup Format

```json
{
  "version": 1,
  "createdAt": "2026-01-20T15:30:00Z",
  "userId": "abc123",
  "data": {
    "properties": [
      {"id": "p1", "name": "Fazenda Primavera", "lat": -23.55, "lng": -46.63}
    ],
    "talhoes": [
      {"id": "t1", "name": "Talhão A", "propertyId": "p1", "area": 50}
    ],
    "chuvas": [
      {"id": "c1", "date": "2026-01-15", "mm": 25.5, "propertyId": "p1"}
    ],
    "settings": {
      "language": "pt",
      "notificationTime": "07:00"
    }
  }
}
```

### UI Integration

```
AgroSettingsScreen
    │
    ├─ Section: "Backup e Sincronização"
    │   ├─ Status: "Último backup: 20/01/2026 15:30"
    │   │
    │   ├─ [☁️ Fazer Backup Agora]
    │   │   └─ Progress → Success/Error Snackbar
    │   │
    │   └─ [📥 Restaurar Backup]
    │       └─ Confirmation Dialog
    │           ├─ Warning: "Isso substituirá os dados atuais"
    │           └─ [Cancelar] / [Restaurar]
    │               └─ Progress → Success → Reload App
```

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/backup_provider.dart` | CREATE | Interface for backup providers |
| `lib/services/cloud_backup_service.dart` | CREATE | Core backup/restore logic |
| `lib/screens/agro_settings_screen.dart` | MODIFY | Add backup UI section |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Backup-related strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Backup-related strings |
| `pubspec.yaml` | MODIFY | Add firebase_storage dependency |

### App-Specific Files (planejachuva)

| File | Action | Description |
|------|--------|-------------|
| `lib/providers/chuva_backup_provider.dart` | CREATE | Rainfall backup provider |
| `lib/main.dart` | MODIFY | Register backup providers |

### L10n Strings Needed

```json
"backupSectionTitle": "Backup e Sincronização",
"backupLastDate": "Último backup: {date}",
"backupNever": "Nenhum backup realizado",
"backupNowButton": "Fazer Backup Agora",
"backupRestoreButton": "Restaurar Backup",
"backupInProgress": "Fazendo backup...",
"backupSuccess": "Backup realizado com sucesso!",
"backupError": "Erro ao fazer backup: {error}",
"restoreConfirmTitle": "Restaurar Backup?",
"restoreConfirmMessage": "Isso substituirá todos os dados atuais pelos dados do backup. Esta ação não pode ser desfeita.",
"restoreCancel": "Cancelar",
"restoreConfirm": "Restaurar",
"restoreInProgress": "Restaurando dados...",
"restoreSuccess": "Dados restaurados com sucesso!",
"restoreError": "Erro ao restaurar: {error}",
"restoreNotFound": "Nenhum backup encontrado para esta conta."
```

### Dependencies

```yaml
dependencies:
  firebase_storage: ^11.0.0
```

### Security Rules (Firebase Storage)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /backups/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

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
