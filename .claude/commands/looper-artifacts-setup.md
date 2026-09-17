# Rule: Clone the Stable Reference Codebase

## Banner

Before doing anything else, read and output the banner from [artifacts/looper-code-banner.md](../artifacts/looper-code-banner.md).

## Goal

Create and maintain a persistent, read-only `stable-codebase/` workspace containing
shallow clones of the Golfler / ClubCaddie platform repos at their canonical release
branches. Lets looper agents grep/read code for reference without re-cloning on every
task.

⚠️ **This file is an internal sub-routine.** It is invoked only by `/looper-setup`'s
Step 6 (read-and-execute-inline) and is intentionally NOT copied into
`<workspace>/.claude/commands/` by `/looper-initialize` — there is no standalone
`/looper-artifacts-setup` slash command. To refresh the stable codebase, re-run
`/looper-setup` (safe and idempotent).

Supports **Windows**, **macOS**, and **Linux**.

## Single Source of Truth: `artifacts/project-structure.md`

This routine does **NOT** carry its own list of repos, URLs, or branches. The
manifest is parsed from [`looper-code/artifacts/project-structure.md`](../artifacts/project-structure.md)
at runtime — that file is the canonical inventory of platform repos and their
release branches. Updating branches there is the supported way to change what
`/looper-setup` clones; nothing in this file should be edited to reflect a branch
change.

### Folder-name mapping rule

For each repo entry parsed from `project-structure.md`:

- If the entry name has a parenthetical disambiguator (e.g. `cc_mobile_pos (Flex)`,
  `cc_mobile_pos (FnB)`), the stable folder name is `<base>-<suffix>` where
  `<base>` is the bare repo name with underscores replaced by dashes and `<suffix>`
  is the lowercased parenthetical token (e.g. `cc-mobile-pos-flex`,
  `cc-mobile-pos-fnb`).
- Otherwise, the stable folder name is the bare repo name as-is (e.g.
  `golfler_asp_2`, `sgs-cts-angular`).

This is the only rule. Do not invent additional renaming.

### Example layout (snapshot — actual contents are derived at runtime)

```
<workspace-root>/
└── looper-code-artifacts/
    └── stable-codebase/
        ├── golfler_asp_2/
        ├── golfler_pos_2/
        ├── sgs-cts-angular/
        ├── cc-mobile-pos-flex/
        ├── cc-mobile-pos-fnb/
        ├── cc_api_manager/
        ├── cc_membership_portal/
        ├── cc_ios/
        └── cc_android/
```

If `project-structure.md` adds, removes, or rebranches an entry, the next run of
`/looper-setup` reflects the change automatically.

## Process

### Step 0: Display welcome header

Output:
```
=== Looper Artifacts Setup ===
Provisioning the stable reference codebase from artifacts/project-structure.md...
```

---

### Step 1: Resolve workspace root

The workspace root is the primary working directory provided by the shell environment
(the same folder that contains `looper-code/`). Use it directly — do not run
`git rev-parse` or search parent directories.

Hold it as `WORKSPACE_ROOT`. All paths below are relative to it.

---

### Step 2: Parse the manifest from `artifacts/project-structure.md`

Read the file at `<WORKSPACE_ROOT>/looper-code/artifacts/project-structure.md`. Build
an in-memory manifest where each entry contains four fields: **Repo name**, **Release
branch**, **Clone URL**, and **Folder name**.

**How to parse each field:**

1. **Repo name + Release branch** — from the `## Repository Overview` table near the
   top of the file (a 5-column Markdown table with header
   `| Repo | Type | API | Release Branch | Role |`). Iterate every data row and
   extract the `Repo` column (col 1) and `Release Branch` column (col 4). Strip
   surrounding backticks and whitespace. The `Repo` cell may include a parenthetical
   disambiguator like `(Flex)` or `(FnB)` — keep it; the folder-name rule consumes
   it in step 4 below.

2. **Clone URL** — each repo has a dedicated section later in the file (heading
   `# <repo-name> — ...`) containing a fenced ` ```bash ` block whose first
   non-empty line is
   `git clone git@bitbucket.org:definelabs/<repo-name>.git`. The URL is the second
   whitespace-separated token on that line. For entries that share a base repo name
   but differ only by parenthetical (the two `cc_mobile_pos` rows), look up the URL
   once from the single shared `# cc_mobile_pos — ...` section and reuse it for both
   manifest entries.

