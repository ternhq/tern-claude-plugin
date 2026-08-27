# Tern agent plugins

The `tern` plugin from [Tern](https://tern.sh) for Claude Code (and Codex)
gives you three on-demand skills — **tour**, **git-history** and **setup**.
Installing it changes no behavior; the agent reaches for a skill when it's
relevant (or you invoke one explicitly). The one automatic piece is a
session-start check that tells the agent, once, if the `tern` CLI isn't
installed yet.

```text
/plugin marketplace add ternhq/tern-claude-plugin
/plugin install tern@tern
```

---

## The skills

### Tour

Open an AI-guided tour of any branch or GitHub pull request, from inside your
agent.

A 47-file change isn't 47 unrelated edits. Tern groups it by what's changing
together, and gives each group a paragraph of context with pointers to the
load-bearing lines. Mechanical churn (renames, formatting, import shuffles) gets
demoted so your attention lands where it matters.

![A Tern tour open in the browser](pr-tour-web.png)

From a checkout of the repo, just ask your agent:

> review this branch with tern

Or invoke it explicitly, with no argument — `/tern:tour` in Claude Code:

```text
/tern:tour
```

That tours whatever branch you have checked out: its open PR if one exists,
otherwise the local branch against its merge-base. To review a PR you don't have
checked out, pass its URL:

```text
/tern:tour https://github.com/owner/repo/pull/123
```

The tour opens in your browser — stops on the left rail, the diff on the right.
No browser available (remote or CI shell)? It falls back to posting the tour as
a pending GitHub review.

### git-history

For a set of files you're about to change, surface what git history knows that
the code at HEAD doesn't. Fully deterministic (no LLM), language-neutral (it
shells out to `git`/`gh`, never parses source), read-only against the repo.

Ask your agent while you're planning a change:

> what should I know about these files before I edit them, with tern

Or invoke it explicitly with the comma-separated files you plan to touch:

```text
/tern:git-history src/foo.ts,src/bar.ts
```

It returns four signals, each a breadcrumb you can't get by reading code at HEAD:

- **moves_together** — files outside your change surface that historically change
  with it. Go read them.
- **in_flight** — open PRs touching these files right now, with their authors'
  stated intent. Consider their direction before you collide.
- **movement** — how hot or cold each file is across recent windows.
- **revert_prone** — files where changes have repeatedly been hard to land.

### setup

Installs the `tern` CLI and runs `tern bootstrap`, the one command that gets a
machine ready: it signs you in (creating an account if you don't have one),
links the repo, runs the initial scan over your agent sessions, and mines your
review lens. Every step it has already done is skipped, so it's safe to re-run.
It then starts the local agent with `tern connect` — a local server that runs
forever, so it stays up in the background.

```text
/tern:setup
```

You rarely need to invoke it. Install the plugin on a machine without the CLI
and the agent runs this for you on the next turn, telling you Tern is finishing
setting up — the sign-in link is the only part you have to do. The tour and
git-history skills bootstrap on their own too.

---

## Requirements

- macOS or Linux (the CLI installer is `curl … | bash`).
- A local git checkout of the repo you're working in.
- The [`gh` CLI](https://cli.github.com), authenticated. Used to find a branch's
  PR (tour) and to list in-flight PRs (git-history).
- An account on app.tern.sh. `tern bootstrap` signs you in on first run — it
  prints a sign-in URL and waits — and stores credentials in `~/.tern`.

The skills are self-contained: on first run they install the `tern` CLI if it's
missing (`curl -fsSL https://tern.sh/install.sh | bash`) and run `tern bootstrap`
if the machine isn't set up. That first bootstrap takes a few minutes — the
initial scan and the review lens are the slow steps.

## Codex

The skills also work in Codex. Let the built-in installer fetch a skill — it
picks the install location:

```text
$skill-installer install https://github.com/ternhq/tern-claude-plugin/tree/main/plugins/tern/skills/tour
$skill-installer install https://github.com/ternhq/tern-claude-plugin/tree/main/plugins/tern/skills/git-history
$skill-installer install https://github.com/ternhq/tern-claude-plugin/tree/main/plugins/tern/skills/setup
```

Then invoke with `$tour`, `$git-history` or `$setup`. The session-start check is
Claude Code only; in Codex the skills still bootstrap on their own.

## Learn more

- [Tours](https://tern.sh/docs/pr-tours): what a tour is, and the three ways to
  read one (browser, VS Code, or posted as a GitHub review)
- [Quickstart](https://tern.sh/docs/install): the CLI on its own, without an agent
- [tern.sh](https://tern.sh): what Tern is
