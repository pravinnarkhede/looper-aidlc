# Unit of Work — Story Map

## Feature: tax-inclusive-inventory (CCD-20)

Note: User Stories stage was skipped (technical server-side feature, no new user personas). Acceptance criteria from PRD-020 serve as the story-equivalent requirements and are mapped to units here.

---

## Acceptance Criteria → Unit Mapping

| # | Acceptance Criterion (from PRD-020) | Unit | Phase |
|---|-------------------------------------|------|-------|
| AC-2 | Terminal-loaded inventory includes `IsTaxInclusive` used by order creation | Unit 2 | Phase 2 |
| AC-3 | `GetDiscountedItedOrdered` uses `IsTaxInclusive` as authoritative for inclusive/exclusive logic | Unit 1 | Phase 1 |
| AC-4 | Items with active dynamic pricing schedules use schedule price at order time (mobile resolves) | Unit 1 | Phase 1 |
| AC-6 | Inclusive items derive correct base/tax split from effective price and persist tax detail records | Unit 1 | Phase 1 |
| AC-7 | Mixed cart (inclusive + exclusive) computes totals correctly | Unit 1 | Phase 1 |
| AC-8 | Sales tax reports continue to produce accurate tax totals | Unit 1 | Phase 1 |
| AC-9 | Existing products and historical orders remain unaffected | Unit 1 | Phase 1 |
| AC-10 | When both `TaxInclusive` and `IsTaxInclusive` present, order logic uses `IsTaxInclusive` | Unit 1 | Phase 1 |
| AC-12 | Combo items with multiple component lines calculate totals and taxes correctly | Unit 1 | Phase 1 |
| AC-13 | Combo pricing/tax behavior consistent between POS display, persisted order lines, and tax reports | Unit 1 | Phase 1 |
| AC-15 | Pre-tax reversal invoked only when `IsTaxInclusive = true`; skipped for false | Unit 1 | Phase 1 |
| AC-16 | POS pre-tax calculation uses correct `TaxGroup` + tax-group-tax calculation behavior | Unit 1 | Phase 1 |
| AC-17 | All POS workflows use shared pre-tax resolution (`ResolvePreTaxUnitPrice`) | Unit 1 | Phase 1 |
| AC-20 | Multi-tax group: tax-inclusive pre-tax reversal produces detail rows consistent with per-tax loop | Unit 1 | Phase 1 |
| AC-21 | Per tax row: `MidpointRounding.AwayFromZero` after one-item tax, before quantity multiplication | Unit 1 | Phase 1 |
| AC-22 | Combo details with `IsTaxInclusive = true`: correct assignment after combo pre-tax resolution | Unit 1 | Phase 1 |
| AC-23 | Penny variance rule: Sales by Department uses original inclusive price, not rounded result | Unit 1 | Phase 1 |
| AC-11 | `GetMenuItems` returns `isTaxInclusive` bool on each product | Unit 2 | Phase 2 |
| AC-19 | `GetInventoryItem` / `GetProduct` returns `isTaxInclusive` bool on each product | Unit 2 | Phase 2 |

---

## Non-Functional Coverage by Unit

| NFR | Unit | Phase |
|-----|------|-------|
| NFR-2 Financial correctness (rounding AwayFromZero) | Unit 1 | Phase 1 |
| NFR-3 Performance (no extra DB roundtrips) | Unit 1 | Phase 1 |
| NFR-4 Observability (Logger.Error in calculation paths) | Unit 1 | Phase 1 |
| NFR-5 Security input validation (grossUnitPrice > 0) | Unit 1 | Phase 1 |
| NFR-6 Security exception handling (try-catch, fail closed) | Unit 1 | Phase 1 |
| NFR-7 Security access control (existing auth filters) | Unit 1 + 2 | Both |
| NFR-8 Security data integrity (GF_OrderLineItemTax preserved) | Unit 1 | Phase 1 |
| NFR-9 PBT — ResolvePreTaxUnitPrice invariant tests | Unit 1 | Phase 1 |
| NFR-10 Resiliency dependency isolation (DB timeouts) | Unit 1 | Phase 1 |
| NFR-1 Backward compatibility | Unit 1 + 2 | Both |

---

## Coverage Summary

| Unit | Acceptance Criteria | NFR Items | Total |
|------|---------------------|-----------|-------|
| Unit 1 — GolferWebAPI | 17 | 9 | 26 |
| Unit 2 — PosApi DTOs | 3 | 2 | 5 |
| **Total** | **19** | **9** | **28** |

All 19 acceptance criteria from PRD-020 are covered. (AC-1 is WPF — already complete; AC-5, AC-14, AC-18 are WPF-specific — already complete.)
