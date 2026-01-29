# CHANGELOG - RuraCash

> **Phase Prefix**: Phases use the `CASH-` prefix.
> Core infrastructure phases are documented in `packages/agro_core/CHANGELOG.md`.

---

## Phase CASH-32: Pendências Remanescentes — L10n, RelatorioService, Build Runner e Polimento

### Status: [TODO]
**Priority**: 🔴 CRITICAL (l10n) + 🟡 ARCHITECTURAL (RelatorioService) + 🟢 ENHANCEMENT (UX)
**Objective**: Resolver todas as pendências identificadas na verificação das fases CASH-26/27/28 e CORE-96. Inclui: internacionalização de 40+ strings hardcoded, implementação real do RelatorioService (skeleton), geração de adapters Hive (build_runner), e polimento de telas.

### Motivação

As fases CASH-26, 27 e 28 foram implementadas com foco na arquitetura (models, services, routes, providers). Porém, a verificação revelou que:
- **5 arquivos** contêm strings hardcoded em português (viola regra l10n obrigatória)
- **RelatorioService** é skeleton (retorna dados zerados — Balanço e Fluxo de Caixa são telas vazias)
- **Categoria.g.dart** não foi gerado (build_runner pendente no agro_core)
- **OrcamentoScreen** usa consumo mockado (75% fixo)
- **ContaPagarScreen** usa placeholder no dialog de pagamento

### Sub-Fases

| Sub-Phase | Description | Priority | Status |
|-----------|-------------|----------|--------|
| CASH-32.1 | L10n: ContaPagarScreen — 11 strings hardcoded | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.2 | L10n: OrcamentoScreen — 10 strings hardcoded | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.3 | L10n: BalancoScreen — 7 strings hardcoded | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.4 | L10n: FluxoCaixaScreen — 9 strings hardcoded | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.5 | L10n: OrcamentoAlertService — 3 strings hardcoded (notificações) | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.6 | RelatorioService: Implementar gerarBalanco() com dados reais | 🟡 ARCHITECTURAL | ⏳ TODO |
| CASH-32.7 | RelatorioService: Implementar gerarFluxoCaixa() com dados reais | 🟡 ARCHITECTURAL | ⏳ TODO |
| CASH-32.8 | Build Runner: Gerar categoria.g.dart no agro_core | 🔴 CRITICAL | ⏳ TODO |
| CASH-32.9 | OrcamentoScreen: Integrar consumo real via LancamentoService | 🟢 ENHANCEMENT | ⏳ TODO |
| CASH-32.10 | ContaPagarScreen: Dialog de pagamento com seletor de conta real | 🟢 ENHANCEMENT | ⏳ TODO |
| CASH-32.11 | OrcamentoScreen: Modal de criação/edição de orçamento | 🟢 ENHANCEMENT | ⏳ TODO |
| CASH-32.12 | FluxoCaixaScreen: Navegação de período (mês anterior/próximo) | 🟢 ENHANCEMENT | ⏳ TODO |

---

### CASH-32.1: L10n — ContaPagarScreen

**Arquivo**: `lib/screens/conta_pagar_screen.dart`

**Strings a migrar para ARB**:

| String Hardcoded | Chave ARB Proposta | Contexto |
|------------------|-------------------|----------|
| `'Contas a Pagar'` | `cashContasPagarTitle` | AppBar title |
| `'🔴 VENCIDAS'` | `cashContasVencidas` | Section title |
| `'🟡 VENCE ESTA SEMANA'` | `cashContasVenceEstaSemana` | Section title |
| `'🟢 PRÓXIMAS'` | `cashContasProximas` | Section title |
| `'Vence '` | `cashContaVence` | ListTile subtitle prefix |
| `' • parc. '` | `cashContaParcela` | Installment separator |
| `'TOTAL PENDENTE'` | `cashContasTotalPendente` | Card label |
| `'Confirmar Pagamento'` | `cashContasConfirmarPagamento` | Dialog title |
| `'Deseja pagar "{descricao}"...'` | `cashContasDesejaPagar` | Dialog content (com placeholder) |
| `'Cancelar'` | `cashCancelar` | Button label (reutilizável) |
| `'Pagar'` | `cashContasPagar` | Button label |

---

### CASH-32.2: L10n — OrcamentoScreen

**Arquivo**: `lib/screens/orcamento_screen.dart`

**Strings a migrar para ARB**:

| String Hardcoded | Chave ARB Proposta | Contexto |
|------------------|-------------------|----------|
| `'Orçamentos'` | `cashOrcamentosTitle` | AppBar title |
| `'Definir Orçamento'` | `cashOrcamentoDefinir` | FAB label |
| `'Por Safra'` | `cashOrcamentoPorSafra` | Dropdown item |
| `'Por Mês'` | `cashOrcamentoPorMes` | Dropdown item |
| `'Por Ano'` | `cashOrcamentoPorAno` | Dropdown item |
| `'Nenhum orçamento definido...'` | `cashOrcamentoEmpty` | Empty state |
| `'Categoria '` | `cashOrcamentoCategoria` | Card title |
| `'R$ X de Y'` | `cashOrcamentoProgresso` | Progress text (com placeholders) |
| `'Restam R$ X'` | `cashOrcamentoRestam` | Budget remaining |
| `'Estourou R$ X'` | `cashOrcamentoEstourou` | Budget exceeded |

---

### CASH-32.3: L10n — BalancoScreen

**Arquivo**: `lib/screens/balanco_screen.dart`

**Strings a migrar para ARB**:

| String Hardcoded | Chave ARB Proposta | Contexto |
|------------------|-------------------|----------|
| `'Balanço Patrimonial'` | `cashBalancoTitle` | AppBar title |
| `'ATIVOS · o que você tem'` | `cashBalancoAtivos` | Section title (vocabulário híbrido) |
| `'PASSIVOS · o que você deve'` | `cashBalancoPassivos` | Section title |
| `'PATRIMÔNIO · o que sobra'` | `cashBalancoPatrimonio` | Section title |
| `'Resumo Financeiro da Fazenda'` | `cashBalancoResumo` | Header label |
| `'Nenhum item registrado'` | `cashBalancoEmpty` | Empty items |
| `'TOTAL'` | `cashBalancoTotal` | Row label |

**Nota**: O vocabulário híbrido ("ATIVOS · o que você tem") deve ser mantido em ambos idiomas:
- pt-BR: `"ATIVOS · o que você tem"`
- en: `"ASSETS · what you own"`

---

### CASH-32.4: L10n — FluxoCaixaScreen

**Arquivo**: `lib/screens/fluxo_caixa_screen.dart`

**Strings a migrar para ARB**:

| String Hardcoded | Chave ARB Proposta | Contexto |
|------------------|-------------------|----------|
| `'Fluxo de Caixa'` | `cashFluxoCaixaTitle` | AppBar title |
| `'RESULTADO DO PERÍODO'` | `cashFluxoResultado` | Card title |
| `'Lucro no período'` | `cashFluxoLucro` | Positive result label |
| `'Prejuízo no período'` | `cashFluxoPrejuizo` | Negative result label |
| `'EVOLUÇÃO DO SALDO'` | `cashFluxoEvolucao` | Section title |
| `'Saldo Inicial'` | `cashFluxoSaldoInicial` | Row label |
| `'Entradas'` | `cashFluxoEntradas` | Row label |
| `'Saídas'` | `cashFluxoSaidas` | Row label |
| `'Saldo Final'` | `cashFluxoSaldoFinal` | Row label |

---

### CASH-32.5: L10n — OrcamentoAlertService

**Arquivo**: `lib/services/orcamento_alert_service.dart`

**Strings a migrar para ARB**:

| String Hardcoded | Chave ARB Proposta | Contexto |
|------------------|-------------------|----------|
| `'Alerta de Orçamento'` | `cashOrcamentoAlertTitle` | Notification title |
| `'Você ultrapassou o orçamento de...'` | `cashOrcamentoAlertExceded` | Notification body (exceeded) |
| `'Atenção: Você atingiu X%...'` | `cashOrcamentoAlertWarning` | Notification body (warning) |

**Nota**: Notificações em background podem não ter acesso a `BuildContext`. Usar `lookupAgroLocalizations()` ou armazenar locale na inicialização.

---

### CASH-32.6: RelatorioService — gerarBalanco() com dados reais

**Arquivo**: `lib/services/relatorio_service.dart`

**Estado atual**: Skeleton — retorna `ativos = []`, `passivos = []` com dados comentados.

**Implementação necessária**:

```
gerarBalanco() deve:
1. ATIVOS (o que o produtor TEM):
   - Buscar saldo de cada Conta bancária/caixa (ContaService — CASH-23, não implementado ainda)
   - Buscar total de ContasReceber pendentes (ContaRecebimentoService.getPendentes())
   - Buscar valor de estoque (se houver — futuro)

2. PASSIVOS (o que o produtor DEVE):
   - Buscar total de ContasPagar pendentes (ContaPagamentoService.getPendentes())
   - Buscar parcelas futuras (ContaPagamentoService por parcelaGrupoId)

3. PATRIMÔNIO LÍQUIDO:
   - Total Ativos - Total Passivos
```

**Dependência**: CASH-23 (Contas Bancárias) precisa estar implementado para Ativos reais. Sem CASH-23, Ativos ficam parciais (apenas ContasReceber).

---

### CASH-32.7: RelatorioService — gerarFluxoCaixa() com dados reais

**Arquivo**: `lib/services/relatorio_service.dart`

**Estado atual**: Skeleton — retorna `totalEntradas = 0.0`, `totalSaidas = 0.0`, meses zerados.

**Implementação necessária**:

```
gerarFluxoCaixa(DateTime inicio, DateTime fim) deve:
1. ENTRADAS (dinheiro que ENTROU no caixa):
   - Buscar Receitas realizadas no período (ReceitaService — CASH-24, não implementado ainda)
   - Buscar ContasReceber com status=recebido e dataRecebimento no período

2. SAÍDAS (dinheiro que SAIU do caixa):
   - Buscar Lançamentos (despesas à vista) no período (LancamentoService)
   - Buscar ContasPagar com status=pago e dataPagamento no período

3. SALDO POR MÊS (FluxoCaixaMensal):
   - Iterar cada mês do período
   - Calcular entradas e saídas por mês
   - Saldo acumulado = saldo anterior + entradas - saídas
```

**Dependência**: CASH-24 (Receitas) precisa estar implementado para Entradas reais. Sem CASH-24, Fluxo mostra apenas saídas.

---

### CASH-32.8: Build Runner — Gerar categoria.g.dart

**Arquivo**: `packages/agro_core/lib/models/categoria.g.dart` (NÃO EXISTE)

**Ação**: Executar no diretório `packages/agro_core/`:

```
dart run build_runner build --delete-conflicting-outputs
```

**Nota**: O `part 'categoria.g.dart';` na linha 8 de `categoria.dart` causa erro de compilação se o arquivo não existir. Este é um bloqueio para build do agro_core e, consequentemente, de todos os apps que dependem dele.

**Adapter gerado esperado**:
- `CategoriaAdapter` (typeId: 78) — já registrado em `main.dart` linha 91

---

### CASH-32.9: OrcamentoScreen — Consumo Real

**Arquivo**: `lib/screens/orcamento_screen.dart`

**Estado atual**: Usa `consumoPercentual = 0.75` (75%) hardcoded para todas as categorias.

**Implementação necessária**:

```
Para cada Orcamento na lista:
1. Obter período do orçamento (orcamento.periodo → DateTimeRange)
2. Buscar lancamentos no período para a categoriaId:
   LancamentoService.instance.getLancamentosPorPeriodo(periodo.start, periodo.end)
     .where((l) => l.categoriaId == orcamento.categoriaId)
3. Somar valores: totalGasto = lancamentos.fold(0.0, (sum, l) => sum + l.valor)
4. Calcular: consumoPercentual = totalGasto / orcamento.valorLimite
```

**Dependência**: LancamentoService já está implementado e funcional.

**Nota**: O campo `categoriaId` no Lancamento ainda usa `CashCategoria` (enum antigo). A integração real depende de CASH-21 (migração CashCategoria → Categoria). Até lá, pode-se fazer um mapeamento temporário via CategoriaCore enum key → CashCategoria index.

---

### CASH-32.10: ContaPagarScreen — Dialog de Pagamento Real

**Arquivo**: `lib/screens/conta_pagar_screen.dart`

**Estado atual**: Dialog de "Confirmar Pagamento" chama `pagar()` com `contaPagamentoId: 'caixa_default'` (placeholder hardcoded).

**Implementação necessária**:

```
1. Ao clicar em "Pagar", abrir BottomSheet/Dialog com:
   - Seletor de conta (DropdownButton com ContaService.getContas())
   - DatePicker para data de pagamento (default: hoje)
   - Botão "Confirmar"
2. Chamar ContaPagamentoService().pagar(id, contaSelecionada.id, dataPagamento)
```

**Dependência**: CASH-23 (ContaService / Contas Bancárias). Sem CASH-23, manter o placeholder com nota visual "Caixa (padrão)".

---

### CASH-32.11: OrcamentoScreen — Modal de Criação/Edição

**Arquivo**: `lib/screens/orcamento_screen.dart`

**Estado atual**: FAB "Definir Orçamento" existe mas não abre modal/form.

**Implementação necessária**:

```
Modal/BottomSheet com:
1. Seletor de Categoria (Dropdown com CategoriaService.getCategoriasAtivas())
2. Campo valor limite (TextFormField numérico com validação > 0)
3. Seletor de tipo de período (SegmentedButton: Mês | Trimestre | Safra | Ano)
4. Seletor de período específico:
   - Mês: MonthPicker (ano + mês)
   - Trimestre: DropdownButton (Q1, Q2, Q3, Q4) + ano
   - Safra: AnoSafra picker (ex: "Safra 2025/26" = Set 2025 a Ago 2026)
   - Ano: YearPicker
5. Toggle alerta ativo (Switch, default: true)
6. Slider percentual alerta (default: 80%)
7. Botão "Salvar" → OrcamentoService().add(orcamento)
```

---

### CASH-32.12: FluxoCaixaScreen — Navegação de Período

**Arquivo**: `lib/screens/fluxo_caixa_screen.dart`

**Estado atual**: Mostra dados de um período fixo sem possibilidade de navegar.

**Implementação necessária**:

```
AppBar ou header com:
1. Botão "◀" (mês anterior)
2. Label do período atual ("Janeiro 2026" ou "Safra 2025/26")
3. Botão "▶" (próximo mês)
4. Seletor de tipo de visualização: Mensal | Trimestral | Safra | Anual
5. Ao trocar período, recalcular dados via RelatorioService.gerarFluxoCaixa()
```

---

### Ordem de Execução Recomendada

| Prioridade | Sub-Phase | Justificativa |
|------------|-----------|---------------|
| 1 | CASH-32.8 | Build runner — sem isso, agro_core não compila |
| 2 | CASH-32.1 a 32.5 | L10n — regra obrigatória do projeto, impede publicação |
| 3 | CASH-32.6 + 32.7 | RelatorioService — telas existem mas mostram dados zerados |
| 4 | CASH-32.9 | Consumo real no orçamento — depende apenas de LancamentoService (já funcional) |
| 5 | CASH-32.10 a 32.12 | UX enhancements — dependem de CASH-23 (Contas Bancárias) |

### Files to be Modified

| File | Action | Sub-Phase |
|------|--------|-----------|
| `packages/agro_core/lib/models/categoria.g.dart` | GENERATE | CASH-32.8 |
| `apps/ruracash/lib/l10n/arb/app_pt.arb` | MODIFY | CASH-32.1 a 32.5 |
| `apps/ruracash/lib/l10n/arb/app_en.arb` | MODIFY | CASH-32.1 a 32.5 |
| `lib/screens/conta_pagar_screen.dart` | MODIFY | CASH-32.1, 32.10 |
| `lib/screens/orcamento_screen.dart` | MODIFY | CASH-32.2, 32.9, 32.11 |
| `lib/screens/balanco_screen.dart` | MODIFY | CASH-32.3 |
| `lib/screens/fluxo_caixa_screen.dart` | MODIFY | CASH-32.4, 32.12 |
| `lib/services/orcamento_alert_service.dart` | MODIFY | CASH-32.5 |
| `lib/services/relatorio_service.dart` | MODIFY | CASH-32.6, 32.7 |

### Cross-Reference

- **CASH-23** (Contas Bancárias): Necessário para CASH-32.6 (ativos reais), CASH-32.10 (seletor de conta)
- **CASH-24** (Receitas): Necessário para CASH-32.7 (entradas no fluxo de caixa)
- **CASH-21** (Migração CashCategoria → Categoria): Necessário para CASH-32.9 (consumo por categoriaId real)
- **CORE-96.1** (fixes anteriores): Já aplicado — serialização e GenericSyncService compliance

---

## Phase CASH-26.1: Bug Fixes — GenericSyncService Compliance

### Status: [DONE]
**Date Completed**: 2026-01-28
**Priority**: 🔵 FIX
**Objective**: Corrigir bugs críticos nas implementações de CASH-26, CASH-27, CASH-28 e CORE-96 que impediam compilação e causariam crash em runtime.

### Bugs Corrigidos

