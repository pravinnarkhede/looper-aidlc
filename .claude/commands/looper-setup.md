# Rule: Interactive Setup for Looper-Code

## Banner

Before doing anything else, read and output the banner from [artifacts/looper-code-banner.md](../artifacts/looper-code-banner.md).

## Goal

Guide a first-time user through the complete looper-code workspace setup interactively:
check prerequisites, configure Jira credentials, bootstrap the workspace, and verify the
installation. Runs inside Claude Code after the user has cloned looper-code and opened
VS Code at the workspace root.

Supports **Windows**, **macOS**, and **Linux**.

## Process

### Step 0: Display welcome header

Output:
```
=== Looper Setup ===
Checking prerequisites and configuring your workspace...
```

---

### Step 1: Verify workspace structure

Check that a `looper-code/` directory exists inside the primary working directory.

**Windows (PowerShell):**
```powershell
Test-Path "<primary-working-dir>\looper-code"
```

**Mac / Linux (bash):**
```bash
[ -d "<primary-working-dir>/looper-code" ] && echo "found" || echo "missing"
```

- **Found** → continue to Step 2.
- **Missing** → stop and output:
  ```
  ❌ looper-code/ not found in this workspace.

  Please complete these steps first (see SETUP.md):
    6. Create a workspace root folder
    7. Clone looper-code into it: git clone <repo-url> looper-code
    8. Open VS Code at the workspace root: code .

  Then run /looper-setup again.
  ```

---

### Step 2: Check prerequisites

#### Git

Run:
```bash
git --version
```

- **Success** → store the version string, continue.
- **Failure** → output a warning and continue (Git Bash may still be available for specific commands):
  ```
  ⚠️  git not found on PATH. Some bootstrap steps may require Git Bash.
     Install from https://git-scm.com/downloads if you haven't already.
  ```

#### VS Code

Run:
```bash
code --version
```

- **Success** → store the version string, continue.
- **Failure** → output a warning and continue:
  ```
  ⚠️  VS Code (code) not found on PATH. Install from https://code.visualstudio.com
     and ensure the 'code' command is added to PATH during installation.
  ```

Output a prerequisites summary:
```
Prerequisites:
  git:     <version or "not found ⚠️">
  VS Code: <version or "not found ⚠️">
```

---

### Step 3: Jira REST Setup — collect and persist credentials

This step persists three credentials used by the `jira-repit-updater` agent's REST
path: `JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_DOMAIN`. It detects what is already
persisted at **User scope** (registry hive on Windows, rc-file on Mac/Linux) — not
just the current process — prompts only for what is missing, writes via real tool
calls (not echoed text), and verifies the writes before continuing.

#### Step 3.1 — Detect persisted credentials at User scope

⚠️ **Use the PowerShell / Bash tool to RUN this block.** Do NOT echo it as
documentation. Capture the printed booleans into your reasoning so you can pick a
branch in Step 3.2.

**Windows (PowerShell):**
```powershell
$emailPersisted  = [System.Environment]::GetEnvironmentVariable("JIRA_EMAIL",     "User")
$tokenPersisted  = [System.Environment]::GetEnvironmentVariable("JIRA_API_TOKEN", "User")
$domainPersisted = [System.Environment]::GetEnvironmentVariable("JIRA_DOMAIN",    "User")

"JIRA_EMAIL     persisted=$([bool]$emailPersisted)  session=$([bool]$env:JIRA_EMAIL)"
"JIRA_API_TOKEN persisted=$([bool]$tokenPersisted)  session=$([bool]$env:JIRA_API_TOKEN)"
"JIRA_DOMAIN    persisted=$([bool]$domainPersisted) session=$([bool]$env:JIRA_DOMAIN)"
```

**Mac / Linux (bash):**
```bash
rc="$HOME/.zshrc"; [ -f "$rc" ] || rc="$HOME/.bashrc"

ep=$(grep -E '^export JIRA_EMAIL='     "$rc" 2>/dev/null | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')
tp=$(grep -E '^export JIRA_API_TOKEN=' "$rc" 2>/dev/null | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')
dp=$(grep -E '^export JIRA_DOMAIN='    "$rc" 2>/dev/null | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')

echo "JIRA_EMAIL     persisted=${ep:+yes}  session=${JIRA_EMAIL:+yes}"
echo "JIRA_API_TOKEN persisted=${tp:+yes}  session=${JIRA_API_TOKEN:+yes}"
echo "JIRA_DOMAIN    persisted=${dp:+yes}  session=${JIRA_DOMAIN:+yes}"
```

