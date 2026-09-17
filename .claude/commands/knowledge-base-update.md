# Command: /knowledge-base-update

## Goal

Manually trigger (or backfill) the shared, cross-feature project knowledge base at `aidlc-docs\knowledge-base\`, built by the `knowledge-base-builder` agent. This is the same agent invoked automatically after every Inception stage approval and every Construction unit / Looper phase completion — this command exists for ad-hoc refreshes or catching up on features that predate the automatic hook.

## Usage

```
/knowledge-base-update                          → backfill across ALL features under aidlc-docs\
/knowledge-base-update {feature-name}            → backfill one feature's full inception + construction docs
/knowledge-base-update {feature-name} {stage}    → re-run for a specific stage/unit/phase
```

## Steps

1. Determine scope from the arguments (all features / one feature / one stage-unit-phase).
2. For the given scope, list the relevant source paths:
   - `aidlc-docs\{feature-name}\inception\**`
   - `aidlc-docs\{feature-name}\construction\**`
   - `RePIT-AIDLC-{feature-name}-E1\RePIT-AIDLC-{feature-name}-E1.md` (if Looper was used)
   - The repos cloned under `RePIT-AIDLC-{feature-name}-E1\{repo}\` or `AIDLC-{feature-name}\{repo}\`, if present locally — for git-diff-based extraction (skip and note if not cloned on this machine)
3. Invoke the `knowledge-base-builder` agent with:
   - The scope description (all / one feature / one stage)
   - The list of source paths to read
   - Instruction: "on-demand backfill" trigger type
4. Present the agent's summary report (files created/updated, new glossary terms, flagged conflicts) to the user.

## Notes

- This command never modifies `aidlc-docs\{feature-name}\` or `RePIT-AIDLC-*` content — it only reads from them and writes to `aidlc-docs\knowledge-base\`.
- Safe to re-run repeatedly — the agent merges into existing knowledge-base files rather than duplicating content.
