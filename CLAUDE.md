# Bridge Workspace: AIDLC + Looper

## Architecture

This workspace integrates two AI-assisted development systems:

- **AIDLC** (AWS AI-Driven Lifecycle) — governs the **INCEPTION phase**: requirements gathering, user stories, application design, and unit decomposition (determines WHAT to build)
- **Looper** (Define Labs Development Harness) — **optional** Construction extension: per-unit research, planning, and implementation via RePIT documents (replaces AIDLC Code Generation when opted in)

**Division of responsibility:**
- AIDLC is authoritative for: requirements, architecture decisions, NFR constraints, unit decomposition, code generation (default), build & test
- Looper (when opted in): replaces AIDLC Code Generation with RePIT-driven implementation — per-unit plans, code changes, git branches, Jira updates

---

## MANDATORY: System Paths

### AIDLC Rule Details
Load AIDLC rules from: `.aidlc-rule-details\` (local to this workspace — all rule files are bundled here)

All references in this file to `inception\`, `construction\`, `common\`, `operations\`, and `extensions\` are relative to `.aidlc-rule-details\` — except where a path is written out in full (e.g. the Extensions Loading table below uses fully-qualified paths deliberately, to avoid exactly this kind of ambiguity).

### Bridge Extensions
Bridge-specific extensions live at: `.aidlc-rule-details\extensions\`
The Looper extension (`looper\looper.md`) is **opt-in** — presented during Requirements Analysis. When opted in, it replaces AIDLC's native Code Generation stage with the Bridge Handoff Protocol below.

### Bridge Overrides
Workspace customisations that must survive vendor updates live at: `bridge-docs\bridge-overrides\`
- `looper-opt-in.md` — Looper opt-in prompt (authoritative — do not read from `.aidlc-rule-details\extensions\looper\`)
- `workspace-repos.md` — which repos to select when `/looper-setup` asks (do not edit `looper-code\artifacts\project-structure.md`)

**Update rule**: When `.aidlc-rule-details\` or `looper-code\` receive upstream updates, `bridge-docs\bridge-overrides\` is never touched. Always read opt-in prompts and repo selection from `bridge-docs\bridge-overrides\`.

### Looper Harness
The Looper harness is pre-installed — commands are in `.claude\commands\`, agents in `.claude\agents\`, hooks in `.claude\hooks\`.
The Looper codebase is at `looper-code\` (used for workspace convention, artifacts, and templates).
The Looper session hook is pre-wired in `.claude\settings.json` pointing to `looper-code\hooks\looper-session-hook.ps1`.

### Bridge State
`bridge-docs\bridge-config.md` — tracks all features and their AIDLC + Looper progress.
Update this file whenever a feature is created or its unit status changes.

### Workspace Root Resolution (never hardcode it)
`{bridge-workspace-root}` throughout this file means **wherever this workspace actually is right now**, re-derived fresh every session — never a value copied from a previous session, a state file, or another machine. Concretely:
- **Never write an absolute path containing the workspace root** into `aidlc-state.md`, `audit.md`, `bridge-docs\bridge-config.md`, or any hook/settings file — the workspace can be relocated, renamed, or cloned onto a different machine/drive at any time, and a stored absolute path silently goes stale the moment that happens (nothing errors — it just points at the wrong place). Record paths **relative to the workspace root** (e.g. `RePIT-AIDLC-{feature-name}-E1\`, not `D:\bridge-workspace\RePIT-AIDLC-{feature-name}-E1\`).
- **On resume, if an existing state file contains an absolute path**, treat it as informational only — never navigate to it or assume it still exists. Re-resolve every path relative to the current session's actual working directory instead.
- This applies to configuration too: if `.claude\settings.json`'s hook commands ever contain an absolute path, verify it still matches the current workspace root before trusting it — don't assume a previously-working hook still fires correctly after a workspace move.

---

## MANDATORY: Plan Publishing (Shared Repos)

**Plans are never left only on one machine.** AIDLC docs and RePIT plans are mirrored into their own shared git repos — never the project repo(s) being worked on — so any teammate can pull the plan and resume the task on their own machine. Cloned project repos (`golfler_asp_2`, etc.) are the one thing that stays local-only inside a task-workspace folder — they already push to their own remotes per phase/unit.

**Repos:**
| Content | Shared repo | Branch | Path inside repo |
|---|---|---|---|
| AIDLC docs | `git@bitbucket.org:definelabs/aidlc-docs.git` | `aidlc-docs/{feature-name}` | `{feature-name}\` (same layout as `aidlc-docs\{feature-name}\`) |
| Knowledge base (shared, cross-feature) | `git@bitbucket.org:definelabs/aidlc-docs.git` (same repo as AIDLC docs, separate branch) | `aidlc-docs/knowledge-base` | `knowledge-base\` (same layout as `aidlc-docs\knowledge-base\`) |
| RePIT plan | `git@bitbucket.org:definelabs/looper-code.git` (already cloned at `looper-code\`) | `repits/{repit-folder-name}` | `repits\{repit-folder-name}\` |

`{repit-folder-name}` is the exact task-workspace folder name (e.g. `RePIT-AIDLC-{feature-name}-E1` for Path B, or the RePIT name Looper generated directly). Using the identical folder name in both places means the same folder that lives at the workspace root also exists inside the shared repo — no renaming, no translation.

**Setup (first use in this workspace):**
- If `aidlc-docs\` is not already a git repo, do NOT `git init` a fresh history over existing content. Clone `git@bitbucket.org:definelabs/aidlc-docs.git` to a temp path, create/checkout an orphan-safe feature branch, copy the existing local `aidlc-docs\` content in on top, then replace the local folder with that clone (preserving `.git\`). Confirm with the user before doing this migration, and before any push.

**When to publish:**
- **AIDLC**: after every Inception stage is approved, and after every Construction unit-status change in `bridge-docs\bridge-config.md` — commit `aidlc-docs\{feature-name}\` on branch `aidlc-docs/{feature-name}` and push.
- **Knowledge base**: after every run of the `knowledge-base-builder` agent (see [Knowledge Base](#mandatory-knowledge-base)) — commit `aidlc-docs\knowledge-base\` on branch `aidlc-docs/knowledge-base` and push. This is what makes the knowledge base actually useful to teammates on another machine, not just local to whoever's session built it.
- **RePIT (Path B / Looper)**: after `/looper-plan` creates or updates the RePIT, and after each phase completes in `/looper-implement` — copy/update `{repit-folder-name}\{repit-folder-name}.md` into `looper-code\repits\{repit-folder-name}\`, commit on branch `repits/{repit-folder-name}`, and push.
- **Never** push the cloned project repos (`golfler_asp_2`, `sgs-cts-angular`, etc.) as part of any of the above — they are excluded (`.gitignore` them inside `looper-code\repits\{repit-folder-name}\` if ever cloned there by mistake).

**Pushing is a shared-system action** — confirm with the user before the first push of a new branch, per the risky-actions guidance. Routine same-branch pushes for an already-confirmed feature don't need to be re-confirmed every time unless the user asks otherwise.

**`aidlc-docs/knowledge-base` is contended — every feature/session pushes to it, unlike the per-feature branches.** Before pushing to it:
1. `git fetch origin aidlc-docs/knowledge-base` then `git merge origin/aidlc-docs/knowledge-base` (or rebase) before pushing your own commit — never push straight without syncing first.
2. If the merge/rebase produces a conflict, resolve it by combining both sides' content (this branch only ever gains Markdown sections — a conflict almost always means two sessions added different sections to the same file, which is a textual merge, not a real conflict of intent). Never resolve by discarding one side.
3. **Never force-push this branch** (the workspace's `.claude\settings.json` permission deny-list already blocks `git push --force*`/`-f` workspace-wide as a backstop, but treat it as a hard rule regardless).
4. If push still fails after one retry (network issue, auth issue, remote down): don't block the session on it. Tell the user the knowledge base update is saved locally at `aidlc-docs\knowledge-base\` but not yet pushed, and that `/knowledge-base-update` (or a plain retry) can re-attempt the push later — then continue the workflow.

**To resume on another machine**: pull the relevant branches (`aidlc-docs/{feature-name}` from `aidlc-docs`, `aidlc-docs/knowledge-base` from the same repo, and/or `repits/{repit-folder-name}` from `looper-code`), place each folder at the workspace root under its original name (`aidlc-docs\{feature-name}\`, `aidlc-docs\knowledge-base\`), then re-clone the project repos listed in `construction\repo-setup.md` (Path A) or the RePIT's repo list (Path B) as siblings — same as Repo Setup / Step 1 of the Bridge Handoff Protocol describe for a fresh run.

---

## MANDATORY: Feature Context

**Every AIDLC session is scoped to one feature.** All documentation for a feature is saved under `aidlc-docs\{feature-name}\`. This keeps multiple features isolated from each other in the same workspace.

This whole section runs automatically the moment the user describes a feature or pastes a ticket ID in a new chat — no command is required. `/aidlc` (`.claude\commands\aidlc.md`) is an optional, explicit entry point into the same steps below, for when the user wants a guaranteed trigger instead of relying on a plain-English message (mirrors why `/looper-plan` exists alongside "just describe the task").

### On Session Start — Determine the Active Feature

**Step 1: Scan for existing features**
List all subdirectories under `aidlc-docs\` (each subdirectory is one feature). Exclude `reverse-engineering\` and `knowledge-base\` — those are shared across all features, not features themselves.

**Step 2a: Existing features found**
Present the list:
```
This workspace has {N} feature(s):

  [1] {feature-name-1}  — last updated: {date from aidlc-state.md}  — status: {phase}
  [2] {feature-name-2}  — last updated: {date from aidlc-state.md}  — status: {phase}
  [N] Start a new feature

