# Command: /aidlc

## Goal

A deterministic, explicit entry point into AIDLC — mirroring `/looper-plan`'s role for Looper. AIDLC normally starts automatically the moment you describe a feature in a new chat (see `CLAUDE.md`'s "MANDATORY: Feature Context"), so this command isn't required for AIDLC to work. It exists for the same reason `/looper-plan` exists alongside "just describe the task": a guaranteed, unambiguous way to (re-)trigger Feature Context and Inception, instead of relying on the model picking that up from a plain-English message or from having read the whole of `CLAUDE.md` fresh.

## Usage

```
/aidlc                          → run Feature Context Step 1: scan aidlc-docs\ and present the feature picker
/aidlc CCD-1234                 → resume that feature directly if it exists, otherwise start a new one named CCD-1234
/aidlc add receipt printing     → start a new feature, deriving a kebab-case name from the description (per Feature Context Step 2b)
```

## Steps

1. Load `CLAUDE.md`'s "MANDATORY: Feature Context" section (and, if not already loaded this session, the rest of `CLAUDE.md`).
2. **No argument** → execute Feature Context **Step 1** (scan `aidlc-docs\`, excluding `reverse-engineering\` and `knowledge-base\`) and present the numbered feature picker exactly as specified there. Wait for the user's selection.
3. **Argument matches an existing `aidlc-docs\{name}\` folder** (ticket ID or feature name, case-insensitive) → skip the picker, resume that feature directly using its `aidlc-state.md`, same as if the user had picked it from the list.
4. **Argument doesn't match an existing folder** → treat it as a new feature request and run Feature Context **Step 2b** (ticket-ID detection vs. kebab-case derivation, then the confirm-before-creating prompt).
5. Once the feature is resolved (existing or newly confirmed), continue the normal AIDLC flow from `CLAUDE.md`: Workspace Detection → Reverse Engineering (if applicable) → Requirements Analysis → ... per the Inception Phase section, exactly as if the user had typed their request in plain English.

## Notes

- This command changes *how* AIDLC gets triggered, never *what* it does — every stage, output path, and approval gate is still governed entirely by `CLAUDE.md`. Don't duplicate or reinterpret those rules here.
- Plain-English descriptions and pasted Jira ticket IDs still work exactly as before, with or without this command — `/aidlc` is an alternative on-ramp, not a replacement.
