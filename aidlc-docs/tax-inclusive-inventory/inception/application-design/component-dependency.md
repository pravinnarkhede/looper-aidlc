# Application Design — Component Dependencies

## Feature: tax-inclusive-inventory (CCD-20)

---

## Dependency Matrix

| Component | Depends On | Communication | Type |
|-----------|-----------|--------------|------|
| OnDemand Calculation Engine | CourseFoodItemDetail Model Extension | Direct method call: `GetIsTaxInclusive()` | Runtime |
| OnDemand Calculation Engine | Pre-Tax Unit Price Resolver | Direct method call: `ResolvePreTaxUnitPrice(gross, taxRates)` | Compile-time |
| OnDemand Calculation Engine | OrderDetails2 Response Model | Sets properties: `IsTaxInclusive`, `UnitPrice`, `UnitListPrice` | Compile-time |
| OnDemand Calculation Engine | GF_TaxGroupTaxes (DB) | EF query within `GetDiscountedItedOrdered` | Runtime (DB) |
| Course Products Service | CourseFoodItemDetail Model Extension | Direct method call: `GetIsTaxInclusive()` | Runtime |
| PosApi Product DTOs | Course Products Service | Mapping in `GetInventoryItem` | Compile-time |
| Pre-Tax Unit Price Resolver | GF_TaxGroupTaxes (data only) | List passed as parameter — no DB call inside | Parameter |

---

## Dependency Diagram

```
PHASE 1 SCOPE (golfler_asp_2 — GolferWebAPI changes)
+------------------------------------------------------------+
|                                                            |
|  PreviewOnlyV2 / PlaceOrderV2 (API controllers)           |
|           |                                               |
|           v                                               |
|  GetDiscountedItedOrdered (OnDemand.cs)                   |
|           |                                               |
|     +-----+------+---------------------+                  |
|     |            |                     |                  |
|     v            v                     v                  |
|  GetIsTaxInclusive()  ResolvePreTaxUnitPrice   Forward    |
|  (CourseFoodItemDetail)  (NEW — OnDemand.cs)   Tax Loop   |
|                              |                  |         |
|                              v                  v         |
|                         GF_TaxGroupTaxes     GF_OrderLine |
|                         (list param)         ItemTax (DB) |
|                                                            |
|  OrderDetails2 (GolflerDataModel)                         |
|  + IsTaxInclusive (NEW)                                   |
|  + UnitPrice (overridden to pre-tax for inclusive items)  |
|  + UnitListPrice (original inclusive price — unchanged)   |
|                                                            |
+------------------------------------------------------------+

PHASE 2 SCOPE (golfler_asp_2 — PosApi changes)
+------------------------------------------------------------+
|                                                            |
|  GetMenuItems (PosApi controller)                         |
|           |                                               |
|           v                                               |
|  ProductList (FoodBeverage.cs)                            |
|  + IsTaxInclusive (NEW) = item.GetIsTaxInclusive()        |
|                                                            |
|  GetInventoryItem (CourseProducts.cs — GolflerShared)     |
|           |                                               |
|           v                                               |
|  BaseProduct (CourseProducts.cs)                          |
|  + IsTaxInclusive (NEW) = product.GetIsTaxInclusive()     |
|  + TaxInclusive (existing — preserved)                    |
|                                                            |
+------------------------------------------------------------+

SHARED (no changes)
+------------------------------------------------------------+
|  GolflerDataModel                                         |
|  - CourseFoodItemDetail.cs — GetIsTaxInclusive() (exists) |
|  - GF_CourseFoodItemDetail.cs — TaxInclusive col (exists) |
+------------------------------------------------------------+
```

---

## Inter-Phase Dependency

```
Phase 1 (GolferWebAPI)
    |
    | Must complete + push before Phase 2 starts
    | (OrderDetails2.IsTaxInclusive available for reference)
    v
Phase 2 (PosApi)
    |
    | Branches from Phase 1 branch:
    | git checkout feature/tax-inclusive-inventory/phase-1
    | git checkout -b feature/tax-inclusive-inventory/phase-2
    v
Both branches merged (separate PRs or sequential merge)
```

---

## Communication Patterns

| Pattern | Where Used | Description |
|---------|-----------|-------------|
| Direct in-process method call | `ResolvePreTaxUnitPrice` | Pure function, no I/O, called inline |
| EF entity property | `GetIsTaxInclusive()` on `CourseFoodItemDetail` | Partial method reads `this.TaxInclusive` |
| DTO field assignment | `orderDetails.IsTaxInclusive = isTaxInclusive` | Set on response model during calculation |
| EF query | Load `GF_TaxGroupTaxes` for pre-tax reversal | Uses existing `GolflerDataModelEntities` context |

---

## Risk Notes

| Dependency | Risk | Mitigation |
|-----------|------|------------|
| `BaseProduct` in GolflerShared | High — affects all projects consuming GolflerShared | Change is additive-only (new bool field); stop-and-verify before applying |
| `GF_TaxGroupTaxes` load for pre-tax reversal | Low — tax rates already loaded in `GetDiscountedItedOrdered` | Verify no duplicate DB roundtrip introduced |
| `OrderDetails2` field addition | Low — additive; mobile treats missing as false | Verify no existing serialization breaks field order |
