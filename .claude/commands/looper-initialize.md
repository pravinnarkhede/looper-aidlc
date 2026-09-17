# Rule: Initialize Looper Commands and Agents

## Banner

Before doing anything else, read and output the banner from [artifacts/looper-code-banner.md](../../looper-code/artifacts/looper-code-banner.md).

## Goal

Copy all looper commands, agents, and hooks from the `looper-code/` root folder in the workspace (the primary working directory) to the **workspace-level** `.claude/` folder (`<workspace_root>/.claude/`), making `/looper-plan`, `/looper-implement`, and `/generate-tasks` available in all Claude Code sessions inside the workspace.

Supports **Windows**, **macOS**, and **Linux**.

## Process

### Step 0: Read the version

Read `looper-code/VERSION` from the primary working directory to get the version being installed (e.g., `1.0.0`). Store it as `SOURCE_VERSION`.

Then check whether a previous version is already installed by reading `~/.claude/looper-version` (Mac/Linux) or `$USERPROFILE/.claude/looper-version` (Windows). If the file exists, store its content as `INSTALLED_VERSION`; otherwise set `INSTALLED_VERSION` to `none`.

### Step 0.5: Clean legacy global Claude user files

Remove any looper artifacts that were installed globally by versions prior to 0.5.0. This step is idempotent — it silently skips anything that does not exist. It also removes Stop hook entries in the global `settings.json` that embed workspace-specific full paths (these accumulated from old global installs).

**Windows (PowerShell):**

```powershell
$globalDir = "$env:USERPROFILE\.claude"

# Remove looper command files
$looperCommands = @(
    "looper-plan.md", "looper-implement.md", "generate-tasks.md",
    "looper-initialize.md", "looper-setup.md"
)
$removedCommands = @()
foreach ($f in $looperCommands) {
    $p = "$globalDir\commands\$f"
    if (Test-Path $p) { Remove-Item $p -Force; $removedCommands += $f }
}

# Remove looper agent files
$looperAgents = @(
    "codebase-analyzer.md", "codebase-locator.md", "codebase-pattern-finder.md",
    "thoughts-analyzer.md", "thoughts-locator.md", "web-search-researcher.md",
    "jira-repit-updater.md", "build-checker.md"
)
$removedAgents = @()
foreach ($f in $looperAgents) {
    $p = "$globalDir\agents\$f"
    if (Test-Path $p) { Remove-Item $p -Force; $removedAgents += $f }
}

# Remove hook (hooks/ subdirectory and root location for even older installs)
$removedHooks = @()
foreach ($hookPath in @("$globalDir\hooks\looper-session-hook.ps1", "$globalDir\looper-session-hook.ps1")) {
    if (Test-Path $hookPath) { Remove-Item $hookPath -Force; $removedHooks += $hookPath }
}

# Remove global looper-version file
$removedVersion = $false
if (Test-Path "$globalDir\looper-version") { Remove-Item "$globalDir\looper-version" -Force; $removedVersion = $true }

# Remove looper Stop hook entries from global settings.json (these embed workspace-specific paths)
$removedStopEntries = 0
$globalSettings = "$globalDir\settings.json"
if (Test-Path $globalSettings) {
    $cfg = Get-Content $globalSettings -Raw | ConvertFrom-Json
    if ($cfg.PSObject.Properties['hooks'] -and $cfg.hooks.PSObject.Properties['Stop']) {
        $before = $cfg.hooks.Stop.Count
        $cfg.hooks.Stop = @($cfg.hooks.Stop | Where-Object {
            -not ($_.hooks | Where-Object { $_.command -like "*looper-session-hook*" })
        })
        $removedStopEntries = $before - $cfg.hooks.Stop.Count
        if ($removedStopEntries -gt 0) {
            $cfg | ConvertTo-Json -Depth 10 | Set-Content $globalSettings -Encoding UTF8
        }
    }
}

# Store results for Step 8 summary
$global:looperCleanup = [PSCustomObject]@{
    Commands    = if ($removedCommands.Count)  { $removedCommands -join ", " } else { "none found" }
    Agents      = if ($removedAgents.Count)    { $removedAgents -join ", " }   else { "none found" }
    Hooks       = if ($removedHooks.Count)     { $removedHooks -join ", " }    else { "none found" }
    Version     = if ($removedVersion)         { "removed" }                   else { "none found" }
    StopEntries = $removedStopEntries
}
Write-Host "Global Claude user cleanup complete."
```

