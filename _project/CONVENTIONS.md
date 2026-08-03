# {{PROJECT_NAME}} — Conventions

How code is written in this project. Read before implementing.

## Tech Stack

> _Languages, runtimes, key libraries with one-line rationale for each. The first PRD task usually establishes this; until then, leave a placeholder line so it is visibly empty._

## Test Pattern

Unit tests follow the **3A pattern**:

- **Arrange** — set up the preconditions
- **Act** — explicitly invoke the function or method under test
- **Assert** — verify the outcomes

Fixtures handle Arrange only. The Act call must be visible in the test body, not hidden inside a fixture helper.

## Pass Gate

The executable pass gate lives in `.ralph/gate.sh` and `.ralph/gate.ps1`, kept behaviorally identical. It must exit 0 before a task is marked complete in `PRD.md`, and the run integration re-runs it. The starter ships both as placeholders — put the real commands in once the stack is chosen (e.g. `cargo fmt --check && cargo clippy -- -D warnings && cargo test`).

## Commit Messages

Subject line: present-imperative, ≤ 72 characters. Body optional and free-form. The implementation LLM has discretion on wording — no template, no enforced prefixes.

## File and Identifier Naming

> _Naming rules that matter for consistency (e.g., snake_case for Rust modules, PascalCase for types, kebab-case for CLI subcommand names). Add as conventions emerge._
