# Issue #87 — Add Drizzle ORM and tRPC to dictionary (Research)

## Objective
Add two new terms requested in https://github.com/iamgerwin/dotfiles/issues/87 to the IT Terms & Jargons Dictionary.

## Codebase Findings
- Dictionary lives at `docs/dictionary.md`.
- Terms are organized by letter sections (`## D`, `## T`) and each term follows:
  - `### <Term>`
  - `**Category:** ...`
  - `**Description:** ...`
  - `**Related Terms:** ...`
- Placement for new entries:
  - `Drizzle ORM` should be in `## D`, alphabetically between `### DQL (Data Query Language)` and `### DRY (Don't Repeat Yourself)`.
  - `tRPC` should be in `## T`, alphabetically between `### Traveling Salesman Problem (TSP)` and `### TTL (Time To Live)`.

## Notes
- Repo does not contain `composer.json` or `package.json`, so no dependency/version updates are required for this docs-only change.

