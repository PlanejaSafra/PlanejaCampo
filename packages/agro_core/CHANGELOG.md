# CHANGELOG - agro_core

---

## Phase CORE-75: Preparação Multi-User (Farm-Centric Model)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Preparar estrutura de dados para futuro modelo multi-user sem implementar UI de convites/permissões.

### Contexto de Negócio

**Hoje (Single-User)**:
- Usuário = Dono da fazenda
- Todos os dados vinculados ao `userId`

**Futuro (Multi-User)**:
- Fazenda tem múltiplos usuários (Dono, Gerente, Funcionário)
- Dados vinculados à `farmId`, não ao `userId`
- Gerente pode lançar pesagem que aparece no app do Dono

### Mudança de Mentalidade

```dart
// ❌ ERRADO (User-Centric) - Problema se gerente sair
class Pesagem {
  String userId;  // Se gerente for demitido, dado some com ele
}

// ✅ CORRETO (Farm-Centric) - Preparado para futuro
class Pesagem {
  String farmId;     // A quem pertence o dado (fazenda)
  String createdBy;  // Quem criou (auditoria)
}
```

### Decisões de Arquitetura

#### 1. UUID Independente para farmId

```dart
// ❌ ERRADO - pode confundir e limita a 1 fazenda por usuário
farmId: userId,

// ✅ CORRETO - UUID independente
farmId: "farm-${uuid.v4()}", // ex: "farm-a1b2c3d4-..."
ownerId: userId,             // Dono da fazenda
```

**Por que UUID separado?**
- Permite múltiplas fazendas por usuário no futuro
- Evita confusão entre conceitos (usuário ≠ fazenda)
- Preparado para transferência de propriedade

#### 2. Farm no BackupProvider

A entidade Farm DEVE ser incluída no backup/restore:
- Sem a Farm, os dados ficam órfãos (farmId aponta para nada)
- BackupProvider deve exportar/importar farms junto com dados

#### 3. Firestore Não Impactado

- Farm é armazenada localmente (Hive) como Property
- Backup manual (CloudBackupService) inclui Farm no JSON
- Zero mudanças em Firestore collections ou rules

### Modelo Base

```dart
/// Farm model (criado automaticamente, invisível para o usuário)
@HiveType(typeId: 20)
class Farm {
  @HiveField(0)
  String id;            // UUID: "farm-a1b2c3d4-..."

  @HiveField(1)
  String name;          // "Seringal Santa Fé"

  @HiveField(2)
  String ownerId;       // userId do dono principal

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isDefault;       // Farm padrão do usuário

  // Futuro: List<FarmMember> members;
}

/// Mixin para entidades que pertencem a uma fazenda
mixin FarmOwnedMixin {
  String get farmId;      // UUID da fazenda
  String get createdBy;   // userId de quem criou
  DateTime get createdAt;
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 75.1 | **Modelo Farm**: Criar entidade com Hive adapter (typeId: 20) | ✅ DONE |
| 75.2 | **FarmService**: CRUD + auto-criar no primeiro uso + getDefaultFarm() | ✅ DONE |
| 75.3 | **Mixin FarmOwned**: Campos farmId + createdBy para modelos | ✅ DONE |
| 75.4 | **L10n Strings**: Adicionar strings para Farm (PT-BR + EN) | ✅ DONE |
| 75.5 | **Export**: Atualizar agro_core.dart | ✅ DONE |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/farm.dart` | CREATE | Modelo Farm com Hive adapter |
| `lib/models/farm.g.dart` | GENERATE | Hive adapter gerado |
| `lib/services/farm_service.dart` | CREATE | Gestão de fazendas |
| `lib/models/farm_owned_mixin.dart` | CREATE | Mixin para entidades com farmId |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Strings PT-BR |
| `lib/l10n/arb/app_en.arb` | MODIFY | Strings EN |
| `lib/agro_core.dart` | MODIFY | Exports |

### O Que NÃO Fazer Agora

- ❌ Tela de convite de membros
- ❌ Sistema de permissões (Owner, Manager, Worker)
- ❌ Sincronização entre dispositivos de usuários diferentes
- ❌ UI de "Trocar de Fazenda"
- ❌ Firestore rules para multi-tenant
- ❌ Migrar modelos existentes (fazer quando necessário)

### Integração com BackupProvider

Apps que implementam BackupProvider devem incluir Farm:

```dart
class AppBackupProvider implements BackupProvider {
  @override
  Future<Map<String, dynamic>> export(String userId) async {
    final farms = await FarmService.instance.getFarmsForUser(userId);
    return {
      'farms': farms.map((f) => f.toJson()).toList(),
      // ... outros dados
    };
  }

  @override
  Future<void> import(String userId, Map<String, dynamic> data) async {
    // Importar farms PRIMEIRO (os dados dependem delas)
    if (data['farms'] != null) {
      await FarmService.instance.importFarms(data['farms']);
    }
    // ... importar outros dados
  }
}
```

### Cross-Reference
- RUBBER-22 (Onboarding cria Farm automaticamente)
- Todos os apps do ecossistema devem usar farmId
- PropertyBackupProvider deve incluir Farm
- CORE-77 (Arquitetura de Backup)

---

## Phase CORE-77: Arquitetura de Backup Dependency-Aware

### Status: [TODO]
**Priority**: 🔴 CRITICAL (Pré-requisito para multi-user e integridade de dados)
**Objective**: Arquitetura de backup/restore que protege integridade cross-app, verifica dependências antes de deletar, e prepara para multi-user.

---

### 1. O Problema Central

```
CENÁRIO REAL (Single-User, Multi-App):

Timeline:
├─ Jan: User faz backup do RuraRubber (Talhão A, B)
├─ Fev: Cria Talhão C no RuraCrop
├─ Fev: Lança Despesa de Fertilizante no Talhão C (RuraCash)
├─ Fev: RuraRubber auto-cria despesa de frete (vai pro RuraCash)
├─ Mar: User faz RESTORE do backup de Janeiro
│
└─ ❓ PROBLEMAS:
   1. Talhão C não existe no backup → Deleta? Mas tem despesa!
   2. Despesa de frete criada pelo RuraRubber → Deleta do RuraCash?
   3. Despesa manual do RuraCash → Não toca? Como diferenciar?
   4. Se não deletar nada → Lixo órfão, dados duplicados
   5. Se deletar tudo → Perde trabalho de outros apps
```

```
CENÁRIO FUTURO (Multi-User):

Farm: "Seringal Santa Fé"
├── Owner: João
├── Gerente: Pedro (faz pesagens, entregas)
└── Funcionário: Zé (só pesagens)

Pedro faz backup → restaura → O que acontece com dados do Zé?
Se sourceApp = "rurarubber" para TODOS, restore do Pedro deleta dados do Zé!
```

---

### 2. Princípio Fundamental: Ownership Explícito

**Toda entidade DEVE saber sua origem para permitir operações seguras.**

#### 2.1 FarmOwnedMixin (Atualizado)

