# PROPERTY MANAGEMENT ARCHITECTURE
## Arquitetura de Gerenciamento de Propriedades/Fazendas

**Data**: 2026-01-18
**Contexto**: PlanejaCampo Suite - Shared property management across apps
**Apps afetados**: PlanejaChuva, PlanejaBorracha, PlanejaDiesel, PlanejaVaca

---

## 1. SITUAÇÃO ATUAL

### 1.1. Modelo de Dados Existente

```dart
// apps/planejachuva/lib/models/registro_chuva.dart
@HiveType(typeId: 1)
class RegistroChuva extends HiveObject {
  @HiveField(0) final int id;
  @HiveField(1) final DateTime data;
  @HiveField(2) final double milimetros;
  @HiveField(3) final String? observacao;
  @HiveField(4) final DateTime criadoEm;
}
```

**Problema**: Nenhuma referência a propriedade/fazenda/localização.

### 1.2. Storage Atual

- **Local**: Hive (`registros_chuva` box) - offline-first
- **Cloud**: Firebase Auth (userId) + Firestore (planejado para Phase 15.0)
- **Compartilhamento entre apps**: NÃO implementado

---

## 2. REQUISITOS DO USUÁRIO

Da pergunta original:
> "Como ficou a questão da propriedade, do local onde a chuva vai ser registrada? Dá pra criar, escolher? É utilizada uma padrão se não escolher, enfim, como fica isso? Cria automático e pode mudar o nome depois (propriedade, e talhão área total, sei lá?) ou não foi pensado? É info compartilhada pelos apps mas do mesmo usuário (com controle de Id, mas que pode ser acessado por vários apps PlanejaChuva, PlanejaBorracha, etc.)?"

**Requisitos identificados**:
1. ✅ Criar e escolher propriedades
2. ✅ Propriedade padrão se não escolher
3. ✅ Criação automática com possibilidade de renomear depois
4. ✅ Informações opcionais: talhão, área total
5. ✅ Compartilhamento entre apps (PlanejaChuva, PlanejaBorracha, etc.)
6. ✅ Controle por userId (Firebase Auth)

---

## 3. ARQUITETURA PROPOSTA

### 3.1. Hierarquia de Entidades

```
User (Firebase Auth userId)
  └── Properties (Propriedades/Fazendas)
       ├── id: String
       ├── name: String (ex: "Fazenda Primavera")
       ├── totalArea: double? (ex: 150.5 hectares)
       ├── location: GeoPoint? (lat/lng para estatísticas regionais)
       ├── isDefault: bool
       ├── createdAt: DateTime
       ├── updatedAt: DateTime
       └── Plots (Talhões - OPCIONAL, Phase futura)
            ├── id: String
            ├── name: String (ex: "Talhão A1")
            ├── area: double? (ex: 25.0 hectares)
            └── crop: String? (ex: "Soja")
```

### 3.2. Onde Armazenar

**DECISÃO**: Propriedades vão em `agro_core` (compartilhadas entre apps)

```
packages/agro_core/lib/
  models/
    property.dart          # Modelo Property (Hive + Firestore)
    property.g.dart        # Generated adapter
  services/
    property_service.dart  # CRUD local (Hive)
    property_sync_service.dart # Sync Firestore (Phase futura)
```

### 3.3. Estrutura Firestore (para sync futuro)

```
users/{userId}/
  properties/{propertyId}/
    - id: string
    - name: string
    - totalArea: number (nullable)
    - location: geopoint (nullable)
    - isDefault: boolean
    - createdAt: timestamp
    - updatedAt: timestamp

  rainfallRecords/{recordId}/
    - propertyId: string (referência)
    - date: timestamp
    - millimeters: number
    - note: string (nullable)
    - createdAt: timestamp
```

**Benefício**: Qualquer app (PlanejaChuva, PlanejaBorracha) acessa as mesmas propriedades via `userId`.

---

## 4. COMPORTAMENTO PADRÃO (UX FLOW)

### 4.1. Primeira Abertura do App (Novo Usuário)

**OPÇÃO A: Auto-criação Silenciosa (RECOMENDADA)**