| Bug | Severidade | Arquivo | Correção |
|-----|-----------|---------|----------|
| `update(updated)` em vez de `update(id, updated)` | CRITICAL (runtime crash) | `conta_pagamento_service.dart` | Corrigido `pagar()` e `adiar()` para usar 2 params |
| `update(updated)` em vez de `update(id, updated)` | CRITICAL (runtime crash) | `conta_recebimento_service.dart` | Corrigido `receber()` para usar 2 params |
| `update(Categoria)` override com assinatura errada | COMPILE ERROR | `categoria_service.dart` (core) | Corrigido para `update(String id, Categoria)` |
| Missing `sourceApp` override | COMPILE ERROR | Todos os 4 novos services | Adicionado `sourceApp => 'ruracash'` / `'agro_core'` |
| Missing `fromMap`/`toMap`/`getId` overrides | COMPILE ERROR | Todos os 4 novos services | Adicionado overrides delegando para `toJson()`/`fromJson()` |
| Missing `toJson()`/`fromJson()` nos models | COMPILE ERROR | ContaPagar, ContaReceber, Orcamento, Categoria | Adicionado serialização completa |
| Missing Provider registrations | RUNTIME (no state updates) | `main.dart` | Adicionado 4 ChangeNotifierProvider no MultiProvider |
| Missing `diasParaVencer` getter | MINOR | `conta_receber.dart` | Adicionado getter |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/conta_pagar.dart` | MODIFY | Add `toJson()` / `fromJson()` |
| `lib/models/conta_receber.dart` | MODIFY | Add `toJson()` / `fromJson()` + `diasParaVencer` getter |
| `lib/models/orcamento.dart` | MODIFY | Add `toJson()` / `fromJson()` |
| `lib/services/conta_pagamento_service.dart` | MODIFY | Add `sourceApp`, `fromMap`, `toMap`, `getId`; fix `update()` calls |
| `lib/services/conta_recebimento_service.dart` | MODIFY | Add `sourceApp`, `fromMap`, `toMap`, `getId`; fix `update()` call |
| `lib/services/orcamento_service.dart` | MODIFY | Add `sourceApp`, `fromMap`, `toMap`, `getId` |
| `lib/main.dart` | MODIFY | Add 4 missing Provider registrations |

### Cross-Reference
- `packages/agro_core/CHANGELOG.md` → CORE-96.1 (Categoria model + CategoriaService fixes)

---

## Phase CASH-31: Tema e UX por Contexto — Identidade Visual Agro vs Pessoal

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Diferenciar visualmente o contexto Agro (verde, ícones rurais, linguagem de fazenda) do contexto Pessoal (azul, ícones domésticos, linguagem de casa/família). Inclui tema dinâmico, onboarding explicativo, linguagem adaptada e filtragem completa de ícones. O objetivo é que o produtor **saiba imediatamente** em qual contexto está, sem precisar ler.

### Motivação

1. **Confusão silenciosa**: Sem diferenciação visual, o usuário pode lançar despesa pessoal no contexto agro (ou vice-versa) sem perceber. O único indicador atual é o nome da farm no AppBar.
2. **Separação mental**: Cor diferente = "não é a mesma coisa". O cérebro processa cor antes de texto.
3. **Diferencial competitivo**: Nenhum app agro oferece modo pessoal com identidade visual própria.
4. **Público real**: Não é nicho — produtores misturam contas, chacareiros urbanos querem visão pessoal, famílias compartilham celular.

### Público Que Usa o Modo Pessoal

| Perfil | Uso |
|--------|-----|
| Produtor que mistura contas | Separa fazenda de casa, DRE fica limpo |
| Produtor com renda externa | Recebe salário de outro emprego |
| Esposa/família | Usa mesmo celular, controla gastos de casa |
| Chacareiro urbano | Horta/pomar é hobby, pessoal é o foco |
| Produtor na entressafra | App continua útil fora do ciclo agrícola |

### Arquitetura: Tema Dinâmico

```dart
/// O tema muda conforme o FarmType da farm ativa.
/// Não é uma preferência do usuário — é automático.
MaterialApp(
  theme: _buildTheme(context),
  // ...
);

ThemeData _buildTheme(BuildContext context) {
  final farm = FarmService.instance.activeFarm;
  final isPersonal = farm?.type == FarmType.personal;

  // Cor seed muda, todo o Material 3 color scheme segue
  final seedColor = isPersonal
    ? const Color(0xFF1565C0)   // Azul (Material Blue 800)
    : const Color(0xFF2E7D32);  // Verde (Material Green 800)

  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seedColor,
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
  );
}
```

### Identidade Visual por Contexto

| Elemento | Contexto Agro | Contexto Pessoal |
|----------|---------------|------------------|
| **Cor primária** | Verde (0xFF2E7D32) | Azul (0xFF1565C0) |
| **Cor de gradiente (cards)** | Verde → Verde escuro | Azul → Azul escuro |
| **Ícone do contexto** | `Icons.agriculture` | `Icons.home` |
| **Título home** | "Fazenda Santa Fé" | "Minhas Finanças" |
| **Subtítulo home** | "Total do Mês (Fazenda)" | "Total do Mês (Pessoal)" |
| **FAB cor** | Verde | Azul |
| **AppBar** | Verde ou tema verde | Azul ou tema azul |
| **Drawer header** | Ilustração rural / verde | Ilustração doméstica / azul |
| **Empty state** | "Nenhuma despesa na fazenda" | "Nenhuma despesa pessoal" |

### Categorias: Ícones e Nomes por Contexto

**Contexto Agro (verde)** — Categorias visíveis:

| Categoria | Ícone | Cor |
|-----------|-------|-----|
| Mão de Obra | `engineering` | Azul |
| Adubo/Fertilizante | `eco` | Verde |
| Defensivos | `science` | Roxo |
| Combustível | `local_gas_station` | Laranja |
| Manutenção | `build` | Cinza |
| Energia/Água | `bolt` | Âmbar |
| Outros (Agro) | `category` | Marrom |

**Contexto Pessoal (azul)** — Categorias visíveis:

| Categoria | Ícone | Cor |
|-----------|-------|-----|
| Alimentação | `restaurant` | Vermelho |
| Transporte | `directions_car` | Cinza-azulado |
| Saúde | `local_hospital` | Teal |
| Educação | `school` | Índigo |
| Lazer | `beach_access` | Laranja |
| Moradia | `home` | Marrom |
| Outros (Pessoal) | `more_horiz` | Cinza |

**Regra**: Categorias agro NUNCA aparecem no contexto pessoal. Categorias pessoais NUNCA aparecem no contexto agro. Isso já está implementado via `isAgro`/`isPersonal` nos getters de `CashCategoria` — migrar para `Categoria.isAgro`/`Categoria.isPersonal` no CORE-96.

### Onboarding: Tela de Escolha de Perfil

Exibida na primeira entrada do app (ou se nenhuma farm existe):

```
┌──────────────────────────────────────────────────────────────┐
│       Bem-vindo ao RuraCash!                                │
│                                                              │
│  Como você quer começar?                                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  🚜  PRODUTOR RURAL                                    │ │
│  │  ──────────────────                                    │ │
│  │  Controle os custos da sua fazenda:                    │ │
│  │  • Combustível, adubo, mão de obra, defensivos        │ │
│  │  • Relatório da safra (DRE)                            │ │
│  │  • Integração com RuraRubber e RuraCattle              │ │
│  │                                                         │ │
│  │  Ideal para: fazendeiros, seringueiros, pecuaristas   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  🏠  MINHAS FINANÇAS PESSOAIS                          │ │
│  │  ────────────────────────────                          │ │
│  │  Controle os gastos da sua casa e família:             │ │
│  │  • Supermercado, farmácia, escola, lazer               │ │
│  │  • Quanto sobrou no mês                                │ │
│  │  • Totalmente separado da fazenda                      │ │
│  │                                                         │ │
│  │  Ideal para: controle doméstico, gastos do dia a dia  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  💡 Você pode usar os dois! Troque a qualquer momento     │
│     pelo seletor no topo da tela.                          │
└──────────────────────────────────────────────────────────────┘
```

### Comportamento da Escolha

| Escolha | Ação |
|---------|------|
| Produtor Rural | Cria farm `FarmType.agro` com nome l10n `farmDefaultName`, ativa tema verde, mostra categorias agro |
| Minhas Finanças | Cria farm `FarmType.personal` com nome l10n `farmDefaultNamePersonal`, ativa tema azul, mostra categorias pessoais |

A segunda farm (a que NÃO foi escolhida) pode ser criada depois pelo context switcher no AppBar. O context switcher mostra opção "Adicionar [Fazenda/Finanças Pessoais]" se a segunda farm não existir.

### Context Switcher com Identidade Visual

```
Contexto Agro:
┌──────────────────────────────────────────────────────┐
│  [🚜 Fazenda Santa Fé ▼]                 Verde      │
│  ┌───────────────────────────────┐                   │
│  │ 🚜 Fazenda Santa Fé     ✓    │                   │
│  │ 🏠 Minhas Finanças           │                   │
│  └───────────────────────────────┘                   │
└──────────────────────────────────────────────────────┘

Contexto Pessoal:
┌──────────────────────────────────────────────────────┐
│  [🏠 Minhas Finanças ▼]                  Azul       │
│  ┌───────────────────────────────┐                   │
│  │ 🚜 Fazenda Santa Fé          │                   │
│  │ 🏠 Minhas Finanças      ✓    │                   │
│  └───────────────────────────────┘                   │
└──────────────────────────────────────────────────────┘
```

### Linguagem Adaptada por Contexto

| Tela/Elemento | Agro | Pessoal |
|---------------|------|---------|
| Home título | "Fazenda Santa Fé" | "Minhas Finanças" |
| Home subtítulo | "Despesas da Fazenda" | "Despesas Pessoais" |
| DRE título | "DRE da Fazenda" | "Finanças Pessoais" |
| Empty state | "Nenhum gasto na fazenda este mês" | "Nenhum gasto pessoal este mês" |
| Orçamento | "Orçamento da Safra" | "Orçamento Mensal" |
| Centro de Custo | "Centro de Custo" | "Categoria de Gasto" |
| Balanço | "Resumo Financeiro (Fazenda)" | "Resumo Financeiro (Pessoal)" |
| Context switcher tooltip | "Trocar para finanças pessoais" | "Trocar para fazenda" |

### L10n: Chaves Necessárias (pt-BR / en)

```
// Onboarding
cashOnboardingTitle: "Bem-vindo ao RuraCash!" / "Welcome to RuraCash!"
cashOnboardingSubtitle: "Como você quer começar?" / "How do you want to start?"
cashProfileRural: "Produtor Rural" / "Rural Producer"
cashProfileRuralDesc: "Controle os custos da sua fazenda" / "Control your farm costs"
cashProfileRuralIdeal: "Ideal para: fazendeiros, seringueiros, pecuaristas" / "Ideal for: farmers, rubber tappers, ranchers"
cashProfilePersonal: "Minhas Finanças Pessoais" / "My Personal Finances"
cashProfilePersonalDesc: "Controle os gastos da sua casa e família" / "Control your home and family expenses"
cashProfilePersonalIdeal: "Ideal para: controle doméstico, gastos do dia a dia" / "Ideal for: household control, daily expenses"
cashProfileBothHint: "Você pode usar os dois! Troque a qualquer momento." / "You can use both! Switch anytime."

// Context-aware titles
cashHomeSubtitleAgro: "Despesas da Fazenda" / "Farm Expenses"
cashHomeSubtitlePersonal: "Despesas Pessoais" / "Personal Expenses"
cashEmptyAgro: "Nenhum gasto na fazenda este mês" / "No farm expenses this month"
cashEmptyPersonal: "Nenhum gasto pessoal este mês" / "No personal expenses this month"
cashBudgetTitleAgro: "Orçamento da Safra" / "Harvest Budget"
cashBudgetTitlePersonal: "Orçamento Mensal" / "Monthly Budget"
cashBalanceAgro: "Resumo Financeiro (Fazenda)" / "Financial Summary (Farm)"
cashBalancePersonal: "Resumo Financeiro (Pessoal)" / "Financial Summary (Personal)"
cashSwitchToPersonal: "Trocar para finanças pessoais" / "Switch to personal finances"
cashSwitchToAgro: "Trocar para fazenda" / "Switch to farm"
```

### Notas de Design

1. **Tema é automático, não é preferência**: Muda ao trocar contexto, não é config manual
2. **Material 3 ColorScheme**: Basta trocar o `seedColor`, todo o design system segue
3. **Transição suave**: Usar `AnimatedTheme` para animar a troca de cor
4. **Drawer adapta**: Header do drawer muda cor e ícone conforme contexto
5. **Orçamento default**: No contexto pessoal, default é "Mensal". No agro, default é "Safra".

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-31.1 | Criar `PersonalThemeData` e `AgroThemeData` com seedColor distinto | ⏳ TODO |
| CASH-31.2 | Implementar troca dinâmica de tema ao mudar contexto (AnimatedTheme) | ⏳ TODO |
| CASH-31.3 | Criar tela de onboarding com escolha de perfil (Produtor Rural / Finanças Pessoais) | ⏳ TODO |
| CASH-31.4 | Adaptar HomeScreen: títulos, subtítulos, gradientes, ícones por contexto | ⏳ TODO |
| CASH-31.5 | Adaptar DreScreen: título contextual | ⏳ TODO |
| CASH-31.6 | Adaptar OrcamentoScreen: default Safra (agro) vs Mensal (pessoal) | ⏳ TODO |
| CASH-31.7 | Adaptar BalancoScreen/FluxoCaixaScreen: título contextual | ⏳ TODO |
| CASH-31.8 | Adaptar Drawer: header com cor/ícone contextual | ⏳ TODO |
| CASH-31.9 | Adaptar Context Switcher: ícones, labels, tooltip contextuais | ⏳ TODO |
| CASH-31.10 | Adicionar ~15 chaves l10n contextuais (pt-BR + en) + gen-l10n | ⏳ TODO |
| CASH-31.11 | Adaptar empty states por contexto (mensagens e ícones) | ⏳ TODO |
| CASH-31.12 | Testar alternância de tema ao trocar contexto (performance, flicker) | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/theme/cash_theme.dart` | CREATE | AgroThemeData e PersonalThemeData com seedColor |
| `lib/screens/onboarding_screen.dart` | CREATE | Tela de escolha de perfil com 2 cards explicativos |
| `lib/main.dart` | MODIFY | Integrar tema dinâmico, gate onboarding |
| `lib/screens/home_screen.dart` | MODIFY | Títulos, subtítulos, gradientes contextuais |
| `lib/screens/dre_screen.dart` | MODIFY | Título contextual |
| `lib/screens/orcamento_screen.dart` | MODIFY | Default período por contexto |
| `lib/screens/balanco_screen.dart` | MODIFY | Título contextual |
| `lib/screens/fluxo_caixa_screen.dart` | MODIFY | Título contextual |
| `lib/widgets/cash_drawer.dart` | MODIFY | Header contextual |
| `lib/l10n/arb/app_pt.arb` | MODIFY | ~15 novas chaves contextuais |
| `lib/l10n/arb/app_en.arb` | MODIFY | ~15 novas chaves contextuais |

### Cross-Reference

- CASH-09: Context Switcher (base, já implementado)
- CORE-91: FarmType enum (FarmType.personal vs FarmType.agro)
- CORE-93: FarmType icon/localizedName
- CASH-20: Princípio "Vocabulário híbrido" (complementado aqui)

---

## Phase CASH-30: Paywall Premium — RevenueCat/Play Billing Integration

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Implementar paywall para desbloquear funcionalidades Premium (contas bancárias, receitas, transferências, orçamento, reconciliação, relatórios avançados). Modelo freemium com assinatura mensal/anual.

### Prerequisite

- CASH-29 (Reconciliação) deve estar DONE
- Conta RevenueCat configurada com produtos

### Modelo de Monetização

| Tier | Preço | Funcionalidades |
|------|-------|-----------------|
| **Free** | R$ 0 | Lançar despesas, 14 categorias core, DRE simples, contexto rural/pessoal, 1 farm agro + 1 farm pessoal |
| **Premium** | R$ 9,90/mês ou R$ 79,90/ano | Tudo do Free + contas bancárias, receitas, transferências, categorias custom ilimitadas, contas a pagar/receber, orçamento, reconciliação, relatórios avançados, multi-farm agro |

### Funcionalidades por Tier (Feature Flags)

```dart
enum PremiumFeature {
  contasBancarias,          // CASH-23
  receitas,                 // CASH-24
  transferencias,           // CASH-25
  contasPagarReceber,       // CASH-26
  orcamento,                // CASH-27
  relatoriosAvancados,      // CASH-28
  reconciliacao,            // CASH-29
  categoriasCustom,         // CASH-22
  multiFarmAgro,            // >1 farm agrícola
}

class PremiumService {
  bool hasFeature(PremiumFeature feature);
  bool get isPremium;
  Future<void> purchase(PremiumPlan plan);
  Future<void> restore();
}
```

### UX Paywall

