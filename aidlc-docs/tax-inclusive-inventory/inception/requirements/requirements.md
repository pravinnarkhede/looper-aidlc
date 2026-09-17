# Requirements — tax-inclusive-inventory (CCD-20)

## Intent Analysis

| Field | Value |
|-------|-------|
| **Request** | Wire existing `TaxInclusive` inventory configuration into OnDemand order calculations and expose `IsTaxInclusive` bool in PosApi product DTOs |
| **Request Type** | Enhancement — brownfield, partial implementation already complete |
| **Scope** | Multiple files across 2 projects (GolferWebAPI, PosApi) in `golfler_asp_2` repo |
| **Complexity** | Moderate — financial calculation path in production revenue system |
| **Partial Implementation** | WPF PosApp (golfler_pos_2) COMPLETE on `ccd-20-tax-inclusive-invenotry-3`. Algorithm reference available. |
| **Jira** | CCD-20 |

## Extension Configuration

| Extension | Mode | Enforced Rules |
|-----------|------|---------------|
| Security Baseline | Full (A) | SECURITY-01 through SECURITY-15 |
| Property-Based Testing | Partial (B) | PBT-02, PBT-03, PBT-07, PBT-08, PBT-09 |
| Resiliency Baseline | Directional (A) | Full rules — many N/A for on-prem brownfield |
| Looper | Always-on | All construction phase rules |

---

## Functional Requirements

### FR-1: Product-Level Tax-Inclusive Configuration
- `TaxInclusive` (string: `Inherit`/`True`/`False`) is an existing inventory add/edit field on `GF_CourseFoodItemDetail` — not changed by CCD-20.
- `IsTaxInclusive` is the effective boolean resolved at order time via `GetIsTaxInclusive()` (already implemented).
- Order calculation logic shall use `IsTaxInclusive` as authoritative; if both `TaxInclusive` and `IsTaxInclusive` are in a payload, use `IsTaxInclusive`.

### FR-2: Pre-Tax Reversal in OnDemand Calculation
- In `GetDiscountedItedOrdered` (`GolferWebAPI/Models/OnDemand.cs:4282–4978`), for each item where `GetIsTaxInclusive() = true`:
  - Back-calculate the pre-tax unit price from the inclusive selling price using `ResolvePreTaxUnitPrice`.
  - Override `orderDetails.UnitPrice` with the pre-tax result.
  - Retain `orderDetails.UnitListPrice` as the original inclusive price (for mobile display as sticker price).
- Pre-tax reversal is applied ONLY when `IsTaxInclusive = true`; tax-exclusive items are completely unchanged.

### FR-3: Pre-Tax Reversal Algorithm
- `ResolvePreTaxUnitPrice(decimal grossUnitPrice, List<GF_TaxGroupTaxes> taxGroupTaxes)` — new private static helper in `OnDemand.cs`.
- Algorithm: 25-iteration binary search to find `mid` such that `mid + Σ Math.Round(mid × tax.Percentage / 100, 2, MidpointRounding.AwayFromZero) ≈ grossUnitPrice`.
- Rounding: `MidpointRounding.AwayFromZero`, 2 decimal places — matches WPF implementation.
- Return `grossUnitPrice` unchanged if `taxGroupTaxes` is empty or null.
- Multi-tax groups: iterate all tax rows in group for both reversal binary search and forward tax loop.

### FR-4: Combo Item Pre-Tax Reversal
- For combo sub-items in `GetDiscountedItedOrdered` (~lines 4773–4808): apply the same `ResolvePreTaxUnitPrice` to each sub-item where `GetIsTaxInclusive() = true`.
- Override `comboOrderDetail.Amount` with `preTaxUnitPrice × comboQty`.
- Forward combo tax loop already operates on `comboOrderDetail.Amount` — this ensures it uses the correct pre-tax base.

### FR-5: IsTaxInclusive Exposed in OnDemand Response
- `OrderDetails2` (`GolflerDataModel/Models/OrderDetails.cs:1106–1119`) shall gain `public bool IsTaxInclusive { get; set; }`.
- Set `orderDetails.IsTaxInclusive = isTaxInclusive` per item during `GetDiscountedItedOrdered`.
- Mobile app uses this flag to display tax mode correctly.

### FR-6: PlaceOrderV2 Correctness
- `PlaceOrderV2` calls the same `GetDiscountedItedOrdered` engine and overwrites order totals from that output (lines 4044–4052).
- No separate `PlaceOrderV2` changes needed — pre-tax reversal fix is inherited automatically.

### FR-7: IsTaxInclusive in PosApi ProductList DTO
- `PosApi/Models/FoodBeverage.cs:2677–2709` (`ProductList` class): add `public bool IsTaxInclusive { get; set; }`.
- In `GetMenuItems` mapping: set `IsTaxInclusive = item.GetIsTaxInclusive()`.

### FR-8: IsTaxInclusive in BaseProduct / GetInventoryItem
- `GolflerShared/Modules/CourseProducts.cs:210–270` (`BaseProduct` class): add `public bool IsTaxInclusive { get; set; }`.
- In `GetInventoryItem` (~lines 3490–3568): map `IsTaxInclusive = product.GetIsTaxInclusive()` alongside existing `TaxInclusive = product.TaxInclusive`.
- **Note**: GolflerShared change — pre-approved in PRD (additive bool field, no breaking impact).