```
1. Usuário passa onboarding (IdentityScreen + ConsentScreen)
2. App cria automaticamente propriedade padrão:
   - name: "Minha Propriedade" (ou "My Property" se en)
   - isDefault: true
   - totalArea: null
   - location: null
3. Primeiro registro de chuva vai automaticamente para essa propriedade
4. Usuário pode renomear/editar depois via Settings → Propriedades
```

**Vantagens**:
- ✅ Zero friction - usuário registra chuva imediatamente
- ✅ Pode organizar depois (progressive disclosure)
- ✅ Similar a apps de notas (criam "Untitled Note" automaticamente)

**Desvantagens**:
- ⚠️ Usuário pode não saber que existe conceito de propriedade

---

**OPÇÃO B: Prompt na Primeira Chuva**

```
1. Usuário passa onboarding
2. Ao tentar registrar PRIMEIRA chuva, mostra dialog:
   "Onde você quer registrar esta chuva?"
   [Campo: Nome da Propriedade]
   [Button: Criar e Registrar]
   [Link: "Organizar minhas propriedades depois"]
3. Se clicar link: cria "Minha Propriedade" padrão
4. Se preencher: cria com nome escolhido
```

**Vantagens**:
- ✅ Contexto claro (usuário entende que chuva tem localização)
- ✅ Oportunidade de nomear corretamente desde o início

**Desvantagens**:
- ❌ Fricção extra antes do primeiro registro (pode gerar abandono)
- ❌ Usuário pode não ter nome em mente (ex: "Fazenda do João"? "Sítio"?)

---

**OPÇÃO C: Tela Dedicada Pós-Onboarding**

```
1. Usuário passa onboarding (IdentityScreen + ConsentScreen)
2. Mostra tela: "Configure sua primeira propriedade"
   [Campo: Nome (ex: Fazenda Primavera)]
   [Campo: Área Total (opcional)]
   [Campo: Localização (opcional, pedir GPS)]
   [Button: Continuar]
   [Link: "Pular por enquanto"]
3. Se preencher: cria propriedade customizada
4. Se pular: cria "Minha Propriedade" padrão
```

**Vantagens**:
- ✅ Fluxo educacional (usuário aprende sobre propriedades)
- ✅ Permite capturar área e localização desde o início

**Desvantagens**:
- ❌ Adiciona mais uma tela no onboarding (aumenta abandono)
- ❌ Informação que usuário pode não ter na mão (área, GPS)

---

### 4.2. Recomendação Final

**OPÇÃO A (Auto-criação Silenciosa)** + **Hint Educacional**

```
1. Criar automaticamente "Minha Propriedade" no primeiro acesso
2. No primeiro registro de chuva, mostrar Snackbar:
   "💡 Dica: Você pode gerenciar propriedades em Configurações"
   [Action: "VER AGORA"]
3. Mostrar badge/indicador em Settings → Propriedades (first-time)
```

**Justificativa**:
- Prioriza conversão e primeiro registro (core value)
- Progressive disclosure (complexidade revelada gradualmente)
- Consistente com offline-first (funciona sem internet)
- Permite multi-propriedade no futuro sem refactor

---

## 5. MODELO DE DADOS COMPLETO

### 5.1. Property Model (agro_core)

```dart
// packages/agro_core/lib/models/property.dart
import 'package:hive/hive.dart';

part 'property.g.dart';

@HiveType(typeId: 10) // Reserve typeId range 10-19 for agro_core models
class Property extends HiveObject {
  /// Unique identifier (timestamp-based or UUID)
  @HiveField(0)
  final String id;

  /// User ID from Firebase Auth (for cross-app access)
  @HiveField(1)
  final String userId;

  /// Property name (ex: "Fazenda Primavera")
  @HiveField(2)
  String name;

  /// Total area in hectares (optional)
  @HiveField(3)
  double? totalArea;

  /// Latitude for regional statistics (optional)
  @HiveField(4)
  double? latitude;

  /// Longitude for regional statistics (optional)
  @HiveField(5)
  double? longitude;

  /// Whether this is the default property for new records
  @HiveField(6)
  bool isDefault;

  /// Creation timestamp
  @HiveField(7)
  final DateTime createdAt;

  /// Last update timestamp
  @HiveField(8)
  DateTime updatedAt;

  Property({
    required this.id,
    required this.userId,
    required this.name,
    this.totalArea,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating a new property
  factory Property.create({
    required String userId,
    required String name,
    double? totalArea,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Property(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      totalArea: totalArea,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update name
  void updateName(String newName) {
    name = newName;
    updatedAt = DateTime.now();
  }

  /// Update total area
  void updateTotalArea(double? newArea) {
    totalArea = newArea;
    updatedAt = DateTime.now();
  }

  /// Update location
  void updateLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
    updatedAt = DateTime.now();
  }

  /// For Firestore sync (toMap/fromMap)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'totalArea': totalArea,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      totalArea: map['totalArea'] as double?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
```