#### Step 3.2 — Pick the branch

Based on Step 3.1's output, take **exactly one** branch:

- **Branch A — All three are persisted** → output the "already configured" block
  below and continue to **Step 3.5 (validation)** — even already-persisted creds
  must be live-checked against the Jira REST API in case the token has expired
  since last setup. No re-persistence needed.

- **Branch B — Process scope has values, but persisted scope is empty for one or
  more** → Adopt the session values directly. **Do NOT re-prompt the user.** Jump
  to Step 3.4 with `$email` / `$token` / `$domain` populated from `$env:JIRA_*` (or
  `$JIRA_*` on bash).

- **Branch C — One or more is missing from BOTH scopes** → Run **Step 3.2.5** first
  (the optional opt-out gate). If the user opts in, continue to Step 3.3 to prompt
  for the variables missing from both scopes. Variables that have a session value
  but no persisted value MUST be carried forward (not re-prompted) and persisted
  alongside the newly-collected ones. If the user opts out, skip the rest of
  Step 3 (3.3 / 3.4 / 3.5 / 3.6) and continue to Step 4.

##### Branch A output

```
Jira credentials:
  JIRA_EMAIL:      <value of JIRA_EMAIL>   ✅ persisted
  JIRA_API_TOKEN:  ••••••••                ✅ persisted
  JIRA_DOMAIN:     <value of JIRA_DOMAIN>  ✅ persisted

Jira already configured — skipping credential setup.
```

Then continue to **Step 3.5 (validation)**.

#### Step 3.2.5 — Optional opt-out gate (Branch C only)

Before prompting for any credentials, give the user an explicit chance to skip
Jira REST setup. **Jira REST is OPTIONAL.** The Atlassian MCP connector (Step 4)
covers the common Jira read/write paths via OAuth; Jira REST credentials are
required only when `jira-repit-updater` falls back to direct REST (e.g. on
machines / sessions where the MCP is unavailable, or when the agent explicitly
prefers REST). A user who only uses the MCP can safely skip this step.

Ask in the conversation:

```
Jira REST credentials are not configured.

Jira REST is OPTIONAL — it powers the REST fallback path of jira-repit-updater.
The Atlassian MCP connector (configured in the next step) covers most Jira
read/write needs on its own. Skip this if you are unsure.

Set up Jira REST credentials now? (y/n)
```

Wait for the user's reply.

- **`y` / `yes` (case-insensitive)** → Set `JIRA_REST_SKIPPED = false` and continue
  to Step 3.3. Variables already present in session scope (carried over from
  Branch B-style adoption) are kept; only variables missing from both scopes are
  prompted for in 3.3.

- **`n` / `no` / anything else** → Output:
  ```
  ⏭️  Skipping Jira REST setup (optional).
     jira-repit-updater's REST fallback will not be available this run.
     You can configure it later by re-running /looper-setup.
  ```
  Set `JIRA_REST_SKIPPED = true`, **skip Steps 3.3, 3.4, 3.5, and 3.6**, and
  continue directly to **Step 4 (JIRA MCP setup)**.

For all other branches (A and B), set `JIRA_REST_SKIPPED = false` implicitly —
they never reach this gate.

#### Step 3.3 — Prompt for missing values (Branch C only)

For each variable that is missing from **both** scopes, prompt the user in the
conversation and wait for their reply. Variables that already have a session
value MUST NOT be re-prompted.

- **JIRA_EMAIL** (if missing from both scopes):
  ```
  Your Jira email address is not set.
  Please enter the email you use to log in to Jira (e.g. you@yourco.com):
  ```
  Wait for the user's reply and store the value as `$email`.

- **JIRA_API_TOKEN** (if missing from both scopes):
  ```
  Your Jira API token is not set.

  To create one:
    1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
    2. Click "Create API token", give it a label (e.g. claude-jira-agent), click Create.
    3. Copy the token immediately — it is only shown once.

  Please paste your Jira API token:
  ```
  Wait for the user's reply and store the value as `$token`.

- **JIRA_DOMAIN** (if missing from both scopes):
  ```
  Your Jira domain is not set.
  Please enter your Atlassian domain (format: yourco.atlassian.net):
  ```
  Wait for the user's reply and store the value as `$domain`.