### FR-9: OpenAPI Spec Updates
- `docs/api/golferwebapi-openapi.json`: add `isTaxInclusive` bool field to `OrderDetails2` response schema.
- `docs/api/posapi-openapi.json`: add `isTaxInclusive` bool field to product/inventory response schemas.

### FR-10: Tax-Exclusive Behavior Unchanged
- When `IsTaxInclusive = false` (or `Inherit` resolves to false), zero changes to existing order calculation path.
- Existing products and historical orders remain unaffected.

### FR-11: Multi-Tenant Safety
- All `GetIsTaxInclusive()` calls are scoped by `clubId`/`CourseId` via the existing `CourseFoodItemDetail` load query — no cross-tenant leakage.

---

## Non-Functional Requirements

### NFR-1: Backward Compatibility (Critical)
- Additive-only changes to API response models — never remove or rename existing fields.
- Mobile apps (iOS, Android) consuming `isTaxInclusive` treat missing field as `false` (default tax-exclusive behavior).
- Existing order workflows and POS flows remain unaffected.

### NFR-2: Financial Correctness
- Rounding policy: `MidpointRounding.AwayFromZero`, 2 decimal places, after one-item tax calculation and before quantity multiplication.
- Pre-tax reversal + forward tax re-computation must match WPF `GetPreTaxAmount` algorithm exactly.
- When reverse-tax rounding creates a penny variance from the original inclusive price, sales-value reports use the original inclusive price (not the rounded result).
- Final persisted totals must equal sum-of-lines and tax-detail breakdowns.

### NFR-3: Performance
- No additional DB round-trips. Tax rates are already loaded per item inside the existing `GF_TaxGroupTaxes` query in `GetDiscountedItedOrdered`.
- Binary search (25 iterations × tax row count) is negligible — well within acceptable order creation latency.

### NFR-4: Observability (SECURITY-03, RESILIENCY-05)
- Calculation failures must return actionable API error responses — no silent failures in financial paths.
- Use existing `Logger.Error` for exception logging in new code paths.
- New code must not log sensitive pricing data (item prices, tax amounts) at DEBUG level in production.

### NFR-5: Security — Input Validation (SECURITY-05)
- Validate `grossUnitPrice` is positive before passing to `ResolvePreTaxUnitPrice`.
- `taxGroupTaxes` null/empty check returns `grossUnitPrice` unchanged (safe default).
- All existing `APIUserTokenMandatoryAuthorizationFilter` constraints continue to apply to modified endpoints.

### NFR-6: Security — Exception Handling (SECURITY-15)
- New code paths (`ResolvePreTaxUnitPrice` call sites) must be wrapped in existing try-catch blocks or add new ones.
- On calculation failure: log the error, return actionable API error response — do not expose internal details.
- Fail closed: on error, do not fall back to incorrect pricing silently.

### NFR-7: Security — Application-Level Access Control (SECURITY-08)
- Modified endpoints (`PreviewOnlyV2`, `PlaceOrderV2`, `GetMenuItems`, `GetInventoryItem`) already have authorization filters — do not remove them.
- No new endpoints introduced — existing auth patterns fully inherited.

### NFR-8: Security — Data Integrity (SECURITY-13)
- `GF_OrderLineItemTax` records continue to be persisted for every order line — tax ledger remains the audit trail.
- No modification to the existing tax ledger write pattern.

