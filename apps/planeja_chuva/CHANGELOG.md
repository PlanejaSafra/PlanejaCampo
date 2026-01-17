# CHANGELOG - planeja_chuva

---

## Análise Crítica da Proposta

### Pontos Fortes da Proposta Original

1. **Foco no MVP**: Separação clara entre funcionalidades essenciais e futuras
2. **Offline-First**: Alinhado com a realidade do campo (sem internet)
3. **Estrutura de Fases**: Organização lógica e incremental
4. **Integração com Core**: Reutilização de componentes (tema, menu, privacidade)

### Críticas e Melhorias Propostas

#### 1. Complexidade Desnecessária
- **UUID**: Para um app local, UUID é overkill. Usar `DateTime.now().millisecondsSinceEpoch` como ID é mais simples e suficiente.
- **ValueListenableBuilder**: Adiciona complexidade. Para MVP, `setState` após operações CRUD é mais simples e entendível.
- **Repository Pattern**: Para um app simples, acesso direto ao Hive Box é suficiente. Repository pode vir depois se necessário.

#### 2. Priorização do Usuário Final
- **Homem do Campo**: Interface deve ter botões GRANDES, textos LEGÍVEIS, fluxos CURTOS.
- **Registro Rápido**: O registro de chuva deve ser possível em NO MÁXIMO 3 toques (FAB → valor → salvar).
- **Data Padrão**: SEMPRE defaultar para HOJE. 90% dos registros são "acabou de chover".

#### 3. Funcionalidades Repensadas
- **Gráficos (fl_chart)**: ADIAR. Complexidade de dependência e manutenção. MVP deve mostrar números simples.
- **Backup JSON**: Simplificar. Exportar como texto simples que pode ser copiado/colado no WhatsApp.
- **Filtros Avançados**: ADIAR. Para MVP, scroll infinito com separadores de mês é suficiente.

#### 4. Decisões Técnicas Simplificadas
- **State Management**: Nenhum package extra. `StatefulWidget` + `setState` para MVP.
- **Navegação**: `Navigator.push/pop` simples. Sem GoRouter.
- **Formulários**: Validação inline simples, sem packages de forms.

### Princípios de Design para o Homem do Campo

1. **Menos é Mais**: Cada tela deve ter UM propósito claro
2. **Feedback Visual**: Cores fortes, ícones grandes, confirmações visuais
3. **Tolerância a Erros**: Confirmação antes de deletar, desfazer quando possível
4. **Modo Noturno**: Produtor acorda cedo, pode registrar às 5h da manhã

---

## Phase 6.0: Backup e Compartilhamento

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Permitir exportar e importar dados de chuva de forma simples.

### Contexto
O produtor precisa ter segurança de que seus dados não serão perdidos se trocar de celular. A solução deve ser SIMPLES: compartilhar um arquivo que pode ser guardado no WhatsApp ou Google Drive.

### Requisitos Funcionais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| 6.1 | Exportar todos os registros para arquivo JSON | Alta |
| 6.2 | Botão "Compartilhar" que abre share sheet do sistema | Alta |
| 6.3 | Importar dados de arquivo JSON | Média |
| 6.4 | Detectar e evitar duplicatas na importação | Média |
| 6.5 | Mostrar resumo antes de importar (X registros encontrados) | Baixa |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/services/backup_service.dart` | CREATE | Lógica de export/import JSON |
| `lib/screens/backup_screen.dart` | CREATE | Tela com botões Exportar/Importar |
| Drawer menu | MODIFY | Adicionar item "Backup" |

### Considerações Técnicas
- Usar `share_plus` para compartilhamento
- Formato JSON legível (pretty print)
- Incluir metadados: versão do app, data do backup, total de registros

---

## Phase 5.0: Resumos e Estatísticas Simples

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Mostrar informações úteis sobre o histórico de chuvas sem gráficos complexos.

### Contexto
O produtor quer saber: "Quanto choveu este mês?", "E no mês passado?", "Qual foi a maior chuva?". Respostas devem ser NÚMEROS GRANDES e CLAROS.

### Requisitos Funcionais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| 5.1 | Card na home mostrando total do mês atual (destaque) | Alta |
| 5.2 | Card mostrando total do mês anterior (comparação) | Alta |
| 5.3 | Tela de estatísticas com: total do ano, média por chuva, maior chuva registrada | Média |
| 5.4 | Indicador visual se mês atual está acima/abaixo do anterior | Baixa |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/widgets/resumo_mensal_card.dart` | CREATE | Card com total do mês |
| `lib/screens/estatisticas_screen.dart` | CREATE | Tela com estatísticas detalhadas |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Adicionar cards de resumo no topo |

### Considerações de UX
- Números em fonte GRANDE (32sp+)
- Cores: verde = acima da média, vermelho = abaixo
- Unidade sempre visível: "mm" ao lado do número
- Nenhum gráfico nesta fase (complexidade desnecessária para MVP)

---

## Phase 4.0: Edição e Exclusão de Registros

### Status: [TODO]
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Permitir corrigir erros e remover registros incorretos.

