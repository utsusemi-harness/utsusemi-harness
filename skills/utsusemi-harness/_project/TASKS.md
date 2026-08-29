# {{PROJECT_NAME}} — Tasks

The open and closed task ledger. Binding intent lives in `INTENT.md`; end-user-facing surface lives in `README.md`; internal structure lives under `SPEC/`; coding style lives in `CONVENTIONS.md`.

Each task is one concern and carries a stable id — `- [ ] T<n>: …`, where `<n>` is the next unused number at append time. Ids are never reused or renumbered. An open task may be amended until a run claims it (`ls .utsusemi/claims`); from then on it is frozen — changes become new tasks — and completed tasks (`- [x]`) are immutable history. Tasks are processed in order subject to their dependencies.

One blank line separates tasks, including before a newly appended one, so that concurrent checkoffs and appends merge without git conflicts.

- [ ] T1: Define the first task.
