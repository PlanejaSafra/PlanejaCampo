# CHANGELOG - RuraRubber

> **Phase Prefix Migration**: From RUBBER-01 onwards, phases use the `RUBBER-` prefix instead of `BORRACHA-`.

---

## 🚀 ROADMAP: Evolução Financeira RuraRubber

> **Objetivo Estratégico**: Transformar o RuraRubber de "Calculadora de Peso" em "Gestor de Safra" completo.
> **Futuro**: Preparar a arquitetura para integração com o futuro app **RuraCash** (Controle de Despesas da Fazenda).
> **Multi-User**: Estrutura de dados preparada para futuro modelo fazenda-centric (ver CORE-75).

---

## Phase RUBBER-23: Sistema de Tabelas (D3/D4) - Opcional

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT (Feature Discovery)
**Objective**: Permitir controle de rotação de sangria (Tabelas D3/D4) de forma opcional e progressiva.

### Business Context
- O sistema D3/D4 é a rotação de sangria (sangrar tabela diferente a cada dia)
- Permite calcular **g/árvore** (indicador real de produtividade)
- Mas é complexo para iniciantes → deve ser **descoberto gradualmente**

### UX: Descoberta Progressiva (Não Obrigatório)

**Dia 1**: Usuário pesa tudo junto, sem tabelas
**Semana 2**: Sistema oferece: "Quer organizar por tabelas?"
**Se aceitar**: Wizard simples configura

```
┌─────────────────────────────────────────┐
│  Parceiro: Zé                           │
├─────────────────────────────────────────┤
│  Tabela: (opcional)                     │
│  ┌─────┬─────┬─────┬─────┐             │
│  │  1  │  2  │  3  │  4  │             │
│  └─────┴─────┴─────┴─────┘             │
│  [Não usar tabelas]  ← Escape fácil     │
│                                         │
│  [TECLADO NUMÉRICO...]                  │
└─────────────────────────────────────────┘
```

### Funcionalidades Avançadas (Quando Ativado)

| Feature | Descrição |
|---------|-----------|
| **g/árvore** | Calcula produtividade real (peso / nº árvores) |
| **Alerta Sangria Enforcada** | Avisa se sangrar mesma tabela 2x seguidas |
| **Sugestão Inteligente** | Destaca tabela provável baseado na sequência |
| **Comparativo Tabelas** | Qual tabela produz mais? |

### Modelo de Dados

```dart
class TabelaSangria {
  String id;
  String parceiroId;
  int numero;           // 1, 2, 3, 4
  int? arvoresEstimadas; // nullable - usuário pode não saber
}

class Pesagem {
  // ... campos existentes ...
  String? tabelaId;     // NULLABLE - tabelas são opcionais
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 23.1 | **Modelo TabelaSangria**: Entidade opcional vinculada ao Parceiro | ⏳ TODO |
| 23.2 | **Feature Flag**: Controle para ativar/desativar tabelas por parceiro | ⏳ TODO |
| 23.3 | **Wizard Configuração**: "Quantas tabelas? [3] [4] [5]" | ⏳ TODO |
| 23.4 | **Seletor na Pesagem**: Botões opcionais com "Não usar" | ⏳ TODO |
| 23.5 | **Cálculo g/árvore**: Analytics quando tabelas configuradas | ⏳ TODO |
| 23.6 | **Alerta Enforcada**: Aviso de repetição de tabela | ⏳ TODO |
| 23.7 | **Sugestão Inteligente**: Destacar próxima tabela provável | ⏳ TODO |

### L10n Keys Required
- `usarTabelas`: "Usar sistema de tabelas?"
- `quantasTabelas`: "Quantas tabelas?"
- `arvoresPorTabela`: "Árvores por tabela (estimado)"
- `naoUsarTabelas`: "Não usar tabelas"
- `tabelaSelecionada`: "Tabela {numero}"
- `alertaEnforcada`: "Atenção: Tabela {numero} foi sangrada ontem"
- `gramasArvore`: "g/árvore"
- `produtividadeTabela`: "Produtividade por Tabela"

---

## Phase RUBBER-22: Onboarding Simplificado (3 Perguntas Máximo)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL (First-Time User Experience)
**Objective**: Capturar informações essenciais no primeiro uso com mínimo de perguntas.

### UX Principle: "Mais de X perguntas, ele sai do programa"

Máximo **3 perguntas** no onboarding. Tudo mais é descoberto depois.

### O Fluxo de Onboarding

```
┌─────────────────────────────────────────┐
│  🌿 Bem-vindo ao RuraRubber!            │
├─────────────────────────────────────────┤
│                                         │
│  1. Nome do seu seringal:               │
│     [Seringal Santa Fé___________]      │
│     Sugestão: "Meu Seringal"            │
│                                         │
│  2. Você é:                             │
│     [👨‍🌾 Produtor]  [🪓 Sangrador]       │
│                                         │
│  3. Quantos sangradores você tem?       │
│     [Só eu] [1-2] [3-5] [6+]            │
│     (Só aparece se Produtor)            │
│                                         │
│         [COMEÇAR →]                     │
└─────────────────────────────────────────┘
```

### Regras de Simplificação

| Resposta | Consequência |
|----------|--------------|
| **"Só eu mesmo"** | Pula TODA complexidade de parceiros. Pesagem direta. |
| **"1-2 sangradores"** | Modo simples: cadastra parceiros manualmente depois |
| **"3-5" ou "6+"** | Oferece wizard: "Quer cadastrar agora?" (opcional) |
| **Sangrador** | Pede nome do "Patrão" (produtor) e seringal que trabalha |

### Smart Defaults

- **Nome padrão**: "Meu Seringal" (pode mudar depois)
- **Tabelas**: Desativadas por padrão (descoberta progressiva)
- **Safra**: Criada automaticamente (Setembro atual)
- **Parceiros**: Zero (cadastra conforme necessidade)

### Preparação Multi-User (CORE-75) ✅

> **Nota:** O modelo Farm já foi implementado no `agro_core` (CORE-75 DONE).
> Use `FarmService.instance.ensureDefaultFarm()` no onboarding.

```dart
// Usar FarmService do agro_core (já implementado!)
import 'package:agro_core/agro_core.dart';

// No onboarding, criar Farm com o nome informado pelo usuário
final farm = await FarmService.instance.createFarm(
  name: "Seringal Santa Fé",  // Nome digitado pelo usuário
  isDefault: true,
);

