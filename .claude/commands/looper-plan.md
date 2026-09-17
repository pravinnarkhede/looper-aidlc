# Rule: Generating a Research Plan Implement Test document (RePIT)

## Banner

Before doing anything else, read and output the banner from [artifacts/looper-code-banner.md](../artifacts/looper-code-banner.md).

## Goal

To guide an AI assistant in creating a detailed Research Plan Implement Test document (RePIT) in Markdown format, based on an initial user prompt. The RePIT should be clear, actionable, and suitable for a junior developer to understand and implement the feature. You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.


## Input Sources

The initial prompt can come from **either** of the following:

### Option A: Plain Text
The user provides a free-form description or request for a new feature or functionality directly in the chat.

### Option B: Jira Issue
The user provides a Jira issue key (e.g., `GOLF-123`) or a Jira issue URL. In this case:
1. Delegate to the `jira-repit-updater` agent with `action: fetch` and the ticket key. It returns the issue fields (summary, description, comments, labels, components, priority, reporter, assignee) — choosing MCP or REST internally.
2. Extract the following fields to use as the initial prompt context:
   - **Summary** → feature title
   - **Description** → feature details and background
   - **Acceptance Criteria** → seed the Functional Requirements and Success Metrics
   - **Labels / Components** → inform scope and technical considerations
   - **Priority** → note in the RePIT header
   - **Reporter / Assignee** → note as stakeholders
3. If the Jira description is sparse or missing acceptance criteria, proceed to the clarifying questions step as normal.

4. **If no parameters provided**, respond with:
```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a ticket file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a ticket file directly: `/looper-plan golfler_asp_2/docs/looper-code/repits/eng_1234.md`
For deeper analysis, try: `/looper-plan think deeply about golfler_asp_2/docs/looper-code/repits/`
```

## Workspace Convention

**Workspace root** = the parent directory of the `looper-code` repo the agent is currently running in (used only to determine where to create the task folder).

**Task workspace** = `<workspace_root>/<repit-name>/` — the isolated folder created in step 0 for this specific task. This is where `looper-code` is cloned and where all work happens.

For example, if the workspace root is `e:/development/r1/tasks/workspace2/release_5_4_41/` and the RePIT name is `RePIT-CCD-123-some-feature`, then the task workspace is `e:/development/r1/tasks/workspace2/release_5_4_41/RePIT-CCD-123-some-feature/`.

All repos (`golfler_asp_2` and any sibling repos: `golfler_pos_2`, `sgs-cts-angular`, `cc_mobile_pos`, `cc_api_manager`, `cc_membership_portal`, `cc_ios`, `cc_android`) **must** be cloned into — and searched for under — the **task workspace**, as siblings of each other. Never clone into the workspace root or any other directory, and never assume a repo is missing without first checking the task workspace.

### ⛔ GUARDRAIL: Derive Workspace from Environment — Never Guess

**Before doing anything else**, determine the correct workspace root from the actual runtime environment. Do NOT rely on memory, examples, or patterns from previous sessions.

**Required steps** (in order):

