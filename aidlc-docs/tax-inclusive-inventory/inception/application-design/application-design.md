# Application Design — Consolidated

## Feature: tax-inclusive-inventory (CCD-20)

---

## Overview

CCD-20 wires the existing inventory-level `TaxInclusive` configuration into OnDemand mobile order calculations and exposes `IsTaxInclusive` in PosApi product DTOs. All work is in `golfler_asp_2`. WPF PosApp changes are already complete on branch `ccd-20-tax-inclusive-invenotry-3`.

The design decomposes into **two phases**:
- **Phase 1**: GolferWebAPI — pre-tax reversal in `GetDiscountedItedOrdered` + `IsTaxInclusive` in `OrderDetails2`
- **Phase 2**: PosApi — `IsTaxInclusive` bool in `ProductList` and `BaseProduct` DTOs

---

## Phase 1 Design: GolferWebAPI OnDemand Tax-Inclusive Integration

### What Changes

| Location | Change | Method |
|----------|--------|--------|
| `GolferWebAPI/Models/OnDemand.cs` | Add `ResolvePreTaxUnitPrice` private static helper | NEW |
| `GolferWebAPI/Models/OnDemand.cs` | Add pre-tax reversal block in regular item loop | MODIFY |
| `GolferWebAPI/Models/OnDemand.cs` | Add pre-tax reversal block in combo sub-item loop | MODIFY |
| `GolflerDataModel/Models/OrderDetails.cs:1106` | Add `IsTaxInclusive` bool property to `OrderDetails2` | MODIFY |
| `docs/api/golferwebapi-openapi.json` | Add `isTaxInclusive` bool to `OrderDetails2` schema | MODIFY |

### Calculation Sequence

```
For each item in GetDiscountedItedOrdered:

  Step 1: Load courseFoodItemDetail (existing)
  Step 2: Resolve discountedPrice / orderDetails.UnitPrice (existing)
  Step 3: [NEW] bool isTaxInclusive = courseFoodItemDetail.GetIsTaxInclusive()
  Step 4: [NEW] orderDetails.IsTaxInclusive = isTaxInclusive
  Step 5: [NEW] if isTaxInclusive AND TaxGroupId valid:
              taxGroupTaxes = load GF_TaxGroupTaxes for TaxGroupId
              orderDetails.UnitPrice = ResolvePreTaxUnitPrice(orderDetails.UnitPrice, taxGroupTaxes)
              // UnitListPrice already = courseFoodItemDetail.Price (original inclusive price)
  Step 6: Forward tax loop (existing) — runs on orderDetails.UnitPrice (now pre-tax for inclusive items)
  Step 7: Persist GF_OrderLineItemTax (existing, PlaceOrderV2 only)
```

### ResolvePreTaxUnitPrice Algorithm

Binary search (25 iterations, convergence guaranteed for financial amounts):
```
lo = 0; hi = grossUnitPrice
for i = 0..24:
    mid = (lo + hi) / 2
    recomputed = mid + Σ Math.Round(mid × rate / 100, 2, AwayFromZero)
                 for each row in taxGroupTaxes
    if recomputed < grossUnitPrice: lo = mid  else: hi = mid
return Math.Round(mid, 2, AwayFromZero)
```

Matches WPF `GetPreTaxAmount` exactly — verified by oracle PBT (advisory in partial mode).

### Security Constraints (Phase 1)
- SECURITY-05: `grossUnitPrice > 0` check before calling `ResolvePreTaxUnitPrice`
- SECURITY-15: Wrap reversal block in existing try-catch; log and fail with actionable error
- SECURITY-08: `PreviewOnlyV2` and `PlaceOrderV2` already have `ApiUserTokenMandatoryAuthorizationFilter` — do not remove
- SECURITY-13: `GF_OrderLineItemTax` write path unchanged — audit trail preserved

### PBT Requirements (Phase 1)
- FsCheck test project: add `FsCheck.xUnit` NuGet package
- PBT-03: `ResolvePreTaxUnitPrice(gross, rates)` — invariant: `result + Σ round(result × rate / 100, 2, AwayFromZero) ≈ gross` (tolerance $0.01)
- Generator: domain-appropriate decimals in range [0.01, 999.99], tax rates [0.1, 30.0]

---

## Phase 2 Design: PosApi Contract Additions

### What Changes

| Location | Change | Method |
|----------|--------|--------|
| `PosApi/Models/FoodBeverage.cs:2677` | Add `IsTaxInclusive` bool to `ProductList` class | MODIFY |
| `PosApi/Models/FoodBeverage.cs` | Set `IsTaxInclusive = item.GetIsTaxInclusive()` in `GetMenuItems` mapping | MODIFY |
| `GolflerShared/Modules/CourseProducts.cs:210` | Add `IsTaxInclusive` bool to `BaseProduct` class | MODIFY |
| `GolflerShared/Modules/CourseProducts.cs:3564` | Set `IsTaxInclusive = product.GetIsTaxInclusive()` in `GetInventoryItem` | MODIFY |
| `docs/api/posapi-openapi.json` | Add `isTaxInclusive` bool to product/inventory schemas | MODIFY |

### GolflerShared Risk Note
`BaseProduct` in `GolflerShared/Modules/CourseProducts.cs` — change is additive-only (new bool field with no behavioral impact on existing consumers). Pre-approved in PRD scope. Stop-and-verify before applying: confirm no other projects consume `BaseProduct` in a way that would break with an extra field.

### Backward Compatibility
All DTO additions are additive (`bool` with default `false`). Mobile apps, WPF PosApp, and Angular CCOnline treat missing/null field as `false` (tax-exclusive — existing behavior unchanged).

---

## Cross-Cutting Design Constraints

### Multi-Tenant Safety (SECURITY-05, existing rule)
`GetIsTaxInclusive()` is called on `courseFoodItemDetail` which is loaded from `GF_CourseFoodItemDetail` already filtered by `clubId`/`CourseId`. No additional tenant-safety work needed.

### Financial Correctness (NFR-2)
- Rounding: `MidpointRounding.AwayFromZero`, 2 decimal places — consistent with WPF and PRD spec
- No new tax formula introduced — CCD-20 uses the existing forward tax loop with corrected input price
- Sales reporting: original inclusive price preserved in `UnitListPrice` for sales-value reporting

### No Behavioral Changes for Tax-Exclusive Items
The conditional `if isTaxInclusive` block means that for all existing tax-exclusive items, code execution is identical to before CCD-20. Zero regression risk on that path.

---

## Files Changed Summary

### Phase 1 (golfler_asp_2)
- `GolferWebAPI/Models/OnDemand.cs` — +1 new method, +~30 lines in `GetDiscountedItedOrdered`
- `GolflerDataModel/Models/OrderDetails.cs` — +1 property (3 lines)
- `docs/api/golferwebapi-openapi.json` — +1 field in schema

### Phase 2 (golfler_asp_2, from Phase 1 branch)
- `PosApi/Models/FoodBeverage.cs` — +1 property + 1 mapping line
- `GolflerShared/Modules/CourseProducts.cs` — +1 property + 1 mapping line
- `docs/api/posapi-openapi.json` — +1 field in schema

**Total**: ~6 source files, ~50–80 lines new/modified code, 2 OpenAPI spec updates.
Well within the 300-line / 5-file Looper safety threshold.