// Todos os dados vinculados à Farm, não ao User
final pesagem = Pesagem(
  farmId: farm.id,      // UUID: "farm-a1b2c3d4-..."
  createdBy: userId,    // Quem criou (auditoria)
  ...
);
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 22.1 | **OnboardingScreen**: Tela de boas-vindas com 3 perguntas | ⏳ TODO |
| 22.2 | **Profile Branch**: Fluxos diferentes para Produtor vs Sangrador | ⏳ TODO |
| 22.3 | **Skip Parceiros**: Se "Só eu", esconde menu de parceiros | ⏳ TODO |
| 22.4 | **Smart Defaults**: Nome, Safra, configurações automáticas | ⏳ TODO |
| 22.5 | **Farm Integration**: Usar FarmService.ensureDefaultFarm() do agro_core | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/onboarding_screen.dart` | CREATE | Wizard de 3 perguntas |
| `lib/services/onboarding_service.dart` | CREATE | Lógica de setup inicial (usa FarmService) |
| `lib/main.dart` | MODIFY | Detectar first-run, init FarmService, mostrar onboarding |

### Dependências do agro_core

| Componente | Uso |
|------------|-----|
| `FarmService` | Criar/gerenciar Farm do usuário |
| `FarmAdapter` | Registrar no Hive durante init |
| `Farm` | Modelo com UUID-based farmId |

### L10n Keys Required
- `bemVindoRuraRubber`: "Bem-vindo ao RuraRubber!"
- `nomeSeringal`: "Nome do seu seringal"
- `sugestaoNome`: "Meu Seringal"
- `voceE`: "Você é:"
- `produtor`: "Produtor"
- `sangrador`: "Sangrador"
- `quantosSangradores`: "Quantos sangradores você tem?"
- `soEu`: "Só eu mesmo"
- `umDois`: "1-2"
- `tresCinco`: "3-5"
- `seisMais`: "6+"
- `comecar`: "Começar"

---

## Phase RUBBER-20: Break-even Dinâmico (Funcionalidade Avassaladora)

### Status: [TODO]
**Priority**: 🔴 CRITICAL (Diferencial Competitivo)
**Objective**: Mostrar o custo de produção por Kg em tempo real, calculando margem de lucro automaticamente.

### O Problema
O produtor sabe por quanto vende (R$ 8,00/kg), mas raramente sabe quanto **custou** produzir aquele kg, considerando que a produção varia mês a mês.

### A Solução
Cruzar dados de Produção (Kg) com dados de Despesa (lançados manualmente ou importados do RuraCash).

### O Dashboard Mágico
```
"Sua produção custou R$ 3,45 por Kg nesta safra."
"Margem de Lucro Atual: 58%"
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 20.1 | **Modelo DespesaSafra**: Criar entidade para despesas associadas à safra (valor, categoria, data) | ⏳ TODO |
| 20.2 | **Tela Lançamento Rápido**: Input simples de despesa mensal (ou importar do RuraCash futuro) | ⏳ TODO |
| 20.3 | **Cálculo Break-even**: Fórmula (Total Despesas / Total Kg Produzido) = Custo/Kg | ⏳ TODO |
| 20.4 | **Dashboard Margem**: Card na Home mostrando Custo/Kg vs Preço Médio de Venda | ⏳ TODO |
| 20.5 | **Alertas Inteligentes**: "Atenção: seu custo subiu 12% este mês" | ⏳ TODO |

### Categorias de Despesa (Sugeridas)
- Mão de Obra (sangradores, diaristas)
- Adubos e Fertilizantes
- Defensivos
- Combustível/Diesel
- Manutenção de Equipamentos
- Outros

### Cross-Reference
- RURACASH-01 (Futuro app de despesas - integração via API)

---

## Phase RUBBER-19: Gestão de Pagamentos (Visão Comprador)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que Compradores (Usinas/Bancas) gerenciem pagamentos a produtores.

### Business Context
Para o comprador que usa o app para registrar compras de múltiplos produtores.

### O Fluxo
1. Comprador registra entrada de borracha → Gera **Obrigação de Pagamento**
2. Sistema calcula valor baseado no contrato
3. Painel "Contas a Pagar" mostra todos os produtores pendentes

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 19.1 | **Modelo ContaPagar**: Entidade vinculada à Entrega (produtor, valor, vencimento, status) | ⏳ TODO |
| 19.2 | **Tela Contas a Pagar**: Lista ordenada por vencimento, com filtros | ⏳ TODO |
| 19.3 | **Baixa em Lote**: Selecionar múltiplos produtores e marcar "Pago via PIX/TED" | ⏳ TODO |
| 19.4 | **Relatório de Compras**: Volume total comprado vs Valor pago, por Safra | ⏳ TODO |
| 19.5 | **Notificação de Vencimento**: Alerta 2 dias antes do pagamento | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/conta_pagar.dart` | CREATE | Modelo ContaPagar |
| `lib/screens/contas_pagar_screen.dart` | CREATE | Tela de gestão de pagamentos |
| `lib/services/conta_pagar_service.dart` | CREATE | Service para CRUD e cálculos |

---

## Phase RUBBER-18: Gestão de Recebíveis (Visão Produtor)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que produtores acompanhem valores a receber das usinas/bancas com UX mínima.

### UX Design Principles (3-Click Rule)
- **Popup Pós-Entrega**: Aparece imediatamente após salvar entrega
- **2 Campos Apenas**: Data prevista de recebimento + Comprador (opcional)
- **Skip fácil**: Botão "Pular" sempre disponível (não obrigatório)
- **Baixa com 1 toque**: Swipe ou tap para marcar como recebido

### O Fluxo Simplificado

```
1. [SALVAR ENTREGA] Usuário clica "Salvar" no fechamento
2. [POPUP AUTOMÁTICO] "Quando você vai receber?"
   ┌─────────────────────────────────────┐
   │  💰 Registrar Recebível?            │
   │                                     │
   │  Valor: R$ 2.450,00                 │
   │  (calculado da entrega)             │
   │                                     │
   │  Data prevista: [__ /__ /____] 📅   │
   │  Comprador:     [Usina X     ] ▼    │
   │                                     │
   │  [Pular]              [Salvar]      │
   └─────────────────────────────────────┘
3. [HOME SCREEN] Card resumo: "A receber: R$ X"
4. [BAIXA] Tap no item → "Recebeu?" → Sim/Não
```

### Dashboard Card (Home Screen)

```
┌─────────────────────────────────────┐
│ 💰 A Receber                        │
│                                     │
│ Esta semana:     R$ 2.450,00        │
│ Este mês:        R$ 8.200,00        │
│                                     │
│ [Ver todos →]                       │
└─────────────────────────────────────┘
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 18.1 | **Modelo TituloReceber**: Entidade simples (entregaId, valor, dataPrevista, comprador?, status) | ⏳ TODO |
| 18.2 | **RecebiveisService**: CRUD básico, query por status, totais por período | ⏳ TODO |
| 18.3 | **Popup Pós-Entrega**: BottomSheet que aparece após salvar entrega | ⏳ TODO |
| 18.4 | **Card Home**: Resumo "A Receber" com totais semanais/mensais | ⏳ TODO |
| 18.5 | **Lista Recebíveis**: Tela simples com status visual (pendente/recebido) | ⏳ TODO |
| 18.6 | **Baixa Rápida**: Swipe-to-complete ou tap para marcar recebido | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/titulo_receber.dart` | CREATE | Modelo TituloReceber simplificado |
| `lib/services/recebiveis_service.dart` | CREATE | Service para gestão de recebíveis |
| `lib/widgets/recebivel_popup.dart` | CREATE | BottomSheet pós-entrega |
| `lib/widgets/recebiveis_card.dart` | CREATE | Card resumo para Home |
| `lib/screens/recebiveis_screen.dart` | CREATE | Lista de recebíveis |
| `lib/screens/fechamento_entrega_screen.dart` | MODIFY | Trigger do popup após salvar |
| `lib/screens/home_screen.dart` | MODIFY | Adicionar RecebiveisCard |

### L10n Keys Required
- `registrarRecebivel`: "Registrar Recebível?"
- `dataPrevistaRecebimento`: "Data prevista"
- `compradorOpcional`: "Comprador (opcional)"
- `pular`: "Pular"
- `aReceberCard`: "A Receber"
- `estaSemana`: "Esta semana"
- `esteMes`: "Este mês"
- `verTodos`: "Ver todos"
- `marcarRecebido`: "Marcar como recebido"
- `recebido`: "Recebido"
- `pendente`: "Pendente"

---

## Phase RUBBER-17: Controle de Safras (Modelo Date Range)

### Status: [TODO]
**Priority**: 🔴 CRITICAL (Pré-requisito para fases financeiras)
**Objective**: Implementar controle de safra baseado em Janela de Tempo (Date Range), não acumulador.

### Arquitetura: Query-Based (Não Acumulador)

**Princípio Fundamental**: Não salvamos totais fixos. Salvamos pesagens individuais.
O total é **calculado na hora** via query de banco de dados.

```
❌ ERRADO (Acumulador fixo):
   safra.totalKg = 15400  // Se editar pesagem antiga, esse número "fura"

