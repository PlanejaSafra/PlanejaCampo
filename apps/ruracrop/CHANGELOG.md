# CHANGELOG - RuraCrop (Planejamento)

> **Status**: App em planejamento. Não iniciado.
> **Objetivo**: Sistema de Inteligência Agronômica para agricultura anual (Soja, Milho, Feijão, etc.)
> **Foco**: Planejamento de safra, Consultor de Solo, Diário de Operações, Colheita com descontos.

---

## 🌱 Visão do Produto

### Por que RuraCrop?

O RuraCrop completa o ecossistema RuraCamp para fazendas mistas:

| App | Função | Perfil de Retorno |
|-----|--------|-------------------|
| **RuraRubber** | Borracha | Fluxo de caixa mensal (aposentadoria) |
| **RuraCattle** | Gado | Patrimônio líquido (poupança) |
| **RuraCrop** | Lavoura | Grande lucro anual (bônus), alto risco |
| **RuraCash** | Despesas | Consolidação financeira |

### Diferencial Competitivo

1. **Consultor de Solo**: Interpreta análise de solo e sugere adubação (não apenas armazena PDF)
2. **Integração Total**: Custo do adubo vai para RuraCash automaticamente
3. **Cálculo de Desconto**: Evita produtor ser enganado na balança (umidade, impureza)
4. **Offline-First**: Funciona no campo sem internet

---

## 📐 Arquitetura: Monolito com Abas de Processo

> **Decisão**: Um único app RuraCrop, NÃO quebrar em RuraPlantio, RuraColheita, etc.
> A agricultura é sistêmica - adubação depende de colheita esperada.

### Estrutura de Navegação

```
RuraCrop
├── 📋 Planejamento (Cultura, Variedade, Meta)
├── 🧪 Preparo (Análise de Solo, Adubação, Calagem)
├── 🌾 Manejo (Plantio, Aplicações, Pragas)
└── 🚛 Colheita (Romaneio, Descontos, Destino)
```

---

## 🔗 Integração com Safra Global (CORE-75 + CORE-76)

### Hierarquia de Dados

```
Safra Global (agro_core)
└── "Safra 2025/2026"
    ├── RuraRubber: Pesagens de borracha
    ├── RuraCattle: Movimentações de gado
    └── RuraCrop: Ciclos de Cultura
        ├── Ciclo 1: Soja (Verão) - Talhão 1
        ├── Ciclo 2: Milho Safrinha - Talhão 1
        └── Ciclo 1: Soja (Verão) - Talhão 2
```

### Diferença: Safra vs Ciclo

| Conceito | Descrição | Exemplo |
|----------|-----------|---------|
| **Safra** | Ano agrícola global (Set-Ago) | "Safra 2025/2026" |
| **Ciclo** | Instância de cultura em um talhão | "Soja Verão - Talhão 1" |

> **Nota**: Borracha não tem ciclos (perene). Lavoura tem múltiplos ciclos por safra.

---

## Phase CROP-01: MVP - Ciclos e Culturas

### Status: [TODO]
**Priority**: 🔴 CRITICAL (Fundação)
**Objective**: Permitir criar Ciclos de Cultura vinculados a Talhões e Safras.

### Modelo de Dados

