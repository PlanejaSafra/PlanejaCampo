# ARCHITECTURE.md - RuraCamp Monorepo

> Documento de referência para a arquitetura do ecossistema RuraCamp.
> Descreve padrões obrigatórios, estratégia de dados e preparações para multi-user.

---

## 1. Visão Geral

O RuraCamp é um ecossistema de micro-apps agrícolas que compartilham um core comum (`agro_core`). Todos operam **offline-first** com Hive como banco principal e backup opcional em nuvem (Firebase).

### Princípios Fundamentais

- **Offline-first**: O dado mestre é sempre o do dispositivo local (Hive)
- **Farm-centric**: Todos os dados pertencem a uma fazenda, não ao usuário individual
- **sourceApp isolation**: Cada app marca e gerencia apenas seus próprios dados
- **LGPD compliance**: Direito ao esquecimento com verificação de ownership
- **Zero subcoleções**: Estrutura flat em todas as coleções/boxes

---

## 2. Atributos Obrigatórios por Entidade (CORE-77)

Toda entidade de negócio (registros de chuva, pesagens, entregas, etc.) **DEVE** possuir os seguintes atributos para garantir backup correto, isolamento multi-app e conformidade LGPD:

### 2.1. Campos Obrigatórios

| Campo | Tipo | Descrição | Preenchimento |
|-------|------|-----------|---------------|
| `farmId` | String | UUID da fazenda/propriedade dona do dado | Automático via `FarmService.instance.defaultFarmId` ou `PropertyService().defaultProperty?.id` |
| `createdBy` | String | Firebase Auth UID de quem criou o registro | Automático via `AuthService.currentUser?.uid` |
| `createdAt` | DateTime | Data/hora de criação do registro | Automático via `DateTime.now()` na factory |
| `sourceApp` | String | Identificador imutável do app criador | Fixo: `"rurarubber"`, `"rurarain"`, etc. |

### 2.2. Regras de Imutabilidade

- **sourceApp NUNCA muda** após criação. Se outro app edita o registro, o sourceApp permanece o do criador original.
- **createdBy NUNCA muda** após criação. É uma trilha de auditoria para o dono da fazenda.
- **farmId** pode mudar apenas em cenários de transferência de propriedade (futuro).

### 2.3. Implementação

Existem duas formas de implementar:

| Tipo | Quando usar | Requisito |
|------|-------------|-----------|
| **FarmOwnedEntity** (interface) | Entidades com `id` do tipo String | Exige `String get id` |
| **FarmOwnedMixin** (mixin) | Entidades com `id` de outro tipo (int, etc.) | Sem requisito de id |

Cada modelo deve fornecer:
- Uma **factory** (ex: `.create()`) que preenche automaticamente farmId, createdBy, createdAt e sourceApp
- Métodos **toJson/fromJson** que incluem todos os 4 campos
- **HiveFields** dedicados para cada campo

### 2.4. Mapeamentos Permitidos

Quando um modelo já possui campos equivalentes, pode-se usar getters para mapear:

| Modelo | Campo existente | Mapeado para |
|--------|----------------|--------------|
| RegistroChuva | `propertyId` | `farmId` (via getter) |
| RegistroChuva | `criadoEm` | `createdAt` (via getter) |

---

## 3. Estratégia de Dados (Offline-First)

### 3.1. Armazenamento Local (Hive)

- **Principal (Hot Storage)**: Todo o funcionamento depende exclusivamente do Hive local
- **Adapters**: Gerados via `build_runner` (comando: `dart run build_runner build --delete-conflicting-outputs`)
- **Boxes**: Abertos durante a inicialização no `main.dart`
- **Regra flat**: Nunca usar subcoleções ou boxes aninhados

### 3.2. Backup na Nuvem (Firebase)

| Componente | Função |
|------------|--------|
| **CloudBackupService** | Orquestra backup/restore de todos os providers |
| **BackupProvider** | Interface básica (getData/restoreData) |
| **EnhancedBackupProvider** | Interface avançada com restore em 3 fases |
| **PropertyBackupProvider** | Backup de propriedades (registrado primeiro) |
| **App-specific providers** | ChuvaBackupProvider, BorrachaBackupProvider, etc. |

### 3.3. Restore em 3 Fases (CORE-77)

