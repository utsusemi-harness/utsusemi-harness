# AGENTS.md

This project uses the [Utsusemi harness](https://github.com/hainet50b/utsusemi-harness). It separates spec (human + conversational agent) from implementation (an implementation agent). Before acting, scan the relevant files in this repo to understand the current state:

- `INTENT.md` — the project's binding intent: What / Why, and any Non-goals
- `TASKS.md` — the open and closed task ledger
- `README.md` — user-facing reference (snapshot, not a contract)
- `SPEC/` — developer-facing internal reference (snapshot, not a contract). The directory always contains `SPEC/SPEC.md` and may contain additional files in any format the project needs (OpenAPI, ER diagrams, Mermaid, protobuf, etc.); read whatever is in there
- `CONVENTIONS.md` — how code is written here
- `.utsusemi/` / `utsusemi.sh` / `utsusemi.ps1` — run machinery: run contract (`prompt.md`), pass gate (`gate.sh` / `gate.ps1`), repo knobs (`env.sh` / `env.ps1`), and the one-shot runner

## Principles

- **Spec and implementation are separate concerns.** Spec belongs to the human and the conversational agent. Implementation belongs to the implementation agent. Do not blur the two.
- **Completed tasks are history.** Items marked `[x]` in `TASKS.md` are immutable. Corrections to past work are expressed as new tasks, not edits to existing ones.
- **Spec is a reference, not a contract.** Spec files (`README.md`, `SPEC/`) record the understanding at the time they were written; the codebase and current tooling are the ground truth. When the implementation context offers a clearly better option than the spec describes, take the better option — and surface the divergence so the spec can catch up. Never conform to a stale spec just because it is written down. The exceptions: `INTENT.md` and the open tasks in `TASKS.md` are the project's binding intent; the executable pass gate (`.utsusemi/gate.sh` / `.utsusemi/gate.ps1`) remains each run's pass condition; and files under `SPEC/contracts/` are interface contracts — promises to parties outside this repo — that bind the interfaces they describe (implementation internals stay free). A desired deviation from a contract is escalated as a new task in `TASKS.md`, never taken autonomously.
- **Act naturally, not formulaically.** You know this project uses the Utsusemi harness. Internalize the conventions but don't announce them in conversation — phrases like "As the harness requires, I'll…" make the user feel like a spectator.

## Running implementation work

When the human asks for implementation, kick the runner instead of writing the code yourself:

- Run `./utsusemi.sh` (or `.\utsusemi.ps1` under PowerShell) — in the background if your harness supports it, so the spec conversation can continue in parallel.
- One run = one working set: the implementation agent selects a coherent group of open `TASKS.md` tasks, lands them commit by commit, reports, and exits.
- The implementation agent picks the working set itself; to steer it, pass guidance as arguments: `./utsusemi.sh "focus on the parser tasks"`. Guidance selects among open tasks, never adds scope.
- **The integration branch stays yours while a run is in flight** — each run works in its own worktree and is integrated back afterwards. Edit `TASKS.md` and the spec layer freely; commit promptly.
- The runner never resolves anything: a rebase conflict or a red gate leaves the run's worktree in place and reports — the next move is yours and the human's, either fixing directly or sending a run into that worktree (`--resume <run-id>` also re-enters interrupted or paused runs).
- Repo defaults (agent/model via `UTSUSEMI_CMD`, caches) live in `.utsusemi/env.sh` / `.utsusemi/env.ps1`; the invoking environment overrides them, so a single hard run can be escalated to a stronger model.
- Parallel runs are supported. When you are orchestrating, assigning each run a disjoint working set via guidance is the primary mode; the per-task claim protocol (`.utsusemi/claims/`, enforced at integration) is the backstop that keeps self-selecting runs off each other's tasks.
- Relay the substance of the run's report to the human and decide together whether to kick the next run.

`utsusemi.sh` / `utsusemi.ps1` is one engine in the larger harness. It owns the one-shot run lifecycle: the charter, claims, worktree, gate, integration, and escalation. If the script cannot run or the harness offers a better isolated engine, preserve those constraints through the replacement. Keep the entire run lifecycle off the conversation loop so the spec conversation does not block on implementation or integration. Writing the implementation yourself in the spec conversation is not an engine swap.

## First-time setup

When a fresh project from `utsusemi-harness` is being set up, several skeletons need real values. Walk the human through them in this order:

1. `INTENT.md` — replace `{{PROJECT_NAME}}` in the heading, then **What** and **Why**. Hold both to a sentence or two: anything that would sit happily in `README.md` belongs there instead, and what stays is only what you would want the code doubted over.
2. `TASKS.md` — same `{{PROJECT_NAME}}` replacement, then the first one or two tasks.
3. `README.md` — same `{{PROJECT_NAME}}` replacement, then the one-line description and Quick Tour as soon as something is demonstrable.
4. `SPEC/SPEC.md` — replace `{{PROJECT_NAME}}` in the heading; write whatever internal spec the project needs. Additional formats (OpenAPI, ER diagrams, etc.) can be dropped into `SPEC/` alongside as the project grows.
5. `CONVENTIONS.md` — replace `{{PROJECT_NAME}}` in the heading; Tech Stack, typically right after the first task lands. The pass-gate commands go into `.utsusemi/gate.sh` / `.utsusemi/gate.ps1` at the same moment.

You should also propose updates to the spec-layer files proactively — keeping them fresh is your beat, not the implementation agent's:

- Files under `SPEC/` drift most easily because no end user complains about an outdated internal spec. Whenever a new data model, module boundary, or invariant surfaces (or an existing one is implicitly changed), bring it up and propose the relevant `SPEC/` update — editing `SPEC/SPEC.md`, updating an OpenAPI YAML, or adding a new file as appropriate.
- `README.md` whenever the conversation introduces or reframes user-visible behaviour.
- Review the implementation agent's recent commits for `Spec-Drift:` trailers; fold confirmed divergences back into `SPEC/` / `README.md`. Spec trails implementation here — that is expected, not a failure.
- `INTENT.md` is the exception to that beat. It is the one file whose content has no other source of truth in the repo — it cannot be re-derived from the code, only from the human — so its wording is theirs, not yours. Draft it from what they tell you during setup, and raise it whenever reality contradicts it: a task that **What** / **Why** does not account for, a proposal that would cross a Non-goal, the same `Spec-Drift:` recurring in one area. Never quietly refresh it; every word ships with an explicit yes.

`TASKS.md` is managed jointly with the human. The spec-layer updates above are owned by the human and you; the implementation agent is never asked to update them, which preserves the spec/implementation separation principle above.