```dart
class CicloCultura {
  String id;
  String farmId;           // UUID da Farm (CORE-75)
  String safraId;          // Vinculo com Safra global
  String talhaoId;         // Qual talhão
  String cultura;          // "soja", "milho", "feijao"
  String? variedade;       // "Brasmax Desafio", "AG 1051"
  String? tecnologia;      // "RR", "IPRO", "Convencional"
  DateTime? dataPlantioAlvo;
  DateTime? dataPlantioReal;
  DateTime? dataColheitaAlvo;
  DateTime? dataColheitaReal;
  double? metaProdutividade;  // sacas/ha
  double? populacaoPlantas;   // plantas/ha
  String status;           // "planejado", "plantado", "colhido"
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.1 | **Scaffold do App**: Criar estrutura básica com Firebase, Hive, agro_core | ⏳ TODO |
| 1.2 | **Modelo CicloCultura**: Entidade com Hive adapter | ⏳ TODO |
| 1.3 | **CicloService**: CRUD + queries por safra/talhão | ⏳ TODO |
| 1.4 | **Lista de Ciclos**: Tela inicial mostrando ciclos da safra atual | ⏳ TODO |
| 1.5 | **Criar Ciclo**: Wizard para configurar novo ciclo | ⏳ TODO |
| 1.6 | **Integração Safra**: Usar SafraService do agro_core | ⏳ TODO |

### L10n Keys Required
- `cicloCultura`: "Ciclo de Cultura"
- `novoCiclo`: "Novo Ciclo"
- `cultura`: "Cultura"
- `variedade`: "Variedade"
- `tecnologia`: "Tecnologia"
- `dataPlantioAlvo`: "Data de Plantio (Alvo)"
- `metaProdutividade`: "Meta de Produtividade (sc/ha)"
- `populacaoPlantas`: "População de Plantas"
- `statusPlanejado`: "Planejado"
- `statusPlantado`: "Plantado"
- `statusColhido`: "Colhido"

---

## Phase CROP-02: Consultor de Solo (Feature Matadora) 🧪

### Status: [TODO]
**Priority**: 🔴 CRITICAL (Diferencial Competitivo)
**Objective**: Interpretar análise de solo e sugerir adubação baseado em literatura técnica.

### Business Context

O produtor recebe a análise de solo do laboratório mas não sabe interpretar.
O RuraCrop vai:
1. Receber os dados da análise
2. Cruzar com tabelas oficiais (Boletim 100, Embrapa)
3. Sugerir calagem e adubação para a meta de produtividade

### O Fluxo do Consultor

```
1. [INPUT] Usuário digita dados da análise de solo
   ┌─────────────────────────────────────┐
   │  📋 Análise de Solo - Talhão 1      │
   │                                     │
   │  pH (CaCl2):    [5.2___]            │
   │  V% (Saturação):[45____]            │
   │  P-Resina:      [12____] mg/dm³     │
   │  K:             [0.15__] cmolc/dm³  │
   │  Ca:            [2.5___] cmolc/dm³  │
   │  Mg:            [0.8___] cmolc/dm³  │
   │  MO:            [2.8___] %          │
   │  Argila:        [35____] %          │
   │                                     │
   │  Meta: [60] sacas/ha de [Soja ▼]    │
   │                                     │
   │  [CALCULAR RECOMENDAÇÃO]            │
   └─────────────────────────────────────┘

2. [PROCESSAMENTO] Motor de Recomendação cruza com tabelas

3. [OUTPUT] Sugestão com proteção jurídica
   ┌─────────────────────────────────────┐
   │  🧪 Recomendação de Adubação        │
   │                                     │
   │  CALAGEM:                           │
   │  └ 1.5 ton/ha Calcário (PRNT 80%)   │
   │                                     │
   │  ADUBAÇÃO DE BASE:                  │
   │  └ P2O5: 80 kg/ha                   │
   │  └ K2O:  60 kg/ha                   │
   │                                     │
   │  FORMULAÇÃO SUGERIDA:               │
   │  └ 150 kg/ha de MAP (11-52-00)      │
   │  └ 100 kg/ha de KCL (00-00-60)      │
   │                                     │
   │  ⚠️ Baseado no Boletim 100-SP.      │
   │  Valide com seu Eng. Agrônomo.      │
   │                                     │
   │  [✓ VALIDAR E GERAR RECOMENDAÇÃO]   │
   └─────────────────────────────────────┘
```

### Proteção Jurídica (Disclaimer)

> **CRÍTICO**: O app é "Ferramenta de Apoio à Decisão", não receita agronômica.

1. **Termos de Uso**: "Cálculos baseados em literatura técnica. Não substitui avaliação de Engenheiro Agrônomo."
2. **Botão de Validação**: Usuário clica "Validar" para assumir responsabilidade
3. **Rastreabilidade**: PDF gerado inclui: "Baseado no Manual X, Tabela Y. Validado em [Data]."

### Modelo de Dados

```dart
class AnaliseSolo {
  String id;
  String farmId;
  String talhaoId;
  DateTime dataColeta;
  DateTime? dataResultado;

  // Parâmetros da análise
  double? ph;           // pH em CaCl2
  double? vPercent;     // Saturação por bases (V%)
  double? pResina;      // Fósforo (mg/dm³)
  double? potassio;     // K (cmolc/dm³)
  double? calcio;       // Ca (cmolc/dm³)
  double? magnesio;     // Mg (cmolc/dm³)
  double? materiaOrganica; // MO (%)
  double? argila;       // Argila (%)
  double? ctc;          // CTC (cmolc/dm³)

  // Micronutrientes (opcionais)
  double? boro;
  double? cobre;
  double? ferro;
  double? manganes;
  double? zinco;
  double? enxofre;
}

class RecomendacaoAdubacao {
  String id;
  String analiseId;
  String cicloId;
  String cultura;
  double metaProdutividade;  // sacas/ha

