# Looper Extension — Construction Phase Rules

## Status
Always-on extension. No `.opt-in.md` file — these rules are enforced in every session of this bridge workspace.

## Purpose
Enforces Looper's RePIT methodology during the Construction phase. Each AIDLC feature is implemented as one Looper RePIT — AIDLC units become phases within that single RePIT.

---

## Hard Constraints (All Are Blocking — Non-Negotiable)

### Feature Isolation
- Each AIDLC feature gets **ONE** Looper task workspace: `{bridge-root}\RePIT-AIDLC-{feature-name}-E1\`
- All repos for the feature are cloned as siblings inside this single folder
- AIDLC units map to RePIT phases — they share the same workspace and repo clones
- Never share a task workspace between two different features

### RePIT Document Fidelity
- The RePIT `.md` file is the authoritative source of truth for the entire feature's implementation
- All implementation decisions must be recorded in the RePIT BEFORE executing them
- Never implement a task not listed in the RePIT
- Check off tasks (`- [ ]` → `- [x]`) IMMEDIATELY after completion — never in batch

### Repo Classification
Before ANY cloning, classify every in-scope repo:
- **✏️ Change** — will be modified; must be a fresh per-task clone in the unit's task workspace
- **🔍 Reference** — read-only context; resolve from stable mirror at `looper-code-artifacts\stable-codebase\`
- **❌ Out-of-scope** — do not access at all

The stable mirror is **read-only** — never edit, branch, or commit in it.
If the stable mirror is absent for a Reference repo, fall back to a per-task clone (still read-only).

### Code Change Safety
- Make surgical, targeted changes only — no refactoring beyond the task scope
- Every database query must include `WHERE CourseId = @CourseId` (multi-tenant isolation)
- Never break mobile API contracts (no removed or renamed fields in existing endpoints)
- Never touch payment code without stopping and asking the user first
- If a proposed change exceeds 300 lines or 5 files: **STOP and ask**

### Phase Gates
- Complete all tasks for Phase N before starting Phase N+1
- Each phase ends with: `git add` → `git commit` → `git push` → update RePIT version → offer Jira sync
- Report the commit hash and pushed branch URL to the user after each phase push
- Never skip the commit-and-push task at the end of a phase

### Human Task Handling
- Never skip `[Human]` tasks
- When a `[Human]` task is reached: state what is required, wait for the user to confirm "done" before continuing
- Never proceed past a `[Human]` task without explicit confirmation

---

## Bridge State Maintenance

Update `bridge-docs\bridge-config.md` at these events:

| Event | Status Change |
|-------|--------------|
| /looper-plan starts for a feature | `Pending` → `In Progress` |
| /looper-implement completes all phases | `In Progress` → `Complete` |
| Feature is blocked on a human dependency | Add `Blocked` note to that row |

After each Looper phase completes, append to `aidlc-docs\audit.md`:
```
## Construction — {Unit Name} (Looper)
**Timestamp**: {ISO 8601 timestamp}
**User Input**: "{any user input during this phase}"
**AI Response**: "Looper Phase {N} complete. Branch: {branch-name}. Files changed: {count}."
**Context**: Construction phase, Unit {unit-number} of {total}, Phase {N}.

---
```

---

## AIDLC Design as Looper Input

When invoking /looper-plan for an AIDLC unit, pass the following as initial context (reduces Step 2 research burden):

| AIDLC Artifact | Location | Looper Use |
|----------------|----------|------------|
| Unit description | `aidlc-docs\inception\units-generation\` | Feature title and scope |
| Functional requirements | `aidlc-docs\inception\requirements\` | Functional Requirements section |
| NFR requirements | `aidlc-docs\inception\requirements\` | Non-Functional Requirements section |
| Application design | `aidlc-docs\inception\application-design\` | Design Considerations section |
| Functional design (if exists) | `aidlc-docs\construction\{unit-name}\functional-design\` | Design Considerations |

When these artifacts are present, looper-plan Step 2 (Research & Discovery) should:
- Reference AIDLC artifacts instead of re-researching what AIDLC already covered
- Supplement with codebase-locator and codebase-analyzer agents for implementation-level details
- Note which findings come from AIDLC vs codebase research

---

## Compliance Checklist (Per Feature)

### Before starting /looper-plan:
- [ ] Single task workspace created: `{bridge-root}\RePIT-AIDLC-{feature-name}-E1\`
- [ ] `bridge-docs\bridge-config.md` updated: feature status = `In Progress`
- [ ] ALL AIDLC design artifacts for all units read into context
- [ ] Repo classifications decided across all units (before any cloning)
- [ ] All in-scope repos cloned as siblings inside the single task workspace

### Before starting /looper-implement:
- [ ] RePIT document approved by user
- [ ] AIDLC units confirmed as phases in the RePIT
- [ ] Feature branches planned per phase per repo

### After all Looper phases complete:
- [ ] All RePIT tasks checked `[x]`
- [ ] All phase branches committed and pushed
- [ ] `bridge-docs\bridge-config.md` updated: status = `Complete`, all branch names listed
- [ ] Looper completion logged in `{FEATURE_ROOT}\audit.md`

---

## Applicable Stages

This extension applies during: **Construction phase only** (per-unit Looper execution).

It does NOT apply during: Inception phase, Build and Test, Operations phase.

At Inception stages, mark this extension as N/A in the compliance summary.