**Mac / Linux (bash):**

```bash
GLOBAL_DIR="$HOME/.claude"
LOOPER_COMMANDS=(looper-plan.md looper-implement.md generate-tasks.md looper-initialize.md looper-setup.md)
LOOPER_AGENTS=(codebase-analyzer.md codebase-locator.md codebase-pattern-finder.md thoughts-analyzer.md thoughts-locator.md web-search-researcher.md jira-repit-updater.md build-checker.md)

removed_commands=(); removed_agents=(); removed_hooks=()
for f in "${LOOPER_COMMANDS[@]}"; do
    [ -f "$GLOBAL_DIR/commands/$f" ] && rm -f "$GLOBAL_DIR/commands/$f" && removed_commands+=("$f")
done
for f in "${LOOPER_AGENTS[@]}"; do
    [ -f "$GLOBAL_DIR/agents/$f" ] && rm -f "$GLOBAL_DIR/agents/$f" && removed_agents+=("$f")
done
for hp in "$GLOBAL_DIR/hooks/looper-session-hook.ps1" "$GLOBAL_DIR/looper-session-hook.ps1"; do
    [ -f "$hp" ] && rm -f "$hp" && removed_hooks+=("$hp")
done
removed_version=false
[ -f "$GLOBAL_DIR/looper-version" ] && rm -f "$GLOBAL_DIR/looper-version" && removed_version=true

# Remove looper Stop hook entries from global settings.json (requires jq)
removed_stop_entries=0
GLOBAL_SETTINGS="$GLOBAL_DIR/settings.json"
if [ -f "$GLOBAL_SETTINGS" ] && command -v jq &>/dev/null; then
    before=$(jq '.hooks.Stop // [] | length' "$GLOBAL_SETTINGS")
    tmp=$(mktemp)
    jq 'if .hooks.Stop then .hooks.Stop = [.hooks.Stop[] | select(.hooks | map(.command) | any(contains("looper-session-hook")) | not)] else . end' \
        "$GLOBAL_SETTINGS" > "$tmp" && mv "$tmp" "$GLOBAL_SETTINGS"
    after=$(jq '.hooks.Stop // [] | length' "$GLOBAL_SETTINGS")
    removed_stop_entries=$((before - after))
fi
echo "Global Claude user cleanup complete."
```

### Step 1: Detect the workspace `.claude/` directory

The workspace root is the primary working directory (the folder containing `looper-code/`). The install target is the `.claude/` folder inside it:

- **Mac / Linux**: `<primary-working-dir>/.claude/`
- **Windows**: `<primary-working-dir>\.claude\` (use forward slashes in bash: `<primary-working-dir>/.claude/`)

### Step 2: Locate the looper-code source directory

The source files are in the `looper-code/` folder at the workspace root (the primary working directory):
```
<primary-working-dir>/looper-code/commands/
<primary-working-dir>/looper-code/agents/
<primary-working-dir>/looper-code/hooks/
```

The primary working directory is provided by the shell environment — use it directly as the workspace root. Do not use `git rev-parse` or search parent directories.

### Step 3: Create target directories if they don't exist

```bash
mkdir -p "<primary-working-dir>/.claude/commands"
mkdir -p "<primary-working-dir>/.claude/agents"
mkdir -p "<primary-working-dir>/.claude/hooks"
```

On Windows in Git Bash or WSL, use forward slashes. On native Windows PowerShell use backslashes and the full path.

### Step 4: Copy commands, agents, and hooks

```bash
LOOPER_SRC="<primary-working-dir>/looper-code"   # replace <primary-working-dir> with the actual path from your shell environment
WORKSPACE_DIR="<primary-working-dir>/.claude"    # workspace-level .claude folder

# Copy commands
cp "$LOOPER_SRC/commands/looper-plan.md"       "$WORKSPACE_DIR/commands/looper-plan.md"
cp "$LOOPER_SRC/commands/looper-implement.md"  "$WORKSPACE_DIR/commands/looper-implement.md"
cp "$LOOPER_SRC/commands/generate-tasks.md"    "$WORKSPACE_DIR/commands/generate-tasks.md"
cp "$LOOPER_SRC/commands/looper-initialize.md" "$WORKSPACE_DIR/commands/looper-initialize.md"
cp "$LOOPER_SRC/commands/looper-setup.md"    "$WORKSPACE_DIR/commands/looper-setup.md"