  // Necessidades calculadas
  double calageTonHa;        // Calcário (ton/ha)
  double prnTRecomendado;    // PRNT mínimo do calcário
  double necessidadeN;       // kg/ha de N
  double necessidadeP2O5;    // kg/ha de P2O5
  double necessidadeK2O;     // kg/ha de K2O

  // Formulação sugerida (opcional)
  List<FormulaSugerida>? formulas;

  // Auditoria
  String fonteCalculo;       // "Boletim 100-SP", "Embrapa Cerrados"
  DateTime calculadoEm;
  DateTime? validadoEm;      // Quando usuário clicou "Validar"
  String? validadoPor;       // userId
}

class FormulaSugerida {
  String produto;      // "MAP", "KCL", "Ureia"
  String formulacao;   // "11-52-00"
  double qtdKgHa;      // Quantidade sugerida
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | **Modelo AnaliseSolo**: Entidade com todos os parâmetros | ⏳ TODO |
| 2.2 | **Tabelas de Referência**: JSON com dados do Boletim 100, Embrapa | ⏳ TODO |
| 2.3 | **Motor de Cálculo**: Lógica de calagem (V% alvo) e adubação (extração + reposição) | ⏳ TODO |
| 2.4 | **Tela de Input**: Formulário para digitar análise de solo | ⏳ TODO |
| 2.5 | **Tela de Resultado**: Exibição da recomendação com disclaimer | ⏳ TODO |
| 2.6 | **Validação Jurídica**: Botão "Validar" com registro de timestamp | ⏳ TODO |
| 2.7 | **Calculadora de Formulação**: Transforma N-P-K em produtos reais | ⏳ TODO |
| 2.8 | **Exportar PDF**: Relatório com fonte de cálculo e validação | ⏳ TODO |

### Tabelas de Referência (Exemplo Simplificado)

```json
{
  "soja": {
    "fonte": "Boletim 100 IAC - 2022",
    "extracaoKg": { "N": 80, "P2O5": 20, "K2O": 45 },
    "tabelaP": {
      "muitoBaixo": { "max": 6, "dose": 90 },
      "baixo": { "max": 12, "dose": 60 },
      "medio": { "max": 30, "dose": 40 },
      "alto": { "max": 60, "dose": 20 },
      "muitoAlto": { "min": 60, "dose": 0 }
    }
  }
}
```

### L10n Keys Required
- `analiseSolo`: "Análise de Solo"
- `dataColeta`: "Data da Coleta"
- `recomendacaoAdubacao`: "Recomendação de Adubação"
- `calagem`: "Calagem"
- `adubacaoBase`: "Adubação de Base"
- `formulacaoSugerida`: "Formulação Sugerida"
- `validarRecomendacao`: "Validar e Gerar Recomendação"
- `disclaimerAdubacao`: "Baseado em literatura técnica. Valide com seu Engenheiro Agrônomo."
- `fonteCalculo`: "Fonte do Cálculo"
- `validadoEm`: "Validado em"

---

## Phase CROP-03: Diário de Operações (Tratos Culturais)

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Registrar cronologia de operações por ciclo/talhão.

### O Diário de Campo Digital

```
┌────────────────────────────────────────┐
│ 📋 Diário - Soja Verão (Talhão 1)      │
├────────────────────────────────────────┤
│                                        │
│ [15/09] 🧪 Dessecação                  │
│         Glyphosate + 2,4-D             │
│         2.5 L/ha + 0.8 L/ha            │
│         Aplicador: João                │
│                                        │
│ [25/09] 🌱 Plantio                     │
│         Brasmax Desafio                │
│         14 sementes/metro              │
│         Profundidade: 3cm              │
│                                        │
│ [20/10] 💊 Fungicida (Preventivo)      │
│         Fox + Ópera                    │
│         0.4 L/ha + 0.5 L/ha            │
│                                        │
│ [+] Nova Operação                      │
└────────────────────────────────────────┘
```

### Tipos de Operação

| Tipo | Ícone | Campos Específicos |
|------|-------|-------------------|
| Dessecação | 🧪 | Produtos, Doses, Volume calda |
| Plantio | 🌱 | Variedade, População, Profundidade |
| Adubação | 🧬 | Produto, Dose kg/ha, Modo aplicação |
| Fungicida | 💊 | Produtos, Doses, Alvo (preventivo/curativo) |
| Herbicida | 🌿 | Produtos, Doses, Plantas daninhas alvo |
| Inseticida | 🐛 | Produtos, Doses, Praga alvo |
| Colheita | 🚛 | Data, Produtividade, Umidade |

### Modelo de Dados

```dart
class OperacaoCampo {
  String id;
  String cicloId;
  String farmId;
  String createdBy;
  DateTime dataOperacao;
  String tipo;              // "dessecacao", "plantio", "fungicida", etc.
  String? descricao;
  List<InsumoAplicado>? insumos;
  double? areaAplicada;     // ha (pode ser parcial)
  String? responsavel;
  String? observacoes;
  List<String>? fotos;      // Paths das fotos
  double? latitude;
  double? longitude;
}

class InsumoAplicado {
  String produto;
  String? principioAtivo;
  double dose;
  String unidadeDose;       // "L/ha", "kg/ha", "mL/ha"
  double? volumeCalda;      // L/ha (para líquidos)
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | **Modelo OperacaoCampo**: Entidade genérica para todos os tipos | ⏳ TODO |
| 3.2 | **Timeline Widget**: Visualização cronológica das operações | ⏳ TODO |
| 3.3 | **Forms por Tipo**: Campos específicos para cada tipo de operação | ⏳ TODO |
| 3.4 | **Captura de Fotos**: Registrar foto com GPS da operação | ⏳ TODO |
| 3.5 | **Integração RuraCash**: Operação gera custo automaticamente | ⏳ TODO |

---

## Phase CROP-04: Colheita e Romaneio

### Status: [TODO]
**Priority**: 🟡 ARCHITECTURAL
**Objective**: Registrar cargas de colheita com cálculo de descontos.

### O Problema do Produtor

O produtor chega na balança do comprador com 30 toneladas de soja.
O comprador diz: "Umidade 16%, impureza 2%. Desconto de X kg."
O produtor não sabe se o cálculo está certo.

### A Solução: Calculadora de Descontos

```
┌─────────────────────────────────────┐
│  🚛 Registro de Carga               │
├─────────────────────────────────────┤
│                                     │
│  Peso Bruto:    [30.000] kg         │
│  Umidade:       [16.0__] %          │
│  Impureza:      [2.0___] %          │
│                                     │
│  ──────────────────────────────     │
│  📊 CÁLCULO DE DESCONTO             │
│                                     │
│  Umidade padrão: 14%                │
│  Desconto umidade: -571 kg          │
│  Desconto impureza: -600 kg         │
│  ──────────────────────────────     │
│  PESO LÍQUIDO: 28.829 kg            │
│  ──────────────────────────────     │
│                                     │
│  Destino: [Cooperativa ABC ▼]       │
│  Placa:   [ABC-1234______]          │
│                                     │
│  [SALVAR CARGA]                     │
└─────────────────────────────────────┘
```

### Fórmulas de Desconto (Padrão Brasileiro)

```dart
// Desconto por Umidade (Regra de Três)
double descontoUmidade(double pesoBruto, double umidadeAtual, double umidadePadrao) {
  if (umidadeAtual <= umidadePadrao) return 0;
  return pesoBruto * (umidadeAtual - umidadePadrao) / (100 - umidadePadrao);
}

// Desconto por Impureza (Direto)
double descontoImpureza(double pesoBruto, double impurezaAtual, double impurezaPadrao) {
  if (impurezaAtual <= impurezaPadrao) return 0;
  return pesoBruto * (impurezaAtual - impurezaPadrao) / 100;
}

// Peso Líquido Final
double pesoLiquido = pesoBruto - descontoUmidade - descontoImpureza;
```

### Modelo de Dados

```dart
class CargaColheita {
  String id;
  String cicloId;
  String farmId;
  String createdBy;
  DateTime dataColheita;

