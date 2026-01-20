# CHANGELOG - PlanejaBorracha

---

## Phase BORRACHA-05: Mercado & Matchmaking (Online/Hybrid)
### Status: [TODO]
**Priority**: 🟡 MEDIUM
**Objective**: Connect producers with buyers through geo-located offers and direct negotiation.

### Implementation Plan
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.1 | Create `market_offers` collection structure in Firestore | ⏳ TODO |
| 5.2 | Implement `MercadoScreen` with GeoHash filtering | ⏳ TODO |
| 5.3 | Implement `CriarOfertaScreen` (Buyer Profile) | ⏳ TODO |
| 5.4 | Implement WhatsApp Deep Link integration | ⏳ TODO |

### Files to Modify
- `lib/services/market_service.dart` (NEW)
- `lib/screens/mercado_screen.dart` (NEW)
- `lib/screens/criar_oferta_screen.dart` (NEW)

---

## Phase BORRACHA-04: Fechamento Financeiro & Output
### Status: [TODO]
**Priority**: 🟢 ENHANCEMENT
**Objective**: Calculate financial totals based on DRC/Wet price and generate shareable receipts.

### Implementation Plan
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.1 | Implement financial calculation logic (Share split, Advances) | ⏳ TODO |
| 4.2 | Create `FechamentoEntregaScreen` dialog | ⏳ TODO |
| 4.3 | Implement PDF generation (Receipt) | ⏳ TODO |
| 4.4 | Integrate simple content sharing (WhatsApp) | ⏳ TODO |

### Files to Modify
- `lib/screens/fechamento_entrega_screen.dart` (NEW)
- `lib/services/pdf_service.dart` (NEW)
- `lib/models/entrega.dart` (Logic extension)

---

## Phase BORRACHA-03: Pesagem Rápida UX (The "Killer Feature")
### Status: [TODO]
**Priority**: 🔴 CRITICAL
**Objective**: Develop the "One-Handed Calculator" interface for rapid data entry in the field.

### Implementation Plan
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.1 | Implement Custom Numeric Keypad (Big Buttons) | ⏳ TODO |
| 3.2 | Create "Tape View" (Accumulator history: 120 + 95...) | ⏳ TODO |
| 3.3 | Implement Partner Switching Logic (Hot-swap) | ⏳ TODO |
| 3.4 | Persist state for "Work in Progress" delivery | ⏳ TODO |

### Files to Modify
- `lib/screens/pesagem_screen.dart` (NEW)
- `lib/widgets/pesagem_keypad.dart` (NEW)
- `lib/widgets/fita_somar_widget.dart` (NEW)

---

## Phase BORRACHA-02: Gestão de Parceiros & Models (Foundation)
### Status: [TODO]
**Priority**: 🔴 CRITICAL
**Objective**: Implement core data structures and "Set-and-Forget" partner configuration.

### Implementation Plan
| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.1 | Implement Hive Models: `Parceiro`, `Entrega`, `ItemEntrega` | ⏳ TODO |
| 2.2 | Generate Hive Adapters (`build_runner`) | ⏳ TODO |
| 2.3 | Create `ParceirosListScreen` (CRUD) | ⏳ TODO |
| 2.4 | Implement Task/Talhão linking | ⏳ TODO |

### Files to Modify
- `lib/models/parceiro.dart` (NEW)
- `lib/models/entrega.dart` (NEW)
- `lib/screens/parceiros_list_screen.dart` (NEW)

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
