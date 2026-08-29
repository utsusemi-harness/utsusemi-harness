# {{PROJECT_NAME}} — Developer Spec

This directory is reference material: it records understanding at the time of writing. The codebase is the source of truth — when they disagree, trust the code and update this file.

The one exception is `SPEC/contracts/`. Interface contracts — promises to parties outside this repo, such as the OpenAPI spec of a published API — live there, and there the direction of authority reverses: files under `SPEC/contracts/` are spec-first, the implementation conforms to them, and a desired deviation is raised with the human as a new task in `TASKS.md`, never taken silently. Artifacts generated from code (e.g. an emitted OpenAPI YAML) are outputs, not contracts, and do not belong there. Create the directory when the first contract appears.

Write whatever internal spec helps a developer (or an AI agent implementing a task) understand the project — data structures, architecture, invariants, anything that does not belong in `README.md` (user-facing) or `CONVENTIONS.md` (coding style).

For small projects, this single file is enough. As the project grows, drop additional files into `SPEC/` alongside this one — OpenAPI specs, ER diagrams, protobuf schemas, Mermaid architecture diagrams, whatever format fits the content.
