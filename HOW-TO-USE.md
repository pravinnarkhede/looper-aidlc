# How to Use This Workspace — Beginner's Guide

This workspace has two tools that help you build software with AI:

- **AIDLC** = the **planner**. It asks you questions and writes down WHAT needs to be built, in detail, before any code is touched.
- **Looper** = the **builder**. It writes the actual code, creates git branches, commits, and pushes — one step at a time, checking in with you along the way.

You can use either one by itself, or combine them (AIDLC plans → Looper builds). Below are three complete, beginner-friendly walkthroughs. Pick the one that matches what you're doing.

---

# 1. USING LOOPER ONLY

**Use this when:** you already know what needs to change — you have a Jira ticket, or a clear task description — and you just want it researched, planned, and built.

## What Looper actually is

Looper is like a careful junior developer who:
1. Reads the ticket (or your description)
2. Goes and studies the relevant code
3. Writes a plan and shows it to you before touching anything
4. Builds it step by step, pausing whenever it needs you to check something
5. Commits and pushes the code when done

Every task gets its own folder and its own plan document (called a **RePIT** — short for Research → Plan → Implement → Test). Think of the RePIT file as the task's diary: what it's supposed to do, what's been done, what's left, and every decision made along the way.

## Step-by-step walkthrough

### Step 1 — Start planning

If you have a Jira ticket:
```
/looper-plan CCD-1234
```
If you don't have a ticket, just a task in mind:
```
/looper-plan
```
(Looper will then ask you to describe the task in your own words.)

### Step 2 — Looper researches automatically

You don't need to do anything here — Looper:
- Fetches the ticket details (if you gave one)
- Searches the codebase for related files
- Studies how similar things were built before
- Figures out which repositories (code projects) are affected

### Step 3 — Looper asks you questions (if needed)

If something is unclear, Looper asks in multiple-choice format, e.g.:
```
1. Which payment methods should this support?
   A) Card only
   B) Card and cash
   C) Same as existing checkout flow
```
You just reply with the letter: `1B`

### Step 4 — Looper shows you the plan

It creates a task folder, e.g.:
```
RePIT-CCD-1234-some-feature-E1\
```
Inside is one file — the plan. It lists:
- What's being built and why
- Which repos/files are affected
- The exact steps, grouped into phases

**Read it.** If something's wrong, just say so in plain English:
```
Move the database change to phase 1 instead of phase 2.
```
Looper updates the plan and shows you the new version.

### Step 5 — Approve and build

Once the plan looks right, say:
```
/looper-implement
```
Looper shows you a quick summary of what's about to happen, then asks you to reply **"go"**.

From there, two kinds of steps happen:
- **`[Agent]` steps** — Looper does these itself automatically (writing code, creating a git branch, committing). You don't need to do anything.
- **`[Human]` steps** — Looper stops and tells you exactly what to check, e.g. "run the app and confirm the button appears." You test it, then reply **"done"**.

### Step 6 — Commit, push, and (optionally) Jira sync

After each phase, Looper:
- Commits the code with a clear message
- Pushes it to a new branch
- Asks if you want the Jira ticket updated with the progress — reply "yes" or "skip"

That's it — repeat Steps 5-6 until all phases are done.

## Quick summary (Looper only)

```
/looper-plan CCD-1234   →  research + plan
   (review, request changes if needed)
/looper-implement        →  build it, phase by phase
   (reply "go", then "done" for any manual checks)
```

---

# 2. USING AIDLC ONLY

**Use this when:** you have a rough idea for a feature (or even a whole new project) and want it properly thought through and *also built* — without bringing in Looper's extra process. Good for smaller or simpler features.

## What AIDLC actually is

AIDLC is like a business analyst + architect combined. Before any code is written, it:
1. Figures out if you're working on something brand new or an existing system
2. (For existing systems, first time only) reads and documents how the current system works
3. Asks you questions to nail down exactly what's needed
4. Writes user stories, if it's a user-facing feature
5. Designs the technical pieces needed
6. Breaks the feature into smaller chunks if it's big
7. Then builds each chunk, and finally tests everything together

Every single step produces a document, and AIDLC **always stops and waits for your approval** before moving to the next step. Nothing happens without your sign-off.

## Step-by-step walkthrough

### Step 1 — Describe what you want

Just type it in chat, in plain English:
```
I need to add a "forgot password" flow to the login screen.
```
Or use the explicit command, same effect: `/aidlc add a "forgot password" flow to the login screen`. If you have several features going and want to pick which one to resume, just type `/aidlc` with nothing after it.

