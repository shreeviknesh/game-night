# Contributing

Practical conventions for editing the codebase. Read `DESIGN.md` and `ARCHITECTURE.md` first.

## Always update the docs

Every substantive change to `index.html` should land in the same patch as the matching documentation update. The full mapping of "which doc covers what" lives in `CLAUDE.md` at the repo root, but the short version: user-visible features → `README.md` + `docs/CHANGELOG.md`; Yahtzee/Phase 10 internals → the relevant module doc; visual or interaction shifts → `docs/DESIGN.md`; state, router, persistence → `docs/ARCHITECTURE.md`; conventions or test checklist → this file. Bump `(current)` in `docs/CHANGELOG.md` for substantive batches. A Stop hook in `.claude/settings.json` will remind you before turn-end if you forget.

## Single-file constraint

`index.html` is intentionally a single self-contained file. Don't introduce a build step, modules, or external dependencies. CDN scripts are also off-limits — that's why the Cloud shim talks to Supabase directly via hand-rolled `fetch` rather than pulling in `@supabase/supabase-js`.

If a feature genuinely needs build tooling, that's a project-level decision — file an issue first.

## Supabase project setup

The persistence layer is backed by Supabase. The HTML works without a
backend (cache-only mode), but to enable cloud sync:

1. Create a Supabase project (free tier is enough).
2. Open the SQL editor and paste in `supabase/schema.sql`. It's
   idempotent — safe to re-run after schema changes (constraints and
   tables are guarded; functions use `create or replace`).
3. From Project Settings → API, copy `Project URL` and `anon public` into
   the `SUPABASE_URL` / `SUPABASE_ANON_KEY` constants near the top of
   `<script>` in `index.html`.
4. In Auth → URL Configuration, add the origin you serve from
   (e.g. `https://USER.github.io`) to the allowed list, otherwise CORS
   will block requests.

The anon key is meant to be public — RLS revokes direct table access from
`anon`, and the four `security definer` RPCs are the only attack surface.
Don't ever embed a `service_role` key in HTML.

## Editing layout

The CSS is organized top-down:

1. Design tokens (`:root`)
2. Theme overrides (`body[data-theme="…"]`)
3. Base reset + body
4. Ambient + confetti
5. Topbar + buttons
6. View router
7. Per-screen sections (home, scorecard, tray, modals)
8. Per-game sections (Phase 10 grid, etc.)
9. Responsive media queries (last)

Keep sections in this order. New components go in the relevant section.

Use existing tokens. Don't introduce new colors at the call site — extend the palette through `:root` if a theme genuinely needs it.

## Editing JS

The script is `"use strict";` from line 1. ES2022 syntax is fine. Avoid:

- Top-level `await` (no module context)
- ESM `import`/`export`
- Class fields you don't need (function-style is the project default)

Pre-existing globals you'll see:
- Yahtzee module: `state`, `currentTheme`, `soundOn`, `statsRollsLeft`, `statsPanelOpen`, etc. (legacy)
- Phase 10 module: wrapped in `P10` IIFE, exposes a small public API (`render`, `undo`, `newGame`, `reset`, `loadState`, `showSettings`, `showPhasesModal`, `showRoundsModal`, `showPlayerPhasesModal`, `showArchiveModal`)
- Shared modal helpers: `closeModal`, `showConfirm`, `showPrompt`, `showSetupModal`, `showThemeModal`, `showShortcuts`, `showHistoryModal`
- Roll Insights helpers: `computeInsight`, `renderInsightBar`, `renderInsightBest`, `renderInsightBody`

Don't add new top-level globals unless they're shared utilities.

## Anti-patterns

The design has consciously rejected many patterns over multiple iterations. Before bringing one back, check `DESIGN.md`'s "Anti-patterns rejected" section. Highlights:

- No perpetual loops (pulse, drift, hue-rotate)
- No `box-shadow` glows on player elements
- No multi-stop linear-gradient backgrounds on chrome
- No `backdrop-filter: blur()` (use solid surfaces)
- No uppercase letter-spaced labels
- No serif outside the home hero
- No inner-scrolling accordions for large reference content (use modals)
- No "Stats for Geeks"-style dashboards (Roll Insights is the canonical pattern)
- No layouts that force scroll on a 13" laptop at 100% zoom

## Persisted state changes

Changing the state shape requires either:
1. A migration in `loadState()` for backwards compatibility, OR
2. A version bump on the storage key (`yahtzee.tracker.v2`) plus an explicit reset path

Don't silently break saves. Both modules already do `if (typeof p.x === "undefined") p.x = …` for new fields.

For the cloud schema, bump the `schema_ver` column and apply the same
migration ladder when reading rows whose `schema_ver` is older than the
current code expects. The `Cloud.loadGame` cache write is the natural
place to normalize; treat older cloud rows the way `loadState` already
treats older localStorage shapes.

## Testing

There's no test suite — verify visually:

```sh
python3 -m http.server 8080 --directory .
```

Then exercise:
- Yahtzee: type all 13 categories, hit a Yahtzee, undo, theme change, PNG export
- Phase 10: 4 players, twisted mode, dealer tracking on, commit a few rounds, finish a game, check the archive
- Mobile breakpoints (resize browser to ~375px)

If you change scoring rules, also check the joker constraint paths and the multi-Yahtzee bonus.

When changing Phase 10's commit flow or the round-validity gate, exercise:
- Empty round → Commit disabled, hint "Enter scores or mark who went out"
- Two players marked 0 + cleared → hint "Only one player can go out per round"
- Player has 0 pts but isn't cleared → hint "Each remaining player needs a score above 0"
- Tap a locked Commit → red ripple on the offending rows for ~2.8s
- Tap Commit while focused on a score field → value still recorded (force-blur path)

When changing setup, exercise:
- Two players with the same name → red bottom border + "Name already in use" hint; Confirm blocked
- Edit one of them to a unique name → red clears live; Confirm proceeds

When changing persistence, exercise:
- Start a new game → URL becomes `#g/CODE`, row appears in Supabase `games` table
- Click Share → URL on clipboard; opens cleanly in another browser
- DevTools → Offline → score a category → pip turns amber, write lands in `gn.queue.v1`
- Re-enable network → pip returns to green, queue clears within ~2s
- Visit `#g/FAKE12` → Loading view briefly, then "Game not found" toast
- Two browsers editing the same game → loser sees "Game updated elsewhere — refreshed"
- Migration: in a profile with `yahtzee.tracker.v1`/`phase10.tracker.v1` populated and `gn.migrated.v1` cleared → reload, expect "Your saves are now in the cloud" toast and rows in Supabase

## Version history

Significant releases are documented in `docs/CHANGELOG.md`. The git history (kept externally to this working tree) is the canonical record. Earlier `snapshots/` archive of pre-reduction builds was retired in v5.2 — past iterations live in git, not in the working tree.

## Style nits

- Lowercase comments, sentence case
- 2-space indent for HTML/JS, 2-space indent for CSS
- Use `let` for reassignable, `const` otherwise
- Use single quotes in attribute selectors and double quotes in JS strings (matches existing code)
- Don't add a `console.log` in committed code
