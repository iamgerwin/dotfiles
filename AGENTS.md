# Repository workflow

Before changing code or documentation, read [learnings/dump.md](learnings/dump.md),
[README.md](README.md), and the latest entries in [CHANGELOG.md](CHANGELOG.md).
Use the lessons relevant to the files being changed.

- Add a regression test for changed behavior. Run `bash scripts/check.sh` before
  submitting; report any checks or hardware verification you could not perform.
- Keep README usage, CHANGELOG user-visible changes, and VERSION aligned in the
  same PR. Released changelog entries are historical; add new work to Unreleased.
- Update `learnings/dump.md` when a failure reveals a reusable lesson: record the
  symptom, cause, prevention, and test or evidence. Revise obsolete guidance.
- Keep macOS scripts compatible with system Bash 3.2. Test authentication using
  mocks; privileged operations and package updates require explicit human testing.
- Follow the release procedure in README; publish only validated main commits.