```dart
/// Mixin para TODAS as entidades do ecossistema
/// Permite rastreabilidade completa de origem
mixin FarmOwnedMixin {
  /// UUID da fazenda dona dos dados
  String get farmId;

  /// userId de quem criou o registro
  String get createdBy;

  /// Quando foi criado
  DateTime get createdAt;

  /// NOVO: App que criou o registro
  /// Valores: "rurarubber", "rurarain", "ruracrop", "ruracash", etc.
  /// Permite restore cirúrgico por app de origem
  String get sourceApp;
}
```

#### 2.2 Por que `sourceApp` é Essencial

```dart
// CENÁRIO: Despesa pode ser criada por múltiplos apps

// Despesa criada manualmente no RuraCash
Despesa(
  id: "desp-001",
  descricao: "Fertilizante",
  sourceApp: "ruracash",  // ← Origem
  createdBy: "user-joao",
)

// Despesa criada automaticamente pelo RuraRubber (ao fechar entrega)
Despesa(
  id: "desp-002",
  descricao: "Frete Entrega #45",
  sourceApp: "rurarubber",  // ← Origem diferente!
  createdBy: "user-joao",
)

// RESTORE do RuraRubber:
// DELETE FROM despesas WHERE sourceApp = "rurarubber"
// ✅ Deleta desp-002 (criada pelo rubber)
// ✅ Mantém desp-001 (criada pelo cash)
```

---

### 3. Arquitetura em Camadas (Layers)

```
┌─────────────────────────────────────────────────────────────────┐
│                    BACKUP LAYERS                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LAYER 0: Farm (IMUTÁVEL)                                       │
│  ├─ Nunca sobrescreve no restore                                │
│  ├─ Só cria se não existir                                      │
│  └─ Razão: É a raiz de todos os dados                           │
│                                                                 │
│  LAYER 1: Estruturas Compartilhadas (APPEND-ONLY)               │
│  ├─ Entidades: Property, Talhão, Parceiro, Cultura              │
│  ├─ Cada uma tem sourceApp (quem criou)                         │
│  ├─ Restore: CRIA novos, NUNCA deleta existentes                │
│  ├─ Deleção: Só se NÃO tiver dependências em outros apps        │
│  └─ Razão: Múltiplos apps referenciam essas estruturas          │
│                                                                 │
│  LAYER 2: Movimentações (REPLACE por sourceApp + scope)         │
│  ├─ Entidades: Pesagem, Entrega, Chuva, Despesa, Ciclo          │
│  ├─ Cada uma tem sourceApp + createdBy                          │
│  ├─ Restore scope "personal":                                   │
│  │   DELETE WHERE sourceApp = X AND createdBy = user            │
│  ├─ Restore scope "full" (owner only):                          │
│  │   DELETE WHERE sourceApp = X                                 │
│  └─ Razão: Isolamento por app E por usuário                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### 4. Dependency-Aware Operations

#### 4.1 O que são Dependências Cross-App?

```
Talhão "Seringal Norte" (criado pelo RuraRubber)
├── Referenciado por:
│   ├── RuraRubber: 45 pesagens
│   ├── RuraRain: 12 registros de chuva
│   ├── RuraCrop: 2 ciclos de cultura
│   └── RuraCash: 8 despesas vinculadas
│
└── REGRA: Só pode ser deletado se TODAS as referências forem zero
           OU se o usuário confirmar cascata (com aviso explícito)
```

#### 4.2 DependencyService (Interface)

```dart
/// Service que conhece todas as referências cross-app
/// Registrado no init de cada app
class DependencyService {
  static final _instance = DependencyService._();
  static DependencyService get instance => _instance;

  final _registry = <String, List<DependencyChecker>>{};

  /// Cada app registra suas dependências no init
  /// Ex: RuraRubber registra que Pesagem depende de Talhão
  void registerDependency(DependencyChecker checker) {
    _registry.putIfAbsent(checker.targetType, () => []).add(checker);
  }

  /// Verifica se entidade pode ser deletada
  /// Retorna mapa de bloqueadores: {appId: [motivos]}
  Future<DependencyCheckResult> canDelete({
    required String entityType,  // "talhao", "parceiro", "property"
    required String entityId,
    required String requestingApp, // App que quer deletar
  }) async {
    final blockers = <String, List<String>>{};

    for (final checker in _registry[entityType] ?? []) {
      // Não bloqueia a si mesmo
      if (checker.sourceApp == requestingApp) continue;

      final count = await checker.countReferences(entityId);
      if (count > 0) {
        blockers[checker.sourceApp] = [
          '${count} ${checker.referenceDescription}',
        ];
      }
    }

    return DependencyCheckResult(
      canDelete: blockers.isEmpty,
      blockers: blockers,
    );
  }
}

/// Registrado por cada app
class DependencyChecker {
  final String sourceApp;           // "rurarubber"
  final String sourceType;          // "pesagem"
  final String targetType;          // "talhao"
  final String referenceDescription; // "pesagens registradas"
  final Future<int> Function(String targetId) countReferences;
}
```

#### 4.3 Exemplo de Registro (cada app no init)

```dart
// RuraRubber registra no main.dart
DependencyService.instance.registerDependency(
  DependencyChecker(
    sourceApp: 'rurarubber',
    sourceType: 'pesagem',
    targetType: 'talhao',
    referenceDescription: 'pesagens registradas',
    countReferences: (talhaoId) async {
      final pesagens = await PesagemService.instance.getByTalhao(talhaoId);
      return pesagens.length;
    },
  ),
);

