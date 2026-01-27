# CHANGELOG - agro_core

---

## Phase CORE-92: L10n Default Name Keys + Missing Export Strings

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Adicionar keys de nomes padrão localizados para farms (rubber, personal) e corrigir keys faltantes de export (exportDataSuccess, exportDataError) que causavam erros de compilação no agro_privacy_screen.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-92.1 | Adicionar `farmDefaultNamePersonal` ("Minhas Financas" / "My Finances") aos ARBs | ✅ DONE |
| CORE-92.2 | Adicionar `farmDefaultNameRubber` ("Meu Seringal" / "My Rubber Plantation") aos ARBs | ✅ DONE |
| CORE-92.3 | Adicionar `rubberPlantationTitle` ("Seringal" / "Rubber Plantation") aos ARBs | ✅ DONE |
| CORE-92.4 | Adicionar `exportDataSuccess` e `exportDataError` faltantes nos ARBs (fix 2 erros em agro_privacy_screen.dart) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/l10n/arb/app_pt.arb` | MODIFY | Adicionar 5 novas keys l10n |
| `lib/l10n/arb/app_en.arb` | MODIFY | Adicionar 5 novas keys l10n |

---

## Phase CORE-91: FarmType — Context Differentiation (Agro vs Pessoal) [LOCKED]

### Status: [LOCKED]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Adicionar diferenciação de tipo ao modelo Farm, permitindo que um mesmo usuário mantenha contextos separados (fazenda rural vs finanças pessoais). Habilita o CASH-09 (Personal Finance Mode) e previne poluição do DRE da fazenda com gastos domésticos.
**Prerequisite**: Nenhum — mudança retrocompatível. Recomenda-se implementar junto com CASH-09.

### Why LOCKED

- Requer decisão de design: enum simples (`agro`, `personal`) ou extensível (`agro`, `personal`, `pecuaria`, `granja`)?
- Requer regeneração do `farm.g.dart` via `build_runner` em TODOS os apps
- Requer testes de migração: farms existentes devem receber `type = FarmType.agro` como default
- Requer decisão sobre filtros cross-app: cada app mostra apenas farms do seu contexto?

### Architecture Overview

```
Modelo Farm — Campos atuais + novo campo `type`:

@HiveField(10)
FarmType type; // default = FarmType.agro

enum FarmType { agro, personal }
// HiveType com typeId 21 (próximo disponível após Farm=20)
```

### Impact Analysis

| App | Impacto | Ação Necessária |
|-----|---------|-----------------|
| agro_core | MODIFY | Adicionar FarmType enum, campo type no Farm, regenerar adapter |
| RuraRubber | MINOR | Filtrar farms por `FarmType.agro` no FarmService — farms pessoais não aparecem |
| RuraRain | MINOR | Idem — filtrar farms por `FarmType.agro` |
| RuraCash | FEATURE | Usar ambos tipos. Farm pessoal habilita categorias domésticas (CASH-09) |
| RuraCattle | MINOR | Filtrar farms por `FarmType.agro` |
| RuraFuel | MINOR | Filtrar farms por `FarmType.agro` |

### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-91.1 | **FarmType Enum**: Criar `enum FarmType { agro, personal }` com HiveType typeId 21, displayName, icon | ⏳ TODO |
| CORE-91.2 | **Farm.type field**: Adicionar `@HiveField(10) FarmType type` ao modelo Farm (default `FarmType.agro`) | ⏳ TODO |
| CORE-91.3 | **Farm.g.dart regeneration**: Rodar `build_runner` no agro_core para regenerar FarmAdapter com novo campo | ⏳ TODO |
| CORE-91.4 | **FarmTypeAdapter registration**: Registrar `FarmTypeAdapter()` no Hive de cada app (main.dart) | ⏳ TODO |
| CORE-91.5 | **Farm.create update**: Adicionar parâmetro `type` na factory `Farm.create()` (default: `FarmType.agro`) | ⏳ TODO |
| CORE-91.6 | **FarmService filtering**: Adicionar `getFarmsByType(FarmType type)` para filtrar farms por tipo | ⏳ TODO |
| CORE-91.7 | **Migration**: Farms existentes sem campo `type` recebem `FarmType.agro` via null fallback no adapter | ⏳ TODO |
| CORE-91.8 | **Export barrel**: Exportar `farm_type.dart` no `agro_core.dart` | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/farm_type.dart` | CREATE | Enum FarmType com HiveType typeId 21 |
| `lib/models/farm.dart` | MODIFY | Adicionar @HiveField(10) FarmType type |
| `lib/models/farm.g.dart` | REGENERATE | build_runner com novo campo |
| `lib/services/farm_service.dart` | MODIFY | Adicionar getFarmsByType(), createPersonalFarm() |
| `lib/agro_core.dart` | MODIFY | Exportar farm_type.dart |

### Licensing Rule

A farm pessoal é **FREE** — não conta para o limite de farms do `subscriptionTier`:
- `getFarmLimit(tier)` controla apenas farms `FarmType.agro` (free=1, basic=3, premium=ilimitado)
- Farms `FarmType.personal` são limitadas a 1 por usuário, independente do tier
- A farm pessoal é uma feature do app, não um recurso premium
- Regra: `countFarms(FarmType.agro) <= farmLimit` + `countFarms(FarmType.personal) <= 1`

### Backwards Compatibility

- Farms existentes no Hive NÃO possuem campo `type` (HiveField 10)
- O Hive reader retorna `null` para fields ausentes
- O adapter deve usar fallback: `type: fields[10] as FarmType? ?? FarmType.agro`
- Resultado: **zero migração manual necessária** — farms existentes automaticamente tornam-se `agro`

### Cross-Reference
- CORE-75: Farm-Centric Model (base)
- CORE-90: MultiFarm (complementar — multi-user requer que FarmType exista)
- CASH-09: Personal Finance Mode (consumidor principal desta funcionalidade)