If this is your first feature in this workspace, AIDLC will suggest a short name for it and confirm:
```
Feature name: forgot-password
Docs will be saved to: aidlc-docs\forgot-password\
Confirm? (yes / change to: ...)
```
Reply `yes`.

> **Got a Jira ticket instead?** If you mention the ticket ID (e.g. "CCD-1234: add forgot password flow"), AIDLC uses that ID as the feature name directly — `aidlc-docs\CCD-1234\` — instead of making one up from your description. This way docs are generated **per ticket** when you have one, or per feature description when you don't.

### Step 2 — Workspace detection (automatic)

AIDLC checks: is this a brand new project, or does code already exist? If code exists, it looks for the repos. You don't need to do anything unless it can't find the code — then it'll tell you what to do.

### Step 3 — Reverse engineering (first time only)

If this is an existing codebase and nobody's done this before, AIDLC reads through the code and writes up documents explaining: what the system does, how it's architected, what APIs exist, what technologies are used, etc.

**This only happens once per codebase.** Every feature after the first skips this step and just reuses those documents.

### Step 4 — Requirements Analysis (always happens)

AIDLC asks you clarifying questions, multiple-choice style:
```
1. Should the reset link expire?
   A) Yes, after 1 hour
   B) Yes, after 24 hours
   C) No expiry

2. Should this use Looper to build, or should AIDLC build it directly?
   A) Yes — use Looper
   B) No — AIDLC builds it directly
```
Reply with letters: `1A, 2B` (choosing "AIDLC builds it directly" is what makes this the "AIDLC only" path).

AIDLC then writes up the requirements and shows you a summary. Approve it to continue.

### Step 5 — User Stories (only if it's user-facing)

AIDLC drafts a list of stories like "As a user, I want to reset my password, so that I can regain access to my account," with acceptance criteria. You approve the list before it writes the full versions.

### Step 6 — Workflow Planning (always happens)

AIDLC shows you a short plan of which remaining steps it thinks it needs to run (and why), so you can see the whole roadmap before it continues. You approve it, or ask it to skip/add steps.

### Step 7 — Application Design (only if new components are needed)

AIDLC designs the actual technical pieces — which services, methods, or screens need to be created or changed.

### Step 8 — Units Generation (only if the feature is big enough to split up)

If the feature is large, AIDLC breaks it into smaller, independent chunks ("units"), each with a clear scope. For a small feature like "forgot password," this step might be skipped entirely — it just becomes one unit.

### Step 9 — Construction: AIDLC identifies repos, clones them, then builds

Since you chose "AIDLC builds it directly" back in Step 4, AIDLC now does two things before writing any code:

**9a. Identify and clone the repos**
AIDLC looks at the Application Design / Units Generation docs to see which repos are actually affected, then clones them into one dedicated folder for this feature:
```
Repos needed for forgot-password:
  [1] golfler_asp_2   → AIDLC-forgot-password\golfler_asp_2\ (base: release_5_7)

Confirm? (yes / adjust)
```
The `base:` part is the repo's release branch (from `looper-code\artifacts\project-structure.md`) — after cloning, AIDLC checks out that branch before writing any code, so your work starts from the correct stable base rather than whatever branch the repo happens to default to.

If a repo is already cloned somewhere in the workspace, AIDLC reuses it instead of cloning again. It never touches the read-only stable mirror directly.

**9b. Generate the code**
For each unit:
- Shows you a short implementation plan
- You approve it
- AIDLC writes the code inside `AIDLC-forgot-password\` (the folder from 9a)

There's no git branching ceremony like Looper does (no automatic branch-per-phase, no auto-push) — but the code now lives in its own clean per-feature folder instead of being scattered directly into whatever was at the workspace root.

### Step 10 — Build & Test

Once all units are built, AIDLC writes out instructions for testing everything together (build steps, test steps, and an end-to-end checklist).

It also runs an automatic **build check** across every repo the feature touched. The feature sits at status **"Testing"** until that passes — only then does it flip to **"Complete"**. If a repo fails to compile, you're shown which one and why, and it stays at "Testing" until a re-run passes.

## Quick summary (AIDLC only)

```
Describe the feature
  → AIDLC asks questions, you answer (choose "AIDLC builds it" when asked)
  → Approve requirements
  → Approve user stories (if any)
  → Approve the workflow plan
  → Approve the design (if any)
  → Approve the units (if any)
  → AIDLC identifies the affected repos and clones them into AIDLC-{feature-name}\
  → AIDLC writes the code there, unit by unit — you approve each one
  → AIDLC gives you build & test instructions