3. **Folder name** — apply the **Folder-name mapping rule** documented above to the
   parsed Repo name.

**After parsing, emit a numbered preview table** so the user sees what was found and
can reference entries by number in the selection step that follows:

```
Manifest parsed from artifacts/project-structure.md (<N> entries):

   1. <folder-name>          → <branch>                (<url>)
   2. <folder-name>          → <branch>                (<url>)
   ...
```

If parsing fails for any row (missing column, missing matching `git clone` block in
the repo's section, unrecognised parenthetical), surface the failing row to the user
and skip it — **do not invent a default URL or branch**. Subsequent steps process
only rows that parsed successfully.

This is also the right place to detect schema drift: if the overview table no longer
has exactly the columns `| Repo | Type | API | Release Branch | Role |`, stop with a
clear error so the user can fix `project-structure.md`.

---

### Step 2.5: Let the user choose which repos to install

Do **not** clone the entire manifest unconditionally. After the numbered preview from
Step 2, prompt the user to choose which entries to provision this run:

```
Which repos do you want to set up in the stable codebase?

  • Press Enter (or type `all`) to clone/refresh all <N> repos.
  • Enter a comma- or space-separated list of numbers to pick a subset
    (e.g. `1,3,5` or `1 3 5`).
  • You may also reference entries by folder name (e.g. `golfler_asp_2, cc_api_manager`).
  • Type `none` (or `q`) to cancel without cloning anything.
```

Wait for the user's reply, then resolve it against Step 2's parsed manifest:

- **Empty / `all` (case-insensitive)** → the selected manifest is the full parsed
  manifest.
- **A list of numbers** → keep only the entries whose 1-based position in the Step 2
  table matches. Ignore out-of-range numbers but warn about each one
  (`⚠️ Ignored selection "12" — only <N> entries exist`).
- **A list of folder names** → match case-insensitively against each entry's folder
  name (the value produced by the Folder-name mapping rule). Warn about any token that
  matches nothing (`⚠️ Ignored selection "foo" — no matching repo`). Numbers and
  names may be mixed in one reply.
- **`none` / `n` / `q` / `cancel` (case-insensitive)** → output
  `⏭️  No repos selected — nothing cloned this run.` and **skip Steps 3–5 entirely**,
  jumping to a minimal summary noting that the user selected zero repos.
- **A reply that resolves to zero valid entries** (e.g. all tokens were ignored) →
  re-print the numbered preview and **re-prompt**. Do not silently clone everything.

**After resolving, echo the confirmed selection back** so the user sees exactly what
will be processed before any network work begins:

```
Selected <M> of <N> repos to set up:
   1. <folder-name>          → <branch>
   3. <folder-name>          → <branch>
   ...
```

From this point on, **"the manifest" means this user-selected subset.** Steps 3, 4,
and 5 operate only on the selected entries — the `$manifest` / `FOLDERS,URLS,BRANCHES`
data structures passed to Step 4 MUST contain only the chosen rows, and the Step 5
summary reports `<M>` selected entries (not the full `<N>`).

---

### Step 3: Create the artifacts tree

Ensure `<WORKSPACE_ROOT>/looper-code-artifacts/stable-codebase/` exists. Idempotent —
re-running does not fail if the folders are already present.

**Windows (PowerShell):**
```powershell
$workspaceRoot   = "<primary-working-dir>"   # replace with the actual workspace root
$artifactsRoot   = Join-Path $workspaceRoot "looper-code-artifacts"
$stableCodebase  = Join-Path $artifactsRoot "stable-codebase"

New-Item -ItemType Directory -Force -Path $stableCodebase | Out-Null
Write-Host "Stable codebase root: $stableCodebase"
```

**Mac / Linux (bash):**
```bash
WORKSPACE_ROOT="<primary-working-dir>"   # replace with the actual workspace root
ARTIFACTS_ROOT="$WORKSPACE_ROOT/looper-code-artifacts"
STABLE_CODEBASE="$ARTIFACTS_ROOT/stable-codebase"

mkdir -p "$STABLE_CODEBASE"
echo "Stable codebase root: $STABLE_CODEBASE"
```

---

### Step 4: Clone or refresh each entry in the parsed manifest

For each entry in **Step 2.5's user-selected manifest**, run the clone-or-refresh
routine. Process sequentially (one entry at a time). Emit a one-line status as each
completes:

- `✅ <folder> — Cloned   @ <branch>`
- `🔄 <folder> — Refreshed @ <branch>`
- `⚠️ <folder> — Skipped (not a git repo — delete the folder and re-run)`
- `❌ <folder> — Failed    @ <branch> — <stderr snippet, first 5 lines>`

Store every outcome (folder, branch, status, error snippet if any) in a `$results`
array (PowerShell) or `RESULTS` accumulator (bash) for the Step 5 summary table.

⚠️ **A failure on one repo MUST NOT abort the whole step.** Catch the error, record
it, and continue to the next manifest entry.

⚠️ **Do NOT hardcode the manifest inside this step.** The `$manifest` /
`FOLDERS,URLS,BRANCHES` data structures referenced below MUST be populated from
Step 2.5's user-selected subset (derived from Step 2's parsed output), not from a
literal list in this file.