// RuraRain registra
DependencyService.instance.registerDependency(
  DependencyChecker(
    sourceApp: 'rurarain',
    sourceType: 'chuva',
    targetType: 'talhao',
    referenceDescription: 'registros de chuva',
    countReferences: (talhaoId) async {
      final chuvas = await ChuvaService.instance.getByTalhao(talhaoId);
      return chuvas.length;
    },
  ),
);
```

---

### 5. Restore em 3 Fases

O restore NUNCA é automático. Sempre passa por análise e confirmação.

```
┌─────────────────────────────────────────────────────────────────┐
│           FASE 1: ANÁLISE (Read-Only, Sem Modificações)         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Lê arquivo de backup                                        │
│  2. Valida _meta (appId, farmId, schemaVersion)                 │
│  3. Compara com estado atual do banco                           │
│  4. Para cada entidade, determina:                              │
│     ├─ ADICIONAR: Existe no backup, não existe local           │
│     ├─ MANTER: Existe em ambos, sem conflito                   │
│     ├─ DELETAR: Não existe no backup, existe local             │
│     │   └─ Verifica dependências antes de marcar               │
│     └─ CONFLITO: Existe em ambos com dados diferentes          │
│  5. Gera RestoreAnalysis com todas as operações planejadas     │
│                                                                 │
│  OUTPUT: RestoreAnalysis {                                      │
│    toAdd: [...],                                                │
│    toDelete: [...],                                             │
│    blocked: {...},  // Não pode deletar por dependências        │
│    conflicts: [...],                                            │
│    warnings: [...],                                             │
│    recalculations: [...],  // Saldos a recalcular              │
│  }                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│           FASE 2: CONFIRMAÇÃO (UI com Relatório Detalhado)      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  📋 Relatório de Restore - RuraRubber                     │  │
│  │                                                           │  │
│  │  Backup: 25/01/2026 às 10:30                              │  │
│  │  Farm: Seringal Santa Fé                                  │  │
│  │                                                           │  │
│  │  ────────────────────────────────────────────────────────│  │
│  │                                                           │  │
│  │  ✅ SERÁ RESTAURADO:                                      │  │
│  │  ├─ 45 pesagens                                           │  │
│  │  ├─ 12 entregas                                           │  │
│  │  └─ 3 parceiros                                           │  │
│  │                                                           │  │
│  │  🗑️ SERÁ REMOVIDO (dados posteriores ao backup):          │  │
│  │  ├─ 3 pesagens (criadas após 25/01)                       │  │
│  │  └─ 1 entrega (criada após 25/01)                         │  │
│  │                                                           │  │
│  │  ⚠️ NÃO SERÁ REMOVIDO (dependências em outros apps):      │  │
│  │  ├─ Talhão "Seringal Norte"                               │  │
│  │  │   └─ RuraCash: 5 despesas vinculadas                   │  │
│  │  │   └─ RuraRain: 8 registros de chuva                    │  │
│  │  └─ Parceiro "João Silva"                                 │  │
│  │      └─ RuraCash: 2 pagamentos registrados                │  │
│  │                                                           │  │
│  │  ℹ️ SALDOS A RECALCULAR APÓS RESTORE:                     │  │
│  │  ├─ Total de produção por período                         │  │
│  │  └─ Saldo devedor com parceiros                           │  │
│  │                                                           │  │
│  │  ────────────────────────────────────────────────────────│  │
│  │                                                           │  │
│  │  ⚠️ Esta operação NÃO pode ser desfeita.                  │  │
│  │                                                           │  │
│  │            [Cancelar]         [Confirmar Restore]         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│           FASE 3: EXECUÇÃO (Transacional)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  try {                                                          │
│    // 1. Inicia transação (ou simula com rollback manual)       │
│    BEGIN_TRANSACTION                                            │
│                                                                 │
│    // 2. Layer 0: Farm (imutável)                               │
│    if (farm não existe) {                                       │
│      criar farm do backup                                       │
│    }                                                            │
│    // NÃO sobrescreve se já existe                              │
│                                                                 │
│    // 3. Layer 1: Estruturas (append-only)                      │
│    for (estrutura in backup.estruturas) {                       │
│      if (não existe local) {                                    │
│        criar estrutura                                          │
│      }                                                          │
│      // NÃO atualiza nem deleta existentes                      │
│    }                                                            │
│                                                                 │
│    // 4. Layer 2: Movimentações (replace por sourceApp)         │
│    // Deleta APENAS dados permitidos pela análise               │
│    for (item in analysis.toDelete) {                            │
│      if (item NOT IN analysis.blocked) {                        │
│        deletar item                                             │
│      }                                                          │
│    }                                                            │
│                                                                 │
│    // 5. Importa dados do backup                                │
│    for (item in backup.movimentacoes) {                         │
│      inserir ou atualizar item                                  │
│    }                                                            │
│                                                                 │
│    // 6. Dispara recálculo de saldos                            │
│    await backupProvider.recalculateAfterRestore()               │
│                                                                 │
│    COMMIT                                                       │
│                                                                 │
│  } catch (error) {                                              │
│    ROLLBACK                                                     │
│    throw RestoreError(error)                                    │
│  }                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### 6. Recálculo de Saldos Pós-Restore

Alguns dados derivados precisam ser recalculados após o restore.

#### 6.1 Princípio: Query-Based é Preferível

```dart
// ✅ PREFERÍVEL: Totais calculados via query (nunca ficam "furados")
Future<double> getTotalProducao(String safraId) async {
  final safra = await getSafra(safraId);
  return pesagens
      .where((p) => p.data >= safra.dataInicio && p.data < safra.dataFim)
      .fold(0.0, (sum, p) => sum + p.peso);
}

// ❌ EVITAR: Totais armazenados (podem ficar inconsistentes)
// safra.totalKg = 15400; // Se editar pesagem antiga, "fura"
```

#### 6.2 Quando Recálculo é Necessário

Alguns cenários exigem saldos pré-calculados por performance:

| Dado | Motivo | Recálculo Após Restore |
|------|--------|------------------------|
| Saldo com Parceiros | Evita somar milhares de pesagens | `recalcularSaldoParceiros()` |
| Posição de Caixa | Snapshot diário para relatórios | `recalcularPosicaoCaixa()` |
| Estoque em Barracão | Entradas - Saídas acumuladas | `recalcularEstoque()` |

#### 6.3 Interface BackupProvider (com recálculo)

```dart
abstract class BackupProvider {
  String get appId;
  int get schemaVersion;

  Future<Map<String, dynamic>> export({...});
  Future<RestoreAnalysis> analyzeRestore({...});
  Future<void> executeRestore(RestoreAnalysis analysis);

  /// Chamado APÓS restore bem-sucedido
  /// Cada app implementa seu recálculo específico
  Future<RecalculationResult> recalculateAfterRestore();
}

// Exemplo: RuraRubber
class BorrachaBackupProvider implements BackupProvider {
  @override
  Future<RecalculationResult> recalculateAfterRestore() async {
    final results = <String>[];

    // Recalcula saldo com cada parceiro
    final parceiros = await ParceiroService.instance.getAll();
    for (final p in parceiros) {
      final saldo = await _recalcularSaldo(p.id);
      results.add('${p.nome}: R\$ ${saldo.toStringAsFixed(2)}');
    }

    // Recalcula totais por safra
    await _recalcularTotaisSafra();

    return RecalculationResult(success: true, details: results);
  }
}
```

---

### 7. Estrutura do JSON de Backup

```json
{
  "_meta": {
    "appId": "rurarubber",
    "appVersion": "1.2.0",
    "backupType": "app",
    "backupScope": "personal",
    "farmId": "farm-abc123",
    "userId": "user-xyz789",
    "createdAt": "2026-01-25T10:30:00Z",
    "schemaVersion": 2
  },

  "farm": {
    "id": "farm-abc123",
    "name": "Seringal Santa Fé",
    "ownerId": "user-xyz789",
    "createdAt": "2025-09-01T00:00:00Z"
  },

  "sharedStructures": {
    "properties": [
      {
        "id": "prop-001",
        "name": "Fazenda Principal",
        "sourceApp": "rurarubber",
        "createdBy": "user-xyz789"
      }
    ],
    "talhoes": [
      {
        "id": "tal-001",
        "name": "Seringal Norte",
        "propertyId": "prop-001",
        "sourceApp": "rurarubber",
        "createdBy": "user-xyz789"
      }
    ],
    "parceiros": [
      {
        "id": "parc-001",
        "nome": "João Sangrador",
        "sourceApp": "rurarubber",
        "createdBy": "user-xyz789"
      }
    ]
  },

  "appData": {
    "pesagens": [
      {
        "id": "pes-001",
        "data": "2026-01-20",
        "peso": 45.5,
        "talhaoId": "tal-001",
        "parceiroId": "parc-001",
        "farmId": "farm-abc123",
        "sourceApp": "rurarubber",
        "createdBy": "user-xyz789",
        "createdAt": "2026-01-20T08:30:00Z"
      }
    ],
    "entregas": [...],
    "despesasGeradas": [
      {
        "id": "desp-rubber-001",
        "descricao": "Frete Entrega #45",
        "sourceApp": "rurarubber",
        "targetApp": "ruracash"
      }
    ]
  }
}
```