```

---

# 3. USING AIDLC + LOOPER TOGETHER

**Use this when:** the feature is big, touches multiple code repositories, or is risky enough that you want the extra discipline of git branches, phase-by-phase commits, and a detailed build log — on top of AIDLC's careful planning.

## What happens, in plain terms

AIDLC still does all the planning (same as "AIDLC only," Steps 1-8 above) — **except** at Step 4 (Requirements Analysis), you answer "Yes, use Looper" instead of "No."

From that point on, instead of AIDLC writing the code itself, it hands the whole plan over to Looper, which builds it using its own careful, step-by-step process — but for the **entire feature in one go**, not ticket by ticket.

Think of it like this: AIDLC draws the blueprint and splits the work into logical chunks (units). Looper then takes that blueprint and treats each chunk as one phase of a single build project — cloning the code, making the changes, testing, committing, and pushing, phase by phase.

> **This scales to any number of units and repos.** A feature might need 1 repo or 10 — the flow doesn't change, only the number of phases and repo clones does. The walkthrough below uses 3 units/repos purely as an example; the same steps apply whether AIDLC decomposes the feature into 2 units or 8, and whether it touches 1 repo or every repo in the workspace.

## Step-by-step walkthrough

### Steps 1-8 — Same as "AIDLC only" above

Describe the feature, answer AIDLC's questions, approve requirements/stories/design/units — **except** at the Looper question, answer:
```
Should this use Looper to build, or should AIDLC build it directly?
A) Yes — use Looper   ← choose this
```

Let's say AIDLC ends up with 3 units (this could just as easily be 2, 5, or more — AIDLC decides based on how big and how spread-out the feature actually is):
```
Unit 1: backend-api          (repo: golfler_asp_2)
Unit 2: pos-app-ui           (repo: golfler_pos_2)
Unit 3: receipt-and-reporting (repos: golfler_asp_2, sgs-cts-angular)
```

### Step 9 — The handoff to Looper

AIDLC shows you exactly what's about to happen. **N** here stands for however many units AIDLC actually created — it always maps one-to-one with the number of phases Looper will run, and covers however many repos are in scope, however many that is:
```
AIDLC Inception complete — membership-class-sale
N unit(s) → N phases in a single Looper plan:

  Phase 1: backend-api           — repo: golfler_asp_2
  Phase 2: pos-app-ui            — repo: golfler_pos_2
  Phase 3: receipt-and-reporting — repos: golfler_asp_2, sgs-cts-angular
  ...                            — (as many phases/repos as the feature actually needs)

Task workspace: RePIT-AIDLC-membership-class-sale-E1\
Ready to start /looper-plan? (yes)
```
Reply `yes`. A single folder is created for the whole feature — **every** repo that needs changing across **every** unit gets cloned inside it, as sibling folders, no matter how many there are.

### Step 10 — Looper plans the whole feature

Looper reads everything AIDLC already wrote (requirements, designs, units) and uses it as a head start — so it barely needs to re-research anything. It then writes one master plan document with **one phase per AIDLC unit** — 3 in this example, but it would be the same with any other number.

It also asks you to confirm which repos it should clone — usually a quick "yes" since AIDLC already scoped this out. If the feature touches many repos, all of them get classified and cloned the same way; there's no limit built into the process.

You review the plan and approve it, same as any Looper plan.

### Step 11 — Looper builds it, phase by phase

```
/looper-implement
```
Reply **"go"**. Looper works through Phase 1 first:
- `[Agent]` steps happen automatically (creates a branch, writes code, commits)
- `[Human]` steps pause and tell you what to manually check — reply **"done"** when you've verified it

When Phase 1 finishes, Looper commits and pushes that phase's branch, then **moves straight on to Phase 2** — same folder, same overall plan, next repo. This repeats until **every** phase is done — whether that's 3 phases or 10.

Example of what you'll see mid-build:
```
✅ 0.0 Create feature branch (golfler_asp_2)
✅ 1.0 Add DB migration
✅ 2.0 Add ClassPassService
⏸ 3.0 HUMAN TASK — run the app and confirm the API returns 200
   Reply "done" when complete.