```
┌──────────────────────────────────────────────────────────────┐
│  🔓 Desbloquear RuraCash Premium                             │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  ✅ Controle de contas bancárias e cartões            │  │
│  │  ✅ Receitas e transferências entre contas            │  │
│  │  ✅ Contas a pagar com alertas de vencimento          │  │
│  │  ✅ Orçamento mensal por categoria                    │  │
│  │  ✅ Reconciliação com extrato bancário                │  │
│  │  ✅ Relatórios avançados (Balanço, Fluxo de Caixa)   │  │
│  │  ✅ Categorias personalizadas ilimitadas              │  │
│  │  ✅ Múltiplas fazendas agrícolas                      │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Seus dados atuais serão 100% preservados.                  │
│                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐           │
│  │   R$ 9,90/mês      │  │  R$ 79,90/ano       │           │
│  │                     │  │  💰 Economia 33%    │           │
│  │    [Assinar]        │  │    [Assinar]        │           │
│  └─────────────────────┘  └─────────────────────┘           │
│                                                              │
│  [Restaurar compra]              [Não, obrigado]            │
└──────────────────────────────────────────────────────────────┘
```

### Trigger Points (Onde mostrar paywall)

| Ação do Usuário | Comportamento |
|-----------------|---------------|
| Tenta criar conta bancária | Mostra paywall |
| Tenta criar receita | Mostra paywall |
| Tenta criar transferência | Mostra paywall |
| Tenta criar categoria custom | Mostra paywall |
| Tenta criar 2ª farm agro | Mostra paywall |
| Acessa "Orçamento" no menu | Mostra paywall |
| Acessa "Reconciliação" no menu | Mostra paywall |
| Acessa "Balanço" ou "Fluxo de Caixa" | Mostra paywall |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-30.1 | Configurar RevenueCat project e produtos (monthly, annual) | ⏳ TODO |
| CASH-30.2 | Criar `PremiumService` com cache local (Hive) + validação RevenueCat | ⏳ TODO |
| CASH-30.3 | Criar `PaywallScreen` com design persuasivo e lista de benefícios | ⏳ TODO |
| CASH-30.4 | Adicionar `PremiumGate` widget para proteger features | ⏳ TODO |
| CASH-30.5 | Integrar gates em todas as telas Premium (contas, receitas, etc.) | ⏳ TODO |
| CASH-30.6 | Implementar restore purchase e handling de erros | ⏳ TODO |
| CASH-30.7 | Adicionar analytics de conversão (view paywall, purchase, abandon) | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/premium_service.dart` | CREATE | Integração RevenueCat, cache, feature flags |
| `lib/screens/paywall_screen.dart` | CREATE | Tela de conversão Premium |
| `lib/widgets/premium_gate.dart` | CREATE | Widget que protege features Premium |
| `lib/main.dart` | MODIFY | Inicializar RevenueCat SDK |
| `pubspec.yaml` | MODIFY | Adicionar purchases_flutter (RevenueCat) |

### Cross-Reference

- CASH-22 a CASH-29: Features protegidas pelo paywall
- CORE-91: Farm model já tem subscriptionTier (base para multi-farm)

---

## Phase CASH-29: Reconciliação Bancária — Local-First Matching

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir importar extrato bancário (CSV/OFX) e reconciliar com lançamentos existentes. Matching feito 100% local (Hive) para evitar custos Firestore. Apenas flags de reconciliação sobem no sync.

### Prerequisite

- CASH-28 (Relatórios Avançados) deve estar DONE
- CASH-23 (Contas) deve estar DONE

### Problema

Reconciliar manualmente = comparar N lançamentos com N linhas do extrato. Se fizesse via Firestore, seria O(n²) leituras — custo proibitivo.

### Solução: Local-First

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Usuário importa extrato (CSV/OFX) do banco                 │
│  2. App parseia e armazena temporariamente no Hive             │
│  3. Matching automático LOCAL: valor + data ± 3 dias           │
│  4. Usuário revisa matches sugeridos                           │
│  5. Usuário confirma ou ajusta                                  │
│  6. App marca lançamentos como reconciliados (isReconciliado)  │
│  7. Sync Tier 3 sobe APENAS os flags alterados (não o extrato) │
│  8. Extrato descartado após reconciliação (não persiste)       │
└─────────────────────────────────────────────────────────────────┘
```

### Campos Adicionais no Lancamento

```dart
// Adicionar ao model Lancamento existente
@HiveField(20) final bool isReconciliado;           // default false
@HiveField(21) final DateTime? dataReconciliacao;   // quando foi reconciliado
@HiveField(22) final String? extratoRef;            // referência do extrato (opcional)
```

### Model: ExtratoItem (Temporário)

```dart
/// Item do extrato bancário. NÃO persiste no Hive/Firestore.
/// Existe apenas durante a sessão de reconciliação.
class ExtratoItem {
  final String id;                    // Gerado localmente
  final DateTime data;
  final double valor;                 // Positivo = crédito, negativo = débito
  final String descricao;             // Descrição do banco
  final String? identificador;        // ID único do banco (se disponível)

  // Estado da reconciliação (em memória)
  String? lancamentoMatchId;          // ID do lançamento matched
  double? matchScore;                 // 0.0 a 1.0, confiança do match
  bool isManualMatch;                 // Usuário fez match manual
}
```

### Algoritmo de Matching

```dart
class ReconciliacaoService {
  /// Encontra matches automáticos entre extrato e lançamentos.
  /// Critérios:
  /// 1. Valor EXATO (considerando sinal: extrato negativo = despesa)
  /// 2. Data dentro de ±3 dias
  /// 3. Mesma conta bancária
  /// Score = 1.0 se valor+data exatos, 0.8 se data ±1 dia, etc.
  List<MatchSuggestion> findMatches(
    List<ExtratoItem> extrato,
    List<Lancamento> lancamentos,
    String contaId,
  );

  /// Confirma match e marca lançamento como reconciliado.
  Future<void> confirmarMatch(String lancamentoId, String extratoItemId);

  /// Cria lançamento a partir de item do extrato sem match.
  Future<Lancamento> criarDe ExtratoItem(ExtratoItem item, String categoriaId);
}
```

### UX Reconciliação

```
┌──────────────────────────────────────────────────────────────────┐
│  Reconciliação — Nubank (Fev/2026)                              │
│                                                                  │
│  Importar: [📄 Selecionar arquivo CSV/OFX]                      │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  ✅ Matches Automáticos (12)                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 05/02 -R$ 150,00 "POSTO SHELL"     ↔  Combustível R$150   │ │
│  │ 07/02 -R$ 89,90 "AMAZON"           ↔  Outros R$89,90      │ │
│  │ ...                                                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ⚠️ Sem Match (3) — Criar lançamento ou ignorar                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 10/02 -R$ 45,00 "PIX JOAO"         [Criar] [Ignorar]      │ │
│  │ 12/02 -R$ 200,00 "TED"             [Criar] [Ignorar]      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ❓ Lançamentos não encontrados no extrato (2)                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 08/02 Mão de Obra R$500           [Buscar] [OK]           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  [Cancelar]                    [Confirmar Reconciliação]        │
└──────────────────────────────────────────────────────────────────┘
```

### Formatos Suportados

| Formato | Bancos | Parser |
|---------|--------|--------|
| OFX | Maioria (padrão bancário) | `ofx_parser` package |
| CSV | Nubank, Inter, C6 | Parser customizado por banco |
| Excel | Sicredi, Caixa | `excel` package |

### Custos Firestore

| Operação | Leituras | Escritas |
|----------|----------|----------|
| Importar extrato | 0 | 0 |
| Buscar lançamentos p/ match | 0 (local) | 0 |
| Confirmar 50 matches | 0 | 50 (só flags) |
| Total reconciliação mensal | 0 | ~50-100 |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-29.1 | Adicionar campos de reconciliação ao Lancamento (isReconciliado, dataReconciliacao, extratoRef) | ⏳ TODO |
| CASH-29.2 | Criar model `ExtratoItem` (em memória, não persiste) | ⏳ TODO |
| CASH-29.3 | Criar parsers: OFX, CSV (Nubank, Inter), Excel | ⏳ TODO |
| CASH-29.4 | Criar `ReconciliacaoService` com algoritmo de matching | ⏳ TODO |
| CASH-29.5 | Criar `ReconciliacaoScreen` com UX de revisão de matches | ⏳ TODO |
| CASH-29.6 | Criar ação "Criar lançamento" a partir de item sem match | ⏳ TODO |
| CASH-29.7 | Adicionar filtro "Não reconciliados" na home/listagem | ⏳ TODO |
| CASH-29.8 | Gate Premium: reconciliação só disponível para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/lancamento.dart` | MODIFY | Adicionar campos de reconciliação |
| `lib/models/extrato_item.dart` | CREATE | Model temporário para itens do extrato |
| `lib/services/reconciliacao_service.dart` | CREATE | Parsing, matching, confirmação |
| `lib/services/parsers/ofx_parser.dart` | CREATE | Parser OFX |
| `lib/services/parsers/csv_parser.dart` | CREATE | Parser CSV com templates por banco |
| `lib/screens/reconciliacao_screen.dart` | CREATE | UI de reconciliação |
| `pubspec.yaml` | MODIFY | Adicionar ofx_parser, file_picker |

### Cross-Reference

- CASH-23: Contas bancárias (pré-requisito)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-28: Relatórios Avançados — Balanço Patrimonial e Fluxo de Caixa

### Status: [IMPLEMENTED]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Adicionar relatórios financeiros avançados: Balanço Patrimonial (ativos vs passivos) e Fluxo de Caixa (entradas vs saídas por período). Complementa o DRE existente.

### Prerequisite

- CASH-27 (Orçamento) deve estar DONE
- CASH-23 (Contas) deve estar DONE
- CASH-24 (Receitas) deve estar DONE

### Vocabulário Híbrido

Padrão adotado: **TERMO TÉCNICO · explicação amigável**

Quem conhece contabilidade reconhece os termos. Quem não conhece entende pelo contexto.

### Relatório 1: Balanço Patrimonial

```
┌──────────────────────────────────────────────────────────────┐
│  Resumo Financeiro — 31/01/2026                             │
│                                                              │
│  ATIVOS · o que você tem                                    │
│  ├── Carteira                          R$ 500,00            │
│  ├── Nubank (Conta Corrente)           R$ 3.200,00          │
│  ├── Sicredi (Poupança)                R$ 15.000,00         │
│  ├── CDB Banco Inter                   R$ 8.000,00          │
│  ├── Clientes devendo                  R$ 2.500,00          │
│  └── TOTAL                             R$ 29.200,00         │
│                                                              │
│  PASSIVOS · o que você deve                                 │
│  ├── Fatura Cartão Nubank              R$ 1.200,00          │
│  ├── Financiamento Rural               R$ 5.000,00          │
│  ├── Fornecedores                      R$ 800,00            │
│  └── TOTAL                             R$ 7.000,00          │
│                                                              │
│  ══════════════════════════════════════════════════════════ │
│  PATRIMÔNIO · o que sobra              R$ 22.200,00         │
│  (Ativos - Passivos = seu patrimônio real)                  │
│  ══════════════════════════════════════════════════════════ │
│                                                              │
│  [Exportar PDF]                                              │
└──────────────────────────────────────────────────────────────┘
```

### Relatório 2: Fluxo de Caixa

```
┌──────────────────────────────────────────────────────────────┐
│  Entradas e Saídas — Janeiro/2026                           │
│  Período: [Mês ▼]  [Janeiro ▼]  [2026 ▼]                    │
│                                                              │
│  ENTRADAS · dinheiro que entrou                             │
│  ├── Venda de Borracha                 R$ 8.500,00          │
│  ├── Venda de Gado                     R$ 12.000,00         │
│  ├── Outras Receitas                   R$ 500,00            │
│  └── TOTAL                             R$ 21.000,00         │
│                                                              │
│  SAÍDAS · dinheiro que saiu                                 │
│  ├── Mão de Obra                       R$ 4.500,00          │
│  ├── Combustível                       R$ 1.200,00          │
│  ├── Adubo/Defensivos                  R$ 2.800,00          │
│  ├── Despesas Pessoais                 R$ 3.200,00          │
│  └── TOTAL                             R$ 11.700,00         │
│                                                              │
│  ══════════════════════════════════════════════════════════ │
│  RESULTADO · quanto sobrou             R$ 9.300,00  ▲       │
│  (Entradas - Saídas no período)                             │
│  ══════════════════════════════════════════════════════════ │
│                                                              │
│  Você começou Janeiro com              R$ 19.900,00         │
│  Você terminou Janeiro com             R$ 29.200,00         │
│                                                              │
│  [Exportar PDF]    [Ver Gráfico]                            │
└──────────────────────────────────────────────────────────────┘
```

### Gráfico Fluxo de Caixa (12 meses)

```
R$ │
   │     ████                    ████
25k│     ████  ████        ████  ████
   │████ ████  ████  ████  ████  ████  ████
20k│████ ████  ████  ████  ████  ████  ████
   │████ ████  ████  ████  ████  ████  ████
15k│████ ████  ████  ████  ████  ████  ████
   └──────────────────────────────────────────
    Jan  Fev  Mar  Abr  Mai  Jun  Jul  Ago

    ████ Entradas   ░░░░ Saídas   ── Saldo
```

### Service: RelatorioService

```dart
class RelatorioService {
  // Balanço Patrimonial
  Future<BalancoPatrimonial> gerarBalanco(DateTime data) async {
    final contas = contaService.getAll();
    final ativos = contas.where((c) => c.tipo.isAtivo);
    final passivos = contas.where((c) => c.tipo.isPassivo);

    return BalancoPatrimonial(
      data: data,
      ativos: ativos.map((c) => ItemBalanco(c.nome, c.saldoAtual)).toList(),
      passivos: passivos.map((c) => ItemBalanco(c.nome, c.saldoAtual)).toList(),
      totalAtivos: ativos.sum((c) => c.saldoAtual),
      totalPassivos: passivos.sum((c) => c.saldoAtual),
      patrimonioLiquido: totalAtivos - totalPassivos,
    );
  }

  // Fluxo de Caixa
  Future<FluxoCaixa> gerarFluxoCaixa(DateTime inicio, DateTime fim) async {
    final receitas = receitaService.getPorPeriodo(inicio, fim);
    final despesas = lancamentoService.getLancamentosPorPeriodo(inicio, fim);

    return FluxoCaixa(
      periodo: DateRange(inicio, fim),
      entradas: _agruparPorCategoria(receitas),
      saidas: _agruparPorCategoria(despesas),
      totalEntradas: receitas.sum((r) => r.valor),
      totalSaidas: despesas.sum((d) => d.valor),
      saldoPeriodo: totalEntradas - totalSaidas,
      saldoInicial: _calcularSaldoEm(inicio.subtract(Duration(days: 1))),
      saldoFinal: _calcularSaldoEm(fim),
    );
  }

  // Fluxo de Caixa Mensal (para gráfico)
  Future<List<FluxoCaixaMensal>> gerarFluxoAnual(int ano) async {
    return List.generate(12, (mes) async {
      final inicio = DateTime(ano, mes + 1, 1);
      final fim = DateTime(ano, mes + 2, 0);
      return gerarFluxoCaixa(inicio, fim);
    });
  }
}
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-28.1 | Criar models: `BalancoPatrimonial`, `FluxoCaixa`, `ItemBalanco`, `FluxoCaixaMensal` | ⏳ TODO |
| CASH-28.2 | Criar `RelatorioService` com métodos de geração | ⏳ TODO |
| CASH-28.3 | Criar `BalancoScreen` com UI de balanço patrimonial | ⏳ TODO |
| CASH-28.4 | Criar `FluxoCaixaScreen` com UI de fluxo de caixa | ⏳ TODO |
| CASH-28.5 | Adicionar gráfico de barras (fl_chart) para fluxo anual | ⏳ TODO |
| CASH-28.6 | Implementar exportação PDF para ambos relatórios | ⏳ TODO |
| CASH-28.7 | Adicionar itens no drawer: "Balanço" e "Fluxo de Caixa" | ⏳ TODO |
| CASH-28.8 | Gate Premium: relatórios avançados só para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/balanco_patrimonial.dart` | CREATE | Model para balanço |
| `lib/models/fluxo_caixa.dart` | CREATE | Model para fluxo de caixa |
| `lib/services/relatorio_service.dart` | CREATE | Geração de relatórios |
| `lib/screens/balanco_screen.dart` | CREATE | UI balanço patrimonial |
| `lib/screens/fluxo_caixa_screen.dart` | CREATE | UI fluxo de caixa |
| `lib/widgets/cash_drawer.dart` | MODIFY | Adicionar itens de menu |

### Cross-Reference

- CASH-04: DRE existente (complementado por estes relatórios)
- CASH-23: Contas (fonte de dados para balanço)
- CASH-24: Receitas (fonte de dados para fluxo)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-27: Orçamento por Período — Planejamento por Categoria

### Status: [IMPLEMENTED]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir definir orçamento por categoria com múltiplos tipos de período (mês, trimestre, safra, ano). O ciclo agrícola não é mensal — orçamento por Safra (Set-Ago) é essencial para planejamento realista.

### Prerequisite

- CASH-26 (Contas a Pagar) deve estar DONE
- CORE-96 (Categoria model) deve estar DONE

### Por que Período Flexível?

O produtor rural opera em ciclos sazonais, não mensais:
- **Safra de borracha**: Set-Ago (colheita intensa no verão)
- **Safra de grãos**: Out-Mar (plantio → colheita)
- **Entressafra**: Gastos baixos, orçamento mensal não faz sentido

Orçamento mensal fixo pode dar falsa sensação de estouro na colheita (gastos altos) e folga na entressafra (gastos baixos).

### Model: Orcamento

```dart
@HiveType(typeId: 82)
class Orcamento implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final String categoriaId;      // Categoria do orçamento
  @HiveField(2)  final double valorLimite;      // Limite do período
  @HiveField(3)  final TipoPeriodoOrcamento tipo; // mes, trimestre, safra, ano
  @HiveField(4)  final int ano;                 // Ano de vigência (ou ano início da safra)
  @HiveField(5)  final int? mes;                // Mês específico (só se tipo=mes)
  @HiveField(6)  final int? trimestre;          // 1-4 (só se tipo=trimestre)
  @HiveField(7)  final bool alertaAtivo;        // Notificar quando ultrapassar
  @HiveField(8)  final int alertaPercentual;    // % para alertar (default 80)
  @HiveField(9)  final String farmId;
  // ... metadata sync

  // Computed
  DateRange get periodo => _calcularPeriodo();
  double get valorConsumido => _lancamentoService.totalPorCategoria(categoriaId, periodo);
  double get percentualConsumido => (valorConsumido / valorLimite) * 100;
  double get valorRestante => valorLimite - valorConsumido;
  bool get ultrapassou => valorConsumido > valorLimite;
  bool get alertar => percentualConsumido >= alertaPercentual;

  DateRange _calcularPeriodo() {
    switch (tipo) {
      case TipoPeriodoOrcamento.mes:
        return DateRange.mes(ano, mes!);
      case TipoPeriodoOrcamento.trimestre:
        return DateRange.trimestre(ano, trimestre!);
      case TipoPeriodoOrcamento.safra:
        // Safra: Set/ano até Ago/ano+1
        return DateRange(DateTime(ano, 9, 1), DateTime(ano + 1, 8, 31));
      case TipoPeriodoOrcamento.ano:
        return DateRange.ano(ano);
    }
  }
}

