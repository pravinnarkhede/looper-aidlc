# Application Design — Components

## Feature: tax-inclusive-inventory (CCD-20)

---

## Component 1: OnDemand Order Calculation Engine

**File**: `GolferWebAPI/Models/OnDemand.cs`
**Type**: Server-side calculation engine (method in model class)

### Purpose
Calculates prices, discounts, and taxes for all items in an OnDemand (mobile) food/beverage order. Both `PreviewOnlyV2` and `PlaceOrderV2` delegate to this component.

### Responsibilities
- Load `CourseFoodItemDetail` per item (including `TaxInclusive` field)
- Resolve `IsTaxInclusive` effective boolean per item via `GetIsTaxInclusive()`
- Apply pre-tax reversal for tax-inclusive items (CCD-20 addition)
- Run forward tax calculation loop per `GF_TaxGroupTaxes` row
- Handle combo item expansion and per-sub-item tax calculation
- Populate `OrderDetails2` list with `UnitPrice`, `TaxAmount`, `LineTotalWithTax`, `IsTaxInclusive`
- Persist `GF_OrderLineItemTax` records (via `PlaceOrderV2` path)

### Interfaces
- **Entry**: Called by `PreviewOnlyV2` and `PlaceOrderV2` with `(clubId, OnDemandOrderRequest)`
- **Output**: `List<OrderDetails2>` with fully-computed pricing and tax per item

### CCD-20 Changes
- Add `ResolvePreTaxUnitPrice` private static helper
- Add `IsTaxInclusive` resolution and pre-tax reversal block per regular item
- Add combo sub-item pre-tax reversal block
- Set `orderDetails.IsTaxInclusive` per item

---

## Component 2: Pre-Tax Unit Price Resolver

**File**: `GolferWebAPI/Models/OnDemand.cs` (new private static method)
**Type**: Pure computation function (no I/O, no state)

### Purpose
Back-calculates the pre-tax unit price from an inclusive (sticker) selling price and the item's applicable tax group rates. Used only for tax-inclusive items.

### Responsibilities
- Accept `grossUnitPrice` (decimal) and `taxGroupTaxes` (List<GF_TaxGroupTaxes>)
- Execute 25-iteration binary search to find `preTaxPrice` satisfying: `preTaxPrice + Σ round(preTaxPrice × rate / 100, 2, AwayFromZero) ≈ grossUnitPrice`
- Return `grossUnitPrice` unchanged when `taxGroupTaxes` is null or empty (safe default)
- Round final result to 2 decimal places with `MidpointRounding.AwayFromZero`

### Interfaces
- **Signature**: `private static decimal ResolvePreTaxUnitPrice(decimal grossUnitPrice, List<GF_TaxGroupTaxes> taxGroupTaxes)`
- **Pure function**: No side effects, no DB calls, idempotent

### CCD-20 Changes
- New method — does not exist yet in `GolferWebAPI` (WPF equivalent is in `golfler_pos_2`)

---

## Component 3: OrderDetails2 Response Model

**File**: `GolflerDataModel/Models/OrderDetails.cs` (lines 1106–1119)
**Type**: Data Transfer Object (response model)

### Purpose
Carries per-line pricing and tax details from the OnDemand calculation engine back to the mobile caller. Represents one order line item in the `PreviewOnlyV2` / `PlaceOrderV2` response.

### Responsibilities
- Hold `UnitListPrice` (original inclusive price — for sticker display)
- Hold `UnitPrice` (effective price used for tax calculation — pre-tax base for inclusive items)
- Hold `TaxAmount`, `LineTotalWithTax`, `Quantity`
- Expose `IsTaxInclusive` bool so mobile app knows the tax mode

### CCD-20 Changes
- Add `public bool IsTaxInclusive { get; set; }` property

---

## Component 4: PosApi Product DTOs

**Files**:
- `PosApi/Models/FoodBeverage.cs:2677–2709` (`ProductList` class)
- `GolflerShared/Modules/CourseProducts.cs:210–270` (`BaseProduct` class)
**Type**: Data Transfer Objects (API response models)

### Purpose
Serve product catalog data to POS terminal (at login via `GetMenuItems`) and individual product lookups (via `GetInventoryItem`). Angular CCOnline and future mobile POS consumers depend on these for knowing whether an item is tax-inclusive before order creation.

### Responsibilities
- `ProductList` (FoodBeverage.cs): Represents one product in the `GetMenuItems` catalog list. Must expose `IsTaxInclusive` for POS terminal to pre-resolve tax mode at load time.
- `BaseProduct` (CourseProducts.cs): Represents a single inventory item in `GetInventoryItem`. Must expose `IsTaxInclusive` alongside the existing `TaxInclusive` string field.

### CCD-20 Changes
- `ProductList`: Add `public bool IsTaxInclusive { get; set; }` and map `= item.GetIsTaxInclusive()`
- `BaseProduct`: Add `public bool IsTaxInclusive { get; set; }` and map `= product.GetIsTaxInclusive()` in `GetInventoryItem`

**Note**: `BaseProduct` is in `GolflerShared` — a high-risk shared module. Change is additive-only (new bool field). Pre-approved by PRD scope. Stop-and-verify before executing.

---

## Component 5: CourseFoodItemDetail Model Extension

**File**: `GolflerDataModel/Models/CourseFoodItemDetail.cs` (line 14)
**Type**: EF Entity partial class extension

### Purpose
Extends the Entity Framework `GF_CourseFoodItemDetail` entity with the `GetIsTaxInclusive()` computed property. Converts the stored `TaxInclusive` string (`Inherit`/`True`/`False`) to an effective boolean for use in order calculations.

### Responsibilities
- `GetIsTaxInclusive()`: Resolves `TaxInclusive` string to `bool IsTaxInclusive`
  - `"True"` → `true`
  - `"False"` → `false`
  - `"Inherit"` → resolve per defined fallback logic (course-level or system default)

### CCD-20 Changes
- **None** — `GetIsTaxInclusive()` is already implemented. Read-only reference.