#### Step 3.4 — Persist credentials, propagate to current session, AND verify (single tool invocation)

⚠️ **CRITICAL — This is not documentation. You MUST execute the block below
exactly once as a single PowerShell (or Bash) tool invocation.** PowerShell tool
calls run in fresh processes — splitting persist and verify into separate calls
would lose the `$email` / `$token` / `$domain` variables between them.

Before invoking the tool, **edit the first three lines** to substitute the actual
values you collected (from Branch B's session adoption or Branch C's prompts).

**Windows (PowerShell):**
```powershell
# >>> SUBSTITUTE ACTUAL VALUES INTO THESE THREE LINES BEFORE INVOKING <<<
$email  = "<actual email>"
$token  = "<actual token>"
$domain = "<actual domain>"

# 1. Persist to the User-scope registry hive (survives restarts).
[System.Environment]::SetEnvironmentVariable("JIRA_EMAIL",     $email,  "User")
[System.Environment]::SetEnvironmentVariable("JIRA_API_TOKEN", $token,  "User")
[System.Environment]::SetEnvironmentVariable("JIRA_DOMAIN",    $domain, "User")

# 2. Seed the CURRENT process env so this Claude/VS Code session sees the values
#    immediately. SetEnvironmentVariable("User") does NOT propagate to the running
#    process — without this, downstream agents read empty strings until restart.
$env:JIRA_EMAIL     = $email
$env:JIRA_API_TOKEN = $token
$env:JIRA_DOMAIN    = $domain

# 3. Read-back verification — compare what we wrote against what is now persisted.
$verifyEmail  = [System.Environment]::GetEnvironmentVariable("JIRA_EMAIL",     "User")
$verifyToken  = [System.Environment]::GetEnvironmentVariable("JIRA_API_TOKEN", "User")
$verifyDomain = [System.Environment]::GetEnvironmentVariable("JIRA_DOMAIN",    "User")

$okEmail  = ($verifyEmail  -eq $email)  -and ($env:JIRA_EMAIL     -eq $email)
$okToken  = ($verifyToken  -eq $token)  -and ($env:JIRA_API_TOKEN -eq $token)
$okDomain = ($verifyDomain -eq $domain) -and ($env:JIRA_DOMAIN    -eq $domain)

"JIRA_EMAIL:     $(if($okEmail){'✅ persisted   ✅ session'} else{'❌ persistence FAILED'})"
"JIRA_API_TOKEN: $(if($okToken){'✅ persisted   ✅ session'} else{'❌ persistence FAILED'})"
"JIRA_DOMAIN:    $(if($okDomain){'✅ persisted   ✅ session'} else{'❌ persistence FAILED'})"

if (-not ($okEmail -and $okToken -and $okDomain)) {
    throw "REST credential persistence failed — do not proceed to Step 4. Re-run /looper-setup or set the variables manually."
}
```

**Mac / Linux (bash):** One invocation that appends to the rc file, exports for
the current shell, and verifies.
```bash
# >>> SUBSTITUTE ACTUAL VALUES INTO THESE THREE LINES BEFORE INVOKING <<<
email="<actual email>"
token="<actual token>"
domain="<actual domain>"

rc="$HOME/.zshrc"; [ -f "$rc" ] || rc="$HOME/.bashrc"

# 1. Idempotent append (no duplicates on re-run; replaces any existing line).
sed -i.bak -E '/^export JIRA_EMAIL=/d;/^export JIRA_API_TOKEN=/d;/^export JIRA_DOMAIN=/d' "$rc"
printf 'export JIRA_EMAIL="%s"\n'     "$email"  >> "$rc"
printf 'export JIRA_API_TOKEN="%s"\n' "$token"  >> "$rc"
printf 'export JIRA_DOMAIN="%s"\n'    "$domain" >> "$rc"

# 2. Seed the current shell.
export JIRA_EMAIL="$email"
export JIRA_API_TOKEN="$token"
export JIRA_DOMAIN="$domain"

# 3. Read-back verification (from the rc file we just wrote).
ve=$(grep -E '^export JIRA_EMAIL='     "$rc" | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')
vt=$(grep -E '^export JIRA_API_TOKEN=' "$rc" | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')
vd=$(grep -E '^export JIRA_DOMAIN='    "$rc" | tail -n1 | sed -E 's/^[^=]+="?([^"]*)"?.*/\1/')

ok=1
if [ "$ve" = "$email" ]  && [ "$JIRA_EMAIL"     = "$email"  ]; then echo "JIRA_EMAIL:     ✅ persisted   ✅ session"; else echo "JIRA_EMAIL:     ❌ persistence FAILED";     ok=0; fi
if [ "$vt" = "$token" ]  && [ "$JIRA_API_TOKEN" = "$token"  ]; then echo "JIRA_API_TOKEN: ✅ persisted   ✅ session"; else echo "JIRA_API_TOKEN: ❌ persistence FAILED";     ok=0; fi
if [ "$vd" = "$domain" ] && [ "$JIRA_DOMAIN"    = "$domain" ]; then echo "JIRA_DOMAIN:    ✅ persisted   ✅ session"; else echo "JIRA_DOMAIN:    ❌ persistence FAILED";     ok=0; fi

if [ "$ok" -ne 1 ]; then
    echo "REST credential persistence failed — do not proceed to Step 4. Re-run /looper-setup or set the variables manually."
    exit 1
fi
```

