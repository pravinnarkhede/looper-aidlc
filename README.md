# looper-aidlc

A bridge workspace that combines two AI-assisted development systems into one workflow:

- **[AIDLC](https://en.wikipedia.org/wiki/AI-driven_lifecycle)** (AWS AI-Driven Lifecycle) — the **planner**. Governs Inception: requirements, user stories, application design, and unit decomposition. Determines *what* to build.
- **[Looper](looper-code/)** (Define Labs Development Harness) — the **builder**. An optional Construction extension that turns each AIDLC unit into a RePIT (Research → Plan → Implement → Test) document, then implements it phase by phase with git branches, commits, and pushes.

You can use either system alone, or combine them — AIDLC plans, Looper builds.

## Where to start

| I want to... | Read |
|---|---|
| Set up this workspace for the first time | [SETUP.md](SETUP.md) |
| Learn how to actually use it, step by step (with examples) | [HOW-TO-USE.md](HOW-TO-USE.md) |
| Understand the exact rules Claude follows (paths, triggers, phase gates) | [CLAUDE.md](CLAUDE.md) |

If you're new here, start with **[HOW-TO-USE.md](HOW-TO-USE.md)** — it has three full beginner walkthroughs (Looper only, AIDLC only, AIDLC + Looper together) and a cheat sheet of every command.

## How it fits together

```
1. Describe a feature (or give a Jira ticket) — or run /aidlc
        ↓
2. AIDLC — Inception phase
   Requirements → User Stories → Workflow Planning → Application Design → Units Generation
   (docs saved per-feature under aidlc-docs\{feature-name}\)
        ↓
3. Construction phase — pick one:
   Path A: AIDLC builds the code itself, unit by unit
   Path B: Looper builds it — one RePIT, one phase per AIDLC unit, per-repo git branches
        ↓
4. Build & Test — cross-unit/phase integration instructions + an automatic
   build check across every touched repo (a feature can't reach "Complete" while any repo fails to compile)
```

Every feature/ticket gets its own isolated doc folder (`aidlc-docs\{feature-name}\`) and, if Looper is used, its own task workspace (`RePIT-AIDLC-{feature-name}-E1\`) with all affected repos cloned inside it as siblings.

## Knowledge base

As you work, a background agent (`knowledge-base-builder`) distills durable business logic, flows, and decisions — from both the planning docs and the actual code changes — into a shared, growing reference at `aidlc-docs\knowledge-base\`. It runs automatically after every approved Inception stage and every completed Construction unit / Looper phase, so the next ticket starts with context instead of a blank page. See the "THE KNOWLEDGE BASE" section in [HOW-TO-USE.md](HOW-TO-USE.md) for details.

## Everything is tracked

- `bridge-docs\bridge-config.md` — live status of every feature and unit
- `aidlc-docs\{feature-name}\aidlc-state.md` / `audit.md` — per-feature progress and full audit trail
- Plans (AIDLC docs and RePITs) are mirrored to shared git repos, never left on one machine only, so any teammate can pull and resume

## Workspace layout

```
looper-aidlc\
├── CLAUDE.md                  ← rules Claude follows to run this workflow
├── HOW-TO-USE.md              ← beginner's guide with full walkthroughs
├── SETUP.md                   ← one-time setup instructions
├── bridge-docs\
│   └── bridge-config.md       ← live status of every feature + unit/phase (multi-feature tracker)
├── .aidlc-rule-details\        ← bundled AIDLC rules + bridge extensions
├── .claude\                    ← Looper harness commands/agents/hooks
├── looper-code\                ← Looper harness codebase (vendored, do not edit)
└── looper-code-artifacts\      ← optional read-only stable codebase mirror
```

## Full hierarchy, with a feature actually running through it

The layout above is the static skeleton. Here's what it looks like once features are in flight — one on Path A (AIDLC builds it), one on Path B (Looper builds it), each with more than one unit/phase and more than one repo, since that's the general case:

```
looper-aidlc\
│
├── aidlc-docs\
│   ├── reverse-engineering\             ← SHARED, one-time per codebase (brownfield only)
│   │
│   ├── knowledge-base\                  ← SHARED, cross-feature, fed by every feature below
│   │   ├── index.md                     ← glossary + table of contents
│   │   ├── business-logic\
│   │   │   └── {domain}.md              ← e.g. billing.md — merges content from multiple features over time
│   │   └── flows\
│   │       └── {flow-name}.md           ← multi-actor/multi-repo processes
│   │
│   ├── {feature-A}\                     ← Path A example — one folder per ticket/feature, always
│   │   ├── aidlc-state.md
│   │   ├── audit.md
│   │   ├── inception\
│   │   │   ├── requirements\
│   │   │   ├── plans\
│   │   │   ├── application-design\      ← only if the feature needs more than one unit
│   │   │   └── units-generation\
│   │   └── construction\
│   │       ├── {unit-1}\                ← one subfolder per unit, only if >1 unit
│   │       ├── {unit-2}\
│   │       └── build-and-test\
│   │
│   └── {feature-B}\                     ← Path B example — Inception docs look identical to Path A
│       ├── aidlc-state.md
│       ├── audit.md
│       └── inception\
│           ├── requirements\
│           ├── plans\
│           └── units-generation\        ← these units become RePIT phases, not construction\ subfolders
│
├── AIDLC-{feature-A}\                   ← Path A's code clone folder (created once per feature)
│   ├── {repo-1}\                        ← real git clone — this is where AIDLC actually edits code
│   └── {repo-2}\
│
├── RePIT-AIDLC-{feature-B}-E1\          ← Path B's task workspace (created once per feature)
│   ├── RePIT-AIDLC-{feature-B}-E1.md    ← single plan doc, one phase per AIDLC unit
│   ├── {repo-1}\                        ← real git clone — Looper branches/commits/pushes here
│   └── {repo-2}\
│
├── looper-code\                         ← Looper harness (vendored, do not edit)
└── looper-code-artifacts\
    └── stable-codebase\                 ← optional read-only reference mirror
```

**Key things this hierarchy encodes:**
- `aidlc-docs\{feature}\` never contains code — only planning docs, state, and audit trail. Code always lives in a sibling folder at the workspace root (`AIDLC-{feature}\` or `RePIT-AIDLC-{feature}-E1\`), never nested inside `aidlc-docs\`.
- `reverse-engineering\` and `knowledge-base\` are the only two folders under `aidlc-docs\` that are *shared* — every other subfolder there is one isolated feature.
- A feature with only one unit skips the `{unit-N}\` subfolders and application-design entirely — everything above scales down as well as up.
- Path A and Path B never mix inside the same feature (see [CLAUDE.md](CLAUDE.md) for the documented escape hatch if a feature needs to switch mid-flight).