| Fase | Método | Descrição |
|------|--------|-----------|
| **1. Análise** | `analyzeRestore()` | Compara backup vs dados locais, verifica ownership, gera relatório de ações |
| **2. Confirmação** | `RestoreConfirmationDialog` | Mostra ao usuário o que será adicionado, removido e protegido |
| **3. Execução** | `executeRestore()` | Aplica as mudanças: deleta apenas dados do mesmo sourceApp, importa novos |

### 3.4. Isolamento por sourceApp no Restore

Durante o restore, o sistema **NUNCA** apaga dados de outros apps:

- **DELETE**: Apenas registros onde `sourceApp == appAtual`
- **INSERT**: Novos registros do backup (com sourceApp preservado)
- **PRESERVA**: Dados de outros apps permanecem intactos

Exemplo: Se o RuraRubber fizer restore, dados do RuraRain na mesma fazenda **não são afetados**.

---

## 4. Modelo Multi-User (Preparação)

### 4.1. Farm-Centric Model (CORE-75, CORE-88)

- Dados pertencem à **fazenda** (via farmId), não ao usuário
- O modelo `Farm` no agro_core armazena: id, name, ownerId, createdAt, subscriptionTier, isShared
- `Farm.isShared` (CORE-88): Quando `true`, ativa Tier 3 sync (GenericSyncService envia dados para Firestore)
- `FarmService` gerencia ciclo de vida: criação, lookup, default farm, `isActiveFarmShared()`, `setFarmShared()`
- `FarmAdapter` registrado no Hive de cada app
- **Futuro**: Farm Switcher para alternar entre fazenda própria e fazendas vinculadas (colaborador)

### 4.2. Ownership Rules (CORE-77 Section 16)

| Papel | Direitos LGPD | Backup | Restore | Delete |
|-------|---------------|--------|---------|--------|
| **Owner (Produtor)** | Full | Pode fazer backup da fazenda | Restore completo | Delete completo |
| **Member (Gerente)** | Limitado | Apenas dados pessoais | Apenas dados pessoais | Apenas dados pessoais |
| **Sangrador** | Limitado | Apenas dados pessoais | Apenas dados pessoais | Apenas dados pessoais |

### 4.3. Auditoria (createdBy)

O campo `createdBy` é uma **trilha de auditoria** para o dono da fazenda:
- O owner vê quem criou cada registro
- Funcionários NÃO podem deletar esse campo (pertence ao owner)
- Funcionário pode sair da fazenda, mas registros permanecem (pertencem à fazenda)

---

## 5. LGPD (Lei Geral de Proteção de Dados)

### 5.1. Deletion Service (CORE-77)

| Componente | Função |
|------------|--------|
| **DataDeletionService** | Orquestra deleção LGPD de todos os providers |
| **AppDeletionProvider** | Interface por app (deleteAppData, deletePersonalData) |
| **DependencyService** | Verifica dependências cross-app antes de deletar |
| **LgpdDeletionResult** | Resultado com contagens de deletados, protegidos e erros |

### 5.2. Tipos de Deleção

| Tipo | Quem solicita | O que deleta |
|------|---------------|-------------|
| **deleteAllUserData** | Qualquer usuário | Conta Firebase + todos os dados Hive + Firestore |
| **deleteAppDataForFarm** | Owner da fazenda | Apenas dados do app específico naquela fazenda |
| **deletePersonalDataOnly** | Membro (não-owner) | Dados pessoais (preferências), NÃO dados da fazenda |

### 5.3. Proteção de Dependências

Antes de deletar uma entidade, o `DependencyService` verifica:
- Se outro app depende desse registro
- Se a deleção quebraria integridade referencial
- Registros protegidos são **ignorados** (não deletados), e o resultado informa ao usuário

---

## 6. Dependency Service (CORE-77)

### 6.1. DependencyManifest

Armazena relações entre entidades de diferentes apps. Usado para:
- Verificar se um registro pode ser deletado
- Identificar impactos cross-app antes de restore
- Prevenir perda de dados por deleção indevida

### 6.2. Registro

Cada app registra suas dependências no `main.dart`:
- `DependencyManifestAdapter` registrado no Hive
- `DependencyService.instance.init()` chamado na inicialização

---

## 7. Backup Metadata (BackupMeta)

Todo backup contém um header `_meta` com:

| Campo | Descrição |
|-------|-----------|
| `appId` | App que gerou o backup |
| `appVersion` | Versão do app no momento do backup |
| `backupType` | "app" (single app) ou "full" (todos) |
| `backupScope` | "personal" (dados do usuário) ou "full" (toda a fazenda) |
| `farmId` | Fazenda dos dados |
| `userId` | Quem criou o backup |
| `createdAt` | Quando foi criado |
| `schemaVersion` | Versão do schema para migração |