### Contexto
Erros acontecem: digitou 50mm ao invés de 5mm, ou registrou no dia errado. O produtor precisa poder corrigir SEM perder dados.

### Requisitos Funcionais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| 4.1 | Tocar em um registro abre tela de edição | Alta |
| 4.2 | Tela de edição idêntica à de adicionar, mas com dados preenchidos | Alta |
| 4.3 | Botão "Excluir" na tela de edição (com confirmação) | Alta |
| 4.4 | Diálogo de confirmação: "Tem certeza que deseja excluir?" | Alta |
| 4.5 | SnackBar com opção "Desfazer" após exclusão | Média |
| 4.6 | Swipe-to-delete na lista (alternativa ao botão) | Baixa |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/screens/editar_chuva_screen.dart` | CREATE | Tela de edição (reutiliza form de adicionar) |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Adicionar onTap para navegar à edição |
| `lib/widgets/registro_chuva_tile.dart` | MODIFY | Suportar Dismissible para swipe |

### Considerações de UX
- Botão excluir deve ser VERMELHO e posicionado longe do "Salvar"
- Confirmação obrigatória antes de excluir
- Mostrar claramente qual registro está sendo editado (data no AppBar)

---

## Phase 3.0: Registro de Nova Chuva

### Status: [TODO]
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Permitir registrar uma nova chuva de forma rápida e simples.

### Contexto
Este é o CORE do app. O produtor acabou de medir a chuva no pluviômetro e quer registrar. Deve ser possível em MENOS DE 10 SEGUNDOS.

### Requisitos Funcionais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| 3.1 | FAB (botão flutuante) visível e grande na tela principal | Alta |
| 3.2 | Tela de registro com campo de milímetros (numérico) | Alta |
| 3.3 | Campo de data com default = HOJE | Alta |
| 3.4 | Botão grande "SALVAR" no final da tela | Alta |
| 3.5 | Validação: valor deve ser > 0 e ≤ 500mm | Alta |
| 3.6 | Campo opcional de observação (ex: "chuva com granizo") | Média |
| 3.7 | Feedback visual após salvar (SnackBar verde) | Alta |
| 3.8 | Voltar automaticamente para lista após salvar | Alta |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/screens/adicionar_chuva_screen.dart` | CREATE | Tela de registro |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Adicionar FAB com navegação |
| `lib/l10n/` | MODIFY | Adicionar strings da tela |

### Fluxo de Interação
```
1. Usuário toca no FAB (+)
2. Abre tela com campo de mm focado e teclado numérico aberto
3. Digita valor (ex: 25)
4. [Opcional] Ajusta data se não for hoje
5. [Opcional] Adiciona observação
6. Toca "SALVAR"
7. Retorna à lista com SnackBar "Chuva de 25mm registrada!"
```

### Considerações de UX
- Campo de mm deve ter fonte GRANDE (48sp+)
- Teclado numérico deve abrir automaticamente
- Botão salvar deve ocupar toda a largura inferior
- Data picker deve mostrar calendário visual, não dropdown

---

## Phase 2.5: Lista de Registros de Chuva

### Status: [TODO]
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Exibir histórico de chuvas registradas de forma clara e organizada.

### Contexto
O produtor quer ver rapidamente: "Quando choveu?", "Quanto choveu?". A lista é a principal interface do app após o onboarding.

### Requisitos Funcionais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| 2.5.1 | Lista ordenada por data (mais recente primeiro) | Alta |
| 2.5.2 | Cada item mostra: data, valor em mm, observação (se houver) | Alta |
| 2.5.3 | Separadores visuais por mês/ano | Alta |
| 2.5.4 | Estado vazio amigável quando não há registros | Alta |
| 2.5.5 | Pull-to-refresh para recarregar lista | Baixa |
| 2.5.6 | Ícone indicativo de intensidade (garoa, chuva, tempestade) | Baixa |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/widgets/registro_chuva_tile.dart` | CREATE | Widget do item da lista |
| `lib/widgets/separador_mes.dart` | CREATE | Header de separação por mês |
| `lib/widgets/estado_vazio.dart` | CREATE | Widget para lista vazia |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Implementar ListView com dados reais |

### Design do Item da Lista
```
┌─────────────────────────────────────┐
│ 🌧️  15 de Janeiro, 2026            │
│      32 mm                    💧    │
│      "Chuva forte à tarde"          │
└─────────────────────────────────────┘
```

### Considerações de UX
- Ícones de intensidade: 💧 (leve <10mm), 🌧️ (moderada 10-30mm), ⛈️ (forte >30mm)
- Valor em mm deve ser o elemento mais destacado visualmente
- Observação em texto menor e cor mais suave
- Separador de mês deve ser sticky (ficar fixo ao scrollar)

---

## Phase 2.4: Modelo de Dados e Persistência

### Status: [TODO]
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Definir estrutura de dados e implementar persistência com Hive.

### Contexto
Os dados de chuva precisam ser salvos localmente e sobreviver ao fechamento do app. Hive é o banco escolhido por ser rápido e offline-first.

### Modelo de Dados: RegistroChuva

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | int | Sim | Timestamp em milliseconds (chave única) |
| data | DateTime | Sim | Data da chuva |
| milimetros | double | Sim | Volume em mm (0.1 a 500.0) |
| observacao | String? | Não | Nota opcional |
| criadoEm | DateTime | Sim | Quando foi registrado (auditoria) |

### Arquivos a Criar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/models/registro_chuva.dart` | CREATE | Classe do modelo com @HiveType |
| `lib/models/registro_chuva.g.dart` | GENERATE | Adapter gerado pelo build_runner |
| `lib/services/chuva_service.dart` | CREATE | CRUD operations no Hive |