---

### 8. Regras de Restore (Resumo)

| Camada | Entidades | Operação no Restore | Deleção |
|--------|-----------|---------------------|---------|
| **Layer 0** | Farm | Cria se não existe, NUNCA sobrescreve | NUNCA |
| **Layer 1** | Property, Talhão, Parceiro | Cria novos, NUNCA deleta | Só se sem dependências |
| **Layer 2** | Pesagem, Entrega, Chuva, Despesa | Replace por sourceApp + scope | Permitido |

| Scope | Quem Pode | O Que Deleta |
|-------|-----------|--------------|
| `personal` | Qualquer membro | `WHERE sourceApp = X AND createdBy = user` |
| `full` | Owner apenas | `WHERE sourceApp = X` |

---

### 9. Cenários de Teste (Validação da Arquitetura)

#### 9.1 Single-User, Multi-App

```
SETUP:
├─ User tem RuraRubber + RuraRain + RuraCash
├─ Talhão "Norte" criado no RuraRubber
├─ Chuvas registradas no RuraRain para Talhão "Norte"
├─ Despesas manuais no RuraCash

TESTE: Restore do RuraRubber (backup antigo)
├─ ✅ Pesagens do RuraRubber: SUBSTITUÍDAS
├─ ✅ Chuvas do RuraRain: INTOCADAS (outro app)
├─ ✅ Despesas manuais do RuraCash: INTOCADAS (sourceApp diferente)
├─ ✅ Despesas geradas pelo RuraRubber: DELETADAS (sourceApp = rurarubber)
└─ ✅ Talhão "Norte": MANTIDO (tem dependências no RuraRain)
```

#### 9.2 Multi-User

```
SETUP:
├─ Farm: Seringal Santa Fé
├─ Owner: João
├─ Gerente: Pedro (cria pesagens)
├─ Funcionário: Zé (cria pesagens)

TESTE: Pedro faz restore (scope: personal)
├─ ✅ Pesagens de Pedro: SUBSTITUÍDAS
├─ ✅ Pesagens de Zé: INTOCADAS (createdBy diferente)
├─ ✅ Pesagens de João: INTOCADAS (createdBy diferente)

TESTE: João faz restore (scope: full, como Owner)
├─ ✅ Pesagens de TODOS: SUBSTITUÍDAS
├─ ⚠️ Aviso: "Isso afetará dados de Pedro e Zé"
```

#### 9.3 Estrutura Órfã

```
SETUP:
├─ Backup de Janeiro tem Talhão X
├─ Talhão X foi DELETADO em Fevereiro
├─ Março: Restore do backup de Janeiro

RESULTADO:
├─ Pesagens do Talhão X no backup → NÃO importadas
├─ ⚠️ Warning: "5 pesagens ignoradas (talhão não existe)"
├─ Opção: "Recriar Talhão X?" [Sim] [Não]
```

---

### 10. Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 77.1 | **sourceApp no FarmOwnedMixin**: Adicionar campo obrigatório | ⏳ TODO |
| 77.2 | **DependencyService**: Interface + registro de dependências | ⏳ TODO |
| 77.3 | **RestoreAnalysis Model**: Estrutura de análise pré-restore | ⏳ TODO |
| 77.4 | **BackupMeta Model**: Metadados do backup com appId | ⏳ TODO |
| 77.5 | **BackupProvider Interface**: Atualizar com analyzeRestore() | ⏳ TODO |
| 77.6 | **RestoreConfirmationDialog**: UI com relatório detalhado | ⏳ TODO |
| 77.7 | **Recálculo de Saldos**: Interface + implementação por app | ⏳ TODO |
| 77.8 | **Migração**: Adicionar sourceApp a entidades existentes | ⏳ TODO |
| 77.9 | **LGPD Delete**: Atualizar DataDeletionService para multi-app | ⏳ TODO |
| 77.10 | **LGPD Export**: Atualizar DataExportService com referências | ⏳ TODO |

---

### 11. Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/farm_owned_mixin.dart` | MODIFY | Adicionar sourceApp |
| `lib/models/backup_meta.dart` | CREATE | Metadados do backup |
| `lib/models/restore_analysis.dart` | CREATE | Resultado da análise |
| `lib/models/dependency_check_result.dart` | CREATE | Resultado de verificação |
| `lib/services/dependency_service.dart` | CREATE | Registro e verificação |
| `lib/services/backup_provider.dart` | MODIFY | Nova interface completa |
| `lib/services/cloud_backup_service.dart` | MODIFY | Fluxo em 3 fases |
| `lib/services/data_deletion_service.dart` | MODIFY | LGPD delete multi-app |
| `lib/services/data_export_service.dart` | MODIFY | LGPD export com referências |
| `lib/widgets/restore_confirmation_dialog.dart` | CREATE | UI de confirmação |
| `lib/widgets/deletion_result_dialog.dart` | CREATE | UI resultado LGPD delete |
| `lib/l10n/arb/*.arb` | MODIFY | Strings para UI |

---

### 12. Perguntas de Design Respondidas

| Pergunta | Resposta |
|----------|----------|
| Backup de um app afeta outros? | **NÃO** - cada app só toca dados WHERE sourceApp = próprio |
| Farm é sobrescrita no restore? | **NÃO** - Layer 0 é imutável |
| Estruturas (Talhão, Parceiro) são deletadas? | **SÓ SE** não tiverem dependências em outros apps |
| Despesas geradas pelo RuraRubber são deletadas? | **SIM** - sourceApp = "rurarubber" |
| Despesas manuais do RuraCash são afetadas? | **NÃO** - sourceApp = "ruracash" |
| Gerente pode fazer backup full? | **NÃO** - só Owner tem scope "full" |
| Como saber o que será afetado? | **Fase 1 (Análise)** + **Fase 2 (Confirmação com relatório)** |
| E se o backup tiver estrutura que foi deletada? | **Warning** + opção de recriar |
| Saldos ficam inconsistentes após restore? | **NÃO** - recalculateAfterRestore() é chamado |
| LGPD Delete pode ser bloqueado? | **NÃO** - direito legal prevalece, apenas informa o que foi mantido |
| Quando Farm é deletada? | **Quando último app** com dados for deletado |
| LGPD Export leva dados de outros apps? | **NÃO** - só referências (id + nome) |

---

### 13. LGPD: Deleção e Exportação (Diferenças do Restore)

#### 13.1 LGPD vs Restore: Regras Diferentes

| Operação | Objetivo | Pode Bloquear? | Razão |
|----------|----------|----------------|-------|
| **Restore** | Conveniência do usuário | ✅ SIM | Protege integridade |
| **LGPD Delete** | Direito Legal (Art. 18, VI) | ❌ NÃO | Lei > Técnica |
| **LGPD Export** | Direito Legal (Art. 18, V) | ❌ NÃO | Deve exportar TUDO |

