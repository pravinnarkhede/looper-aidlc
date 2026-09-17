# Unit of Work — Dependency Matrix

## Feature: tax-inclusive-inventory (CCD-20)

---

## Dependency Summary

| Unit | Depends On | Dependency Type | Constraint |
|------|-----------|----------------|-----------|
| Unit 2 (PosApi Contract) | Unit 1 (GolferWebAPI) | Sequential branch dependency | Phase 2 branches from Phase 1 feature branch |
| Unit 1 (GolferWebAPI) | `release_5_4_41` base | Branch dependency | Checkout from `release_5_4_41` |

---

## Dependency Diagram

```
release_5_4_41 (base branch)
       |
       | git checkout -b
       v
feature/tax-inclusive-inventory/phase-1 [UNIT 1]
       |
       | MUST COMPLETE + PUSH before Phase 2 starts
       | (phase gate per Looper rules)
       v
feature/tax-inclusive-inventory/phase-2 [UNIT 2]
(git checkout phase-1, then -b phase-2)
```

---

## Why Sequential (Not Parallel)

- Unit 2 **branches from** Unit 1's branch — Phase 2 needs Phase 1's code as its starting point
- Phase 1 contains the `OrderDetails2.IsTaxInclusive` field; Phase 2 agents may reference it as a structural anchor
- Looper phase gates require Phase N complete + pushed before Phase N+1 starts
- Both units are in the same repo (`golfler_asp_2`) — parallel would create merge conflicts

---

## Shared Resources

| Resource | Used By | Access Mode |
|----------|---------|------------|
| `golfler_asp_2` clone | Unit 1, Unit 2 | Sequential (not concurrent) |
| `GetIsTaxInclusive()` (CourseFoodItemDetail) | Both units | Read-only reference |
| `GF_TaxGroupTaxes` (DB) | Unit 1 (load for reversal) | Read-only |
| WPF PosApp algorithm (`golfler_pos_2`) | Unit 1 (algorithm reference) | Reference only — stable mirror |

---

## Parallel Opportunities (None in This Feature)

There are no parallel opportunities between units because:
1. Unit 2 depends on Unit 1's branch
2. Both units modify the same repo
3. Risk profile demands sequential review and verification per phase

---

## Deferred Work (Out of Scope for CCD-20)

| Work Item | Blocked On | Notes |
|-----------|-----------|-------|
| Angular CCOnline changes | Phase 1 + 2 complete | Separate ticket/RePIT after POS confirmed |
| FnB React Native App | Phase 1 + 2 complete | Deferred per PRD |
| Flex Mobile POS App | Phase 1 + 2 complete | Deferred per PRD |