### 5.2. PropertyService (agro_core)

```dart
// packages/agro_core/lib/services/property_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/property.dart';

/// Service for managing properties (local Hive storage).
class PropertyService {
  static const String _boxName = 'properties';

  // Singleton
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();

  late Box<Property> _box;

  /// Initialize Hive box (call from main.dart)
  Future<void> init() async {
    Hive.registerAdapter(PropertyAdapter());
    _box = await Hive.openBox<Property>(_boxName);
  }

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all properties for current user
  List<Property> getAllProperties() {
    if (_currentUserId == null) return [];
    return _box.values
        .where((p) => p.userId == _currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get default property for current user (or null if none exists)
  Property? getDefaultProperty() {
    if (_currentUserId == null) return null;
    try {
      return _box.values.firstWhere(
        (p) => p.userId == _currentUserId && p.isDefault,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get property by ID
  Property? getPropertyById(String id) {
    return _box.get(id);
  }

  /// Create a new property
  Future<Property> createProperty({
    required String name,
    double? totalArea,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final property = Property.create(
      userId: _currentUserId!,
      name: name,
      totalArea: totalArea,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );

    // If this is set as default, unset other defaults
    if (isDefault) {
      await _unsetOtherDefaults();
    }

    await _box.put(property.id, property);
    return property;
  }

  /// Update property
  Future<void> updateProperty(Property property) async {
    property.updatedAt = DateTime.now();
    await _box.put(property.id, property);
  }

  /// Delete property
  Future<void> deleteProperty(String id) async {
    await _box.delete(id);
  }

  /// Set property as default (unsets others)
  Future<void> setAsDefault(String propertyId) async {
    final property = _box.get(propertyId);
    if (property == null || property.userId != _currentUserId) {
      throw Exception('Property not found or unauthorized');
    }

    await _unsetOtherDefaults();
    property.isDefault = true;
    property.updatedAt = DateTime.now();
    await _box.put(propertyId, property);
  }

  /// Unset all default properties for current user
  Future<void> _unsetOtherDefaults() async {
    if (_currentUserId == null) return;

    final defaults = _box.values
        .where((p) => p.userId == _currentUserId && p.isDefault)
        .toList();

    for (final prop in defaults) {
      prop.isDefault = false;
      prop.updatedAt = DateTime.now();
      await _box.put(prop.id, prop);
    }
  }

  /// Ensure user has at least one default property (auto-create if needed)
  Future<Property> ensureDefaultProperty() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    var defaultProp = getDefaultProperty();
    if (defaultProp != null) return defaultProp;

    // No default exists - create one
    // TODO: Localize this string using AgroLocalizations
    return await createProperty(
      name: 'Minha Propriedade', // Will need l10n
      isDefault: true,
    );
  }
}
```

### 5.3. Atualização em RegistroChuva

```dart
// apps/planejachuva/lib/models/registro_chuva.dart
import 'package:hive/hive.dart';

part 'registro_chuva.g.dart';

@HiveType(typeId: 1)
class RegistroChuva extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  final double milimetros;

  @HiveField(3)
  final String? observacao;

  @HiveField(4)
  final DateTime criadoEm;

  /// NEW: Property ID (foreign key to Property model)
  @HiveField(5)
  final String propertyId;

  RegistroChuva({
    required this.id,
    required this.data,
    required this.milimetros,
    this.observacao,
    required this.criadoEm,
    required this.propertyId, // NEW
  });

  factory RegistroChuva.novo({
    required DateTime data,
    required double milimetros,
    String? observacao,
    required String propertyId, // NEW
  }) {
    final agora = DateTime.now();
    return RegistroChuva(
      id: agora.millisecondsSinceEpoch,
      data: data,
      milimetros: milimetros,
      observacao: observacao,
      criadoEm: agora,
      propertyId: propertyId, // NEW
    );
  }
}
```