### Validação no Restore

Antes de restaurar, o sistema valida:
- `appId` corresponde ao app atual
- `schemaVersion` não é mais novo que o suportado
- `farmId` corresponde a uma fazenda acessível pelo usuário

---

## 8. Inicialização Obrigatória (main.dart)

Todo app deve inicializar os seguintes componentes na ordem correta:

| Ordem | Componente | Método |
|-------|-----------|--------|
| 1 | Hive | `Hive.initFlutter()` |
| 2 | Hive Adapters | `registerAdapter()` para todos os models + Farm + DependencyManifest + **Sync Adapters** |
| 3 | Privacy Store | `AgroPrivacyStore.init()` |
| 4 | Firebase | `Firebase.initializeApp()` (nativo para Android/iOS, `DefaultFirebaseOptions` para desktop/web) |
| 5 | App Check | `FirebaseAppCheck.instance.activate()` envolvido em `if (!kDebugMode)` |
| 6 | Data Migration | `DataMigrationService.instance.runMigrations()` |
| 7 | Cloud Service | `UserCloudService.instance.init()` |
| 8 | Backup Providers | `CloudBackupService.instance.registerProvider(...)` |
| 9 | Deletion Providers | `DataDeletionService.instance.registerDeletionProvider(...)` |
| 10 | Farm Service | `FarmService.instance.init()` |
| 11 | Dependency Service | `DependencyService.instance.init()` |
| 12 | App Services | PropertyService, TalhaoService, etc. |
| 13 | AdMob | `AgroAdService.instance.initialize()` |

### 8.1. Sync Adapters Obrigatórios (CORE-84)

Todo app que usa `GenericSyncService` com `syncEnabled => true` **DEVE** registrar os 3 adapters de sync:

```dart
Hive.registerAdapter(OfflineOperationAdapter());
Hive.registerAdapter(OperationTypeAdapter());
Hive.registerAdapter(OperationPriorityAdapter());
```

Estes são necessários porque o `OfflineQueueManager` persiste objetos `OfflineOperation` no Hive. Sem estes adapters, qualquer operação de sync causa `HiveError: Cannot write, unknown type`.

### 8.2. Firebase Init Pattern (CORE-84)

```dart
if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} else {
  // Android/iOS: native config (google-services.json / GoogleService-Info.plist)
  await Firebase.initializeApp();
}
```

---

## 9. Fases do agro_core Implementadas

| Fase | Nome | Status | Descrição |
|------|------|--------|-----------|
| CORE-75 | Farm-Centric Model | DONE | Modelo Farm, FarmService, FarmAdapter para multi-user |
| CORE-77 | Dependency-Aware Backup | DONE | EnhancedBackupProvider, 3-phase restore, sourceApp isolation, DependencyService, AppDeletionProvider, BackupMeta, RestoreAnalysis, LgpdDeletionResult |
| CORE-78 | GenericSyncService | DONE | Infraestrutura offline-first unificada: GenericSyncService, OfflineQueueManager, LocalCacheManager, DataIntegrityManager, SyncConfig |
| CORE-83 | Migration to GenericSyncService | DONE | Migração de todos os services dos apps para GenericSyncService |
| CORE-84 | Sync Infrastructure Fixes | DONE | Adapter registration, processQueue logging, _save error handling, property prompt fix, App Check debug guard, 61 unit tests |
| CORE-85 | Remove misleading "Delete Cloud Data" | DONE | Removido botão incompleto de Settings, melhorado dialog de exclusão em Privacy |
| CORE-86 | Owner-Based Settings Visibility | DONE | isOwner flag em AgroSettingsScreen/AgroPrivacyScreen para controle de visibilidade |
| CORE-87 | Auto-Backup UX | DONE | Switch de auto-backup no card de Cloud Backup |
| CORE-88 | Data Tier Architecture | DONE | Farm.isShared, GenericSyncService Tier 3 gate, FarmService helpers |
| CORE-92 | L10n Default Name Keys + Missing Export Strings | DONE | ARB keys para nomes padrão de farms + fix exportDataSuccess/Error |

### Integração nos Apps

