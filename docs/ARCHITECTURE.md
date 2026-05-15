# Architecture

Single self-contained `index.html`: HTML markup + `<style>` design system + `<script>` app code. No build step, no modules, no bundler.

## High-level structure

```
index.html
├── <style>          ~3,200 lines · design tokens, themes, components
├── <body>
│   ├── #ambient     Fixed solid background (no gradients, no blur)
│   ├── #confetti    Fixed canvas for celebration particles
│   ├── #app         max-width 1120px, min-height 100dvh, centered
│   │   ├── .view#view-home      Game tile launcher
│   │   ├── .view#view-yahtzee   Yahtzee tracker
│   │   ├── .view#view-phase10   Phase 10 tracker
│   │   └── .view#view-loading   Tiny placeholder while resolving #g/CODE
│   ├── #toasts      Top-center toast stack
│   └── #modal-root  Single modal slot
└── <script>         ~5,200 lines · Cloud shim + game modules
```

The script begins with the `Cloud` IIFE (Supabase persistence shim), then
the Yahtzee module (module-scoped), then the Phase 10 module (`P10` IIFE).

## View router

Three sibling `.view` `<section>` elements live in `#app`. CSS:

```css
.view{display:none !important}
.view.active{
  display:flex !important;
  flex-direction:column;
  flex:1; min-height:0;
  animation:viewIn 0.18s var(--ease);
}
```

Only one view is `.active` at a time. Each game view fills the remaining viewport via `flex:1; min-height:0`, so no inner scroll is needed.

The router function:

```js
navigate(targetId, dir = "forward")
```

removes `.active` from the current view, adds it to the target, and triggers per-view boot logic (`onEnterHome`, `onEnterYahtzee`, `onEnterPhase10`). Boot is gated by `_yahtzeeBooted` / `_phase10Booted` so revisiting a view doesn't reset state.

URL hash `#yahtzee` / `#phase10` jumps straight in on load.

## Yahtzee module

Lives at module-scope (no namespace) — predates the `P10` IIFE wrapper. Globals it owns:

- `state` — current game (players, dice, currentIdx, history, gameOver, hailMary, startedAt)
- `currentTheme`, `soundOn`, `editingNameId`, `openColorPickerId`
- `statsRollsLeft`, `statsPanelOpen` (persisted under `yahtzee.settings.v1`)

Key functions:

| Function | Role |
|----|----|
| `scoreFor(catKey, dice, player)` | Pure scoring engine — Hasbro rules + Joker |
| `jokerConstraint(dice, player)` | Returns `{require}` / `{choose}` / `{force0}` |
| `commitScore(catKey)` | Applies the score, advances turn, ends game |
| `pushHistory()` / `undo()` | Snapshot + restore |
| `render()` → `renderScorecard()` + `renderTray()` | DOM re-render entry points |
| `computeStats(player, dice, rollsLeft)` | Closed-form distributions per category |
| `computeInsight(results, dice, rollsLeft, player, forcedFocus)` | Reduces `computeStats` results into a single tactical "insight" object that drives Roll Insights |
| `renderInsightBar` / `renderInsightBest` / `renderInsightBody` | Roll Insights UI fragments |
| `exportFinalCard()` | Renders the final scorecard to a PNG via `<canvas>` |

### Roll Insights (Yahtzee tactical companion)

`computeInsight()` returns:

```js
{
  focus,              // the highlighted result (CategoryResult)
  mood,               // "strong" | "live" | "upside" | "safe" | "long" | "locked" | "sacrifice"
  phrase,             // contextual headline e.g. "Big upside on Sixes"
  value,              // points if it lands (or guaranteed value for exact)
  odds,               // 0..1 chance of landing the headline value
  others,             // top 3 alternative results
  exact,              // true when rollsLeft === 0
}
```

The bar (collapsed view) shows: status dot tinted by mood, phrase, odds-or-value, chevron.
The body (expanded view) shows: best card with mood-tinted progress bar, three near-miss chips (tapping swaps focus), plan-for rolls segment.

## Phase 10 module

Wrapped in an IIFE: `const P10 = (() => { … })()`. Public API:

```
{ boot, render, undo, newGame, reset, loadState,
  showSettings, showPhasesModal, showRoundsModal,
  showPlayerPhasesModal, showArchiveModal,
  get state() { return state; } }
```

State shape (round-based — no per-player turn):

