# CHANGELOG - RuraCash (Planejamento)

> **Status**: App em planejamento. Não iniciado.
> **Objetivo**: Controle de Despesas centralizado para toda a fazenda, integrando com todos os apps RuraCamp.

---

## 📱 Visão do Produto

### Por que um app separado?

1. **Multiuso**: O trator gasta diesel arrumando cerca do gado (RuraCattle) E levando adubo na seringueira (RuraRubber). Se a despesa ficar presa em um app, o custo do outro fica errado.

2. **Simplicidade**: Quem lança despesa muitas vezes não é quem pesa borracha. Pode ser a esposa, o gerente administrativo, ou o produtor na cidade comprando peça.

3. **DRE Completo**: Um único lugar que mostra o resultado financeiro de toda a fazenda.

---

## Phase CASH-01: MVP - Lançamento Rápido

### Status: [TODO]
**Priority**: 🔴 CRITICAL
**Objective**: Permitir lançamento ultra-rápido de despesas com UX de calculadora.

### UX Design Principles (3-Click Rule)
- **Calculator-Style Interface**: Similar ao app de calculadora do celular
- **Valor Primeiro**: Digita o valor, depois escolhe categoria
- **2 Toques Máximo**: Valor → Categoria → Salvo!
- **Smart Defaults**: Categoria mais usada pré-selecionada

### O Fluxo "Calculadora"

```
┌─────────────────────────────────────┐
│                        R$ 0,00     │
│                                     │
│  [Mão de Obra] [Adubo] [Diesel]    │
│  [Veneno] [Manut.] [Outros]        │
│                                     │
│  ┌─────┬─────┬─────┐               │
│  │  7  │  8  │  9  │               │
│  ├─────┼─────┼─────┤               │
│  │  4  │  5  │  6  │               │
│  ├─────┼─────┼─────┤               │
│  │  1  │  2  │  3  │               │
│  ├─────┼─────┼─────┤               │
│  │  ,  │  0  │  ⌫  │               │
│  └─────┴─────┴─────┘               │
│                                     │
│  [       ✓ SALVAR       ]          │
└─────────────────────────────────────┘
```

### UX Flow
```
1. Abre app → Teclado numérico GIGANTE na tela
2. Digita valor (ex: 150)
3. Toca na categoria (chips no topo)
4. Toca "Salvar" → PRONTO!
   - Feedback háptico
   - Toast "R$ 150,00 - Diesel ✓"
   - Tela limpa para próximo lançamento
```

### Smart Features (Invisible Complexity)
- **Categoria Frequente**: A categoria mais usada fica pré-selecionada
- **Valor Recente**: Sugere valores frequentes (R$ 50, R$ 100, R$ 200)
- **Data Automática**: Sempre "hoje", sem perguntar
- **Centro de Custo Padrão**: Usa o padrão até usuário mudar

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | **Scaffold do App**: Criar estrutura básica com Firebase, Hive, agro_core | ⏳ TODO |
| 1.2 | **Modelo Despesa**: Entidade com valor, categoria, data, centroCusto | ⏳ TODO |
| 1.3 | **Calculator Keypad**: Teclado numérico grande estilo calculadora | ⏳ TODO |
| 1.4 | **Category Chips**: Seletor de categorias com chips coloridos | ⏳ TODO |
| 1.5 | **Quick Save Flow**: Salvar com feedback háptico + toast | ⏳ TODO |
| 1.6 | **Home Lista**: Lista de despesas do mês com total no topo | ⏳ TODO |

### Categorias de Despesa

| Categoria | Ícone | Cor | Atalho |
|-----------|-------|-----|--------|
| Mão de Obra | 👷 | Blue | MO |
| Adubo/Fertilizante | 🌱 | Green | AD |
| Defensivos/Veneno | 🧪 | Purple | VE |
| Combustível/Diesel | ⛽ | Orange | DI |
| Manutenção | 🔧 | Gray | MA |
| Energia/Água | 💡 | Yellow | EN |
| Outros | 📦 | Brown | OU |

---

## Phase CASH-02: Centro de Custo (O Segredo)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Permitir alocar despesas para diferentes áreas da fazenda.

