# Application Design — Services

## Feature: tax-inclusive-inventory (CCD-20)

## Note on Service Layer

The Golfler platform is a monolithic ASP.NET application. There is no separate service layer — business logic is embedded directly in model classes (e.g., `OnDemand.cs`) and shared modules (`GolflerShared`). This is an intentional constraint of the legacy codebase. CCD-20 follows the same pattern.

---

## Service 1: OnDemand Order Processing Service

**Location**: `GolferWebAPI/Models/OnDemand.cs` (model class acting as service)
**Pattern**: Fat model — orchestrates DB access, calculation, and response building

### Service Responsibilities
- Orchestrate the full OnDemand order lifecycle: item lookup → price resolution → tax calculation → response building
- For tax-inclusive items: resolve effective pre-tax unit price before running forward tax loop
- Serve both `PreviewOnlyV2` (read-only) and `PlaceOrderV2` (create order in DB)

### Service Interactions
```
OnDemand Service
    |
    +---> GF_CourseFoodItemDetail (DB read) — item config including TaxInclusive
    +---> GF_TaxGroupTaxes (DB read) — tax rates per item
    +---> ResolvePreTaxUnitPrice (local pure function) — pre-tax reversal
    +---> GF_OrderLineItemTax (DB write — PlaceOrderV2 path only)
    +---> GF_Order, GF_OrderLineItem (DB write — PlaceOrderV2 path only)
```

### CCD-20 Addition
Adds inline pre-tax reversal step for tax-inclusive items between "item load" and "forward tax loop." No external service calls added — `ResolvePreTaxUnitPrice` is a local pure function.

---

## Service 2: Course Products Service

**Location**: `GolflerShared/Modules/CourseProducts.cs`
**Pattern**: Shared module — provides product catalog operations for PosApi consumers

### Service Responsibilities
- Retrieve and map inventory item details from `GF_CourseFoodItemDetail` to `BaseProduct` DTO
- Map `TaxInclusive` string to effective `IsTaxInclusive` bool via `GetIsTaxInclusive()`
- Serve `GetMenuItems` and `GetInventoryItem` PosApi endpoints

### Service Interactions
```
CourseProducts Service
    |
    +---> GF_CourseFoodItemDetail (DB read) — product catalog
    +---> CourseFoodItemDetail.GetIsTaxInclusive() (model method) — bool resolution
    +---> BaseProduct DTO (output)
```

### CCD-20 Addition
Maps `IsTaxInclusive = product.GetIsTaxInclusive()` in the `GetInventoryItem` mapping block alongside existing `TaxInclusive = product.TaxInclusive`.

---

## Service 3: Tax Calculation Engine (Existing — Reference)

**Location**: `GolferWebAPI/Models/OnDemand.cs` (embedded in `GetDiscountedItedOrdered`)
**Pattern**: Forward tax loop per `GF_TaxGroupTaxes` row

### Service Responsibilities
- Compute per-tax-row tax amount: `Math.Round(unitPrice × tax.Percentage / 100, 2, AwayFromZero) × quantity`
- Sum all tax rows to produce line-level `TaxAmount`
- Write `GF_OrderLineItemTax` records per tax row (PlaceOrderV2 path)

### CCD-20 Interaction
- No changes to the forward tax loop itself
- CCD-20 pre-tax reversal runs BEFORE this loop, providing `orderDetails.UnitPrice` as the correct pre-tax base
- Forward loop operates on `orderDetails.UnitPrice` unchanged — it just now receives the pre-tax value for inclusive items

---

## OpenAPI Spec Maintenance

Both API specs act as service contracts for downstream consumers:

| Spec File | Change | Consumer Impact |
|-----------|--------|----------------|
| `docs/api/golferwebapi-openapi.json` | Add `isTaxInclusive` bool to `OrderDetails2` schema | Mobile apps: iOS, Android can read flag |
| `docs/api/posapi-openapi.json` | Add `isTaxInclusive` bool to product/inventory schemas | Angular CCOnline, future mobile POS |
