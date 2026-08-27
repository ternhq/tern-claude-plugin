---
name: setup
description: Install the Tern CLI and bootstrap this machine — sign in, link the repo, run the initial scan, mine the review lens. Use when `tern` is missing, when a tern command reports the machine is not set up or exits 3, or when the user asks to install, set up, or bootstrap Tern.
allowed-tools: Bash
---

# Tern setup

Gets this machine from nothing to ready: the CLI installed, and `tern bootstrap`
run to do everything else.

Tern installs to `~/.tern/bin`, which is often not on `PATH`. Resolve the binary
once and use `$TERN` for every command below:

```bash
TERN="$(command -v tern || echo "$HOME/.tern/bin/tern")"
```

## Step 1: Install the CLI

Skip if `tern` is already on `PATH` or at `~/.tern/bin/tern`. Re-running just
updates to the latest version.

```bash
command -v tern >/dev/null 2>&1 || [ -x "$HOME/.tern/bin/tern" ] || curl -fsSL https://tern.sh/install.sh | bash
```

## Step 2: See what's still missing

`tern bootstrap --check` performs nothing and reports one row per setup step —
git, your account, your org, an LLM provider, this repo's link, the initial scan,
your review lens, and the Claude Code Stop hook — as `ok`, `missing`, `pending`
or `unknown`:

```bash
"$TERN" bootstrap --check --json
```

`ready: true` means there is nothing to do; stop here. Otherwise go on.

## Step 3: Bootstrap

One command sets the machine up, and every step it has already done is skipped,
so running it twice is harmless:

```bash
"$TERN" bootstrap
```

It signs you in (creating an account if there isn't one), links this repo, runs
the initial scan over your agent sessions, and mines your review lens.

Two things to tell the user before you run it:

- **It waits for a sign-in.** On a machine with no account it prints an
  `app.tern.sh` URL (and opens a browser if there is one). Surface that URL —
  the command blocks until the user opens it and finishes.
- **The first run takes a few minutes.** The scan and the lens are the slow
  steps. Run it in the foreground and let it finish; a half-finished bootstrap
  leaves the machine not set up.

## Step 4: Report what it couldn't do

Exit `0` means set up, `3` means something required is still missing, `1` means
the command failed.

Two things bootstrap cannot do for you, and both come back as a row with a
`fix_cmd` naming the real remedy:

- **git isn't installed** — the user has to install it.
- **no LLM provider credentials** — the user has to supply them
  (`tern set-provider <name>`).

Relay the failing rows and their `fix_cmd`; don't retry `tern bootstrap` for
either of these, it will report the same thing.

## Step 5: Start the agent

Bootstrap exits when it is done; it does not leave anything running. The local
agent is a separate, long-lived process:

```bash
"$TERN" connect
```

This starts the local agent. The command runs forever as a local server — it
must stay running in a separate terminal or background process, so run it as a
background process rather than waiting on it. Step 3 already signed the user in,
so it will not ask them to authenticate again.

## Notes

- If `tern` reports `bootstrap` as an unknown command, the installed CLI predates
  it — run `"$TERN" update`, then retry.
- Everything here is idempotent. When in doubt, run `bootstrap --check` again
  rather than guessing at state.