**Princípio**: LGPD SEMPRE executa. Restore pode ser bloqueado.

#### 13.2 LGPD Delete (Direito ao Esquecimento)

```dart
/// Regras de deleção LGPD por camada
class LgpdDeletionRules {

  // Layer 2: Movimentações - SEMPRE deleta (são dados do usuário)
  // Não verifica dependências - direito legal prevalece
  await deleteMovements(appId, userId, farmId);

  // Layer 1: Estruturas - Deleta SE não tiver referência em OUTRO app
  // Se tiver, deixa para o outro app limpar depois
  for (final estrutura in structures) {
    final deps = await checkDependencies(estrutura);
    if (deps.onlyFromThisApp || deps.none) {
      await delete(estrutura);
    } else {
      // NÃO bloqueia, apenas mantém e informa
      result.kept.add(estrutura);
    }
  }

  // Layer 0: Farm - Deleta SE é o último app com dados
  if (!hasDataFromOtherApps(farmId)) {
    await deleteFarm(farmId);
  }
}
```

#### 13.3 Cascata de Deleção (Último App)

```
User deleta apps na ordem: RuraRubber → RuraCash → RuraRain (último)

Após deletar RuraRubber:
├─ Pesagens, Entregas: DELETADAS
├─ Talhão Norte: MANTIDO (RuraRain usa)
└─ Farm: MANTIDA (RuraRain tem dados)

Após deletar RuraCash:
├─ Despesas manuais: DELETADAS
├─ Talhão Norte: MANTIDO (RuraRain usa)
└─ Farm: MANTIDA (RuraRain tem dados)

Após deletar RuraRain (último):
├─ Chuvas: DELETADAS
├─ Talhão Norte: DELETADO (ninguém mais usa)
└─ Farm: DELETADA (ninguém mais tem dados)
└─ TUDO LIMPO ✅
```

#### 13.4 LGPD Export (Portabilidade)

```json
{
  "_meta": {
    "exportType": "lgpd_portability",
    "appId": "rurarubber",
    "userId": "user-xyz789"
  },

  "userData": {
    "profile": { "email": "...", "name": "..." },

    "structures": {
      "farms": [...],
      "properties": [...],
      "talhoes": [
        {
          "id": "tal-001",
          "name": "Seringal Norte",
          "createdByThisApp": true,
          "usedByOtherApps": ["rurarain"]
        }
      ]
    },

    "movements": {
      "pesagens": [...],
      "entregas": [...]
    },

    "consents": {...},
    "settings": {...}
  },

  "references": {
    "note": "Estruturas usadas mas criadas por outros apps",
    "externalStructures": [
      {"id": "tal-005", "sourceApp": "ruracrop"}
    ]
  }
}
```

| Dado | Exporta? | Formato |
|------|----------|---------|
| Movimentações próprias | ✅ | Completo |
| Estruturas criadas | ✅ | Completo |
| Estruturas de outros apps (usadas) | ✅ | Referência |
| Dados de outros apps | ❌ | N/A |
| Consentimentos | ✅ | Completo |

---

### 14. Cross-Reference

- **CORE-75**: Farm model, FarmOwnedMixin (base para sourceApp)
- **CORE-76**: Safra global (totais por período)
- **CORE-33**: CloudBackupService (implementação atual a ser atualizada)
- **CORE-36**: DataDeletionService (atualizar para multi-app)
- **CORE-37**: DataExportService (atualizar para multi-app)
- **RUBBER-XX**: BorrachaBackupProvider (implementar nova interface)
- **RAIN-XX**: ChuvaBackupProvider (implementar nova interface)
- **CROP-XX**: CropBackupProvider (futuro)
- **CASH-XX**: CashBackupProvider (futuro)

---

### 15. Pontos Críticos e Correções Arquiteturais

#### 15.1 DependencyService "Blind Spot" — Apps Não Instalados

**Problema**: Se o RuraRain não está instalado, ele não registra seus DependencyCheckers.
O DependencyService não sabe que Talhão X tem 12 registros de chuva.
Restore do RuraRubber pode deletar Talhão X achando que não tem dependência.

**Solução**: DependencyManifest Persistido

```dart
/// Cada app, ao gravar dados, persiste um manifesto
/// no Hive box compartilhado (acessível por todos os apps)
@HiveType(typeId: XX)
class DependencyManifest {
  @HiveField(0)
  final String appId;           // "rurarain"

  @HiveField(1)
  final Map<String, Set<String>> references;
  // { "talhao": {"tal-001", "tal-002"}, "property": {"prop-001"} }

  @HiveField(2)
  final DateTime updatedAt;     // Última atualização do manifesto
}

/// Ao salvar/deletar qualquer entidade, atualiza manifesto:
Future<void> onSaveChuva(Chuva chuva) async {
  await chuvaBox.put(chuva.id, chuva);
  await DependencyManifestService.instance.addReference(
    appId: 'rurarain',
    targetType: 'talhao',
    targetId: chuva.talhaoId,
  );
}
```

**Regra**: O DependencyService consulta TANTO os checkers registrados
(apps rodando) QUANTO o manifesto persistido (apps não rodando).

---

#### 15.2 Dependências de Movimentações (Denormalização)

**Problema**: Se Entrega referencia Pesagem por ID, e o restore deleta a Pesagem,
a Entrega fica com referência quebrada. Mesmo sendo do mesmo app.

**Solução**: Denormalização no momento da criação

```dart
// ❌ FRÁGIL - Referência por ID que pode quebrar
class Entrega {
  List<String> pesagemIds;  // Se pesagem for deletada, "fura"
}

// ✅ ROBUSTO - Dados copiados na criação
class Entrega {
  List<String> pesagemIds;   // Referência (para navegação)
  double totalPeso;          // Copiado: sum(pesagens.peso)
  int quantidadePesagens;    // Copiado: pesagens.length
  // Entrega é auto-suficiente, não "fura" se pesagem for deletada
}
```

**Princípio**: Movimentações que referenciam outras movimentações
devem copiar os dados essenciais no momento da criação.
A referência por ID é mantida para navegação, mas os dados
de negócio são denormalizados para resiliência.

---

#### 15.3 Farm Restore — Contexto de Fazenda Diferente

**Problema**: Backup foi feito na Farm A, mas dispositivo atual tem Farm B.
O que fazer?

**Solução**: UI de decisão com 3 opções

```
┌──────────────────────────────────────────────────┐
│  ⚠️ Fazenda Diferente Detectada                  │
│                                                    │
│  Backup: "Seringal Santa Fé" (farm-abc123)        │
│  Atual:  "Fazenda Esperança" (farm-xyz789)        │
│                                                    │
│  O que deseja fazer?                               │
│                                                    │
│  ○ Restaurar na fazenda atual ("Fazenda Esperança")│
│    → Dados migrados para farm-xyz789               │
│                                                    │
│  ○ Criar nova fazenda com dados do backup          │
│    → Cria "Seringal Santa Fé" como 2ª fazenda      │
│                                                    │
│  ○ Cancelar                                        │
│                                                    │
│         [Cancelar]         [Confirmar]             │
└──────────────────────────────────────────────────┘
```

**Regra**: NUNCA mesclar silenciosamente. Sempre perguntar ao usuário.