| App | Fase | Status | Descrição |
|-----|------|--------|-----------|
| RuraRubber | RUBBER-24 | DONE | FarmOwnedEntity em Parceiro/Entrega, BorrachaBackupProvider, BorrachaDeletionProvider |
| RuraRubber | RUBBER-25 | DONE | Migração de 5 services para GenericSyncService |
| RuraRubber | RUBBER-26 | DONE | Sync adapters, App Check, Property Name Gate, Firebase init nativo |
| RuraRubber | RUBBER-27 | DONE | Owner-Based Settings: isOwner via FarmService/AuthService |
| RuraRubber | RUBBER-28 | DONE | Code quality: fix static_access_to_instance_member, unnecessary imports, missing @override |
| RuraRubber | RUBBER-29 | DONE | L10n hardcoded default names fix: "Meu Seringal", "Seringal" → l10n keys |
| RuraRain | RAIN-03 | DONE | FarmOwnedMixin em RegistroChuva, ChuvaBackupProvider, ChuvaDeletionProvider |
| RuraRain | RAIN-04 | DONE | ChuvaService migrado para GenericSyncService |
| RuraRain | RAIN-05 | DONE | Sync adapter registration |
| RuraRain | RAIN-06 | DONE | Sync adapters + Firebase init nativo |
| RuraRain | RAIN-07 | DONE | Owner-Based Settings: isOwner via FarmService/AuthService |
| RuraRain | RAIN-08 | DONE | Tier 2 Statistics Sync: fix queueForSync bug, integrate Tier 2 in ChuvaService.adicionar/atualizar |
| RuraCash | CASH-05 | DONE | Migração de services para GenericSyncService |
| RuraCash | CASH-06 | DONE | Sync adapter registration |
| RuraCash | CASH-07 | DONE | Architecture alignment: gen-l10n, syncEnabled=false, dead code fix, code quality |
| RuraCattle | - | TODO | Aguardando implementação |
| RuraFuel | - | TODO | Aguardando implementação |

---

## 10. Checklist para Novo App ou Nova Entidade

### Nova Entidade de Negócio

- [ ] Adicionar campos: farmId, createdBy, createdAt, sourceApp como HiveFields
- [ ] Implementar FarmOwnedEntity (se id é String) ou FarmOwnedMixin (se id é outro tipo)
- [ ] Criar factory `.create()` que preenche metadata automaticamente
- [ ] Implementar `toJson()` e `fromJson()` incluindo os 4 campos
- [ ] Rodar `dart run build_runner build --delete-conflicting-outputs`
- [ ] Atualizar EnhancedBackupProvider para incluir a nova entidade
- [ ] Atualizar AppDeletionProvider para deletar a nova entidade

### Novo App

- [ ] Registrar FarmAdapter e DependencyManifestAdapter no Hive
- [ ] Registrar OfflineOperationAdapter, OperationTypeAdapter, OperationPriorityAdapter no Hive (CORE-84)
- [ ] Inicializar Firebase com pattern nativo (Android/iOS) vs DefaultFirebaseOptions (desktop/web)
- [ ] Adicionar App Check com guard `if (!kDebugMode)` (CORE-84)
- [ ] Inicializar FarmService e DependencyService no main.dart
- [ ] Criar BackupProvider implementando EnhancedBackupProvider
- [ ] Criar DeletionProvider implementando AppDeletionProvider
- [ ] Registrar providers no CloudBackupService e DataDeletionService
- [ ] Garantir que todas as entidades usam sourceApp = "nomedoapp"
- [ ] Adicionar Property Name Gate no fluxo de navegação (CORE-84)

---

## 11. GenericSyncService (CORE-78)

> **Status**: Implementado e testado (61 unit tests)
> **Propósito**: Infraestrutura unificada para serviços offline-first com sincronização opcional.

### 11.1. Visão Geral

O `GenericSyncService` é uma classe base abstrata que elimina a duplicação de códido nos serviços de dados (Repositories/Services). Ele encapsula:
- **CRUD Local**: Operações Hive padronizadas
- **Sync Opcional**: Sincronização automática com Firestore (se ativado)
- **Fila Offline**: Enfileiramento de operações quando sem internet
- **Integridade**: Validação de dados via Hash SHA256 e detecção de conflitos

### 11.2. Arquitetura em Camadas

```mermaid
graph TD
    A[App Service] -->|extends| B[GenericSyncService<T>]
    B --> C[LocalCacheManager]
    B --> D[OfflineQueueManager]
    B --> E[DataIntegrityManager]
    C -->|Leitura/Escrita| F[(Hive Local)]
    D -->|Fila de Ops| F
    D -->|Sync (Online)| G[(Firestore)]
    B -->|Background Sync| G
```

