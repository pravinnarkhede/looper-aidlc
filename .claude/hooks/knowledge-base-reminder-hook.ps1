# knowledge-base-reminder-hook.ps1
# Claude Code PostToolUse hook — deterministic backstop for CLAUDE.md's
# "MANDATORY: Knowledge Base" rule.
#
# That rule (invoke the knowledge-base-builder agent after every Inception
# stage approval and every Construction unit/Looper phase completion) is
# stated once in a long CLAUDE.md and relies on the model recalling it many
# turns later. This hook fires deterministically instead: whenever
# bridge-config.md or a feature's aidlc-state.md is edited (the two files
# CLAUDE.md already updates at exactly those checkpoints), it feeds a
# reminder back into Claude's context via a PostToolUse block (exit code 2),
# so the trigger doesn't depend purely on prompt recall.
#
# Silently exits (code 0) for any file that isn't one of those two triggers.

param()

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch { exit 0 }

$filePath = $payload.tool_input.file_path
if (-not $filePath) { exit 0 }

$isTrigger = ($filePath -match 'bridge-config\.md$') -or ($filePath -match 'aidlc-state\.md$')
if (-not $isTrigger) { exit 0 }

[Console]::Error.WriteLine(
    "Reminder (per CLAUDE.md 'MANDATORY: Knowledge Base'): '$filePath' was just updated -- " +
    "this is a knowledge-base-builder trigger point. Invoke the knowledge-base-builder agent " +
    "now for the Inception stage / Construction unit / Looper phase that just completed, " +
    "before moving on."
)
exit 2