✅ CORRETO (Query dinâmica):
   SELECT SUM(peso) FROM pesagens
   WHERE data >= safra.dataInicio AND data < safra.dataFim
   // Sempre atualizado, mesmo com lançamentos retroativos
```

**Vantagem**: Se o produtor achar um papelzinho de Outubro e lançar hoje com data de Outubro,
o sistema atualiza o relatório da safra automaticamente.

### O Modelo Safra (agro_core - CORE-76)

> **Nota:** O modelo Safra será implementado no `agro_core` (CORE-76) para ser compartilhado
> por todos os apps (RuraRubber, RuraCrop, RuraCattle, RuraCash).

```dart
// Usar Safra e SafraService do agro_core
import 'package:agro_core/agro_core.dart';

// No RuraRubber, apenas adiciona farmId nas queries
final safra = await SafraService.instance.getSafraAtiva();
final totalKg = await pesagemService.getTotalPorSafra(safra);
```

### UX Design Principles
- **Zero Configuration**: Safra inicia automaticamente em Setembro
- **Ajuste Manual Opcional**: Usuário pode editar datas nas configurações se precisar
- **Encerramento Simples**: Botão "Encerrar Safra" define dataFim = HOJE e cria nova safra

### O Fluxo Simplificado

```
1. [PRIMEIRA VEZ] App cria "Safra Inicial" com dataInicio = 01/Set atual (ou data instalação)
2. [DURANTE ANO] Todas as pesagens são salvas com sua data original
3. [ENCERRAMENTO] Usuário clica "Encerrar Safra":
   - Sistema define dataFim = HOJE
   - Sistema cria nova safra com dataInicio = AMANHÃ
4. [AJUSTE] Se precisar, usuário edita datas nas configurações da Safra
```

### Season Chip in Header (Home Screen)

```
┌────────────────────────────────────────┐
│ [≡]  RuraRubber         [Safra 25/26 ▼]│
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ Total Fazenda: 25.000 kg         │  │
│  │ Média Mensal:   2.500 kg         │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 👤 Zé      10.000 kg  (40%)      │  │
│  │ 👤 Tião     8.000 kg  (32%)      │  │
│  │ 👤 Maria    7.000 kg  (28%)      │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### Visão Hierárquica: Fazenda > Parceiros

**Cabeçalho (Total da Fazenda)**:
- Somatório de TODOS os parceiros
- Gráfico de barras: Média Mensal da fazenda

**Lista de Parceiros**:
- Cards ordenados por produção
- Cada card mostra: Nome, Total Kg, % do total

**Drill-Down**:
- Clicar no parceiro → Tela exclusiva dele (ver RUBBER-21)

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 17.1 | **CORE-76 Dependency**: Aguardar/usar Safra e SafraService do agro_core | ⏳ TODO |
| 17.2 | **SafraChip Widget**: Chip compacto para header com nome abreviado (ex: "25/26") | ⏳ TODO |
| 17.3 | **SafraBottomSheet**: Lista de safras com resumo calculado dinamicamente | ⏳ TODO |
| 17.4 | **Home Dashboard**: Visão hierárquica (Total Fazenda + Lista Parceiros) | ⏳ TODO |
| 17.5 | **Filtro por Período**: Queries usam WHERE data BETWEEN dataInicio AND dataFim | ⏳ TODO |
| 17.6 | **Encerramento**: Botão "Encerrar Safra" com criação automática da próxima | ⏳ TODO |
| 17.7 | **Ajuste Manual**: Tela de configuração para editar datas se necessário | ⏳ TODO |

### Dependências do agro_core (CORE-76)

| Componente | Uso |
|------------|-----|
| `Safra` | Modelo com dataInicio, dataFim, ativa |
| `SafraService` | CRUD + getSafraAtiva() + encerrarSafra() |
| `SafraAdapter` | Registrar no Hive durante init |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/safra_chip.dart` | CREATE | Chip compacto para header (usa Safra do core) |
| `lib/widgets/safra_bottom_sheet.dart` | CREATE | Bottom sheet com lista e estatísticas |
| `lib/widgets/fazenda_summary_card.dart` | CREATE | Card com total da fazenda |
| `lib/widgets/parceiro_list_card.dart` | CREATE | Lista de parceiros com % |
| `lib/screens/home_screen.dart` | MODIFY | Dashboard hierárquico completo |
| `lib/screens/safra_settings_screen.dart` | CREATE | Configurações da safra (ajuste datas) |
| `lib/services/pesagem_service.dart` | MODIFY | Adicionar queries filtradas por safra |

### L10n Keys Required
- `safraChipLabel`: "{ano1}/{ano2}" (ex: "25/26")
- `totalFazenda`: "Total Fazenda"
- `mediaMensal`: "Média Mensal"
- `mediaQuinzenal`: "Média Quinzenal"
- `encerrarSafra`: "Encerrar Safra"
- `novaSafraCriada`: "Nova safra criada: {nome}"
- `ajustarDatas`: "Ajustar Datas"
- `dataInicio`: "Data Início"
- `dataFim`: "Data Fim"
- `safraAtiva`: "Safra Ativa"
- `safrasAnteriores`: "Safras Anteriores"
- `doTotal`: "do total"

---

## Phase RUBBER-21: Analytics do Parceiro (Raio-X)

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Gráficos detalhados de produção por parceiro com comparativo de média.

### Business Context
O patrão com múltiplos sangradores precisa:
- Ver quem está produzindo mais/menos
- Identificar quedas de produção (pode ser doença, problema, etc.)
- Comparar desempenho individual vs média da fazenda

### O "Raio-X" do Parceiro

Ao clicar no card do parceiro na Home, entra na tela de detalhes:

```
┌────────────────────────────────────────┐
│ [←]  Zé - Sangrador                    │
├────────────────────────────────────────┤
│                                        │
│  Total Safra: 10.000 kg                │
│  Média Quinzenal: 300 kg               │
│                                        │
│  [15 Dias] [Mês] [Safra]  ← Seletor    │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    ▓▓▓                           │  │
│  │    ▓▓▓  ▓▓▓                      │  │
│  │    ▓▓▓  ▓▓▓  ▓▓▓                 │  │
│  │ ───────────────────── (média)    │  │
│  │    1ª   2ª   1ª   2ª            │  │
│  │   Jan  Jan  Fev  Fev            │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Ver Extrato Financeiro]              │
└────────────────────────────────────────┘
```

### Seletor de Período (3 Visões)

| Visão | Eixo X | Uso |
|-------|--------|-----|
| **15 Dias** | 1ª Jan, 2ª Jan, 1ª Fev... | Ciclo de pagamento quinzenal |
| **Mês** | Janeiro, Fevereiro... | Curva da safra (pico vs seca) |
| **Safra** | Safra 24/25, Safra 25/26 | Comparativo anual |

### Recurso "Comparativo Fantasma"

Linha cinza clara no fundo do gráfico mostrando a **Média da Fazenda**.

**Interpretação visual**:
- Barra do Zé **acima** da linha cinza → Acima da média
- Barra do Zé **abaixo** da linha cinza → Precisa melhorar

```
  │    ▓▓▓
  │    ▓▓▓  ▓▓▓
  │────░░░──░░░──░░░───── ← Média Fazenda (linha cinza)
  │    ▓▓▓  ▓▓▓  ▓▓▓
  │   Jan  Fev  Mar
