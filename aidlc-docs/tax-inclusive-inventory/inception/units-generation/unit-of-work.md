# Units of Work — tax-inclusive-inventory (CCD-20)

## Decomposition Summary

The feature decomposes into **2 units of work** mapped to the 2 existing RePIT phases. Both units operate on the `golfler_asp_2` repo. They are executed sequentially — Unit 2 branches from Unit 1's feature branch.

---

## Unit 1: GolferWebAPI OnDemand Tax-Inclusive Integration

| Field | Value |
|-------|-------|
| **Unit Name** | GolferWebAPI OnDemand Tax-Inclusive Integration |
| **RePIT Phase** | Phase 1 |
| **Repo** | `golfler_asp_2` |
| **Base Branch** | `release_5_4_41` |
| **Feature Branch** | `feature/tax-inclusive-inventory/phase-1` |
| **Complexity** | Moderate-High |
| **Risk** | High (revenue-impacting financial calculation path) |

### Scope
Add `ResolvePreTaxUnitPrice` helper and wire pre-tax reversal into `GetDiscountedItedOrdered` for both regular and combo items. Expose `IsTaxInclusive` in `OrderDetails2` response model and GolferWebAPI OpenAPI spec.

### Files
| File | Change Type |
|------|-------------|
| `GolferWebAPI/Models/OnDemand.cs` | Modify — new method + pre-tax reversal block |
| `GolflerDataModel/Models/OrderDetails.cs` | Modify — add `IsTaxInclusive` bool property |
| `docs/api/golferwebapi-openapi.json` | Modify — add `isTaxInclusive` to schema |

### Tasks (for RePIT)
- [x] 0.0 Create feature branch: `git checkout release_5_4_41`, `git checkout -b feature/tax-inclusive-inventory/phase-1`
- [ ] 1.0 Add `IsTaxInclusive` bool to `OrderDetails2` (OrderDetails.cs)
- [ ] 2.0 Add `ResolvePreTaxUnitPrice` private static helper to `OnDemand.cs`
- [ ] 3.0 Update regular item loop in `GetDiscountedItedOrdered` — pre-tax reversal block
- [ ] 4.0 Update combo sub-item loop in `GetDiscountedItedOrdered` — pre-tax reversal block
- [ ] 5.0 Update GolferWebAPI OpenAPI spec (`golferwebapi-openapi.json`)
- [ ] 6.0 Commit and push Phase 1 branch

### Human Tasks
- [ ] 5.2 Review OpenAPI spec diff and confirm accuracy
- Manual Postman verification: `isTaxInclusive = true` in response for tax-inclusive items
- Manual Postman verification: mixed cart totals correct (inclusive + exclusive items)

### Definition of Done
- `ResolvePreTaxUnitPrice` binary search matches WPF algorithm output
- Tax-exclusive items: zero behavioral change
- `OrderDetails2.isTaxInclusive = true` in `PreviewOnlyV2` response for inclusive items
- Committed + pushed to `feature/tax-inclusive-inventory/phase-1`

---

## Unit 2: PosApi Contract Additions

| Field | Value |
|-------|-------|
| **Unit Name** | PosApi Contract Additions |
| **RePIT Phase** | Phase 2 |
| **Repo** | `golfler_asp_2` |
| **Base Branch** | `feature/tax-inclusive-inventory/phase-1` |
| **Feature Branch** | `feature/tax-inclusive-inventory/phase-2` |
| **Complexity** | Low-Moderate |
| **Risk** | Medium (GolflerShared change — additive only but shared module) |

### Scope
Add `IsTaxInclusive` bool to `ProductList` (PosApi) and `BaseProduct` (GolflerShared) DTOs. Map from `item.GetIsTaxInclusive()`. Update PosApi OpenAPI spec.

### Files
| File | Change Type |
|------|-------------|
| `PosApi/Models/FoodBeverage.cs` | Modify — add `IsTaxInclusive` property + mapping |
| `GolflerShared/Modules/CourseProducts.cs` | Modify — add `IsTaxInclusive` property + mapping (STOP-AND-VERIFY: GolflerShared) |
| `docs/api/posapi-openapi.json` | Modify — add `isTaxInclusive` to schemas |

### Tasks (for RePIT)
- [ ] 0.0 Create Phase 2 branch: `git checkout feature/tax-inclusive-inventory/phase-1`, `git checkout -b feature/tax-inclusive-inventory/phase-2`
- [ ] 1.0 Add `IsTaxInclusive` bool to `ProductList` (FoodBeverage.cs) + map in `GetMenuItems`
- [ ] 2.0 Add `IsTaxInclusive` bool to `BaseProduct` (CourseProducts.cs) + map in `GetInventoryItem`
- [ ] 3.0 Update PosApi OpenAPI spec (`posapi-openapi.json`)
- [ ] 4.0 Commit and push Phase 2 branch

### Human Tasks
- [ ] 1.3 Postman verify: `GetMenuItems` returns `isTaxInclusive` bool on each product
- [ ] 2.3 Postman verify: `GetProduct`/`GetInventoryItem` returns `isTaxInclusive` bool
- [ ] 3.2 Review PosApi spec diff and confirm accuracy
- GolflerShared change approval: confirm additive-only, no breaking impact

### Definition of Done
- `isTaxInclusive` bool present in `GetMenuItems` and `GetInventoryItem` responses
- `BaseProduct.IsTaxInclusive` set correctly for tax-inclusive and tax-exclusive items
- Committed + pushed to `feature/tax-inclusive-inventory/phase-2`

---

## Looper Task Workspace

| Field | Value |
|-------|-------|
| **Task Workspace** | `RePIT-AIDLC-tax-inclusive-inventory-E1\` |
| **RePIT Document** | `RePIT-AIDLC-tax-inclusive-inventory-E1.md` |
| **Repo Clone (Phase 1 + 2)** | `RePIT-AIDLC-tax-inclusive-inventory-E1\golfler_asp_2\` |
| **Reference Repo (read-only)** | `looper-code-artifacts\stable-codebase\golfler_pos_2\` (WPF algorithm reference) |