**Windows (PowerShell):**

```powershell
# $manifest is an array of PSCustomObject entries produced by Step 2:
#   [PSCustomObject]@{ Folder = <string>; Url = <string>; Branch = <string> }
# Do NOT define $manifest inline here — use the value built by the parser in Step 2.

$results = @()
foreach ($r in $manifest) {
    $target = Join-Path $stableCodebase $r.Folder
    $gitDir = Join-Path $target ".git"

    try {
        if (-not (Test-Path $target)) {
            $stderr = & git clone --depth 1 --branch $r.Branch $r.Url $target 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $($r.Folder) — Cloned   @ $($r.Branch)"
                $results += [PSCustomObject]@{ Folder=$r.Folder; Branch=$r.Branch; Status="Cloned";    Error=$null }
            } else {
                $snippet = ($stderr | Select-Object -First 5) -join "`n"
                Write-Host "❌ $($r.Folder) — Failed    @ $($r.Branch) — $snippet"
                $results += [PSCustomObject]@{ Folder=$r.Folder; Branch=$r.Branch; Status="Failed";    Error=$snippet }
            }
        }
        elseif (-not (Test-Path $gitDir)) {
            Write-Host "⚠️ $($r.Folder) — Skipped (not a git repo — delete the folder and re-run)"
            $results += [PSCustomObject]@{ Folder=$r.Folder; Branch=$r.Branch; Status="Skipped";   Error="not a git repo" }
        }
        else {
            $stderr = & git -C $target fetch --depth 1 origin $r.Branch 2>&1
            if ($LASTEXITCODE -ne 0) { throw "fetch failed: $($stderr -join '; ')" }
            $stderr = & git -C $target checkout $r.Branch 2>&1
            if ($LASTEXITCODE -ne 0) { throw "checkout failed: $($stderr -join '; ')" }
            $stderr = & git -C $target reset --hard "origin/$($r.Branch)" 2>&1
            if ($LASTEXITCODE -ne 0) { throw "reset failed: $($stderr -join '; ')" }

            Write-Host "🔄 $($r.Folder) — Refreshed @ $($r.Branch)"
            $results += [PSCustomObject]@{ Folder=$r.Folder; Branch=$r.Branch; Status="Refreshed"; Error=$null }
        }
    } catch {
        $msg = $_.Exception.Message
        Write-Host "❌ $($r.Folder) — Failed    @ $($r.Branch) — $msg"
        $results += [PSCustomObject]@{ Folder=$r.Folder; Branch=$r.Branch; Status="Failed";    Error=$msg }
    }
}
```

**Mac / Linux (bash):**

```bash
# FOLDERS, URLS, BRANCHES are parallel arrays produced by Step 2's parser.
# Do NOT define them inline here — use the values built from project-structure.md.

RESULTS=()   # each row: "<folder>|<branch>|<status>|<error or empty>"