  // Dados da carga
  double pesoBruto;        // kg
  double umidade;          // %
  double impureza;         // %
  double? avariados;       // % (opcional)
  double? verdoengos;      // % (opcional)

  // Cálculos
  double descontoUmidade;
  double descontoImpureza;
  double pesoLiquido;

  // Destino
  String? destinoNome;     // "Cooperativa ABC"
  String? placa;
  String? motorista;
  String? notaFiscal;

  // Preço (opcional)
  double? precoSaca;       // R$/saca
  double? valorTotal;
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | **Modelo CargaColheita**: Entidade com descontos calculados | ⏳ TODO |
| 4.2 | **Calculadora de Descontos**: Widget com preview em tempo real | ⏳ TODO |
| 4.3 | **Tela de Registro**: Formulário de carga com cálculo automático | ⏳ TODO |
| 4.4 | **Romaneio do Ciclo**: Lista de cargas com totais | ⏳ TODO |
| 4.5 | **Exportar Romaneio**: PDF com todas as cargas e totais | ⏳ TODO |
| 4.6 | **Integração RuraCash**: Gerar receita ao vender | ⏳ TODO |

---

## Phase CROP-05: Controle de Estoque (Barracão Digital)

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Controlar estoque de insumos e alertar sobre sobras/faltas.

### O Problema

Se o RuraCrop sabe que você comprou 10 toneladas de adubo (RuraCash) e aplicou 8 toneladas nos talhões...

**O App avisa:** "Você deve ter 2 toneladas sobrando no barracão. Confere?"

### Fluxo de Controle

```
ENTRADA (RuraCash)          SAÍDA (RuraCrop)
─────────────────           ────────────────
Compra 10 ton MAP    →     Aplicou 3 ton Talhão 1
                           Aplicou 3 ton Talhão 2
                           Aplicou 2 ton Talhão 3
                           ─────────────────────
                           SALDO: 2 ton (conferir!)
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | **Modelo Estoque**: Entradas (compras) e Saídas (aplicações) | ⏳ TODO |
| 5.2 | **Integração RuraCash**: Compra de insumo vira entrada no estoque | ⏳ TODO |
| 5.3 | **Baixa Automática**: Operação de adubação baixa do estoque | ⏳ TODO |
| 5.4 | **Alerta de Conferência**: Notificar quando saldo positivo | ⏳ TODO |
| 5.5 | **Inventário Físico**: Tela para ajustar estoque real vs calculado | ⏳ TODO |

---

## Phase CROP-06: Monitoramento de Pragas (MIP Digital)

### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Registrar focos de pragas com GPS para mapear infestação.

### O Mapa de Calor de Pragas

```
┌────────────────────────────────────────┐
│  🐛 Monitoramento - Talhão 1           │
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  🔴 Lagarta                      │  │
│  │       🟡                         │  │
│  │            🟢                    │  │
│  │  [Mapa do Talhão com pontos]     │  │
│  │                                  │  │
│  └──────────────────────────────────┘  │
│                                        │
│  🔴 Alta infestação (canto represa)   │
│  🟡 Média infestação                   │
│  🟢 Baixa infestação                   │
│                                        │
│  [+ Registrar Foco]                    │
└────────────────────────────────────────┘
```

### Modelo de Dados

```dart
class RegistroPraga {
  String id;
  String cicloId;
  String talhaoId;
  String farmId;
  String createdBy;
  DateTime dataRegistro;