# Copy agents
cp "$LOOPER_SRC/agents/codebase-analyzer.md"       "$WORKSPACE_DIR/agents/codebase-analyzer.md"
cp "$LOOPER_SRC/agents/codebase-locator.md"        "$WORKSPACE_DIR/agents/codebase-locator.md"
cp "$LOOPER_SRC/agents/codebase-pattern-finder.md" "$WORKSPACE_DIR/agents/codebase-pattern-finder.md"
cp "$LOOPER_SRC/agents/thoughts-analyzer.md"       "$WORKSPACE_DIR/agents/thoughts-analyzer.md"
cp "$LOOPER_SRC/agents/thoughts-locator.md"        "$WORKSPACE_DIR/agents/thoughts-locator.md"
cp "$LOOPER_SRC/agents/web-search-researcher.md"   "$WORKSPACE_DIR/agents/web-search-researcher.md"
cp "$LOOPER_SRC/agents/jira-repit-updater.md"      "$WORKSPACE_DIR/agents/jira-repit-updater.md"

# Copy hook
cp "$LOOPER_SRC/hooks/looper-session-hook.ps1" "$WORKSPACE_DIR/hooks/looper-session-hook.ps1"

# Fix relative links that only resolve correctly from looper-code/commands/, not from
# the copied location .claude/commands/ (one directory level further from looper-code/artifacts/).
# Without this, every copied command's banner link (and looper-plan.md's RePIT-TEMPLATE.md link)
# silently breaks each time this copy step runs.
# bash/Git Bash:
for f in "$WORKSPACE_DIR/commands/looper-plan.md" "$WORKSPACE_DIR/commands/looper-implement.md" \
         "$WORKSPACE_DIR/commands/looper-initialize.md" "$WORKSPACE_DIR/commands/looper-setup.md"; do
    sed -i 's#(\.\./artifacts/#(../../looper-code/artifacts/#g' "$f"
done
# native PowerShell (no sed) — equivalent fix:
#   foreach ($f in @("looper-plan.md","looper-implement.md","looper-initialize.md","looper-setup.md")) {
#       $p = "$WORKSPACE_DIR\commands\$f"
#       (Get-Content $p -Raw) -replace '\(\.\./artifacts/', '(../../looper-code/artifacts/' | Set-Content $p -NoNewline
#   }

# Write the installed version
echo "$SOURCE_VERSION" > "$WORKSPACE_DIR/looper-version"
```

### Step 5: Register the Stop hook in workspace settings.json

This step wires the copied hook script into the workspace `.claude/settings.json` so it fires for all Claude Code sessions inside the workspace. It is idempotent — re-running `/looper-initialize` will not create duplicate entries.

**Windows (PowerShell):**

```powershell
$workspaceDir = "<primary-working-dir>"   # replace with the actual workspace root path
$settingsPath = "$workspaceDir\.claude\settings.json"
$hookCommand  = "powershell -NonInteractive -File `"$workspaceDir\.claude\hooks\looper-session-hook.ps1`""

# Load or initialise
$settings = if (Test-Path $settingsPath) {
    Get-Content $settingsPath -Raw | ConvertFrom-Json
} else { [PSCustomObject]@{} }

# Ensure hooks → Stop path exists
if (-not ($settings.PSObject.Properties['hooks'])) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{})
}
if (-not ($settings.hooks.PSObject.Properties['Stop'])) {
    $settings.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @()
}

# Idempotent: skip if already registered
$already = $settings.hooks.Stop | Where-Object {
    $_.hooks | Where-Object { $_.command -like "*looper-session-hook*" }
}
if (-not $already) {
    $entry = [PSCustomObject]@{
        matcher = ""
        hooks   = @([PSCustomObject]@{ type = "command"; command = $hookCommand })
    }
    $settings.hooks.Stop += $entry
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "Stop hook registered in settings.json"
} else {
    Write-Host "Stop hook already registered — skipped"
}
```

**Mac / Linux:** The hook script is PowerShell (`.ps1`). Skip automatic registration and output:
```
Hook registration skipped — looper-session-hook.ps1 requires PowerShell (pwsh).
Install pwsh and add the hook to ~/.claude/settings.json manually.
```

### Step 6: Add git permissions to workspace settings.json