---

#### 15.4 Performance do DependencyChecker (Batch API)

**Problema**: Verificar dependências uma a uma (O(n)) é lento
quando há centenas de talhões/parceiros para verificar.

**Solução**: API batch no DependencyChecker

```dart
class DependencyChecker {
  final String sourceApp;
  final String sourceType;
  final String targetType;
  final String referenceDescription;

  // API individual (mantida para operações pontuais)
  final Future<int> Function(String targetId) countReferences;

  // API batch (nova, para restore/LGPD)
  final Future<Map<String, int>> Function(List<String> targetIds)
      countReferencesBatch;
}

// Uso no restore:
final talhaoIds = backup.talhoes.map((t) => t.id).toList();
final counts = await checker.countReferencesBatch(talhaoIds);
// Retorna: {"tal-001": 45, "tal-002": 0, "tal-003": 12}
// Uma única query em vez de N queries individuais
```

**Implementação sugerida**: Filtro em memória no Hive box
(que já está carregado), ou query batch se migrar para SQLite.

---

#### 15.5 sourceApp — Imutabilidade e Modificação por Outro App

**Problema**: Se RuraCash edita uma Despesa criada pelo RuraRubber,
o sourceApp muda? Quem "owns" a entidade?

**Solução**: sourceApp é IMUTÁVEL

```dart
mixin FarmOwnedMixin {
  /// App que CRIOU o registro. IMUTÁVEL após criação.
  /// Determina quem pode deletar/restaurar este registro.
  String get sourceApp;

  /// OPCIONAL (futuro): Último app que modificou
  /// Apenas para auditoria, não afeta ownership
  // String? get lastModifiedByApp;
}
```

**Regras**:
- `sourceApp` NUNCA muda. Define ownership permanente.
- Se RuraCash edita uma Despesa do RuraRubber, `sourceApp` continua "rurarubber".
- Restore do RuraRubber restaura a Despesa. Restore do RuraCash NÃO toca nela.
- `lastModifiedByApp` é opcional e apenas para trilha de auditoria.

---

### 16. Regras de Ownership e LGPD Multi-User

#### 16.1 Quem Pode Executar Operações LGPD na Farm

**Princípio**: Dados pertencem à FAZENDA (Farm), não ao indivíduo.
Apenas o DONO da fazenda (`farm.ownerId == userId`) tem direito
de executar operações LGPD (delete, export) sobre os dados da fazenda.

```dart
/// Verifica se usuário pode executar LGPD na farm
bool canPerformLgpdOnFarm(Farm farm, String userId) {
  return farm.ownerId == userId;
}
```

#### 16.2 Papéis e Direitos LGPD

| Papel | É Owner? | LGPD Delete Farm Data | LGPD Delete Pessoal | LGPD Export Farm Data | LGPD Export Pessoal |
|-------|----------|-----------------------|---------------------|-----------------------|---------------------|
| **Produtor (Owner)** | ✅ | ✅ Tudo da farm | ✅ | ✅ Tudo da farm | ✅ |
| **Sangrador (vinculado, pode ser Owner)** | ✅/❌ | Se owner: ✅ | ✅ | Se owner: ✅ | ✅ |
| **Gerente** | ❌ NUNCA | ❌ | ✅ | ❌ | ✅ |

**Esclarecimentos**:
- **Gerente NUNCA é Owner** — se fosse, seria Produtor. Gerente administra
  a farm de outro usuário. Não faz sentido ser dono da farm que gerencia.
- **Sangrador pode ser Owner** — cenário simulado quando o produtor não
  controla diretamente e o sangrador quer gerenciar seu próprio app.
  Neste caso, o sangrador É o produtor para fins do sistema.
- **`createdBy` é trilha de auditoria para o Owner**, NÃO dado pessoal
  do funcionário. O Owner vê quem criou cada registro na SUA farm.

#### 16.3 LGPD Delete — O Que Cada Papel Pode Deletar

```
PRODUTOR (Owner):
├─ Pode deletar TODOS os dados da farm (LGPD Art. 18, VI)
├─ Isso inclui dados criados por Gerente e Sangrador
├─ Porque os dados pertencem à FARM, não ao criador
└─ createdBy é auditoria, não ownership

GERENTE (não-owner):
├─ Pode deletar seus DADOS PESSOAIS (login, consentimento, preferências)
├─ NÃO pode deletar dados da farm (pesagens, entregas, etc.)
├─ Mesmo que ele tenha criado (createdBy = gerente)
└─ Porque os dados pertencem à farm do Owner

SANGRADOR (owner do próprio app):
├─ Se farm.ownerId == sangrador.uid → Age como Produtor
├─ Se farm.ownerId != sangrador.uid → Age como Gerente
└─ Determinado em runtime pela comparação farm.ownerId vs userId
```

#### 16.4 Resumo de Decisão

```dart
// Pseudo-código para decisão LGPD
Future<LgpdResult> handleLgpdDelete(String userId) async {
  // 1. Sempre deleta dados pessoais (qualquer papel)
  await deletePersonalData(userId); // login, consent, prefs

  // 2. Verifica ownership para dados da farm
  final farm = await FarmService.instance.getDefaultFarm();
  if (farm != null && farm.ownerId == userId) {
    // Owner: pode deletar tudo da farm
    await deleteFarmData(farm.id, sourceApp: currentAppId);
  } else {
    // Não-owner: informa que dados da farm permanecem
    result.addInfo(
      'Dados da fazenda pertencem ao proprietário e não foram deletados.',
    );
  }

  return result;
}
```

---

### 17. Cross-Reference (Atualizado)

- **CORE-75**: Farm model, FarmOwnedMixin (base para sourceApp)
- **CORE-76**: Safra global (totais por período)
- **CORE-33**: CloudBackupService (implementação atual a ser atualizada)
- **CORE-36**: DataDeletionService (atualizar para multi-app + ownership)
- **CORE-37**: DataExportService (atualizar para multi-app + ownership)
- **RUBBER-XX**: BorrachaBackupProvider (implementar nova interface)
- **RAIN-XX**: ChuvaBackupProvider (implementar nova interface)
- **CROP-XX**: CropBackupProvider (futuro)
- **CASH-XX**: CashBackupProvider (futuro)
- **LGPD Art. 18, V**: Direito à portabilidade dos dados
- **LGPD Art. 18, VI**: Direito à eliminação dos dados

---

## Phase CORE-76: Safra Global + Ciclos de Cultura (Suporte RuraCrop)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL (Futuro - RuraCrop)
**Objective**: Implementar modelo de Safra como "Ano Agrícola" global e Ciclos para agricultura anual.

### Contexto de Negócio

A Safra é o "guarda-chuva temporal" de todos os apps:

```
Safra Global (agro_core)
└── "Safra 2025/2026" (Set/2025 - Ago/2026)
    ├── RuraRubber: Pesagens de borracha (perene, sem ciclos)
    ├── RuraCattle: Movimentações de gado (perene, sem ciclos)
    └── RuraCrop: Ciclos de Cultura (anual, múltiplos ciclos)
        ├── Ciclo 1: Soja (Verão) - Talhão 1
        ├── Ciclo 2: Milho Safrinha - Talhão 1
        └── Ciclo 1: Soja (Verão) - Talhão 2
```