---

## Phase CORE-90: MultiFarm — Farm Switcher & Multi-Membership [LOCKED]

### Status: [LOCKED]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que um usuário acesse múltiplas fazendas (própria + vinculadas como gerente/sangrador). Implementar farm switcher na UI, modelo de membership, convite/aceite de membros, e filtragem de dados por fazenda ativa.
**Prerequisite**: CORE-88 (Data Tier Architecture), todos os apps com Firebase/Auth configurado

### Why LOCKED

- Requer todos os apps com Firebase + Auth integrados (RuraCash ainda não tem — CASH-08)
- Requer backend Firestore para troca de convites (farm invitations)
- Requer definição de business rules para licenças multi-user
- Requer UX design do farm switcher (dropdown? drawer section? tela dedicada?)

### Architecture Overview

```
Cenário: User B (sangrador) é convidado para Farm A (owner: User C)

User B possui:
├─ Farm B (própria, isOwner=true, isDefault=true)
└─ Farm A (vinculada, isOwner=false, role=worker)

Farm Switcher:
├─ [●] Farm B — "Minha Fazenda" (owner)
└─ [ ] Farm A — "Seringal Santa Fé" (sangrador)

Ao trocar para Farm A:
├─ FarmService.setActiveFarm("farm-A-id")
├─ Dados filtrados por farmId = "farm-A-id"
├─ isOwner = false → backup/LGPD ocultos
├─ isShared = true → GenericSyncService sincroniza
└─ UI mostra dados de Farm A apenas
```

### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-90.1 | **FarmMember Model**: Criar modelo `FarmMember` com `userId`, `farmId`, `role` (owner/manager/worker), `invitedBy`, `joinedAt`, `status` (pending/accepted/rejected). HiveType + Firestore | ⏳ TODO |
| CORE-90.2 | **FarmRole Enum**: Criar enum `FarmRole` (owner, manager, worker) com permissões associadas. HiveType | ⏳ TODO |
| CORE-90.3 | **Farm.members field**: Adicionar `List<FarmMember>? members` ao modelo Farm (HiveField 7, reservado) | ⏳ TODO |
| CORE-90.4 | **FarmInvitation Model**: Criar modelo para convites pendentes. Armazenado no Firestore (`farm_invitations/{inviteId}`) para troca entre usuários | ⏳ TODO |
| CORE-90.5 | **FarmService.getAccessibleFarms()**: Retornar todas as farms acessíveis (próprias + vinculadas). Composição de farms locais (Hive) + farms remotas (Firestore, se online) | ⏳ TODO |
| CORE-90.6 | **FarmService.setActiveFarm(farmId)**: Trocar a farm ativa. Atualiza `isDefault` em todas as farms. Notifica listeners para UI refresh. Recarrega dados filtrados | ⏳ TODO |
| CORE-90.7 | **FarmService.inviteMember()**: Criar convite no Firestore. Gera link/código que o convidado usa para aceitar | ⏳ TODO |
| CORE-90.8 | **FarmService.acceptInvitation()**: Aceitar convite. Cria FarmMember local + registra no Firestore da farm | ⏳ TODO |
| CORE-90.9 | **FarmService.removeMember()**: Owner remove membro. Revoga acesso, limpa dados locais do membro | ⏳ TODO |
| CORE-90.10 | **FarmService.leaveFarm()**: Membro sai voluntariamente. Dados criados por ele permanecem na farm (pertencem ao owner) | ⏳ TODO |
| CORE-90.11 | **Farm Switcher Widget**: Componente reutilizável (dropdown ou bottom sheet) para alternar entre fazendas. Mostra nome, role, ícone de owner/worker | ⏳ TODO |
| CORE-90.12 | **AgroDrawer integration**: Adicionar farm switcher no drawer (acima dos itens de menu). Cada app herda automaticamente | ⏳ TODO |
| CORE-90.13 | **Data Filtering**: Todos os services que usam GenericSyncService devem filtrar por `farmId` da farm ativa. `getAll()` retorna apenas dados da farm ativa | ⏳ TODO |
| CORE-90.14 | **Sync on Farm Switch**: Ao trocar para farm compartilhada (isShared=true), trigger `syncAllWithServer()` para baixar dados mais recentes | ⏳ TODO |
| CORE-90.15 | **License Activation**: Quando licença multi-user é comprada, setar `farm.isShared = true` e habilitar Tier 3 sync. Endpoint ou in-app purchase flow | ⏳ TODO |

### Firestore Collections (New)

| Collection | Document | Description |
|------------|----------|-------------|
| `farm_members/{farmId}_{userId}` | FarmMember data | Registro de membership com role |
| `farm_invitations/{inviteId}` | Invitation data | Convite pendente com code, expiration |

### Permission Matrix

