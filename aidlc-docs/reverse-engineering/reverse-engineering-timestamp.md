# Reverse Engineering Metadata

**Analysis Date**: 2026-06-10T00:00:00Z  
**Analyzer**: AIDLC Bridge Workflow — Live Codebase Scan  
**Workspace**: d:\bridge-workspace (workspace path *at the time of this scan* — historical record only, not a live pointer; the workspace has since moved)  
**Source**: `stable-codebase\` (live shallow clones at release branches)  
**Repos Scanned**: 5 of 9 (golfler_asp_2, golfler_pos_2, sgs-cts-angular, cc_api_manager, cc_membership_portal)  
**Repos Excluded**: cc_ios, cc_android, cc-mobile-pos-flex, cc-mobile-pos-fnb (not in stable-codebase for this env)  
**Total Projects Catalogued**: 16 backend (.NET) + 4 WPF + ~20 Angular modules + ~40 PHP controllers  
**Method**: Direct file system scan — folder structure, .csproj, package.json, composer.json, controller files, config files

**Previous RE**: 2026-06-09 (derived from documentation only — PRD + RePIT; no live code access)  
**This RE supersedes**: All prior RE artifacts — now based on actual code

---

## Artifacts Generated

- [x] architecture.md — full platform architecture with diagram; all 5 repos, Jenkins CI/CD, integration points
- [x] business-overview.md — business context, all business transactions, business dictionary
- [x] code-structure.md — build systems, key files per repo, design patterns, critical dependencies
- [x] api-documentation.md — all PosApi + GolferWebAPI controller domains; PHP proxy model; data models
- [x] component-inventory.md — complete inventory of all projects, modules, controllers across all 5 repos
- [x] technology-stack.md — languages, frameworks, UI libs, cloud infra, payment gateways, build tools, testing
- [x] dependencies.md — internal project graph, cross-repo runtime deps, NuGet/npm/binary dependencies
- [x] code-quality-assessment.md — test coverage, linting, technical debt, patterns/anti-patterns, risk summary
- [x] reverse-engineering-timestamp.md (this file)

---

## Key Findings Summary

1. **Architecture**: Monolithic ASP.NET backend (golfler_asp_2) with two APIs (PosApi staff, GolferWebAPI customer). PHP repos are thin rendering layers — all business logic stays in .NET.
2. **Payment risk**: All 9 payment gateways integrated via GolflerShared — a single shared project compiled into every .NET API simultaneously. Changes have platform-wide blast radius.
3. **Multi-tenancy**: Application-layer only (CourseId on every query). No DB-level row security.
4. **Test coverage**: Near-zero on backend; PHP repos have none. Angular has spec files of unknown quality.
5. **Tech debt hotspots**: CommonFunctions.cs duplicated 5+ times; dead controllers in PHP repos; 638K-line JS in Golfler admin; CourseWebApi deprecated but present; Telerik trial assemblies in VCS.
6. **CI/CD**: Jenkins only for golfler_asp_2; no pipelines for other repos.
7. **Documentation quality**: Excellent for golfler_asp_2 (docs/, ADRs, ARCHITECTURE.md, KNOWN_RISKS); poor for all other repos.