  String praga;            // "lagarta", "percevejo", "ferrugem"
  String nivel;            // "baixo", "medio", "alto"
  int? contagem;           // Ex: 2 lagartas/pano de batida

  double latitude;
  double longitude;
  List<String>? fotos;
  String? observacoes;
}
```

### Implementation Plan

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1 | **Modelo RegistroPraga**: Entidade com GPS | ⏳ TODO |
| 6.2 | **Catálogo de Pragas**: Lista das principais pragas por cultura | ⏳ TODO |
| 6.3 | **Registro com Foto**: Captura de foto + localização | ⏳ TODO |
| 6.4 | **Mapa de Calor**: Visualização de focos no mapa do talhão | ⏳ TODO |
| 6.5 | **Alerta de Threshold**: Notificar quando atingir nível de ação | ⏳ TODO |

---

## Dependências

### De agro_core
- `Farm` e `FarmService` (CORE-75) - Vinculação de dados
- `Safra` e `SafraService` (CORE-76) - Janela temporal
- `Talhao` e `TalhaoService` - Áreas de cultivo
- `Property` e `PropertyService` - Propriedades
- `AuthService` - Autenticação
- `CloudBackupService` - Backup
- `AgroTheme` - Visual consistente
- `L10n` - Internacionalização

### De RuraCash (Futuro)
- `DespesaService` - Custos das operações
- `ReceitaService` - Receitas das vendas

### De RuraRain
- `WeatherService` - Condições para plantio/aplicação

---

## Prioridade de Implementação

1. **CROP-01** (MVP) - Ciclos e Culturas (fundação)
2. **CROP-02** (Diferencial) - Consultor de Solo
3. **CROP-03** (Core) - Diário de Operações
4. **CROP-04** (Core) - Colheita e Romaneio
5. **CROP-05** (Enhancement) - Controle de Estoque
6. **CROP-06** (Enhancement) - MIP Digital

---

## Cross-Reference

- **CORE-75**: Farm model para multi-user
- **CORE-76**: Ciclos de Cultura (a criar)
- **RUBBER-17**: Modelo de Safra (janela de tempo)
- **CASH-02**: Centros de Custo por Talhão
- **RAIN-XX**: Alertas de condição de plantio
