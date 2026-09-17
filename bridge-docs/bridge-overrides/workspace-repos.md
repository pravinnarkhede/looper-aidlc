# Workspace Repo Selection

**Override location**: `bridge-docs\bridge-overrides\` — workspace customisation, not a vendor file.  
**Do not edit** `looper-code\artifacts\project-structure.md` — that file is managed by upstream Looper updates.

---

## Purpose

This file defines which repos are cloned into the stable codebase (`looper-code-artifacts\stable-codebase\`) for this environment.

When `/looper-setup` runs and asks "Which repos do you want to set up?", **default to the selection below** rather than cloning all 9.

---

## This Environment — Repo Selection

Select these **5 repos** (by folder name or number from the manifest):

| # | Folder name | Type | Why included |
|---|---|---|---|
| 1 | `golfler_asp_2` | ASP.NET | Core backend — always needed |
| 2 | `golfler_pos_2` | WPF POS | Staff POS terminal |
| 3 | `sgs-cts-angular` | Angular | CCOnline web app |
| 6 | `cc_api_manager` | PHP CodeIgniter | iFrames / booking widgets |
| 7 | `cc_membership_portal` | PHP CodeIgniter | Customer portal |

**Excluded** (not cloned in this env):

| Folder name | Type | Reason |
|---|---|---|
| `cc-mobile-pos-flex` | React Native | Not cloned — mobile POS not in active scope |
| `cc-mobile-pos-fnb` | React Native | Not cloned — mobile POS not in active scope |
| `cc_ios` | Swift / iOS | Not in scope for this env |
| `cc_android` | Kotlin / Android | Not in scope for this env |

---

## How to Apply

When `/looper-setup` shows the numbered manifest and asks which repos to set up, type:

```
1, 2, 3, 6, 7
```

Or by name:
```
golfler_asp_2, golfler_pos_2, sgs-cts-angular, cc_api_manager, cc_membership_portal
```

---

## Updating This File

- To add a repo: add a row to the "included" table above
- To remove a repo: move it to the "excluded" table
- Never edit `looper-code\artifacts\project-structure.md` — that is the upstream vendor manifest
- If a new repo is added upstream (new row in `project-structure.md`), decide here whether to include it