```js
{
  players: [
    {
      id, name, color, glow,
      phaseOrder: number[10],  // [1..10] in standard, random permutation in twisted mode
      currentPhase,            // phase number being attempted (e.g. 4)
      cleared: number[],       // phase numbers cleared, in clearance order
      totalScore,              // accumulated round scores (lower wins)
      pendingScore,            // 0..9999, entered for the current round
      pendingCleared,          // toggle: did this player clear their phase this round?
    }
  ],
  round: number,
  rounds: [{round, entries: [{playerId, name, color, pts, clearedPhase}]}],
  history: [snapshots],        // for undo
  startedAt, gameOver, winnerId,
  twisted: boolean,
  dealerTracking: boolean,
  dealerIdx: number,
}
```

Key flow: `commitRound()` applies every player's pending score + cleared flag in a single transaction, advances each player's `currentPhase` along their personal `phaseOrder`, increments `state.round`, rotates dealer if tracking is on, and checks end-of-game (any player with `cleared.length >= 10`).

`commitRoundValidation()` returns `{ ok, reason }` and is the single source of truth for whether the Commit button is enabled. `pulseInvalidRows(reason)` derives the at-fault rows from the same conditions and applies a brief red-ring animation. See `PHASE10.md` for the rule.

There is no `currentIdx`. Inputs live inline on each player's row; the right panel surfaces a compact round summary + commit.

## Persistence

Game data lives in Supabase Postgres (one `games` table, accessed via four
`security definer` RPCs). A localStorage cache backs the first paint and
gives the app full functionality offline. Device-level UI prefs (theme,
sound, Roll Insights state) stay in localStorage as before.

### Cloud schema

One row per game (in-progress *and* completed):

| Column | Notes |
|---|---|
| `code` | Primary key — 6-char Crockford base32 (minus `0/1/I/O/L/U`) |
| `kind` | `'yahtzee'` or `'phase10'` |
| `state` | The whole game blob as `jsonb` |
| `schema_ver` | Bumped per state-shape migration (currently 1) |
| `game_over` | Stored generated column from `state->>'gameOver'` — drives the History query |
| `started_at`, `updated_at`, `ended_at` | Timestamps |
| `rev` | Monotonic per-row revision; bumped by trigger |

RLS is enabled and direct anon access is revoked. The four RPCs are:
`get_game(code)`, `create_game(kind, state, code)`,
`save_game(code, state, expected_rev)` (returns `conflict: true` on stale
rev — caller refetches and re-renders), and
`list_completed_by_codes(kind, codes[])` (powers the History modal).

**Abuse safeguards** (anon key is public by design):

- `check (octet_length(state::text) <= 262144)` on the `games` table.
  Real game states are <50 KB; 256 KB leaves headroom for shape growth.
- `creates_per_day` counter table + `creates_per_day_check()` function
  called from `create_game`. Caps at 200 new games per day across all
  anon callers. Bump the constant if you legitimately need more.

The whole `supabase/schema.sql` is idempotent — safe to re-run after
edits. Constraints, tables, and indexes are guarded by `if not exists`
or `do $$ if not exists ... $$` blocks; functions use `create or replace`.

### `Cloud` shim

A small IIFE near the top of `<script>` that wraps PostgREST in a
synchronous-looking API. Its public surface:

```
Cloud.init({url, anonKey})
Cloud.isConfigured() / isOnline() / status() / onStatusChange(fn)
Cloud.makeCode()
Cloud.readCache(code) / writeCache(code, payload)
Cloud.createGame(kind, state)        -> {code, rev, updated_at}
Cloud.loadGame(code)                 -> {code, kind, state, rev, ...} | null
Cloud.saveGame(code, state, rev)     -> {rev, updated_at, conflict?}
Cloud.listCompletedByCodes(kind, codes)
Cloud.enqueueWrite(code, state) / Cloud.flushQueue()
```

All RPC calls are hand-rolled `fetch` — no Supabase JS SDK. Writes that
fail offline land in the retry queue (`gn.queue.v1`), drained on `online`
events, on `visibilitychange → visible`, and after every successful write.

### Cache layout (localStorage)

| Key | Role |
|---|---|
| `gn.cache.<code>` | Per-game cache: `{kind, state, rev, updated_at, savedAt}` |
| `gn.current.yahtzee` / `gn.current.phase10` | Active code per game |
| `gn.codes.v1` | Every code this device has touched (drives History) |
| `gn.queue.v1` | Retry queue for offline writes |
| `gn.migrated.v1` | One-shot flag — set after migration finishes |
| `yahtzee.theme.v1` | Active theme (shared across both games) |
| `yahtzee.sound.v1` | Mute state (shared) |
| `yahtzee.settings.v1` | Roll Insights state: `{statsRollsLeft, statsPanelOpen}` |
| (legacy `yahtzee.tracker.v1`, `yahtzee.history.v1`, `phase10.tracker.v1`, `phase10.history.v1`) | Read-only fallbacks; mirror writes happen until the migration flag is set |