---

## 6. MIGRAÇÃO DE DADOS EXISTENTES

### 6.1. Problema

Registros existentes não têm `propertyId`. Como migrar?

### 6.2. Estratégia de Migração

```dart
// apps/planejachuva/lib/services/migration_service.dart

class MigrationService {
  /// Migrate existing rainfall records to default property
  static Future<void> migrateToPropertySystem() async {
    final prefs = await Hive.openBox('migration_flags');

    // Check if already migrated
    if (prefs.get('rainfall_to_property_migrated') == true) {
      return;
    }

    // 1. Ensure default property exists
    final propertyService = PropertyService();
    final defaultProperty = await propertyService.ensureDefaultProperty();

    // 2. Get all rainfall records
    final chuvaBox = await Hive.openBox<RegistroChuva>('registros_chuva');
    final records = chuvaBox.values.toList();

    // 3. For each record without propertyId, assign default
    for (final record in records) {
      if (record.propertyId == null || record.propertyId.isEmpty) {
        // Create updated record with propertyId
        final updated = RegistroChuva(
          id: record.id,
          data: record.data,
          milimetros: record.milimetros,
          observacao: record.observacao,
          criadoEm: record.criadoEm,
          propertyId: defaultProperty.id,
        );
        await chuvaBox.put(record.id.toString(), updated);
      }
    }

    // 4. Mark migration as complete
    await prefs.put('rainfall_to_property_migrated', true);
  }
}
```

**Chamada em main.dart**:
```dart
// After ChuvaService().init()
await MigrationService.migrateToPropertySystem();
```

---

## 7. UI/UX FLOW DETALHADO

### 7.1. Settings → Propriedades

```
┌─────────────────────────────────────┐
│ Minhas Propriedades              [+]│
├─────────────────────────────────────┤
│ 🏡 Fazenda Primavera          [●] │  ← isDefault (ícone preenchido)
│    150.5 ha                          │
│                                      │
│ 🏡 Sítio do Vale                    │
│    25.0 ha                           │
└─────────────────────────────────────┘

[+] = Adicionar nova propriedade
[●] = Propriedade padrão
Tap = Editar propriedade
Long press = Opções (Definir como padrão, Excluir)
```

### 7.2. Adicionar/Editar Chuva

**MODO SIMPLIFICADO (padrão)**:
```
┌─────────────────────────────────────┐
│ Registrar Chuva                     │
├─────────────────────────────────────┤
│ Milímetros (mm)                     │
│ [________] mm                       │
│                                      │
│ Data                                │
│ [18/01/2026          ] 📅          │
│                                      │
│ Observação (opcional)               │
│ [________________________]          │
│                                      │
│ 🏡 Fazenda Primavera    [trocar] │  ← Mostra propriedade padrão
│                                      │
│         [SALVAR]    [CANCELAR]      │
└─────────────────────────────────────┘

"trocar" = Abre seletor de propriedade
```

**MODO AVANÇADO (se usuário tem múltiplas propriedades)**:
```
Adicionar campo dropdown/seletor sempre visível
```

### 7.3. Visualização de Dados

**Lista de Chuvas**:
```
┌─────────────────────────────────────┐
│ 18/01/2026                    25.5mm│
│ 🏡 Fazenda Primavera              │
│ Chuva forte à tarde                 │
├─────────────────────────────────────┤
│ 15/01/2026                    10.2mm│
│ 🏡 Sítio do Vale                    │
│                                      │
└─────────────────────────────────────┘
```

**Estatísticas** (com filtro de propriedade):
```
┌─────────────────────────────────────┐
│ Estatísticas de Chuva               │
│                                      │
│ Propriedade: [Todas ▼]              │  ← Filtro
│                                      │
│ Total 2026:          1.245,5 mm     │
│ Média por chuva:       45,2 mm      │
│ Maior registro:       125,0 mm      │
└─────────────────────────────────────┘
```

