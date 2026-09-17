# Rule: Implementing a Research Plan Implement Test document (RePIT)

## Banner

Before doing anything else, read and output the banner from [artifacts/looper-code-banner.md](../artifacts/looper-code-banner.md).

## Goal

To guide an AI agent in implementing a previously approved RePIT by working through its tasks systematically — executing `[Agent]` tasks autonomously and pausing for `[Human]` tasks.

## Input Sources

The RePIT to implement can be specified as:

### Option A: Filename
The user provides a RePIT filename or path (e.g., `RePIT-001-CCD-676-anonymous-gift-card-online-booking.md`). Derive the task workspace from the repit name: `<workspace_root>/<repit-name>/`. Read the RePIT file from inside that task workspace folder.

### Option B: Jira Issue Key
The user provides a Jira issue key (e.g., `CCD-931`). Search the workspace root for a folder whose name matches the repit naming format for that key (e.g., `RePIT-CCD-931-*/`). The task workspace is that folder; read the RePIT file from inside it.

### Option C: Handover from looper-plan
looper-plan passes a pre-resolved context block when the user selects "A. Continue implementation from the next pending task". This context includes:
- Task workspace path (absolute)
- RePIT filename
- Active phase N and next pending task identifier
- Repo → current branch map (which repos are already cloned, which branch each is on)
- Per-repo classification (✏️ Change = per-task clone in the workspace · 🔍 Reference = resolved read-only from the stable mirror, not cloned) — so implement does not re-clone reference repos

When this context is present, **skip the workspace derivation steps** — use the provided paths directly. Still read the full RePIT file before starting any work.

## Workspace Convention

**Workspace root** = the parent directory of the `looper-code` repo the agent is currently running in.

**Task workspace** = `<workspace_root>/<repit-name>/` — the isolated folder created by `looper-plan` for this task. The RePIT file and all repo clones live here.

For example, if the workspace root is `e:/development/r1/tasks/workspace2/release_5_4_41/` and the RePIT name is `RePIT-CCD-123-some-feature`, then the task workspace is `e:/development/r1/tasks/workspace2/release_5_4_41/RePIT-CCD-123-some-feature/`.

All repos (`golfler_asp_2` and any sibling repos: `golfler_pos_2`, `sgs-cts-angular`, `cc_mobile_pos`, `cc_api_manager`, `cc_membership_portal`, `cc_ios`, `cc_android`) live as siblings of each other under the task workspace or the stable mirror. Never assume a repo is missing without first checking the task workspace.

**Changeable repos live in the workspace.** Every repo the RePIT modifies — i.e. any repo with a task in the `## Implementation` section (**✏️ Change**) — **must** be a per-task clone under `<workspace_root>/<repit-name>/<repo>/` (writable, isolated). If a Change repo is missing, **clone it** — never satisfy a changeable repo from the mirror.

**Reference repos are read-only from the mirror.** Repos consulted only for context — those in `## Repos & Projects Affected` with a Change Summary of `N/A` / `out of scope` / empty, or with no `## Implementation` tasks (**🔍 Reference**) — are **read** from the shared **stable-codebase mirror** `<workspace_root>/looper-code-artifacts/stable-codebase/<repo>/`. Do not clone them per-task. If the mirror is absent, fall back to a per-task clone (still treated as read-only) and surface:
```
⚠️  <repo> classified as reference, but stable codebase missing — cloning into task workspace instead.
   Run /looper-setup (Step 6 = y) to provision stable for future tasks.
```

⛔ **The stable mirror is read-only — never edit, branch, or commit in it** (see **Reference Repos & the Stable Mirror** under Execution Rules). If scope grows and a task begins targeting a repo that only exists as a mirror, promotion-clone it into the workspace first.

### ⛔ GUARDRAIL: Derive Workspace from Environment — Never Guess

**Before loading the RePIT**, determine the correct workspace root from the actual runtime environment. Do NOT rely on memory, examples, or patterns from previous sessions.

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
- Proceed until the workspace root is confirmed from actual disk state

### ⛔ GUARDRAIL: Stop If Task Workspace Cannot Be Determined

If at any point the task workspace cannot be confirmed — **stop immediately and ask the user**. Do not proceed, guess, or search outside the primary working directory tree.