| Ação | Owner | Manager | Worker |
|------|-------|---------|--------|
| Ver dados da farm | ✅ | ✅ | ✅ |
| Criar registros | ✅ | ✅ | ✅ |
| Editar registros (próprios) | ✅ | ✅ | ✅ |
| Editar registros (de outros) | ✅ | ✅ | ❌ |
| Deletar registros | ✅ | ✅ | ❌ |
| Backup da farm | ✅ | ❌ | ❌ |
| Restore da farm | ✅ | ❌ | ❌ |
| Export LGPD (farm) | ✅ | ❌ | ❌ |
| Deletar dados (LGPD) | ✅ | ❌ | ❌ |
| Convidar membros | ✅ | ✅ | ❌ |
| Remover membros | ✅ | ❌ | ❌ |
| Alterar roles | ✅ | ❌ | ❌ |
| Ativar/desativar sharing | ✅ | ❌ | ❌ |
| Trocar de farm (switcher) | ✅ | ✅ | ✅ |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/farm_member.dart` | CREATE | Modelo FarmMember + HiveAdapter |
| `lib/models/farm_role.dart` | CREATE | Enum FarmRole (owner, manager, worker) |
| `lib/models/farm_invitation.dart` | CREATE | Modelo FarmInvitation para Firestore |
| `lib/models/farm.dart` | MODIFY | Adicionar `List<FarmMember>? members` (HiveField 7) |
| `lib/services/farm_service.dart` | MODIFY | getAccessibleFarms, setActiveFarm, invite/accept/remove/leave |
| `lib/widgets/farm_switcher.dart` | CREATE | Widget reutilizável de seleção de farm |
| `lib/widgets/agro_drawer.dart` | MODIFY | Integrar farm switcher no drawer |
| `lib/services/sync/generic_sync_service.dart` | MODIFY | Filtrar getAll() por farmId da farm ativa |

### UX Flow (Planned)

1. **Owner cria farm** → Farm criada com `isShared = false` (offline-only)
2. **Owner compra licença** → `farm.isShared = true`, Tier 3 sync ativado
3. **Owner convida sangrador** → Gera convite (código ou link)
4. **Sangrador aceita** → FarmMember criado, farm aparece no switcher do sangrador
5. **Sangrador troca para farm do owner** → Dados sincronizados, UI filtrada
6. **Sangrador cria registro** → `createdBy = sangrador.uid`, `farmId = farm-owner`
7. **Owner vê registro** → Vê quem criou (auditoria via createdBy)
8. **Sangrador sai** → Perde acesso, dados permanecem na farm

### Cross-Reference
- CORE-75: Farm-Centric Model (base)
- CORE-77: Ownership rules, LGPD, createdBy audit trail
- CORE-86/87: isOwner-based visibility (já implementado)
- CORE-88: Data Tier Architecture, farm.isShared, Tier 3 gate
- Todos os apps: Precisam de CASH-08 / equivalente antes de CORE-90

---

## Phase CORE-88: Data Tier Architecture - Farm.isShared + GenericSyncService Tier 3 Gate

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Implementar arquitetura de tiers de dados para sincronização cloud. Definir 4 níveis de dados (Tier 0-3) com gates específicos. Tier 3 (full data sync via GenericSyncService) só sincroniza quando `farm.isShared=true` (licença multi-user ativada). Preparação completa para futuro multi-user sem necessidade de revisitar.

### Data Tier Architecture

| Tier | Dados | Gate | Service | Coleções |
|------|-------|------|---------|----------|
| **Tier 0** | Identidade e Termos | Sempre (obrigatório) | `UserCloudService` | `users` |
| **Tier 1** | Backups Manuais | `consentCloudBackup` | `CloudBackupService` | `user_backups`, `user_backup_chunks` |
| **Tier 2** | Estatísticas Anônimas | `consentAggregateMetrics` | `SyncService` (rurarain) | `rainfall_data`, `rainfall_stats` |
| **Tier 3** | Dados Completos (Multi-User) | `farm.isShared` | `GenericSyncService` | Todas as coleções do app |

### Design Decisions

- **`Farm.isShared`** (HiveField 9, default `false`): Flag que indica se a farm está no modo compartilhado (multi-user). Quando `true`, GenericSyncService sincroniza com Firestore.
- **Ativação futura**: Quando licença multi-user for adquirida, o sistema apenas seta `farm.isShared = true`. O GenericSyncService já estará pronto para sincronizar.
- **Consent implícito**: Ao ativar licença multi-user, o usuário concorda com termos que incluem sync de dados. Não é necessário check de `consentCloudBackup` no Tier 3.
- **Retrocompatibilidade**: `isShared` default `false` garante que apps existentes continuam offline-only sem mudanças.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-88.1 | Adicionar `@HiveField(9) bool isShared` ao modelo Farm (default false), atualizar construtor, factory, toJson, fromJson | ✅ DONE |
| CORE-88.2 | Atualizar `farm.g.dart` manualmente (adapter com 9 fields, leitura/escrita de isShared) | ✅ DONE |
| CORE-88.3 | Atualizar FarmService: `importFarm()` preserva isShared, `transferData()` preserva isShared, adicionar helpers `isActiveFarmShared()` e `setFarmShared()` | ✅ DONE |
| CORE-88.4 | Atualizar GenericSyncService: substituir check `consentCloudBackup` por `_shouldSyncToCloud()` que verifica `farm.isShared`, importar FarmService, remover import uuid | ✅ DONE |
| CORE-88.5 | Documentar Data Tier Architecture no ARCHITECTURE.md (nova seção 13) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/farm.dart` | MODIFY | Adicionar `@HiveField(9) bool isShared` (default false), helpers `setShared()`, `activateSharing()`, `deactivateSharing()`, atualizar toJson/fromJson |
| `lib/models/farm.g.dart` | REGENERATE | Adapter com 9 campos (inclui isShared) |
| `lib/services/farm_service.dart` | MODIFY | `importFarm()` preserva isShared, `transferData()` preserva isShared, novos métodos `isActiveFarmShared()` e `setFarmShared()` |
| `lib/services/sync/generic_sync_service.dart` | MODIFY | Substituir import AgroPrivacyStore por FarmService, criar `_shouldSyncToCloud()`, atualizar `_save()` e `delete()` |

### Notes

- Tier 0, 1, 2 já possuem services dedicados com seus próprios gates — não são afetados por esta fase
- GenericSyncService é exclusivamente Tier 3 — só deve sincronizar quando farm está em modo compartilhado
- O campo `subscriptionTier` (HiveField 8) é para limites de farms; `isShared` (HiveField 9) é para habilitar sync
- Quando `isShared=false`, dados ficam exclusivamente offline-first (Hive local) — nenhum dado é enviado ao Firestore via GenericSyncService

