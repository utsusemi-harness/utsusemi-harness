# {{PROJECT_NAME}} — PRD

This is the Product Requirements Document. It owns three things: the project's **What**, the project's **Why**, and the open and closed **Tasks**. End-user-facing surface lives in `README.md`; internal structure lives under `SPEC/`; coding style lives in `CONVENTIONS.md`.

## What

> _One short paragraph: what this product is, in product terms. Update as scope sharpens. The conversational LLM is expected to propose updates here as understanding deepens — accept or modify in conversation._

## Why

> _One short paragraph: why this product exists, who it serves, what problem it removes from the world. Same update rhythm as **What**._

## Tasks

Each task is one concern and carries a stable id — `- [ ] T<n>: …`, where `<n>` is the next unused number at append time. Ids are never reused or renumbered. An open task may be amended until a run claims it (`ls .ralph/claims`); from then on it is frozen — changes become new tasks — and completed tasks (`- [x]`) are immutable history. Tasks are processed in order subject to their dependencies.

- [ ] T1: Define the first task.
