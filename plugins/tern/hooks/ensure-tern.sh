#!/usr/bin/env bash
# SessionStart and UserPromptSubmit: say once per session that the tern CLI this
# plugin's skills shell out to isn't on this machine yet. UserPromptSubmit is
# the belt to SessionStart's braces — a session resumed or forked into an
# already-running client still gets told before the first prompt does anything.
#
# Right after a `/plugin install` it just sets Tern up, without asking: someone
# who installed the plugin a moment ago has already said what they want, and a
# confirmation there only adds a step. Mid-task it stays out of the way and
# reports instead.
set -euo pipefail

payload="$(cat 2>/dev/null || true)"

# First match, not last: a UserPromptSubmit payload carries the user's prompt,
# and a greedy match would happily read a key name out of whatever they typed.
json_str() {
    printf '%s' "$payload" |
        grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" |
        head -1 |
        sed 's/.*"\([^"]*\)"$/\1/'
}

EVENT="$(json_str hook_event_name)"
[ -n "$EVENT" ] || EVENT="SessionStart"

# additionalContext rather than plain stdout: on both these events it reaches
# Claude, but only this renders a notice in the transcript, so the user sees the
# same thing Claude was told. Hand-rolled JSON, and the escaping with it, because
# jq is not a safe assumption on a machine that doesn't even have tern. Callers
# pass real newlines and this turns them into the \n a JSON string wants, so the
# message below stays readable in the source.
emit() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$EVENT" "$text"
    exit 0
}

# `compact` fires mid-session, where this would interrupt work in progress for
# something that was already said at startup.
if [ "$EVENT" = "SessionStart" ] && [ "$(json_str source)" = "compact" ]; then
    exit 0
fi

TERN=""
if command -v tern >/dev/null 2>&1; then
    TERN="$(command -v tern)"
elif [ -x "$HOME/.tern/bin/tern" ]; then
    TERN="$HOME/.tern/bin/tern"
fi

[ -n "$TERN" ] && exit 0

# Once per session. Without this the notice repeats on every single prompt for
# as long as tern is missing, which is nagging rather than informing.
session="$(json_str session_id | tr -c 'A-Za-z0-9_-' '_')"
stamp="${TMPDIR:-/tmp}/tern-ensure-hook-${session:-unknown}"
[ -f "$stamp" ] && exit 0
: >"$stamp" 2>/dev/null || true

# Read into a variable rather than inlined at the call: a heredoc inside $( )
# is not parsed by bash 3.2, which is still /bin/bash on macOS. `read -d ''`
# stops at EOF and reports it, hence the `|| true`.
read -r -d '' MESSAGE <<'TXT' || true
The Tern plugin is installed but the `tern` CLI is not on this machine, so the
tour and git-history skills cannot run yet.

If the user has just installed the Tern plugin or this is a new session, do not
ask — set it up now, before anything else this turn. Tell them Tern is finishing
setting up, then run the `/tern:setup` skill: it installs the CLI, runs `tern
bootstrap` to sign them in, link this repo, run the initial scan and mine the
review lens, and starts the local agent. Surface the sign-in URL bootstrap
prints — that is the one part only they can do.

If they are in the middle of something else, don't derail it: say once that Tern
needs setup, and run `/tern:setup` before the first Tern command of the session
or whenever they ask.
TXT

emit "$MESSAGE"