### 11.3. Fluxo de Operações

#### Escrita (Create/Update/Delete)
1. **Local First**: Salva imediatamente no Hive (UI reage instantaneamente).
2. **Metadata**: Adiciona/atualiza metadados (`version`, `hash`, `syncStatus='pending'`).
3. **Check Conectividade**:
   - **Offline**: Adiciona operação à `OfflineQueueManager` (persistida no Hive).
   - **Online**: Tenta enviar para Firestore imediatamente.
     - Sucesso: Atualiza `syncStatus='synced'`.
     - Falha: Move para fila offline com `retryCount`.

#### Leitura (Read)
1. **Cache First**: Retorna dados do Hive imediatamente.
2. **Background Sync** (Se online e debounced):
   - Consulta Firestore por atualizações (`updatedAt > lastSyncAt`).
   - Se houver mudanças, atualiza cache e notifica listeners (`notifyListeners`).

### 11.4. Resolução de Conflitos

- **Server-Wins** (Padrão): Se servidor tem versão mais nova, sobrescreve local.
- **Detecção**: Baseada em `version` e `hash` do documento.
- **Integridade**: `DataIntegrityManager` verifica hashes para garantir que dados não foram corrompidos no transporte.

### 11.5. Benefícios para os Apps

1. **Redução de Código**: Services caem de ~150 linhas para ~30 linhas.
2. **Sync Inteligente**: O `OfflineQueueManager` usa `connectivity_plus` para monitorar a rede. Uploads são pausados automaticamente quando offline e retomados quando o Wi-Fi/Dados volta.
3. **Resolução de Conflitos Simplificada**: Estratégia "Server Wins" por padrão. O uso de `FieldValue.serverTimestamp()` garante que a ordem cronológica de chegada no servidor seja a fonte da verdade. manual conflict resolution was removed to simplify UX.

---

## 12. Análise de Decisões e Limitações (CORE-78)

> **Contexto**: Implementação do `GenericSyncService` no `agro_core`.

### 12.1. Acoplamento do Firestore (Phantom Coupling)
- **Problema**: O pacote `agro_core` depende de `cloud_firestore`. Apps "Offline-Only" (como RuraCash atual) carregam a dependência binária mesmo sem usá-la.
- **Decisão**: Aceitável em prol da padronização e reuso de código.
- **Mitigação**:
  - `GenericSyncService.syncEnabled` atua como feature flag.
  - Apps que não usam sync não devem inicializar `Firebase.initializeApp()` no `main.dart`.
  - O código de sync só é executado se a flag estiver ativa.

### 12.2. Performance de Query (Hive in Memory)
- **Problema**: `GenericSyncService.getByAttributes` e filtros realizam iteração em memória (O(N)).
- **Impacto**: Imperceptível para o volume alvo (Pequenas/Médias propriedades, < 5.000 registros).
- **Limite**: Pode engasgar com "Big Data" (> 50.000 itens).
- **Plano Futuro**: Se necessário, migrar storage local para `LazyBox` ou SQLite (Drift).

### 12.3. Sincronização e Relógio (Clock Skew)
- **Problema**: Delta Sync baseia-se em timestamps gerados pelo cliente (`DateTime.now()`). Relógios desajustados podem causar perda de dados ou conflitos.
- **Decisão**: Aceitável para o MVP e cenários onde o usuário mantém o horário automático.
- **Plano Futuro**: Implementar `FieldValue.serverTimestamp()` do Firestore para garantir a "hora da verdade" no servidor, independente do cliente.

---

## 13. Data Tier Architecture (CORE-88)

> **Status**: Implementado
> **Propósito**: Controle granular de quais dados são enviados ao Firestore, em quais circunstâncias, e por qual serviço.

### 13.1. Visão Geral

Nem todos os dados têm o mesmo nível de sensibilidade ou necessidade de sincronização. O RuraCamp define 4 tiers de dados no Firestore, cada um com sua própria gate (condição de ativação) e serviço responsável.

### 13.2. Tiers de Dados