#### Step 3.5 — Validate REST credentials against the Jira API

⚠️ **You MUST execute this block via the PowerShell or Bash tool.** This step
makes a single authenticated `GET https://$JIRA_DOMAIN/rest/api/3/myself` call to
prove the credentials actually work — not just that they were stored. Without
this, bad credentials (wrong domain, expired token, typo'd email) would persist
silently and `/looper-plan` would fail later with confusing errors.

This step runs **regardless of which Branch fired in Step 3.2** — Branch A's
"already persisted" state can still have expired or wrong-account credentials.

**Exception:** Skip this entire step if `JIRA_REST_SKIPPED = true` (set by the
Step 3.2.5 opt-out gate). There are no credentials to validate, and Step 3.6
will print the corresponding skip line.

**Windows (PowerShell):**
```powershell
$pair  = "$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"
$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$uri   = "https://$($env:JIRA_DOMAIN)/rest/api/3/myself"

try {
    $r    = Invoke-WebRequest -Uri $uri -Headers @{ Authorization = "Basic $basic"; Accept = "application/json" } -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $body = $r.Content | ConvertFrom-Json
    "JIRA REST validation: ✅ authenticated as $($body.emailAddress) ($($body.displayName))"
    "  Endpoint:  $uri"
    if ($body.emailAddress -and ($body.emailAddress -ne $env:JIRA_EMAIL)) {
        "  ⚠️ JIRA_EMAIL=$($env:JIRA_EMAIL) but token belongs to $($body.emailAddress) — possible account mix-up; continuing anyway."
    }
} catch {
    $status = $null
    if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
    switch ($status) {
        401 {
            "JIRA REST validation: ❌ 401 Unauthorized — JIRA_API_TOKEN is invalid for JIRA_EMAIL=$($env:JIRA_EMAIL)."
            "  Fix: regenerate the token at https://id.atlassian.com/manage-profile/security/api-tokens and re-run /looper-setup."
            throw "REST credential validation failed (401)"
        }
        403 {
            "JIRA REST validation: ❌ 403 Forbidden — account lacks Jira access on $($env:JIRA_DOMAIN)."
            throw "REST credential validation failed (403)"
        }
        404 {
            "JIRA REST validation: ❌ 404 Not Found — JIRA_DOMAIN=$($env:JIRA_DOMAIN) is wrong or not a Jira Cloud site."
            "  Fix: ensure JIRA_DOMAIN is your Atlassian Cloud host (format: yourco.atlassian.net), then re-run /looper-setup."
            throw "REST credential validation failed (404)"
        }
        default {
            if ($null -eq $status) {
                # Network error / timeout / DNS — non-fatal warning so setup proceeds with persisted creds.
                "JIRA REST validation: ⚠️ could not reach $uri — $($_.Exception.Message)."
                "  Skipping validation. If Jira is reachable later, /looper-plan will surface real auth errors."
            } else {
                "JIRA REST validation: ❌ HTTP $status from $uri — $($_.Exception.Message)"
                throw "REST credential validation failed ($status)"
            }
        }
    }
}
```

**Mac / Linux (bash):**
```bash
status=$(curl -s -o /tmp/jira-myself.json -w "%{http_code}" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  --max-time 15 \
  "https://$JIRA_DOMAIN/rest/api/3/myself" 2>/dev/null) || status="000"

case "$status" in
    200)
        rest_email=$(grep -oE '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' /tmp/jira-myself.json | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
        rest_name=$(grep -oE '"displayName"[[:space:]]*:[[:space:]]*"[^"]*"'  /tmp/jira-myself.json | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
        echo "JIRA REST validation: ✅ authenticated as $rest_email ($rest_name)"
        echo "  Endpoint:  https://$JIRA_DOMAIN/rest/api/3/myself"
        if [ -n "$rest_email" ] && [ "$rest_email" != "$JIRA_EMAIL" ]; then
            echo "  ⚠️ JIRA_EMAIL=$JIRA_EMAIL but token belongs to $rest_email — possible account mix-up; continuing anyway."
        fi
        ;;
    401)
        echo "JIRA REST validation: ❌ 401 Unauthorized — JIRA_API_TOKEN is invalid for JIRA_EMAIL=$JIRA_EMAIL."
        echo "  Fix: regenerate the token at https://id.atlassian.com/manage-profile/security/api-tokens and re-run /looper-setup."
        rm -f /tmp/jira-myself.json
        exit 1
        ;;
    403)
        echo "JIRA REST validation: ❌ 403 Forbidden — account lacks Jira access on $JIRA_DOMAIN."
        rm -f /tmp/jira-myself.json
        exit 1
        ;;
    404)
        echo "JIRA REST validation: ❌ 404 Not Found — JIRA_DOMAIN=$JIRA_DOMAIN is wrong or not a Jira Cloud site."
        echo "  Fix: ensure JIRA_DOMAIN is your Atlassian Cloud host (format: yourco.atlassian.net), then re-run /looper-setup."
        rm -f /tmp/jira-myself.json
        exit 1
        ;;
    000)
        echo "JIRA REST validation: ⚠️ could not reach https://$JIRA_DOMAIN/rest/api/3/myself (offline / DNS / timeout). Skipping validation."
        echo "  If Jira is reachable later, /looper-plan will surface real auth errors."
        ;;
    *)
        echo "JIRA REST validation: ❌ HTTP $status from https://$JIRA_DOMAIN/rest/api/3/myself."
        rm -f /tmp/jira-myself.json
        exit 1
        ;;
esac

rm -f /tmp/jira-myself.json
```

If validation fails (PowerShell `throw` / bash `exit 1`), **do NOT proceed to
Step 3.6 or Step 4.** Surface the specific status code and remediation hint to
the user, then stop the setup.

#### Step 3.6 — Confirmation

**Skip-case (JIRA_REST_SKIPPED = true):** the Step 3.2.5 opt-out line has already
been printed and there are no credentials to confirm. Do not emit the saved
confirmation block below. Continue to Step 4.

If Step 3.4 verification succeeded (three `✅ persisted   ✅ session` lines, no
throw / exit 1) AND Step 3.5 validation succeeded (or was network-skipped with a
`⚠️` warning), output the saved confirmation:

```
Jira credentials saved:
  JIRA_EMAIL:      <email>   ✅ persisted   ✅ session   ✅ REST validated
  JIRA_API_TOKEN:  ••••••••  ✅ persisted   ✅ session   ✅ REST validated
  JIRA_DOMAIN:     <domain>  ✅ persisted   ✅ session   ✅ REST validated
```

(If 3.5 was network-skipped, change the third column to `⚠ validation skipped`
on each line.)

Then continue to Step 4.

If verification (3.4) or validation (3.5) failed, **do NOT proceed to Step 4.**
Surface the failure verbatim, ask the user to resolve it, and stop the setup.

---

### Step 4: JIRA MCP setup — detect or acknowledge the Atlassian connector

The Atlassian/Jira MCP is a Claude-managed cloud connector. This step first
**probes live whether the connector is enabled and authenticated** (Step 4.1). If
detection succeeds, setup continues silently — no banner, no prompt. If detection
fails for any reason, setup falls through to the manual gate (Step 4.2), which
prints a loud banner and blocks on an explicit `(y/n)` acknowledgement.

#### Step 4.1 — Auto-detect MCP availability (probe before prompting)

⚠️ **Use the ToolSearch and MCP tool invocations directly via tool calls.** Do
NOT echo them as documentation. The outcome of this block decides whether Step
4.2 fires.

1. **Load the schema for the Atlassian "who am I" tool.** Call:
   ```
   ToolSearch(query: "select:mcp__claude_ai_Atlassian__atlassianUserInfo", max_results: 1)
   ```
   - If the result does NOT include a `<function>` block whose `name` is
     `mcp__claude_ai_Atlassian__atlassianUserInfo` → the connector is NOT
     registered for this session. **Go to Step 4.2 (manual gate).**
   - If the result DOES include it → continue to step 2.

2. **Invoke the tool with no arguments.** Call:
   ```
   mcp__claude_ai_Atlassian__atlassianUserInfo()
   ```
   - **Success (returns email / accountId / displayName)** → the connector is
     enabled AND authenticated. Hold these values; do NOT print anything yet —
     the consolidated success banner is emitted in step 4 below so the site
     check can be folded in.

   - **Auth error / 401 / "not connected"** → the connector is registered but
     OAuth is not current. Go to Step 4.2 and prepend this line ABOVE the
     banner: `ℹ️  Connector found but OAuth not completed — re-run Connect.`

   - **Any other error** → treat as "couldn't detect" and go to Step 4.2.

3. **Sanity-check the connected resource matches `$env:JIRA_DOMAIN`.** Only run
   this when step 2 returned success. Call:
   ```
   mcp__claude_ai_Atlassian__getAccessibleAtlassianResources()
   ```
   Capture the result for the banner in step 4 — do NOT print yet.
   - If any returned resource `url` contains the host in `$env:JIRA_DOMAIN` →
     mark as **match** and record the matching URL.
   - If none match → mark as **mismatch** and record the first URL (or
     `<none>` if the list is empty).
   - On error → mark as **skipped**.

4. **Emit the consolidated detection banner.** This banner is MANDATORY when
   auto-detection succeeds — the user must see explicit confirmation so they
   understand why Step 4.2 (the manual gate) was bypassed and can spot a
   wrong-account connect. Do not collapse it to one line.

   ```
   ┌──────────────────────────────────────────────────────────────────────┐
   │                                                                      │
   │   ✅  Atlassian / Jira MCP Connector — AUTO-DETECTED                 │
   │                                                                      │
   │   Authenticated as:  <email>                                         │
   │   Atlassian site:    <matching url | first url + ⚠ mismatch | (skipped)> │
   │                                                                      │
   │   Connector is enabled and ready.                                    │
   │   Skipping the manual gate (Step 4.2). Continuing to Step 5.         │
   │                                                                      │
   └──────────────────────────────────────────────────────────────────────┘
   ```

   If step 3 marked **mismatch**, ALSO emit this warning line directly under
   the banner (do NOT block, do NOT fall through to 4.2):
   ```
   ⚠️ Atlassian MCP is authenticated, but no resource matches JIRA_DOMAIN=<domain> — confirm you connected the right Atlassian account.
   ```

   Then store `MCP_ACKNOWLEDGED = true (auto-detected)` for the Step 6 summary,
   **skip Step 4.2 entirely**, and continue to Step 5.

#### Step 4.2 — Manual gate (auto-detection failed or skipped)

**Only reach this sub-step if Step 4.1 fell through.** If Step 4.1 emitted the
"Connector found but OAuth not completed" hint, output that line ABOVE the
banner before printing the banner itself.

##### Output the banner exactly as shown

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ⚠️  ACTION REQUIRED — Atlassian / Jira MCP Connector               ║
║                                                                      ║
║   Looper relies on the Atlassian MCP for Jira read/write             ║
║   operations. This connector CANNOT be enabled automatically.        ║
║   Please enable it now if you haven't already:                       ║
║                                                                      ║
║     1. Open Claude → Settings → Connectors (or MCP Servers)          ║
║     2. Find "Atlassian" in the list                                  ║
║     3. Click "Connect" and complete the OAuth flow with your Jira    ║
║        account                                                       ║
║     4. Confirm the connector status shows "Connected" (green)        ║
║                                                                      ║
║   Without this connector, /looper-plan and /looper-implement will    ║
║   fail when they try to read or update Jira tickets.                 ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

##### Then prompt and wait for the user's reply

Ask in the conversation:
```
Has the Atlassian / Jira MCP connector been enabled in Claude?

Jira MCP is OPTIONAL — it powers the Atlassian connector path of
jira-repit-updater (fetching tickets, posting comments via OAuth).
If you do not plan to use Jira integration in this session, you can skip.

(y = enabled, ready to continue
 n = skip optional MCP setup for this run
 anything else = re-prompt)
```

##### Handle the reply

- **`y` / `yes` (case-insensitive)** → output `✅ Jira MCP acknowledged — continuing.`
  and proceed to Step 5. Store `MCP_ACKNOWLEDGED = true (acknowledged by user)`
  for the Step 7 summary.

- **`n` / `no` (case-insensitive)** → output:
  ```
  ⏭️  Skipping Jira MCP setup (optional).
     jira-repit-updater's MCP path will not be available this run.
     /looper-plan and /looper-implement will not be able to read or update
     Jira tickets until the connector is enabled. Re-run /looper-setup any
     time to acknowledge it then.
  ```
  Store `JIRA_MCP_SKIPPED = true` for the Step 7 summary and proceed to Step 5.

- **Anything else (ambiguous reply, unrelated message, blank)** → output:
  ```
  Please answer 'y' to confirm the connector is enabled, or 'n' to skip
  the optional MCP setup for this run.
  ```
  Then **re-prompt the same question and wait again**. Loop until the user
  gives an explicit `y` / `n`.

⚠️ **IMPORTANT — do not break the Step 4.2 contract:**

- Do **NOT** proceed to Step 5 on an ambiguous / unrelated reply. Only an explicit
  `y` (acknowledge) or `n` (skip) advances the flow; anything else re-prompts.
- Do **NOT** infer acknowledgement from silence, ambiguity, or unrelated messages.
- Do **NOT** skip this sub-step automatically even if it appears the MCP was set up
  in a previous session — re-acknowledging takes seconds and guarantees the user
  has not since disconnected the connector. The user is still free to type `n` to
  skip; the gate must just BE shown.
- Do **NOT** collapse the banner into a one-line summary. Output it verbatim so
  the user actually sees the click-path before deciding.

---

### Step 5: Bootstrap the workspace

Run the full workspace bootstrap by reading and executing `looper-initialize.md` **directly**.

⚠️ **IMPORTANT — Do NOT use the `looper-initialize` skill or the skill registry.**
You MUST use the Read tool to read the file at the path below, then execute every step
(Step 0 through Step 8) yourself inline. Do not delegate via the Skill tool.

Read the file using the Read tool:
- `<primary-working-dir>/looper-code/commands/looper-initialize.md`

Then execute **all steps** in that file (Step 0 through Step 8) in full, using the same
primary working directory. The output from looper-initialize will appear inline here.

---

### Step 6: Clone the stable reference codebase

#### Step 6.1 — Opt-in gate

The stable reference codebase is **OPTIONAL**. It clones platform repos at their
release branches into `<workspace>/looper-code-artifacts/stable-codebase/` so future
looper tasks can grep/read code without re-cloning. Skip if you don't need
cross-repo reference access this session, are offline, or want to defer the
network-heavy clone. If you opt in, you'll then be asked **which** repos to set up
(all, or a subset) — it is not all-or-nothing.

Ask in the conversation:

```
Set up / refresh the stable reference codebase now?

Optional — clones platform repos at their release branches into
`looper-code-artifacts/stable-codebase/`. If you say yes, you'll choose which
repos to set up (all or a subset). First-time provisioning takes
1–5 minutes (network-bound); a refresh of existing clones takes ~30 seconds.

(y = continue to repo selection, then provision / refresh
 n = skip this run, continue to the final summary
 anything else = re-prompt)
```

- **`y` / `yes` (case-insensitive)** → Store `ARTIFACTS_SETUP = "ran"` for the
  Step 7 summary and continue to **Step 6.2** below.

- **`n` / `no` (case-insensitive)** → Output:
  ```
  ⏭️  Skipping stable reference codebase setup (optional).
     looper-code-artifacts/stable-codebase/ will not be created or refreshed
     this run. Re-run /looper-setup any time to provision or refresh.
  ```
  Store `ARTIFACTS_SETUP = "skipped"` and **skip Step 6.2 entirely**, jumping
  straight to **Step 7 (Final summary)**.

- **Anything else (ambiguous reply, unrelated message, blank)** → Output:
  ```
  Please answer 'y' to provision/refresh, or 'n' to skip the optional codebase setup.
  ```
  Then **re-prompt the same question and wait again**. Loop until the user gives
  an explicit `y` / `n`.

#### Step 6.2 — Provision / refresh (runs only on Step 6.1 = `y`)

Provision the workspace's read-only stable reference clones by reading and executing
`looper-artifacts-setup.md` **directly**.

⚠️ **IMPORTANT — `looper-artifacts-setup` is NOT a registered slash command.** It is
an internal sub-routine that lives only at `looper-code/commands/looper-artifacts-setup.md`
and is not copied into `<workspace>/.claude/commands/` by `/looper-initialize`. You
MUST use the Read tool to read the file at the path below, then execute every step
(Step 0 through Step 5) yourself inline. Do not delegate via the Skill tool.

Read the file using the Read tool:
- `<primary-working-dir>/looper-code/commands/looper-artifacts-setup.md`

Then execute **all steps** in that file (Step 0 through Step 6) in full, using the same
primary working directory as `WORKSPACE_ROOT`. The output (per-repo status lines and
the final summary table) will appear inline here.

Capture the Step 5 summary table — the Step 7 final summary below references it.

If any rows in the summary table are `❌ Failed`, surface the failure to the user with
the captured stderr but do **not** halt setup. Stable codebase failures are
informational at this stage; the user can fix SSH / network and re-run `/looper-setup`
to retry.

---

### Step 7: Final summary

After the bootstrap completes, output:

```
=== Looper Setup Complete ===

Jira credentials (Step 3 — Jira REST):
  <ONE of the following blocks, based on the Step 3 outcome:>

  -- Configured (Branch A / B / C-with-opt-in):
  JIRA_EMAIL:      <email>   ✅
  JIRA_API_TOKEN:  ••••••••  ✅
  JIRA_DOMAIN:     <domain>  ✅

  -- Skipped (Branch C, user declined the optional gate at Step 3.2.5):
  ⏭️  Jira REST: skipped (optional). REST fallback for jira-repit-updater
     unavailable this run. Re-run /looper-setup to add credentials later.

Jira MCP connector (Step 4):
  <ONE of the following lines, based on the Step 4 outcome:>
  ✅  Detected automatically (Step 4.1)
  ✅  Acknowledged by user (Step 4.2)
  ⏭️  Skipped (optional, declined at Step 4.2) — jira-repit-updater MCP path
       unavailable this run. Re-run /looper-setup to acknowledge later.

<looper-initialize summary output from Step 5>

Stable reference codebase (Step 6 — looper-code-artifacts/stable-codebase):
  <ONE of the following blocks, based on Step 6.1's outcome:>

  -- Ran (Step 6.1 = y):
  <Step 5 summary table from looper-artifacts-setup.md — verbatim>

  -- Skipped (Step 6.1 = n):
  ⏭️  Skipped (optional, declined at Step 6.1) — looper-code-artifacts/stable-codebase/
       not created/refreshed this run. Re-run /looper-setup to provision later.

Next steps:
  • Reload VS Code now: Command Palette → Developer: Reload Window
  • After reload, /looper-plan, /looper-implement, and /looper-setup will be
    available in all Claude Code sessions inside this workspace.
  • To start a task, run /looper-plan.
```

---

## Notes

- Run `/looper-setup` again at any time to re-check credentials, refresh the install, AND
  refresh the stable reference codebase (when Step 6.1 is answered `y`, Step 6.2 fetches
  + hard-resets every clone in `looper-code-artifacts/stable-codebase/` to the latest tip
  of its release branch). This is the only supported refresh path — there is no
  standalone `/looper-artifacts-setup` slash command. Step 6.1's opt-in gate also lets
  you re-run `/looper-setup` purely for credential / install changes by answering `n`
  to skip the network-heavy clone.
- Jira env vars set with `SetEnvironmentVariable(..., "User")` take effect in new
  terminal/VS Code windows. The CURRENT Claude Code session also sees them
  immediately because Step 3.4 seeds `$env:JIRA_*` in the running process after
  the registry write. Other already-open VS Code windows or terminals still need
  a reload to pick them up.
- On macOS / Linux, the hook script (`looper-session-hook.ps1`) requires PowerShell (pwsh).
  If pwsh is not installed, hook registration is skipped — see looper-initialize output.
