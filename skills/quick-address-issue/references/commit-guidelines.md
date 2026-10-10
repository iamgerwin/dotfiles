# Commit Guidelines

Check every commit against this list before creating it.

## Checklist

- [ ] **One intent per commit**: a single change theme; never mix refactor, feature, and bugfix.
- [ ] **Independently safe**: the build passes, with no broken state or half-finished logic.
- [ ] **Small, reviewable diff**: no "mega commits"; split by responsibility.
- [ ] **Layer-separated**: schema → backend → UI → tests; mix layers only when unavoidable.
- [ ] **Pure refactors isolated**: no behavior change inside a refactor commit.
- [ ] **Formatting/lint isolated**: never bundled with logic changes.
- [ ] **Tests travel with the change**: in the same commit or the one right after it, never "later".
- [ ] **Clean reverts**: reverting this commit must not break others; avoid hidden dependencies.
- [ ] **No secrets or debug artifacts**: no tokens, console spam, or temporary files.
- [ ] **Conventional, descriptive message**: imperative verb + scope + outcome.
- [ ] **Ticket referenced**: `Fixes #<n>` on the commit that resolves the issue, `Refs #<n>` on the others.
- [ ] **Guard risky changes**: use a feature flag, fallback path, or config toggle.
- [ ] **No AI attribution**: no `Co-Authored-By` AI trailers and no "Generated with" lines.

## Message format

```
<type>(<scope>): <imperative summary, lowercase, no period>

<why the change exists and what it does, wrapped at ~72 chars>

Refs #<issue-number>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`, `ci`, `build`.

If the repository already uses a different convention (check `git log --oneline -20`),
follow the repository's convention instead.

## Examples

```
fix(auth): enforce approval guard on update
feat(brew): add orca and headroom AI tools
docs(readme): remove windsurf reference
refactor(skills): rename templates/ to assets/ in existing skills
test(parser): cover short owner/repo#number form
```

## Typical commit sequence

1. `refactor`: preparatory moves or renames, with no behavior change
2. `feat` / `fix`: the actual change, plus its tests
3. `test`: any extra coverage that didn't fit the change commit
4. `docs`: README, guides, and CHANGELOG alignment
