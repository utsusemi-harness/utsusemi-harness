# utsusemi-harness

A harness that separates _spec_ from _implementation_. You and a conversational agent keep the spec; implementation agents write the code. Neither side waits for the other: you keep writing tasks while several implementation agents land the ones already written.

This repository bootstraps the harness into a new project. It is intentionally minimal. What it puts in the project is markdown files and a few short scripts. There is no binary to install, no service to run, and no abstraction to learn beyond reading those files.

## The name

_Utsusemi_ (空蝉) is Japanese for a cicada's empty shell — an archaic, literary word for it.

Each run is one cicada. It grows in a worktree of its own, on a branch named `utsusemi/<run-id>`, with no memory of the runs before it. When the work is ready, the commits fly off and join the integration branch. The worktree and the branch are left behind. That is the empty shell — _Utsusemi_.

## How it works

### Roles

- **You and a conversational agent** own the spec: the What and Why in `PRD.md`, its Tasks ledger, `README.md`, everything under `SPEC/`, and `CONVENTIONS.md`.
- **An implementation agent** owns the code. It never edits the spec, only reads it, and what it implements is the open tasks you have written there. Its work has to pass the gate in `.utsusemi/gate.sh`. Where the spec turns out to be stale or wrong, the agent can depart from it, and records the divergence as a `Spec-Drift:` trailer in the commit so you can decide what to do about it.

### Stages of a run

- **Isolation.** The runner, `utsusemi.sh`, creates a worktree at `.utsusemi/worktrees/<run-id>` on a new branch `utsusemi/<run-id>`, made from whatever branch is currently checked out. It pipes `.utsusemi/prompt.md`, the run contract, into an agent that starts with an empty context.

- **Execution.** The agent reads `PRD.md` and picks a working set: open tasks that belong together. It claims each one in `.utsusemi/claims/` before touching it, so that two runs never take the same task. Then it works through them one at a time — implement, run the gate, check the task off, commit. When the set is done it writes a report and exits.

- **Integration.** A run takes the lock at `.utsusemi/integrate.lock` before it integrates, so only one integration happens at a time. The run's branch is rebased onto the integration branch, and the pass gate runs again on the result. If it passes, the work lands. If anything fails, the runner fixes nothing. It leaves the worktree in place and reports the reason, and the next move is yours: fix it yourself, or send another run into that worktree with `./utsusemi.sh --resume <run-id>`.

### Choosing a working set

- **Guided by an orchestrator.** Pass guidance as arguments — `./utsusemi.sh "focus on the parser tasks"`. Your conversational agent uses this to keep several runs going at once, giving each one a different part of the ledger.
- **Self-selected.** Start the runner with no arguments — `./utsusemi.sh`. The agent reads the open tasks and takes a set that belongs together.

## Usage

Clone or copy this repository, then run the bootstrap from a normal shell — no AI involved at this step.

```sh
./init.sh ~/projects/my-new-project        # bash
.\init.ps1 $HOME\projects\my-new-project   # PowerShell
```

Move into the new project and start your conversational agent (Claude Code, Codex, etc.) from there:

```sh
cd ~/projects/my-new-project
claude        # or your agent of choice
```

A useful first prompt is something like:

> _I just initialized a project from utsusemi-harness here. I want to build [a short description of what you have in mind]. Walk me through first-time setup._

The agent reads `AGENTS.md` and `CLAUDE.md` in the new project, then asks you what it needs to know. You answer, and the first version of the spec takes shape out of that conversation. When it is in shape, ask the agent to start an implementation run, and it kicks `./utsusemi.sh` for you.

## What gets created

`init.sh` (or `init.ps1`) copies `_project/` into a destination directory and runs `git init`:

```
my-new-project/
├── PRD.md              spec: What / Why + the Tasks ledger
├── README.md           spec: user-facing
├── SPEC/
│   └── SPEC.md         spec: internal
├── CONVENTIONS.md      spec: how code is written here
├── AGENTS.md           guidance for agents
├── CLAUDE.md           a one-line import of AGENTS.md
├── utsusemi.sh / .ps1  the runner
├── .utsusemi/
│   ├── prompt.md       the run contract
│   ├── gate.sh / .ps1  the pass gate
│   └── env.sh / .ps1   repo knobs
├── .gitattributes
└── .gitignore
```

A few are worth calling out.

- `PRD.md` holds the tasks that come out of your discussion with the conversational agent. A run works from them.
- `SPEC/` starts with a nearly empty `SPEC/SPEC.md`. Put whatever the project needs beside it — OpenAPI, ER diagrams, anything. A run reads these for background; the exception is `SPEC/contracts/`, which holds promises to something outside the repo and does bind a run.
- `.utsusemi/gate.sh` and `.ps1` are the pass gate: the agent runs it before checking a task off, and the runner runs it again at integration. They ship as placeholders that pass everything — put the real commands in once the stack is chosen.
- `.utsusemi/env.sh` and `.ps1` set which agent and model a run uses, through `UTSUSEMI_CMD`. The usual setup is a strong model for the conversation and a cheaper one for the implementation agents, which keeps the token cost of runs down. The invoking environment overrides it, so a single hard run can still go to a stronger model.

## Lineage

This harness began as [Ralph Loop](https://ghuntley.com/ralph/), then went through [ralph-loop-starter](https://github.com/hainet50b/ralph-loop-starter) before becoming what it is now. What survives from that line is a fresh context for every run, continuity kept in files instead of in the agent, and the separation of conversation from implementation.

> [!NOTE]
> The design behind this version—and how it departed from Ralph Loop—is described in [A Departure from Ralph Loop — Notes on What My Harness Became](https://programacho.com/blog/a-departure-from-ralph/). Its earlier starting point is preserved in [Living with a Harness — Notes from Ralph Loop](https://programacho.com/blog/living-with-a-harness/).