### Operações do ChuvaService

| Método | Descrição |
|--------|-----------|
| `init()` | Registra adapter e abre box |
| `listarTodos()` | Retorna todos registros ordenados por data |
| `adicionar(RegistroChuva)` | Salva novo registro |
| `atualizar(RegistroChuva)` | Atualiza registro existente |
| `excluir(int id)` | Remove registro |
| `totalDoMes(DateTime)` | Soma mm de um mês específico |

### Considerações Técnicas
- Box name: `'registros_chuva'`
- TypeId do HiveType: `1` (0 já usado pelo core para settings)
- Ordenação sempre por `data` DESC (mais recente primeiro)
- Validação de milimetros: min 0.1, max 500.0

---

## Phase 2.3: Localização (l10n) do App

### Status: [TODO]
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Adicionar todas as strings do app nos arquivos ARB.

### Strings Necessárias (PT-BR)

| Chave | Valor PT-BR |
|-------|-------------|
| appTitle | Planeja Chuva |
| listaVaziaTitle | Nenhuma chuva registrada |
| listaVaziaSubtitle | Toque no + para registrar sua primeira chuva |
| adicionarChuvaTitle | Registrar Chuva |
| campoMilimetros | Milímetros (mm) |
| campoData | Data |
| campoObservacao | Observação (opcional) |
| botaoSalvar | SALVAR |
| botaoCancelar | CANCELAR |
| botaoExcluir | EXCLUIR |
| confirmarExclusao | Tem certeza que deseja excluir este registro? |
| chuvaRegistrada | Chuva de {mm}mm registrada! |
| chuvaExcluida | Registro excluído |
| desfazer | DESFAZER |
| totalDoMes | Total do mês |
| mesAnterior | Mês anterior |
| estatisticas | Estatísticas |
| backup | Backup |
| exportarDados | Exportar dados |
| importarDados | Importar dados |
| erroValorInvalido | Digite um valor entre 0.1 e 500 mm |

### Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `lib/l10n/app_pt_BR.arb` | CREATE | Strings em português |
| `lib/l10n/app_en.arb` | CREATE | Strings em inglês |
| `l10n.yaml` | CREATE | Configuração do gen-l10n |

### Nota
O core já tem AgroLocalizations. Este app pode:
1. Usar as strings do core diretamente
2. Criar AppLocalizations próprio para strings específicas
3. Ou estender o ARB do core (preferível para manter DRY)

---

## Phase 2.0: Standard Menu Integration

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟢 ENHANCEMENT
**Objective**: Integrate agro_core standard menu (AgroDrawer) and base screens into planeja_chuva.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.0.1 | Create ListaChuvasScreen with AgroDrawer | ✅ DONE |
| 2.0.2 | Implement navigation to Settings, Privacy, About | ✅ DONE |
| 2.0.3 | Update main.dart to use ListaChuvasScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/lista_chuvas_screen.dart` | CREATE | Main screen with AgroDrawer and navigation |
| `lib/main.dart` | MODIFY | Import and use ListaChuvasScreen |

---

## Phase 1.0: Privacy Onboarding Integration

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟢 ENHANCEMENT
**Objective**: Integrate agro_core privacy onboarding flow into planeja_chuva app.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.0.1 | Update pubspec.yaml with dependencies | ✅ DONE |
| 1.0.2 | Update main.dart with Hive initialization | ✅ DONE |
| 1.0.3 | Add AgroPrivacyStore.init() call | ✅ DONE |
| 1.0.4 | Wrap home screen with AgroOnboardingGate | ✅ DONE |
| 1.0.5 | Add l10n delegates and supported locales | ✅ DONE |
| 1.0.6 | Remove unused platform folders (windows, linux, macos, web) | ✅ DONE |

---

## Roadmap Visual

```
DONE ─────────────────────────────────────────────────
  [1.0] Privacy Onboarding ✅
  [2.0] Menu Integration ✅

TODO ─────────────────────────────────────────────────
  [2.3] Localização (l10n) ⏳
  [2.4] Modelo de Dados (Hive) ⏳
  [2.5] Lista de Registros ⏳
  [3.0] Registro de Nova Chuva 🔴 MVP CORE
  [4.0] Edição e Exclusão ⏳
  [5.0] Resumos e Estatísticas ⏳
  [6.0] Backup e Compartilhamento ⏳

FUTURO ───────────────────────────────────────────────
  [7.0] Gráficos de Histórico
  [8.0] Sincronização de Dados Agregados
  [9.0] Notificações/Lembretes
```

---
