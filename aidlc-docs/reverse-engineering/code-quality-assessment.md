# Code Quality Assessment — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Test Coverage

| Repo | Test Project | Coverage | Notes |
|---|---|---|---|
| golfler_asp_2 | PosApiUnitTest (MSTest) | Near-zero | 2 stub files found: `MembershipControllerTest.cs`, `PurchaseInvoiceControllerTest.cs`. Previously documented as empty — now confirmed to have minimal stubs. |
| golfler_pos_2 | POSUnitTest (MSTest) | Unknown | Project exists; content not examined in scan |
| sgs-cts-angular | Jasmine + Karma + Protractor | Partial | Many `.spec.ts` files present (app.component.spec.ts, auth.guard.spec.ts, tee-sheet-service.service.spec.ts, etc.); E2E config (`e2e/protractor.conf.js`) present |
| cc_api_manager | None | None | No test files found anywhere |
| cc_membership_portal | None | None | No test files found anywhere |

**Overall assessment**: Test coverage is critically low. The .NET backend (the most critical component, handling all payments and business logic) has essentially no automated tests. The Angular frontend has spec files but their quality/completeness is unknown.

---

## Code Quality Indicators

### Linting / Static Analysis

| Repo | Config | Status |
|---|---|---|
| golfler_asp_2 | No `.editorconfig` at solution root; no StyleCop config found | Not configured |
| golfler_pos_2 | Not found | Not configured |
| sgs-cts-angular | `tslint.json` (tslint 6.1.0 + codelyzer 5.1.2); `.editorconfig` present | Configured |
| cc_api_manager | None found | Not configured |
| cc_membership_portal | None found | Not configured |

### Code Style

| Repo | Assessment |
|---|---|
| golfler_asp_2 | Inconsistent — no enforced style rules; `CommonFunctions.cs` duplicated in 5+ locations |
| golfler_pos_2 | Structured MVVM pattern, but no linting |
| sgs-cts-angular | TSLint configured; `.editorconfig` and `.browserslistrc` present — moderate consistency |
| cc_api_manager | Inconsistent — `Manager_old.php` coexists alongside `Manager.php` (dead code not removed) |
| cc_membership_portal | Three generations of controllers coexist: `controllers/` (active), `controllers_1/` (alternate), `controllers_old/` (archived) |

### Documentation

| Repo | Quality |
|---|---|
| golfler_asp_2 | **Good** — `docs/` folder with `CODE_CONVENTIONS.md`, `API_CONVENTIONS.md`, `DB_CONVENTIONS.md`, `MOBILE_CONVENTIONS.md`, `KNOWN_RISKS_AND_TECH_DEBT.md`, `DATABASE.md` (88 KB schema reference), ADR folder, `ARCHITECTURE.md`, `AGENTS.md` |
| golfler_pos_2 | Poor — no documentation found |
| sgs-cts-angular | Poor — no project-level docs found |
| cc_api_manager | Poor — no documentation |
| cc_membership_portal | `README.md` present; content not examined |

### CI/CD

| Repo | CI/CD | Configuration |
|---|---|---|
| golfler_asp_2 | Jenkins (Groovy) | `JenkinsAutomation/PipelineScripts/ASP_Deployment.groovy` — deploys PosApi, GolferWebAPI, Golfler; selectable environment; target: `CCAZUREDEV2` |
| Others | None found | No CI/CD pipeline files in golfler_pos_2, sgs-cts-angular, PHP repos |

---

## Technical Debt

| Issue | Location | Severity |
|---|---|---|
| Zero automated tests on backend | golfler_asp_2 — PosApiUnitTest | Critical — payment/billing code untested |
| `CommonFunctions.cs` duplicated 5+ times | golfler_asp_2 — multiple locations | High — divergence risk |
| CourseWebApi deprecated but not removed | golfler_asp_2 | Medium — dead code in production codebase |
| `Manager_old.php` not removed | cc_api_manager | Low — dead code |
| Three controller generations coexisting | cc_membership_portal (`controllers/`, `controllers_1/`, `controllers_old/`) | Medium — confusion about which is authoritative |
| Telerik trial assemblies in repo | golfler_pos_2 (`Binary/`) | Medium — trial binaries committed to VCS |
| No pre-commit hooks | All repos | Medium — no automated quality gates before commit |
| No CI/CD for frontend/PHP repos | golfler_pos_2, sgs-cts-angular, PHP repos | Medium — manual deployment risk |
| GolflerShared compiled into all projects | golfler_asp_2 | Architectural risk — payment change affects all APIs simultaneously |
| No DB-level multi-tenancy enforcement | golfler_asp_2 (SQL Server) | Architectural risk — CourseId filtering is app-layer only |
| jQuery version fragmentation | golfler_asp_2 (Golfler MVC) | Low — multiple jQuery versions (1.7.1, 1.8.3, 1.9.1) alongside modern Angular in same solution |
| EDMX database-first EF6 | golfler_asp_2 | Technical debt — EF6 EDMX is legacy; EF Core migration not started |

---

## Patterns and Anti-patterns

### Good Patterns

| Pattern | Location | Notes |
|---|---|---|
| MVVM | golfler_pos_2 | Consistent ViewModelBase/IViewModel hierarchy; well-structured WPF separation |
| Shared project for cross-cutting logic | golfler_asp_2 (GolflerShared) | Avoids DLL versioning issues; consistent business logic across APIs |
| Database-First EF6 EDMX | golfler_asp_2 | Single source of truth for 431 entity classes |
| HTTP Proxy pattern (PHP apps) | cc_api_manager, cc_membership_portal | Clean separation — PHP only handles rendering; all business logic stays in .NET |
| Comprehensive documentation | golfler_asp_2 (`docs/`) | Extensive convention docs, architecture doc, KNOWN_RISKS file, ADRs |
| Per-environment config | cc_api_manager | Separate `config/{env}/constants.php` per environment — clean env separation |
| CourseId multi-tenancy convention | golfler_asp_2 | Consistent application-level tenant isolation across 431 tables |

### Anti-patterns

| Anti-pattern | Location | Risk |
|---|---|---|
| Payment code in shared project | GolflerShared/Modules/Payment.cs | A single bad commit can break billing across all APIs |
| Dead code not removed | cc_api_manager (Manager_old.php), cc_membership_portal (controllers_old/) | Maintenance confusion, potential for wrong controller being called |
| 638K-line JavaScript file | golfler_asp_2 (Golfler/Scripts/) | Unmaintainable monolithic JS in admin portal |
| CommonFunctions.cs duplicated 5+ times | golfler_asp_2 | Bug fixed in one copy won't be in others |
| No tests on payment/billing paths | golfler_asp_2 | Regressions only caught in production |
| Trial UI controls in VCS | golfler_pos_2 (Binary/Telerik trial) | Legal/licensing risk; binary bloat in repository |

---

## Risk Summary

| Risk | Repos | Mitigation Recommendation |
|---|---|---|
| **Payment regressions** | golfler_asp_2 | Add unit tests for GolflerShared Payment.cs before any payment changes |
| **Multi-tenant data leak** | golfler_asp_2 | Code review enforcing CourseId; consider DB-level row security |
| **GolflerShared blast radius** | golfler_asp_2 | Any change to GolflerShared requires regression testing PosApi + GolferWebAPI + Golfler |
| **PHP dead code** | cc_api_manager, cc_membership_portal | Audit and remove `controllers_old/`, `Manager_old.php` |
| **No CI for PHP/Angular/WPF** | golfler_pos_2, sgs-cts-angular, PHP repos | Add Jenkins/GitHub Actions pipelines |
