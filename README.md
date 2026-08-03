# ralph-loop-starter

A bootstrap for projects driven by the [Ralph Loop](https://ghuntley.com/ralph/) methodology — a workflow that separates _spec_ (kept by the human and a conversational LLM) from _implementation_ (carried out by Ralph, an executor LLM invoked run-by-run against a PRD). The separation is about ownership, not precedence: spec files are reference snapshots of understanding, and the codebase is the ground truth — only the PRD's intent and tasks bind the implementation.

This starter is intentionally minimal. The artifacts it produces are markdown files and a pair of runner scripts. There is no binary to install, no service to run, no abstraction to learn beyond reading the files it places.

> [!NOTE]
> The thinking behind this starter — externalized memory, documenting the "how," and treating the harness as plain text rather than a tool — is in [Living with a Harness — Notes from Ralph Loop](https://programacho.com/blog/living-with-a-harness/).

## Usage

Clone or copy this starter, then run the bootstrap from a normal shell — no AI involved at this step.

```sh
./init.sh ~/projects/my-new-thing        # Linux / macOS
.\init.ps1 $HOME\projects\my-new-thing   # Windows / PowerShell
```

Move into the new project and start your conversational AI agent (Claude Code, Codex, etc.) from there:

```sh
cd ~/projects/my-new-thing
claude        # or your agent of choice
```

A useful first prompt is something like:

> _I just initialized a Ralph Loop project here. I want to build [a short description of what you have in mind]. Walk me through first-time setup._

The agent reads `AGENTS.md` / `CLAUDE.md` in the new project and walks you through replacing `{{PROJECT_NAME}}` placeholders and filling in the spec documents based on what you want to build. When the specs are in shape, ask the agent to run Ralph — it kicks `./ralph.sh` (or `.\ralph.ps1`) while the spec conversation continues — or run the script yourself.

## What gets created

`init.sh` (or `init.ps1`) copies `_project/` into a destination directory and runs `git init`. The generated project contains:

| File | Role |
| --- | --- |
| `README.md` | User-facing reference (snapshot, not a contract) |
| `SPEC/` | Developer-facing internal reference (snapshot, not a contract). Starts with a nearly-empty `SPEC/SPEC.md`; add additional spec files (OpenAPI, ER diagrams, etc.) alongside as the project grows |
| `PRD.md` | Product requirements (What / Why) + Tasks ledger |
| `CONVENTIONS.md` | How code is written (test pattern, lint, commits) |
| `AGENTS.md` | Ralph Loop philosophy + first-time setup hints |
| `CLAUDE.md` | One-line `@AGENTS.md` import so Claude Code reads the same guidance |
| `.ralph/` | Ralph's machinery: `prompt.md` (the run contract), `gate.sh` / `gate.ps1` (the executable pass gate), `env.sh` / `env.ps1` (repo knobs) |
| `ralph.sh` / `ralph.ps1` | Ralph's one-shot runner: isolates each run in a worktree, then integrates it (rebase onto the integration branch → pass gate → fast-forward) |
| `.gitignore` | Standard ignores |

## Departures from the original Ralph

The original Ralph is a bash loop — `while :; do cat PROMPT.md | claude-code ; done` — with one hard rule: one item per loop. The loop itself never checks for completion; it spins until Ralph runs out of things to do in its plan file. Both the tight granularity and the relentless repetition were devices for an era of scarce context.

This starter departs from that form in two ways:

- **The `while` is gone from the shell.** `ralph.sh` runs Ralph **once**: a fresh context wakes up, selects a working set of open tasks (or follows guidance passed as arguments), lands it commit by commit, reports, and exits. Whether and when the next run happens is decided in the spec conversation, not by a counter.
- **One working set per run, not one item.** The one-item rule was budgeting for scarce context; with that scarcity receded, Ralph is trusted to pick a coherent group of related tasks per run — a divergence made for the same reason the rule existed: spend the context window where it pays.

What survives is what made Ralph work in the first place: an executor that begins every run with amnesia and trusts the files — PRD, spec, conventions, git history — as its only memory. That, not the shell loop, was always the heart of the technique.
