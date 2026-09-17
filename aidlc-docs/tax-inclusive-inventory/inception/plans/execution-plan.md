# Execution Plan — tax-inclusive-inventory (CCD-20)

## Detailed Analysis Summary

### Transformation Scope
- **Type**: Single-component enhancement within existing brownfield monolith
- **Primary Changes**: Add pre-tax reversal logic to `GetDiscountedItedOrdered`; expose `IsTaxInclusive` bool in PosApi DTOs
- **Related Components**: `GolferWebAPI/OnDemand.cs`, `GolflerDataModel/OrderDetails.cs`, `GolflerShared/CourseProducts.cs`, `PosApi/FoodBeverage.cs`

### Change Impact Assessment

| Area | Impact | Description |
|------|--------|-------------|
| User-facing changes | No | Server-side calculation change; mobile app sees new `isTaxInclusive` bool (additive) |
| Structural changes | No | No new projects, controllers, or routes introduced |
| Data model changes | Additive only | `IsTaxInclusive` bool added to DTOs; no DB schema changes |
| API changes | Additive only | New bool field on existing response models — no breaking changes |
| NFR impact | Low | No performance degradation (pure in-memory binary search); enhanced observability via existing Logger |

### Component Relationships

```
PreviewOnlyV2 / PlaceOrderV2 (GolferWebAPI)
        |
        v
GetDiscountedItedOrdered (OnDemand.cs) [CHANGE — pre-tax reversal]
        |
        +---> ResolvePreTaxUnitPrice (OnDemand.cs) [NEW helper]
        |
        +---> CourseFoodItemDetail.GetIsTaxInclusive() [EXISTING — read-only]
        |
        +---> OrderDetails2 (GolflerDataModel) [CHANGE — +IsTaxInclusive field]
        |
        +---> GF_OrderLineItemTax (DB) [UNCHANGED — existing write path]

GetMenuItems (PosApi)
        |
        v
ProductList DTO (FoodBeverage.cs) [CHANGE — +IsTaxInclusive field]

GetInventoryItem (PosApi / GolflerShared)
        |
        v
BaseProduct (CourseProducts.cs) [CHANGE — +IsTaxInclusive field]
```

### Risk Assessment

| Dimension | Level | Reason |
|-----------|-------|--------|
| Overall Risk | High | Financial calculation path in live production system; no automated test coverage |
| Rollback Complexity | Moderate | Additive-only changes; revert = remove new field + pre-tax block |
| Testing Complexity | Complex | Manual testing required; no test harness; financial math correctness critical |
| Blast Radius | Moderate | Both `PreviewOnlyV2` and `PlaceOrderV2` use same engine; incorrect math = wrong billing |

---

## Workflow Visualization

```
Start (CCD-20 Request)
    |
    +--[x]--> Workspace Detection (COMPLETE)
    |
    +--[x]--> Reverse Engineering (COMPLETE — from PRD + CLAUDE.md)
    |
    +--[x]--> Requirements Analysis (COMPLETE)
    |
    +--[SKIP]--> User Stories (SKIP — technical server-side feature)
    |
    +--[x]--> Workflow Planning (this document)
    |
    +--[EXECUTE]--> Application Design
    |
    +--[EXECUTE]--> Units Generation
    |
    +--[EXECUTE]--> Construction via Looper
    |               /looper-plan (all units → single RePIT)
    |               /looper-implement (phase 1 → phase 2)
    |
    +--[EXECUTE]--> Build and Test
    |
    End
```

---

## Phases to Execute

### INCEPTION PHASE