for i in "${!FOLDERS[@]}"; do
    folder="${FOLDERS[$i]}"; url="${URLS[$i]}"; branch="${BRANCHES[$i]}"
    target="$STABLE_CODEBASE/$folder"

    if [ ! -d "$target" ]; then
        stderr=$(git clone --depth 1 --branch "$branch" "$url" "$target" 2>&1)
        if [ $? -eq 0 ]; then
            echo "✅ $folder — Cloned   @ $branch"
            RESULTS+=("$folder|$branch|Cloned|")
        else
            snippet=$(echo "$stderr" | head -5 | tr '\n' ' ')
            echo "❌ $folder — Failed    @ $branch — $snippet"
            RESULTS+=("$folder|$branch|Failed|$snippet")
        fi
    elif [ ! -d "$target/.git" ]; then
        echo "⚠️ $folder — Skipped (not a git repo — delete the folder and re-run)"
        RESULTS+=("$folder|$branch|Skipped|not a git repo")
    else
        err=""
        stderr=$(git -C "$target" fetch --depth 1 origin "$branch" 2>&1) || err="fetch failed: $stderr"
        if [ -z "$err" ]; then
            stderr=$(git -C "$target" checkout "$branch" 2>&1) || err="checkout failed: $stderr"
        fi
        if [ -z "$err" ]; then
            stderr=$(git -C "$target" reset --hard "origin/$branch" 2>&1) || err="reset failed: $stderr"
        fi

        if [ -z "$err" ]; then
            echo "🔄 $folder — Refreshed @ $branch"
            RESULTS+=("$folder|$branch|Refreshed|")
        else
            snippet=$(echo "$err" | head -5 | tr '\n' ' ')
            echo "❌ $folder — Failed    @ $branch — $snippet"
            RESULTS+=("$folder|$branch|Failed|$snippet")
        fi
    fi
done
```

---

### Step 5: Print the summary table

After every manifest entry has been processed, print a final summary in this exact
format. The model executing this step must format the table from the `$results` /
`RESULTS` accumulator built in Step 4.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                  LOOPER ARTIFACTS — STABLE CODEBASE                          ║
║                  <date-time>                                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

Manifest source:        artifacts/project-structure.md (<M> of <N> entries selected)
Stable codebase root:   <WORKSPACE_ROOT>/looper-code-artifacts/stable-codebase/

┌──────────────────────────┬─────────────────────────────────────────────┬────────────────┐
│ Folder                   │ Branch                                      │ Status         │
├──────────────────────────┼─────────────────────────────────────────────┼────────────────┤
│ <folder>                 │ <branch>                                    │ ✅ Cloned       │
│ <folder>                 │ <branch>                                    │ 🔄 Refreshed   │
│ ...                      │ ...                                         │ ...            │
└──────────────────────────┴─────────────────────────────────────────────┴────────────────┘

FAILED REPOS: <N>
  ❌ <folder> — <first line of stderr verbatim>
```

Rules for the table:
- One row per **selected** manifest entry, in the order produced by Step 2.5.
- Truncate branch names longer than 43 chars with `…` in the middle (keep both ends
  recognisable, e.g. `rtj_and_validation_punch_…New_UI`).
- If any row is `❌ Failed`, include a `FAILED REPOS: N` section listing each failed
  folder with the first line of its captured stderr verbatim.
- If every row is `✅ Cloned` or `🔄 Refreshed` (no failures, no skips), end with
  `ALL REPOS READY ✅`.
- If any row is `⚠️ Skipped`, include a `SKIPPED REPOS: N` section listing each with
  its reason.

---

## Notes

- Re-running this routine (via `/looper-setup`) is the supported refresh path. Every
  existing clone is fetched and hard-reset to the latest tip of its release branch,
  so any accidental local edits inside the stable codebase will be discarded — this
  is intentional, the stable codebase is reference-only.
- **Manifest changes belong in `artifacts/project-structure.md`, not here.** If a
  release branch is renamed, a new repo is added, or a repo is removed, edit
  `project-structure.md` and re-run `/looper-setup`. Nothing in this file should be
  modified to reflect a branch or URL change.
- SSH access to `bitbucket.org` is required. If clones fail with
  `Permission denied (publickey)`, configure your SSH agent / keys and re-run.
- No `--single-branch` flag override is needed — `--depth 1 --branch <branch>`
  already implies single-branch behaviour in modern git.
- Sequential processing keeps stderr readable. Parallelising the clones would shave
  seconds at the cost of interleaved logs and harder error attribution.