### Cross-Reference
- CORE-86: Check de consent substituído por isShared (evolução)
- CORE-87: Owner-based access control (complementar)
- RAIN-07: Adaptação do RuraRain para isOwner + parity com RUBBER-27
- RUBBER-27: Já adaptado para isOwner (não requer mudanças adicionais)

---

## Phase CORE-87: Owner-Based Access Control for Settings & Privacy

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Restringir funcionalidades de backup, exportação, importação e exclusão LGPD ao owner da farm ativa. Usuários vinculados a farms de terceiros não veem essas opções.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-87.1 | Adicionar parâmetro `isOwner` ao AgroSettingsScreen (default true) | ✅ DONE |
| CORE-87.2 | Esconder seção Cloud Backup quando isOwner=false | ✅ DONE |
| CORE-87.3 | Esconder seção Local Backup quando isOwner=false | ✅ DONE |
| CORE-87.4 | Esconder Sync toggle quando isOwner=false | ✅ DONE |
| CORE-87.5 | Remover "Exportar Meus Dados LGPD" de Settings (redundante com Privacy) | ✅ DONE |
| CORE-87.6 | Adicionar parâmetro `isOwner` ao AgroPrivacyScreen (default true) | ✅ DONE |
| CORE-87.7 | Esconder botões Export/Delete LGPD em Privacy quando isOwner=false | ✅ DONE |
| CORE-87.8 | Propagar isOwner de Settings para Privacy na navegação | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/agro_settings_screen.dart` | MODIFY | Adicionado `isOwner`, removido `onExportData`/`_handleExportData`/import DataExportService, seções condicionais por isOwner |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Adicionado `isOwner`, botões Export/Delete condicionais |

### Notes

- Default `isOwner = true` para retrocompatibilidade (apps single-owner como RuraRain/RuraCash não precisam mudar)
- Lógica de owner: `FarmService.instance.getDefaultFarm()?.isOwner(currentUser.uid)`
- Consents (toggles) continuam visíveis para todos — são preferências pessoais, não dados da farm

---

## Phase CORE-86: Consent Check for GenericSyncService Cloud Sync

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Bloquear sincronização automática de dados completos para o Firestore sem consentimento do usuário. O GenericSyncService enfileirava operações para o cloud sem verificar `consentCloudBackup`.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-86.1 | Adicionar check `AgroPrivacyStore.consentCloudBackup` no `_save()` antes de enfileirar | ✅ DONE |
| CORE-86.2 | Adicionar check `AgroPrivacyStore.consentCloudBackup` no `delete()` antes de enfileirar | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/sync/generic_sync_service.dart` | MODIFY | Import AgroPrivacyStore, condicional `syncEnabled && AgroPrivacyStore.consentCloudBackup` em _save() e delete() |

### Notes

- Dados locais continuam sendo salvos normalmente (offline-first)
- Apenas a operação de enfileirar para sync no Firestore é bloqueada sem consent
- Se o usuário consentir depois, novos saves serão sincronizados (dados anteriores não retroativos)

---

## Phase CORE-85: Remove Incomplete Cloud Data Deletion from Settings + Improve Privacy Deletion Dialog

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Remover o botão "Deletar Dados Nuvem" da tela de configurações (só deletava `users/{uid}`, não deletava backups — enganoso). Melhorar UX do dialog de exclusão na tela de Privacidade com botão Cancelar mais visível.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CORE-85.1 | Remover botão "Deletar Dados Nuvem", handler e callback de AgroSettingsScreen | ✅ DONE |
| CORE-85.2 | Melhorar dialog de exclusão em AgroPrivacyScreen — botão Cancelar verde, mesmo tamanho do Excluir | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/agro_settings_screen.dart` | MODIFY | Removido campo `onDeleteCloudData`, parâmetro do construtor, método `_handleDeleteCloudData`, e ListTile "Deletar Dados Nuvem" |
| `lib/screens/agro_privacy_screen.dart` | MODIFY | Botões do dialog de exclusão agora em Row com Expanded: Cancelar (verde) e Excluir Permanentemente (vermelho), mesma largura |

### Notes

- A exclusão completa de dados (backups, auth, dados locais) permanece disponível na tela de Privacidade via `DataDeletionService.deleteAllUserData()`
- Strings l10n mantidas (`deleteCloudDataTitle`, etc.) para possível uso futuro

---

## Phase CORE-84: Fix Sync Infrastructure & Property Prompt Bugs

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Corrigir bugs críticos na infraestrutura de sincronização (adapters Hive não registrados, erros silenciosos no processQueue, erro de propagação no _save) e loop no prompt de nome de propriedade.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 84.1 | **Sync Adapter Registration**: Registrar OfflineOperationAdapter, OperationTypeAdapter, OperationPriorityAdapter em todos os apps (RuraRain, RuraRubber, RuraCash) | ✅ DONE |
| 84.2 | **processQueue Logging**: Adicionar debugPrint em init(), addToQueue(), processQueue() para diagnóstico completo do pipeline de sync | ✅ DONE |
| 84.3 | **GenericSyncService._save() Error Handling**: Envolver operações de queue em try-catch para evitar propagação de erros de sync ao CRUD local | ✅ DONE |
| 84.4 | **Property Name Prompt Loop Fix**: Adicionar flag persistente `propertyNamePrompted` em AgroPrivacyStore para evitar re-prompt quando usuário mantém nome padrão | ✅ DONE |
| 84.5 | **App Check Debug Guard**: Envolver FirebaseAppCheck.activate() em `if (!kDebugMode)` para evitar falhas em builds debug | ✅ DONE |
| 84.6 | **Unit Tests**: 61 testes unitários cobrindo SyncModels, DataIntegrityManager, Hive serialization, pipeline CRUD e cross-app scenarios | ✅ DONE |

### Root Causes

1. **Sync Adapter Missing**: `OfflineOperation` (typeId 33), `OperationType` (typeId 32), `OperationPriority` (typeId 31) tinham adapters gerados em `sync_models.g.dart` e exportados via `agro_core.dart`, mas NENHUM app registrava esses adapters no `main.dart`. Resultado: `HiveError: Cannot write, unknown type: OfflineOperation`.

2. **Silent Queue Failures**: `OfflineQueueManager.processQueue()` não tinha nenhum `debugPrint`, tornando impossível diagnosticar falhas de sincronização.

3. **Save Error Propagation**: `GenericSyncService._save()` propagava erros do OfflineQueueManager para o chamador, fazendo CRUD local falhar quando sync falhava.

4. **Property Prompt Loop**: `shouldPromptForPropertyName()` verificava se o nome era genérico ("Minha Propriedade"), mas o usuário podia confirmar mantendo o nome padrão, causando re-prompt infinito.

5. **App Check in Debug**: `FirebaseAppCheck.instance.activate()` falhava em builds debug sem token configurado, bloqueando inicialização.

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/sync/offline_queue_manager.dart` | MODIFY | Adicionar debugPrint em processQueue para logging de início, batches, sucesso e falha |
| `lib/services/sync/generic_sync_service.dart` | MODIFY | Envolver queue operations em try-catch no _save() |
| `lib/privacy/agro_privacy_keys.dart` | MODIFY | Adicionar key `propertyNamePrompted` |
| `lib/privacy/agro_privacy_store.dart` | MODIFY | Adicionar isPropertyNamePrompted() e setPropertyNamePrompted() |
| `lib/widgets/property_name_prompt_dialog.dart` | MODIFY | Verificar flag antes de checar nome; setar flag após salvar |
| `test/sync_models_test.dart` | CREATE | 18 testes para OfflineOperation, SyncMetadata, SyncResult |
| `test/data_integrity_test.dart` | CREATE | 22 testes para hash, validação, conflitos, resolução |
| `test/sync_pipeline_test.dart` | CREATE | 21 testes para Hive adapters, queue, CRUD pipeline, cross-app |
| `pubspec.yaml` | MODIFY | Adicionar mocktail e fake_cloud_firestore em dev_dependencies |

