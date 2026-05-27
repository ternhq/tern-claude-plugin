#!/usr/bin/env bash
# Plan-time nudge for tern git-history.
#
# Injects a loud reminder to consult `tern git-history` while a change is being
# planned, so the model picks up the co-change / in-flight / movement / revert
# context before it locks in which files to edit. Fires on:
#   - UserPromptSubmit, but only when the session is in plan mode, and
#   - PreToolUse for ExitPlanMode (the moment a plan is submitted).
#
# Deliberately NOISY for now: we want to see it trigger and confirm the model
# acts on it. Dial the volume down (or drop UserPromptSubmit) once it's proven.
set -euo pipefail

# Without jq we can't read the event payload or emit safe JSON; no-op rather
# than error, so a missing dependency never wedges the turn.
command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

input="$(cat)"
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty')"
mode="$(printf '%s' "$input" | jq -r '.permission_mode // empty')"

# UserPromptSubmit fires on every prompt; restrict it to plan mode so we only
# nudge while planning. ExitPlanMode is already filtered by the hooks.json
# matcher and always fires at plan submission, so it needs no mode check.
if [ "$event" = "UserPromptSubmit" ] && [ "$mode" != "plan" ]; then
  printf '{}'
  exit 0
fi

ctx="$(
  cat <<'TXT'
Before you finalize which files to edit, consult git history for the context that 
is NOT visible by reading the code at HEAD:

    tern git-history --files <comma-separated paths> --pretty

It deterministically surfaces:
  • moves_together — files outside your surface that change with it; go read them
  • in_flight      — open PRs touching these files now, and their authors' intent
  • movement       — how hot or cold each file is
  • revert_prone   — files where changes have been hard to land

This will prevent you from missing context or coupling in the codebase that's not 
obvious. Update your plan any files that are relevant. 
TXT
)"

jq -n --arg event "$event" --arg ctx "$ctx" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