Configures `permissions.allow`, `permissions.deny`, and `permissions.ask` for git commands in the workspace `.claude/settings.json`. Idempotent — re-running `/looper-initialize` will not create duplicate entries.

**Windows (PowerShell):**

```powershell
$workspaceDir = "<primary-working-dir>"   # replace with the actual workspace root path
$settingsPath = "$workspaceDir\.claude\settings.json"

$settings = if (Test-Path $settingsPath) {
    Get-Content $settingsPath -Raw | ConvertFrom-Json
} else { [PSCustomObject]@{} }

if (-not ($settings.PSObject.Properties['permissions'])) {
    $settings | Add-Member -NotePropertyName permissions -NotePropertyValue ([PSCustomObject]@{})
}

function Add-PermRule($obj, $key, $rule) {
    if (-not ($obj.PSObject.Properties[$key])) {
        $obj | Add-Member -NotePropertyName $key -NotePropertyValue @()
    }
    if ($obj.$key -notcontains $rule) {
        $obj.$key += $rule
        Write-Host "Added $key`: $rule"
    }
}

Add-PermRule $settings.permissions 'allow' "Bash(git *)"
Add-PermRule $settings.permissions 'allow' "Bash(cd * && git *)"
Add-PermRule $settings.permissions 'allow' "Bash(git log*)"
Add-PermRule $settings.permissions 'allow' "Bash(git diff*)"
Add-PermRule $settings.permissions 'allow' "Bash(git show*)"
Add-PermRule $settings.permissions 'allow' "Bash(git blame*)"
Add-PermRule $settings.permissions 'allow' "Bash(git status*)"
Add-PermRule $settings.permissions 'allow' "Bash(ls*)"
Add-PermRule $settings.permissions 'allow' "Bash(cd *)"

foreach ($rule in @(
    "Bash(git push --force*)",
    "Bash(git push -f *)",
    "Bash(git push -f)",
    "Bash(git push --force-with-lease*)",
    "Bash(git push --mirror*)",
    "Bash(git push --delete*)",
    "Bash(git push origin --delete*)",
    "Bash(git push origin :*)",
    "Bash(git reset --hard*)",
    "Bash(git clean -f*)",
    "Bash(git branch -D*)",
    "Bash(git config --global*)"
)) { Add-PermRule $settings.permissions 'deny' $rule }

foreach ($rule in @(
    "Bash(git rebase*)",
    "Bash(git branch -d *)",
    "Bash(git remote remove*)",
    "Bash(git remote rm*)",
    "Bash(git stash drop*)",
    "Bash(git stash clear*)",
    "Bash(git tag -d*)"
)) { Add-PermRule $settings.permissions 'ask' $rule }

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "Git permissions written to settings.json"
```

**Mac / Linux (bash, requires jq):**

```bash
SETTINGS_PATH="<primary-working-dir>/.claude/settings.json"

[ -f "$SETTINGS_PATH" ] || echo '{"permissions":{"allow":[],"deny":[],"ask":[]}}' > "$SETTINGS_PATH"

add_rule() {
    local key="$1" rule="$2"
    if jq -e --arg r "$rule" ".permissions.$key | index(\$r)" "$SETTINGS_PATH" > /dev/null 2>&1; then
        echo "Already present ($key): $rule — skipped"
    else
        tmp=$(mktemp)
        jq --arg r "$rule" ".permissions.$key += [\$r]" "$SETTINGS_PATH" > "$tmp" && mv "$tmp" "$SETTINGS_PATH"
        echo "Added $key: $rule"
    fi
}

add_rule allow "Bash(git *)"
add_rule allow "Bash(cd * && git *)"
add_rule allow "Bash(git log*)"
add_rule allow "Bash(git diff*)"
add_rule allow "Bash(git show*)"
add_rule allow "Bash(git blame*)"
add_rule allow "Bash(git status*)"
add_rule allow "Bash(ls*)"
add_rule allow "Bash(cd *)"

for rule in \
    "Bash(git push --force*)" "Bash(git push -f *)" "Bash(git push -f)" \
    "Bash(git push --force-with-lease*)" "Bash(git push --mirror*)" \
    "Bash(git push --delete*)" "Bash(git push origin --delete*)" "Bash(git push origin :*)" \
    "Bash(git reset --hard*)" "Bash(git clean -f*)" \
    "Bash(git branch -D*)" "Bash(git config --global*)"; do
    add_rule deny "$rule"
done

