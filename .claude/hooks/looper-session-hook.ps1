# looper-session-hook.ps1
# Claude Code Stop hook — auto-logs ad-hoc session costs to the active RePIT's ## Sessions table.
# Silently exits when not in a looper task workspace or when looper-plan/implement already handled logging.

param()

# --- 1. Parse hook payload from stdin ---
try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch { exit 0 }

# Guard: prevent re-entrancy (Stop hook calling itself)
if ($payload.stop_hook_active -eq $true) { exit 0 }

$cwd            = $payload.cwd
$model          = $payload.model
$transcriptPath = $payload.transcript_path

if (-not $cwd) { exit 0 }

# --- 2. Detect looper context: find a RePIT file in cwd ---
$repitFiles = @(Get-ChildItem -Path $cwd -Filter "RePIT-*.md" -File -ErrorAction SilentlyContinue)
if ($repitFiles.Count -eq 0) { exit 0 }
$repitPath = $repitFiles[0].FullName

# --- 3. Skip if this was a looper-plan or looper-implement session (they self-log) ---
if ($transcriptPath -and (Test-Path $transcriptPath)) {
    $transcriptRaw = Get-Content $transcriptPath -Raw -ErrorAction SilentlyContinue
    if ($transcriptRaw -match '"text"\s*:\s*"/looper-plan|"text"\s*:\s*"/looper-implement') { exit 0 }
}

# --- 4. Resolve author and agent version ---
$author = (& git -C $cwd config user.name 2>$null)
if (-not $author) { $author = $env:USERNAME }

$versionPath = Join-Path (Split-Path $cwd -Parent) "looper-code\VERSION"
$agentVersion = if (Test-Path $versionPath) { (Get-Content $versionPath -Raw -ErrorAction SilentlyContinue).Trim() } else { "?" }
$agentLabel   = "looper-code v$agentVersion"

# --- 5. Derive AI model short name ---
$modelShort = switch -Wildcard ($model) {
    "*sonnet-4-6*" { "Sonnet 4.6" }
    "*opus-4-7*"   { "Opus 4.7"   }
    "*haiku-4-5*"  { "Haiku 4.5"  }
    default        { $model        }
}
$aiModel = "Claude Code — $modelShort"

# --- 6. Parse transcript JSONL for token usage ---
$inputTokens = 0; $outputTokens = 0; $cacheReadTokens = 0; $cacheWriteTokens = 0
$tokensFound  = $false

if ($transcriptPath -and (Test-Path $transcriptPath)) {
    Get-Content $transcriptPath -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $obj = $_ | ConvertFrom-Json
            if ($obj.usage) {
                $inputTokens      += [int]($obj.usage.input_tokens              ?? 0)
                $outputTokens     += [int]($obj.usage.output_tokens             ?? 0)
                $cacheReadTokens  += [int]($obj.usage.cache_read_input_tokens   ?? 0)
                $cacheWriteTokens += [int]($obj.usage.cache_creation_input_tokens ?? 0)
                $tokensFound = $true
            }
        } catch {}
    }
}

# --- 7. Format session values ---
$date = Get-Date -Format "yyyy-MM-dd"
$sessionCost = 0

if ($tokensFound) {
    # Anthropic pricing per million tokens — https://www.anthropic.com/pricing
    $pricing = switch -Wildcard ($model) {
        "*opus*"  { @{ Input = 15;   Output = 75; CacheWrite = 18.75; CacheRead = 1.50 } }
        "*haiku*" { @{ Input = 0.80; Output = 4;  CacheWrite = 1.00;  CacheRead = 0.08 } }
        default   { @{ Input = 3;    Output = 15; CacheWrite = 3.75;  CacheRead = 0.30 } }
    }
    $sessionCost  = ($inputTokens / 1e6 * $pricing.Input) + ($outputTokens / 1e6 * $pricing.Output) +
                    ($cacheWriteTokens / 1e6 * $pricing.CacheWrite) + ($cacheReadTokens / 1e6 * $pricing.CacheRead)
    $iFmt  = "~{0:N0}" -f $inputTokens
    $oFmt  = "~{0:N0}" -f $outputTokens
    $crFmt = "~{0:N0}" -f $cacheReadTokens
    $cwFmt = "~{0:N0}" -f $cacheWriteTokens
    $cFmt  = "~`${0:F2}" -f $sessionCost
} else {
    $iFmt = "~"; $oFmt = "~"; $crFmt = "~"; $cwFmt = "~"; $cFmt = "~$"
}

$newSessionRow = "| $date | auto-logged | $aiModel | $iFmt | $oFmt | $crFmt | $cwFmt | $cFmt |"

# --- 8. Update ## Sessions table (line-by-line to stay robust against formatting variations) ---
$lines          = Get-Content $repitPath -Encoding UTF8
$outputLines    = [System.Collections.Generic.List[string]]::new()
$inSessions     = $false
$totalInserted  = $false
$runningCost    = $sessionCost

foreach ($line in $lines) {

    if ($line -match '^## Sessions\s*$') {
        $inSessions = $true
        $outputLines.Add($line)
        continue
    }

    if ($inSessions -and -not $totalInserted) {

        # Accumulate cost from existing data rows
        if ($line -match '^\| \d{4}-\d{2}-\d{2} \|') {
            if ($line -match '~\$([\d.]+)\s*\|?\s*$') {
                $runningCost += [double]$Matches[1]
            }
            $outputLines.Add($line)
            continue
        }

        # Total row — insert new row above it, then emit updated Total
        if ($line -match '\*\*Total\*\*') {
            $outputLines.Add($newSessionRow)
            $totalFmt = "~`${0:F2}" -f $runningCost
            $outputLines.Add("| | | | | | | **Total** | **$totalFmt** |")
            $totalInserted = $true
            continue  # discard the old Total row
        }

        # Blank line or blockquote ends the table zone without a Total row (shouldn't happen with new template)
        if ($line.Trim() -eq '' -or $line -match '^>') {
            $inSessions = $false
        }
    }

    $outputLines.Add($line)
}

# --- 9. Update ## Contributors table ---
$fileText       = $outputLines -join "`n"
$escapedAuthor  = [regex]::Escape($author)
$escapedAgent   = [regex]::Escape($agentLabel)
$escapedModel   = [regex]::Escape($aiModel)
$escapedDate    = [regex]::Escape($date)

$alreadyPresent = $fileText -match "^\| $escapedAuthor \| $escapedAgent \| $escapedModel \| $escapedDate \|"

if (-not $alreadyPresent) {
    $newContribRow = "| $author | $agentLabel | $aiModel | $date |"
    # Append after last data row inside ## Contributors table
    $fileText = $fileText -replace `
        '(?m)(## Contributors\r?\n\r?\n\| Author[^\n]*\n\|[-| ]+\n)((?:\|[^\n]*\n)*)', `
        "`$1`$2$newContribRow`n"
}

# --- 10. Write back ---
[System.IO.File]::WriteAllText($repitPath, $fileText, [System.Text.Encoding]::UTF8)
