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

All references in this file to `inception\`, `construction\`, `common\`, `operations\` are relative to `.aidlc-rule-details\`.

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

---

## MANDATORY: Plan Publishing (Shared Repos)

**Plans are never left only on one machine.** AIDLC docs and RePIT plans are mirrored into their own shared git repos — never the project repo(s) being worked on — so any teammate can pull the plan and resume the task on their own machine. Cloned project repos (`golfler_asp_2`, etc.) are the one thing that stays local-only inside a task-workspace folder — they already push to their own remotes per phase/unit.

**Repos:**
| Content | Shared repo | Branch | Path inside repo |
|---|---|---|---|
| AIDLC docs | `git@bitbucket.org:definelabs/aidlc-docs.git` | `aidlc-docs/{feature-name}` | `{feature-name}\` (same layout as `aidlc-docs\{feature-name}\`) |
| RePIT plan | `git@bitbucket.org:definelabs/looper-code.git` (already cloned at `looper-code\`) | `repits/{repit-folder-name}` | `repits\{repit-folder-name}\` |

`{repit-folder-name}` is the exact task-workspace folder name (e.g. `RePIT-AIDLC-{feature-name}-E1` for Path B, or the RePIT name Looper generated directly). Using the identical folder name in both places means the same folder that lives at the workspace root also exists inside the shared repo — no renaming, no translation.

**Setup (first use in this workspace):**
- If `aidlc-docs\` is not already a git repo, do NOT `git init` a fresh history over existing content. Clone `git@bitbucket.org:definelabs/aidlc-docs.git` to a temp path, create/checkout an orphan-safe feature branch, copy the existing local `aidlc-docs\` content in on top, then replace the local folder with that clone (preserving `.git\`). Confirm with the user before doing this migration, and before any push.

**When to publish:**
- **AIDLC**: after every Inception stage is approved, and after every Construction unit-status change in `bridge-docs\bridge-config.md` — commit `aidlc-docs\{feature-name}\` on branch `aidlc-docs/{feature-name}` and push.
- **RePIT (Path B / Looper)**: after `/looper-plan` creates or updates the RePIT, and after each phase completes in `/looper-implement` — copy/update `{repit-folder-name}\{repit-folder-name}.md` into `looper-code\repits\{repit-folder-name}\`, commit on branch `repits/{repit-folder-name}`, and push.
- **Never** push the cloned project repos (`golfler_asp_2`, `sgs-cts-angular`, etc.) as part of either of the above — they are excluded (`.gitignore` them inside `looper-code\repits\{repit-folder-name}\` if ever cloned there by mistake).

**Pushing is a shared-system action** — confirm with the user before the first push of a new branch, per the risky-actions guidance. Routine same-branch pushes for an already-confirmed feature don't need to be re-confirmed every time unless the user asks otherwise.

**To resume on another machine**: pull the relevant branch (`aidlc-docs/{feature-name}` from `aidlc-docs`, and/or `repits/{repit-folder-name}` from `looper-code`), place the folder at the workspace root under its original name, then re-clone the project repos listed in `construction\repo-setup.md` (Path A) or the RePIT's repo list (Path B) as siblings — same as Repo Setup / Step 1 of the Bridge Handoff Protocol describe for a fresh run.

---

## MANDATORY: Feature Context

**Every AIDLC session is scoped to one feature.** All documentation for a feature is saved under `aidlc-docs\{feature-name}\`. This keeps multiple features isolated from each other in the same workspace.

### On Session Start — Determine the Active Feature

**Step 1: Scan for existing features**
List all subdirectories under `aidlc-docs\` (each subdirectory is one feature). Exclude `reverse-engineering\` — that is shared across all features.

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
Every path in this file that begins with `aidlc-docs\` (except `aidlc-docs\reverse-engineering\`) uses `FEATURE_ROOT` as its base.

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
| Security Baseline | `extensions\security\baseline\security-baseline.opt-in.md` | `security-baseline.md` | After user opts in — all phases |
| Property-Based Testing | `extensions\testing\property-based\property-based-testing.opt-in.md` | `property-based-testing.md` | After user opts in — Construction phase |
| Resiliency Baseline | `extensions\resiliency\baseline\resiliency-baseline.opt-in.md` | `resiliency-baseline.md` | After user opts in — all phases (blocking rules) |

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

**After every Inception stage approval**: publish `aidlc-docs\{feature-name}\` per [Plan Publishing](#mandatory-plan-publishing-shared-repos).

**Inception → Construction trigger**: When the user approves the final Inception stage output, the Construction phase begins.

---

# CONSTRUCTION PHASE

**Purpose**: Build each unit — generate code, run tests, verify quality.
**Default Owner**: AIDLC rules (Path A below)
**Optional**: If Looper was opted in during Requirements Analysis, use Path B (Bridge Handoff Protocol) instead of Path A Code Generation.

---

## Path A — AIDLC Native Construction (Default)

Execute when Looper is **not** opted in. Run the applicable AIDLC Construction stages for each unit. Load each stage's rules from `.aidlc-rule-details\construction\` before executing:

### Repo Setup (ALWAYS — before Code Generation)

1. **Identify affected repos**: read the repo list per unit from `{FEATURE_ROOT}\inception\application-design\` and `{FEATURE_ROOT}\inception\units-generation\` (or Requirements Analysis output if those stages were skipped).
2. **Determine the clone target folder**: `{bridge-workspace-root}\AIDLC-{feature-name}\` — one dedicated folder for the whole feature, sibling to the workspace root, created the first time Path A construction runs for this feature (not re-created per unit).
3. **Resolve each repo's source**, in order:
   a. Already cloned somewhere under the workspace root → use directly, do not re-clone
   b. Otherwise, clone fresh into `AIDLC-{feature-name}\{repo-name}\` — from the stable mirror's remote/origin if `looper-code-artifacts\stable-codebase\` exists (never clone or copy the mirror's working files directly — it is read-only, [see stable mirror rule]), otherwise from the repo's configured remote
4. Present the resolved repo list before cloning:
   ```
   Repos needed for {feature-name}:
     [1] golfler_asp_2      → AIDLC-{feature-name}\golfler_asp_2\
     [2] sgs-cts-angular    → AIDLC-{feature-name}\sgs-cts-angular\

   Confirm? (yes / adjust)
   ```
5. All subsequent Code Generation steps for this feature operate inside `AIDLC-{feature-name}\`, not the bare workspace root.

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

### Build & Test (ALWAYS — after all units)
Load and execute `construction\build-and-test.md`.
Generate cross-unit integration test instructions.
Output: `{FEATURE_ROOT}\construction\build-and-test\`
**Wait for explicit approval before proceeding.**

---

## Path B — Bridge Handoff Protocol (Looper opted in)

Execute when Looper IS opted in. AIDLC Code Generation is replaced by Looper's RePIT process.

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

### Step 6 — After all phases complete

- Update `bridge-docs\bridge-config.md`: `In Progress` → `Complete` (include all branch names)
- Log to `{FEATURE_ROOT}\audit.md`:
  ```
  ## Construction — {feature-name} (Looper)
  **Timestamp**: {ISO timestamp}
  **AI Response**: "Looper construction complete. Phases: {N}. Repos: {repo-list}. Branches: {branch-list}."
  **Context**: Construction phase complete — all {N} units implemented.
  ---
  ```

### Step 7 — Build and Test

After all phases complete:
1. Load and execute `construction\build-and-test.md`
2. Generate cross-unit integration test instructions
3. Create files in `{FEATURE_ROOT}\construction\build-and-test\`
4. Present completion to user

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
