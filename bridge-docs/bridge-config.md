# Bridge Configuration

## Workspace Identity

| Field | Value |
|-------|-------|
| **AIDLC Rule Details** | `.aidlc-rule-details\` (local) |
| **Looper Version** | 0.7.2 |
| **Looper Harness** | `looper-code\` (local) |
| **Shared RE Artifacts** | `aidlc-docs\reverse-engineering\` |

---

## Reverse Engineering (Shared — Once Per Codebase)

| Status | Output Path | Date | Source |
|--------|-------------|------|--------|
| Complete | `aidlc-docs\reverse-engineering\` | 2026-06-10 | Live scan — `stable-codebase\` (5 repos: golfler_asp_2, golfler_pos_2, sgs-cts-angular, cc_api_manager, cc_membership_portal) |

---

## Features

Each feature has its own subfolder under `aidlc-docs\{feature-name}\` and its own set of Looper RePIT task workspaces.

---

### Feature: tax-inclusive-inventory

| Field | Value |
|-------|-------|
| **Created** | 2026-06-09 |
| **Description** | Setup Tax Inclusive Pricing for Inventory Items — wire TaxInclusive config into OnDemand order calculations (GolferWebAPI) and expose IsTaxInclusive bool in PosApi product DTOs |
| **Jira** | CCD-20 |
| **AIDLC Docs Path** | `aidlc-docs\tax-inclusive-inventory\` |
| **AIDLC Status** | Construction In Progress — Phase 1 + Phase 2 complete + release_5_4_43 merged; awaiting Postman verification + Build & Test |
| **Last Active** | 2026-06-10 |

#### AIDLC Inception Progress

| Stage | Status | Output |
|-------|--------|--------|
| Workspace Detection | Complete | — |
| Reverse Engineering | Complete | `aidlc-docs\reverse-engineering\` (shared) |
| Requirements Analysis | Complete | `aidlc-docs\tax-inclusive-inventory\inception\requirements\` |
| User Stories | Skipped | N/A — technical server-side feature |
| Workflow Planning | Complete | `aidlc-docs\tax-inclusive-inventory\inception\plans\` |
| Application Design | Complete | `aidlc-docs\tax-inclusive-inventory\inception\application-design\` |
| Units Generation | Complete | `aidlc-docs\tax-inclusive-inventory\inception\units-generation\` |

#### Unit -> RePIT Mapping

| # | AIDLC Unit | RePIT Phase | Repos | Status | Branch(es) |
|---|-----------|------------|-------|--------|------------|
| 1 | GolferWebAPI OnDemand Tax-Inclusive Integration | Phase 1 | golfler_asp_2 | Complete | feature/tax-inclusive-inventory/phase-1 |
| 2 | PosApi Contract Additions (IsTaxInclusive DTOs) | Phase 2 | golfler_asp_2 | Complete | feature/tax-inclusive-inventory/phase-2 |

> **Note**: golfler_pos_2 (WPF PosApp) COMPLETE on branch `ccd-20-tax-inclusive-invenotry-3` — not included in AIDLC construction units.

---

### Feature: *(none yet)*

> Features are added here when you start an AIDLC session.
> Each feature gets a block like the one below.

---

<!--
FEATURE BLOCK TEMPLATE — copy this for each new feature:

### Feature: {feature-name}

| Field | Value |
|-------|-------|
| **Created** | {date} |
| **Description** | {one-line description} |
| **AIDLC Docs Path** | `aidlc-docs\{feature-name}\` |
| **AIDLC Status** | Inception In Progress / Inception Complete / Construction In Progress / Complete |
| **Last Active** | {date} |

#### AIDLC Inception Progress

| Stage | Status | Output |
|-------|--------|--------|
| Workspace Detection | — | — |
| Reverse Engineering | Shared / Skipped | `aidlc-docs\reverse-engineering\` |
| Requirements Analysis | — | `aidlc-docs\{feature-name}\inception\requirements\` |
| User Stories | — | `aidlc-docs\{feature-name}\inception\user-stories\` |
| Workflow Planning | — | `aidlc-docs\{feature-name}\inception\plans\` |
| Application Design | — | `aidlc-docs\{feature-name}\inception\application-design\` |
| Units Generation | — | `aidlc-docs\{feature-name}\inception\units-generation\` |

**Stage Status Values**: `—` · `In Progress` · `Complete` · `Skipped`

#### Unit → RePIT Mapping

| # | AIDLC Unit | RePIT Document | Task Workspace | Status | Branch(es) |
|---|-----------|----------------|----------------|--------|------------|
| — | — | — | — | — | — |

**Unit Status**: `Pending` · `In Progress` · `Complete` · `Blocked`
-->

---

## Active Extensions

| Extension | Type | Status |
|-----------|------|--------|
| Looper (Construction) | Opt-in | Presented at Requirements Analysis per feature |
| Security Baseline | Opt-in | Asked per feature at Requirements Analysis |
| Property-Based Testing | Opt-in | Asked per feature at Requirements Analysis |
| Resiliency Baseline | Opt-in | Asked per feature at Requirements Analysis |