for rule in \
    "Bash(git rebase*)" "Bash(git branch -d *)" \
    "Bash(git remote remove*)" "Bash(git remote rm*)" \
    "Bash(git stash drop*)" "Bash(git stash clear*)" "Bash(git tag -d*)"; do
    add_rule ask "$rule"
done
```

### Step 7: Add PowerShell permissions to workspace settings.json

Configures `permissions.allow`, `permissions.deny`, and `permissions.ask` for PowerShell commands in the workspace `.claude/settings.json`. Idempotent — re-running `/looper-initialize` will not create duplicate entries.

> **Note on prefix matching**: deny/ask rules only fire for scripts that START with the bare cmdlet name (e.g. `Remove-Item foo`). Scripts starting with variable assignments (`$x = Remove-Item ...`) match `PowerShell(*)` (allow) — this is intentional; complex agent scripts need the broad allow.

**Windows (PowerShell):**

```powershell
$workspaceDir = "<primary-working-dir>"   # replace with the actual workspace root path
$settingsPath = "$workspaceDir\.claude\settings.json"

$settings = if (Test-Path $settingsPath) {
    Get-Content $settingsPath -Raw | ConvertFrom-Json
} else { [PSCustomObject]@{} }

if (-not ($settings.PSObject.Properties['permissions'])) {
    $settings | Add-Member -NotePropertyName permissions -NotePropertyValue ([PSCustomObject]@{})
}

function Add-PermRule($obj, $key, $rule) {
    if (-not ($obj.PSObject.Properties[$key])) {
        $obj | Add-Member -NotePropertyName $key -NotePropertyValue @()
    }
    if ($obj.$key -notcontains $rule) {
        $obj.$key += $rule
        Write-Host "Added $key`: $rule"
    }
}

Add-PermRule $settings.permissions 'allow' "PowerShell(*)"

foreach ($rule in @(
    "PowerShell(Remove-Item*)",
    "PowerShell(Stop-Process*)",
    "PowerShell(kill *)",
    "PowerShell(Invoke-Expression*)",
    "PowerShell(iex *)",
    "PowerShell(Set-ExecutionPolicy*)",
    "PowerShell(Format-Volume*)",
    "PowerShell(Clear-Disk*)",
    "PowerShell(Initialize-Disk*)",
    "PowerShell(Remove-Partition*)",
    "PowerShell(Uninstall-Package*)",
    "PowerShell(Uninstall-Module*)"
)) { Add-PermRule $settings.permissions 'deny' $rule }

foreach ($rule in @(
    "PowerShell(Start-Process*)",
    "PowerShell(New-Item*)",
    "PowerShell(Set-Content*)",
    "PowerShell(Out-File*)",
    "PowerShell(Add-Content*)",
    "PowerShell(Move-Item*)",
    "PowerShell(Rename-Item*)",
    "PowerShell(Copy-Item*)",
    "PowerShell(Install-Package*)",
    "PowerShell(Install-Module*)",
    "PowerShell(Set-ItemProperty*)",
    "PowerShell(Clear-Content*)",
    "PowerShell(Stop-Service*)",
    "PowerShell(Start-Service*)",
    "PowerShell(Register-ScheduledTask*)"
)) { Add-PermRule $settings.permissions 'ask' $rule }

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "PowerShell permissions written to settings.json"
```

**Mac / Linux (bash, requires jq):**

```bash
SETTINGS_PATH="<primary-working-dir>/.claude/settings.json"

[ -f "$SETTINGS_PATH" ] || echo '{"permissions":{"allow":[],"deny":[],"ask":[]}}' > "$SETTINGS_PATH"

add_rule() {
    local key="$1" rule="$2"
    if jq -e --arg r "$rule" ".permissions.$key | index(\$r)" "$SETTINGS_PATH" > /dev/null 2>&1; then
        echo "Already present ($key): $rule — skipped"
    else
        tmp=$(mktemp)
        jq --arg r "$rule" ".permissions.$key += [\$r]" "$SETTINGS_PATH" > "$tmp" && mv "$tmp" "$SETTINGS_PATH"
        echo "Added $key: $rule"
    fi
}

add_rule allow "PowerShell(*)"

