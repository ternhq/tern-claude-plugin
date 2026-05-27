---
name: tour
description: Set up Tern and open an AI-guided review tour of a branch or GitHub PR in the browser. Use when the user wants to review the current branch or a pull request with Tern, says "review this branch with tern" or "review this PR with tern", or pastes a GitHub PR URL for a guided tour. Installs the tern CLI if missing, creates an account on app.tern.sh if there isn't one, and runs `tern tour`.
argument-hint: "[github-pr-url]"
allowed-tools: Bash
---

# Tern Tour

Sets up Tern if needed and opens an AI-guided tour of the branch you have
checked out (or a GitHub PR) in the browser. If the machine has no Tern
account, one is created automatically on app.tern.sh.

Tern installs to `~/.tern/bin`, which is often not on `PATH`. Resolve the
binary once and use `$TERN` for every command below:

```bash
TERN="$(command -v tern || echo "$HOME/.tern/bin/tern")"
```

## Step 1: Install tern

Skip if `tern` is already on `PATH` or at `~/.tern/bin/tern`. Re-running just
updates to the latest version.

```bash
command -v tern >/dev/null 2>&1 || [ -x "$HOME/.tern/bin/tern" ] || curl -fsSL https://tern.sh/install.sh | bash
```

## Step 2: Ensure an account

`tern tour` needs a Tern account. Run by a person without one, it drops
into an interactive sign-in UI, which a skill can't drive, so create the
account up front. Only do this if the machine isn't already signed in, and
never overwrite an existing identity.

Pick two short, random, lowercase words (for example `maple-otter`) and use
them as the username suffix:

```bash
"$TERN" auth whoami >/dev/null 2>&1 || "$TERN" auth new --username "$(whoami)-WORD1-WORD2"
```

Replace `WORD1-WORD2` with the two words you picked. The `$(whoami)` prefix
keeps the account recognizable in the Tern UI; the random words keep it from
colliding with other users on app.tern.sh. If the username is already taken,
pick two different words and retry.

## Step 3: Open the tour

The browser tour is the primary path. The usual case is the branch you have
checked out, so default to no argument:

```bash
"$TERN" tour
```

This tours the current branch: its open PR if one exists, otherwise the local
branch against its merge-base.

If the user explicitly passed a PR URL, tour that PR instead:

```bash
"$TERN" tour "$ARGUMENTS"
```

`tern tour` opens the tour in the browser, then keeps the local Tern
agent running. It runs until stopped and does not exit on its own. Run it as a
long-running/background process; the tour opens shortly after it starts.

Running from inside the repo auto-links it on the way through, so there is no
need to run `tern repo add` first.

If a `tern` command errors (for example reporting an unknown command on an older
CLI), run `"$TERN" update` to upgrade, then retry.

### Headless fallback (no browser)

Not the default. Use only when no browser is available, such as a remote or CI
shell. This generates the tour, posts it as a pending GitHub review, and
exits. Requires the `gh` CLI authenticated against GitHub:

```bash
"$TERN" tour --post-draft "$ARGUMENTS"
```

## Notes

- The no-argument and `--post-draft` flows use `gh` to find the PR for the
  current branch. If `gh` is missing or unauthenticated, pass an explicit PR
  URL instead.
- Edge case: touring a branch with no open PR requires the repo to already be
  linked. If Tern reports it isn't linked, run `"$TERN" repo add .` once (add
  `--org <slug>` if it lists multiple orgs), then retry.
