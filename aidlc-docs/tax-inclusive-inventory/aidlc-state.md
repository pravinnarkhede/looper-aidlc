# AI-DLC State Tracking — tax-inclusive-inventory

## Project Information

- **Feature Name**: tax-inclusive-inventory
- **Jira Ticket**: CCD-20
- **Description**: Setup Tax Inclusive Pricing for Inventory Items — wire TaxInclusive config into OnDemand order calculations (GolferWebAPI) and expose IsTaxInclusive bool in PosApi product DTOs.
- **Project Type**: Brownfield
- **Start Date**: 2026-06-09T00:00:00Z
- **Current Stage**: INCEPTION COMPLETE — Ready for Construction (/looper-plan)

## Workspace State

- **Existing Code**: Yes
- **Partial Implementation**: WPF PosApp (golfler_pos_2) COMPLETE on branch `ccd-20-tax-inclusive-invenotry-3`. golfler_asp_2 work not yet started.
- **Reverse Engineering**: Complete — artifacts at `aidlc-docs\reverse-engineering\` (shared)
- **Workspace Root**: (workspace root — resolved fresh each session, do not hardcode; was `d:\bridge-workspace` at authoring time, workspace has since moved)
- **Task Workspace (Looper)**: `RePIT-AIDLC-tax-inclusive-inventory-E1\` (create at /looper-plan)

## Extension Configuration

| Extension | Enabled | Mode | Decided At |
|-----------|---------|------|-----------|
| Looper (Construction) | Yes | Always-on | System |
| Security Baseline | Yes | Full enforcement (all SECURITY rules) | Requirements Analysis — 2026-06-09 |
| Property-Based Testing | Yes | Partial (PBT-02, 03, 07, 08, 09) | Requirements Analysis — 2026-06-09 |
| Resiliency Baseline | Yes | Directional best practices | Requirements Analysis — 2026-06-09 |

## Stage Progress

### INCEPTION PHASE
- [x] Workspace Detection — 2026-06-09
- [x] Reverse Engineering — 2026-06-09 (artifacts in aidlc-docs\reverse-engineering\)
- [x] Requirements Analysis — 2026-06-09 (requirements.md, PRD + extensions)
- [x] User Stories — SKIPPED (technical server-side feature, no new user personas)
- [x] Workflow Planning — 2026-06-09 (execution-plan.md)
- [x] Application Design — 2026-06-09 (5 artifacts in inception\application-design\)
- [x] Units Generation — 2026-06-09 (3 artifacts in inception\units-generation\)

### CONSTRUCTION PHASE (Looper)
- [x] /looper-plan — COMPLETE (2026-06-09)
  - Task workspace: `RePIT-AIDLC-tax-inclusive-inventory-E1\`
  - RePIT: `RePIT-AIDLC-tax-inclusive-inventory-E1.md` (version 1.0.0)
  - Base branch: `ccd-20-tax-inclusive-invenotry-3` (existing partial implementation)
  - Phase 1 branch: `feature/tax-inclusive-inventory/phase-1`
  - Phase 2 branch: `feature/tax-inclusive-inventory/phase-2`
- [x] /looper-implement Phase 1 — COMPLETE (2026-06-09)
  - Commit: `7f62bd0` — branch: `feature/tax-inclusive-inventory/phase-1`
  - File changed: `GolferWebAPI/Models/OnDemand.cs` (54 lines, ResolvePreTaxUnitPrice helper + regular + combo pre-tax reversal)
  - Deferred: task 5.0 (FsCheck PBT), task 6.0 (GolferWebAPI OpenAPI spec)
- [x] /looper-implement Phase 2 — COMPLETE (2026-06-10)
  - Commit: `14986fc` — branch: `feature/tax-inclusive-inventory/phase-2`
  - File changed: `PosApi/Models/FoodBeverage.cs` (2 lines — property + mapping)
  - Human task pending: task 1.3 Postman verification
- [ ] Build and Test — PENDING

### OPERATIONS PHASE
- [ ] Operations — PLACEHOLDER

## Current Status

- **Lifecycle Phase**: CONSTRUCTION (Looper in progress)
- **Current Stage**: /looper-implement Phase 1 + Phase 2 complete — awaiting Build and Test
- **Next Action**: Human task 1.3 Postman verification, then Build and Test
- **Status**: Construction In Progress — Pending Human Verification + Build & Test

## Bridge Handoff

### Looper Task Workspace
- **Folder**: `{bridge-workspace-root}\RePIT-AIDLC-tax-inclusive-inventory-E1\` (workspace root resolved fresh each session — do not hardcode a drive/path here)
- **RePIT**: `RePIT-AIDLC-tax-inclusive-inventory-E1.md`
- **Repo to clone**: `golfler_asp_2` (Change)
- **Reference repo**: `looper-code-artifacts\stable-codebase\golfler_pos_2\` (read-only)

### AIDLC Context Files for /looper-plan
| Artifact | Path | Looper Use |
|----------|------|-----------|
| Units | `inception\units-generation\unit-of-work.md` | Phase descriptions |
| Application Design | `inception\application-design\application-design.md` | Design considerations |
| Requirements | `inception\requirements\requirements.md` | FR + NFR + security/PBT/resiliency |
| Component Methods | `inception\application-design\component-methods.md` | Method signatures |
| RE: Code Structure | `aidlc-docs\reverse-engineering\code-structure.md` | File locations + line numbers |
| RE: API Docs | `aidlc-docs\reverse-engineering\api-documentation.md` | API endpoint context |
| PRD | `tax-inclusive-inventory\golfler_asp_2\docs\requirements\PRD-020-tax-inclusive-inventory.md` | Full requirement detail |

### Unit → Phase Mapping
| AIDLC Unit | RePIT Phase | Repos | Branch |
|-----------|------------|-------|--------|
| GolferWebAPI OnDemand Tax-Inclusive Integration | Phase 1 | golfler_asp_2 | feature/tax-inclusive-inventory/phase-1 |
| PosApi Contract Additions | Phase 2 | golfler_asp_2 | feature/tax-inclusive-inventory/phase-2 |