---

## 8. COMPARTILHAMENTO ENTRE APPS

### 8.1. Como Funciona

```
User (Firebase Auth: uid_12345)
  └── Properties (agro_core)
       ├── property_1 (Fazenda Primavera)
       └── property_2 (Sítio do Vale)

PlanejaChuva App
  └── rainfallRecords → propertyId: property_1

PlanejaBorracha App (futuro)
  └── rubberHarvestRecords → propertyId: property_1

PlanejaDiesel App (futuro)
  └── fuelRecords → propertyId: property_2
```

**Benefício**: Usuário configura propriedades UMA VEZ, todos os apps usam.

### 8.2. Implementação

1. **Property models em agro_core** (já proposto acima)
2. **Cada app usa PropertyService** para obter lista de propriedades
3. **Cada registro (chuva, borracha, diesel) tem propertyId**
4. **Firestore sync** sincroniza properties globalmente para o userId

---

## 9. L10N (INTERNACIONALIZAÇÃO)

### 9.1. Strings Necessárias

**packages/agro_core/lib/l10n/arb/app_pt.arb**:
```json
{
  "propertyDefaultName": "Minha Propriedade",
  "propertyTitle": "Propriedades",
  "propertyAdd": "Adicionar Propriedade",
  "propertyEdit": "Editar Propriedade",
  "propertyName": "Nome",
  "propertyNameHint": "Ex: Fazenda Primavera",
  "propertyTotalArea": "Área Total (ha)",
  "propertyTotalAreaHint": "Ex: 150.5",
  "propertyLocation": "Localização",
  "propertyLocationDesc": "Usado para estatísticas regionais (opcional)",
  "propertySetAsDefault": "Definir como padrão",
  "propertyIsDefault": "Propriedade padrão",
  "propertyDelete": "Excluir Propriedade",
  "propertyDeleteConfirm": "Tem certeza que deseja excluir esta propriedade? Todos os registros vinculados serão movidos para a propriedade padrão.",
  "propertyNoProperties": "Nenhuma propriedade cadastrada",
  "propertyChangeProperty": "Trocar propriedade",
  "propertySelectProperty": "Selecionar Propriedade",
  "propertyAllProperties": "Todas",
  "propertyFirstTimeTip": "💡 Dica: Você pode gerenciar propriedades em Configurações"
}
```

**app_en.arb** (traduções equivalentes)

---

## 10. FASES DE IMPLEMENTAÇÃO

### Phase 16.0: Property Management Foundation
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implement multi-property support with cross-app sharing

#### Phase 16.1: Core Models and Services (agro_core)
- Create Property model (Hive + Firestore-ready)
- Create PropertyService (CRUD local)
- Add L10n strings (pt + en)
- Register adapters and exports

**Files**:
- CREATE `packages/agro_core/lib/models/property.dart`
- CREATE `packages/agro_core/lib/services/property_service.dart`
- MODIFY `packages/agro_core/lib/agro_core.dart` (exports)
- MODIFY `packages/agro_core/lib/l10n/arb/app_pt.arb`
- MODIFY `packages/agro_core/lib/l10n/arb/app_en.arb`
- RUN `dart run build_runner build --delete-conflicting-outputs`

#### Phase 16.2: Update PlanejaChuva Models
- Add propertyId to RegistroChuva
- Create migration service
- Update ChuvaService to filter by property
- Initialize PropertyService in main.dart

**Files**:
- MODIFY `apps/planejachuva/lib/models/registro_chuva.dart`
- CREATE `apps/planejachuva/lib/services/migration_service.dart`
- MODIFY `apps/planejachuva/lib/services/chuva_service.dart`
- MODIFY `apps/planejachuva/lib/main.dart`
- RUN `dart run build_runner build --delete-conflicting-outputs` (in planejachuva)

#### Phase 16.3: Property Management UI (agro_core)
- Create PropertyListScreen
- Create PropertyFormScreen (add/edit)
- Add to AgroDrawer menu

