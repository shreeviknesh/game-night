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
│   │   └── .view#view-phase10   Phase 10 tracker
│   ├── #toasts      Top-center toast stack
│   └── #modal-root  Single modal slot
└── <script>         ~4,800 lines · everything else
```

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

## Persistence keys

All `localStorage`. JSON-encoded, capped at 50 entries for history.

| Key | Owner |
|----|----|
| `yahtzee.tracker.v1` | Yahtzee in-progress game |
| `yahtzee.history.v1` | Yahtzee completed games |
| `yahtzee.theme.v1` | Active theme (shared across both games) |
| `yahtzee.sound.v1` | Mute state (shared) |
| `yahtzee.settings.v1` | Roll Insights state: `{statsRollsLeft, statsPanelOpen}` |
| `phase10.tracker.v1` | Phase 10 in-progress game |
| `phase10.history.v1` | Phase 10 completed games |

The theme + sound keys carry the `yahtzee.` prefix for legacy reasons — they're applied app-wide. Don't rename without a migration.

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
