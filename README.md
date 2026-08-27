# ralph-loop-starter

A bootstrap for projects using a harness derived from [Ralph Loop](https://ghuntley.com/ralph/) — a workflow that separates _spec_ (kept by the human and a conversational LLM) from _implementation_ (carried out by an implementation agent started once per run against a PRD). The separation is about ownership, not precedence: spec files are reference snapshots of understanding, and the codebase is the ground truth — only the PRD's intent and tasks bind the implementation.

This starter is intentionally minimal. The artifacts it produces are markdown files and a pair of runner scripts. There is no binary to install, no service to run, no abstraction to learn beyond reading the files it places.

> [!NOTE]
> The design behind this version—and how it departed from Ralph Loop—is described in [A Departure from Ralph Loop — Notes on What My Harness Became](https://programacho.com/blog/a-departure-from-ralph/). Its earlier starting point is preserved in [Living with a Harness — Notes from Ralph Loop](https://programacho.com/blog/living-with-a-harness/).

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

> _I just initialized a project from ralph-loop-starter here. I want to build [a short description of what you have in mind]. Walk me through first-time setup._

The agent reads `AGENTS.md` / `CLAUDE.md` in the new project and walks you through replacing `{{PROJECT_NAME}}` placeholders and filling in the spec documents based on what you want to build. When the specs are in shape, ask the agent to start an implementation run — it kicks `./utsusemi.sh` (or `.\utsusemi.ps1`) while the spec conversation continues — or run the script yourself.

## What gets created

`init.sh` (or `init.ps1`) copies `_project/` into a destination directory and runs `git init`. The generated project contains:

| File | Role |
| --- | --- |
| `README.md` | User-facing reference (snapshot, not a contract) |
| `SPEC/` | Developer-facing internal reference (snapshot, not a contract). Starts with a nearly-empty `SPEC/SPEC.md`; add additional spec files (OpenAPI, ER diagrams, etc.) alongside as the project grows |
| `PRD.md` | Product requirements (What / Why) + Tasks ledger |
| `CONVENTIONS.md` | How code is written (test pattern, lint, commits) |
| `AGENTS.md` | Harness guidance + first-time setup hints |
| `CLAUDE.md` | One-line `@AGENTS.md` import so Claude Code reads the same guidance |
| `.utsusemi/` | Run machinery: `prompt.md` (the run contract), `gate.sh` / `gate.ps1` (the executable pass gate), `env.sh` / `env.ps1` (repo knobs) |
| `utsusemi.sh` / `utsusemi.ps1` | One-shot runner: isolates each run in a worktree, then integrates it (rebase onto the integration branch → pass gate → fast-forward) |
| `.gitignore` | Standard ignores |

## Departures from Ralph Loop

The original Ralph Loop is a bash loop — `while :; do cat PROMPT.md | claude-code ; done` — with one hard rule: one item per loop. The loop itself never checks for completion; it spins until the agent runs out of things to do in its plan file. Both the tight granularity and the relentless repetition were devices for an era of scarce context.

This starter departs from that form in four ways:

- **The `while` is gone from the shell.** `utsusemi.sh` starts an implementation agent **once**: a fresh context wakes up, selects a working set of open tasks (or follows guidance passed as arguments), lands it commit by commit, reports, and exits. Whether and when the next run happens is decided by the conversation or orchestration layer, not by a counter.
- **One working set per run, not one item.** The one-item rule was budgeting for scarce context; with that scarcity receded, the implementation agent is trusted to pick a coherent group of related tasks per run.
- **Runs are parallel by default.** The original loop was strictly serial — one context alive at a time. Here each run works in its own worktree, integration is serialized by a lock, and per-task claims keep concurrent runs off each other's tasks; kicking several runs at once is a normal mode, not a hack.
- **`utsusemi.sh` is one engine in a larger harness.** It executes an isolated one-shot run. The surrounding harness decides when runs start and how independent work is composed.

What survives from Ralph Loop is fresh context for each run, context externalized into files, and the separation of conversation from implementation. The starter keeps its name for historical reasons, but the harness around those ideas has changed substantially.