```

### Regra de Dados Mínimos (Cold Start Problem)

**Problema**: No primeiro mês, a "Média da Fazenda" pode ser instável (poucos dados).

**Solução**: Só mostrar a "Linha Fantasma" quando houver dados suficientes:

| Condição | Comportamento |
|----------|---------------|
| **< 2 parceiros ativos** | Não mostra linha fantasma (não faz sentido comparar) |
| **< 15 dias de dados** | Não mostra linha fantasma (média instável) |
| **≥ 2 parceiros E ≥ 15 dias** | Mostra linha fantasma normalmente |

```dart
bool shouldShowPhantomLine({
  required int activePartners,
  required int daysWithData,
}) {
  return activePartners >= 2 && daysWithData >= 15;
}
```

**UX**: Quando a linha não aparece, o gráfico funciona normalmente - só não tem a referência de comparação.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 21.1 | **ParceiroDetailScreen**: Tela de detalhes do parceiro | ⏳ TODO |
| 21.2 | **Period Selector**: Botões [15 Dias] [Mês] [Safra] | ⏳ TODO |
| 21.3 | **Bar Chart Widget**: Gráfico de barras com fl_chart | ⏳ TODO |
| 21.4 | **Média Fantasma**: Linha de referência da média da fazenda | ⏳ TODO |
| 21.5 | **Cold Start Guard**: Só mostrar linha fantasma se ≥2 parceiros E ≥15 dias | ⏳ TODO |
| 21.6 | **Cálculo Médias**: Quinzenal e Mensal baseados na safra | ⏳ TODO |
| 21.7 | **Extrato Financeiro**: Link para histórico de pagamentos do parceiro | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/parceiro_detail_screen.dart` | CREATE | Tela "Raio-X" do parceiro |
| `lib/widgets/period_selector.dart` | CREATE | Seletor [15 Dias] [Mês] [Safra] |
| `lib/widgets/production_bar_chart.dart` | CREATE | Gráfico de barras com fl_chart |
| `lib/services/analytics_service.dart` | CREATE | Cálculos de médias e comparativos |
| `lib/screens/home_screen.dart` | MODIFY | Navegação para ParceiroDetailScreen |
| `pubspec.yaml` | MODIFY | Adicionar fl_chart: ^0.68.0 |

### L10n Keys Required
- `raioXParceiro`: "Detalhes do Parceiro"
- `totalSafra`: "Total Safra"
- `mediaQuinzenal`: "Média Quinzenal"
- `mediaMensal`: "Média Mensal"
- `periodo15Dias`: "15 Dias"
- `periodoMes`: "Mês"
- `periodoSafra`: "Safra"
- `acimaDaMedia`: "Acima da média"
- `abaixoDaMedia`: "Abaixo da média"
- `verExtratoFinanceiro`: "Ver Extrato Financeiro"
- `mediaFazenda`: "Média Fazenda"

---

## Phase RUBBER-16: Melhorias UX Pesagem

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Pequenas melhorias na experiência de pesagem baseadas em feedback.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 16.1 | **Gestos de Swipe**: Deslizar para desfazer última pesagem | ⏳ TODO |
| 16.2 | **Feedback Sonoro**: Som de confirmação ao adicionar peso | ⏳ TODO |
| 16.3 | **Modo Noturno Pesagem**: Tela mais escura para uso à noite | ⏳ TODO |
| 16.4 | **Atalho Valores Frequentes**: Botões +50, +100, +150 kg | ⏳ TODO |

---

## Phase RUBBER-15: Job Classifieds (Vagas e Disponibilidade)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir que Sangradores publiquem disponibilidade para trabalho e Produtores publiquem vagas em seus seringais.

### Business Context
- **Sangradores** podem postar "Estou disponível para trabalho na região X"
- **Produtores** podem postar "Preciso de sangrador para meu seringal"
- Ambos podem se conectar via WhatsApp
- Diferente de ofertas de compra/venda - são anúncios de mão de obra

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 15.1 | **Model JobPost**: Criar modelo Firestore para anúncios de vagas/disponibilidade | ✅ DONE |
| 15.2 | **JobListScreen**: Tela de listagem de vagas/disponibilidades com filtro por região | ✅ DONE |
| 15.3 | **CreateJobScreen**: Formulário para criar anúncio (tipo, região, descrição, contato) | ✅ DONE |
| 15.4 | **WhatsApp Integration**: Botão de contato direto via WhatsApp | ✅ DONE |
| 15.5 | **Profile-based UI**: Sangrador vê vagas, Produtor vê sangradores disponíveis | ✅ DONE |
| 15.6 | **L10n Strings**: Adicionar todas as strings em pt-BR e en | ✅ DONE |
| 15.7 | **Routes & Navigation**: Adicionar rotas /jobs e /criar-vaga ao main.dart | ✅ DONE |
| 15.8 | **Drawer Integration**: Adicionar item Jobs ao drawer de todas as telas | ✅ DONE |

### Data Model: JobPost (Firestore)

```dart
enum JobType { offeringWork, seekingWork }

class JobPost {
  String id;
  String userId;
  String userName;
  JobType type; // offeringWork (Produtor) | seekingWork (Sangrador)
  List<String> regions;
  String description;
  String contactPhone;
  double? offeredPercentage; // % oferecido ao sangrador
  int? treesCount; // árvores em sangria
  String? municipality; // município
  DateTime createdAt;
  DateTime validUntil;

  bool get isExpiringSoon => daysRemaining <= 2;
  int get daysRemaining => validUntil.difference(DateTime.now()).inDays;
}
```

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/job_post.dart` | CREATE | Modelo JobPost com enum JobType, fromFirestore, toFirestore |
| `lib/screens/job_list_screen.dart` | CREATE | Lista com TabBar (Vagas/Disponíveis), filtro região, WhatsApp |
| `lib/screens/criar_vaga_screen.dart` | CREATE | Formulário com seletor de tipo, campos condicionais |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 35+ novas strings para jobs |
| `lib/l10n/arb/app_en.arb` | MODIFY | 35+ novas strings para jobs |
| `lib/main.dart` | MODIFY | Rotas /jobs e /criar-vaga |

---

## Phase RUBBER-14: Sell Offers (Ofertas de Venda - Produtor)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir que Produtores publiquem ofertas de venda de borracha ("Tenho X kg disponível"), complementando o Mercado que atualmente só tem ofertas de compra.

### Business Context
- Atualmente o Mercado só mostra **ofertas de COMPRA** (compradores postam preços)
- Esta fase adiciona **ofertas de VENDA** (produtores postam disponibilidade)
- Compradores podem ver o que está disponível na região
- Sistema bidirecional de matchmaking

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 14.1 | **Extend MarketOffer Model**: Adicionar campo `offerType` (buy/sell), municipality, treesInTapping, estimatedWeight | ✅ DONE |
| 14.2 | **Update CriarOfertaScreen**: Suportar tipo de oferta (buy/sell) com campos específicos | ✅ DONE |
| 14.3 | **Update MercadoScreen**: Tabs para Compras vs Vendas, exibição de campos extras | ✅ DONE |
| 14.4 | **Price Negotiable**: Para ofertas de venda, preço é opcional ("preço a combinar") | ✅ DONE |
| 14.5 | **Expiration Warning**: Alerta visual quando oferta está próxima de vencer (2 dias) | ✅ DONE |
| 14.6 | **WhatsApp Message**: Mensagem contextual diferente para ofertas de venda | ✅ DONE |
| 14.7 | **L10n Strings**: 25+ novas strings em pt-BR e en | ✅ DONE |

### Extended MarketOffer Model

```dart
enum OfferType { buy, sell }