### Cross-Reference
- RAIN-05: Registro de adapters no RuraRain
- RUBBER-26: Registro de adapters + App Check + Property Name Gate no RuraRubber
- CASH-06: Registro de adapters no RuraCash

---

## Phase CORE-78: GenericSyncService - Infraestrutura Offline-First Unificada

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Criar classe base GenericSyncService no agro_core que encapsula toda a lógica offline-first (Hive + Firestore sync opcional), eliminando duplicação de código nos apps.
**Implementation Details**:
- **Offline-First**: Uso de Hive para cache local e filas de operações.
- **Sync-Smart**: Integração com `connectivity_plus` para só sincronizar via rede ativa.
- **Conflict-Free**: Resolução automática (Server Wins) e uso de `FieldValue.serverTimestamp()` para garantir ordem cronológica correta.
- **Optimized**: Indexação em memória para buscas O(1) por Farm ID.

## Phase CORE-83: Migration of App Services to GenericSyncService

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 CRITICAL (Tech Debt)
**Objective**: Migrar todos os services de dados (CRUD) dos apps RuraRain, RuraRubber, etc. para usar a nova infraestrutura `GenericSyncService`.

### Services Migrated

| App | Service | Status |
|-----|---------|--------|
| **RuraRain** | `ChuvaService` → `GenericSyncService<RegistroChuva>` | ✅ DONE (RAIN-04) |
| **RuraRubber** | `DespesaService` → `GenericSyncService<Despesa>` | ✅ DONE (RUBBER-25.1) |
| **RuraRubber** | `EntregaService` → `GenericSyncService<Entrega>` | ✅ DONE (RUBBER-25.2) |
| **RuraRubber** | `RecebivelService` → `GenericSyncService<Recebivel>` | ✅ DONE (RUBBER-25.3) |
| **RuraRubber** | `ParceiroService` → `GenericSyncService<Parceiro>` | ✅ DONE (RUBBER-25.4) |
| **RuraRubber** | `TabelaService` → `GenericSyncService<TabelaSangria>` | ✅ DONE (RUBBER-25.5) |
| **RuraCash** | `CentroCustoService` → `GenericSyncService<CentroCusto>` | ✅ DONE |
| **RuraCash** | `LancamentoService` → `GenericSyncService<Lancamento>` | ✅ DONE |
| **Outros** | RuraCattle, RuraFuel | ⏳ TODO (apps ainda não criados) |

### Problema Resolvido

Cada app tinha services duplicados (DespesaService, LancamentoService, ChuvaService) com ~150 linhas cada, todos reimplementando a mesma lógica de:
- Inicialização de Hive Box
- CRUD básico
- Singleton pattern
- ChangeNotifier
- Backup helpers (toJson/fromJson)

Com CORE-78, cada service passa a ter ~30 linhas (apenas métodos específicos do domínio), estendendo GenericSyncService que fornece toda a infraestrutura.

### Cross-Reference
- RUBBER-25: Migração dos 5 services do RuraRubber
- RAIN-04: Migração do ChuvaService
- RuraCash v1.1.0: Migração de CentroCustoService e LancamentoService

---

### Sub-Phase 78.1: Modelos de Sync

**Arquivo**: `lib/services/sync/sync_models.dart`

**Hive TypeIds Reservados**:
| TypeId | Modelo |
|--------|--------|
| 31 | OperationPriority (enum) |
| 32 | OperationType (enum) |
| 33 | OfflineOperation (class) |

**Enums a criar**:

