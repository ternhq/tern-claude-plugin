---
name: git-history
description: For a set of files you're about to change, surface what git history knows that the code at HEAD doesn't: which files co-change with them (go read those too), which open PRs are touching them right now and with what intent, how hot or cold each file is, and which are revert-prone. Use while planning a change, before finalizing which files to edit, or whenever the user asks what's related, risky, or in-flight about a set of files. Pass the comma-separated paths you plan to modify.
argument-hint: "<comma-separated file paths>"
allowed-tools: Bash
---

# Tern git-history

Mines local git history and open PRs for the things you can't see by reading
the code at HEAD, for an already-decided set of files. Fully deterministic (no
LLM), language-neutral (it shells out to `git`/`gh`, never parses source), and
read-only against the repo.

It answers one question about the files you're about to touch: *what do I need to
know that isn't in the code or the ticket?* — co-change neighbors, in-flight PRs,
movement, and revert-prone files.

Tern installs to `~/.tern/bin`, which is often not on `PATH`. Resolve the binary
once and use `$TERN` for every command below:

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

The first `git-history` run links the repo on the way through, which needs a
Tern account. `tern bootstrap` supplies both, and skips every step already done:

```bash
"$TERN" bootstrap --check --json
```

If that reports `ready: true`, go straight to Step 3. Otherwise:

```bash
"$TERN" bootstrap
```

On a machine with no account it prints an `app.tern.sh` sign-in URL and blocks
until the user finishes — surface the URL. The first run takes a few minutes.

It exits `3` if something required is still missing, with a `fix_cmd` on each
failing row. git and LLM provider credentials are the two it cannot supply
itself; relay those rather than retrying.

## Step 3: Run git-history on your planned files

Determine the files you intend to modify and pass them comma-separated. If the
skill was invoked with an argument, that argument already is the list:

```bash
"$TERN" git-history --files "$ARGUMENTS" --pretty
```

If you have no argument, substitute the comma-separated paths you plan to touch,
e.g. `"$TERN" git-history --files "src/foo.ts,src/bar.ts" --pretty`.

The first run builds the history index (and links the repo), which can take a
little while on a large repo; later runs refresh incrementally and are fast.

If this errors that `git-history` is an unknown command, the installed `tern`
predates it — run `"$TERN" update` to upgrade to a version that has it, then
retry.

## Step 4: Fold the result into your plan

Read the output and act on it explicitly:

- **moves_together** — files outside your change surface that historically change
  with it. Read them before finalizing the plan; they're the coupling you can't
  see from the code at HEAD.
- **in_flight** — open PRs touching these files right now, with their authors'
  stated intent. Consider their direction so you don't collide or duplicate work.
- **movement** — how hot or cold each file is across recent windows.
- **revert_prone** — files where changes have repeatedly been hard to land.

State in your plan what git-history surfaced and how it changed (or didn't
change) the plan.

## Notes

- Read-only against the repo; it never edits your files.
- `--files` is required. Paths are relative to the repo root.
- Add `--offline` to skip the open-PR (in-flight) lookup. JSON instead of text:
  drop `--pretty`.