class MarketOffer {
  // ... existing fields ...
  OfferType offerType; // buy (comprador) or sell (produtor)
  double? priceDrc; // NOW NULLABLE for "preço a combinar"
  double? availableKg; // quantidade disponível (para sell)
  String? municipality; // município
  int? treesInTapping; // árvores em sangria
  double? estimatedWeight; // peso estimado

  bool get isPriceNegotiable => priceDrc == null && priceWet == null;
  bool get isExpiringSoon => daysRemaining <= 2;
}
```

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/market_offer.dart` | MODIFY | Added OfferType enum, nullable prices, municipality, treesInTapping, estimatedWeight, expiration helpers |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Buy/sell type selector, production details section, optional prices for sell |
| `lib/screens/mercado_screen.dart` | MODIFY | TabBar for buy/sell filtering, expiration warning badge, municipality/trees/weight display |
| `lib/l10n/arb/app_pt.arb` | MODIFY | 25+ new localized strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | 25+ new localized strings |

---

## Phase RUBBER-13: Social Sharing (Compartilhamento de Peso)

### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🔵 FIX
**Objective**: Permitir compartilhamento rápido do peso atual via WhatsApp com visual atraente (card de imagem), além do PDF já existente.

### Business Context
- Atualmente só existe PDF de fechamento completo
- Usuários querem compartilhar peso rapidamente durante a pesagem
- Similar ao "Rain Card" do RuraRain - imagem visual para redes sociais
- Usa compartilhamento nativo do sistema (igual PIX receipt)

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 13.1 | **ShareService**: Serviço centralizado de compartilhamento (captura widget como imagem, share_plus) | ✅ DONE |
| 13.2 | **WeightCardWidget**: Widget visual do card de peso com gradiente verde | ✅ DONE |
| 13.3 | **ImageGenerator**: RepaintBoundary + toImage para converter widget em PNG | ✅ DONE |
| 13.4 | **showShareWeightDialog**: Dialog que auto-compartilha via nativo do sistema | ✅ DONE |
| 13.5 | **Share Button on TapeView**: Botão de compartilhar no total acumulado (quando há pesagens) | ✅ DONE |
| 13.6 | **L10n Strings**: Strings de compartilhamento em pt-BR e en | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/share_service.dart` | CREATE | captureWidgetAsImage, shareImage, shareText, generateQuickShareText |
| `lib/widgets/weight_card_widget.dart` | CREATE | WeightCardWidget, showShareWeightDialog function |
| `lib/screens/pesagem_screen.dart` | MODIFY | Added onShare callback to TapeViewWidget |
| `lib/widgets/tape_view_widget.dart` | MODIFY | Added onShare callback, share icon button |
| `lib/l10n/arb/app_pt.arb` | MODIFY | shareTitle, shareAsImage, shareAsText, shareWeightButton, etc. |
| `lib/l10n/arb/app_en.arb` | MODIFY | English translations for share strings |

### Dependencies
- `share_plus: ^10.1.4` - From agro_core (native system share like PIX receipt)

---

## Phase RUBBER-12: Profile UX & Navigation Fixes

### Status: [TODO]
**Priority**: 🔵 FIX
**Objective**: Fix multiple UX issues related to profile display, navigation consistency, terminology clarity, and About screen branding.

### Problems Identified

1. **Profile Not Shown in Menu**: After selecting a profile (Producer/Tapper/Buyer), there's no visual indication in the drawer or main screen.

2. **Mercado Firestore Error**: Users see "sem permissões para visualizar" when accessing the Market screen. Needs to verify Firestore security rules and macroregion filtering.

3. **Menu Navigation Inconsistent**: Clicking the drawer on certain screens doesn't show all navigation options. Some screens have incomplete `extraItems` in their `AgroDrawer`.

4. **Partner/Producer Naming Confusion**:
   - When in **Tapper profile**, the "Parceiro" field during weighing should show the **Producer's name** (who owns the seringal)
   - When in **Producer profile**, the "Parceiro" field should show the **Tapper's name**
   - The **percentage is ALWAYS the Tapper's percentage** (their cut of the sale)

5. **About Screen Inconsistent**: The About screen on some screens shows the old tractor icon instead of the RuraRubber app icon. Need to pass `appLogoLightPath` and `appLogoDarkPath` consistently.

6. **Property Name for Tapper**: When selecting the Tapper profile, the property should be called "Seringal" and the user should be prompted to enter a name, not use the default "Minha Propriedade".

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 12.1 | **Profile in Drawer**: Pass current profile to `AgroDrawer` via new `profileName` parameter | ⏳ TODO |
| 12.2 | **Fix Mercado Firestore**: Review security rules, add proper error handling, check macroregion query | ⏳ TODO |
| 12.3 | **Standardize Drawer extraItems**: Ensure all screens with `AgroDrawer` have the same extraItems for consistent navigation | ⏳ TODO |
| 12.4 | **Clarify Partner Terminology**: Update UI labels based on profile - "Produtor" vs "Sangrador" context | ⏳ TODO |
| 12.5 | **Fix About Screen Logos**: Pass correct `appLogoLightPath`/`appLogoDarkPath` to all `AgroAboutScreen` usages | ⏳ TODO |
| 12.6 | **Property Naming Flow**: Prompt for property/seringal name during profile selection | ⏳ TODO |

### Files to Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/home_screen.dart` | MODIFY | Add profile display, standardize drawer, fix About screen |
| `lib/screens/pesagem_screen.dart` | MODIFY | Standardize drawer, fix partner terminology, fix About screen |
| `lib/screens/mercado_screen.dart` | MODIFY | Add error handling, standardize drawer, check query |
| `lib/screens/profile_selection_screen.dart` | MODIFY | Add property name prompt after profile selection |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add terminology strings (producerLabel, tapperLabel, seringalName) |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add terminology strings |
| `firestore.rules` | REVIEW | Check market_offers collection permissions |

### Cross-Reference
- CORE-67 (Profile Display in AgroDrawer)

---