@HiveType(typeId: 83)
enum TipoPeriodoOrcamento {
  @HiveField(0) mes,        // Janeiro, Fevereiro, etc.
  @HiveField(1) trimestre,  // Q1, Q2, Q3, Q4
  @HiveField(2) safra,      // Set-Ago (ciclo agrícola)
  @HiveField(3) ano,        // Janeiro-Dezembro
}
```

### UX Orçamento

```
┌──────────────────────────────────────────────────────────────┐
│  Orçamento — Janeiro/2026                                   │
│  [◀ Dez]                                        [Fev ▶]     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Combustível                                            │ │
│  │ R$ 800 / R$ 1.000                           80% ██████░│ │
│  │ Restam R$ 200                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Mão de Obra                                   ⚠️       │ │
│  │ R$ 4.200 / R$ 4.000                        105% ██████▓│ │
│  │ Estourou R$ 200                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Alimentação                                            │ │
│  │ R$ 450 / R$ 800                             56% ████░░░│ │
│  │ Restam R$ 350                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ──────────────────────────────────────────────────────────  │
│  TOTAL ORÇADO: R$ 12.000    CONSUMIDO: R$ 8.500   71%       │
│  ──────────────────────────────────────────────────────────  │
│                                                              │
│  [+ Adicionar Categoria ao Orçamento]                       │
└──────────────────────────────────────────────────────────────┘
```

### UX Criação de Orçamento

```
┌──────────────────────────────────────────────────────────────┐
│  Definir Orçamento                                          │
│                                                              │
│  Categoria: [Combustível ▼]                                 │
│                                                              │
│  Período:                                                    │
│  ○ Mês      → [Janeiro ▼] / [2026 ▼]                       │
│  ○ Trimestre → [1º Tri ▼] / [2026 ▼]                       │
│  ◉ Safra    → Set/2025 a Ago/2026 (automático)             │
│  ○ Ano      → [2026 ▼]                                      │
│                                                              │
│  Valor limite: [R$ 12.000,00______]                        │
│  (Para toda a safra Set/2025 - Ago/2026)                   │
│                                                              │
│  Alertas:                                                    │
│  [✓] Notificar quando atingir [80]% do orçamento           │
│                                                              │
│  [Cancelar]                              [Salvar]           │
└──────────────────────────────────────────────────────────────┘
```

### Por que Safra como Período Padrão?

| Cenário | Orçamento Mensal | Orçamento por Safra |
|---------|------------------|---------------------|
| Jan (colheita) | ⚠️ Estoura (R$ 5k / R$ 1k) | ✅ Normal (R$ 5k / R$ 12k) |
| Jun (entressafra) | ✅ Sobra muito (R$ 200 / R$ 1k) | ✅ Normal |
| Visão real | Falsa sensação de descontrole | Visão do ciclo completo |

### Alertas

```dart
class OrcamentoAlertService {
  /// Verifica orçamentos e dispara notificações.
  /// Chamado após cada lançamento de despesa.
  Future<void> verificarAlertas() async {
    for (final orcamento in orcamentoService.orcamentosDoMes) {
      if (orcamento.alertaAtivo && orcamento.alertar && !_jaAlertou(orcamento)) {
        await _notificar(
          title: 'Orçamento de ${orcamento.categoria.nome}',
          body: orcamento.ultrapassou
            ? 'Você ultrapassou o orçamento em R\$ ${orcamento.valorConsumido - orcamento.valorMensal}'
            : 'Você atingiu ${orcamento.percentualConsumido.toInt()}% do orçamento',
        );
        _marcarAlertado(orcamento);
      }
    }
  }
}
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-27.1 | Criar model `Orcamento` com Hive typeId 82 | ⏳ TODO |
| CASH-27.2 | Criar `OrcamentoService` extends GenericSyncService | ⏳ TODO |
| CASH-27.3 | Criar `OrcamentoScreen` com lista de orçamentos e progresso | ⏳ TODO |
| CASH-27.4 | Criar bottom sheet para criar/editar orçamento | ⏳ TODO |
| CASH-27.5 | Criar `OrcamentoAlertService` para notificações | ⏳ TODO |
| CASH-27.6 | Integrar verificação de alerta após cada lançamento | ⏳ TODO |
| CASH-27.7 | Adicionar "Orçamento" no drawer | ⏳ TODO |
| CASH-27.8 | Gate Premium: orçamento só para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/orcamento.dart` | CREATE | Model Hive typeId 82 |
| `lib/services/orcamento_service.dart` | CREATE | CRUD + queries |
| `lib/services/orcamento_alert_service.dart` | CREATE | Verificação e notificações |
| `lib/screens/orcamento_screen.dart` | CREATE | UI de orçamento |
| `lib/screens/calculator_screen.dart` | MODIFY | Chamar verificação após lançamento |
| `lib/main.dart` | MODIFY | Registrar adapter, inicializar service |

### Hive TypeIds

| TypeId | Model |
|--------|-------|
| 82 | Orcamento |
| 83 | TipoPeriodoOrcamento |

### Cross-Reference

- CORE-96: Categoria (categoriaId referencia)
- CASH-04: DRE (já usa período Safra Sep-Aug)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-26: Contas a Pagar e a Receber — Gestão de Vencimentos

### Status: [IMPLEMENTED]
**Priority**: 🔴 CRITICAL
**Objective**: Gerenciar compromissos financeiros com vencimento: contas a pagar (fornecedores, parcelas) e contas a receber (clientes, vendas a prazo). Alertas de vencimento via notificação.

### Prerequisite

- CASH-25 (Transferências) deve estar DONE
- CASH-23 (Contas) deve estar DONE

### Model: ContaPagar

```dart
@HiveType(typeId: 80)
class ContaPagar implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final String descricao;         // "Parcela Trator", "Nota Fiscal Adubo"
  @HiveField(2)  final double valor;
  @HiveField(3)  final DateTime vencimento;
  @HiveField(4)  final String? fornecedor;       // Nome do fornecedor
  @HiveField(5)  final String? categoriaId;      // Categoria da despesa
  @HiveField(6)  final StatusPagamento status;   // pendente, pago, vencido, cancelado
  @HiveField(7)  final DateTime? dataPagamento;

  // VÍNCULO COM LANÇAMENTO (Double-Entry Escondido)
  @HiveField(8)  final String? lancamentoOrigemId;  // Lançamento criado NA COMPRA (despesa reconhecida)
  @HiveField(9)  final String? contaPagamentoId;    // Conta de onde SAIU o dinheiro (preenchido ao pagar)

  @HiveField(10) final int? parcela;             // Número da parcela (1, 2, 3...)
  @HiveField(11) final int? totalParcelas;       // Total de parcelas
  @HiveField(12) final String? parcelaGrupoId;   // Agrupa parcelas do mesmo compromisso
  @HiveField(13) final String farmId;
  // ... metadata sync

  // Computed
  bool get isVencido => status == StatusPagamento.pendente && vencimento.isBefore(DateTime.now());
  int get diasParaVencer => vencimento.difference(DateTime.now()).inDays;
  String get parcelaLabel => parcela != null ? '$parcela/$totalParcelas' : '';
}

enum StatusPagamento { pendente, pago, vencido, cancelado }
```

### Regra Contábil (Double-Entry Escondido)

**IMPORTANTE:** A despesa é reconhecida no momento da COMPRA, não do pagamento.

```
COMPRA A PRAZO (criar ContaPagar):
┌─────────────────────────────────────────────────────────────┐
│  1. Cria Lancamento (despesa reconhecida, contaId=NULL)    │
│  2. Cria ContaPagar com lancamentoOrigemId = lancamento.id │
│  3. DRE reconhece despesa na data da COMPRA                │
│  4. Balanço: Passivo aumenta (fornecedor)                  │
└─────────────────────────────────────────────────────────────┘

PAGAMENTO (baixar ContaPagar):
┌─────────────────────────────────────────────────────────────┐
│  1. Atualiza ContaPagar: status=pago, contaPagamentoId=X   │
│  2. NÃO cria novo Lancamento (despesa já reconhecida!)     │
│  3. DRE: sem alteração (despesa já estava lá)              │
│  4. Fluxo de Caixa: saída na data do PAGAMENTO             │
│  5. Balanço: Passivo diminui, Ativo diminui                │
└─────────────────────────────────────────────────────────────┘
```

### Model: ContaReceber

```dart
@HiveType(typeId: 81)
class ContaReceber implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final String descricao;         // "Venda Borracha João", "Bezerro Faz. Esperança"
  @HiveField(2)  final double valor;
  @HiveField(3)  final DateTime vencimento;
  @HiveField(4)  final String? cliente;          // Nome do cliente
  @HiveField(5)  final String? categoriaId;      // Categoria da receita
  @HiveField(6)  final String? contaId;          // Conta que vai receber
  @HiveField(7)  final StatusRecebimento status; // pendente, recebido, vencido, cancelado
  @HiveField(8)  final DateTime? dataRecebimento;
  @HiveField(9)  final String? receitaId;        // Receita gerada ao receber
  @HiveField(10) final String farmId;
  // ... metadata sync

  bool get isVencido => status == StatusRecebimento.pendente && vencimento.isBefore(DateTime.now());
  int get diasParaVencer => vencimento.difference(DateTime.now()).inDays;
}

enum StatusRecebimento { pendente, recebido, vencido, cancelado }
```

### UX Contas a Pagar

```
┌──────────────────────────────────────────────────────────────┐
│  Contas a Pagar                                    [+ Nova] │
│                                                              │
│  🔴 VENCIDAS (2)                              R$ 1.500,00   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ⚠️ Parcela Trator 3/12          Venceu 05/01          │ │
│  │    R$ 800,00                    [Pagar] [Adiar]       │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │ ⚠️ Nota Fiscal Adubo            Venceu 10/01          │ │
│  │    R$ 700,00                    [Pagar] [Adiar]       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  🟡 VENCE ESTA SEMANA (3)                     R$ 2.100,00   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Energia Elétrica                Vence 25/01 (3 dias)  │ │
│  │ R$ 450,00                       [Pagar]               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  🟢 PRÓXIMAS (5)                              R$ 4.800,00   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Parcela Trator 4/12             Vence 05/02           │ │
│  │ R$ 800,00                                              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ──────────────────────────────────────────────────────────  │
│  TOTAL PENDENTE: R$ 8.400,00                                │
└──────────────────────────────────────────────────────────────┘
```

### Ação "Pagar"

Ao clicar em "Pagar":
1. Abre modal para selecionar conta de origem (de onde sai o dinheiro)
2. **NÃO cria novo Lancamento** (despesa já foi reconhecida na compra!)
3. Atualiza `ContaPagar`:
   - `status = pago`
   - `dataPagamento = hoje`
   - `contaPagamentoId = conta selecionada`
4. Saldo da conta é recalculado automaticamente (Fluxo de Caixa registra a saída)

**Por que não cria Lançamento ao pagar?**
- A despesa já foi reconhecida quando a ContaPagar foi criada (regime de competência)
- Criar outro Lançamento duplicaria a despesa no DRE
- O Fluxo de Caixa captura a saída através do `contaPagamentoId`

### Criação com Parcelas

```
┌──────────────────────────────────────────────────────────────┐
│  Nova Conta a Pagar                                         │
│                                                              │
│  Descrição: [Financiamento Trator_____]                    │
│  Fornecedor: [Banco do Brasil_________]                    │
│  Valor total: [R$ 9.600,00____________]                    │
│                                                              │
│  Parcelamento:                                               │
│  ○ À vista                                                   │
│  ◉ Parcelado em [12] vezes de R$ 800,00                    │
│                                                              │
│  Primeiro vencimento: [05/02/2026]                          │
│                                                              │
│  Categoria: [Financiamentos ▼]                              │
│  Pagar com: [Sicredi Agro ▼]                               │
│                                                              │
│  [Cancelar]                              [Criar 12 parcelas]│
└──────────────────────────────────────────────────────────────┘
```

### Alertas de Vencimento

```dart
class VencimentoAlertService {
  /// Agenda notificações para vencimentos.
  /// Chamado no startup e após criar/editar conta.
  Future<void> agendarAlertas() async {
    // Limpa alertas antigos
    await notificationService.cancelByTag('vencimento');

    // Agenda alertas para os próximos 30 dias
    final contas = [...contaPagarService.pendentes, ...contaReceberService.pendentes];
    for (final conta in contas.where((c) => c.diasParaVencer <= 30)) {
      // Alerta 3 dias antes
      if (conta.diasParaVencer >= 3) {
        await notificationService.schedule(
          id: '${conta.id}_3d',
          title: conta is ContaPagar ? 'Conta a pagar' : 'Conta a receber',
          body: '${conta.descricao} vence em 3 dias (R\$ ${conta.valor})',
          scheduledDate: conta.vencimento.subtract(Duration(days: 3)),
          tag: 'vencimento',
        );
      }
      // Alerta no dia
      await notificationService.schedule(
        id: '${conta.id}_0d',
        title: conta is ContaPagar ? '⚠️ Conta vence HOJE' : '💰 Recebimento HOJE',
        body: '${conta.descricao} - R\$ ${conta.valor}',
        scheduledDate: conta.vencimento,
        tag: 'vencimento',
      );
    }
  }
}
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-26.1 | Criar model `ContaPagar` com Hive typeId 80 | ⏳ TODO |
| CASH-26.2 | Criar model `ContaReceber` com Hive typeId 81 | ⏳ TODO |
| CASH-26.3 | Criar `ContaPagarService` e `ContaReceberService` | ⏳ TODO |
| CASH-26.4 | Criar `ContasPagarScreen` com agrupamento por status | ⏳ TODO |
| CASH-26.5 | Criar `ContasReceberScreen` | ⏳ TODO |
| CASH-26.6 | Implementar ação "Pagar" que cria Lancamento automaticamente | ⏳ TODO |
| CASH-26.7 | Implementar ação "Receber" que cria Receita automaticamente | ⏳ TODO |
| CASH-26.8 | Implementar criação de parcelas em lote | ⏳ TODO |
| CASH-26.9 | Criar `VencimentoAlertService` para notificações | ⏳ TODO |
| CASH-26.10 | Adicionar "A Pagar" e "A Receber" no drawer | ⏳ TODO |
| CASH-26.11 | Gate Premium: contas a pagar/receber só para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/conta_pagar.dart` | CREATE | Model Hive typeId 80 |
| `lib/models/conta_receber.dart` | CREATE | Model Hive typeId 81 |
| `lib/services/conta_pagar_service.dart` | CREATE | CRUD + queries |
| `lib/services/conta_receber_service.dart` | CREATE | CRUD + queries |
| `lib/services/vencimento_alert_service.dart` | CREATE | Agendamento de notificações |
| `lib/screens/contas_pagar_screen.dart` | CREATE | UI contas a pagar |
| `lib/screens/contas_receber_screen.dart` | CREATE | UI contas a receber |
| `lib/main.dart` | MODIFY | Registrar adapters, inicializar services |

### Hive TypeIds

| TypeId | Model |
|--------|-------|
| 80 | ContaPagar |
| 81 | ContaReceber |

### Cross-Reference

- CASH-23: Conta (contaId referencia)
- CORE-96: Categoria (categoriaId referencia)
- CASH-01: Lancamento (gerado ao pagar)
- CASH-24: Receita (gerada ao receber)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-25: Transferências entre Contas

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir transferências entre contas (ex: da conta corrente para poupança, ou da carteira para conta). Atualiza saldos de ambas as contas sem afetar DRE (não é receita nem despesa).

### Prerequisite

- CASH-23 (Contas) deve estar DONE

### Model: Transferencia

```dart
@HiveType(typeId: 79)
class Transferencia implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final double valor;
  @HiveField(2)  final String contaOrigemId;     // De onde sai
  @HiveField(3)  final String contaDestinoId;    // Para onde vai
  @HiveField(4)  final DateTime data;
  @HiveField(5)  final String? descricao;        // "Reserva para emergência"
  @HiveField(6)  final String farmId;
  // ... metadata sync

  // Computed (via service)
  Conta get contaOrigem => contaService.getById(contaOrigemId)!;
  Conta get contaDestino => contaService.getById(contaDestinoId)!;
}
```

### Regra de Negócio

```
Transferência de R$ 500 da "Nubank" para "Poupança":
  1. Nubank.saldo -= 500
  2. Poupança.saldo += 500
  3. NÃO cria Lancamento (não é despesa)
  4. NÃO cria Receita (não é receita)
  5. NÃO afeta DRE
  6. AFETA Fluxo de Caixa (movimentação interna)