1. **Check the primary working directory** — the shell environment provides this (e.g., `e:\development\r1\tasks\TASK3`). This is your starting anchor.
2. **List the primary working directory** (`ls <primary_working_dir>`) to see what is actually present on disk.
3. **Check any IDE-opened files** in the conversation — their full paths reveal where `looper-code` lives (e.g., `e:\development\r1\tasks\TASK3\release_5_4_41\looper-code\...` → workspace root is `e:\development\r1\tasks\TASK3\release_5_4_41\`).
4. **Workspace root = the parent of the existing `looper-code` folder** — determine this by inspection only.
5. **State the resolved workspace root explicitly** before proceeding, e.g.:
   ```
   Workspace root resolved to: e:/development/r1/tasks/TASK3/release_5_4_41/
   (derived from: primary working directory + looper-code found at release_5_4_41/looper-code/)
   ```

**NEVER**:
- Guess or hard-code a path (e.g., `workspace/`, `workspace2/`) based on examples in this document or prior sessions
- Run `ls` on directories outside the primary working directory tree to hunt for the workspace
- Proceed to step 0 until the workspace root is confirmed from actual disk state

## Process

> **Version discipline:** The version format is `E.P.I` (Endeavour · Plan changes · Implementation phases completed). P stays at `0` throughout the initial planning pass (Steps 1–4). Only increment P when the user explicitly requests a change to the plan content after it has been presented for review. P may also be incremented by `looper-implement` when the user directs plan content changes mid-implementation (see Plan Change Protocol in looper-implement). When resuming a session, if the RePIT content has changed but P was not incremented, treat it as a user edit: increment P and append `| <new version> | user | Plan content updated outside of agent session |`. **I always starts at `0` in looper-plan** and is only incremented by `looper-implement` — once per completed phase (e.g. `3.0.0` → `3.0.1` after Phase 1).

0.  **Initialize Task Workspace:**

    Before anything else, set up an isolated folder for this task. **All three sub-steps below are mandatory. Do NOT proceed to step 1 until every sub-step is complete and verified.**

    1. **Determine the RePIT folder name** from the input (Jira key + short description, or `NOJIRA` + short description). Use the naming convention from `looper-code/README.md`: `RePIT-[JIRA-KEY]-[short-description]-E{N}` or `RePIT-NOJIRA-[short-description]-E{N}`. The `-E{N}` suffix is **always** present — E=1 for the first endeavour, E=2 for the second, etc. If the exact name can't be determined yet, use a temporary placeholder and rename once the prompt is fully parsed.

    1a. **Discover previous endeavours and confirm with user before creating anything** *(applies to both Jira and NOJIRA tasks)*:

       ⛔ **BLOCKER — Do NOT create the task folder or take any other action until BOTH checks below have returned a result (success or explicit failure).** Concluding "no previous endeavours" from only one source is a hard error.

       **For Jira tickets** — search two sources **in parallel** (single message, two simultaneous actions):
       - **Workspace root** — glob for `RePIT-<JIRA-KEY>-*-E*/` folders and `RePIT-<JIRA-KEY>-*-E*.md` files inside them.
       - **Jira comments** — delegate to the `jira-repit-updater` agent with `action: fetch` and the ticket key. The agent always includes `comment` in its fields and returns the full comment list. Filter comments whose body starts with `📋 RePIT plan — Endeavour` or `Implementation of RePIT — Endeavour`, and extract the endeavour number N from each matching comment header.

       > ⚠️ **Jira may be unavailable.** If `jira-repit-updater` reports that both MCP and REST are unavailable, do NOT silently skip — log it explicitly: `"Jira unavailable — comment check could not be completed."` Then proceed using only the local workspace result, and note the gap in the endeavour list presented to the user.

       **For NOJIRA tasks** — search one source only:
       - **Workspace root** — glob for `RePIT-NOJIRA-<short-description>-E*/` folders and `RePIT-NOJIRA-<short-description>-E*.md` files inside them. Match on the short description derived from the user's input.

       Merge and deduplicate by filename. Derive each endeavour's number from the `**RePIT Version:**` E digit inside the file, or fall back to the `-E{N}` suffix in the filename. Then present:

       ```
       I found N previous endeavour(s) for <JIRA-KEY or short-description>:

         [1] Endeavour 1 — RePIT-CCD-123-some-feature-E1.md
             Version: 1.2.3  |  Source: workspace

         [2] Endeavour 2 — RePIT-CCD-123-some-feature-E2.md
             Version: 2.1.0  |  Source: Jira comment (plan)  ← (Jira only)

         [3] Endeavour 3 — RePIT-CCD-123-some-feature-E3.md
             Version: 3.0.0  |  Source: Jira comment (implementation)  ← (Jira only)

       Would you like to:
         A. Continue a previous endeavour (reply with the number, e.g. "A1" or "A2")
         B. Start a new endeavour (E = N+1)
       ```

       **If continuing an existing endeavour:**
       - Do NOT reset P or I — continue from the version already in that file
       - If the task folder **already exists locally** → use it as-is; read the RePIT file from inside it
       - If the task folder **does NOT exist locally** *(Jira only — found only as a Jira attachment)* → create the folder (`<workspace_root>/<repit-name>-E{N}/`), download the RePIT file from the Jira attachment into it, then continue
       - If the task folder **does NOT exist locally** *(NOJIRA)* → this should not happen (workspace is the only source); warn the user and stop: the folder may have been deleted or moved

       **Status Assessment (mandatory when continuing):**

       After loading the existing RePIT, assess the current state of the endeavour before doing anything else. Run all three checks in parallel:

       1. **Task progress** — Read the full RePIT file. Count and list:
          - Completed tasks (`- [x]`): list parent task titles
          - Pending tasks (`- [ ]`): list parent task titles
          - Open Questions still unresolved
          - Current `**RePIT Version:**` and Changelog tail (last 3 rows)

       2. **Git branch state** — For each repo present in the task workspace, run:
          ```bash
          git -C "<task_workspace>/<repo>" branch -a --sort=-committerdate | head -20
          git -C "<task_workspace>/<repo>" log --oneline -5
          ```
          Report: which feature branches exist, the latest commit message per branch, and whether any branches have uncommitted changes (`git status --short`).

       3. **Repo presence** — List `<task_workspace>` to confirm which repos are already cloned vs still missing.

       Then present a concise **Continuation Summary** to the user before proceeding:

       ```
       ── Endeavour {N} Status ─────────────────────────────
       RePIT Version : {version}
       File          : {repit-filename}.md

       Task Progress:
         ✅ Done  ({X} tasks): [Phase 1 – Backend Changes], [Phase 1 – Angular CCOnline], …
         🔲 Pending ({Y} tasks): [Phase 2 – WPF PosApp], [Phase 3 – Testing], …

       Git Branches (per repo):
         golfler_asp_2   : feature/some-feature/phase-1 (last: "fix(CCD-123): add endpoint")
         sgs-cts-angular : feature/some-feature/phase-1 (last: "feat(CCD-123): booking form")
         golfler_pos_2   : ❌ not cloned

       Open Questions: {Z} unresolved (see RePIT §Open Questions)

       What would you like to do?
         A. Continue implementation from the next pending task → hand off to /looper-implement
         B. Update or extend the plan (add phases, revise tasks, change scope)
         C. Start fresh as a new endeavour (E = {N+1})
       ──────────────────────────────────────────────────────
       ```

       - If the user selects **A**: skip the rest of looper-plan; surface the next pending task and instruct the user to run `/looper-implement` with that context.
       - If the user selects **B**: continue into Steps 1–5 of looper-plan with the existing RePIT pre-loaded (no need to re-create from template). Only update sections the user wants to change; preserve all `[x]` checked tasks.
       - If the user selects **C**: treat as a new endeavour (E = N+1) and proceed from sub-step 2 below.

       **If starting a new endeavour (or no previous endeavours):**
       - E = total previous endeavours + 1
       - version = `E.0.0`
       - Folder and file always named with `-E{N}` suffix

       **If no previous endeavours exist:** proceed directly to sub-step 2 with E = 1.

    2. **Create the task folder** in the workspace root:
       ```bash
       mkdir "<workspace_root>/<repit-name>"
       ```

    3. **Provision `golfler_asp_2` — conditional on task-inferred scope.** ASP must be available for every task (DTOs, table references) but does not always need a per-task clone. **Infer both the scope and the intended base branch from the task**, then provision accordingly. Scope and base branch are independent inferences: scope decides *whether we will write to ASP*; the base branch decides *which branch we read or write against*.

       **3a. Detect `stable_present`** — does the shared stable-codebase clone exist?
       ```bash
       [ -d "<workspace_root>/looper-code-artifacts/stable-codebase/golfler_asp_2/.git" ] && echo "stable_present=true" || echo "stable_present=false"
       ```

       **3b. Infer the intended base branch from the task.** Use the first signal that yields a value:
       1. The branch task in the RePIT (e.g. `feature/<repit-name>/phase-{N}`) — if the RePIT exists and lists one for `golfler_asp_2` (continuation).
       2. An explicit base-branch value provided at `/looper-plan` invocation (e.g. resuming a teammate's feature branch).
       3. Default: the stable branch from `looper-code/artifacts/project-structure.md` (currently `release_5_4_41`).

       A base branch is **stable** if its name matches the ASP stable branch from `project-structure.md`; otherwise it is **non-stable**.

       **3c. Infer `asp_scope` from the task** — one of **Change** / **Reference** / **No-change**:
       - **Continuation (a RePIT already exists)** — the RePIT is authoritative. ASP is **Change** if *either*:
         - its `## Repos & Projects Affected` table has at least one `golfler_asp_2` row whose Change Summary is not literally `N/A`, `out of scope`, or empty, **or**
         - its `## Implementation` section contains any task (checked or unchecked) under a `golfler_asp_2` subsection.

         Otherwise it is **Reference**.
       - **New task (no RePIT yet)** — infer from the ticket/prompt text:
         - Backend (`golfler_asp_2`) code changes are needed → **Change**.
         - The task only needs to *read* backend code (DTOs, table references, API contracts) → **Reference**.
         - Backend is neither changed nor read → **No-change**.
         - **Unsure → default to `Change`.** If you cannot confidently classify Change vs Reference from the task text, treat ASP as **Change** and clone the base branch. Do **not** pause to ask, and do **not** default to Reference. A writable clone is harmless and cheap to ignore; a missing clone blocks implementation later, and the Step 2a reconciliation can promote Reference→Change but cannot un-clone — so erring toward Change is always the safe direction.

       > Reference and No-change provision **identically** — the distinction is only semantic. ASP is never fully out-of-scope; it must always be available (per-task clone or stable mirror).

       **3d. Provision.**

       - **`asp_scope = Change`** → fresh per-task clone, then check out the **intended base branch** (3b):
         ```bash
         git clone --depth=1 git@bitbucket.org:definelabs/golfler_asp_2.git "<workspace_root>/<repit-name>/golfler_asp_2"
         ```
         - If the RePIT exists and has `- [x]` checked tasks → find the **highest Phase number** with at least one checked task (this is active phase N), then:
           ```bash
           git -C "<workspace_root>/<repit-name>/golfler_asp_2" branch -a | grep "feature/.*phase-{N}"
           ```
           If found → `git checkout feature/<repit-name>/phase-{N}`. If NOT found → fall back to `git checkout <stable-branch>` and surface:
           > ⚠️ Expected branch `feature/<repit-name>/phase-{N}` not found in the cloned repo. Checked out stable branch instead. Verify the feature branch was pushed before continuing.
         - Else if a non-stable base branch was inferred (explicit invocation) → `git checkout <that branch>`. If missing → fall back to `git checkout <stable-branch>` with the same warning pattern as above.
         - Else → `git checkout <stable-branch>`.

         **Verify:** `ls "<workspace_root>/<repit-name>/golfler_asp_2"`. If empty or the command fails, fix the clone before continuing.

       - **`asp_scope = Reference` or `No-change`** — the base branch decides whether the stable mirror can serve the read:

         - **Base is stable AND `stable_present = true`** → **skip the per-task clone**. Do NOT create `<workspace_root>/<repit-name>/golfler_asp_2`. Agents read from the mirror. Surface this banner once:
           ```
           ℹ️  ASP is reference-only — skipping per-task clone.
              Agents will read from the shared stable-codebase clone:
                <workspace_root>/looper-code-artifacts/stable-codebase/golfler_asp_2 (release_5_4_41)
              Re-run /looper-setup Step 6 to refresh the stable clone.
           ```
           **Verify:** `ls "<workspace_root>/looper-code-artifacts/stable-codebase/golfler_asp_2"` and confirm directory contents.

         - **Base is stable AND `stable_present = false`** → fall back to a fresh per-task clone of the **stable** branch and surface:
           ```
           ⚠️  Stable codebase not provisioned — falling back to per-task golfler_asp_2 clone.
              Run /looper-setup (Step 6 = y) to provision the stable clone and avoid this on future tasks.
           ```
           Then `git clone` and `git checkout <stable-branch>` (no feature-branch detection — this is reference-only).

         - **Base is non-stable** → the stable mirror cannot serve a non-stable base, so make a fresh per-task clone of the **intended base branch** (3b) regardless of `stable_present`:
           ```bash
           git clone --depth=1 git@bitbucket.org:definelabs/golfler_asp_2.git "<workspace_root>/<repit-name>/golfler_asp_2"
           git -C "<workspace_root>/<repit-name>/golfler_asp_2" checkout <intended-base-branch>
           ```
           Surface:
           ```
           ℹ️  ASP reference base (<intended-base-branch>) differs from stable — provisioning a per-task clone of <intended-base-branch>.
           ```
           **Verify:** `ls "<workspace_root>/<repit-name>/golfler_asp_2"`. If empty or the checkout fails, fix the clone before continuing.

       Do NOT proceed to step 4 until ASP is resolvable: either the per-task clone is present and verified, or the stable-codebase clone is confirmed.

    4. **Clone other in-scope repos and check out the correct branch** *(continuation only — skip for new endeavours).*

       This step only runs when continuing an existing endeavour that has `- [x]` checked tasks in the RePIT (i.e. implementation is already underway).

       **Process — run all clone + checkout operations in parallel (single message, multiple agents):**

       1. Read the RePIT's `## Repos & Projects Affected` table to identify every repo that is in-scope (marked ✅ or equivalent).
       2. Exclude `golfler_asp_2` — already handled in step 3.
       3. For each remaining in-scope repo:
          - Determine the active phase N (highest Phase with at least one `- [x]` task in that repo's subsection).
          - Clone the repo into the task workspace:
            ```bash
            git clone --depth=1 git@bitbucket.org:definelabs/<repo>.git "<task_workspace>/<repo>"
            ```
            Use clone URLs and repo names from `looper-code/artifacts/project-structure.md`.
          - After cloning, check out the correct branch:
            - If a `feature/<repit-name>/phase-{N}` branch exists for that repo → check it out.
            - If NOT found → check out the stable branch and warn:
              > ⚠️ Expected branch `feature/<repit-name>/phase-{N}` not found in `<repo>`. Checked out stable branch instead. Verify the feature branch was pushed before continuing.
       4. Summarise results: which repos were cloned, which branch each is on, and any warnings.

    ✅ **Checkpoint:** Before proceeding to step 1, confirm all sub-steps are done:
    - [ ] Task folder created at `<workspace_root>/<repit-name>/`
    - [ ] `golfler_asp_2` resolvable per Step 0.3 — **either** a per-task clone exists at `<workspace_root>/<repit-name>/golfler_asp_2` with the correct branch checked out (intended base / feature-phase-N), **or** (Reference/No-change on a stable base with the mirror present) the stable mirror at `<workspace_root>/looper-code-artifacts/stable-codebase/golfler_asp_2` is confirmed
    - [ ] *(Continuation only)* All other in-scope repos cloned and on their correct feature branches

    All subsequent work for this task — the RePIT file, implementation branches, and any other repo clones — lives under `<workspace_root>/<repit-name>/`.

1.  **Receive Initial Prompt:** Accept input as plain text **or** a Jira issue key/URL (see Input Sources above). Then **immediately create the RePIT file** from the template with `TBD` in every content field, and save it to `<workspace_root>/<repit-name>/` (the task folder created in step 0) using the naming convention from `looper-code/README.md` — `RePIT-[JIRA-KEY]-[short-description]-E{N}.md` if a Jira ticket was provided, or `RePIT-NOJIRA-[short-description]-E{N}.md` otherwise. The `-E{N}` suffix is always present. The document will be filled in progressively as each step completes — never left empty until the end.

    **Set initial version and contributors table:** In the newly created file:
    - Set `**RePIT Version:** E.0.0` (where E is the endeavour number from step 0)
    - Populate the `## Contributors` section table with the current session's row:
      - **Author** — resolve via `git config user.name` inside any cloned repo in the task workspace
      - **Agent** — read `looper-code/VERSION` and format as `looper-code v{VERSION}` (e.g. `looper-code v0.3.0`)
      - **AI Model** — the Claude tool and model in use for this session, formatted as `Claude Code — {model}` (e.g. `Claude Code — Sonnet 4.6`). Derive the model short name from the active model ID: `claude-sonnet-4-6` → `Sonnet 4.6`, `claude-opus-4-7` → `Opus 4.7`, `claude-haiku-4-5` → `Haiku 4.5`
      - **Date** — today's date in `YYYY-MM-DD` format
    - Write the first Changelog row:
    ```
    | E.0.0 | {name} | Initial plan created |
    ```

    **Contributor accumulation (applies on every looper-plan run, including continuations):** At the start of any session — new endeavour or continuation — resolve the current user's name and looper-code version. If a row with the same **Author + Agent + Date** combination does not already exist in the `## Contributors` table, append a new row. Never duplicate an identical row. A returning author on a different date or with a different agent version gets a new row.

2.  **Context Gathering & Initial Analysis:**

    ### Step 1: Context Gathering & Initial Analysis

    0. **Determine and record the task workspace**: The task workspace is the folder created in step 0 — `<workspace_root>/<repit-name>/`. Store this as a concrete absolute path (e.g. `e:/development/r1/tasks/TASK3/release_5_4_41/RePIT-CCD-123-some-feature/`). Every sub-agent you spawn for the rest of this process MUST receive this path in their prompt with the instruction: `"IMPORTANT: Restrict ALL file searches, reads, and globs strictly to the task workspace: <task_workspace>. Do NOT access any path outside this directory."`

    1. **Read all mentioned files immediately and FULLY**:
       - Ticket files (e.g., `thoughts/allison/tickets/eng_1234.md`)
       - Research documents
       - Related implementation plans
       - Any JSON/data files mentioned
       - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
       - **CRITICAL**: DO NOT spawn sub-tasks before reading these files yourself in the main context
       - **NEVER** read files partially - if a file is mentioned, read it completely

    2. **Infer initial scope from ticket and files already read**:
       Without spawning any agents, reason from the ticket description and any files read in step 1 to form a working hypothesis. If a Jira ticket was provided and full details are not yet in context, delegate to the `jira-repit-updater` agent with `action: fetch` and the ticket key to retrieve them now before inferring:

       - Which repos and projects are likely in scope (backend, Angular, WPF, PHP, mobile)?
       - What kind of changes are probably needed (database schema, API endpoint, frontend UI, consumer apps)?
       - What is the key technical area (e.g. voucher validation, payment flow, booking logic)?
       - Are there any obvious risks or constraints visible from the ticket alone?

       Record this as a short bullet-point summary internally. It will guide which agents to spawn in Step 2 and which repos to check in step 3.

    2a. **Present inferred scope to user and classify each repo (Change / Reference / Out-of-scope)**:
       Before cloning or researching anything, present the repo list with the **base branch** for each repo (from `looper-code/artifacts/project-structure.md`'s Release Branch column) and ask the user to classify each candidate.

       ⛔ **ALWAYS show the FULL table — all 9 rows — on every run.** (`cc_mobile_pos` is two rows: the Flex App and the FnB App ship from different branches.) Never abbreviate it, never drop rows you think are irrelevant, and never present an inferred subset. The rows themselves are fixed. Inference fills two columns: the **Decided** column shows your single inferred classification per row (one icon — ✏️, 🔍, ❌, or ❔ — not the whole set), and the **Notes** column explains why (e.g. "backend API changes" vs "candidate — no changes expected"). The Decided icon is a pre-filled default the user can override; render exactly as below:

       ```
       Decided  Repo                    Base branch                                              Notes
       ✏️  [1]  golfler_asp_2           release_5_4_41                                           always present (Step 0.3); backend API changes
       ✏️  [2]  golfler_pos_2           release_5_4_41                                           WPF POS fix
       ✏️  [3]  sgs-cts-angular         teesheet_v2_step617                                      Angular CCOnline fix
       🔍  [4]  cc_mobile_pos (Flex)    release                                                  candidate — read-only to confirm API contract
       ❔  [5]  cc_mobile_pos (FnB)     fnb_step188                                              undecided — may need changes; research to confirm
       ❌  [6]  cc_api_manager          release                                                  candidate — no changes expected
       ❌  [7]  cc_membership_portal    release                                                  candidate — no changes expected
       ❌  [8]  cc_ios                  master                                                   candidate — no changes expected
       ❌  [9]  cc_android              rtj_and_validation_punch_promo_release_7_04_Multi_Course_New_UI  candidate — no changes expected
       ```

       Decided icon (left column): ✏️ change · 🔍 reference · ❌ out-of-scope · ❔ undecided (research to decide) — one inferred default shown per row, which the user can override.

       ```
       For each repo, reply with one of: ✏️ change | 🔍 reference | ❌ out-of-scope | ❔ undecided (I'll research it).

       Default if you say "confirm" without per-repo flags:
         - rows I marked as likely affected → 🔍 reference
         - rows I marked ❔ undecided       → research first, then resolve to ✏️ / 🔍 / ❌
         - rows I marked as unlikely        → ❌ out-of-scope
       You can also reply with shorthand like "1=change, 3=change, 4=out, rest=reference".
       ```

       Classification semantics:
       - **✏️ Change** — this repo will be modified by the task. Step 3 will create a per-task clone of it.
       - **🔍 Reference** — read-only research. Step 3 will NOT clone; agents read from `<workspace_root>/looper-code-artifacts/stable-codebase/<repo>/`. Falls back to a fresh clone only if the stable mirror is missing for that repo.
       - **❌ Out-of-scope** — ignored entirely; agents must not access it.
       - **❔ Undecided** — inference can't yet tell whether this repo needs changes. Treated like 🔍 reference for provisioning (read from the stable mirror, no per-task clone), but Step 3 MUST research it and then resolve it to ✏️ change, 🔍 reference, or ❌ out-of-scope before the plan is finalized — no row may remain ❔ at the end of Step 2a once the user confirms.

       **Do not proceed to step 3 until the user has classified every repo (explicitly or via the "confirm" default).** Update the table based on user responses and confirm once more before continuing.

       **ASP reconciliation.** ASP was already physically provisioned at Step 0.3 using task-inferred scope and base branch. After Step 2a captures the user's explicit ASP classification, reconcile:
       - **User said ✏️ Change** AND `<workspace_root>/<repit-name>/golfler_asp_2/` does NOT exist (Step 0.3 inferred Reference/No-change and read from the mirror) → run the same fresh clone Step 0.3 documents, checking out the **intended base branch** (3b — default stable):
         ```bash
         git clone --depth=1 git@bitbucket.org:definelabs/golfler_asp_2.git "<workspace_root>/<repit-name>/golfler_asp_2"
         cd "<workspace_root>/<repit-name>/golfler_asp_2" && git checkout <intended-base-branch>
         ```
         Surface: `ℹ️  ASP is now in scope — provisioning per-task clone of golfler_asp_2.`
       - **User said 🔍 Reference** AND a per-task ASP clone already exists → leave it; no demotion. Note: `the per-task ASP clone already exists; leaving it in place.`
       - **User said ❌ Out-of-scope for ASP** → not allowed. ASP must always be present. Re-prompt for Change vs Reference only.

    3. **Provision in-scope repos — apply per-repo Change / Reference classification from step 2a**:
       Walk every repo the user classified at step 2a (skip `golfler_asp_2` — it was already handled by Step 0.3 + the ASP reconciliation at the end of step 2a). For each repo R, follow the decision rule below. Use `looper-code/artifacts/project-structure.md` for clone URLs and stable branch names.

       **Per-repo decision rule:**

       1. **Already in task workspace?** If `<workspace_root>/<repit-name>/<R>/.git` exists → leave it alone (continuation case; an existing clone is authoritative).
       2. **R is ✏️ Change** → fresh per-task clone. Spawn a **separate `general-purpose` agent** for each Change repo and launch all of them **in a single message** (parallel). Each agent runs:
          ```bash
          git clone --depth=1 git@bitbucket.org:definelabs/<R>.git "<workspace_root>/<repit-name>/<R>"
          cd "<workspace_root>/<repit-name>/<R>" && git checkout <stable-branch>
          ```
          and reports back: repo name, `CLONED` or `FAILED`, and any error message.
       3. **R is 🔍 Reference AND stable mirror present** (`<workspace_root>/looper-code-artifacts/stable-codebase/<R>/.git` exists) → **skip clone**. Record `<R>_REF_PATH = <workspace_root>/looper-code-artifacts/stable-codebase/<R>` for downstream agent prompts. Surface:
          ```
          🔍 <R> — reference-only, reading from stable mirror (<stable-branch>).
          ```
       4. **R is 🔍 Reference AND stable mirror absent** → fall back to a fresh per-task clone (same command as step 2 above) and surface:
          ```
          ⚠️  <R> classified as reference, but stable codebase missing — cloning into task workspace instead.
             Run /looper-setup (Step 6 = y) to provision stable for future tasks.
          ```
       5. **R is ❌ Out-of-scope** → do nothing; agents must not access it.

       **⚠️ Wait for ALL clone agents (Change set + Reference fallbacks) to return before proceeding to step 4.** Do not spawn research agents until every clone attempt has completed (succeeded or failed).

       **Summarize at the end of step 3** which repos were cloned (Change set + Reference fallbacks), which resolved to the stable mirror, which were ignored, and which failed.

    4. **Spawn initial research tasks to gather context**:
       Before asking the user any questions, use specialized agents to research in parallel.

       > ⚠️ **GUARDRAILS — strictly enforced:**
       > - Search only repos under (a) the task workspace, or (b) the stable-codebase mirror — both confirmed present in step 3
       > - Do NOT search outside these two roots
       > - Do NOT attempt to read, glob, or grep paths in repos that were neither cloned per-task nor available in the stable mirror
       > - Writes are only permitted under the task workspace; the stable-codebase mirror is read-only
       > - If a relevant repo is missing from BOTH roots, note it as unavailable — do not try to access it
       > - **Every sub-agent prompt MUST start with:** `"IMPORTANT: Restrict ALL file searches, reads, and globs to (a) the task workspace: <task_workspace>, and (b) the stable-codebase mirror: <workspace_root>/looper-code-artifacts/stable-codebase/. Do not access any path outside these two roots. Writes are only permitted under the task workspace."` (substitute the actual task workspace path from step 2.0)

       **Repo resolution rule for sub-agents** — include this in every spawn prompt alongside the guardrails above:

       > When resolving `<repo>/<sub-path>`:
       > 1. Try `<workspace_root>/<repit-name>/<repo>/<sub-path>`. If it exists, use it.
       > 2. Otherwise, fall back to `<workspace_root>/looper-code-artifacts/stable-codebase/<repo>/<sub-path>`.
       > 3. If neither exists, the repo is unavailable — note it and continue without accessing it.

       - Use the **codebase-locator** agent to find all files related to the ticket/task
       - Use the **codebase-analyzer** agent to understand how the current implementation works
       - If relevant, use the **thoughts-locator** agent to find any existing thoughts documents about this feature

       These agents will:
       - Find relevant source files, configs, and tests
       - Identify the specific projects to focus on (Club Caddie has a multi-project architecture — backend code lives in this project, but consumers are in separate projects):
           - **Database Changes**
           - **API Changes for PosApi Project**
           - **API Changes for GolferApi Project**
           - **Changes for PosApi Consumers**: WPF PosApp, Angular CCOnline App, FnB React Native App, Mobile POS App (React Native)
           - **Changes for GolferApi Consumers**: API Manager (PHP CodeIgniter), Member Portal (PHP CodeIgniter), Android Mobile App (Kotlin), iOS App (Swift)
       - Trace data flow and key functions
       - Return detailed explanations with file:line references

    5. **Re-check repos after research — apply the same Change / Reference rule**:
       Research agents may have identified additional repos as relevant. For each newly identified repo, ask the user to classify it (✏️ Change / 🔍 Reference / ❌ Out-of-scope) using the same prompt format as step 2a, then apply the same per-repo decision rule from step 3.

       > ⚠️ **GUARDRAILS — strictly enforced:**
       > - Only act on repos listed in `looper-code/artifacts/project-structure.md`
       > - Clone targets are the task workspace ONLY; never clone outside it
       > - Reads are permitted from (a) the task workspace and (b) the stable-codebase mirror; never outside these two roots
       > - Writes are only permitted under the task workspace
       > - **Every sub-agent prompt MUST start with:** `"IMPORTANT: Restrict ALL file searches, reads, and globs to (a) the task workspace: <task_workspace>, and (b) the stable-codebase mirror: <workspace_root>/looper-code-artifacts/stable-codebase/. Do not access any path outside these two roots. Writes are only permitted under the task workspace."` (substitute the actual task workspace path from step 2.0)

       **Process:**
       1. List repos that research surfaced but were not classified at step 2a.
       2. Present them to the user with base branches (same UI as step 2a) and collect a classification per repo.
       3. For each classified repo, apply the **per-repo decision rule from step 3**:
          - ✏️ Change → spawn a `general-purpose` clone agent (parallel with the others).
          - 🔍 Reference AND stable mirror present → skip clone; record `<R>_REF_PATH`; surface the 🔍 banner.
          - 🔍 Reference AND stable mirror absent → fall back to fresh per-task clone with the ⚠️ banner.
          - ❌ Out-of-scope → ignore.
       4. **⚠️ Wait for ALL clone agents (Change set + Reference fallbacks) to return before proceeding to step 6.** Do not continue until every clone attempt has completed.
       5. Summarize: which repos were cloned, which resolved to the stable mirror, which were ignored, and which failed.

    6. **Read all files identified by research tasks**:
       - After research tasks complete, read ALL files they identified as relevant
       - Read them FULLY into the main context
       - This ensures you have complete understanding before proceeding

    7. **Analyze and verify understanding**:
       - Cross-reference the ticket requirements with actual code
       - Identify any discrepancies or misunderstandings
       - Note assumptions that need verification
       - Determine true scope based on codebase reality

    8. **Present informed understanding and focused questions**:
       ```
       Based on the ticket and my research of the codebase, I understand we need to [accurate summary].

       I've found that:
       - [Current implementation detail with file:line reference]
       - [Relevant pattern or constraint discovered]
       - [Potential complexity or edge case identified]

       Questions that my research couldn't answer:
       - [Specific technical question that requires human judgment]
       - [Business logic clarification]
       - [Design preference that affects implementation]
       ```

       Only ask questions that you genuinely cannot answer through code investigation.

    9. **If questions go unanswered for 10 minutes**, do not wait indefinitely — record each unanswered question verbatim in the RePIT's **Open Questions** section, including all options presented, then continue to the next step using the most reasonable default assumption. Note the assumption made alongside the open question.

    10. **Update the RePIT document** — replace `TBD` markers in:
       - **Overview** — draft the 1-2 sentence summary based on the ticket
       - **Problem Statement** — fill in from ticket description and initial findings
       - **Repos & Projects Affected** — populate the table with every repo and project identified as in-scope so far; mark anything not yet confirmed as TBD
       - **Dependencies** — list any already-identified external systems or APIs

3.  **Research & Discovery:**

    ### Step 2: Research & Discovery

    After getting initial clarifications:

    1. **If the user corrects any misunderstanding**:
       - DO NOT just accept the correction
       - Spawn new research tasks to verify the correct information
       - Read the specific files/directories they mention
       - Only proceed once you've verified the facts yourself

    2. **Create a research todo list** using TodoWrite to track exploration tasks

    3. **Spawn parallel sub-tasks for comprehensive research**:
       - Create multiple Task agents to research different aspects concurrently
       - Use the right agent for each type of research:

       **For deeper investigation:**
       - **codebase-locator** - To find more specific files (e.g., "find all files that handle [specific component]")
       - **codebase-analyzer** - To understand implementation details (e.g., "analyze how [system] works")
       - **codebase-pattern-finder** - To find similar features we can model after

       **For historical context:**
       - **thoughts-locator** - To find any research, plans, or decisions about this area
       - **thoughts-analyzer** - To extract key insights from the most relevant documents

       **For related tickets:**
       - Delegate to the `jira-repit-updater` agent with `action: search` and a JQL string to find similar issues or past implementations

       Each agent knows how to:
       - Find the right files and code patterns
       - Identify conventions and patterns to follow
       - Look for integration points and dependencies
       - Return specific file:line references
       - Find tests and examples

    4. **Wait for ALL sub-tasks to complete** before proceeding

    5. **Present findings and design options**:
       ```
       Based on my research, here's what I found:

       **Current State:**
       - [Key discovery about existing code]
       - [Pattern or convention to follow]

       **Design Options:**
       1. [Option A] - [pros/cons]
       2. [Option B] - [pros/cons]

       **Open Questions:**
       - [Technical uncertainty]
       - [Design decision needed]

       Which approach aligns best with your vision?
       ```

    6. **If no response within 10 minutes**, record all design options presented in the RePIT's **Open Questions** section, pick the most appropriate option based on the codebase research, state the choice and reasoning clearly, then continue with the next step.

    7. **Update the RePIT document** — replace `TBD` markers in:
       - **Design Considerations** — fill in architecture notes, existing patterns to follow, risks discovered
       - **Dependencies** — complete with all identified systems
       - **Backend Changes / Consumer Changes** — populate section structure based on what's in scope (mark N/A for anything confirmed out of scope)

4.  **Plan Structure Development:**

    ### Step 3: Plan Structure Development

    Once aligned on approach:

    1. **Create initial plan outline**:
       ```
       Here's my proposed plan structure:

       ## Overview
       [1-2 sentence summary]

       ## Implementation Phases:
       1. [Phase name] - [what it accomplishes]
       2. [Phase name] - [what it accomplishes]
       3. [Phase name] - [what it accomplishes]

       Does this phasing make sense? Should I adjust the order or granularity?
       ```

    2. **Get feedback on structure** before writing details. If no feedback is provided within 10 minutes, proceed with the proposed structure as-is.

    3. **Update the RePIT document** — replace remaining `TBD` markers in:
       - **Goals** and **Non-Goals** — finalize based on agreed scope
       - **Functional Requirements** — write out each requirement clearly
       - **Non-Functional Requirements** — add performance, security, compatibility notes
       - **Open Questions** — list anything still unresolved

5.  **Finalize RePIT:** Review the document end-to-end. Confirm no `TBD` markers remain. Present to the user for approval.

    - If the user **requests changes** (revises requirements, scope, design, phases, or task descriptions), apply the change, then:
      1. Increment P in `**RePIT Version:**`
      2. Append a row to `## Changelog`: `| <new version> | {name} | <one-line summary of what the user changed> |` — where `{name}` is resolved via `git config user.name`
      3. If a Jira ticket is associated, offer to post the updated RePIT now: `"Plan updated to {new-version}. Post updated RePIT to Jira <JIRA-KEY>? Reply 'yes' or 'skip'."` — if yes, delegate to `jira-repit-updater` (attach updated file; no new plan comment needed, just replace the attachment).
      Repeat until the user approves.
    - If the user **approves with no changes**, version stays at `E.0.0`.

    Once approved, immediately generate the complete task list (parent tasks **and** sub-tasks together) and embed it directly into the RePIT document — do not wait for a second "Go" prompt.

    **Re-evaluate per-repo scope after finalization.** Earlier steps (0.3 for ASP, 2a/3/5 for the rest) classified each repo as Change or Reference using the best signals available at the time. Now that the RePIT is authoritative, walk every row of its `## Repos & Projects Affected` table. For each repo R whose Change Summary is **not** literally `N/A`, `out of scope`, or empty AND for which `<workspace_root>/<repit-name>/<R>/` does NOT exist, do the promotion clone now:
    ```bash
    git clone --depth=1 git@bitbucket.org:definelabs/<R>.git "<workspace_root>/<repit-name>/<R>"
    cd "<workspace_root>/<repit-name>/<R>" && git checkout <stable-branch>
    ```
    Surface one banner per promoted repo:
    ```
    ℹ️  <R> is now in scope — provisioning per-task clone.
    ```
    ASP folds into the same walk — no separate ASP-only path. Demotion (in-scope → reference-only) is not auto-handled: an existing per-task clone is left in place. Delete `<workspace_root>/<repit-name>/<R>` manually to release disk if desired; the next `/looper-plan` invocation will not recreate it.

6.  **Offer Jira update** *(only if the input was a Jira issue key/URL)*: After the task list is embedded and the RePIT file is saved:

    ⛔ **NEVER interact with Jira directly** — no `mcp__claude_ai_Atlassian__*` tool calls, no REST/curl commands. Always delegate every Jira operation (fetch, search, comment, attach) to the `jira-repit-updater` agent. It selects MCP or REST internally and handles auth, encoding, and retry logic.

    **Before asking the user**, append this session's cost to the `## Sessions` table in the RePIT `.md` file:

    - If the `## Sessions` table already exists (continuation), **append a new row** for this session and **recalculate the Total row**.
    - If it does not exist yet (new endeavour), write the full block:

    ```markdown
    ## Sessions

    | Date | Command | AI Model | Input Tokens | Output Tokens | Cache Read Tokens | Cache Write Tokens | Estimated Cost |
    |------|---------|----------|-------------|--------------|------------------|--------------------|---------------|
    | YYYY-MM-DD | looper-plan | Claude Code — Sonnet 4.6 | ~X,XXX | ~X,XXX | ~X,XXX | ~X,XXX | ~$X.XX |
    | | | | | | | **Total** | **~$X.XX** |

    > Pricing basis varies by model — see [Anthropic pricing](https://www.anthropic.com/pricing).
    > Sonnet: Input $3/1M · Output $15/1M · Cache write $3.75/1M · Cache read $0.30/1M
    > Opus:   Input $15/1M · Output $75/1M · Cache write $18.75/1M · Cache read $1.50/1M
    > Haiku:  Input $0.80/1M · Output $4/1M · Cache write $1/1M · Cache read $0.08/1M
    ```

    Use today's date for the Date column. The **Total** row sums the Estimated Cost column across all session rows.

    Then ask the user:

    ```
    The RePIT is ready. Would you like me to post it to Jira ticket <JIRA-KEY>?

    This will:
    1. Comment "📋 RePIT plan — Endeavour {N}" — append to existing comment for this endeavour if one exists, otherwise create new
    2. Attach the RePIT file — replace the existing Endeavour {N} attachment if one exists, otherwise upload new

    Reply "yes" to post, or "skip" to continue without posting.
    ```

    If the user replies **"yes"** (or equivalent), invoke the `jira-repit-updater` agent using the prompt template below.

    > ⛔ **NEVER specify MCP, REST, or any transport method** in the prompt to `jira-repit-updater` — it selects transport internally based on credential availability. Caller overrides break the routing table and produce incorrect behaviour.
    > ⛔ **NEVER post the full file content as a comment.** The comment is a short summary only; the file is delivered as an attachment.

    **Prompt template — fill in the `< >` placeholders before sending:**

    ```
    Action: both
    Ticket: <JIRA-KEY>
    File path: <absolute path to RePIT .md file>

    Comment:
    - Search this ticket for an existing comment whose heading starts with "📋 RePIT plan — Endeavour <N>"
    - If found: append below all existing content — rule node first, then one paragraph node per line below
    - If not found: create a new comment — H3 heading "📋 RePIT plan — Endeavour <N>", then one paragraph node per line below
    - Comment body lines:
        "Document: <repit-filename>.md"
        "Summary: <one-line overview copied from the RePIT Overview section>"
        "Full plan attached — see Attachments panel."

    Attachment:
    - Search this ticket's attachments for a filename matching "RePIT-<JIRA-KEY>-*-E<N>.md"
    - If found: delete the old attachment, then upload the new file
    - If not found: upload the file as a new attachment
    ```

    Resolve placeholders from the RePIT file before invoking:
    - `<JIRA-KEY>` — from `**Jira Ticket:**` frontmatter
    - `<N>` — leading digit of `**RePIT Version:**`
    - `<repit-filename>.md` — the `.md` filename (not the full path)
    - `<one-line overview>` — first sentence of `## Overview`
    - `<absolute path>` — the full absolute path to the saved RePIT `.md` file (with cost summary already appended)

    If the user replies **"skip"** or does not respond, proceed without posting.

## Clarifying Questions (Guidelines)

Ask only the most critical questions needed to write a clear RePIT. Focus on areas where the initial prompt is ambiguous or missing essential context. Common areas that may need clarification:

*   **Problem/Goal:** If unclear - "What problem does this feature solve for the user?"
*   **Core Functionality:** If vague - "What are the key actions a user should be able to perform?"
*   **Scope/Boundaries:** If broad - "Are there any specific things this feature *should not* do?"
*   **Success Criteria:** If unstated - "How will we know when this feature is successfully implemented?"

**Important:** Only ask questions when the answer isn't reasonably inferable from the initial prompt. Prioritize questions that would significantly impact the RePIT's clarity.

### Formatting Requirements

- **Number all questions** (1, 2, 3, etc.)
- **List options for each question as A, B, C, D, etc.** for easy reference
- Make it simple for the user to respond with selections like "1A, 2C, 3B"

### Example Format

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Generate additional revenue

2. Who is the target user for this feature?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the expected timeline for this feature?
   A. Urgent (1-2 weeks)
   B. High priority (3-4 weeks)
   C. Standard (1-2 months)
   D. Future consideration (3+ months)
```

## RePIT Structure

The generated RePIT **must follow the structure defined in [`RePIT-TEMPLATE.md`](../artifacts/RePIT-TEMPLATE.md)** exactly — do not invent or omit sections.

Key sections from the template:
- **Overview** — brief feature description
- **Problem Statement** — what problem this solves
- **Goals** / **Non-Goals**
- **Functional Requirements** / **Non-Functional Requirements**
- **Design Considerations**
- **Dependencies**
- **`## Implementation`** — contains all phases as `### Phase N` subsections.

- **`### Phase 1: [Phase Name]`** — always include all three sections with all subsections listed:
  - **`#### Backend Changes`** — with `##### Database Changes`, `##### API Changes for PosApi Project`, `##### API Changes for GolferApi Project` subsections; include `- [ ] 0.0 Create feature branch` at the `####` level only if any subsection has changes (all three subsections share the `golfler_asp_2` repo) *(remind: update OpenAPI/Swagger spec files after API changes)*
  - **`#### Changes for POSAPI Consumers`** — with `##### WPF PosApp`, `##### Angular CConline App`, `##### FnB React Native App`, `##### Mobile POS App (React Native)` subsections. Do **not** place `0.0 Create feature branch` at the `####` level — each `#####` subsection is a different repo. Instead, place `- [ ] 0.0 Create feature branch` as the **first task inside each `#####` subsection** that has changes.
  - **`#### Changes for GolferApi Consumers`** — with `##### API Manager (PHP CodeIgniter)`, `##### Member Portal (PHP CodeIgniter)`, `##### Android Mobile App (Kotlin)`, `##### iOS App (Swift)` subsections. Do **not** place `0.0 Create feature branch` at the `####` level — each `#####` subsection is a different repo. Instead, place `- [ ] 0.0 Create feature branch` as the **first task inside each `#####` subsection** that has changes.
  - Write `N/A` under any subsection that has no changes in Phase 1 — do not remove the heading.
  - Each `#####` project/consumer subsection ends with a **Relevant Files** list scoped to that project only.

- **`### Phase 2+: [Phase Name]`** — only include sections and subsections that have actual changes. Omit empty sections and subsections entirely — do not list them with N/A. Each included project/consumer subsection ends with its own **Relevant Files** list.

- **Open Questions**

Add or remove phases as needed.

## Target Audience

Assume the primary reader of the RePIT is a **junior developer**. Therefore, requirements should be explicit, unambiguous, and avoid jargon where possible. Provide enough detail for them to understand the feature's purpose and core logic.

## Output

*   **Format:** Markdown (`.md`)
*   **Location:** `<workspace_root>/<repit-name>/` (the task folder created in step 0)
*   **Filename:** Follow the naming convention from `looper-code/README.md`:
    - With Jira ticket: `RePIT-[JIRA-KEY]-[short-description].md` (e.g., `RePIT-CCD-676-anonymous-voucher-online-booking.md`)
    - Without Jira ticket: `RePIT-NOJIRA-[short-description].md` (e.g., `RePIT-NOJIRA-tee-time-booking-redesign.md`)
    - Append `-VXXX` (e.g., `-V1`, `-V2`) only when multiple RePITs share the same key and description
*   **Jira link:** If the input was a Jira issue, include the issue key and URL in the RePIT header.

## Task Generation Process

After the RePIT is approved by the user, immediately generate the complete implementation task list — parent tasks **and** sub-tasks together in one step — and embed it directly into the RePIT document. Do **not** present parent tasks first and wait for a "Go" prompt before adding sub-tasks.

### Generate the Complete Task List
1. Analyze the RePIT's functional requirements and scope.
2. **Include task `0.0 Create feature branch` as the first task inside each `#####` repo subsection that has actual changes.** For `#### Backend Changes` (single repo `golfler_asp_2`), place it at the `####` level instead. For `#### Changes for POSAPI Consumers` and `#### Changes for GolferApi Consumers`, each `#####` subsection is a different repo — place the branch task inside each `#####` that has changes; do NOT place it at the `####` level. Omit it from any subsection with no changes (write `N/A` there). One branch per phase per repo, named `feature/<repit-name>/phase-1`, `feature/<repit-name>/phase-2`, etc. Branches chain sequentially:
   - **Phase 1** `0.1`: checkout the repo's stable branch from `looper-code/artifacts/project-structure.md` (e.g. `git checkout release_5_4_41`), then create `feature/<repit-name>/phase-1` from it.
   - **Phase 2+** `0.1`: checkout the previous phase's branch (e.g. `git checkout feature/<repit-name>/phase-1`), then create the next phase's branch from it (e.g. `git checkout -b feature/<repit-name>/phase-2`).
   This way each phase builds on the previous phase's committed changes.
3. **Include a commit-and-push task as the last task inside each `#####` repo subsection that has changes** (and at the `#### Backend Changes` level for `golfler_asp_2`). Number it after all implementation tasks (e.g. if the last implementation task is `3.0`, this becomes `4.0`). Sub-tasks are always `[Agent]`:
   - `N.1` Stage all modified files: `git add <file1> <file2> ...` (list files explicitly — never `git add .`)
   - `N.2` Commit: `git commit -m "fix(JIRA-KEY): <concise description of what changed in this repo for this phase>"`
   - `N.3` Push: `git push -u origin <branch-name>`
   - `N.4` Report the commit hash and pushed branch URL to the user.
4. Break every parent task into sub-tasks immediately — do not present parent tasks alone and wait for confirmation.
5. Sub-tasks must follow the numbered hierarchy: `1.0 / 1.1 / 1.2`, `2.0 / 2.1`, etc.
6. **Label every sub-task** with who should perform it:
   - `[Human]` — requires a human (manual testing, approval, deployment, QA, config changes in environments)
   - `[Agent]` — can be performed by an AI coding agent (code changes, file edits, searches)
7. As tasks are completed, check them off: `- [ ]` → `- [x]`. Update after each sub-task, not just the parent.

### Task Format
```markdown
##### <Repo/App Name>    ← each ##### subsection follows this pattern

# Phase 1
- [ ] 0.0 Create feature branch
  - [ ] 0.1 [Agent] In `<repo>`: `git checkout <stable-branch>` (see `project-structure.md`), then `git checkout -b feature/<repit-name>/phase-1`
- [ ] 1.0 Parent Task Title
  - [ ] 1.1 [Agent] [Sub-task description]
  - [ ] 1.2 [Human] [Sub-task description]
- [ ] 2.0 Parent Task Title
  - [ ] 2.1 [Agent] [Sub-task description]
- [ ] 3.0 Commit and push
  - [ ] 3.1 [Agent] Stage all modified files: `git add <file1> <file2> ...`
  - [ ] 3.2 [Agent] Commit: `git commit -m "fix(JIRA-KEY): <description>"`
  - [ ] 3.3 [Agent] Push: `git push -u origin feature/<repit-name>/phase-1`
  - [ ] 3.4 [Agent] Report commit hash and pushed branch URL

# Phase 2+
- [ ] 0.0 Create feature branch
  - [ ] 0.1 [Agent] In `<repo>`: `git checkout feature/<repit-name>/phase-1`, then `git checkout -b feature/<repit-name>/phase-2`
- [ ] 1.0 Parent Task Title
  - [ ] 1.1 [Agent] [Sub-task description]
  - [ ] 1.2 [Human] [Sub-task description]
- [ ] 2.0 Commit and push
  - [ ] 2.1 [Agent] Stage all modified files: `git add <file1> <file2> ...`
  - [ ] 2.2 [Agent] Commit: `git commit -m "fix(JIRA-KEY): <description>"`
  - [ ] 2.3 [Agent] Push: `git push -u origin feature/<repit-name>/phase-2`
  - [ ] 2.4 [Agent] Report commit hash and pushed branch URL
```

**Guidelines for assigning Human vs Agent:**
- `[Agent]` — writing/editing code, reading files, searching codebase, creating branches, generating SQL migrations
- `[Human]` — running the app and manually testing, deploying to staging/production, approving changes, updating environment configs, verifying on physical devices

### Relevant Files
After generating sub-tasks, populate the **Relevant Files** list inside each project/consumer subsection (`####`) with the specific files that will be created or modified for that project in that phase. Each subsection has its own scoped list — do not aggregate into a single global list.

## Final instructions

1. Do NOT start implementing the RePIT
2. Make sure to ask the user clarifying questions
3. Take the user's answers to the clarifying questions and improve the RePIT
4. Only generate tasks after the user has approved the RePIT content
5. When generating tasks, generate parent tasks **and** sub-tasks together in one step — do not present parents first and wait for a "Go" prompt
6. **At the very end of every looper-plan run**, append this session's row to the `## Sessions` table in the RePIT `.md` file using the format defined in step 6 above — and recalculate the Total row. Do this regardless of whether a Jira ticket was involved. After saving, also echo the updated Sessions table to the user in chat so they can see it without opening the file.

   Use your best estimate of tokens consumed during this session. If exact counts are unavailable, provide a reasonable approximation based on context size and response length. Always show the calculation basis so the user can verify.
7. After tasks are generated, if a Jira ticket was involved, always offer to post the RePIT to Jira (step 6 above) — do not skip this prompt. Use the `jira-repit-updater` agent for all Jira operations; **never** call `mcp__claude_ai_Atlassian__*` tools or Jira REST endpoints directly from looper-plan.