## Phase RUBBER-01: Rebranding PlanejaBorracha → RuraRubber
### Status: [DONE]
**Date Completed**: 2026-01-25
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Rebrand from PlanejaBorracha to RuraRubber for internationalization. Migrate folder structure, package IDs, Firebase configuration, and all branding references.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | Rename folder `apps/planejaaborracha` → `apps/rurarubber` | ✅ DONE |
| 1.2 | Update `pubspec.yaml` with new name | ✅ DONE |
| 1.3 | Update `android/app/build.gradle` (namespace, applicationId, flavors) | ✅ DONE |
| 1.4 | Create Kotlin package `com/ruracamp/rubber/` and move MainActivity.kt | ✅ DONE |
| 1.5 | Update iOS PRODUCT_BUNDLE_IDENTIFIER to `com.ruracamp.rubber` | ✅ DONE |
| 1.6 | Configure Firebase for dev (`ruracamp-dev`) and prod (`ruracamp-c1f38`) | ✅ DONE |
| 1.7 | Create flavor structure with separate google-services.json | ✅ DONE |
| 1.8 | Update all Dart files with RuraRubber branding | ✅ DONE |
| 1.9 | Update ARB files (app_pt.arb, app_en.arb) | ✅ DONE |
| 1.10 | Update BackupProvider key from 'planeja_borracha' to 'rura_rubber' | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | name: planejaaborracha → rurarubber |
| `android/app/build.gradle` | MODIFY | namespace/applicationId to com.ruracamp.rubber, flavors to RuraRubber |
| `android/app/src/main/kotlin/com/ruracamp/rubber/MainActivity.kt` | CREATE | New Kotlin package location |
| `android/app/src/main/kotlin/br/com/planejacampo/planejaaborracha/` | DELETE | Old Kotlin package structure |
| `android/app/src/dev/google-services.json` | CREATE | Firebase config for dev (ruracamp-dev) |
| `android/app/src/prod/google-services.json` | CREATE | Firebase config for prod (ruracamp-c1f38) |
| `ios/Runner.xcodeproj/project.pbxproj` | MODIFY | PRODUCT_BUNDLE_IDENTIFIER to com.ruracamp.rubber |
| `lib/main.dart` | MODIFY | Renamed PlanejaBorrachaApp to RuraRubberApp, updated branding |
| `lib/screens/*.dart` | MODIFY | Updated PlanejaBorracha references to RuraRubber |
| `lib/services/borracha_backup_provider.dart` | MODIFY | key: 'planeja_borracha' → 'rura_rubber' |
| `lib/services/backup_service.dart` | MODIFY | Updated app identifier and branding |
| `lib/l10n/arb/app_pt.arb` | MODIFY | appName and branding strings to RuraRubber |
| `lib/l10n/arb/app_en.arb` | MODIFY | appName and branding strings to RuraRubber |
| `lib/firebase_options.dart` | CREATE | Generated by flutterfire configure |

### Configuration Details

**Android:**
- Package: `com.ruracamp.rubber`
- Flavors: `dev` (RuraRubber Dev), `prod` (RuraRubber)
- Firebase Dev App ID: `1:447693754827:android:1359a65bb46ad3c622264e`
- Firebase Prod App ID: `1:298390927056:android:ee917222f15733cb3ed0d5`

**iOS:**
- Bundle ID: `com.ruracamp.rubber`
- Firebase Dev App ID: `1:447693754827:ios:6a50de3e827a8ace22264e`
- Firebase Prod App ID: `1:298390927056:ios:cb740f7b51a31f313ed0d5`

**Cross-Reference**: CORE-70 (agro_core umbrella phase for rebranding)

---

## Phase BORRACHA-11: UI Refactor - Weather & Navigation
### Status: [IN PROGRESS]
**Date Started**: 2026-01-25
**Priority**: 🟡 ENHANCEMENT
**Objective**: Refine the Home Screen and Navigation based on user feedback to prioritize Weather context and simplify role-based access.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 11.1 | **Weather Widget Integration**: Replace "Quick Actions" grid with `WeatherCard` (from `agro_core`) to provide immediate climate context for the property/seringal. | ⏳ PENDING |
| 11.2 | **Role-Based Navigation**: Remove "Parceiros" menu item and access for "Sangrador" profile, as they don't manage other partners. | ⏳ PENDING |
| 11.3 | **Layout Optimization**: Keep Floating Action Button (FAB) for primary actions ("Nova Pesagem") and maintain Monthly Summary/Recent Deliveries for quick insights. | ⏳ PENDING |

### Files to Modify
- `lib/screens/home_screen.dart`
- `package/agro_core/lib/widgets/agro_drawer.dart` (Conceptually, via composition)

---

## Phase BORRACHA-10: Fix Restore Data (Replace vs Merge)

### Status: [DONE]
**Date Completed**: 2026-01-24
**Priority**: 🔵 FIX
**Objective**: Fix cloud restore to REPLACE data instead of MERGE.
**Cross-Reference**: CORE-63

### Problem
When restoring from backup, parceiros and entregas were merged with backup data instead of being replaced. Records created after the backup was made would still exist after restore.

### Solution
1. Added `clearAll()` method to ParceiroService
2. Added `clearAll()` method to EntregaService
3. Modified `BorrachaBackupProvider.restoreData()` to call both clear methods before importing backup records

### Files Modified
| File | Action | Description |
|------|--------|-------------|
| `lib/services/parceiro_service.dart` | MODIFY | Added `clearAll()` method |
| `lib/services/entrega_service.dart` | MODIFY | Added `clearAll()` method |
| `lib/services/borracha_backup_provider.dart` | MODIFY | Call clear before restore |

---

## Phase BORRACHA-09: Cloud Sync & Local Backup Integration
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟢 ENHANCEMENT
**Objective**: Implement complete backup/restore system with cloud sync (via CloudBackupService) and local JSON export/import, matching PlanejaChuva's functionality.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 9.1 | Create `BorrachaBackupProvider` implementing `BackupProvider` interface | ✅ DONE |
| 9.2 | Create `BackupService` for local JSON export/import with Share integration | ✅ DONE |
| 9.3 | Register `BorrachaBackupProvider` with `CloudBackupService` in main() | ✅ DONE |
| 9.4 | Add local backup callbacks to `AgroSettingsScreen` route | ✅ DONE |
| 9.5 | Add `file_picker` dependency for import functionality | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/borracha_backup_provider.dart` | CREATE | Cloud sync provider - serializes/deserializes Parceiro and Entrega data to JSON |
| `lib/services/backup_service.dart` | CREATE | Local backup service - exportar(), parseBackup(), importar() with duplicate detection |
| `lib/main.dart` | MODIFY | Register cloud provider, add inline callbacks for local backup in /settings route |
| `pubspec.yaml` | MODIFY | Add file_picker: ^8.1.6 dependency |

### Implementation Details

**BorrachaBackupProvider (Cloud Sync):**
- Implements `BackupProvider` interface from agro_core
- `key`: 'planeja_borracha' (unique identifier)
- `getData()`: Serializes all Parceiro and Entrega data to JSON format
- `restoreData()`: Deserializes JSON, imports avoiding duplicates, uses Hive box directly for entregas
- Handles ItemEntrega fields correctly (valorTotal, descontos, not drc/precoKg)

**BackupService (Local Backup):**
- `exportar()`: Creates timestamped JSON file, shares via Share.shareXFiles
- `parseBackup()`: Validates backup structure, parses JSON to model objects
- `importar()`: Imports data avoiding duplicates by checking existing IDs
- Returns `ImportResult` with counts of imported items and duplicates
- Uses Hive.openBox for direct Entrega persistence

**Main Integration:**
- Registered BorrachaBackupProvider in main() initialization
- Added inline lambda callbacks to AgroSettingsScreen route:
  - `onExportLocalBackup`: Calls BackupService.exportar() with error handling
  - `onImportLocalBackup`: Uses FilePicker, parses JSON, calls BackupService.importar()
- Both callbacks show SnackBars for success/error feedback

### Fixes Applied

**Model Field Corrections:**
- ❌ **ItemEntrega.drc/precoKg don't exist** → ✅ Use valorTotal/descontos instead
- ❌ **ParceiroService.adicionarParceiro()** → ✅ Correct method is addParceiro()
- ❌ **EntregaService.salvarEntrega() missing** → ✅ Save directly to Hive box

**Architecture:**
- ✅ Follows agro_core BackupProvider pattern (same as PlanejaChuva)
- ✅ Local backup uses Share plugin for file distribution
- ✅ Duplicate detection on import (by ID comparison)
- ✅ Proper error handling with user feedback

---

## Phase BORRACHA-08: UX Overhaul - Dashboard, Profile & Smart Auth
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Transformar o fluxo do app de "cair direto na pesagem" para experiência completa com dashboard, seleção de perfil (Produtor/Comprador), e navegação inteligente.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 8.1 | Create `UserProfile` model with `UserProfileType` enum (Hive) | ✅ DONE |
| 8.2 | Create `UserProfileService` singleton for profile management | ✅ DONE |
| 8.3 | Create `ProfileSelectionScreen` with Produtor/Comprador cards | ✅ DONE |
| 8.4 | Create `HomeScreen` (Dashboard) with profile-based content | ✅ DONE |
| 8.5 | Add L10n strings for new screens (pt-BR and en) | ✅ DONE |
| 8.6 | Modify `main.dart` to use HomeScreen as entry point | ✅ DONE |
| 8.7 | Integrate profile check in auth flow | ✅ DONE |
| 8.8 | Update documentation (README, ARCHITECTURE) | ✅ DONE |
| 8.9 | Fix Propriedades navigation to use core PropertyListScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/user_profile.dart` | CREATE | UserProfile model with Hive adapters |
| `lib/models/user_profile.g.dart` | CREATE | Generated Hive adapter |
| `lib/services/user_profile_service.dart` | CREATE | Profile management service |
| `lib/screens/profile_selection_screen.dart` | CREATE | Profile type selection UI |
| `lib/screens/home_screen.dart` | CREATE | Dashboard with resumos |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add ~25 new strings |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add ~25 new translations |
| `lib/main.dart` | MODIFY | Change home, add routes |
| `README.md` | MODIFY | Document new UX flow |
| `ARCHITECTURE.md` | MODIFY | Add HomeScreen and Profile docs |

