# Bridge Workspace Setup

## What This Is
A standalone workspace that runs AIDLC (AWS AI-Driven Lifecycle) for requirements and design, then hands off to Looper (Define Labs harness) for per-unit implementation — linked by a shared bridge state file.

---

## Prerequisites

| Requirement | Location | Status |
|------------|----------|--------|
| AIDLC rule details | `.aidlc-rule-details\` (bundled in this workspace) | Ready |
| Looper commands | `.claude\commands\` (bundled in this workspace) | Ready |
| Looper agents | `.claude\agents\` (bundled in this workspace) | Ready |
| Looper harness | `looper-code\` (bundled in this workspace) | Ready |
| Claude Code (VS Code extension) | Installed | Must be active |

Everything is self-contained — no external dependencies required.

---

## One-Time Initialization (do this once per project)

### Step 1 — Open this workspace in VS Code
```
code {path-to-this-workspace}
```

### Step 2 — (Optional) Provision the stable codebase mirror
If your repos are large and you want reference-only reads to avoid repeated cloning, run:
```
/looper-setup
```
When prompted for "Set up stable codebase? (y/n)": enter `y`.
This creates `looper-code-artifacts\stable-codebase\` with read-only reference clones.

### Step 3 — Start your first project
In a new Claude Code session just say:
```
Start a new software development project.
```
AIDLC's Inception phase will begin automatically (Workspace Detection → Requirements → ... → Units Generation).

---

## Typical Session Flow

```
Session 1: AIDLC Inception
  ├─ Workspace Detection
  ├─ Requirements Analysis
  ├─ User Stories
  ├─ Workflow Planning
  ├─ Application Design
  └─ Units Generation
       ↓
  bridge-docs\bridge-config.md populated with unit → RePIT mapping

Sessions 2+: Looper Construction (one session per unit, or continue across sessions)
  ├─ Unit 1: /looper-plan → /looper-implement
  ├─ Unit 2: /looper-plan → /looper-implement
  └─ ...

Final Session: Build & Test
  └─ AIDLC cross-unit integration test instructions
```

---

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Bridge master — tells Claude how to run both systems |
| `bridge-docs\bridge-config.md` | Shared state: AIDLC stages + Looper RePIT mapping |
| `.aidlc-rule-details\extensions\looper\looper.md` | Always-on Looper rules for Construction |
| `.claude\settings.json` | Permissions + Looper session cost hook |
| `aidlc-docs\audit.md` | AIDLC audit trail (auto-generated) |
| `aidlc-docs\aidlc-state.md` | AIDLC workflow state (auto-generated) |

---

## Resuming a Session

If you return to an in-progress project, Claude will:
1. Detect `aidlc-docs\aidlc-state.md` and resume from the last completed stage
2. Check `bridge-docs\bridge-config.md` for unit status (Pending/In Progress/Complete)
3. For Looper units in progress: find the RePIT document in the unit's task workspace

---

## Adding AIDLC Extensions

Place extensions in the AIDLC template directory (applies to all workspaces):
```
d:\aidlc\workspace-common-template\.aidlc-rule-details\extensions\{extension-name}\
  {extension-name}.opt-in.md   ← shown to user during Requirements Analysis
  {extension-name}.md          ← full rules, loaded only if user opts in
```

To add a bridge-specific extension (this workspace only), place it in:
```
.aidlc-rule-details\extensions\{extension-name}\
```
Without an `.opt-in.md` file, it is always enforced.

---

## Troubleshooting

**Looper commands not available (`/looper-plan` not found)**
→ Check that `.claude\commands\looper-plan.md` exists — if missing, copy from `looper-code\commands\`

**AIDLC rules not loading**
→ Check that `.aidlc-rule-details\common\`, `.aidlc-rule-details\inception\`, `.aidlc-rule-details\construction\` all exist

**Stable mirror missing for a repo**
→ Run `/looper-setup` and enter `y` when asked about stable codebase provisioning

**Session cost not logging**
→ Check that `.claude\settings.json` Stop hook path points at `{this-workspace-root}\looper-code\hooks\looper-session-hook.ps1` — if the workspace was ever moved or renamed, this absolute path goes stale silently and needs updating by hand