```

### UX Transferência

```
┌──────────────────────────────────────────────────────────────┐
│  Nova Transferência                                         │
│                                                              │
│  De: [Nubank - Conta Corrente ▼]      Saldo: R$ 3.200,00   │
│                                                              │
│           ↓ R$ [500,00___________]                          │
│                                                              │
│  Para: [Sicredi - Poupança ▼]         Saldo: R$ 15.000,00  │
│                                                              │
│  Data: [28/01/2026]                                         │
│                                                              │
│  Descrição: [Reserva para emergência_____] (opcional)       │
│                                                              │
│  [Cancelar]                              [Transferir]       │
└──────────────────────────────────────────────────────────────┘
```

### UX Histórico de Transferências

```
┌──────────────────────────────────────────────────────────────┐
│  Transferências — Janeiro/2026                              │
│                                                              │
│  28/01  Nubank → Poupança                    R$ 500,00     │
│         Reserva para emergência                             │
│                                                              │
│  15/01  Carteira → Nubank                    R$ 200,00     │
│         Depósito dinheiro físico                            │
│                                                              │
│  05/01  Poupança → Nubank                    R$ 1.000,00   │
│         Pagar parcela trator                                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-25.1 | Criar model `Transferencia` com Hive typeId 79 | ⏳ TODO |
| CASH-25.2 | Criar `TransferenciaService` extends GenericSyncService | ⏳ TODO |
| CASH-25.3 | Implementar lógica de atualização de saldos (origem -= valor, destino += valor) | ⏳ TODO |
| CASH-25.4 | Criar `TransferenciaScreen` para nova transferência | ⏳ TODO |
| CASH-25.5 | Criar `TransferenciasListScreen` para histórico | ⏳ TODO |
| CASH-25.6 | Adicionar "Transferências" no drawer | ⏳ TODO |
| CASH-25.7 | Gate Premium: transferências só para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/transferencia.dart` | CREATE | Model Hive typeId 79 |
| `lib/services/transferencia_service.dart` | CREATE | CRUD + atualização de saldos |
| `lib/screens/transferencia_screen.dart` | CREATE | UI nova transferência |
| `lib/screens/transferencias_list_screen.dart` | CREATE | Histórico |
| `lib/main.dart` | MODIFY | Registrar adapter |

### Hive TypeId

| TypeId | Model |
|--------|-------|
| 79 | Transferencia |

### Cross-Reference

- CASH-23: Conta (contaOrigemId, contaDestinoId referenciam)
- CASH-28: Fluxo de Caixa (inclui transferências como movimentação)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-24: Receitas — Registro de Entradas

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir registro de receitas (vendas, rendimentos, outras entradas). Complementa as despesas para ter visão completa de entradas e saídas. Integra com DRE e Fluxo de Caixa.

### Prerequisite

- CASH-23 (Contas) deve estar DONE
- CORE-96 (Categoria com isReceita) deve estar DONE

### Model: Receita

```dart
@HiveType(typeId: 74)
class Receita implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final double valor;
  @HiveField(2)  final String categoriaId;       // Categoria com isReceita=true
  @HiveField(3)  final DateTime data;
  @HiveField(4)  final String? descricao;
  @HiveField(5)  final String? contaId;          // Conta onde entrou (Premium)
  @HiveField(6)  final String? centroCustoId;
  @HiveField(7)  final String? clienteNome;      // Nome do cliente/comprador
  @HiveField(8)  final String farmId;
  @HiveField(9)  final String createdBy;
  @HiveField(10) final DateTime createdAt;
  @HiveField(11) final DateTime updatedAt;
  @HiveField(12) final String sourceApp;         // 'ruracash', 'rurarubber', 'ruracattle'

  // Factory
  factory Receita.create({...});

  // Serialization
  Map<String, dynamic> toJson();
  factory Receita.fromJson(Map<String, dynamic> json);
}
```

### Categorias de Receita (Core)

Adicionar ao CORE-96 (CategoriaCore):

```dart
enum CategoriaCore {
  // ... despesas existentes ...

  // Receitas Agrícolas
  vendaBorracha,      // Cross-app: RuraRubber
  vendaGado,          // Cross-app: RuraCattle
  vendaLeite,         // Cross-app: RuraCattle
  vendaGraos,         // Soja, milho, etc
  arrendamento,       // Aluguel de terra/pasto
  outrasReceitasAgro, // Receitas agrícolas diversas

  // Receitas Pessoais
  salario,            // Salário/pró-labore
  rendimentos,        // Investimentos, dividendos
  outrasReceitasPessoal,
}
```

### UX Entrada de Receita

Usar mesmo padrão da CalculatorScreen, mas para receitas:

```
┌──────────────────────────────────────────────────────────────┐
│  Nova Receita                                               │
│                                                              │
│              R$ 8.500,00                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  7  │  8  │  9  │                                      │ │
│  │  4  │  5  │  6  │                                      │ │
│  │  1  │  2  │  3  │                                      │ │
│  │  ,  │  0  │  ⌫  │                                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Categoria:                                                  │
│  [Venda Borracha] [Venda Gado] [Arrendamento] [Outras]     │
│                                                              │
│  Entrou em: [Sicredi Agro ▼]                               │
│                                                              │
│  Cliente: [Cooperativa ABC_______] (opcional)               │
│                                                              │
│                                    [✓ Salvar Receita]       │
└──────────────────────────────────────────────────────────────┘
```

### Integração Cross-App

RuraRubber e RuraCattle podem criar receitas diretamente no RuraCash:

```dart
// No RuraRubber, ao registrar venda:
await receitaService.quickAdd(
  valor: vendaBorracha.valorTotal,
  categoriaId: categoriaService.getByCoreKey('vendaBorracha')!.id,
  descricao: 'Venda ${vendaBorracha.kg}kg borracha',
  sourceApp: 'rurarubber',
);
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-24.1 | Criar model `Receita` com Hive typeId 74 | ⏳ TODO |
| CASH-24.2 | Adicionar categorias de receita ao CORE-96 (CategoriaCore) | ⏳ TODO |
| CASH-24.3 | Criar `ReceitaService` extends GenericSyncService | ⏳ TODO |
| CASH-24.4 | Criar `ReceitaCalculatorScreen` (clone do CalculatorScreen para receitas) | ⏳ TODO |
| CASH-24.5 | Integrar receitas no DRE existente (seção "Receitas" funcional) | ⏳ TODO |
| CASH-24.6 | Atualizar saldo da conta ao criar receita (se Premium com contas) | ⏳ TODO |
| CASH-24.7 | Adicionar botão "+ Receita" na home | ⏳ TODO |
| CASH-24.8 | Gate Premium: vincular conta é Premium, criar receita é Free | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/receita.dart` | CREATE | Model Hive typeId 74 |
| `lib/services/receita_service.dart` | CREATE | CRUD + queries |
| `lib/screens/receita_calculator_screen.dart` | CREATE | UI entrada de receita |
| `lib/screens/home_screen.dart` | MODIFY | Adicionar FAB para receita |
| `lib/screens/dre_screen.dart` | MODIFY | Integrar receitas reais |
| `lib/main.dart` | MODIFY | Registrar adapter |

### Hive TypeId

| TypeId | Model |
|--------|-------|
| 74 | Receita |

### Cross-Reference

- CORE-96: Categoria (categoriaId com isReceita=true)
- CASH-04: DRE (consumidor de receitas)
- CASH-23: Conta (contaId para atualizar saldo)
- CASH-28: Fluxo de Caixa (entradas)
- RuraRubber: Venda de borracha cria receita
- RuraCattle: Venda de gado/leite cria receita

---

## Phase CASH-23: Contas Bancárias — Controle de Saldos

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir criação de contas (carteira, conta corrente, poupança, cartão de crédito, investimentos) para controle de saldos e origem/destino de movimentações. Base para transferências, reconciliação e balanço patrimonial.

### Prerequisite

- CASH-22 (Categorias Custom) deve estar DONE

### Model: TipoConta

```dart
@HiveType(typeId: 75)
enum TipoConta {
  @HiveField(0) carteira,         // Dinheiro físico
  @HiveField(1) contaCorrente,    // Banco - conta corrente
  @HiveField(2) poupanca,         // Banco - poupança
  @HiveField(3) investimento,     // CDB, ações, fundos
  @HiveField(4) cartaoCredito,    // Fatura de cartão (passivo)
  @HiveField(5) emprestimo,       // Financiamento, empréstimo (passivo)
  @HiveField(6) aPagar,           // Fornecedores (passivo)
  @HiveField(7) aReceber,         // Clientes (ativo)
}

extension TipoContaExtension on TipoConta {
  bool get isAtivo => [carteira, contaCorrente, poupanca, investimento, aReceber].contains(this);
  bool get isPassivo => [cartaoCredito, emprestimo, aPagar].contains(this);
  String get label => _labels[this]!;
  IconData get icon => _icons[this]!;
}
```

### Model: Conta

```dart
@HiveType(typeId: 73)
class Conta implements FarmOwnedEntity, SyncableEntity {
  @HiveField(0)  final String id;
  @HiveField(1)  final String nome;              // "Nubank", "Carteira", "Sicredi Agro"
  @HiveField(2)  final TipoConta tipo;
  @HiveField(3)  final double saldoInicial;      // Saldo no momento da criação
  @HiveField(4)  final String? banco;            // Nome do banco (opcional)
  @HiveField(5)  final String? agencia;          // Agência (opcional)
  @HiveField(6)  final String? numeroConta;      // Número da conta (opcional)
  @HiveField(7)  final int corValue;             // Cor para identificação
  @HiveField(8)  final String icone;             // Ícone Material
  @HiveField(9)  final bool isAtiva;             // false = arquivada
  @HiveField(10) final int ordem;                // Ordenação na lista
  @HiveField(11) final String farmId;
  // ... metadata sync

  // Computed
  Color get cor => Color(corValue);
  IconData get iconData => _iconMap[icone] ?? tipo.icon;

  /// Saldo atual = saldoInicial + receitas - despesas - transferênciasOut + transferênciasIn
  /// Calculado pelo ContaService, não armazenado (evita inconsistência)
  double get saldoAtual => _contaService.calcularSaldo(id);

  // Factory
  factory Conta.create({
    required String nome,
    required TipoConta tipo,
    double saldoInicial = 0.0,
    String? banco,
    int? corValue,
  });
}
```

### Service: ContaService

```dart
class ContaService extends GenericSyncService<Conta> {
  static final ContaService _instance = ContaService._internal();
  factory ContaService() => _instance;

  @override String get boxName => 'contas';
  @override String get firestoreCollection => 'contas';

  // Queries
  List<Conta> get contasAtivas => getAll().where((c) => c.isAtiva).toList();
  List<Conta> get contasAtivos => contasAtivas.where((c) => c.tipo.isAtivo).toList();
  List<Conta> get contasPassivos => contasAtivas.where((c) => c.tipo.isPassivo).toList();
  Conta? get contaPadrao => contasAtivas.firstOrNull;

  /// Calcula saldo atual da conta.
  /// saldo = saldoInicial + receitas(contaId) - despesas(contaId) + transferênciasIn - transferênciasOut
  double calcularSaldo(String contaId) {
    final conta = getById(contaId);
    if (conta == null) return 0.0;

    final receitas = receitaService.getByContaId(contaId).sum((r) => r.valor);
    final despesas = lancamentoService.getByContaId(contaId).sum((l) => l.valor);
    final transferenciasIn = transferenciaService.getByDestinoId(contaId).sum((t) => t.valor);
    final transferenciasOut = transferenciaService.getByOrigemId(contaId).sum((t) => t.valor);

    return conta.saldoInicial + receitas - despesas + transferenciasIn - transferenciasOut;
  }

  /// Patrimônio total = soma dos saldos de contas ativas (ativos - passivos)
  double get patrimonioTotal {
    return contasAtivos.sum((c) => calcularSaldo(c.id)) -
           contasPassivos.sum((c) => calcularSaldo(c.id).abs());
  }

