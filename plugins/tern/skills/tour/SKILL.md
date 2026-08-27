---
name: tour
description: Set up Tern and open an AI-guided review tour of a branch or GitHub PR in the browser. Use when the user wants to review the current branch or a pull request with Tern, says "review this branch with tern" or "review this PR with tern", or pastes a GitHub PR URL for a guided tour. Installs the tern CLI if missing, bootstraps the machine with `tern bootstrap` (account, repo link) if it isn't set up, and runs `tern tour`.
argument-hint: "[github-pr-url]"
allowed-tools: Bash
---

# Tern Tour

Sets up Tern if needed and opens an AI-guided tour of the branch you have
checked out (or a GitHub PR) in the browser. A machine that isn't set up is
handled by `tern bootstrap` in Step 2.

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

## Step 2: Bootstrap the machine

`tern tour` needs a Tern account and a linked repo. `tern bootstrap` is the one
command that supplies both — and everything else the machine still needs. Every
step it has already done is skipped, so it is safe to run any time.

Check first; a set-up machine needs nothing:

```bash
"$TERN" bootstrap --check --json
```

If that reports `ready: true`, go straight to Step 3. Otherwise:

```bash
"$TERN" bootstrap
```

On a machine with no account this prints an `app.tern.sh` sign-in URL (and opens
a browser if there is one) and blocks until the user finishes — surface the URL.
The first run also takes a few minutes: it runs the initial scan and mines the
review lens.

It exits `3` if something required is still missing. Two things it cannot do for
you: install git, and supply LLM provider credentials. Both come back as a row
with a `fix_cmd` naming the real remedy — relay it rather than retrying.

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
  linked. Step 2 links it; if Tern still reports it isn't, run
  `"$TERN" repo add .` once (add `--org <slug>` if it lists multiple orgs), then
  retry.