### Business Context
Uma fazenda tem múltiplas atividades. O produtor precisa saber:
- Quanto a Seringueira custou este ano?
- Quanto o Gado custou?
- Quanto a Sede administrativa custou?

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Modelo CentroCusto**: Entidade com nome, ícone, cor, vinculação ao app | ⏳ TODO |
| 2.2 | **Seletor de Centro**: Ao lançar despesa, escolher para onde foi | ⏳ TODO |
| 2.3 | **Divisão Proporcional**: Opção de dividir uma despesa (ex: 50% Seringal, 50% Gado) | ⏳ TODO |
| 2.4 | **Relatório por Centro**: Dashboard mostrando despesas de cada atividade | ⏳ TODO |

### Centros de Custo Padrão

| Centro | Vinculado ao App | Descrição |
|--------|------------------|-----------|
| Seringal | RuraRubber | Produção de borracha |
| Gado | RuraCattle | Pecuária |
| Lavoura | RuraRain (futuro) | Agricultura |
| Sede | - | Administrativo geral |
| Trator/Veículos | - | Uso compartilhado |

---

## Phase CASH-03: Integração com Ecossistema RuraCamp

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Sincronizar receitas e custos com os outros apps.

### O Fluxo de Integração

```
RuraRubber (Entregas) ──┐
                       ├──► RuraCash (Receitas)
RuraCattle (Vendas) ───┘

RuraCash (Despesas por Centro) ──► RuraRubber (Custo/Kg)
                                ──► RuraCattle (Custo/Arroba)
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | **API de Receitas**: Endpoint para buscar receitas dos outros apps | ⏳ TODO |
| 3.2 | **Listener de Entregas**: Quando RuraRubber fecha entrega, notificar RuraCash | ⏳ TODO |
| 3.3 | **Push de Custos**: Enviar custo/kg para RuraRubber calcular margem | ⏳ TODO |
| 3.4 | **Sincronização Cloud**: Usar Firestore para sincronizar entre apps | ⏳ TODO |

---

## Phase CASH-04: DRE Simplificado

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Demonstrativo do Resultado do Exercício da fazenda inteira.

### O Dashboard Final

```
┌─────────────────────────────────────┐
│       DRE FAZENDA - Jan/2026        │
├─────────────────────────────────────┤
│ RECEITAS                            │
│   Borracha (RuraRubber)   R$ 45.000 │
│   Gado (RuraCattle)       R$ 12.000 │
│   ────────────────────────────────  │
│   Total Receitas          R$ 57.000 │
├─────────────────────────────────────┤
│ DESPESAS                            │
│   Seringal                R$ 18.000 │
│   Gado                    R$  8.000 │
│   Sede                    R$  3.000 │
│   ────────────────────────────────  │
│   Total Despesas          R$ 29.000 │
├─────────────────────────────────────┤
│ RESULTADO                 R$ 28.000 │
│ Margem                        49.1% │
└─────────────────────────────────────┘
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **Tela DRE**: Dashboard visual com receitas x despesas | ⏳ TODO |
| 4.2 | **Filtro por Período**: Mês, Trimestre, Safra, Ano | ⏳ TODO |
| 4.3 | **Comparativo**: DRE atual vs período anterior | ⏳ TODO |
| 4.4 | **Exportar PDF**: Gerar relatório para contador/banco | ⏳ TODO |

---

## Dependências

### De agro_core
- AuthService (login compartilhado)
- PropertyService (propriedades)
- CloudBackupService (backup)
- AgroTheme (visual consistente)
- L10n (internacionalização)

### De Firebase
- Firestore (sincronização entre apps)
- Cloud Functions (triggers de integração)

---

## Prioridade de Implementação

1. **CASH-01** (MVP) - Lançamento funcional
2. **CASH-02** (Centros de Custo) - Diferenciação
3. **RUBBER-20** (Break-even) - Implementar no RuraRubber primeiro usando despesas locais
4. **CASH-03** (Integração) - Conectar os apps
5. **CASH-04** (DRE) - Visão consolidada

---

## Notas Técnicas

### Arquitetura de Dados

```dart
// Despesa (Hive + Firestore)
class Despesa {
  String id;
  String userId;
  double valor;
  String categoria;
  String centroCusto;
  DateTime data;
  bool pago;
  String? observacao;
  String? safraId; // Vinculação com safra
}

// CentroCusto
class CentroCusto {
  String id;
  String nome;
  String icone;
  String cor;
  String? appVinculado; // 'rurarubber', 'ruracattle', null
}
```

### Sincronização
- Usar mesmo padrão de BackupProvider do agro_core
- Firestore collection: `users/{userId}/despesas`
- Real-time sync quando online