  // Inicialização
  /// Cria conta "Carteira" padrão se não existir.
  Future<void> ensureDefaultConta() async {
    if (contasAtivas.isEmpty) {
      await add(Conta.create(
        nome: 'Carteira',
        tipo: TipoConta.carteira,
        saldoInicial: 0.0,
      ));
    }
  }
}
```

### Migração Free → Premium

Ao ativar Premium, se não existem contas:
1. Cria conta "Carteira" com saldo R$ 0
2. Todos os lançamentos existentes ficam com `contaId = null` (sem conta vinculada)
3. Usuário pode vincular retrospectivamente ou deixar sem conta

### UX Lista de Contas

```
┌──────────────────────────────────────────────────────────────┐
│  Minhas Contas                                     [+ Nova] │
│                                                              │
│  ATIVOS                                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 💵 Carteira                               R$ 500,00    │ │
│  │ 🏦 Nubank (Conta Corrente)                R$ 3.200,00  │ │
│  │ 🏦 Sicredi Agro (Conta Corrente)          R$ 8.500,00  │ │
│  │ 💰 Sicredi (Poupança)                     R$ 15.000,00 │ │
│  │ 📈 CDB Banco Inter                        R$ 8.000,00  │ │
│  └────────────────────────────────────────────────────────┘ │
│  Total Ativos: R$ 35.200,00                                 │
│                                                              │
│  PASSIVOS                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 💳 Cartão Nubank                          R$ 1.200,00  │ │
│  │ 🏛️ Financiamento Trator                   R$ 25.000,00 │ │
│  └────────────────────────────────────────────────────────┘ │
│  Total Passivos: R$ 26.200,00                               │
│                                                              │
│  ══════════════════════════════════════════════════════════ │
│  PATRIMÔNIO LÍQUIDO                          R$ 9.000,00   │
│  ══════════════════════════════════════════════════════════ │
└──────────────────────────────────────────────────────────────┘
```

### UX Criar Conta

```
┌──────────────────────────────────────────────────────────────┐
│  Nova Conta                                                 │
│                                                              │
│  Tipo:                                                       │
│  [💵 Carteira]  [🏦 Conta Corrente]  [💰 Poupança]         │
│  [📈 Investimento]  [💳 Cartão]  [🏛️ Empréstimo]          │
│                                                              │
│  Nome: [Sicredi Agro_____________]                          │
│                                                              │
│  Banco: [Sicredi_________________] (opcional)               │
│                                                              │
│  Saldo atual: [R$ 8.500,00_________]                        │
│  (Informe o saldo de hoje, o app calculará a partir daqui) │
│                                                              │
│  Cor: [●] [●] [●] [●] [●]                                  │
│                                                              │
│  [Cancelar]                              [Criar Conta]      │
└──────────────────────────────────────────────────────────────┘
```

### Vínculo com Lancamento

Adicionar campo ao Lancamento existente:

```dart
// Adicionar ao model Lancamento
@HiveField(15) final String? contaId;  // Conta de onde saiu o dinheiro (opcional)
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-23.1 | Criar enum `TipoConta` com Hive typeId 75 | ⏳ TODO |
| CASH-23.2 | Criar model `Conta` com Hive typeId 73 | ⏳ TODO |
| CASH-23.3 | Criar `ContaService` com cálculo de saldo e patrimônio | ⏳ TODO |
| CASH-23.4 | Adicionar campo `contaId` ao Lancamento existente | ⏳ TODO |
| CASH-23.5 | Criar `ContasScreen` com lista de contas e patrimônio | ⏳ TODO |
| CASH-23.6 | Criar bottom sheet para criar/editar conta | ⏳ TODO |
| CASH-23.7 | Adicionar seletor de conta no CalculatorScreen | ⏳ TODO |
| CASH-23.8 | Adicionar "Contas" no drawer | ⏳ TODO |
| CASH-23.9 | Gate Premium: contas só para assinantes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/tipo_conta.dart` | CREATE | Enum Hive typeId 75 |
| `lib/models/conta.dart` | CREATE | Model Hive typeId 73 |
| `lib/models/lancamento.dart` | MODIFY | Adicionar contaId |
| `lib/services/conta_service.dart` | CREATE | CRUD + cálculo de saldo |
| `lib/screens/contas_screen.dart` | CREATE | UI lista de contas |
| `lib/screens/calculator_screen.dart` | MODIFY | Adicionar seletor de conta |
| `lib/main.dart` | MODIFY | Registrar adapters |

### Hive TypeIds

| TypeId | Model |
|--------|-------|
| 73 | Conta |
| 75 | TipoConta |

### Cross-Reference

- CASH-24: Receita.contaId (entrada na conta)
- CASH-25: Transferencia (origem/destino)
- CASH-28: Balanço Patrimonial (usa saldos)
- CASH-29: Reconciliação (por conta)
- CASH-30: Paywall (feature Premium)

---

## Phase CASH-22: Categorias Customizáveis — UI de Gestão

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Criar interface para usuário visualizar, criar, editar e arquivar categorias. Categorias core (14) são editáveis apenas visualmente (ícone, cor). Categorias custom são totalmente editáveis.

### Prerequisite

- CASH-21 (Migração para Categoria model) deve estar DONE
- CORE-96 (CategoriaService) deve estar DONE

### UX Lista de Categorias

```
┌──────────────────────────────────────────────────────────────┐
│  Categorias                                        [+ Nova] │
│                                                              │
│  DESPESAS AGRÍCOLAS                                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ⛽ Diesel da Fazenda              🔒 core    [Editar]  │ │
│  │ 👷 Mão de Obra                    🔒 core    [Editar]  │ │
│  │ 🌱 Adubo                          🔒 core    [Editar]  │ │
│  │ 🧪 Defensivos                     🔒 core    [Editar]  │ │
│  │ 🔧 Manutenção                     🔒 core    [Editar]  │ │
│  │ ⚡ Energia                        🔒 core    [Editar]  │ │
│  │ 🐄 Ração Gado                              [Editar] 🗑️│ │
│  │ 📦 Outros                         🔒 core    [Editar]  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  DESPESAS PESSOAIS                                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 🍽️ Alimentação                    🔒 core    [Editar]  │ │
│  │ 🚗 Transporte                     🔒 core    [Editar]  │ │
│  │ ...                                                    │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ARQUIVADAS (2)                                    [Mostrar]│
└──────────────────────────────────────────────────────────────┘
```

### UX Editar Categoria Core

```
┌──────────────────────────────────────────────────────────────┐
│  Editar Categoria                                           │
│                                                              │
│  Nome: [Diesel da Fazenda_____]                             │
│  (O nome original "Combustível" é usado internamente)       │
│                                                              │
│  Ícone: [⛽] [🚜] [🛢️] [🔥] [+]                            │
│                                                              │
│  Cor: [●] [●] [●] [●] [●] [+]                              │
│                                                              │
│  Tipo: Despesa 🔒 (não editável)                           │
│  Contexto: Agrícola 🔒 (não editável)                      │
│                                                              │
│  [Cancelar]                    [Salvar Personalização]      │
│                                                              │
│  ℹ️ Esta é uma categoria do sistema. Você pode             │
│     personalizar a aparência, mas não pode excluí-la.      │
└──────────────────────────────────────────────────────────────┘
```

### UX Criar Categoria Custom

```
┌──────────────────────────────────────────────────────────────┐
│  Nova Categoria                                             │
│                                                              │
│  Nome: [Ração para Gado__________]                         │
│                                                              │
│  Tipo:                                                       │
│  ◉ Despesa   ○ Receita                                      │
│  (Não pode mudar depois de usar)                            │
│                                                              │
│  Contexto:                                                   │
│  [✓] Agrícola   [ ] Pessoal                                │
│                                                              │
│  Ícone: [🐄] [🌾] [🚜] [💊] [+]                            │
│                                                              │
│  Cor: [●] [●] [●] [●] [●] [+]                              │
│                                                              │
│  [Cancelar]                              [Criar Categoria]  │
└──────────────────────────────────────────────────────────────┘
```

### UX Deletar/Arquivar

```
┌──────────────────────────────────────────────────────────────┐
│  Remover "Ração para Gado"?                                 │
│                                                              │
│  Esta categoria tem 15 lançamentos vinculados.              │
│                                                              │
│  ○ Arquivar (recomendado)                                   │
│    A categoria ficará oculta, mas os lançamentos            │
│    continuarão mostrando o nome original.                   │
│                                                              │
│  ○ Mover lançamentos para outra categoria                   │
│    [Outros Agrícola ▼]                                      │
│    E então excluir permanentemente.                         │
│                                                              │
│  [Cancelar]                              [Confirmar]        │
└──────────────────────────────────────────────────────────────┘
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-22.1 | Criar `CategoriasScreen` com lista agrupada (agro despesa, pessoal despesa, receitas, arquivadas) | ⏳ TODO |
| CASH-22.2 | Criar bottom sheet para editar categoria (core: só visual; custom: tudo) | ⏳ TODO |
| CASH-22.3 | Criar bottom sheet para criar categoria custom | ⏳ TODO |
| CASH-22.4 | Criar dialog de confirmação para arquivar/mover/deletar | ⏳ TODO |
| CASH-22.5 | Adicionar "Categorias" no drawer | ⏳ TODO |
| CASH-22.6 | Atualizar CalculatorScreen para usar categorias do CategoriaService (não mais enum) | ⏳ TODO |
| CASH-22.7 | Gate Premium: criar categoria custom é Premium, editar visual de core é Free | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/categorias_screen.dart` | CREATE | UI lista de categorias |
| `lib/widgets/categoria_edit_sheet.dart` | CREATE | Bottom sheet edição |
| `lib/widgets/categoria_create_sheet.dart` | CREATE | Bottom sheet criação |
| `lib/widgets/categoria_delete_dialog.dart` | CREATE | Dialog confirmação |
| `lib/screens/calculator_screen.dart` | MODIFY | Usar CategoriaService |
| `lib/widgets/cash_drawer.dart` | MODIFY | Adicionar item "Categorias" |

### Cross-Reference

- CORE-96: CategoriaService (backend)
- CASH-21: Migração (pré-requisito)
- CASH-30: Paywall (criar custom é Premium)

---

## Phase CASH-21: Migração CashCategoria enum → Categoria model

### Status: [TODO]
**Priority**: 🔴 CRITICAL
**Objective**: Migrar de `CashCategoria` (enum com 14 valores fixos) para `Categoria` (model do CORE-96). Preservar todos os lançamentos existentes mapeando enum → categoriaId. Deprecar enum após migração.

### Prerequisite

- CORE-96 (Categoria model e CategoriaService) deve estar DONE

### Problema Atual

```dart
// Lancamento atual
class Lancamento {
  final CashCategoria categoria;  // Enum, limitado a 14 valores
  // ...
}

// Enum atual
enum CashCategoria {
  maoDeObra, adubo, defensivos, combustivel, manutencao, energia, outros,
  alimentacao, transporte, saude, educacao, lazer, moradia, outrosPessoal,
}
```

### Solução: Migração

```dart
// Lancamento novo
class Lancamento {
  final String categoriaId;       // ID do model Categoria
  // campo 'categoria' removido
}
```

### Fluxo de Migração

```
┌─────────────────────────────────────────────────────────────────┐
│  1. App inicia                                                  │
│  2. CategoriaService.ensureDefaultCategorias()                 │
│     → Cria 14 categorias core com coreKey preenchido           │
│  3. MigrationService.migrateCategoriasIfNeeded()               │
│     → Detecta se há lançamentos com campo 'categoria' (enum)   │
│     → Para cada lançamento:                                     │
│        a. Pega enum: lancamento.categoria (ex: CashCategoria.combustivel) │
│        b. Busca model: categoriaService.getByCoreKey('combustivel')      │
│        c. Atualiza: lancamento.categoriaId = model.id           │
│     → Marca migração como concluída em SharedPreferences       │
│  4. Remove campo 'categoria' do Lancamento em versão futura    │
└─────────────────────────────────────────────────────────────────┘
```

### Mapeamento enum → coreKey

| CashCategoria (enum) | CategoriaCore (coreKey) |
|----------------------|-------------------------|
| `maoDeObra` | `'maoDeObra'` |
| `adubo` | `'adubo'` |
| `defensivos` | `'defensivos'` |
| `combustivel` | `'combustivel'` |
| `manutencao` | `'manutencao'` |
| `energia` | `'energia'` |
| `outros` | `'outrosAgro'` |
| `alimentacao` | `'alimentacao'` |
| `transporte` | `'transporte'` |
| `saude` | `'saude'` |
| `educacao` | `'educacao'` |
| `lazer` | `'lazer'` |
| `moradia` | `'moradia'` |
| `outrosPessoal` | `'outrosPessoal'` |

### Service: CategoriaMigrationService

```dart
class CategoriaMigrationService {
  static const _migrationKey = 'categoria_migration_v1';

  /// Verifica se migração já foi feita.
  Future<bool> isMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Migra lançamentos de enum para model.
  Future<MigrationResult> migrate() async {
    if (await isMigrated()) {
      return MigrationResult.alreadyDone();
    }

    // Garante que categorias core existem
    await CategoriaService().ensureDefaultCategorias();

    int migrated = 0;
    int failed = 0;

    // Busca todos os lançamentos
    final lancamentos = LancamentoService().getAll();

    for (final lancamento in lancamentos) {
      // Se já tem categoriaId, pula
      if (lancamento.categoriaId != null) continue;

      // Pega enum antigo (campo será @deprecated)
      final enumValue = lancamento.categoriaLegacy; // CashCategoria?

      if (enumValue == null) {
        failed++;
        continue;
      }

      // Mapeia para coreKey
      final coreKey = _enumToCoreKey[enumValue];
      if (coreKey == null) {
        failed++;
        continue;
      }

      // Busca categoria model
      final categoria = CategoriaService().getByCoreKey(coreKey);
      if (categoria == null) {
        failed++;
        continue;
      }

      // Atualiza lançamento
      await LancamentoService().update(
        lancamento.copyWith(categoriaId: categoria.id),
      );
      migrated++;
    }

    // Marca como concluído
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);

    return MigrationResult(migrated: migrated, failed: failed);
  }

  static const _enumToCoreKey = {
    CashCategoria.maoDeObra: 'maoDeObra',
    CashCategoria.adubo: 'adubo',
    CashCategoria.defensivos: 'defensivos',
    CashCategoria.combustivel: 'combustivel',
    CashCategoria.manutencao: 'manutencao',
    CashCategoria.energia: 'energia',
    CashCategoria.outros: 'outrosAgro',
    CashCategoria.alimentacao: 'alimentacao',
    CashCategoria.transporte: 'transporte',
    CashCategoria.saude: 'saude',
    CashCategoria.educacao: 'educacao',
    CashCategoria.lazer: 'lazer',
    CashCategoria.moradia: 'moradia',
    CashCategoria.outrosPessoal: 'outrosPessoal',
  };
}
```

### Alterações no Lancamento

```dart
@HiveType(typeId: 71)
class Lancamento implements FarmOwnedEntity, SyncableEntity {
  // NOVO: campo principal
  @HiveField(14) final String? categoriaId;

  // DEPRECATED: manter para migração, remover em versão futura
  @Deprecated('Use categoriaId. Será removido na v2.0')
  @HiveField(1) final CashCategoria? categoriaLegacy;

  // Getter de conveniência
  Categoria? get categoria => categoriaId != null
    ? CategoriaService().getById(categoriaId!)
    : null;

  // ...
}
```

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-21.1 | Adicionar campo `categoriaId` ao Lancamento (HiveField 14) | ⏳ TODO |
| CASH-21.2 | Deprecar campo `categoria` (renomear para `categoriaLegacy`) | ⏳ TODO |
| CASH-21.3 | Criar `CategoriaMigrationService` com lógica de migração | ⏳ TODO |
| CASH-21.4 | Chamar migração no startup (main.dart) | ⏳ TODO |
| CASH-21.5 | Atualizar LancamentoService para usar categoriaId | ⏳ TODO |
| CASH-21.6 | Atualizar queries (totalPorCategoria, etc.) para usar categoriaId | ⏳ TODO |
| CASH-21.7 | Atualizar CalculatorScreen para usar CategoriaService | ⏳ TODO |
| CASH-21.8 | Atualizar DreScreen para usar CategoriaService | ⏳ TODO |
| CASH-21.9 | Regenerar Hive adapters (build_runner) | ⏳ TODO |
| CASH-21.10 | Testar migração com dados existentes | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/lancamento.dart` | MODIFY | Adicionar categoriaId, deprecar categoria |
| `lib/models/lancamento.g.dart` | REGENERATE | build_runner |
| `lib/services/categoria_migration_service.dart` | CREATE | Lógica de migração |
| `lib/services/lancamento_service.dart` | MODIFY | Usar categoriaId em queries |
| `lib/screens/calculator_screen.dart` | MODIFY | Usar CategoriaService |
| `lib/screens/dre_screen.dart` | MODIFY | Usar CategoriaService |
| `lib/screens/home_screen.dart` | MODIFY | Exibir categoria via model |
| `lib/main.dart` | MODIFY | Chamar migração no startup |

### Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| Perda de dados se migração falhar | Backup automático antes da migração |
| Campo antigo fica indefinidamente | Remover em v2.0 após 3 meses |
| Performance da migração | Migração é O(n), roda uma vez |

### Cross-Reference

- CORE-96: Categoria model e CategoriaService (dependência)
- CASH-01: Lancamento original (modificado)
- CASH-04: DRE (atualizar queries)

---

## Phase CASH-20: RuraCash Premium — Visão Arquitetural

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Documentar a visão completa do RuraCash Premium. Esta fase é um overview arquitetural das funcionalidades avançadas que serão implementadas nas fases CASH-21 a CASH-30.

### Motivação

O RuraCash Free oferece controle básico de despesas. O Premium adiciona funcionalidades de um sistema financeiro completo, mantendo a simplicidade de uso. Diferencial vs GNUCash: double-entry escondido, UX de app de banco moderno.

### Funcionalidades Premium

| Fase | Funcionalidade | Descrição |
|------|----------------|-----------|
| CASH-21 | Migração Categoria | Base técnica para categorias custom |
| CASH-22 | Categorias Custom | Criar/editar categorias além das 14 core |
| CASH-23 | Contas Bancárias | Carteira, conta corrente, poupança, cartão, investimento |
| CASH-24 | Receitas | Registro de entradas (vendas, rendimentos) |
| CASH-25 | Transferências | Mover dinheiro entre contas |
| CASH-26 | Contas a Pagar/Receber | Gestão de vencimentos com alertas |
| CASH-27 | Orçamento | Planejamento mensal por categoria |
| CASH-28 | Relatórios Avançados | Balanço Patrimonial, Fluxo de Caixa |
| CASH-29 | Reconciliação | Comparar com extrato bancário |
| CASH-30 | Paywall | Monetização via RevenueCat |

### Hive TypeIds Reservados (CASH-20 a CASH-30)

| TypeId | Model | Fase |
|--------|-------|------|
| 70 | CashCategoria (enum) | CASH-01 (existente, será deprecated) |
| 71 | Lancamento | CASH-01 (existente, será modificado) |
| 72 | CentroCusto | CASH-02 (existente) |
| 73 | Conta | CASH-23 |
| 74 | Receita | CASH-24 |
| 75 | TipoConta (enum) | CASH-23 |
| 76-77 | Reservado | - |
| 78 | Categoria | CORE-96 |
| 79 | Transferencia | CASH-25 |
| 80 | ContaPagar | CASH-26 |
| 81 | ContaReceber | CASH-26 |
| 82 | Orcamento | CASH-27 |
| 83 | TipoPeriodoOrcamento (enum) | CASH-27 |

### Arquitetura de Dados

```
┌─────────────────────────────────────────────────────────────────┐
│                        RuraCash Premium                         │
├─────────────────────────────────────────────────────────────────┤
│  CATEGORIAS (CORE-96)                                          │
│  ├── Core (14): coreKey imutável, nome editável, não deletável │
│  └── Custom: criadas pelo usuário, editáveis, arquiváveis      │
├─────────────────────────────────────────────────────────────────┤
│  CONTAS (CASH-23)                                              │
│  ├── Ativos: carteira, conta corrente, poupança, investimento  │
│  └── Passivos: cartão crédito, empréstimo                      │
├─────────────────────────────────────────────────────────────────┤
│  MOVIMENTAÇÕES                                                  │
│  ├── Lancamento (CASH-01): despesa com categoriaId + contaId   │
│  ├── Receita (CASH-24): entrada com categoriaId + contaId      │
│  └── Transferencia (CASH-25): entre contas, não afeta DRE     │
├─────────────────────────────────────────────────────────────────┤
│  COMPROMISSOS (CASH-26)                                        │
│  ├── ContaPagar: fornecedores, parcelas, vencimentos           │
│  └── ContaReceber: clientes, vendas a prazo                    │
├─────────────────────────────────────────────────────────────────┤
│  PLANEJAMENTO (CASH-27)                                        │
│  └── Orcamento: limite mensal por categoria, alertas           │
├─────────────────────────────────────────────────────────────────┤
│  RELATÓRIOS                                                     │
│  ├── DRE (CASH-04): Receitas - Despesas = Resultado            │
│  ├── Balanço (CASH-28): Ativos - Passivos = Patrimônio         │
│  └── Fluxo de Caixa (CASH-28): Entradas - Saídas = Saldo       │
├─────────────────────────────────────────────────────────────────┤
│  RECONCILIAÇÃO (CASH-29)                                       │
│  └── Matching local-first com extrato bancário                 │
├─────────────────────────────────────────────────────────────────┤
│  SYNC (CORE-95)                                                │
│  ├── Tier 1: Local only (Hive)                                 │
│  ├── Tier 2: Anonymous aggregate (Firestore)                   │
│  └── Tier 3: Full sync multi-user (Firestore)                  │
└─────────────────────────────────────────────────────────────────┘
```