1. **SyncStatus** (plain Dart, não Hive)
   - `pending` - Aguardando sync
   - `syncing` - Em processo de sync
   - `synced` - Sincronizado com sucesso
   - `failed` - Falhou (vai retentar)
   - `conflict` - Conflito detectado

2. **OperationPriority** (@HiveType 31)
   - `critical` (HiveField 0) - Deletes
   - `high` (HiveField 1) - Creates
   - `medium` (HiveField 2) - Updates
   - `low` (HiveField 3) - Reads/Syncs

3. **OperationType** (@HiveType 32)
   - `create` (HiveField 0)
   - `update` (HiveField 1)
   - `delete` (HiveField 2)

**Classes a criar**:

1. **OfflineOperation** (@HiveType 33, extends HiveObject)
   - Campos HiveField:
     - 0: `String id` - UUID único da operação
     - 1: `String collection` - Nome do box/coleção
     - 2: `OperationType operationType` - Tipo da operação
     - 3: `String docId` - ID do documento afetado
     - 4: `Map<String, dynamic>? data` - Dados (para create/update)
     - 5: `DateTime timestamp` - Quando foi enfileirado
     - 6: `OperationPriority priority` - Prioridade
     - 7: `int retryCount` - Número de tentativas
     - 8: `String? lastError` - Último erro
     - 9: `String? sourceApp` - App de origem
     - 10: `String? farmId` - Fazenda (multi-farm)
   - Métodos:
     - `factory OfflineOperation.create(...)` - Cria com ID auto-gerado
     - `void recordFailure(String error)` - Incrementa retry e salva erro
     - `bool get hasExceededRetries` - Se passou de 5 tentativas
     - `int compareTo(OfflineOperation other)` - Para ordenar fila

2. **SyncMetadata** (plain Dart, não Hive)
   - Campos:
     - `int version` - Número de versão (incrementa a cada update)
     - `String? hash` - Hash SHA256 dos dados
     - `DateTime? lastSyncAt` - Último sync
     - `SyncStatus syncStatus` - Status atual
     - `String? lastModifiedBy` - sourceApp que modificou
     - `String? lastModifiedDevice` - Device ID
   - Métodos:
     - `factory SyncMetadata.create({sourceApp, deviceId})`
     - `SyncMetadata copyWithUpdate({...})` - Incrementa versão
     - `Map<String, dynamic> toMap()`
     - `factory SyncMetadata.fromMap(Map)`

3. **SyncResult** (plain Dart)
   - Campos:
     - `bool success`
     - `int syncedCount`
     - `int failedCount`
     - `int conflictCount`
     - `String? error`
     - `DateTime completedAt`
   - Factories: `SyncResult.success()`, `SyncResult.failure(error)`

4. **SyncableEntity** (interface abstrata)
   - `String get id`
   - `DateTime? get updatedAt`

---

### Sub-Phase 78.2: LocalCacheManager

**Arquivo**: `lib/services/sync/local_cache_manager.dart`

**Propósito**: Gerenciamento genérico de cache Hive. Encapsula todas as operações de leitura/escrita no cache local.

**Singleton**: `LocalCacheManager.instance`

**Estado interno**:
- `Map<String, Box<Map<String, dynamic>>> _boxes` - Cache de boxes abertos
- `Map<String, DateTime> _lastSyncTimestamps` - Último sync por coleção
- `bool _initialized`

**Métodos públicos**:

1. **init()** - Abre box de metadados (`_sync_metadata`)
2. **openBox(String boxName)** - Abre/retorna box genérico
3. **closeBox(String boxName)** - Fecha box
4. **readFromCache(String collection, String id)** - Lê 1 documento
5. **readManyFromCache(String collection, List<String> ids)** - Lê N documentos
6. **getAllFromCache(String collection)** - Lê todos
7. **queryCache(String collection, Map<String, dynamic> filters)** - Query com filtros
8. **updateCache(String collection, String id, Map<String, dynamic> data)** - Salva no cache
9. **removeFromCache(String collection, String id)** - Remove do cache
10. **clearCollection(String collection)** - Limpa toda a coleção
11. **getLastSyncTimestamp(String collection)** - Retorna último sync
12. **setLastSyncTimestamp(String collection, DateTime timestamp)** - Salva timestamp
13. **getCacheStats(String collection)** - Estatísticas (count, size, lastUpdate)

**Lógica de queryCache**:
- Filtros suportados: `isEqualTo`, `isGreaterThan`, `isLessThan`
- Itera sobre valores do box e filtra em memória
- Retorna lista de maps que passam nos filtros

---

### Sub-Phase 78.3: OfflineQueueManager

**Arquivo**: `lib/services/sync/offline_queue_manager.dart`

**Propósito**: Gerencia fila de operações offline com prioridade. Quando online, processa a fila em ordem.

**Singleton**: `OfflineQueueManager.instance`

**Hive Box**: `_offline_queue` (armazena OfflineOperation)

**Estado interno**:
- `Box<OfflineOperation> _queueBox`
- `bool _isProcessing` - Evita processamento paralelo
- `StreamController<SyncResult> _syncResultController` - Stream de resultados

**Métodos públicos**:

1. **init()** - Abre box da fila
2. **addToQueue(OfflineOperation op)** - Adiciona operação à fila
3. **getQueue()** - Retorna todas operações ordenadas por prioridade/timestamp
4. **getPendingCount()** - Conta operações pendentes
5. **processQueue()** - Processa toda a fila (quando online)
6. **processQueueBatch(int maxBatch)** - Processa até N operações
7. **removeFromQueue(String operationId)** - Remove operação específica
8. **clearQueue()** - Limpa toda a fila
9. **retryFailed()** - Reprocessa operações que falharam
10. **Stream<SyncResult> get onSyncComplete** - Stream de resultados