```
You test it, reply `done`, and it continues automatically.

### Step 12 — All phases complete

```
✅ Phase 1 (backend-api) complete
✅ Phase 2 (pos-app-ui) complete
✅ Phase 3 (receipt-and-reporting) complete
...                                   (however many phases the feature had)
```
`bridge-docs\bridge-config.md` gets updated automatically — the feature moves to status **"Testing"** (not "Complete" yet), along with every branch name, regardless of how many units/repos were involved.

### Step 13 — Build & Test

AIDLC generates final instructions for testing the whole feature end-to-end, across all the repos that were touched.

It also runs an automatic **build check** across every repo the feature touched, to confirm they all still compile. Only if that passes does the feature flip from **"Testing"** to **"Complete"** in `bridge-docs\bridge-config.md`. If any repo fails to build, the status stays at "Testing" and you'll be shown exactly which repo failed and why — so a feature can never be marked done while it's broken.

## Quick summary (AIDLC + Looper)

```
Describe the feature
  → AIDLC asks questions — this time answer "Yes, use Looper"
  → Approve requirements / stories / design / units (same as AIDLC-only)
  → AIDLC hands the plan to Looper as ONE task folder, units = phases
  → /looper-plan  → reviews AIDLC's work, drafts one plan with all phases → you approve
  → /looper-implement  → builds phase by phase, pausing for human checks, committing + pushing each phase
  → AIDLC gives you final build & test instructions once every phase is done
```

## Which one should a beginner pick?

| If... | Use |
|---|---|
| You just have a ticket/task, nothing to plan | **Looper only** |
| You have a new feature idea, it's fairly small/simple, one repo | **AIDLC only** |
| You have a new feature idea, and it's large, spans multiple repos, or feels risky | **AIDLC + Looper** |

---

# KEY FILES (where things are saved)

| File | What it's for |
|---|---|
| `bridge-docs\bridge-config.md` | Live status of every feature and every unit |
| `aidlc-docs\reverse-engineering\` | One-time write-up of the existing codebase (shared by all features) |
| `aidlc-docs\{feature}\aidlc-state.md` | Where that feature's AIDLC planning is up to |
| `aidlc-docs\{feature}\audit.md` | Full history of everything said/decided for that feature |
| `RePIT-{ticket}-E1\` or `RePIT-AIDLC-{feature}-E1\` | Looper's task folder — the plan document + cloned repos |
| `AIDLC-{feature}\` | AIDLC Path A's own clone folder (no Looper) — repos identified during design, cloned here before Code Generation |
| `aidlc-docs\knowledge-base\` | Shared, cross-feature write-up of business logic, flows, and decisions — built automatically as you work (see below) |

---

# COMMAND CHEAT SHEET

| Command | What it does |
|---|---|
| `/aidlc` | Show the feature picker (existing features + "start a new one") |
| `/aidlc CCD-123` | Resume that feature if it exists, otherwise start a new one named CCD-123 |
| `/aidlc add receipt printing` | Start a new feature from a plain description |
| `/looper-plan CCD-123` | Research + plan a specific Jira ticket |
| `/looper-plan` | Research + plan from a plain description |
| `/looper-implement` | Build the current plan, phase by phase |
| `/looper-implement CCD-123` | Resume building a specific ticket |
| `/looper-setup` | One-time setup — clones a shared, read-only copy of all repos (do this first, before your first feature) |
| `/bridge-jira-sync` | Push AIDLC's user stories into Jira as an Epic + Stories |
| `/knowledge-base-update` | Manually refresh/backfill the knowledge base (normally automatic — see below) |

`/aidlc` is optional — AIDLC starts automatically the moment you describe what you want to build in plain English, in a new chat, or paste a ticket ID. Use `/aidlc` when you want an explicit, guaranteed entry point instead (e.g. to force the feature picker even if you don't type a request yet).

---

# THE KNOWLEDGE BASE (builds itself as you work)

Every time you approve an AIDLC stage, or finish a Construction unit / Looper phase, a background agent reads what just happened — the plan docs, and (for Construction/Looper) the actual code changes — and writes a short, plain-English summary of the durable business logic, flows, and decisions into `aidlc-docs\knowledge-base\`. It merges into existing files rather than piling up duplicates, so it stays a single readable reference for "how does this system actually work and why" — useful on your next ticket, and structured so it can later feed a RAG/search tool if you want one.

You don't need to do anything — it runs automatically. The only time you'd run `/knowledge-base-update` yourself is to backfill a feature that was built before this existed, or to force a re-run.

---

# TIPS FOR BEGINNERS

- **Run `/looper-setup` once**, the very first time you use this workspace on an existing codebase. It saves time later.
- **You're always in control.** Both AIDLC and Looper stop and wait for your approval at every important step — nothing gets built or committed without you saying so.
- **Answering questions fast:** you can just reply with letters, e.g. `1A, 2B, 3C` — no need to write full sentences.
- **If Looper pauses on a `[Human]` task**, it's telling you exactly what to check manually — do that, then reply `"done"`.
- **If you're unsure which path to use**, default to describing the feature in plain English — AIDLC will start and ask you the right questions, including whether to bring in Looper.
- **Nothing is lost if you close the session.** Both tools save their progress to files, so you can resume anytime by starting a new session and asking to continue.
