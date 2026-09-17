# Looper Construction Harness — Opt-In

**Extension**: Looper (Define Labs Development Harness)  
**Override location**: `bridge-docs\bridge-overrides\` — workspace customisation, not a vendor file.  
**Do not edit** `.aidlc-rule-details\extensions\looper\` — that directory is managed by upstream AIDLC updates.

---

## What Looper Does

When opted in, Looper **replaces AIDLC's native Code Generation stage** with a Research→Plan→Implement→Test methodology (RePIT documents). Looper adds:
- Structured per-unit research before coding
- A living RePIT document as the authoritative implementation plan
- Automatic git branching and per-phase commits
- Jira ticket updates on phase completion

When **not** opted in, AIDLC's native Code Generation and Build & Test stages run instead.

---

## Opt-In Prompt

The following question is automatically included in the Requirements Analysis clarifying questions:

```markdown
## Question: Construction Methodology
Should Looper be used for the Construction phase of this feature?

A) Yes — use Looper's RePIT process (Research→Plan→Implement→Test): structured research, living plan document, automatic git branching and commits per unit. Recommended for production features touching multiple repos.

B) No — use AIDLC's native Code Generation: plan + generate code directly, no separate harness. Suitable for smaller features or when direct code generation is preferred.

[Answer]: 
```