**Stop conditions**:
- `looper-code` is not found inside the primary working directory (workspace root cannot be derived)
- No folder matching the issue key (e.g., `RePIT-CMP-100-*/`) exists inside the confirmed workspace root
- The RePIT file is not found inside the expected task workspace folder

**Required response when stopped**:
```
⛔ STOPPED — Task workspace could not be determined for <ISSUE-KEY>.

Workspace root checked: <path>
Issue: <what was missing or ambiguous>

Please confirm:
1. The correct workspace root path, OR
2. Whether the RePIT for <ISSUE-KEY> needs to be created first (via /looper-plan)
```

Do NOT search parent directories, sibling directories, or any path outside the primary working directory tree.

## Process

1. **Read the RePIT** — Determine the task workspace (see Workspace Convention above), then load the RePIT file from inside it (`<workspace_root>/<repit-name>/<repit-filename>.md`). Understand the full scope before starting any work.
2. **Read CLAUDE.md** — Always read `CLAUDE.md` first to understand system constraints, forbidden actions, and required patterns.
2a. **Update Contributors section** — Resolve the current user's name via `git config user.name` and read `looper-code/VERSION`. If a row with the same **Author + Agent + AI Model + Date** combination does not already exist in the `## Contributors` table of the RePIT file, append a new row (`| Name | looper-code vX.Y.Z | Claude Code — {model} | YYYY-MM-DD |`). Derive the model short name from the active model ID: `claude-sonnet-4-6` → `Sonnet 4.6`, `claude-opus-4-7` → `Opus 4.7`, `claude-haiku-4-5` → `Haiku 4.5`. Never duplicate an identical row. A returning author on a different date, agent version, or model gets a new row.
3. **Identify pending tasks** — Scan the RePIT's task sections for unchecked items (`- [ ]`). Skip already-completed tasks (`- [x]`).

3a. **Show resumption summary** — Before executing any task, output the current state and wait for user confirmation:
    ```
    ▶ Resuming <repit-filename>
      Endeavour   : {N}
      Active phase: Phase {N}
      Next pending: {task-number} — {task-title}

      Repo state:
        <repo>  : <branch> ✅ cloned          (✏️ Change)
        <repo>  : ❌ missing — will clone before starting   (✏️ Change)
        <repo>  : 🔍 reference (stable mirror) — not cloned
        ...

    Reply "go" to start, or describe any corrections first.
    ```