Which would you like to work on?
```
Resume the selected feature using its `aidlc-docs\{feature-name}\aidlc-state.md`.

**Step 2b: No existing features (first use)**

**If the user's request includes a ticket ID** (e.g. Jira key like `CCD-1234`, `CRB-456`), use the ticket ID as the feature name directly — do not derive a name from the description:
- "CCD-1234: add receipt printing to POS" → `CCD-1234`
- "fix bug CRB-456" → `CRB-456`

**Otherwise**, derive a short kebab-case feature name from the user's description (max 30 chars, lowercase, hyphens for spaces, no special characters):
- "membership renewal portal" → `membership-renewal`
- "add receipt printing to POS" → `receipt-printing`
- "payment gateway integration" → `payment-gateway`

Confirm with the user before creating anything:
```
Feature name: `{feature-name}`
Docs will be saved to: aidlc-docs\{feature-name}\

Confirm? (yes / change to: ...)
```

This keeps AIDLC docs generated **per ticket or per feature** — one `aidlc-docs\{feature-name}\` folder per unit of work, named after the ticket when one exists so it's traceable back to Jira.

**Step 3: Set the feature path**
All AIDLC documentation for this session is rooted at:
```
FEATURE_ROOT = aidlc-docs\{feature-name}\
```
Every path in this file that begins with `aidlc-docs\` (except `aidlc-docs\reverse-engineering\` and `aidlc-docs\knowledge-base\`, both shared across all features) uses `FEATURE_ROOT` as its base. **This substitution also applies inside any `.aidlc-rule-details\*.md` rule file loaded via "Load and execute"** — those vendor files predate this bridge's per-feature model and often reference bare paths like `aidlc-docs/aidlc-state.md` or `aidlc-docs/inception/requirements/requirements.md` with no feature-name scoping. Treat every such bare `aidlc-docs/...` reference inside a loaded rule file as implicitly `{FEATURE_ROOT}\...` (i.e. insert `{feature-name}\` after `aidlc-docs\`) — this file's Inception/Construction sections above always state the correctly-scoped `Output:` path for each stage; that stated output path is authoritative over whatever bare path the loaded rule file itself mentions.

**Update `bridge-docs\bridge-config.md`**: add a row for the new feature, or update the last-active timestamp for a resumed feature.

---

## MANDATORY: AIDLC Rule Loading

At every session start, load from `.aidlc-rule-details\`:
- `common\process-overview.md` — workflow overview
- `common\session-continuity.md` — session resumption
- `common\content-validation.md` — content validation requirements
- `common\question-format-guide.md` — question formatting rules

Reference these throughout the workflow execution.

---

## MANDATORY: Extensions Loading (Context-Optimized)

Scan extensions from `.aidlc-rule-details\extensions\` (all extensions are local to this workspace):

- For all extensions with a `*.opt-in.md` file: load only the opt-in file at session start; load full rules only after the user opts in during Requirements Analysis

Opt-in extensions and when they apply:
| Extension | Opt-in file | Full rules file | When enforced |
|-----------|-------------|-----------------|---------------|
| Looper (Construction) | `bridge-docs\bridge-overrides\looper-opt-in.md` | `.aidlc-rule-details\extensions\looper\looper.md` | After user opts in — replaces AIDLC Code Generation |
| Security Baseline | `.aidlc-rule-details\extensions\security\baseline\security-baseline.opt-in.md` | `.aidlc-rule-details\extensions\security\baseline\security-baseline.md` | After user opts in — all phases |
| Property-Based Testing | `.aidlc-rule-details\extensions\testing\property-based\property-based-testing.opt-in.md` | `.aidlc-rule-details\extensions\testing\property-based\property-based-testing.md` | After user opts in — Construction phase |
| Resiliency Baseline | `.aidlc-rule-details\extensions\resiliency\baseline\resiliency-baseline.opt-in.md` | `.aidlc-rule-details\extensions\resiliency\baseline\resiliency-baseline.md` | After user opts in — all phases (blocking rules) |

All paths above are given in full — do not treat them as relative to any other path mentioned nearby (e.g. they are **not** relative to "Scan extensions from `.aidlc-rule-details\extensions\`" above; that line only names the directory to scan, not a base to resolve these against).

Enforcement applies only to the applicable phase or stage for each extension.

---

## MANDATORY: Content Validation
Before creating any file, validate per `common\content-validation.md`.

## MANDATORY: Question Format
Follow `common\question-format-guide.md` for all questions.

## MANDATORY: Welcome Message
At the start of every new workflow, display the welcome message from `.aidlc-rule-details\common\welcome-message.md`.

## MANDATORY: Checkbox Tracking
- Mark each plan step `[x]` immediately after completing it — same interaction, no batching
- Update `{FEATURE_ROOT}\aidlc-state.md` after each stage completes
- Update `bridge-docs\bridge-config.md` when unit status changes

## MANDATORY: Audit Trail
- Log every user input and AI response in `{FEATURE_ROOT}\audit.md`
- Use ISO 8601 timestamps (YYYY-MM-DDTHH:MM:SSZ)
- NEVER overwrite audit.md — always append/edit
- Also log Construction phase completions in `{FEATURE_ROOT}\audit.md` under `## Construction — [Unit Name]` (append `(Looper)` if Looper was used for that unit)

