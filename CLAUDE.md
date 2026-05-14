# Claude conventions for game-night

## Always keep docs in sync with code

Whenever you make a substantive code change to `index.html`, **proactively** update any markdown files that describe the affected surface area — without being asked. The repo's docs are the canonical record the maintainer reviews and ships; stale docs erode trust in the working tree.

Map of which doc covers what:

| Change type | Files to update |
|---|---|
| New / changed user-visible feature | `README.md` (feature bullets) + `docs/CHANGELOG.md` (new entry, bump `(current)`) |
| Yahtzee-specific behavior | `docs/YAHTZEE.md` |
| Phase 10-specific behavior | `docs/PHASE10.md` |
| State, persistence, router, modals, audio | `docs/ARCHITECTURE.md` |
| Visual / interaction patterns, colors, motion, anti-patterns | `docs/DESIGN.md` |
| Editing conventions, test checklist, single-file constraints | `docs/CONTRIBUTING.md` |
| Repo file map (adding / removing top-level files or directories) | `README.md` file-map block |

For substantive batches add a new versioned entry at the top of `docs/CHANGELOG.md` matching the existing prose style (short headline + bulleted detail). Move the `(current)` tag to the new section.

A Stop hook in `.claude/settings.json` surfaces a reminder before each turn ends. The reminder is a safety net — the expectation is that you've already updated the docs by then.

## Single-file working tree

There is no `.git/` here. The maintainer keeps git history in an external repo and copies `index.html` + the markdown files there manually. Don't suggest `git init` or run git commands in this directory; use the conversation diffs to draft commit messages instead.

## See also

- `docs/CONTRIBUTING.md` — editing conventions, anti-patterns, test checklist
- `docs/DESIGN.md` — what to do, what to never reintroduce
- `docs/CHANGELOG.md` — what changed and when