### NFR-9: Property-Based Testing — ResolvePreTaxUnitPrice (PBT-02, PBT-03)
- **PBT-03 Invariant**: For any `grossUnitPrice > 0` and valid `taxGroupTaxes`, `ResolvePreTaxUnitPrice(gross) + Σ tax(ResolvePreTaxUnitPrice(gross)) ≈ gross` (within rounding tolerance of $0.01).
- **PBT-05 Oracle** (advisory in partial mode): Compare `ResolvePreTaxUnitPrice` output against WPF `GetPreTaxAmount` for the same inputs — must match within $0.01.
- **Framework**: FsCheck (C#/.NET) — add as test dependency per PBT-09.
- **Enforcement**: PBT-02, 03, 07, 08, 09 are blocking. PBT tests must be written during construction phase.

### NFR-10: Resiliency — Dependency Isolation (RESILIENCY-10)
- `GetDiscountedItedOrdered` already operates within existing DB connection timeout patterns — maintain these.
- New `ResolvePreTaxUnitPrice` is a pure in-memory computation — no additional DB calls, no timeout concerns.

### NFR-11: Resiliency — Workload Classification (RESILIENCY-01)
- GolferWebAPI OnDemand flow = **Critical** (revenue-impacting: handles live golf course food orders).
- PosApi product catalog = **High** (staff-facing, terminal loads at login).
- RTO/RPO: Inherits existing Golfler platform disaster recovery definitions (not CCD-20 scope — document existing platform DR policy separately).

---

## Acceptance Criteria Summary

Key acceptance criteria from PRD (24 total):

1. Terminal-loaded inventory includes `IsTaxInclusive` used by order creation.
2. For items where `IsTaxInclusive = true`, `GetDiscountedItedOrdered` applies pre-tax reversal before forward tax loop.
3. Pre-tax reversal uses binary search algorithm matching WPF `GetPreTaxAmount` behavior.
4. `OrderDetails2.IsTaxInclusive` bool is set per item in the response.
5. Tax-exclusive items: no behavioral change whatsoever.
6. Mixed cart (inclusive + exclusive items): totals computed correctly.
7. Combo sub-items with `IsTaxInclusive = true`: reversal applied per sub-item before combo tax calculation.
8. For multi-tax groups: per-tax rounding uses `MidpointRounding.AwayFromZero` — matches WPF behavior.
9. Sales tax reports continue to produce accurate tax totals.
10. When reverse-tax rounding creates penny variance, sales-value reports use original inclusive price.
11. `GetMenuItems` returns `isTaxInclusive` bool on each product.
12. `GetInventoryItem` returns `isTaxInclusive` bool on each product.
13. Existing products and historical orders remain unaffected.
14. `PlaceOrderV2` inherits fix via `GetDiscountedItedOrdered` — no separate change.
15. Pre-tax reversal invoked only when `IsTaxInclusive = true`.

---

## Security Compliance Summary

| Rule | Status | Notes |
|------|--------|-------|
| SECURITY-01 Encryption at rest/transit | N/A | No new storage resources |
| SECURITY-02 Access logging on intermediaries | N/A | No new LBs or API gateways |
| SECURITY-03 Application-level logging | Required | Use existing Logger.Error in new code paths |
| SECURITY-04 HTTP security headers | N/A | API endpoints, not HTML-serving |
| SECURITY-05 Input validation | Required | Validate grossUnitPrice > 0; null check on taxGroupTaxes |
| SECURITY-06 Least-privilege access | N/A | No new IAM/role changes |
| SECURITY-07 Restrictive network configuration | N/A | No new network resources |
| SECURITY-08 Application-level access control | Required | Maintain existing auth filters on all modified endpoints |
| SECURITY-09 Security hardening | Required | Error responses must not expose internal details |
| SECURITY-10 Supply chain | N/A | No new external dependencies (FsCheck for tests only) |
| SECURITY-11 Secure design principles | Required | Financial logic isolated in dedicated method |
| SECURITY-12 Authentication | N/A | Existing auth unchanged |
| SECURITY-13 Data integrity | Required | GF_OrderLineItemTax audit trail must be preserved |
| SECURITY-14 Alerting and monitoring | N/A | Existing platform monitoring, not changed by CCD-20 |
| SECURITY-15 Exception handling | Required | try-catch in new code; fail closed on calculation error |

---

## PBT Compliance Summary (Partial Enforcement)

| Rule | Status | Notes |
|------|--------|-------|
| PBT-02 Round-trip | N/A | No serialization/encoding pairs in CCD-20 scope |
| PBT-03 Invariant | **Required** | `ResolvePreTaxUnitPrice(gross) + tax = gross ± $0.01` |
| PBT-07 Generator quality | Required | Domain generator for decimal prices + tax rate lists |
| PBT-08 Shrinking & reproducibility | Required | FsCheck with seed logging |
| PBT-09 Framework selection | Required | FsCheck for .NET — add to test project |

---

## Resiliency Compliance Summary

| Rule | Status | Notes |
|------|--------|-------|
| RESILIENCY-01 Workload classification | Required | GolferWebAPI OnDemand = Critical (revenue) |
| RESILIENCY-02 RTO/RPO targets | Inherits platform | CCD-20 does not change platform DR — confirm existing platform RTO/RPO definition |
| RESILIENCY-03 Change management | Inherits org process | Reference existing Jira/SDLC change process |
| RESILIENCY-04 Automated deployment | Inherits org process | Reference existing CI/CD pipeline |
| RESILIENCY-05 Monitoring | N/A | Existing platform monitoring; new code uses Logger.Error |
| RESILIENCY-06 Health checks | N/A | No new service endpoints |
| RESILIENCY-07 Resiliency monitoring | N/A | On-prem monolith, no cloud resiliency tooling |
| RESILIENCY-08 Multi-zone deployment | N/A | On-prem deployment, not cloud-managed |
| RESILIENCY-09 Auto-scaling | N/A | On-prem monolith, not auto-scaled |
| RESILIENCY-10 Dependency isolation | Required | Maintain existing DB timeout patterns; ResolvePreTaxUnitPrice is pure in-memory |
| RESILIENCY-11 DR strategy | Inherits platform | Existing SQL Server backup/DR policy |
| RESILIENCY-12 Data backup | Inherits platform | Existing automated SQL Server backups |
| RESILIENCY-13 Failover procedures | Inherits platform | Existing org runbooks |
| RESILIENCY-14 Chaos engineering | N/A | Defer to Operations phase |
| RESILIENCY-15 Incident response | Inherits platform | Reference existing on-call/incident process |