The theme + sound keys carry the `yahtzee.` prefix for legacy reasons —
they're applied app-wide. Don't rename without a migration.

### Read / write paths

- `saveState()` (both games): update in-memory `state`, sync-write the
  legacy key + `gn.cache.<code>`, fire-and-forget `Cloud.saveGame`. On
  rev conflict, swap to the server's state and toast
  "Game updated elsewhere — refreshed."
- `loadState()` (both games): if a `gn.current.<kind>` code is set, return
  the cached state synchronously; otherwise fall back to the legacy
  tracker key. The boot path also schedules an async `Cloud.loadGame()`
  that re-renders if `remote.rev > cached.rev`.
- `newGame()`: builds the new state, claims a code via
  `Cloud.createGame`, stamps the URL via `history.replaceState('#g/CODE')`,
  then `saveState()` runs as usual.

### Sharing

URL hash format: `#g/CODE` (kind is returned by the server). The hash
dispatcher checks the cache first — if known, it navigates immediately.
If unknown, it shows `#view-loading` and fetches before navigating.
A `hashchange` listener handles browser back/forward across share URLs.

### Configuration

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are top-of-script constants.
When unset, every `Cloud` method becomes a no-op that just touches the
cache, so the app stays fully functional without a backend (good for
local dev + as a graceful-degradation path).

## Modal system

Single slot at `#modal-root`. Helpers:

- `closeModal()` — empties the slot
- `showConfirm({title, body, confirmText, onConfirm})` — generic confirm
- `showPrompt({title, placeholder, initial, onConfirm})` — text input
- `showSetupModal({title, hint, maxPlayers, options, initialPlayers, onConfirm})` — player setup with optional toggles (used by both games; Phase 10 passes a "Twisted phases" option). Confirm blocks on duplicate names (case-insensitive) — offending rows get `.has-error` and a `.setup-name-hint` underneath; editing the name clears the error live.
- `showThemeModal()` — theme picker
- `showShortcuts()` — keyboard cheatsheet (view-aware)
- `showHistoryModal()` — Yahtzee history
- Phase 10 module exposes `showPhasesModal`, `showRoundsModal`, `showPlayerPhasesModal(id)`, `showArchiveModal`, `showSettings`

All modals share styling (`.modal`, `.modal-backdrop`) and accept a backdrop click + `Esc` to dismiss.

## Audio graph

Web Audio API, lazy-initialized on first sound:

```
oscillator(s) → gain (envelope) → biquad filter → masterBus → destination
                                                  ↓
                                           feedback delay (reverb send) → masterBus
```

`themeVoice()` returns the active theme's voicing (oscillator type, harmonic stack, detune, filter, reverb amount). Per-category SFX live in the `SFX` object.

## Confetti

`<canvas id="confetti">` covers the viewport at z-index 50. `burstConfetti(count, ox, oy)` spawns particles; `tickConfetti()` runs the animation frame and self-stops when particles drain.

## Keyboard

Global listener filters by `currentView`:

- Home: `T` / `M` / `?`
- Yahtzee: `1`–`6`, `Backspace`, `R` (random), `C` (clear), `Z` (undo), `H` (Hail Mary), `T`, `M`, `N` (new), `Esc`
- Phase 10: `Enter` (commit round), `Z` (undo), `T`, `M`, `N`, `Esc`. Score digits go through the row's native `<input type=text inputmode="numeric">`.

`?` and `/` open the cheatsheet from anywhere.

## Theme system

`applyTheme(id)` toggles `body[data-theme]`. The default theme has no attribute (Midnight). Each themed block in CSS overrides:

- All token variables (colors, fonts, dice material)
- Per-component visual treatments (chrome buttons for Retro 98, console-shell shadows for Gameboy, etc.)
- Audio voicing via `themeVoice()`

Adding a theme requires changes in three places: CSS variables, the `THEMES` array, and `themeVoice()` plus `dieTap()` / `keyTap()` per-theme branches.

## Viewport-fit constraint

The default theme is sized so a typical 13" laptop at 100% browser zoom never needs to scroll:

- Topbar ≈ 36px
- Yahtzee scorecard rows = 32px each (40px for grand)
- Phase 10 row ≈ 56px
- Section dividers ≈ 22px

App padding is `14px clamp(14px,2vw,22px) 18px` so the playable area fills `~720px - 32px = ~688px`. Adjust these numbers carefully if you change row heights.

## Coordinate-free constraints

- No frameworks. No modules. No imports. No build.
- All dependencies are browser-native APIs.
- ES2022 syntax (optional chaining, nullish coalescing).
- Strict mode (`"use strict";` at top of script).
- Single-pass parsing — module declarations precede their usages or are hoisted as function declarations.