### Diferença: Safra vs Ciclo

| Conceito | Quem Usa | Descrição |
|----------|----------|-----------|
| **Safra** | Todos os apps | Ano agrícola (Set-Ago), janela de tempo |
| **Ciclo** | Apenas RuraCrop | Instância de cultura em um talhão |

### Modelo de Dados

```dart
/// Safra Global - Ano Agrícola (agro_core)
@HiveType(typeId: 21)
class Safra {
  @HiveField(0)
  String id;

  @HiveField(1)
  String farmId;           // UUID da Farm

  @HiveField(2)
  String nome;             // "Safra 2025/2026"

  @HiveField(3)
  DateTime dataInicio;     // 01/09/2025

  @HiveField(4)
  DateTime? dataFim;       // 31/08/2026 (null = em aberto)

  @HiveField(5)
  bool ativa;              // true se for a safra atual

  // NOTA: Totais são CALCULADOS via query, não armazenados!
  // Cada app calcula seus totais com WHERE data BETWEEN inicio AND fim
}
```

### Arquitetura: Query-Based (Não Acumulador)

**Princípio**: Não salvamos totais fixos. Salvamos registros individuais.
O total é **calculado na hora** via query.

```dart
// ✅ CORRETO - Query dinâmica por período
Future<double> getTotalKg(String safraId) async {
  final safra = await getSafra(safraId);
  return pesagens
      .where((p) => p.data >= safra.dataInicio && p.data < safra.dataFim)
      .fold(0.0, (sum, p) => sum + p.peso);
}

// ❌ ERRADO - Total fixo que "fura" se editar pesagem antiga
// safra.totalKg = 15400;
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 76.1 | **Modelo Safra**: Entidade com Hive adapter (typeId: 21) | ⏳ TODO |
| 76.2 | **SafraService**: CRUD + auto-criar em Setembro + getAtiva() | ⏳ TODO |
| 76.3 | **SafraChip Widget**: Chip compacto para header ("25/26") | ⏳ TODO |
| 76.4 | **Encerrar Safra**: Define dataFim e cria nova automaticamente | ⏳ TODO |
| 76.5 | **Query Helpers**: Métodos para filtrar por período da safra | ⏳ TODO |

### Files to Create

| File | Action | Description |
|------|--------|-------------|
| `lib/models/safra.dart` | CREATE | Modelo Safra com Hive adapter |
| `lib/services/safra_service.dart` | CREATE | Gestão de safras |
| `lib/widgets/safra_chip.dart` | CREATE | Chip para header |
| `lib/widgets/safra_bottom_sheet.dart` | CREATE | Seletor de safra |

### L10n Keys Required
- `safraGlobal`: "Safra"
- `safraAtiva`: "Safra Ativa"
- `safraChipLabel`: "{ano1}/{ano2}"
- `encerrarSafra`: "Encerrar Safra"
- `novaSafraCriada`: "Nova safra criada: {nome}"
- `safraAnterior`: "Safras Anteriores"

### Cross-Reference
- **RUBBER-17**: Usa Safra para controle de produção
- **CROP-01**: Ciclos vinculados à Safra
- **CASH-04**: DRE por Safra
- **CATTLE-XX**: Movimentações por Safra

---

## Phase CORE-67: Profile Display in AgroDrawer

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟢 ENHANCEMENT
**Objective**: Display the user's selected profile type (Producer/Tapper/Buyer) in the drawer header to provide visual feedback of current context.

### Problem
After selecting a profile in RuraRubber (or future apps with profiles), users have no visual indication of their current role when viewing the drawer menu. This can cause confusion about which features are available.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 67.1 | Add optional `profileWidget` or `profileName` parameter to `AgroDrawer` | ✅ DONE |
| 67.2 | Display profile badge/chip below app name in drawer header | ✅ DONE |
| 67.3 | Update l10n strings for profile display | ⏫ SKIPPED (not needed - profile name comes from app) |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/menu/agro_drawer.dart` | MODIFY | Added `profileName` and `profileWidget` parameters |

### Usage Example

```dart
// Simple profile name (displays as chip)
AgroDrawer(
  appName: 'RuraRubber',
  profileName: 'Produtor',  // Shows chip in header
  onNavigate: _handleNavigation,
)

// Custom profile widget
AgroDrawer(
  appName: 'RuraRubber',
  profileWidget: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.agriculture, size: 16),
      SizedBox(width: 4),
      Text('Produtor'),
    ],
  ),
  onNavigate: _handleNavigation,
)
```

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

### Problem
1. 0.1mm precipitation was labeled "Chovendo agora" when it should be "Garoando" (drizzle)
2. No differentiation between light, moderate, and heavy rain
3. Hourly forecast didn't show precipitation amounts

### Solution
1. Added `PrecipIntensity` enum with thresholds (none, drizzle, light, moderate, heavy)
2. Added new l10n strings for each intensity level
3. Modified `getStatusMessage()` to return appropriate description based on intensity
4. Added `precipitation` to hourly API request
5. Modified weather detail screen to show hourly precipitation amounts

### Precipitation Thresholds (per 15 minutes)
- < 0.1 mm = none
- 0.1 - 0.5 mm = drizzle (garoa)
- 0.5 - 2.0 mm = light rain (chuva fraca)
- 2.0 - 5.0 mm = moderate rain (chuva moderada)
- > 5.0 mm = heavy rain (chuva forte)

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

### Problem
1. When restoring from backup, existing data was merged with backup data instead of being replaced
2. After restore, the main screen didn't refresh - showed old data until manual navigation

### Solution
1. Modified all BackupProvider implementations to clear existing data before importing:
   - `PropertyBackupProvider`: Added `clearAllForUser()` to PropertyService
   - `ChuvaBackupProvider`: Added `limparTodos()` to ChuvaService
   - `BorrachaBackupProvider`: Added `clearAll()` to ParceiroService and EntregaService
2. Added `onRestoreComplete` callback to `AgroSettingsScreen` to notify when restore finishes

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
1. **Fixed Red Screen Error**: Added guard for empty frames list in `_buildRadarControls()` to prevent index out of bounds error when satellite data is unavailable
2. **Default Map Type**: Changed default map type from satellite to normal (road map)
3. **Reorganized Layer Buttons**: New order:
   - Community (measured rainfall data)
   - Radar (precipitation)
   - Cloud (satellite infrared)
   - Rain/Snow mode (when radar selected)
   - Normal map (road) - now first
   - Satellite map
4. **Added tooltips**: All layer buttons now have proper tooltips using existing l10n strings

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 62.1 | Add empty frames guard to prevent crash | ✅ DONE |
| 62.2 | Change default MapType to normal | ✅ DONE |
| 62.3 | Reorganize button order | ✅ DONE |
| 62.4 | Add radarNoData l10n string | ✅ DONE |

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

