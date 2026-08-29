![Utsusemi Harness](assets/banner.png)

A harness that separates _spec_ from _implementation_. You and a conversational agent keep the spec; implementation agents write the code. Neither side waits for the other: you keep writing tasks while several implementation agents land the ones already written.

This repository initializes a new project with the harness. It is intentionally minimal. What it puts in the project is markdown files and a few short scripts. There is no binary to install, no service to run, and no abstraction to learn beyond reading those files.

## The name

_Utsusemi_ (空蝉) is Japanese for a cicada's empty shell — an archaic, literary word for it.

Each run is one cicada. It grows in a worktree of its own, on a branch named `utsusemi/<run-id>`, with no memory of the runs before it. When the work is ready, the commits fly off and join the integration branch. The worktree and the branch are left behind. That is the empty shell — _Utsusemi_.

## How it works

### Roles

- **You and a conversational agent** own the spec: the binding intent in `INTENT.md`, the task ledger in `TASKS.md`, `README.md`, everything under `SPEC/`, and `CONVENTIONS.md`.
- **An implementation agent** owns the code. It never edits the spec, only reads it, and what it implements is the open tasks you have written in `TASKS.md`. Its work has to pass the gate in `.utsusemi/gate.sh`. Where the spec turns out to be stale or wrong, the agent can depart from it, and records the divergence as a `Spec-Drift:` trailer in the commit so you can decide what to do about it.

### Stages of a run

- **Isolation.** The runner, `utsusemi.sh`, creates a worktree at `.utsusemi/worktrees/<run-id>` on a new branch `utsusemi/<run-id>`, made from whatever branch is currently checked out. It pipes `.utsusemi/prompt.md`, the run contract, into an agent that starts with an empty context.

- **Execution.** The agent reads `TASKS.md` and picks a working set: open tasks that belong together. It claims each one in `.utsusemi/claims/` before touching it, so that two runs never take the same task. Then it works through them one at a time — implement, run the gate, check the task off, commit. When the set is done it writes a report and exits.

- **Integration.** A run takes the lock at `.utsusemi/integrate.lock` before it integrates, so only one integration happens at a time. The run's branch is rebased onto the integration branch, and the pass gate runs again on the result. If it passes, the work lands. If anything fails, the runner fixes nothing. It leaves the worktree in place and reports the reason, and the next move is yours: fix it yourself, or send another run into that worktree with `./utsusemi.sh --resume <run-id>`.

### Choosing a working set

- **Guided by an orchestrator.** Pass guidance as arguments — `./utsusemi.sh "focus on the parser tasks"`. Your conversational agent uses this to keep several runs going at once, giving each one a different part of the ledger.
- **Self-selected.** Start the runner with no arguments — `./utsusemi.sh`. The agent reads the open tasks and takes a set that belongs together.

## Install as an agent skill

The repository is a self-contained [Agent Skill](https://agentskills.io). For example, install it from GitHub for Claude Code with:

```sh
gh skill install hainet50b/utsusemi-harness utsusemi-harness --agent claude-code --scope user
```

Install it for whichever agent you prefer. For Codex or OpenCode, use `codex` or `opencode` for `--agent` instead of `claude-code`.

## Usage

### Initialize with the skill

1. Start Claude from any directory. It does not need to be the future project directory.

   ```sh
   claude
   ```

   Use whichever agent you prefer; for example, run `codex` or `opencode` instead.

2. Ask it to create an Utsusemi project. At this point, a description just detailed enough to inspire a provisional name is sufficient; first-time setup explores the idea after initialization.

   > _Create a new Utsusemi project. I want to make [a brief description], but I do not have a name yet._

3. When asked where to initialize it, choose the current directory or a new location. If the project has no name yet, the skill helps choose a provisional project and directory name first.

After initialization, continue in the same agent session. The agent asks what it needs to know, and the first version of the spec takes shape as you answer. When it is ready, ask the agent to start an implementation run; it runs `./utsusemi.sh` (`.\utsusemi.ps1` on Windows) for you.

### Manual initialization

You can still clone or copy this repository and run the initializer directly from a normal shell.

```sh
./init.sh ~/projects/my-new-project        # Linux / macOS
.\init.ps1 $HOME\projects\my-new-project   # Windows
```

Move into the new project and start your conversational agent:

```sh
cd ~/projects/my-new-project
claude        # or codex / opencode
```

A useful first prompt is something like:

> _I initialized a new Utsusemi project here. I want to make [a brief description]. Guide me through first-time setup._

The agent asks what it needs to know, and the first version of the spec takes shape as you answer. When it is ready, ask the agent to start an implementation run; it runs `./utsusemi.sh` (`.\utsusemi.ps1` on Windows) for you.

## What gets created

`init.sh` (or `init.ps1`) copies the bundled project template into a destination directory and runs `git init`:

```
my-new-project/
├── INTENT.md           spec: the binding What / Why
├── TASKS.md            spec: the task ledger
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

- `INTENT.md` states what the project is, why it exists, and what it deliberately is not.
- `TASKS.md` holds the tasks that come out of your discussion with the conversational agent. A run works from the open ones.
- `SPEC/` starts with a nearly empty `SPEC/SPEC.md`. Put whatever the project needs beside it — OpenAPI, ER diagrams, anything. A run reads these for background; the exception is `SPEC/contracts/`, which holds promises to something outside the repo and does bind a run.
- `.utsusemi/gate.sh` and `.ps1` are the pass gate: the agent runs it before checking a task off, and the runner runs it again at integration. They ship as placeholders that pass everything — put the real commands in once the stack is chosen.
- `.utsusemi/env.sh` and `.ps1` set which agent and model a run uses, through `UTSUSEMI_CMD`. The usual setup is a strong model for the conversation and a cheaper one for the implementation agents, which keeps the token cost of runs down. The invoking environment overrides it, so a single hard run can still go to a stronger model.

## Lineage

This harness began as [Ralph Loop](https://ghuntley.com/ralph/), then went through [ralph-loop-starter](https://github.com/hainet50b/ralph-loop-starter) before becoming what it is now. What survives from that line is a fresh context for every run, continuity kept in files instead of in the agent, and the separation of conversation from implementation.

> [!NOTE]
> The design behind this version—and how it departed from Ralph Loop—is described in [A Departure from Ralph Loop — Notes on What My Harness Became](https://programacho.com/blog/a-departure-from-ralph/). Its earlier starting point is preserved in [Living with a Harness — Notes from Ralph Loop](https://programacho.com/blog/living-with-a-harness/).