- [x] Workspace Detection — COMPLETE
  - Brownfield detected; partial implementation in `tax-inclusive-inventory\`
- [x] Reverse Engineering — COMPLETE
  - Artifacts at `aidlc-docs\reverse-engineering\` (shared)
  - Derived from PRD-020 + CLAUDE.md + existing RePIT
- [x] Requirements Analysis — COMPLETE
  - See `requirements.md` — from PRD-020 + extension configurations
  - Security: Full enforcement; PBT: Partial; Resiliency: Directional
- [ ] User Stories — SKIP
  - Rationale: Pure server-side enhancement; no new user personas; acceptance criteria in PRD-020 cover all behavioral requirements
- [x] Workflow Planning — IN PROGRESS (this document)
- [ ] Application Design — EXECUTE
  - Rationale: New method (`ResolvePreTaxUnitPrice`), new fields on multiple DTOs, and cross-project component changes require explicit design documentation
- [ ] Units Generation — EXECUTE
  - Rationale: Two distinct units (GolferWebAPI + PosApi), different project boundaries, sequential dependency (Phase 2 branches from Phase 1)

### CONSTRUCTION PHASE (via Looper)

- [ ] /looper-plan — EXECUTE
  - Create single RePIT for all units: `RePIT-AIDLC-tax-inclusive-inventory-E1\`
  - AIDLC units map to RePIT phases — AIDLC design artifacts passed as context
  - Reduces Step 2 (Research & Discovery) significantly — PRD + RE artifacts cover it
- [ ] /looper-implement — EXECUTE
  - Phase 1: GolferWebAPI changes (OnDemand.cs, OrderDetails.cs, golferwebapi-openapi.json)
  - Phase 2: PosApi changes (FoodBeverage.cs, CourseProducts.cs, posapi-openapi.json)
  - Each phase: commit + push before next phase starts
- [ ] Build and Test — EXECUTE
  - Manual MSBuild verification
  - Postman testing for both phases
  - FsCheck PBT tests for `ResolvePreTaxUnitPrice`

### OPERATIONS PHASE

- [ ] Operations — PLACEHOLDER (future deployment and monitoring workflows)

---

## Package Change Sequence

| Order | Package/File | Dependency Constraint |
|-------|-------------|----------------------|
| 1 | `GolflerDataModel/Models/OrderDetails.cs` | Must be done first — Phase 1 depends on `OrderDetails2.IsTaxInclusive` |
| 2 | `GolferWebAPI/Models/OnDemand.cs` | Depends on #1 (`OrderDetails2.IsTaxInclusive`) |
| 3 | `docs/api/golferwebapi-openapi.json` | After #2 (Phase 1 complete) |
| 4 | `GolflerShared/Modules/CourseProducts.cs` | Phase 2 — independent of Phase 1 DTOs |
| 5 | `PosApi/Models/FoodBeverage.cs` | After #4 (`GetIsTaxInclusive` available) |
| 6 | `docs/api/posapi-openapi.json` | After #5 (Phase 2 complete) |

---

## Estimated Timeline

- **Total Phases**: 2 (Looper construction phases)
- **Total Files Changed**: ~6 source files + 2 OpenAPI specs
- **Phase 1 Complexity**: Moderate-High (binary search algorithm, calculation logic)
- **Phase 2 Complexity**: Low-Moderate (additive DTO fields only)

---

## Success Criteria

- **Primary Goal**: Mobile golfers see correct pre-tax / tax split for tax-inclusive items in OnDemand orders
- **Key Deliverables**:
  1. `ResolvePreTaxUnitPrice` implemented with correct binary search algorithm
  2. `GetDiscountedItedOrdered` applies reversal for tax-inclusive regular + combo items
  3. `OrderDetails2.IsTaxInclusive` bool exposed in GolferWebAPI response
  4. `ProductList.IsTaxInclusive` and `BaseProduct.IsTaxInclusive` exposed in PosApi
  5. OpenAPI specs updated for both APIs
  6. All Phase 1 + Phase 2 changes committed + pushed
- **Quality Gates**:
  - Pre-tax reversal matches WPF `GetPreTaxAmount` output for identical inputs
  - Tax-exclusive items: zero behavioral change (regression free)
  - Mixed carts: correct totals (inclusive + exclusive items)
  - FsCheck PBT: `ResolvePreTaxUnitPrice` invariant tests pass
  - Manual Postman: `isTaxInclusive = true` in response for inclusive items