## MANDATORY: Knowledge Base

**Purpose**: Build a shared, cross-feature knowledge base capturing durable business logic, flows, and domain knowledge — so future work (and, eventually, a RAG system built on top of it) can quickly understand how the system works, without re-reading every feature's inception docs.

**Location** (shared across all features, like `aidlc-docs\reverse-engineering\`): `aidlc-docs\knowledge-base\`

**Owner**: the `knowledge-base-builder` agent (`.claude\agents\knowledge-base-builder.md`). It reads AIDLC/Looper artifacts, extracts the *meaning* (not raw copies), and merges it into Markdown files with frontmatter under `aidlc-docs\knowledge-base\` (`index.md`, `business-logic\{domain}.md`, `flows\{flow-name}.md`, `decisions\{feature-name}.md`). For Construction/Looper triggers it also reads the read-only `git diff` of that unit's/phase's commits in the changed repos, since business logic sometimes lands in code without the plan doc being updated.

**Automatic triggers** — invoke the `knowledge-base-builder` agent:
- After every approved Inception stage (same point where `aidlc-docs\{feature-name}\` is published — see [Plan Publishing](#mandatory-plan-publishing-shared-repos))
- After every Construction unit-status change (Path A) or Looper phase completion (Path B) — same point where `bridge-docs\bridge-config.md` is updated

**On-demand**: `/knowledge-base-update` — full or partial backfill, safe to re-run (merges, never duplicates).

**Never**: write application code, touch `aidlc-docs\reverse-engineering\`, or modify any `aidlc-docs\{feature-name}\` / `RePIT-AIDLC-*` content — the agent only reads those and writes to `aidlc-docs\knowledge-base\`.

---

# INCEPTION PHASE (AIDLC-Governed)

**Purpose**: Determine WHAT to build and WHY.
**Owner**: AIDLC rules
**All output paths are under `{FEATURE_ROOT}\` unless stated otherwise.**

Execute all applicable AIDLC Inception stages. Load each stage's rules from `.aidlc-rule-details\` before executing:

## Workspace Detection (ALWAYS)
1. Log initial user request in `{FEATURE_ROOT}\audit.md`
2. Load and execute `inception\workspace-detection.md`
3. Check for existing `{FEATURE_ROOT}\aidlc-state.md` (resume if found)
4. Determine brownfield vs greenfield:
   - **Greenfield**: no repos needed — proceed normally
   - **Brownfield**: AIDLC needs to read the codebase. Check in this order:
     a. Repos already cloned anywhere under the workspace root → use them directly
     b. Stable mirror exists at `looper-code-artifacts\stable-codebase\` → use it as the codebase root for all RE scanning and Application Design reads
     c. Neither found → **pause and instruct the user** (read `bridge-docs\bridge-overrides\workspace-repos.md` and include the repo list so they know which repos to select during `/looper-setup`):
        ```
        ⚠️  No codebase found locally.
        Before Inception can analyse the code, the repos need to be available.

        Run /looper-setup to provision a read-only stable mirror at:
          looper-code-artifacts\stable-codebase\
        When asked which repos to set up, select: {list from bridge-docs\bridge-overrides\workspace-repos.md}

        Reply "done" once /looper-setup completes, or point me to where the repos are cloned.
        ```
        Wait for confirmation, then proceed using the stable mirror or user-specified path.
5. Log findings; auto-proceed to next stage

## Reverse Engineering (CONDITIONAL — Brownfield only, shared across all features)

**Path**: `aidlc-docs\reverse-engineering\` — **NOT under FEATURE_ROOT** — this is shared once per codebase.

**Execute IF**: existing codebase detected AND `aidlc-docs\reverse-engineering\` does NOT exist.
**Skip IF**: greenfield project OR `aidlc-docs\reverse-engineering\` already exists (from any prior feature).

When skipped, load existing RE artifacts from `aidlc-docs\reverse-engineering\` as context.

**Codebase source for scanning** (resolved during Workspace Detection):
- Use `looper-code-artifacts\stable-codebase\` if available (preferred — set up via `/looper-setup`)
- Otherwise use any locally cloned repo path confirmed by the user

Load and execute `inception\reverse-engineering.md`.
**Wait for explicit approval before proceeding.**

## Requirements Analysis (ALWAYS — Adaptive Depth)
Load and execute `inception\requirements-analysis.md`.
Present extension opt-in prompts during this stage.
Output: `{FEATURE_ROOT}\inception\requirements\`
**Wait for explicit approval before proceeding.**

## User Stories (CONDITIONAL)
Load and execute `inception\user-stories.md`.
Execute if new user-facing features or complex business requirements are involved.
**Two-part stage**: Plan → Approval → Generate.
Output: `{FEATURE_ROOT}\inception\user-stories\`
**Wait for explicit approval before proceeding.**

## Workflow Planning (ALWAYS)
Load and execute `inception\workflow-planning.md`.
Validate all Mermaid/ASCII content before writing files.
Output: `{FEATURE_ROOT}\inception\plans\`
**Wait for explicit approval before proceeding.**

## Application Design (CONDITIONAL)
Execute if new components, services, or complex business rules are needed.
Load and execute `inception\application-design.md`.
Output: `{FEATURE_ROOT}\inception\application-design\`
**Wait for explicit approval before proceeding.**

## Units Generation (CONDITIONAL)
Execute if the system needs decomposition into multiple development units.
Load and execute `inception\units-generation.md`.
Output: `{FEATURE_ROOT}\inception\units-generation\`
**Wait for explicit approval before proceeding.**

**After every Inception stage approval**: publish `aidlc-docs\{feature-name}\` per [Plan Publishing](#mandatory-plan-publishing-shared-repos), and invoke the `knowledge-base-builder` agent per [Knowledge Base](#mandatory-knowledge-base).

**Inception → Construction trigger**: When the user approves the final Inception stage output, the Construction phase begins.

---

# CONSTRUCTION PHASE

**Purpose**: Build each unit — generate code, run tests, verify quality.
**Default Owner**: AIDLC rules (Path A below)
**Optional**: If Looper was opted in during Requirements Analysis, use Path B (Bridge Handoff Protocol) instead of Path A Code Generation.

**Switching path mid-feature (rare, requires explicit user confirmation)**: "Never mix mid-feature" means don't run units on both paths simultaneously — it doesn't mean the choice is unfixable if a unit turns out bigger or riskier than expected. If the user wants to switch:
- **Path A → Path B, mid-feature**: any unit not yet started (or whose Code Generation hasn't been approved) can move to Looper. Do Bridge Handoff Protocol Step 1 for the whole feature if it hasn't run yet, then map only the *not-yet-built* units to RePIT phases (already-completed Path A units stay as-is, recorded in `bridge-docs\bridge-config.md` as built via Path A — don't redo them under Looper).
- **Path B → Path A, mid-feature**: any RePIT phase not yet started can instead run as an AIDLC Path A unit (Repo Setup → Code Generation). Already-completed Looper phases stay as-is.
- Either direction: confirm with the user first (this changes how remaining work gets built), then update `bridge-docs\bridge-config.md`'s unit-to-phase mapping to reflect which units are on which path from that point forward.

---

## Path A — AIDLC Native Construction (Default)

Execute when Looper is **not** opted in. Run the applicable AIDLC Construction stages for each unit. Load each stage's rules from `.aidlc-rule-details\construction\` before executing:

### Repo Setup (ALWAYS — before Code Generation)

1. **Identify affected repos**: read the repo list per unit from `{FEATURE_ROOT}\inception\application-design\` and `{FEATURE_ROOT}\inception\units-generation\` (or Requirements Analysis output if those stages were skipped).
2. **Determine the clone target folder**: `{bridge-workspace-root}\AIDLC-{feature-name}\` — one dedicated folder for the whole feature, sibling to the workspace root, created the first time Path A construction runs for this feature (not re-created per unit).
3. **Resolve each repo's source**, in order:
   a. Already cloned somewhere under the workspace root → use directly, do not re-clone
   b. Otherwise, will be cloned fresh into `AIDLC-{feature-name}\{repo-name}\` — from the stable mirror's remote/origin if `looper-code-artifacts\stable-codebase\` exists (never clone or copy the mirror's working files directly — it is read-only, [see stable mirror rule]), otherwise from the repo's configured remote
4. **Look up each repo's Release Branch** in `looper-code\artifacts\project-structure.md`'s `## Repository Overview` table (`Release Branch` column — e.g. `golfler_asp_2` → `release_5_7`), so it can be shown in the confirmation prompt below. If a repo isn't listed in that table at all (a new repo not yet onboarded), stop and ask the user which branch to base work on rather than guessing the default.
5. Present the resolved repo list before cloning:
   ```
   Repos needed for {feature-name}:
     [1] golfler_asp_2      → AIDLC-{feature-name}\golfler_asp_2\ (base: release_5_7)
     [2] sgs-cts-angular    → AIDLC-{feature-name}\sgs-cts-angular\ (base: release_v1_3)

   Confirm? (yes / adjust)
   ```
6. Once confirmed, clone each repo per step 3 and **immediately `git checkout {release-branch}`** (the branch found in step 4) before any feature branch is created off it. A plain clone lands on the repo's default branch (often `master`/`main`), which is **not** the stable base to build on — this is the same branch `/looper-artifacts-setup` already uses for the read-only stable mirror.
7. All subsequent Code Generation steps for this feature operate inside `AIDLC-{feature-name}\`, not the bare workspace root.

Output: repos cloned at `{bridge-workspace-root}\AIDLC-{feature-name}\`; a short record of what was cloned/reused at `{FEATURE_ROOT}\construction\repo-setup.md`.

### Functional Design (CONDITIONAL)
Execute if detailed component specifications are needed beyond Application Design output.
Load and execute `construction\functional-design.md`.
Output: `{FEATURE_ROOT}\construction\{unit-name}\functional-design\`
**Wait for explicit approval before proceeding.**

### Infrastructure Design (CONDITIONAL)
Execute if deployment, infra, or environment specs are required.
Load and execute `construction\infrastructure-design.md`.
Output: `{FEATURE_ROOT}\construction\{unit-name}\infrastructure-design\`
**Wait for explicit approval before proceeding.**

### NFR Requirements / NFR Design (CONDITIONAL)
Execute if non-functional requirements need detailed implementation specs.
Load and execute `construction\nfr-requirements.md` then `construction\nfr-design.md`.
Output: `{FEATURE_ROOT}\construction\{unit-name}\nfr\`
**Wait for explicit approval before proceeding.**

### Code Generation (ALWAYS — per unit)
Load and execute `construction\code-generation.md`.
- Part 1 (Planning): create and approve the unit code generation plan
- Part 2 (Generation): execute the plan step by step, marking [x] after each step
Output: Application code inside `{bridge-workspace-root}\AIDLC-{feature-name}\` (repos cloned during Repo Setup); docs at `{FEATURE_ROOT}\construction\{unit-name}\code\`
**Wait for explicit approval before proceeding.**

**After each unit's Code Generation completes and `bridge-docs\bridge-config.md` unit status is updated**: invoke the `knowledge-base-builder` agent per [Knowledge Base](#mandatory-knowledge-base), pointing it at the unit's docs **and** the git diff of that unit's commits in each repo changed under `{bridge-workspace-root}\AIDLC-{feature-name}\{repo}\`.

### Build & Test (ALWAYS — after all units)
Load and execute `construction\build-and-test.md`.
Generate cross-unit integration test instructions.
Once all units' Code Generation is done, set `bridge-docs\bridge-config.md`'s **AIDLC Status** to `Testing` (not `Complete` yet).
**Before marking Build & Test complete**: invoke the `build-checker` agent (`.claude\agents\build-checker.md`) against `{bridge-workspace-root}\AIDLC-{feature-name}\` to confirm every affected repo actually compiles. Include its pass/fail report in the Build & Test output.
- If `build-checker` reports all present repos ✅ PASS: update **AIDLC Status** `Testing` → `Complete`.
- If it reports any ❌ FAIL: keep **AIDLC Status** at `Testing`, surface the failing repo(s) and error output to the user, and do not mark `Complete` until a re-run passes.
Output: `{FEATURE_ROOT}\construction\build-and-test\`
**Wait for explicit approval before proceeding.**

---

## Path B — Bridge Handoff Protocol (Looper opted in)

Execute when Looper IS opted in. AIDLC Code Generation is replaced by Looper's RePIT process.

**Opted-in extensions still apply.** "Looper replaces AIDLC Code Generation" replaces *how code gets written*, not the extension rules the user opted into during Requirements Analysis. Any extension marked "all phases" or "blocking" (e.g. Resiliency Baseline) still applies to Looper's phases — pass the relevant extension's full rules file (from [Extensions Loading](#mandatory-extensions-loading-context-optimized)) into the `/looper-plan` context alongside the AIDLC design artifacts (Step 4a), and treat its blocking rules as gating the same way `[Human]` tasks gate a RePIT phase. Do not treat opting into Looper as opting out of a previously-opted-into extension.

---

## Bridge Handoff Protocol

When the final Inception stage is approved:

### Step 1 — Create one task workspace for the entire feature

One feature = one Looper task workspace = one RePIT document.
AIDLC units map to **phases** inside the single RePIT — not to separate workspaces.

**Task workspace folder**: `{bridge-workspace-root}\RePIT-AIDLC-{feature-name}-E1\`
**RePIT document**: `RePIT-AIDLC-{feature-name}-E1.md`

All repos cloned for this feature live as siblings inside this single folder:
```
RePIT-AIDLC-{feature-name}-E1\
├── RePIT-AIDLC-{feature-name}-E1.md   ← single living document for entire feature
├── golfler_asp_2\                      ← cloned once, used across all phases
├── golfler_pos_2\                      ← cloned if in scope
└── sgs-cts-angular\                    ← cloned if in scope
```

**No extra rule needed here** — `/looper-plan` already checks out each repo's Release Branch from `looper-code\artifacts\project-structure.md` before creating Phase 1's branch (and each later phase chains off the previous phase's branch), so Path B was never affected by the Path A gap above. Noted here only so it's clear this was checked, not assumed.

### Step 2 — Map AIDLC units to RePIT phases

Open `bridge-docs\bridge-config.md` and populate the unit-to-phase mapping table under the active feature.

Each AIDLC unit becomes one RePIT phase:

| AIDLC Unit | RePIT Phase | Repos | Status |
|-----------|------------|-------|--------|
| Unit 1 name | Phase 1 | golfler_asp_2 | Pending |
| Unit 2 name | Phase 2 | golfler_pos_2 | Pending |
| Unit 3 name | Phase 3 | golfler_asp_2, sgs-cts-angular | Pending |

### Step 3 — Present construction plan

Display to user:
```
AIDLC Inception complete for feature: {feature-name}
{N} unit(s) → {N} phases in a single Looper RePIT:

  Phase 1: {unit-1-name}  — repos: {repo-list}
  Phase 2: {unit-2-name}  — repos: {repo-list}
  Phase 3: {unit-3-name}  — repos: {repo-list}

Task workspace: RePIT-AIDLC-{feature-name}-E1\
All repos will be cloned inside this single folder.

AIDLC design artifacts will be passed as context to /looper-plan.

Ready to start /looper-plan? (yes)
```

**Note**: Steps 4 and 5 below produce/update the RePIT — publish it per [Plan Publishing](#mandatory-plan-publishing-shared-repos) each time (RePIT created, and after each phase completes), never into the project repo(s).

### Step 4 — Run /looper-plan for the entire feature

**4a. Prepare context**
Gather all AIDLC design artifacts from `{FEATURE_ROOT}`:
- `{FEATURE_ROOT}\inception\units-generation\` — all unit descriptions (become phase descriptions)
- `{FEATURE_ROOT}\inception\application-design\` — component designs for all units
- `{FEATURE_ROOT}\inception\requirements\` — functional + non-functional requirements
- `aidlc-docs\reverse-engineering\` — codebase reference (shared, if available)

**4b. Task workspace**
Folder: `{bridge-workspace-root}\RePIT-AIDLC-{feature-name}-E1\`
All repo clones for the feature go here as siblings.

**4c. Update bridge-docs\bridge-config.md**
Set feature status: `Pending` → `In Progress`

**4d. Invoke /looper-plan**
Pass all AIDLC design artifacts as the initial context.
Structure the plan so that each AIDLC unit becomes one RePIT phase.
The AIDLC design reduces Step 2 (Research & Discovery) of looper-plan significantly — reference existing artifacts instead of re-researching what AIDLC already covered.

### Step 5 — Run /looper-implement

After the user approves the RePIT, run `/looper-implement`.
Looper executes phase by phase — one AIDLC unit per phase.
Each phase ends with commit + push for all repos changed in that phase.

**After each phase completes**: invoke the `knowledge-base-builder` agent per [Knowledge Base](#mandatory-knowledge-base), pointing it at that phase's section of the RePIT **and** the git diff of that phase's commits in each repo changed under `RePIT-AIDLC-{feature-name}-E1\{repo}\` — code changes often carry business logic the RePIT text doesn't capture.

### Step 6 — After all phases complete

- Update `bridge-docs\bridge-config.md`: `In Progress` → `Testing` (all phases implemented, verification pending — include all branch names). Do **not** set `Complete` yet; that happens after Step 7's build-checker pass.
- Log to `{FEATURE_ROOT}\audit.md`:
  ```
  ## Construction — {feature-name} (Looper)
  **Timestamp**: {ISO timestamp}
  **AI Response**: "Looper construction complete, entering Build & Test. Phases: {N}. Repos: {repo-list}. Branches: {branch-list}."
  **Context**: All {N} units implemented — verifying before marking Complete.
  ---
  ```

### Step 7 — Build and Test

After all phases complete:
1. Load and execute `construction\build-and-test.md`
2. Generate cross-unit integration test instructions
3. Invoke the `build-checker` agent (`.claude\agents\build-checker.md`) against `{bridge-workspace-root}\RePIT-AIDLC-{feature-name}-E1\` to confirm every repo touched across all phases actually compiles
4. Create files in `{FEATURE_ROOT}\construction\build-and-test\` (include the build-checker report)
5. If `build-checker` reports all present repos ✅ PASS: update `bridge-docs\bridge-config.md` `Testing` → `Complete`. If it reports any ❌ FAIL: keep status at `Testing`, surface the failing repo(s) and error output to the user, and do not mark `Complete` until a re-run passes.
6. Present completion (or the outstanding failures) to user

---

# OPERATIONS PHASE (Placeholder)

Load `operations\operations.md` from `.aidlc-rule-details\`.
Currently a placeholder for future deployment and monitoring workflows.

---

# Key Principles

## From AIDLC
- **Adaptive Execution**: Only run stages that add value; skip what doesn't apply
- **Transparent Planning**: Show the execution plan before starting each stage
- **User Control**: User can override stage inclusion/exclusion at any point
- **No Emergent Behavior**: Always use the standardized completion messages from rule files
- **Complete Audit Trail**: Every interaction logged in `{FEATURE_ROOT}\audit.md`

## From Looper
- **Workspace isolation**: Each feature gets ONE task workspace — all its repos cloned as siblings inside
- **Repo classification first**: Classify every repo as Change / Reference / Out-of-scope before cloning
- **RePIT is authoritative**: All implementation decisions recorded in the RePIT before executing
- **Phase gates**: Complete and push one phase before starting the next
- **Human tasks**: Never skip `[Human]` tasks — pause and wait for confirmation
- **Stop if uncertain**: If a change exceeds 300 lines or 5 files, or touches payments, stop and ask

## Bridge-Specific
- **One feature = one `aidlc-docs\{feature-name}\` subfolder**: Never mix feature docs
- **Looper task workspace only when Looper opted in**: `RePIT-AIDLC-{feature-name}-E1\` is created only if Looper was selected at Requirements Analysis
- **Reverse Engineering is shared**: `aidlc-docs\reverse-engineering\` is codebase-level, not feature-level
- **Inception owns WHAT, Construction owns HOW**: AIDLC Construction (Path A) or Looper (Path B) — never mix mid-feature
- **AIDLC design feeds Looper research (when Looper used)**: Pass AIDLC artifacts as context to reduce looper-plan research time
- **Bridge state stays current**: `bridge-docs\bridge-config.md` tracks all features and their phase status

---

# Known Constraints (acknowledged, not yet addressed)

These require restructuring live shared infrastructure (the `aidlc-docs`/`looper-code` Bitbucket repos, or the per-feature clone strategy) — deliberately not changed silently here. Flag to the user before acting on either:

- **Branch-per-feature in `aidlc-docs` doesn't scale for discoverability.** Every feature's docs live on their own permanently-diverging branch (`aidlc-docs/{feature-name}`) that never merges to `main`. At dozens of features, the repo's default branch shows nothing, and finding a feature's docs requires already knowing its branch name. A folder-per-feature layout on `main` (normal commits/PRs) would keep the repo browsable. The shared `aidlc-docs/knowledge-base` branch is a further mismatch — it's continuously-updated shared content riding alongside orphan per-feature branches built for a different lifecycle.
- **Every feature does a full fresh clone of every affected repo.** `AIDLC-{feature-name}\` and `RePIT-AIDLC-{feature-name}-E1\` each get their own complete clone of e.g. `golfler_asp_2`, `golfler_pos_2`, etc. With many concurrent features this multiplies disk usage. A shared local object cache with `git worktree` per feature branch (clone once, worktree per feature) would avoid the duplication, but changes how Repo Setup / Bridge Handoff Step 1 resolve repos.

---

# Directory Structure

```
{bridge-workspace-root}\
├── CLAUDE.md
├── HOW-TO-USE.md
├── SETUP.md
│
├── bridge-docs\
│   └── bridge-config.md              ← all features + unit status (multi-feature tracker)
│
├── .aidlc-rule-details\              ← bundled AIDLC rules + bridge extensions
│   ├── common\
│   ├── inception\
│   ├── construction\
│   ├── operations\
│   └── extensions\
│       ├── security\
│       ├── testing\
│       └── looper\
│           ├── looper.md             ← opt-in
│           └── looper.opt-in.md      ← presented at Requirements Analysis
│
├── aidlc-docs\
│   ├── reverse-engineering\          ← SHARED — one-time per codebase, not per feature
│   ├── knowledge-base\               ← SHARED — cross-feature, built by knowledge-base-builder agent
│   │   ├── index.md
│   │   ├── business-logic\
│   │   ├── flows\
│   │   └── decisions\
│   │
│   ├── {feature-name-1}\             ← Feature 1 (all docs scoped here)
│   │   ├── inception\
│   │   │   ├── plans\
│   │   │   ├── requirements\
│   │   │   ├── user-stories\
│   │   │   └── application-design\
│   │   ├── construction\
│   │   │   └── build-and-test\
│   │   ├── operations\
│   │   ├── aidlc-state.md
│   │   └── audit.md
│   │
│   └── {feature-name-2}\             ← Feature 2 (completely separate)
│       ├── inception\
│       ├── construction\
│       ├── aidlc-state.md
│       └── audit.md
│
├── RePIT-AIDLC-{feature-1}-E1\        ← only created when Looper opted in for feature-1
│   ├── RePIT-AIDLC-{feature-1}-E1.md  ← single RePIT, AIDLC units = phases
│   ├── golfler_asp_2\                  ← all in-scope repos cloned here as siblings
│   ├── golfler_pos_2\
│   └── sgs-cts-angular\
│
├── AIDLC-{feature-2}\                  ← only created when Looper NOT opted in (Path A) for feature-2
│   ├── golfler_asp_2\                  ← repos identified in Application Design/Units Generation, cloned here as siblings
│   └── golfler_pos_2\
│
├── looper-code\                        ← Looper harness (do not edit)
└── looper-code-artifacts\              ← stable codebase mirror (set up via /looper-setup)
    └── stable-codebase\
```

**CRITICAL:**
- Application code lives in a dedicated per-feature clone folder, never inside `aidlc-docs\` or `bridge-docs\`: `RePIT-AIDLC-{feature-name}-E1\` when Looper is opted in, `AIDLC-{feature-name}\` when using Path A
- AIDLC docs per feature: `aidlc-docs\{feature-name}\`
- Reverse Engineering (shared): `aidlc-docs\reverse-engineering\`
- Looper task workspace (`RePIT-AIDLC-{feature-name}-E1\`) only created when Looper opted in
- AIDLC Path A clone folder (`AIDLC-{feature-name}\`) only created when Looper is NOT opted in — repos are identified during Application Design/Units Generation and cloned once per feature during Construction's Repo Setup step
- The stable mirror (`looper-code-artifacts\stable-codebase\`) is always read-only reference — never edit it, never clone code changes directly on top of it
- When Looper used: AIDLC units map to RePIT phases — not to separate workspaces
- Bridge state: `bridge-docs\bridge-config.md`
