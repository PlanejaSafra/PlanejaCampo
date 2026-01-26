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

### 4.1. Farm-Centric Model (CORE-75)

- Dados pertencem à **fazenda** (via farmId), não ao usuário
- O modelo `Farm` no agro_core armazena: id, name, ownerId, memberIds, createdAt
- `FarmService` gerencia ciclo de vida: criação, lookup, default farm
- `FarmAdapter` registrado no Hive de cada app

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
| 2 | Hive Adapters | `registerAdapter()` para todos os models + Farm + DependencyManifest |
| 3 | Privacy Store | `AgroPrivacyStore.init()` |
| 4 | Data Migration | `DataMigrationService.instance.runMigrations()` |
| 5 | Cloud Service | `UserCloudService.instance.init()` |
| 6 | Backup Providers | `CloudBackupService.instance.registerProvider(...)` |
| 7 | Deletion Providers | `DataDeletionService.instance.registerDeletionProvider(...)` |
| 8 | Farm Service | `FarmService.instance.init()` |
| 9 | Dependency Service | `DependencyService.instance.init()` |
| 10 | App Services | PropertyService, TalhaoService, etc. |

---

## 9. Fases do agro_core Implementadas

| Fase | Nome | Status | Descrição |
|------|------|--------|-----------|
| CORE-75 | Farm-Centric Model | DONE | Modelo Farm, FarmService, FarmAdapter para multi-user |
| CORE-77 | Dependency-Aware Backup | DONE | EnhancedBackupProvider, 3-phase restore, sourceApp isolation, DependencyService, AppDeletionProvider, BackupMeta, RestoreAnalysis, LgpdDeletionResult |

### Integração nos Apps

| App | Fase | Status | Descrição |
|-----|------|--------|-----------|
| RuraRubber | RUBBER-24 | DONE | FarmOwnedEntity em Parceiro/Entrega, BorrachaBackupProvider, BorrachaDeletionProvider |
| RuraRain | RAIN-03 | DONE | FarmOwnedMixin em RegistroChuva, ChuvaBackupProvider, ChuvaDeletionProvider |
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
- [ ] Inicializar FarmService e DependencyService no main.dart
- [ ] Criar BackupProvider implementando EnhancedBackupProvider
- [ ] Criar DeletionProvider implementando AppDeletionProvider
- [ ] Registrar providers no CloudBackupService e DataDeletionService
- [ ] Garantir que todas as entidades usam sourceApp = "nomedoapp"

---

## 11. GenericSyncService (CORE-78)

> **Status**: Planejado (Aguardando Implementação)
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
2. **Robustez**: Tratamento centralizado de erros, retries e conectividade.
3. **Padronização**: Todos os apps comportam-se da mesma forma (Offline-First real).
4. **Cross-App Data**: Habilita sincronização entre apps (ex: RuraRubber e RuraCash compartilhando dados via Firestore).