**Files**:
- CREATE `packages/agro_core/lib/screens/property_list_screen.dart`
- CREATE `packages/agro_core/lib/screens/property_form_screen.dart`
- MODIFY `packages/agro_core/lib/menu/agro_drawer.dart`
- MODIFY `packages/agro_core/lib/agro_core.dart` (exports)

#### Phase 16.4: Integrate Property Selector in PlanejaChuva
- Add property selector in AdicionarChuvaScreen
- Add property selector in EditarChuvaScreen
- Show property name in RegistroChuva tile
- Add property filter in EstatisticasScreen

**Files**:
- MODIFY `apps/planejachuva/lib/screens/adicionar_chuva_screen.dart`
- MODIFY `apps/planejachuva/lib/screens/editar_chuva_screen.dart`
- MODIFY `apps/planejachuva/lib/widgets/registro_chuva_tile.dart`
- MODIFY `apps/planejachuva/lib/screens/estatisticas_screen.dart`

#### Phase 16.5: First-Time UX
- Show educational tip on first rainfall registration
- Auto-create default property on first app launch
- Badge/indicator in Settings → Propriedades

**Files**:
- MODIFY `apps/planejachuva/lib/screens/adicionar_chuva_screen.dart`
- MODIFY `apps/planejachuva/lib/main.dart`
- MODIFY `packages/agro_core/lib/screens/agro_settings_screen.dart`

#### Phase 16.6: Testing and Documentation
- Test migration from existing data
- Test multi-property scenarios
- Update CHANGELOG.md
- Update README.md with property architecture

**Files**:
- MODIFY `apps/planejachuva/CHANGELOG.md`
- MODIFY `packages/agro_core/CHANGELOG.md`
- MODIFY `README.md`

---

## 11. QUESTÕES EM ABERTO (DECISÕES NECESSÁRIAS)

### 11.1. Comportamento Padrão

**DECISÃO 1**: Auto-criação silenciosa vs. Prompt na primeira chuva?

**Recomendação**: Auto-criação silenciosa (Opção A) com hint educacional

### 11.2. Campos Obrigatórios

**DECISÃO 2**: Quais campos são obrigatórios em Property?
- ✅ name (obrigatório)
- ❓ totalArea (opcional - RECOMENDADO)
- ❓ location (opcional - RECOMENDADO para estatísticas regionais)

**Recomendação**: Somente `name` obrigatório, resto opcional (progressive disclosure)

### 11.3. Deletion Behavior

**DECISÃO 3**: O que fazer ao excluir uma propriedade com registros?
- **Opção A**: Bloquear exclusão (mostrar erro)
- **Opção B**: Mover registros para propriedade padrão (RECOMENDADO)
- **Opção C**: Excluir em cascata (perigoso!)

**Recomendação**: Opção B (mover para padrão) com confirmação clara

### 11.4. Talhões (Plots)

**DECISÃO 4**: Implementar talhões na Phase 16.0 ou deixar para o futuro?

**Recomendação**: NÃO implementar agora. Adicionar em Phase futura se necessário.

