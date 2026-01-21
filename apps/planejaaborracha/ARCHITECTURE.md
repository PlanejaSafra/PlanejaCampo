# Architecture - PlanejaBorracha

Este documento define a arquitetura técnica e o roadmap de desenvolvimento do **PlanejaBorracha**, focado em simplicidade e robustez para o sangrador e produtor de seringueira.

## Visão Geral

O app atua em duas frentes principais:
1.  **Romaneio Digital (Offline API)**: Calculadora de pesagem rápida e gestão de parceiros.
2.  **Mercado (Online/Híbrido)**: Conexão com compradores (Usinas/Bancas).

---

## Estrutura de Dados (Models)

### Fase 1: Gestão de Parceiros e Pesagem (Offline-First - Hive)

*   **`UserProfile` (HiveObject)**:
    *   `profileType`: Enum (produtor, comprador)
    *   `displayName`: String?
    *   `profileComplete`: bool
    *   `createdAt`: DateTime
    *   `updatedAt`: DateTime?

*   **`Parceiro` (HiveObject)**:
    *   `id`: String (UUID)
    *   `nome`: String
    *   `percentualPadrao`: double (ex: 50.0)
    *   `telefone`: String?
    *   `fotoPath`: String? (Local storage)
    *   `tarefasIds`: List<String> (IDs de Talhões do `agro_core`)

*   **`Entrega` (HiveObject)**:
    *   `id`: String (UUID)
    *   `data`: DateTime
    *   `status`: Enum (Aberto, Fechado, Pago)
    *   `precoDrc`: double?
    *   `precoUmido`: double?
    *   `compradorId`: String? (Link para Mercado - opcional)
    *   `itens`: List<ItemEntrega>

*   **`ItemEntrega` (HiveObject)**:
    *   `parceiroId`: String
    *   `pesagens`: List<double> (ex: `[30.5, 40.2]`)
    *   `pesoTotal`: double (Computed)
    *   `valorTotal`: double (Computed - após fechamento)
    *   `descontos`: double (Adiantamentos)

### Fase 2: O Mercado (Firestore)

*   **`MarketOffer` (Firestore Collection: `market_offers`)**:
    *   `id`: String
    *   `buyerId`: String (User ID do comprador)
    *   `regions`: List<String> (GeoHash 4-5 chars)
    *   `priceDrc`: double
    *   `priceWet`: double (Banca)
    *   `conditions`: String (Texto livre ou estruturado)
    *   `validUntil`: Timestamp
    *   `createdAt`: Timestamp

---

## Telas Principais (Screens)

### Módulo 0: Fluxo de Entrada

*   **`ProfileSelectionScreen`**:
    *   Seleção de perfil (Produtor ou Comprador).
    *   Exibido apenas na primeira vez após login.

*   **`HomeScreen` (Dashboard)**:
    *   Visão geral personalizada baseada no perfil.
    *   Resumo mensal, ações rápidas, entregas recentes.
    *   FAB contextual (Nova Pesagem ou Nova Oferta).

### Módulo 1: Romaneio Digital (Produtor)

*   **`ListaEntregasScreen`**:
    *   Histórico de pesagens agrupado por mês.
    *   Resumo financeiro rápido.

*   **`PesagemScreen` (Core UX)**:
    *   **Foco**: Uso com uma mão. Botões grandes.
    *   **Fluxo**: Selecionar Parceiro -> Teclado Calculadora (Acumulador) -> Salvar.
    *   **Visual**: "Fita de somar" visível.

*   **`ParceirosListScreen`**:
    *   CRUD de parceiros.
    *   Configuração "Set-and-Forget" de percentuais e talhões.

*   **`FechamentoEntregaScreen`**:
    *   Input de preço final.
    *   Cálculo automático de rateio.
    *   Geração de Recibo PDF simples (via `pdf` package).

### Módulo 2: O Mercado

*   **`MercadoScreen`**:
    *   Feed de ofertas filtrado pela localização da propriedade (`agro_core`).
    *   Botão "Tenho Interesse": Deeplink para WhatsApp.

*   **`CriarOfertaScreen`**:
    *   Exclusivo para perfil Comprador.
    *   Formulário de criação de anúncio.

---

## Roadmap

### Fase 1: MVP - O Caderno Digital
*   [ ] Implementar Models Hive (`Parceiro`, `Entrega`).
*   [ ] Criar `ParceirosListScreen` e fluxo de cadastro.
*   [ ] Implementar `PesagemScreen` (Calculadora UX).
*   [ ] Criar `ListaEntregasScreen` e `FechamentoEntregaScreen`.
*   [ ] Gerador de PDF simples para compartilhamento.

### Fase 2: Conectividade
*   [ ] Implementar módulo de Mercado (Firestore).
*   [ ] Matchmaking geográfico (GeoHash).
*   [ ] Integração WhatsApp.