### Problem
When user logged in with Google:
1. `_handleLoginSuccess()` in main.dart set `consentCloudBackup = true` before ConsentScreen
2. `setConsent()` also updates `consentTimestamp` as a side effect
3. ConsentScreen's initState checked `consentTimestamp != null` → thought user already made choices
4. Loaded values from store: `cloudBackup=true, social=false, aggregate=false`
5. This made `_hasAnyConsent = true` (checkbox already marked)
6. Clicking "Accept All" went to Scenario B (save current values) instead of Scenario A
7. Result: Only cloudBackup was true, all other consents stayed false
8. Location prompt never appeared because aggregateMetrics was false

### Solution
Changed ConsentScreen's initState to use `isOnboardingCompleted()` as source of truth instead of `consentTimestamp`:
- If `isOnboardingCompleted() == true`: User has completed consent screen before → load saved values
- If `isOnboardingCompleted() == false`: First time user → start with all checkboxes unchecked

The key insight is that `consentTimestamp` can be set by implicit consents (like cloudBackup from login), but `onboardingCompleted` is ONLY set when user actually finishes ConsentScreen.

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 61.1 | Fix initState to use isOnboardingCompleted() instead of timestamp | ✅ DONE |

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

### Problem
When user clicked on location in Home without consent:
1. LocationHelper opened ConsentScreen
2. User accepted consents
3. ConsentScreen called LocationHelper again (recursion)
4. Dialog showed in wrong context, then ConsentScreen closed
5. Original LocationHelper tried to show dialog with invalid context

### Solution
Added `skipLocationPrompt` parameter to ConsentScreen. When opened by LocationHelper, this flag prevents ConsentScreen from calling LocationHelper again, avoiding recursion.

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 60.1 | Add `skipLocationPrompt` parameter to ConsentScreen | ✅ DONE |
| 60.2 | Update LocationHelper to pass `skipLocationPrompt: true` | ✅ DONE |
| 60.3 | Replace `print` with `debugPrint` in LocationHelper | ✅ DONE |
| 60.4 | Add debug logs to track consent persistence issues | ✅ DONE |

### Files Modified
| File | Action | Description |
|------|--------|-------------|
| `lib/privacy/consent_screen.dart` | MODIFY | Add skipLocationPrompt parameter, add debug logs |
| `lib/utils/location_helper.dart` | MODIFY | Pass skipLocationPrompt, fix print statements |
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Add debug logs to acceptAllConsents and syncConsentsToCloud |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Add debug log to _loadConsents |

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
| 57.5 | Unit Tests for Alert Logic | ⏩ SKIPPED |

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
**Objective**: Integrate real-time weather radar (REDEMET/RainViewer) into the map to visualize actual precipitation and cloud movement (Past/Present/Future).

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

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 53.1 | Create `ComparativeStatsHelper` logic | ✅ DONE |
| 53.2 | Update `EstatisticasScreen` to use TabBarView | ✅ DONE |
| 53.3 | Implement `ComparacaoAnualChart` using `fl_chart` | ✅ DONE |
| 53.4 | Add localized strings | ✅ DONE |

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
**Objective**: Boost user engagement and brand awareness by enabling sharing of rainfall data on social networks.

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 52.1 | Create `RainCardWidget` (UI for capture) | ✅ DONE |
| 52.2 | Implement `ShareService` with screenshot logic | ✅ DONE |
| 52.3 | Add Share button to `RegistroChuvasTile` | ✅ DONE |
| 52.4 | Add Share button to `EditarChuvaScreen` | ✅ DONE |

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

### Implementation Summary
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 51.1 | Add `home_widget` dependency | ✅ DONE |
| 51.2 | Implement `HomeWidgetService` in `agro_core` | ✅ DONE |
| 51.3 | Create Android Layout (`widget_layout.xml`) | ✅ DONE |
| 51.4 | Implement `RainWidgetProvider.kt` | ✅ DONE |
| 51.5 | Update `ChuvaService` to sync data | ✅ DONE |

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
| 46.8 | **UX**: Request Notification Permission in `ConsentScreen` (Onboarding) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/notification_service.dart` | CREATE | AgroNotificationService (Local) |
| `lib/services/background_service.dart` | CREATE | Background logic (Hive/Weather check) |
| `lib/screens/agro_settings_screen.dart` | MODIFY | Add Rain Alerts toggle |
| `lib/privacy/consent_screen.dart` | MODIFY | Request permissions after consent |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add Alert strings |
| `pubspec.yaml` | MODIFY | Add workmanager dependency |

### App Integration Required

Apps using this feature must add to their `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

---

## Phase CORE-44: Collaborative Rain Heatmap

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Display a visual heatmap of community-reported rain intensity on a Google Map.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 44.1 | Research heatmap plugins (flutter_heatmap incompatible) | ✅ DONE |
| 44.2 | Implement `HeatmapService` (Mock logic removed for release) | ✅ DONE |
| 44.3 | Implement `RainHeatmapScreen` (Circles overlay) | ✅ DONE |
| 44.4 | Add L10n strings and export screen | ✅ DONE |
| 44.5 | Add drawer route key (`heatmap`) | ✅ DONE |
| 44.6 | Fix null safety: check property.hasLocation | ✅ DONE |
| 44.7 | **UX**: Show "No data" SnackBar if empty | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/heatmap_service.dart` | CREATE | Community rain data service |
| `lib/screens/rain_heatmap_screen.dart` | CREATE | Map with Circle overlays |
| `lib/menu/agro_drawer_item.dart` | MODIFY | Add heatmap route key |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add Heatmap strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add Heatmap strings |

---

## Phase CORE-45: Property Location UX Polish

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 UX POLISH
**Objective**: Improve the location setup flow for properties, ensuring seamless integration with onboarding and intuitive editing.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 45.1 | Extract location logic to `LocationHelper` | ✅ DONE |
| 45.2 | Trigger "Are you here?" prompt after "Accept All" in Onboarding | ✅ DONE |
| 45.3 | Make Property Name in `WeatherDetailScreen` clickable to edit location | ✅ DONE |
| 45.4 | Refactor `WeatherCard` location handling | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/utils/location_helper.dart` | CREATE | Centralized location logic |
| `lib/widgets/weather_card.dart` | MODIFY | Use LocationHelper, remove dup logic |
| `lib/privacy/consent_screen.dart` | MODIFY | Trigger location check after consent |
| `lib/screens/weather_detail_screen.dart` | MODIFY | Clickable AppBar property name |

---

## Phase CORE-43: Advanced Weather - Nowcasting

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟢 ENHANCEMENT
**Objective**: Provide immediate "minutely" rain forecasts (Nowcasting) for the next hour.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 43.1 | Update `WeatherForecast` model for minutely data | ✅ DONE |
| 43.2 | Update `WeatherService` to fetch `minutely_15` API | ✅ DONE |
| 43.3 | Create `MinutelyForecastWidget` UI | ✅ DONE |
| 43.4 | Integrate Nowcasting into `WeatherCard` | ✅ DONE |

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

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 42.1 | Add `google_maps_flutter`, remove `flutter_map` | ✅ DONE |
| 42.2 | Implement `LocationPickerScreen` with Google Maps | ✅ DONE |
| 42.3 | Configure Hybrid Map Type (Satellite + Labels) | ✅ DONE |
| 42.4 | Direct Navigation from WeatherCard to Map | ✅ DONE |

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