---

## Phase BORRACHA-07: UX Improvements & Navigation Polish
### Status: [DONE]
**Date Completed**: 2026-01-21
**Priority**: 🔵 FIX
**Objective**: Improve user experience by adding missing navigation elements, fixing drawer inconsistencies, and providing clear CTAs for empty states.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 7.1 | Add "Cadastrar Parceiro" button to empty state in PesagemScreen | ✅ DONE |
| 7.2 | Refactor drawer navigation from if-statements to switch-case | ✅ DONE |
| 7.3 | Add Settings and About handlers to all screens with drawer | ✅ DONE |
| 7.4 | Add drawer to CriarOfertaScreen (was missing) | ✅ DONE |
| 7.5 | Add /settings route to main.dart | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/pesagem_screen.dart` | MODIFY | Added empty state with icon, message, and CTA button to navigate to /parceiros |
| `lib/screens/pesagem_screen.dart` | MODIFY | Refactored onNavigate from if-statements to switch-case, added settings/about handlers |
| `lib/screens/mercado_screen.dart` | MODIFY | Refactored drawer navigation to switch-case, added settings/about handlers |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Added AgroDrawer with full navigation (was missing entirely) |
| `lib/main.dart` | MODIFY | Added /settings route pointing to AgroSettingsScreen |

### Issues Fixed

**User Experience:**
- ❌ **Empty state without action** → ✅ Added "Adicionar Parceiro" button when no partners exist
- ❌ **Inconsistent drawer navigation** → ✅ All screens use switch-case pattern now
- ❌ **Missing Settings/About handlers** → ✅ Settings opens AgroSettingsScreen, About shows dialog
- ❌ **CriarOfertaScreen without drawer** → ✅ Added drawer with extraItems
- ❌ **Code duplication in onNavigate** → ✅ Cleaned up redundant if-statements

**Code Quality:**
- ✅ DRY: Drawer navigation logic consistent across all 3 screens
- ✅ Maintainability: Switch-case easier to extend than if-chains
- ✅ Accessibility: showAboutDialog provides standard app info

### Navigation Flow Improved

**Before:**
- Empty PesagemScreen: "Nenhum parceiro cadastrado" (dead end)
- Drawer: Properties → Parceiros (confusing mapping)
- Settings/About: Clicked but nothing happened
- CriarOfertaScreen: No drawer (inconsistent)

**After:**
- Empty PesagemScreen: Icon + message + "Adicionar Parceiro" button → /parceiros
- Drawer: Properties → Parceiros (consistent switch-case)
- Settings: Opens AgroSettingsScreen
- About: Shows dialog with app name, version, icon, description
- CriarOfertaScreen: Full drawer with extraItems

---

## Phase BORRACHA-06: Production Fixes & L10n Migration
### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🔴 CRITICAL
**Objective**: Fix critical production issues, migrate all hardcoded strings to l10n, implement missing features, and ensure CLAUDE.md compliance.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1 | Fix Android minSdkVersion error (Firebase Auth requires 23+) | ✅ DONE |
| 6.2 | Update Kotlin version to 2.0.0 for compatibility | ✅ DONE |
| 6.3 | Add missing url_launcher dependency to pubspec.yaml | ✅ DONE |
| 6.4 | Create complete ARB files (app_pt.arb, app_en.arb) with 100+ keys | ✅ DONE |
| 6.5 | Configure l10n.yaml for BorrachaLocalizations generation | ✅ DONE |
| 6.6 | Migrate all 70+ hardcoded strings across 8 files to l10n | ✅ DONE |
| 6.7 | Implement empty callbacks in MercadoScreen (_showLocationFilterInfo, _showNotifyMeInfo) | ✅ DONE |
| 6.8 | Add /criar-oferta route to main.dart for proper navigation | ✅ DONE |
| 6.9 | Replace FAB placeholder with actual navigation to CriarOfertaScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/app/build.gradle` | MODIFY | Set minSdk = 23 (Firebase Auth requirement) |
| `android/settings.gradle` | MODIFY | Updated Kotlin to 2.0.0 |
| `pubspec.yaml` | MODIFY | Added url_launcher: ^6.3.1, flutter_localizations |
| `l10n.yaml` | CREATE | L10n configuration (BorrachaLocalizations, output-dir) |
| `lib/l10n/arb/app_pt.arb` | CREATE | 100+ Portuguese strings (parceiros, pesagem, fechamento, mercado, etc.) |
| `lib/l10n/arb/app_en.arb` | CREATE | 100+ English translations |
| `lib/screens/parceiros_list_screen.dart` | MODIFY | Migrated to BorrachaLocalizations |
| `lib/screens/parceiro_form_screen.dart` | MODIFY | Migrated form labels, validation, dialogs |
| `lib/screens/pesagem_screen.dart` | MODIFY | Migrated all UI strings |
| `lib/screens/fechamento_entrega_screen.dart` | MODIFY | Migrated financial screen strings |
| `lib/screens/lista_entregas_screen.dart` | MODIFY | Migrated history screen strings |
| `lib/screens/mercado_screen.dart` | MODIFY | Migrated + implemented _showLocationFilterInfo, _showNotifyMeInfo |
| `lib/screens/criar_oferta_screen.dart` | MODIFY | Migrated form and validation strings |
| `lib/widgets/tape_view_widget.dart` | MODIFY | Migrated tape header and labels |
| `lib/widgets/big_calculator_keypad.dart` | MODIFY | Migrated "ADICIONAR PESO" button |
| `lib/main.dart` | MODIFY | Added /criar-oferta route |