for rule in \
    "PowerShell(Remove-Item*)" "PowerShell(Stop-Process*)" "PowerShell(kill *)" \
    "PowerShell(Invoke-Expression*)" "PowerShell(iex *)" "PowerShell(Set-ExecutionPolicy*)" \
    "PowerShell(Format-Volume*)" "PowerShell(Clear-Disk*)" "PowerShell(Initialize-Disk*)" \
    "PowerShell(Remove-Partition*)" "PowerShell(Uninstall-Package*)" "PowerShell(Uninstall-Module*)"; do
    add_rule deny "$rule"
done

for rule in \
    "PowerShell(Start-Process*)" "PowerShell(New-Item*)" \
    "PowerShell(Set-Content*)" "PowerShell(Out-File*)" "PowerShell(Add-Content*)" \
    "PowerShell(Move-Item*)" "PowerShell(Rename-Item*)" "PowerShell(Copy-Item*)" \
    "PowerShell(Install-Package*)" "PowerShell(Install-Module*)" \
    "PowerShell(Set-ItemProperty*)" "PowerShell(Clear-Content*)" \
    "PowerShell(Stop-Service*)" "PowerShell(Start-Service*)" \
    "PowerShell(Register-ScheduledTask*)"; do
    add_rule ask "$rule"
done
```

### Step 8: Confirm success

After copying, report the version status and list the installed files:

- If `INSTALLED_VERSION` was `none`, report a fresh install:
  ```
  ✅ Looper Code v{SOURCE_VERSION} installed (fresh install).
  ```
- If `INSTALLED_VERSION` equals `SOURCE_VERSION`, report no change:
  ```
  ✅ Looper Code v{SOURCE_VERSION} already up to date — files refreshed.
  ```
- If `INSTALLED_VERSION` differs from `SOURCE_VERSION`, report an upgrade:
  ```
  ✅ Looper Code upgraded: v{INSTALLED_VERSION} → v{SOURCE_VERSION}
  ```

Then list the installed files, and reflect the actual hook registration outcome:

```
Commands installed to <workspace_root>/.claude/commands/:
  - looper-plan.md
  - looper-implement.md
  - looper-initialize.md
  - looper-setup.md
  - generate-tasks.md

Agents installed to <workspace_root>/.claude/agents/:
  - codebase-analyzer.md
  - codebase-locator.md
  - codebase-pattern-finder.md
  - thoughts-analyzer.md
  - thoughts-locator.md
  - web-search-researcher.md
  - jira-repit-updater.md

Hook installed to <workspace_root>/.claude/hooks/:
  - looper-session-hook.ps1

Stop hook: <outcome>   ← replace with one of:
  ✅ Registered in <workspace_root>/.claude/settings.json
  ⏭️  Already registered — skipped
  ⚠️  Skipped — requires PowerShell (pwsh) on Mac/Linux

Git permissions (Step 6):
  allow — Bash(git *):          ✅ Added  /  ⏭️  Already present
  allow — Bash(cd * && git *):  ✅ Added  /  ⏭️  Already present
  allow — Bash(ls*):            ✅ Added  /  ⏭️  Already present
  allow — Bash(cd *):           ✅ Added  /  ⏭️  Already present
  deny  — 12 rules:             ✅ Written (force push, hard reset, clean, etc.)
  ask   — 7 rules:              ✅ Written (rebase, branch -d, stash drop, etc.)

PowerShell permissions (Step 7):
  allow — PowerShell(*): ✅ Added  /  ⏭️  Already present
  deny  — 12 rules:      ✅ Written (Remove-Item, Stop-Process, Invoke-Expression, etc.)
  ask   — 15 rules:      ✅ Written (New-Item, Set-Content, Start-Process, etc.)

Version file written to <workspace_root>/.claude/looper-version

Global Claude user cleanup (Step 0.5):
  Commands removed: <list or "none found">
  Agents removed:   <list or "none found">
  Hooks removed:    <path(s) or "none found">
  Version file:     <"removed" or "none found">
  Stop hook entries removed from global settings.json: <N> (including embedded workspace paths)
```

Restart Claude Code if it was already running to pick up the new commands.

## Notes

- On **Windows with PowerShell** (not bash), use backslash paths.
- On **macOS / Linux**, `~/.claude/` is the standard global path.
- Running `/looper-initialize` again will overwrite existing workspace files with the latest versions — safe to re-run after updates.
- Commands and agents are scoped to the workspace and its subfolders. They are **not** available in unrelated projects outside the workspace.
- The `repits/` output directory is project-specific and is **not** copied — RePITs live in the task workspace.