3b. **Ensure repos are provisioned per classification** — After the user confirms, apply the per-repo rule below. Use `looper-code/artifacts/project-structure.md` for clone URLs and stable branch names.

    - **For each ✏️ Change repo** (has any task — pending or completed — in the RePIT's `## Implementation` section; it will be modified):
      - If already cloned in the task workspace → verify it is on the correct feature branch:
        `git -C "<task_workspace>/<repo>" branch --show-current`
        If not on the expected branch → `git checkout <expected-branch>` before starting work.
      - If missing → clone it per-task now using the clone URL from `project-structure.md`, then check out the active phase branch (or stable branch with a warning if the feature branch is not found).
      - ⛔ A Change repo must **never** be left resolving to the stable mirror — it will be written to.
    - **For each 🔍 Reference repo** (in `## Repos & Projects Affected` with a Change Summary of `N/A` / `out of scope` / empty, or with no `## Implementation` tasks; read-only context only): do **not** clone. It resolves read-only from `<workspace_root>/looper-code-artifacts/stable-codebase/<repo>/`. If the stable mirror is absent → fall back to a per-task clone and surface the ⚠️ "stable codebase missing" banner (see Workspace Convention).
    - **❌ Out-of-scope** repos → ignore; do not access them.

4. **Execute Agent tasks** — For each `[Agent]` sub-task, implement it following the rules below. Check it off (`- [x]`) in the RePIT file immediately after completion.
5. **Pause for Human tasks** — When a `[Human]` sub-task is reached, stop and notify the user. Do not proceed until the user confirms the human task is done.
6. **Update task status** — After each sub-task (Agent or Human), update the RePIT file: `- [ ]` → `- [x]`. Update the parent task checkbox only after all its sub-tasks are complete.
7. **Report progress** — After completing each parent task, briefly summarise what was done before moving to the next.
8. **Increment I, update Sessions, and offer Jira update** — After each phase completes (all tasks for that phase checked off):
   1. Increment `I` in `**RePIT Version:**` (e.g. `3.0.0` → `3.0.1` after Phase 1, `3.0.1` → `3.0.2` after Phase 2).
   2. Append a row to `## Changelog`: `| <new version> | {name} | Phase N complete |` — where `{name}` is resolved via `git config user.name`.
   3. Append this session's row to the `## Sessions` table and recalculate the Total row:
      `| YYYY-MM-DD | looper-implement | Claude Code — {model} | ~X,XXX | ~X,XXX | ~X,XXX | ~X,XXX | ~$X.XX |`
      Derive `{model}` from the active model ID: `claude-sonnet-4-6` → `Sonnet 4.6`, `claude-opus-4-7` → `Opus 4.7`, `claude-haiku-4-5` → `Haiku 4.5`. Use today's date. Use your best estimate of tokens consumed during this session.
   4. Offer to post the updated RePIT to Jira — see **Jira Update Offer** section below. Do NOT auto-post.

## Execution Rules

### Before Making Any Change
- [ ] Re-read the relevant section of `CLAUDE.md` for the type of change being made
- [ ] Search for existing similar code patterns to follow
- [ ] Identify all files that will be touched
- [ ] Check if the change affects mobile apps, payments, or multi-tenant isolation

### Phase Execution
- **At the start of working on each repo within a phase**, execute the `0.0 Create feature branch` task defined in that repo's `#####` subsection (or at the `#### Backend Changes` level for `golfler_asp_2`) — follow the exact branch name written there. Before creating it, check if it already exists:
  ```bash
  git -C "<task_workspace>/<repo>" branch -a | grep "<branch-name>"
  ```
  - If it **exists** → `git checkout <branch-name>` (do not re-create it)
  - If it **does not exist** → follow the branch creation steps in the RePIT task exactly (checkout base branch, then `git checkout -b <branch-name>`)
  Do not invent a branch name or reuse the branch from a previous phase.
- **At the end of working on each repo within a phase**, after all Agent tasks for that repo are complete and all Human tasks for that repo are confirmed, commit and push that repo's branch:
  1. Stage all modified files: `git add <file1> <file2> ...` (list files explicitly — never `git add .`)
  2. Commit with a message following the format: `fix(JIRA-KEY): <concise description of what changed in this repo for this phase>`
  3. Push the branch: `git push -u origin <branch-name>`
  4. Report the commit hash and pushed branch URL to the user.
- Work through repos sequentially within a phase — complete all tasks for one repo (branch → implement → commit → push) before moving to the next repo.

### Reference Repos & the Stable Mirror

- **Where each repo resolves (no fallback for Change repos):**
  - A **✏️ Change** repo (has `## Implementation` tasks) resolves **only** from its per-task clone in the task workspace. If it isn't there, clone it — do **not** read or edit it from the mirror.
  - A **🔍 Reference** repo (read-only context) resolves from the stable mirror `<workspace_root>/looper-code-artifacts/stable-codebase/<repo>/` (or a per-task clone fallback only if the mirror is absent).
- **Dual-root read guardrail** — for any read, in the main context or by a spawned sub-agent: reads are allowed from (a) the task workspace and (b) the read-only stable mirror only; **writes are only permitted under the task workspace.** Any sub-agent prompt (e.g. `jira-repit-updater`, or a build/test helper) and any reference read must obey these two roots.
- ⛔ **Read-only safety rule (most important):** never write to, create branches in, or commit from the stable mirror (`<workspace_root>/looper-code-artifacts/stable-codebase/`). **Promotion clone:** if a task targets a repo that currently only exists as a mirror (scope grew beyond the original Change set), clone it per-task into the task workspace *before* making any edit, then proceed. This mirrors looper-plan's post-finalization promotion clone.

### Agent Task Execution
- Before editing any file, confirm its repo has a per-task clone in the task workspace — never edit a path under `<workspace_root>/looper-code-artifacts/stable-codebase/`. If the target repo isn't cloned per-task, promotion-clone it first (see **Reference Repos & the Stable Mirror**).
- Make surgical, targeted changes only — do not refactor surrounding code
- Follow existing code patterns exactly (copy, don't invent)
- Every database query must include `WHERE CourseId = @CourseId`
- Never break mobile API contracts (no removed/renamed fields)
- Never touch payment code without stopping to ask
- If a change exceeds 300 lines or 5 files, **stop and ask**

### Human Task Handling
When a `[Human]` task is reached:
1. Clearly state which task requires human action
2. Describe exactly what the human needs to do
3. Wait for the user to confirm completion before continuing

Example:
```
⏸ HUMAN TASK REQUIRED — 1.5
Please manually test: void a transaction that had service charge → clone it
→ confirm service charge auto-applies with the same amount as the original.

Reply "done" when complete, or describe what you observed.
```

### Plan Change Protocol

If the user provides feedback or instruction during implementation that results in a change to plan content in the RePIT (adding, removing, or modifying tasks, sub-tasks, phases, or their descriptions), apply the change and then:

1. Increment P in `**RePIT Version:**`
2. Append a row to `## Changelog`:
   `| <new version> | {name} | <one-line summary of what changed in the plan> |` — where `{name}` is resolved via `git config user.name`
3. Offer to post the updated RePIT to Jira — see **Jira Update Offer** section below.

This applies to: adding new tasks/phases, removing tasks, changing task descriptions or scope.
It does NOT apply to: checking off completed tasks (`- [ ]` → `- [x]`) or updating task status.

### Stopping Conditions
Stop immediately and ask the user if:
- A task is ambiguous or contradicts the codebase
- A change would affect more files than expected
- A `[Human]` task reveals unexpected behaviour
- Any high-risk area is encountered (payments, GolflerShared, DB schema, mobile API)
- A pending task targets a repo that exists only as a read-only stable mirror and cannot be promotion-cloned into the task workspace

## Task Completion Format

After completing each sub-task, update the RePIT:
```markdown
- [x] 1.1 [Agent] Description of completed task
- [ ] 1.2 [Human] Description of pending human task
```

After ALL sub-tasks of a parent task are done:
```markdown
- [x] 1.0 Parent Task Title  ← mark parent complete
  - [x] 1.1 [Agent] ...
  - [x] 1.2 [Human] ...
```

## Output

- All changes are made directly to the codebase files listed in the RePIT's `## Relevant Files` section
- The RePIT file itself is updated as tasks are checked off
- Do not create new files unless the RePIT explicitly requires it

## Jira Update Offer

After any version change (I increment after phase completion, or P increment after a plan content change), ask the user:

```
Version bumped to {new-version} ({reason: e.g. "Phase N complete" or "plan updated"}).
Would you like me to post the updated RePIT to Jira ticket <JIRA-KEY>?
This will:
  1. Replace the E{N} attachment with the current RePIT file
  2. Append a phase/plan-change entry to the "Implementation of RePIT — Endeavour {N}" comment

Reply "yes" to post, or "skip" to continue.
```

⛔ **NEVER interact with Jira directly** — no `mcp__claude_ai_Atlassian__*` tool calls, no REST/curl commands. Always delegate every Jira operation (fetch, search, comment, attach) to the `jira-repit-updater` agent. It selects MCP or REST internally and handles auth, encoding, and retry logic.

If the user replies **"yes"**, invoke `jira-repit-updater` using the prompt template below. If **"skip"** or no response, continue without posting.

> ⛔ **NEVER specify MCP, REST, or any transport method** in the prompt to `jira-repit-updater` — it selects transport internally based on credential availability. Caller overrides break the routing table and produce incorrect behaviour.
> ⛔ **NEVER post the full file content as a comment.** The comment is a short phase-entry only; the file is delivered as an attachment.

**Prompt template — fill in the `< >` placeholders before sending:**

```
Action: both
Ticket: <JIRA-KEY>
File path: <absolute path to updated RePIT .md file>

Comment:
- Search this ticket for an existing comment whose heading starts with "Implementation of RePIT — Endeavour <N>"
- If found: append below all existing content — rule node, then the phase entry nodes below
- If not found: create a new comment — H3 heading "Implementation of RePIT — Endeavour <N>", rule node, then the phase entry nodes below
- Phase entry nodes (one paragraph per line):
    H4 heading: "🔄 Phase <X> — <Phase name> — Complete"
    "Repos changed: <comma-separated list of repos touched in this phase>"
    "Branch(es): <branch name(s) pushed>"
    "Base branch: <repo>: <base branch> (one line per repo touched in this phase)"
    "📎 Updated RePIT attached: <repit-filename>.md"

Attachment:
- Search this ticket's attachments for a filename matching "RePIT-<JIRA-KEY>-*-E<N>.md"
- If found: delete the old attachment, then upload the new file
- If not found: upload the file as a new attachment
```

Resolve placeholders from the RePIT file before invoking:
- `<JIRA-KEY>` — from `**Jira Ticket:**` frontmatter
- `<N>` — leading digit of `**RePIT Version:**`
- `<X>` — the phase number just completed
- `<Phase name>` — the phase title from the RePIT
- `<repit-filename>.md` — the `.md` filename (not the full path)
- `<absolute path>` — full absolute path to the updated RePIT `.md` file
- `<base branch>` — per repo: the branch checked out before `git checkout -b` in that repo's `0.0 Create feature branch` task (e.g. `release_5_4_41`)

### Jira ticket key resolution
- Read the Jira ticket key from the RePIT's `**Jira Ticket:**` frontmatter field (e.g. `CCD-566`).
- If the key is missing or TBD, skip the Jira update and warn the user.

### What jira-repit-updater must do (reference — the prompt template above is authoritative)

1. **Find or create the endeavour-scoped "Implementation of RePIT" comment** — there is one comment per endeavour per ticket:
   - Read the endeavour number N from the `**RePIT Version:**` field in the RePIT file (the leading digit — e.g. version `2.1.3` → N = 2).
   - Search the ticket's existing comments for one that starts with `Implementation of RePIT — Endeavour {N}`.
   - If found → **append** the phase entry ADF nodes below all existing content (preserve everything above).
   - If not found → **create** a new comment in ADF format with the title as an H3 heading followed by the first phase entry.

   **New comment ADF structure** (title + first phase entry):
   ```
   • Heading (level 3): "Implementation of RePIT — Endeavour {N}"
   • Rule node (horizontal divider)
   • Heading (level 4): "🔄 Phase X — <Phase name> — Complete"
   • Paragraph: "Repos changed: <comma-separated list of repos touched in this phase>"
   • Paragraph: "Branch(es): <branch name(s) pushed>"
   • Paragraph: "Base branch: <repo>: <base-branch>" (one paragraph per repo touched in this phase)
   ```

   **Appending a phase entry** to an existing comment (ADF nodes to add at the end):
   ```
   • Rule node (horizontal divider)
   • Heading (level 4): "🔄 Phase X — <Phase name> — Complete"
   • Paragraph: "Repos changed: <comma-separated list of repos touched in this phase>"
   • Paragraph: "Branch(es): <branch name(s) pushed>"
   • Paragraph: "Base branch: <repo>: <base-branch>" (one paragraph per repo touched in this phase)
   ```

2. **Replace the RePIT attachment** — the RePIT file has been updated (tasks checked off). There is one attachment per endeavour:
   - Search the ticket's attachments for a filename matching `RePIT-<JIRA-KEY>-*-E{N}.md` (same endeavour suffix as the current file).
   - If found → **delete** the old attachment, then **upload** the updated file.
   - If not found → **upload** the file as a new attachment.
   - Never delete or replace attachments from other endeavours (different `-E{N}` suffix).

3. After the attachment is replaced, append one more ADF paragraph node to the comment:
   ```
   • Paragraph: "📎 Updated RePIT attached: <repit-filename>.md"
   ```

4. **After all phases are complete** — append a final summary block to the `Implementation of RePIT — Endeavour {N}` comment. ADF nodes to append:
   ```
   • Rule node (horizontal divider)
   • Heading (level 4): "✅ Implementation Complete"
   • Paragraph: "Final branches:"
   • Paragraph: "- golfler_asp_2: feature/<repit-name>/phase-X (base: <base branch>)"
   • Paragraph: "- <repo>: <branch> (base: <base branch>)"
   ... (one paragraph per repo that had changes)
   ```
   Only include repos that had at least one change across all phases. Use the last phase branch pushed for each repo. The base branch for each repo is the branch that was checked out when Phase 1 execution began for that repo.

## Final Instructions

1. Do NOT skip `[Human]` tasks — pause and wait for confirmation
2. Do NOT implement anything not in the RePIT
3. Do NOT refactor code beyond what is required by the task
4. Always check off tasks in the RePIT file as you go
5. If uncertain, stop and ask — never guess in a legacy production system