### Issues Fixed

**Critical Issues:**
- ❌ **Missing url_launcher dependency** → ✅ Added to pubspec.yaml
- ❌ **70+ hardcoded strings (l10n violation)** → ✅ All migrated to ARB files
- ❌ **Empty button implementations** → ✅ Implemented with dialogs/snackbars
- ❌ **CriarOfertaScreen not routable** → ✅ Route added, FAB navigation fixed
- ❌ **Android build errors (minSdk, Kotlin)** → ✅ Fixed in gradle files

**Compliance:**
- ✅ CLAUDE.md Rule 6: Zero hardcoded strings (all use BorrachaLocalizations)
- ✅ CLAUDE.md Rule 4: Hive offline-first (maintained)
- ✅ CLAUDE.md Rule 7: build_runner for Hive (working)
- ✅ Both pt-BR and en translations complete

### L10n Keys Added

**Total: 102 keys** across categories:
- Parceiros: 13 keys (titles, form labels, validation)
- Pesagem: 7 keys (screen labels, error messages)
- Tape View: 4 keys (header, empty state, total, undo)
- Fechamento: 11 keys (financial labels, buttons)
- Lista Entregas: 14 keys (history, status labels, actions)
- Mercado: 14 keys (market screen, offers, filters)
- Criar Oferta: 16 keys (form, validation, success/error)
- Calculator: 1 key (add weight button)
- Drawer: 4 keys (menu items)
- Utility: 3 keys (unknown, partners attended, error)

### Migration Statistics

- **Files changed**: 18
- **Lines added**: ~350
- **Lines removed**: ~120
- **Hardcoded strings eliminated**: 70+
- **L10n keys created**: 102
- **Languages supported**: 2 (pt-BR, en)
- **Compilation errors**: 0
- **CLAUDE.md violations**: 0

---

## Phase BORRACHA-05: O Mercado (Compradores e Ofertas)
### Status: [DONE]
**Priority**: 🟡 MEDIUM
**Objective**: Conectar produtores a compradores (Usinas/Bancas) através de um mural de ofertas geolocalizado e negociação direta via WhatsApp.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | **Perfil do Comprador**: Implementar cadastro com definição de Tipo (Indústria/Banca) e Regiões de Atuação (Raio km ou Cidades). | ✅ DONE |
| 5.2 | **Mural de Ofertas (Classificados)**: Criar sistema de publicação de propostas com Título, Preço DRC (Referência), Preço Banca (Úmido), Condições de Pagamento e Validade da oferta. | ✅ DONE |
| 5.3 | **Matchmaking Simples**: Implementar filtro de ofertas baseado na localização da propriedade do usuário (GeoHash) para mostrar apenas compradores relevantes. | ✅ DONE |
| 5.4 | **Botão "Tenho Interesse"**: Integrar deeplink para WhatsApp com mensagem pré-formatada ("Olá, vi sua oferta no PlanejaBorracha...") para iniciar negociação direta. | ✅ DONE |

### Files Modified
- `lib/models/market_offer.dart`
- `lib/screens/mercado_screen.dart`
- `lib/screens/criar_oferta_screen.dart`

---

## Phase BORRACHA-04: Fechamento Financeiro (O Pagamento)
### Status: [DONE]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Automatizar o cálculo de pagamentos e gerar recibos transparentes para os parceiros.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **Input de Preço Final**: Tela para entrada do Valor de Venda (R$/kg) ou DRC Médio apurado no romaneio. | ✅ DONE |
| 4.2 | **Mágica Automática (Cálculo)**: Implementar lógica que calcula instantaneamente o Total da Venda e a Parte do Parceiro baseado na porcentagem contratada. | ✅ DONE |
| 4.3 | **Gestão de Adiantamentos**: Campo para dedução de valores/vales já pagos ao parceiro. | ✅ DONE |
| 4.4 | **Recibo Transparente**: Gerar PDF simplificado com o resumo do romaneio e cálculo financeiro para envio via WhatsApp. | ✅ DONE |

### Files Modified
- `lib/screens/fechamento_entrega_screen.dart`
- `lib/services/pdf_service.dart`
- `lib/models/financeiro_helper.dart`

---

## Phase BORRACHA-03: Pesagem Rápida (UX "Calculadora de Padaria")
### Status: [DONE]
**Priority**: 🔴 CRITICAL
**Objective**: Criar uma interface focada em agilidade e uso com uma mão para o momento caótico da pesagem.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | **Teclado Numérico Customizado**: Implementar teclado com botões GRANDES para facilitar a digitação com mãos sujas ou em movimento. | ✅ DONE |
| 3.2 | **Modo Acumulador**: Lógica de soma contínua (120kg + 95kg + ...) com visualização clara da "fita de somar" (histórico de entradas). | ✅ DONE |
| 3.3 | **Troca Rápida de Contexto**: Permitir alternar a "Etiqueta" (Talhão/Tarefa) da pesagem atual com um único toque. | ✅ DONE |
| 3.4 | **Fluxo de Salvamento**: Botão "Concluir Parceiro" que salva o total, zera o acumulador e prepara a tela instantaneamente para o próximo parceiro. | ✅ DONE |

### Files Modified
- `lib/screens/pesagem_screen.dart`
- `lib/widgets/big_calculator_keypad.dart`
- `lib/widgets/tape_view_widget.dart`
- `lib/services/entrega_service.dart`

---

## Phase BORRACHA-02: Gestão de Parceiros (Set-and-Forget)
### Status: [DONE]
**Priority**: 🔴 CRITICAL
**Objective**: Configurar a "equipe" uma única vez para automatizar todos os cálculos futuros.

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Cadastro de Parceiro**: Implementar entidade (Hive) com Nome, Foto e Telefone. | ✅ DONE |
| 2.2 | **Contrato Padrão**: Campo para definir a Porcentagem padrão do parceiro (ex: 40%, 50%) para automação financeira. | ✅ DONE |
| 2.3 | **Vinculação de Tarefas**: Interface para selecionar quais Talhões (do `agro_core`) o parceiro atende, ou opção simples "Propriedade Toda". | ✅ DONE |
| 2.4 | **Sincronização**: Garantir persistência offline robusta para acesso no campo. | ✅ DONE |

### Files Modified
- `lib/models/parceiro.dart`
- `lib/screens/parceiros_list_screen.dart`
- `lib/screens/parceiro_form_screen.dart`
- `lib/services/parceiro_service.dart`

---

## Phase BORRACHA-01: Initial Documentation & Planning

### Status: [DONE]
**Date Completed**: 2026-01-20
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Establish the foundational documentation and architecture for the PlanejaBorracha application, focusing on the "Real-Time Weighing Calculator" and Market features.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | Create `README.md` with product vision and features | ✅ DONE |
| 1.2 | Create `ARCHITECTURE.md` with models, screens, and roadmap | ✅ DONE |
| 1.3 | Create `CHANGELOG.md` structure | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `README.md` | MODIFY | Added features (Romaneio Digital, Mercado) |
| `ARCHITECTURE.md` | CREATE | Detailed architectural plan (Phase 1 & 2) |
| `CHANGELOG.md` | CREATE | Initial changelog setup |
