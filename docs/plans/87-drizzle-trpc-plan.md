# Issue #87 — Add Drizzle ORM and tRPC to dictionary (Plan)

## Changes
1. Add `Drizzle ORM` entry to `docs/dictionary.md` under `## D` between `DQL` and `DRY` using the existing term template:
+
```md
### Drizzle ORM

**Category:** ORM / Database
**Description:** A lightweight, TypeScript-first ORM that provides type-safe database access with a SQL-like query builder. Drizzle defines schema in TypeScript, offers strong inference, and keeps runtime overhead minimal while supporting modern deployment targets.
**Related Terms:** TypeScript, ORM (Object-Relational Mapping), SQL (Structured Query Language), SQLite, Edge Computing
```

2. Add `tRPC` entry to `docs/dictionary.md` under `## T` between `Traveling Salesman Problem (TSP)` and `TTL`:
+
```md
### tRPC

**Category:** API / Full-Stack
**Description:** A TypeScript framework for building end-to-end type-safe APIs without code generation. tRPC lets clients call backend procedures directly with full TypeScript inference, often used in full-stack apps and monorepos.
**Related Terms:** REST API (Representational State Transfer), GraphQL, TypeScript, Next.js, Monorepo, TanStack
```

3. Update docs references:
   - `CHANGELOG.md` (Unreleased) noting the dictionary additions.
   - `README.md` (dictionary section) mentioning the new modern TypeScript terms.

## Validation
- Ensure Markdown formatting matches existing conventions in `docs/dictionary.md`.
- Run `markdownlint` if available; otherwise do a quick render sanity check (headings, spacing).