### Princípios de Design

1. **Double-entry escondido**: Sistema faz débito/crédito por baixo, usuário só vê "gastei R$ 500 em Combustível, saiu da Nubank"
2. **Offline-first**: Tudo funciona sem internet, sync quando disponível
3. **Migração transparente**: Free → Premium sem perder dados
4. **Cross-app**: Categorias core funcionam com RuraFuel, RuraRubber, RuraCattle
5. **Multi-user**: Compartilhar fazenda com funcionário/sócio (Tier 3)
6. **Custos otimizados**: Reconciliação local-first, agregações no Hive
7. **Vocabulário híbrido**: Termos técnicos + explicações amigáveis ("ATIVOS · o que você tem")

### Filosofia: Double-Entry Escondido (Detalhado)

O RuraCash implementa contabilidade de partidas dobradas **sem que o usuário saiba**. O sistema traduz ações do mundo real para lançamentos contábeis corretos.

#### Comparação de Abordagens

| Aspecto | GNUCash | RuraCash Premium |
|---------|---------|------------------|
| Linguagem | "Débito em Despesas:Adubo, Crédito em Passivo:Fornecedores" | "Comprei adubo a prazo do João" |
| Quem faz as partidas | Usuário | Sistema |
| Curva de aprendizado | Alta (precisa saber contabilidade) | Baixa (só descreve o que aconteceu) |
| Precisão contábil | ✅ | ✅ (igual, mas escondida) |

#### Fluxo: Compra À Vista vs A Prazo

**UX Unificada na Tela de Lançamento:**

```
┌──────────────────────────────────────────────────────────────┐
│  Lançar Despesa                                             │
│                                                              │
│              R$ 1.000,00                                    │
│                                                              │
│  Categoria: [Adubo ▼]                                       │
│                                                              │
│  Pagamento:                                                  │
│  ◉ À vista    → Saiu de: [Sicredi Agro ▼]                  │
│  ○ A prazo    → Fornecedor: [__________] Vence: [__/__]    │
│                                                              │
│  [Salvar]                                                    │
└──────────────────────────────────────────────────────────────┘
```

**Cenário 1: Compra À Vista**

```
Usuário: "Comprei adubo R$ 1.000, paguei na hora com Sicredi"

Sistema faz (invisível):
┌─────────────────────────────────────────────────────────────┐
│  Débito:  Despesa/Adubo           +R$ 1.000  (reconhece)   │
│  Crédito: Ativo/Sicredi           -R$ 1.000  (sai dinheiro)│
└─────────────────────────────────────────────────────────────┘

Resultado:
- Cria Lancamento com categoriaId=adubo, contaId=sicredi
- Saldo Sicredi diminui R$ 1.000
- DRE: Despesa de R$ 1.000 em Janeiro (mês da compra)
- Fluxo de Caixa: Saída de R$ 1.000 em Janeiro
```

**Cenário 2: Compra A Prazo**

```
Usuário: "Comprei adubo R$ 1.000 do João, vence dia 15/02"

Sistema faz (invisível):
┌─────────────────────────────────────────────────────────────┐
│  Débito:  Despesa/Adubo           +R$ 1.000  (reconhece)   │
│  Crédito: Passivo/Fornecedores    +R$ 1.000  (dívida)      │
└─────────────────────────────────────────────────────────────┘

Resultado:
- Cria Lancamento com categoriaId=adubo, contaId=NULL (não saiu de conta)
- Cria ContaPagar vinculado ao Lancamento (lancamentoOrigemId)
- DRE: Despesa de R$ 1.000 em Janeiro (mês da COMPRA, não do pagamento)
- Fluxo de Caixa: Nenhuma saída ainda
- Balanço: Passivo aumenta R$ 1.000
```

**Cenário 3: Pagamento da Conta A Prazo**

```
Usuário: "Paguei o João, saiu da Sicredi"

Sistema faz (invisível):
┌─────────────────────────────────────────────────────────────┐
│  Débito:  Passivo/Fornecedores    -R$ 1.000  (quita dívida)│
│  Crédito: Ativo/Sicredi           -R$ 1.000  (sai dinheiro)│
└─────────────────────────────────────────────────────────────┘

Resultado:
- Atualiza ContaPagar: status=pago, contaPagamentoId=sicredi
- NÃO cria novo Lancamento (despesa já foi reconhecida na compra!)
- Saldo Sicredi diminui R$ 1.000
- DRE: Nenhuma alteração (despesa já estava em Janeiro)
- Fluxo de Caixa: Saída de R$ 1.000 em Fevereiro (mês do PAGAMENTO)
- Balanço: Passivo diminui R$ 1.000
```

#### Regime de Competência vs Caixa

| Relatório | Regime | Quando reconhece |
|-----------|--------|------------------|
| **DRE** | Competência | Data da COMPRA (fato gerador) |
| **Fluxo de Caixa** | Caixa | Data do PAGAMENTO (saída efetiva) |

**Isso é contabilidade correta.** O produtor não precisa saber — o sistema garante.

### Ordem de Implementação

```
CORE-96 (Categoria model)
    ↓
CASH-21 (Migração)
    ↓
CASH-22 (UI Categorias) ──────────────────────────┐
    ↓                                              │
CASH-23 (Contas) ←─────────────────────────────────┤
    ↓                                              │
CASH-24 (Receitas)                                 │
    ↓                                              │
CASH-25 (Transferências)                           │
    ↓                                              │
CASH-26 (A Pagar/Receber)                          │
    ↓                                              │
CASH-27 (Orçamento)                                │
    ↓                                              │
CASH-28 (Relatórios Avançados)                     │
    ↓                                              │
CASH-29 (Reconciliação)                            │
    ↓                                              │
CASH-30 (Paywall) ─────────────────────────────────┘
```

### Cross-Reference

- CORE-96: Categoria model (infraestrutura compartilhada)
- CASH-01 a CASH-12: Fases existentes (base do app)
- GNUCash: Inspiração para funcionalidades, não para UX

---

## Phase CASH-12: Android Build Configuration — Flavors, Firebase, Desugaring

### Status: [DOING]
**Priority**: 🔴 CRITICAL
**Objective**: Configurar o projeto Android do RuraCash com paridade ao RuraRain/RuraRubber. O `flutter create` deixou tudo no padrão sem Firebase, sem flavors, sem desugaring.

### Gaps Found

| Item | Atual (RuraCash) | Correto (RuraRain/Rubber) |
|------|-------------------|---------------------------|
| `settings.gradle` AGP | 8.1.0 | 8.6.0 |
| `settings.gradle` Kotlin | 1.8.22 | 2.0.0+ |
| `settings.gradle` google-services | AUSENTE | 4.3.15 |
| `settings.gradle` flutter-plugin-loader | 1.0.0 | 1.0.0 (rubber) / 3.16.0 (rain) |
| `build.gradle` google-services plugin | AUSENTE | `com.google.gms.google-services` |
| `build.gradle` flavors | AUSENTE | dev/prod |
| `build.gradle` desugaring | AUSENTE | `coreLibraryDesugaringEnabled true` |
| `build.gradle` minSdk | flutter default | 23 |
| `build.gradle` Firebase dependencies | AUSENTE | firebase-bom + analytics |
| `AndroidManifest.xml` label | Hardcoded "ruracash" | `@string/app_name` |
| `google-services.json` | AUSENTE | dev/ + prod/ |
| `firebase_options.dart` | PLACEHOLDER values | Real Firebase credentials |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-12.1 | Atualizar `settings.gradle`: AGP 8.6.0, Kotlin 2.0.0, add google-services plugin | ✅ DONE |
| CASH-12.2 | Atualizar `build.gradle`: add google-services plugin, flavors dev/prod, desugaring, minSdk 23 | ✅ DONE |
| CASH-12.3 | Fix `AndroidManifest.xml`: usar `@string/app_name` em vez de hardcoded | ✅ DONE |
| CASH-12.4 | Criar `google-services.json` para dev/prod via Firebase CLI | 🚫 BLOCKED (requer criação de projeto Firebase) |
| CASH-12.5 | Atualizar `firebase_options.dart` com credenciais reais | 🚫 BLOCKED (requer criação de projeto Firebase) |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/settings.gradle` | MODIFY | AGP, Kotlin, google-services versions |
| `android/app/build.gradle` | MODIFY | Flavors, desugaring, minSdk, Firebase deps |
| `android/app/src/main/AndroidManifest.xml` | MODIFY | Fix app label |
| `android/app/src/dev/google-services.json` | CREATE | Firebase config (dev) |
| `android/app/src/prod/google-services.json` | CREATE | Firebase config (prod) |
| `lib/firebase_options.dart` | MODIFY | Real Firebase credentials |

---

## Phase CASH-11: Unified Sync Pipeline Verification

### Status: [DONE]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Verificar que todos os serviços do RuraCash usam exclusivamente GenericSyncService. Ambos services (Lancamento, CentroCusto) já estendem GenericSyncService com syncEnabled=false (Firebase placeholder). Nenhum tem Tier 2 customizado.

### Prerequisites
- CORE-95: Unified Sync Pipeline deve estar DOING ✅

### Scope
- Verificar que nenhum service usa subcollections
- Verificar que nenhum service tem lógica de sync customizada fora do GenericSyncService
- Quando Firebase for configurado (CASH-12.4/12.5), re-habilitar syncEnabled=true

### Cross-Reference
- RAIN-10 [TODO]: Unified Sync Pipeline (rurarain)
- RUBBER-30 [TODO]: Unified Sync Pipeline (rurarubber)
- CORE-95 [DOING]: Unified Sync Pipeline (agro_core)

---

## Phase CASH-10: Gap Fixes — L10n, isOwner, syncEnabled, typeId

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Corrigir gaps encontrados nas fases CASH-08 e CASH-09: strings hardcoded na home_screen, isOwner hardcoded, syncEnabled=true com Firebase placeholder, e keys l10n faltantes.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-10.1 | Fix 6 strings hardcoded em home_screen.dart (contexto switcher, farm names, error messages) → usar l10n | ✅ DONE |
| CASH-10.2 | Adicionar `contextSwitcherTooltip` e `contextSwitchError` aos ARBs pt/en + gen-l10n | ✅ DONE |
| CASH-10.3 | Fix ConfiguracoesScreen: isOwner hardcoded `true` → computar via FarmService/AuthService | ✅ DONE |
| CASH-10.4 | Fix syncEnabled=true → false em LancamentoService e CentroCustoService (Firebase tem PLACEHOLDER credentials, crashava) | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/home_screen.dart` | MODIFY | 6 hardcoded strings → l10n (contextSwitcherTooltip, farmTypeAgro/Personal, farmDefaultName, contextSwitchError) |
| `lib/screens/configuracoes_screen.dart` | MODIFY | isOwner computado via FarmService.getDefaultFarm().isOwner(uid) |
| `lib/services/lancamento_service.dart` | MODIFY | syncEnabled: true → false (CASH-08 placeholder Firebase) |
| `lib/services/centro_custo_service.dart` | MODIFY | syncEnabled: true → false (CASH-08 placeholder Firebase) |
| `lib/l10n/arb/app_pt.arb` | MODIFY | Add contextSwitcherTooltip, contextSwitchError |
| `lib/l10n/arb/app_en.arb` | MODIFY | Add contextSwitcherTooltip, contextSwitchError |

### Cross-Reference
- CORE-93: farmTypeAgro/farmTypePersonal l10n keys + typeId fix
- CASH-08: Firebase integration (syncEnabled guard)
- CASH-09: Context switcher (l10n keys)

---

## Phase CASH-09: Personal Finance Mode [DONE]

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Permitir alternância entre contexto Rural e Pessoal para sanear o DRE da fazenda. Usar o modelo Farm-Centric para criar uma "Fazenda Pessoal" com categorias domésticas, isolando gastos pessoais (supermercado, farmácia, lazer) dos custos operacionais da fazenda (adubo, mão de obra, combustível).
**Prerequisite**: CORE-91 (FarmType enum no Farm model)

### Why LOCKED

- Requer CORE-91 (FarmType) implementado primeiro
- Requer strings l10n para todas as categorias novas (pt-BR + en)

### UX Decision: Onboarding Profile Selection

Na **primeira entrada** do app, exibir uma tela com dois botões grandes:

```
┌──────────────────────────────────────────┐
│       Bem-vindo ao RuraCash!             │
│                                          │
│  Como você quer começar?                 │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🚜  Produtor Rural               │  │
│  │  Controle custos da fazenda       │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🏠  Finanças Pessoais            │  │
│  │  Controle gastos domésticos       │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Você pode mudar depois na barra de cima │
└──────────────────────────────────────────┘
```

Comportamento:
- **Produtor Rural**: Cria farm `FarmType.agro` com nome l10n `farmDefaultName`, ativa categorias agro
- **Finanças Pessoais**: Cria farm `FarmType.personal` com nome l10n `farmDefaultNamePersonal`, ativa categorias pessoais
- A segunda farm (a que não foi escolhida) pode ser criada depois pelo context switcher no AppBar
- O context switcher fica no AppBar da tela principal, permitindo alternar entre farms ou criar a segunda

### Licensing Rule

A farm pessoal é **FREE** — o usuário pode ter 2 farms sem assinatura/compra:
- 1 farm `FarmType.agro` (criada no onboarding normal)
- 1 farm `FarmType.personal` (criada automaticamente pelo CASH-09)

Não é necessário licença, assinatura ou compra para habilitar o modo pessoal. O `subscriptionTier` do modelo Farm controla apenas farms **agro** adicionais (futuro multi-fazenda). A farm pessoal é uma feature do app, não um recurso premium.

O `FarmService` deve permitir esta exceção:
- `getFarmLimit(tier)` retorna o limite de farms **agro** (free=1, basic=3, premium=ilimitado)
- Farms `FarmType.personal` **NÃO** contam para o limite
- Regra: `countFarms(FarmType.agro) <= farmLimit` + `countFarms(FarmType.personal) <= 1`

### Problem Statement

A maioria dos produtores rurais mistura gastos da fazenda com gastos pessoais no mesmo controle financeiro. Isso resulta em:
- **DRE poluído**: O relatório da fazenda inclui conta de luz de casa, feira, farmácia
- **Falsa sensação de prejuízo**: A fazenda pode dar lucro, mas aparenta dar prejuízo porque os gastos pessoais estão somados
- **Nenhuma visibilidade doméstica**: O produtor não sabe quanto gasta com a família por mês
- **O app "perde utilidade" fora de safra**: Se só registra custos rurais, fica sem uso nos meses de entre-safra

### Solution: "Farm as Context"

Tratar a "Vida Pessoal" como se fosse uma Farm:
- `Farm A`: "Seringal Santa Fé" (`type: FarmType.agro`) — categorias rurais
- `Farm B`: "Minhas Finanças" (`type: FarmType.personal`) — categorias domésticas

Ao trocar o contexto, o `farmId` muda. Todos os filtros, DRE, queries e backups funcionam automaticamente.

### Architecture Overview

```
Usuário abre RuraCash:
  ┌──────────────────────────────────────────┐
  │ Header: [ 🚜 Seringal Sta Fé  ▼ ]       │  ← Context Switcher
  │                                          │
  │  Total do Mês: R$ 3.200,00              │
  │  ├─ Mão de Obra: R$ 1.500               │
  │  ├─ Combustível: R$ 800                  │
  │  └─ Adubo: R$ 900                        │
  └──────────────────────────────────────────┘

Ao trocar para "Pessoal":
  ┌──────────────────────────────────────────┐
  │ Header: [ 🏠 Minhas Finanças  ▼ ]       │  ← Context Switcher
  │                                          │
  │  Total do Mês: R$ 2.100,00              │
  │  ├─ Mercado: R$ 800                      │
  │  ├─ Farmácia: R$ 300                     │
  │  ├─ Educação: R$ 500                     │
  │  └─ Casa: R$ 500                         │
  └──────────────────────────────────────────┘

Dados NUNCA se misturam — farmId diferente.
DRE da fazenda mostra apenas custos operacionais.
DRE pessoal mostra apenas gastos domésticos.
```

### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-09.1 | **CashCategoria with personal categories**: Categorias pessoais integradas no enum CashCategoria (alimentacao, transporte, saude, educacao, lazer, moradia, outrosPessoal — HiveFields 7-13) com getters `isAgro`/`isPersonal`, icons, colors, localizedName | ✅ DONE |
| CASH-09.2 | **Lancamento model**: Usa campo único `categoria` (CashCategoria) que cobre agro e pessoal via `isAgro`/`isPersonal` getters. Decisão de design: enum unificado em vez de campo separado | ✅ DONE |
| CASH-09.3 | **Auto-create personal farm**: Criação sob demanda via `_switchContext()` no HomeScreen. Ao trocar para Personal, se não existe, cria via `FarmService.createPersonalFarm()` | ✅ DONE |
| CASH-09.4 | **Context Switcher Widget**: PopupMenuButton no AppBar do HomeScreen com ícones (agriculture/person) e labels l10n (farmTypeAgro/farmTypePersonal) | ✅ DONE |
| CASH-09.5 | **Category Context**: CalculatorScreen filtra categorias por `isPersonal`/`isAgro` baseado no tipo da farm ativa. Default inteligente: pré-seleciona categoria mais usada do contexto | ✅ DONE |
| CASH-09.6 | **DRE Filtering**: DreScreen filtra por farmId via LancamentoService. Título context-aware: `dreTitlePersonal` vs `dreTitle` | ✅ DONE |
| CASH-09.7 | **HomeScreen Context**: Título, ícone e gradiente mudam conforme contexto (verde/agriculture para agro, azul/person para personal) | ✅ DONE |
| CASH-09.8 | **L10n strings**: Strings para categorias pessoais (catAlimentacao, catTransporte, etc.) + context switcher (contextSwitcherTooltip, contextSwitchError) + dreTitlePersonal adicionadas | ✅ DONE |
| CASH-09.9 | **Cross-app guard**: RuraRubber/RuraRain usam GenericSyncService com farms; farm pessoal não aparece nesses contextos pois é tipo `FarmType.personal` | ✅ DONE |