**Lógica de processQueue**:
1. Verifica se está online (via connectivity ou flag)
2. Ordena fila por prioridade (critical > high > medium > low) e timestamp
3. Para cada operação:
   - Se create/update: envia para Firestore via `set(data, merge: true)`
   - Se delete: envia `delete()` para Firestore
   - Se sucesso: remove da fila
   - Se erro: incrementa retryCount, mantém na fila
4. Emite SyncResult no stream

**Batch processing para otimização**:
- Agrupa múltiplas operações em WriteBatch do Firestore (max 500)
- Reduz número de round-trips

---

### Sub-Phase 78.4: DataIntegrityManager

**Arquivo**: `lib/services/sync/data_integrity_manager.dart`

**Propósito**: Validação de integridade de dados e resolução de conflitos.

**Métodos estáticos** (não precisa ser singleton):

1. **computeHash(Map<String, dynamic> data)** - Retorna SHA256 dos dados (excluindo `_metadata`)
2. **hasValidHash(Map<String, dynamic> data)** - Verifica se hash em `_metadata.hash` bate
3. **validateDataIntegrity(Map<String, dynamic> data)** - Retorna true se dados são válidos
4. **addFullMetadata(Map<String, dynamic> data, {sourceApp, deviceId})** - Adiciona `_metadata` com hash, version, timestamp
5. **hasConflict(String collection, String id, Map localData, Map serverData)** - Detecta conflito
6. **resolveConflict(Map localData, Map serverData, ConflictStrategy strategy)** - Resolve conflito
7. **hasStoredConflict(Map<String, dynamic> data)** - Verifica se há conflito não resolvido

**ConflictStrategy** (enum):
- `serverWins` - Dados do servidor prevalecem
- `localWins` - Dados locais prevalecem
- `merge` - Merge campo a campo (mais recente vence)
- `manual` - Requer intervenção do usuário

**Estrutura do `_metadata`** (dentro de cada documento):
```
_metadata: {
  version: 3,
  hash: "sha256...",
  lastSyncAt: "2026-01-26T10:00:00Z",
  syncStatus: "synced",
  lastModifiedBy: "rurarubber",
  lastModifiedDevice: "device-uuid-123"
}
```

---

### Sub-Phase 78.5: GenericSyncService

**Arquivo**: `lib/services/sync/generic_sync_service.dart`

**Propósito**: Classe base abstrata que todo service de dados deve estender. Fornece CRUD completo com sync automático.

**Assinatura**:
```
abstract class GenericSyncService<T> extends ChangeNotifier
```

**Parâmetros do construtor**:
- `String boxName` - Nome do Hive box
- `bool syncEnabled` - Se usa Firestore (default: false)
- `String? firestoreCollection` - Nome da coleção no Firestore (default: boxName)

**Getters abstratos** (a ser implementado por cada service):
- `String get sourceApp` - Identificador do app (ex: "rurarubber")
- `T fromMap(Map<String, dynamic> map)` - Deserializa
- `Map<String, dynamic> toMap(T item)` - Serializa
- `String getId(T item)` - Extrai ID do item

**Getters opcionais com default**:
- `String? get farmId` - Pode retornar null para services globais

**Estado interno**:
- `Box<T>? _box`
- `bool _initialized`
- `Map<String, DateTime> _lastSyncScheduled` - Debounce por ID
- `bool _isSyncing`

**Métodos públicos CRUD**:

1. **init()** - Abre Hive box, retorna se já inicializado
2. **getAll()** - Lista todos os itens do box, ordenados
3. **getById(String id)** - Busca por ID, agenda sync em background se online
4. **add(T item)** - Adiciona item, enfileira sync se offline
5. **update(String id, T item)** - Atualiza, enfileira sync se offline
6. **delete(String id)** - Deleta, enfileira sync se offline
7. **clearAll()** - Limpa tudo (usado em restore)

**Métodos de sync**:

8. **syncWithServer(String id)** - Sincroniza 1 documento com Firestore
9. **syncAllWithServer({Map<String, dynamic>? filters})** - Sincroniza todos (com filtros opcionais)
10. **forceSync()** - Força sync completo ignorando cache
11. **scheduleSyncInBackground(String id)** - Agenda sync com debounce de 5 min

**Métodos de query**:

12. **getByAttributes(Map<String, dynamic> filters)** - Query local com filtros
13. **getByFarmId(String farmId)** - Filtra por fazenda

**Métodos de backup** (para CloudBackupService):

14. **toJsonList()** - Exporta todos como List<Map>
15. **importFromJson(List<dynamic> jsonList)** - Importa lista de maps

**Lógica interna de add/update/delete**:

```
1. Salva no Hive local imediatamente
2. Adiciona _metadata com hash, version, syncStatus='pending'
3. Se syncEnabled:
   a. Se online: tenta enviar para Firestore
      - Sucesso: atualiza _metadata.syncStatus='synced'
      - Erro: enfileira no OfflineQueueManager
   b. Se offline: enfileira no OfflineQueueManager
4. notifyListeners()
```

**Lógica de getById com background sync**:

```
1. Lê do Hive local (cache-first)
2. Se encontrou e está online:
   - Agenda syncInBackground com debounce
3. Retorna dado local
4. Background sync (após 2 segundos):
   - Busca do Firestore
   - Se versão diferente, atualiza cache local
```

---

### Sub-Phase 78.6: SyncConfig

**Arquivo**: `lib/services/sync/sync_config.dart`

**Propósito**: Configuração global de sync, centralizando timeouts, retries, debounce.

**Singleton**: `SyncConfig.instance`

**Configurações**:

| Config | Default | Descrição |
|--------|---------|-----------|
| `timeoutOnlineWrite` | 30s | Timeout para writes online |
| `timeoutOnlineRead` | 20s | Timeout para reads online |
| `timeoutOfflineWrite` | 5s | Timeout para writes offline (local) |
| `timeoutOfflineRead` | 3s | Timeout para reads offline |
| `maxRetries` | 5 | Máximo de tentativas antes de desistir |
| `syncDebounceMinutes` | 5 | Debounce entre syncs do mesmo ID |
| `batchSize` | 500 | Max operações por batch do Firestore |
| `conflictStrategy` | serverWins | Estratégia padrão de conflitos |
| `autoSyncOnConnect` | true | Sync automático quando reconecta |

**Métodos**:
- `configure({...})` - Atualiza configurações
- `reset()` - Volta para defaults

---

### Sub-Phase 78.7: Exports e L10n

**Arquivo**: `lib/agro_core.dart`

Adicionar exports:
```
// Services (Sync Infrastructure - CORE-78)
export 'services/sync/sync_models.dart';
export 'services/sync/local_cache_manager.dart';
export 'services/sync/offline_queue_manager.dart';
export 'services/sync/data_integrity_manager.dart';
export 'services/sync/generic_sync_service.dart';
export 'services/sync/sync_config.dart';
```

**Strings L10n** (app_pt.arb / app_en.arb):

| Key | PT | EN |
|-----|----|----|
| `syncPending` | Sincronização pendente | Sync pending |
| `syncInProgress` | Sincronizando... | Syncing... |
| `syncComplete` | Sincronização concluída | Sync complete |
| `syncFailed` | Falha na sincronização | Sync failed |
| `syncConflict` | Conflito detectado | Conflict detected |
| `offlineMode` | Modo offline | Offline mode |
| `offlineQueueCount` | {count} operações pendentes | {count} pending operations |
| `syncRetrying` | Tentando novamente... | Retrying... |
| `syncOfflineQueued` | Salvo localmente, será sincronizado | Saved locally, will sync |

---

### Files Created

| File | Description |
|------|-------------|
| `lib/services/sync/sync_models.dart` | OfflineOperation (typeId 33), SyncMetadata, SyncStatus, OperationPriority (31), OperationType (32) |
| `lib/services/sync/local_cache_manager.dart` | Gerenciamento de cache Hive genérico com TTL e invalidação |
| `lib/services/sync/offline_queue_manager.dart` | Fila de operações offline com prioridade e batch processing |
| `lib/services/sync/data_integrity_manager.dart` | Hash SHA256, conflict detection e resolution |
| `lib/services/sync/generic_sync_service.dart` | Classe base abstrata com CRUD + sync |
| `lib/services/sync/sync_config.dart` | Configuração global de sync |
| `lib/services/sync/sync_models.g.dart` | GERADO via build_runner |

### Files Modified

| File | Changes |
|------|---------|
| `lib/agro_core.dart` | Export dos 6 novos arquivos de sync |
| `lib/l10n/arb/app_pt.arb` | 9 strings de sync/offline |
| `lib/l10n/arb/app_en.arb` | 9 strings de sync/offline |

---

### Dependências

Verificar se já existem no pubspec.yaml do agro_core:
- `hive_flutter` ✅ (já existe)
- `crypto` (para SHA256) - **ADICIONAR se não existir**
- `connectivity_plus` (para detectar online/offline) - **OPCIONAL, pode usar flag manual**

---

### Ordem de Implementação

1. **sync_models.dart** - Não tem dependências
2. **sync_config.dart** - Não tem dependências
3. **local_cache_manager.dart** - Não tem dependências
4. **data_integrity_manager.dart** - Usa crypto para hash
5. **offline_queue_manager.dart** - Usa sync_models, local_cache_manager
6. **generic_sync_service.dart** - Usa todos os anteriores
7. **Rodar build_runner** para gerar sync_models.g.dart
8. **Atualizar exports** em agro_core.dart
9. **Adicionar L10n** strings

---

### Testes de Validação

Após implementação, testar:

1. **CRUD local** - Criar/ler/atualizar/deletar com syncEnabled=false
2. **Offline queue** - Criar operações offline, verificar que são enfileiradas
3. **Sync online** - Com syncEnabled=true, verificar que chega no Firestore
4. **Delta sync** - Modificar documento no Firestore, verificar que sync traz apenas alterado
5. **Conflito** - Modificar mesmo documento local e remoto, verificar detecção de conflito
6. **Batch** - Enfileirar 600 operações, verificar que são processadas em 2 batches

---

### Cross-Reference

- **CORE-77**: EnhancedBackupProvider pode ser adaptado para usar GenericSyncService
- **CASH-03**: Será desbloqueado após esta fase (cross-app sync via Firestore)
- **generic_service_v3.dart**: Referência original em `examples/planejacampo/lib/services/`

---

### Migration Guide

Apps que quiserem migrar seus services existentes para GenericSyncService:

**Passo 1**: Adicionar import
```dart
import 'package:agro_core/services/sync/generic_sync_service.dart';
```

**Passo 2**: Mudar extends
```dart
// ANTES
class DespesaService extends ChangeNotifier { ... }

// DEPOIS
class DespesaService extends GenericSyncService<Despesa> { ... }
```

**Passo 3**: Implementar abstratos
```dart
@override
String get sourceApp => 'rurarubber';

@override
Despesa fromMap(Map<String, dynamic> map) => Despesa.fromJson(map);

@override
Map<String, dynamic> toMap(Despesa item) => item.toJson();

@override
String getId(Despesa item) => item.id;
```

**Passo 4**: Chamar super no construtor
```dart
DespesaService._() : super(boxName: 'despesas', syncEnabled: false);
```

**Passo 5**: Remover boilerplate
- Remover `Box<T>? _box`
- Remover `init()` (usa o do pai)
- Remover CRUD básico (usa do pai)
- Manter apenas métodos específicos do domínio (ex: `totalPorSafra()`)

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