**Justificativa**:
- Aumenta complexidade significativamente
- Maioria dos usuários não precisa (YAGNI - You Aren't Gonna Need It)
- Pode ser adicionado depois sem breaking changes (nova tabela `plots` com `propertyId`)

### 11.5. Location Capture

**DECISÃO 5**: Pedir permissão de GPS ao criar propriedade?

**Recomendação**: Tornar COMPLETAMENTE OPCIONAL com botão "Usar minha localização"

**Justificativa**:
- Evita fricção e recusas de permissão
- Usuário pode não querer compartilhar localização exata
- Estatísticas regionais podem funcionar com município/estado (menos preciso)

---

## 12. RISCOS E MITIGAÇÕES

### 12.1. Migração de Dados

**Risco**: Registros existentes perdem vínculo com propriedade

**Mitigação**: Migration service automático que roda uma vez, vincula todos os registros órfãos à propriedade padrão

### 12.2. Sincronização Multi-App

**Risco**: Propriedades ficam dessincronizadas entre apps se houver conflitos

**Mitigação**:
- Firestore sync com merge strategy (last-write-wins)
- Propriedades são append-only (raramente deletadas)
- Conflitos resolvidos no servidor (Firestore timestamp)

### 12.3. Performance

**Risco**: Queries de registros podem ficar lentas com filtro de propriedade

**Mitigação**:
- Hive já é extremamente rápido para dados locais
- Adicionar índice composto em Firestore: `(userId, propertyId, date)`

### 12.4. UX Complexity

**Risco**: Adicionar propriedades pode confundir usuários simples

**Mitigação**:
- Progressive disclosure (funcionalidade escondida até ser necessária)
- Default silencioso (zero friction para usuário básico)
- Educação contextual (hints, tooltips)

---

## 13. EXEMPLOS DE CÓDIGO COMPLETO

### 13.1. Criar Propriedade Padrão (main.dart)

```dart
// apps/planejachuva/lib/main.dart
Future<void> main() async {
  // ... existing Firebase and Hive initialization ...

  // Initialize PropertyService
  await PropertyService().init();

  // Ensure default property exists
  await PropertyService().ensureDefaultProperty();

  // Migrate existing rainfall records
  await MigrationService.migrateToPropertySystem();

  // ... rest of initialization ...
}
```

### 13.2. Adicionar Chuva com Propriedade

```dart
// apps/planejachuva/lib/screens/adicionar_chuva_screen.dart

class _AdicionarChuvaScreenState extends State<AdicionarChuvaScreen> {
  Property? _selectedProperty;

  @override
  void initState() {
    super.initState();
    // Load default property
    _selectedProperty = PropertyService().getDefaultProperty();
  }

  Future<void> _salvarChuva() async {
    if (_selectedProperty == null) {
      // Should never happen, but handle gracefully
      _selectedProperty = await PropertyService().ensureDefaultProperty();
    }

    final novoRegistro = RegistroChuva.novo(
      data: _dataSelecionada,
      milimetros: double.parse(_milimetrosController.text),
      observacao: _observacaoController.text.isEmpty
        ? null
        : _observacaoController.text,
      propertyId: _selectedProperty!.id,
    );

    await ChuvaService().adicionar(novoRegistro);

    // Show educational tip on first registration
    await _showFirstTimeTip();

    Navigator.pop(context);
  }

  Future<void> _showFirstTimeTip() async {
    final prefs = await Hive.openBox('ui_flags');
    if (prefs.get('property_tip_shown') == true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AgroLocalizations.of(context)!.propertyFirstTimeTip),
        action: SnackBarAction(
          label: 'VER AGORA',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyListScreen(),
              ),
            );
          },
        ),
        duration: Duration(seconds: 10),
      ),
    );

    await prefs.put('property_tip_shown', true);
  }
}
```

---

## 14. CONCLUSÃO

### 14.1. Arquitetura Proposta

✅ **Property model em agro_core** (compartilhado entre apps)
✅ **Auto-criação silenciosa** de propriedade padrão (zero friction)
✅ **Progressive disclosure** (funcionalidade revelada gradualmente)
✅ **Migração automática** de dados existentes
✅ **Cross-app sharing** via userId (Firebase Auth)
✅ **Offline-first** com Firestore sync planejado

### 14.2. Benefícios

1. **UX Simplificada**: Usuário básico não precisa entender propriedades
2. **Escalável**: Usuários avançados podem gerenciar múltiplas propriedades
3. **Compartilhado**: Propriedades reutilizadas entre PlanejaChuva, PlanejaBorracha, etc.
4. **Extensível**: Talhões, culturas, safras podem ser adicionados no futuro
5. **LGPD-ready**: Localização é opcional e explícita

### 14.3. Próximos Passos

**AGUARDANDO APROVAÇÃO DO USUÁRIO**:
1. ✅ Decisão 1: Auto-criação silenciosa?
2. ✅ Decisão 2: Campos obrigatórios (somente `name`)?
3. ✅ Decisão 3: Mover registros ao excluir propriedade?
4. ✅ Decisão 4: NÃO implementar talhões agora?
5. ✅ Decisão 5: Localização COMPLETAMENTE OPCIONAL?

Após aprovação, iniciar **Phase 16.0** conforme planejado.

---

**Documento criado em**: 2026-01-18
**Autor**: Claude Code
**Status**: AGUARDANDO APROVAÇÃO