### Categorias Pessoais (Planned)

| Enum Value | Icon | Color | pt-BR | en |
|------------|------|-------|-------|-----|
| `mercado` | shopping_cart | green | Mercado | Groceries |
| `farmacia` | medical_services | red | Farmácia | Pharmacy |
| `lazer` | sports_esports | purple | Lazer | Leisure |
| `casa` | home | brown | Casa | Home |
| `educacao` | school | blue | Educação | Education |
| `saude` | health_and_safety | pink | Saúde | Health |
| `transporte` | directions_car | orange | Transporte | Transport |
| `vestuario` | checkroom | teal | Vestuário | Clothing |
| `outros` | category | grey | Outros | Other |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/cash_categoria_personal.dart` | CREATE | Enum com 9 categorias pessoais, HiveType typeId 73 |
| `lib/models/lancamento.dart` | MODIFY | Adicionar HiveField para categoriaPersonal (nullable) |
| `lib/models/lancamento.g.dart` | REGENERATE | build_runner com novo campo |
| `lib/screens/cash_home_screen.dart` | MODIFY | Adicionar context switcher, filtrar por farm ativa |
| `lib/screens/calculator_screen.dart` | MODIFY | Mostrar categorias conforme contexto (agro vs personal) |
| `lib/screens/dre_screen.dart` | MODIFY | Título contextual, validar filtro por farmId |
| `lib/widgets/context_switcher.dart` | CREATE | Dropdown widget de seleção de contexto |
| `lib/l10n/arb/app_pt.arb` | MODIFY | ~20 novas chaves para categorias pessoais |
| `lib/l10n/arb/app_en.arb` | MODIFY | ~20 novas chaves para categorias pessoais |
| `lib/main.dart` | MODIFY | Auto-create farm pessoal, registrar novo adapter |

### Strategic Value

- **Diferencial competitivo**: Nenhum app agro separa finanças rural/pessoal de forma simples
- **Retenção o ano todo**: Fora de safra, o produtor continua usando para gastos domésticos
- **Educação financeira**: O produtor finalmente vê que a fazenda dá lucro — o problema é o gasto pessoal
- **Base para DRE consolidado** (futuro): "Resultado Geral = Receita Fazenda - Custos Fazenda - Gastos Pessoais"

### Cross-Reference
- CORE-91: FarmType enum (prerequisite)
- CORE-75: Farm-Centric Model (base)
- CASH-01: MVP Lançamento de Despesas (base de categorias e models)
- CASH-04: DRE (consumidor de dados filtrados por farm)

---

## Phase CASH-08: Firebase & Auth Integration [IN PROGRESS]

### Status: [IN PROGRESS]
**Start Date**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Integrar Firebase, autenticação Google, CloudBackupService, DataDeletionService, e fluxo de login completo ao RuraCash. Alinhar com RuraRubber/RuraRain que já possuem esses recursos.
**Prerequisite**: CASH-07 (corrigir erros e alinhar base)



### Implementation Summary (Planned)

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-08.1 | Configurar acesso ao projeto Firebase existente (RuraCamp/RuraCamp-Dev). Registrar app `com.planejacampo.ruracash` nestes projetos e obter `google-services.json` | ⏳ BLOCKED — Aguardando google-services.json do projeto RuraCamp |
| CASH-08.2 | Inicializar Firebase no main.dart (pattern nativo Android/iOS + DefaultFirebaseOptions desktop) | ✅ DONE |
| CASH-08.3 | Adicionar App Check com guard `if (!kDebugMode)` | ✅ DONE |
| CASH-08.4 | Registrar Hive adapters: DeviceInfoAdapter, ConsentDataAdapter, UserCloudDataAdapter + sync adapters | ✅ DONE |
| CASH-08.5 | Inicializar UserCloudService, DataMigrationService no main.dart | ✅ DONE |
| CASH-08.6 | Criar AuthGate com LoginScreen e fluxo de login Google/Anônimo | ✅ DONE |
| CASH-08.7 | Criar CashBackupProvider (implements BackupProvider) para Lancamento + CentroCusto | ✅ DONE |
| CASH-08.8 | Criar CashDeletionProvider (implements AppDeletionProvider) para LGPD | ✅ DONE |
| CASH-08.9 | Registrar backup/deletion providers no main.dart | ✅ DONE |
| CASH-08.10 | Criar ConfiguracoesScreen app-specific com isOwner, locale, theme, backup callbacks | ✅ DONE |
| CASH-08.11 | Re-habilitar `syncEnabled => true` nos services (após Firebase estar ativo) | ⏳ BLOCKED — aguarda Firebase real (CASH-08.1) |
| CASH-08.12 | Adicionar Property Name Gate no fluxo de navegação | ✅ DONE |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/firebase_options.dart` | CREATE | Gerado pelo FlutterFire CLI |
| `lib/main.dart` | MODIFY | Firebase init, App Check, adapters, services, AuthGate |
| `lib/screens/configuracoes_screen.dart` | CREATE | Settings wrapper com isOwner, locale, theme |
| `lib/services/cash_backup_provider.dart` | CREATE | EnhancedBackupProvider para backup/restore |
| `lib/services/cash_deletion_provider.dart` | CREATE | AppDeletionProvider para LGPD |
| `android/app/src/main/google-services.json` | CREATE | Firebase config Android |

### Cross-Reference
- CORE-84: Firebase init pattern, App Check, Sync adapters
- CORE-86/87: Owner-based settings, auto-backup
- RUBBER-26/27: Referência de implementação completa
- RAIN-06/07: Referência de implementação completa

---

## Phase CASH-07: Architecture Alignment & Error Fixes

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Corrigir 17 erros de compilação (CashLocalizations), prevenir crash de runtime (syncEnabled sem Firebase), e alinhar code quality com padrões do monorepo.

### Root Cause Analysis

1. **CashLocalizations não gerado** (17 erros): `l10n.yaml` existe, ARB files existem, `flutter: generate: true` está no pubspec — mas `flutter gen-l10n` nunca foi executado. Resultado: todas as telas que importam `package:flutter_gen/gen_l10n/app_localizations.dart` falham.

2. **syncEnabled => true sem Firebase** (crash em runtime): Ambos services (LancamentoService, CentroCustoService) declaram `syncEnabled => true`, mas o app NÃO inicializa Firebase. Quando `getById()` é chamado, `scheduleSyncInBackground()` → `syncWithServer()` → `FirebaseFirestore.instance` → crash. Solução: `syncEnabled => false` até Firebase ser configurado (CASH-08).

3. **Dead code**: `CentroCustoService.defaultCentroCusto` tem `return list.first;` seguido de `return list.firstWhere(...)` — segunda linha é inalcançável.

4. **Imports não utilizados**: `uuid` importado em ambos services mas não usado diretamente (GenericSyncService cuida de IDs).

5. **Missing @override**: `clearAll()` em ambos services sobrescreve método do GenericSyncService sem anotação.

6. **Imports desnecessários**: `generic_sync_service.dart` importado diretamente quando já está no barrel `agro_core.dart`.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| CASH-07.1 | Gerar CashLocalizations via `flutter gen-l10n` no diretório ruracash | ✅ DONE |
| CASH-07.2 | Alterar `syncEnabled => false` em LancamentoService e CentroCustoService | ✅ DONE |
| CASH-07.3 | Corrigir dead code em `CentroCustoService.defaultCentroCusto` — remover `return list.first;` inalcançável | ✅ DONE |
| CASH-07.4 | Remover imports `package:uuid/uuid.dart` não utilizados em ambos services | ✅ DONE |
| CASH-07.5 | Adicionar `@override` em `clearAll()` de ambos services, remover imports desnecessários de `generic_sync_service.dart` | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/lancamento_service.dart` | MODIFY | syncEnabled=false, remover uuid import, remover generic_sync_service import, @override clearAll |
| `lib/services/centro_custo_service.dart` | MODIFY | syncEnabled=false, remover uuid import, remover generic_sync_service import, @override clearAll, fix dead code |
| `.dart_tool/flutter_gen/` | GENERATE | CashLocalizations gerado por flutter gen-l10n |

### Notes

- `syncEnabled => false` é temporário — será re-habilitado em CASH-08 quando Firebase estiver configurado
- CashLocalizations é app-level l10n (strings específicas do RuraCash), separado do AgroLocalizations do core
- isOwner não precisa ser wired agora — sem Auth, o default `true` é correto para uso single-user offline

### Cross-Reference
- CORE-83: Migração para GenericSyncService (origem do syncEnabled=true prematuro)
- CORE-88: Data Tier Architecture (GenericSyncService Tier 3 gate via farm.isShared)

---

## Phase CASH-06: Fix Sync Adapter Registration

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔵 FIX
**Objective**: Registrar adapters Hive da infraestrutura de sync (OfflineOperation, OperationType, OperationPriority) no main.dart para evitar `HiveError: Cannot write, unknown type: OfflineOperation` quando GenericSyncService tenta enfileirar operações offline.
**Cross-Reference**: CORE-84

### Root Cause
Os services LancamentoService e CentroCustoService usam `GenericSyncService` com `syncEnabled => true`, que enfileira operações no `OfflineQueueManager`. O OfflineQueueManager persiste objetos `OfflineOperation` no Hive, mas os adapters nunca foram registrados no `main.dart` do RuraCash.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1 | Registrar OfflineOperationAdapter, OperationTypeAdapter, OperationPriorityAdapter no main.dart | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | MODIFY | Adicionar 3 registros de adapter após adapters existentes |

---

## Phase CASH-05: Migração para GenericSyncService

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Migrar todos os services para `GenericSyncService` do agro_core, habilitando sync Firestore.
**Cross-Reference**: CORE-83

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | **CentroCustoService**: Migração para `GenericSyncService<CentroCusto>` com auto-create "Geral" | ✅ DONE |
| 5.2 | **LancamentoService**: Migração para `GenericSyncService<Lancamento>` com queries complexas | ✅ DONE |
| 5.3 | **Data Migration**: Lógica de migração de dados antigos (Adapter → Map) em ambos services | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/centro_custo_service.dart` | REFACTOR | Estende GenericSyncService, remove CRUD manual, mantém auto-create "Geral" |
| `lib/services/lancamento_service.dart` | REFACTOR | Estende GenericSyncService, remove CRUD manual, mantém queries de agregação |

---

## Phase CASH-04: Relatório Financeiro (DRE)

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟢 ENHANCEMENT
**Objective**: Demonstrativo de Resultados com filtros de período e exportação PDF.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **DreScreen**: Tela com filtros Mês/Trimestre/Safra/Ano | ✅ DONE |
| 4.2 | **Agregações**: totalPorMes, totalPorCategoria, totalPorCentroCusto, totalMensalAno | ✅ DONE |
| 4.3 | **PDF Export**: Exportação de relatório via pdf + printing | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/dre_screen.dart` | CREATE | Tela DRE com 4 filtros de período, gráfico receitas vs despesas |
| `lib/services/lancamento_service.dart` | MODIFY | Métodos de agregação por período, categoria e centro de custo |

---

## Phase CASH-03: Integração Cross-App (Firestore Sync)

### Status: [BLOCKED]
**Priority**: 🔴 CRITICAL
**Objective**: Permitir que despesas do RuraCash apareçam no break-even do RuraRubber.
**Blocker**: Requer que ambos apps usem GenericSyncService com syncEnabled=true e Firestore como meio de troca. Infraestrutura pronta (CORE-78), falta implementar a leitura cross-app no RuraRubber.

### Cross-Reference
- CORE-78: GenericSyncService (infraestrutura pronta)
- RUBBER-20: Break-even (consumidor dos dados)

---

## Phase CASH-02: Centros de Custo

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir alocação de despesas por centro de custo (seringal, pasto, geral).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Modelo CentroCusto**: Hive typeId 72, FarmOwnedEntity, nome, ícone, cor, appVinculado | ✅ DONE |
| 2.2 | **CentroCustoService**: Singleton com CRUD, auto-create "Geral", defaultCentroCusto | ✅ DONE |
| 2.3 | **CentroCustoScreen**: Tela CRUD com lista, add, edit, delete | ✅ DONE |
| 2.4 | **Integração Lançamento**: Campo centroCustoId no modelo Lancamento | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/centro_custo.dart` | CREATE | Modelo Hive typeId 72, FarmOwnedEntity, create/toJson/fromJson |
| `lib/services/centro_custo_service.dart` | CREATE | Singleton com CRUD, auto-create "Geral" |
| `lib/screens/centro_custo_screen.dart` | CREATE | Tela CRUD para centros de custo |

---

## Phase CASH-01: MVP Lançamento de Despesas

### Status: [DONE]
**Date Completed**: 2026-01-26
**Priority**: 🔴 CRITICAL
**Objective**: Entrada rápida de despesas com categorização e visualização mensal.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | **Modelo Lancamento**: Hive typeId 71, FarmOwnedEntity, valor, categoria, data, descrição | ✅ DONE |
| 1.2 | **CashCategoria Enum**: Hive typeId 70, 7 categorias com ícone e cor | ✅ DONE |
| 1.3 | **LancamentoService**: Singleton com CRUD, queries por mês/categoria/período, totais | ✅ DONE |
| 1.4 | **CashHomeScreen**: Dashboard com card de total mensal e lista de lançamentos | ✅ DONE |
| 1.5 | **CalculatorScreen**: Entrada rápida estilo calculadora com smart defaults | ✅ DONE |
| 1.6 | **CashDrawer**: Navegação com drawer padronizado (Calculator, Centros, DRE) | ✅ DONE |
| 1.7 | **Main.dart Integration**: Adapters Hive, providers, rotas, l10n, AdMob | ✅ DONE |
| 1.8 | **L10n Strings**: 55 chaves em pt-BR e en | ✅ DONE |

### Hive TypeIds

| TypeId | Modelo |
|--------|--------|
| 70 | CashCategoria (enum) |
| 71 | Lancamento (class) |
| 72 | CentroCusto (class) |

### Files Created

| File | Action | Description |
|------|--------|-------------|
| `lib/models/cash_categoria.dart` | CREATE | Enum com 7 categorias, ícone, cor, localizedName |
| `lib/models/lancamento.dart` | CREATE | Modelo Hive typeId 71, FarmOwnedEntity, toJson/fromJson |
| `lib/models/centro_custo.dart` | CREATE | Modelo Hive typeId 72, FarmOwnedEntity |
| `lib/services/lancamento_service.dart` | CREATE | Service com CRUD + agregações por mês/categoria/centro |
| `lib/services/centro_custo_service.dart` | CREATE | Service com CRUD + auto-create "Geral" |
| `lib/screens/cash_home_screen.dart` | CREATE | Dashboard com total mensal e lista |
| `lib/screens/calculator_screen.dart` | CREATE | Entrada rápida de despesa |
| `lib/screens/centro_custo_screen.dart` | CREATE | CRUD de centros de custo |
| `lib/screens/dre_screen.dart` | CREATE | Relatório financeiro com filtros |
| `lib/widgets/cash_drawer.dart` | CREATE | Drawer padronizado com navegação |
| `lib/l10n/arb/app_pt.arb` | CREATE | 55 strings pt-BR |
| `lib/l10n/arb/app_en.arb` | CREATE | 55 strings en |
| `lib/main.dart` | CREATE | App entry point com rotas, providers, adapters |

### Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/home` | CashHomeScreen | Dashboard principal |
| `/calculator` | CalculatorScreen | Entrada de despesa |
| `/centros` | CentroCustoScreen | Gestão de centros de custo |
| `/dre` | DreScreen | Relatório financeiro |
| `/settings` | AgroSettingsScreen | Configurações (agro_core) |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `hive` | 2.2.3 | Armazenamento local |
| `hive_flutter` | 1.1.0 | Hive integration |
| `provider` | 6.1.2 | State management |
| `firebase_core` | 3.15.2 | Firebase init |
| `pdf` | 3.10.8 | PDF generation |
| `printing` | 5.11.1 | PDF export/print |
| `file_picker` | 8.1.6 | File import |
| `share_plus` | 10.1.4 | Sharing |
| `uuid` | 4.5.1 | ID generation |

### Cross-Reference
- CORE-78: GenericSyncService (base para services)
- CORE-75: Farm model (FarmOwnedEntity)
- CORE-77: Backup infrastructure
- RUBBER-20: Break-even consome dados de despesas (futuro CASH-03)
