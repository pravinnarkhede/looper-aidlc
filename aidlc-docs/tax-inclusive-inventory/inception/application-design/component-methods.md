# Application Design — Component Methods

## Feature: tax-inclusive-inventory (CCD-20)

---

## Component 1: OnDemand Order Calculation Engine (`OnDemand.cs`)

### GetDiscountedItedOrdered (existing — modified)

**Signature** (existing, not changed):
```
private List<OrderDetails2> GetDiscountedItedOrdered(int clubId, List<OnDemandItem> items)
```

**CCD-20 Modifications** (within existing method body):

```
// Per regular item — NEW block after loading courseFoodItemDetail and resolving discountedPrice:
bool isTaxInclusive = courseFoodItemDetail.GetIsTaxInclusive()
orderDetails.IsTaxInclusive = isTaxInclusive
if isTaxInclusive AND TaxGroupId is valid:
    taxGroupTaxes = load GF_TaxGroupTaxes for item's TaxGroupId
    orderDetails.UnitPrice = ResolvePreTaxUnitPrice(orderDetails.UnitPrice, taxGroupTaxes)
    // UnitListPrice already holds courseFoodItemDetail.Price (original inclusive — no change needed)

// Per combo sub-item — NEW block after resolving comboOrderDetail.Amount:
bool comboIsTaxInclusive = comboCourseFooditemDetail.GetIsTaxInclusive()
if comboIsTaxInclusive AND TaxGroupId is valid:
    comboTaxGroupTaxes = load GF_TaxGroupTaxes for combo item's TaxGroupId
    preTaxUnitPrice = ResolvePreTaxUnitPrice(comboOrderDetail.Amount / comboQty, comboTaxGroupTaxes)
    comboOrderDetail.Amount = preTaxUnitPrice * comboQty
```

**Input**: `clubId` (int), `items` (List<OnDemandItem>)
**Output**: `List<OrderDetails2>` — each element has `UnitPrice` = pre-tax base (for inclusive) or original price (for exclusive)
**Business Rule**: Pre-tax reversal runs only when `IsTaxInclusive = true`. Tax-exclusive path completely unchanged.

---

## Component 2: Pre-Tax Unit Price Resolver (`OnDemand.cs` — new)

### ResolvePreTaxUnitPrice (new)

**Signature**:
```
private static decimal ResolvePreTaxUnitPrice(
    decimal grossUnitPrice,
    List<GF_TaxGroupTaxes> taxGroupTaxes)
```

**Algorithm**:
```
if taxGroupTaxes == null or empty: return grossUnitPrice

lo = 0, hi = grossUnitPrice
for 25 iterations:
    mid = (lo + hi) / 2
    computedGross = mid + Σ Math.Round(mid * tax.GF_Tax.Percentage / 100, 2, AwayFromZero)
                         for each tax in taxGroupTaxes
    if computedGross < grossUnitPrice: lo = mid
    else: hi = mid

return Math.Round(mid, 2, MidpointRounding.AwayFromZero)
```

**Input**:
- `grossUnitPrice`: decimal — the inclusive selling price (must be positive)
- `taxGroupTaxes`: List<GF_TaxGroupTaxes> — the applicable tax rows for this item's tax group

**Output**: decimal — the pre-tax unit price (2 decimal places, AwayFromZero)

**Business Rule**: When `taxGroupTaxes` is null or empty, return `grossUnitPrice` unchanged (no tax reversal possible, treat as tax-exclusive)

**Security** (SECURITY-05): Caller validates `grossUnitPrice > 0` before calling this method

**PBT Invariant** (PBT-03): For all valid inputs, `ResolvePreTaxUnitPrice(gross) + Σ round(result × rate / 100, 2) ≈ gross` within $0.01

---

## Component 3: OrderDetails2 Response Model (`OrderDetails.cs`)

### IsTaxInclusive property (new)

**Signature**:
```
public bool IsTaxInclusive { get; set; }
```

**Purpose**: Signals to the mobile app whether this line item used tax-inclusive pricing.

**Usage**:
- `true`: `UnitPrice` is the pre-tax base; `UnitListPrice` is the sticker price
- `false` (default): `UnitPrice` is the direct selling price (existing behavior)

---

## Component 4: PosApi Product DTOs

### ProductList.IsTaxInclusive (new field in FoodBeverage.cs)

**Signature**:
```
public bool IsTaxInclusive { get; set; }
```

**Mapping in GetMenuItems**:
```
IsTaxInclusive = item.GetIsTaxInclusive()
```

### BaseProduct.IsTaxInclusive (new field in CourseProducts.cs)

**Signature**:
```
public bool IsTaxInclusive { get; set; }
```

**Mapping in GetInventoryItem** (alongside existing TaxInclusive mapping at ~line 3564):
```
IsTaxInclusive = product.GetIsTaxInclusive(),
TaxInclusive = product.TaxInclusive  // existing — keep
```

---

## Component 5: CourseFoodItemDetail (existing — no changes)

### GetIsTaxInclusive (existing, reference only)

**Signature**:
```
public bool GetIsTaxInclusive()
```

**Location**: `GolflerDataModel/Models/CourseFoodItemDetail.cs:14`

**Logic** (already implemented):
- `"True"` → returns `true`
- `"False"` → returns `false`
- `"Inherit"` → resolved to effective bool per course-level configuration

**No CCD-20 changes.** Referenced by all calculation paths.