| Tier | Coleções Firestore | Gate (Condição) | Serviço | Quando Sincroniza |
|------|-------------------|-----------------|---------|-------------------|
| **Tier 0** | `users` | Sempre (aceitar termos) | `UserCloudService` | Ao aceitar termos de uso; consents, preferências, lastActive |
| **Tier 1** | `user_backups`, `user_backup_chunks` | `consentCloudBackup` | `CloudBackupService` | Backup manual ou automático (se consent ativo) |
| **Tier 2** | `rainfall_data`, `rainfall_stats` | `consentAggregateMetrics` | `SyncService` (app-specific) | Dados anonimizados para estatísticas regionais |
| **Tier 3** | Todas as coleções via GenericSyncService | `farm.isShared` | `GenericSyncService` | Apenas quando licença multi-user é ativada na fazenda |

### 13.3. Detalhamento dos Tiers

#### Tier 0 — Dados do Usuário (Obrigatório)
- **Coleção**: `users/{uid}`
- **Conteúdo**: Consents, preferências de sync, timestamps, device info
- **Gate**: Implícita — aceitar termos de uso já autoriza
- **Controlado por**: `UserCloudService`
- **Nota**: Único tier que sincroniza sem consent explícito adicional

#### Tier 1 — Backup na Nuvem (Consent Explícito)
- **Coleções**: `user_backups/{uid}`, `user_backup_chunks/{uid}_chunk_{n}`
- **Conteúdo**: Snapshot completo dos dados locais (properties, registros, etc.)
- **Gate**: `AgroPrivacyStore.consentCloudBackup == true`
- **Controlado por**: `CloudBackupService` com `BackupProvider`/`EnhancedBackupProvider`
- **Nota**: Login com Google implica consent para Cloud Backup (termos de uso)

#### Tier 2 — Métricas Agregadas (Consent Explícito)
- **Coleções**: `rainfall_data`, `rainfall_stats` (app-specific)
- **Conteúdo**: Dados anonimizados (sem identificação pessoal) para estatísticas regionais
- **Gate**: `AgroPrivacyStore.consentAggregateMetrics == true`
- **Controlado por**: `SyncService` específico do app (ex: RuraRain)
- **Nota**: Dados são anonimizados antes do envio; o usuário pode revogar a qualquer momento

#### Tier 3 — Sync Completo Multi-User (Licença)
- **Coleções**: Todas as coleções gerenciadas por subclasses de `GenericSyncService`
- **Conteúdo**: Dados completos de negócio (pesagens, entregas, despesas, etc.)
- **Gate**: `Farm.isShared == true` (ativado por licença multi-user)
- **Controlado por**: `GenericSyncService._shouldSyncToCloud()`
- **Nota**: Consent é implícito na compra da licença multi-user. O flag `isShared` é ativado na fazenda, não no usuário.

### 13.4. Implementação da Gate Tier 3

O método `_shouldSyncToCloud()` no `GenericSyncService` verifica duas condições:

1. `syncEnabled` — flag no nível do serviço (subclasse opt-in)
2. `FarmService.instance.isActiveFarmShared()` — flag na fazenda ativa

Ambas devem ser `true` para que dados sejam enfileirados para sync com Firestore. Caso contrário, todos os dados permanecem exclusivamente no Hive local.

### 13.5. Fluxo de Decisão

```
Operação de Escrita (add/update/delete)
  │
  ├─ 1. Salva no Hive local (SEMPRE)
  │
  ├─ 2. Verifica _shouldSyncToCloud()
  │     │
  │     ├─ syncEnabled == false → FIM (dados locais apenas)
  │     │
  │     ├─ farm.isShared == false → FIM (dados locais apenas)
  │     │
  │     └─ AMBOS true → Enfileira operação no OfflineQueueManager
  │                       │
  │                       ├─ Online → Envia para Firestore
  │                       └─ Offline → Persiste na fila, retry automático
  │
  └─ 3. notifyListeners() (UI atualiza imediatamente)
```

### 13.6. Controle de Visibilidade por Ownership

O flag `isOwner` (computado via `Farm.isOwner(uid)`) controla a visibilidade de features na UI:

| Feature | Owner | Membro/Colaborador |
|---------|-------|-------------------|
| Backup Nuvem | Visível | Oculto |
| Backup Local (export/import) | Visível | Oculto |
| Cloud Sync Toggle | Visível | Oculto |
| Export LGPD | Visível | Oculto |
| Deletar Dados | Visível | Oculto |
| Configurações Gerais (idioma, tema, notificações) | Visível | Visível |
| Gerenciar Consents (Privacidade) | Visível | Visível |

Isso é implementado via `AgroSettingsScreen(isOwner: ...)` e `AgroPrivacyScreen(isOwner: ...)`.


