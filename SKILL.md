---
name: utsusemi-harness
description: Initialize a brand-new project from the bundled Utsusemi harness, including helping choose a provisional project and directory name when the idea is still vague. Use when the user asks to create, bootstrap, or start a new Utsusemi project in a new or empty directory. Do not use to run, update, migrate, or modify an already initialized project.
---

# Initialize an Utsusemi project

## Establish the destination

- Do not require the user to create or enter a project directory before invoking this skill.
- Use the destination the user gives you. If none is given, ask whether to initialize the current directory or create the project in a new location.
- When creating a new directory and no name is settled, ask only for enough of the idea to suggest two or three concise project names with matching directory names. Treat the choice as provisional; leave detailed requirements for first-time setup after initialization.
- Confirm the destination before creating a new directory when you derived its name or location.

## Run the bundled initializer

Resolve paths relative to this `SKILL.md`; do not assume the skill is installed at a fixed location.

- On Linux or macOS, run `init.sh` with the destination as its single argument.
- On Windows, run `init.ps1` with the destination as its single argument.
- Pass the destination as one quoted argument. Do not copy `_project/` yourself and do not download another copy of the harness.
- Let the initializer decide whether the destination is acceptable. Do not duplicate its validation or override a refusal.

Treat exit status 0 as success. On a non-zero status, stop and report the initializer's error; do not repair, remove, or overwrite the destination.

## Hand off to the generated project

After a successful initialization, treat the destination as the working directory and read its generated `AGENTS.md`. Continue the first-time setup in the same agent session under those project instructions. The skill's workflow ends at this handoff.
