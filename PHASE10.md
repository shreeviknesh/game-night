# Phase 10 module

Round-based score tracker for Mattel's Phase 10. Supports the standard ordering and the "Twisted Phases" variant.

## Why round-based, not turn-based

Phase 10 isn't played one player at a time the way Yahtzee is. Everyone plays in parallel, the round ends when one player goes out, and at that point *every* player counts the cards left in their hand and reports those points to the scorekeeper. The UI matches: a single roster where every row is an inline entry surface, plus a side panel with one big "Commit round" button.

There is no `currentIdx`. There is no turn pointer. Everything is per-round.

## State shape

```js
{
  players: [
    {
      id, name, color, glow,
      phaseOrder: number[10],  // [1..10] in standard, random permutation in twisted
      currentPhase,            // phase number (1..10) the player is currently attempting
      cleared: number[],       // phase numbers cleared, in clearance order
      totalScore: number,
      pendingScore: number,    // entry for this round (0..9999)
      pendingCleared: boolean, // ticked if this player cleared their phase this round
    }
  ],
  round: number,
  rounds: [
    {round, entries: [{playerId, name, color, pts, clearedPhase}]}
  ],
  history: [snapshots],
  startedAt, gameOver, winnerId,
  twisted: boolean,
  dealerTracking: boolean,
  dealerIdx: number,
}
```

`phaseOrder` decouples the *slot* a player is in from the *phase number* they're attempting. In standard mode `phaseOrder === [1,2,3,4,5,6,7,8,9,10]`. In twisted mode it's a random permutation, generated per player at game start.

## The ten phases

| # | Goal | Hint |
|---|------|------|
| 1 | 2 sets of 3 | Two groups of three matching numbers |
| 2 | 1 set of 3 + 1 run of 4 | Three of a kind plus a four-card run |
| 3 | 1 set of 4 + 1 run of 4 | Four of a kind plus a four-card run |
| 4 | 1 run of 7 | Seven cards in numerical order |
| 5 | 1 run of 8 | Eight cards in numerical order |
| 6 | 1 run of 9 | Nine cards in numerical order |
| 7 | 2 sets of 4 | Two groups of four matching numbers |
| 8 | 7 cards of one color | Seven cards sharing a single color |
| 9 | 1 set of 5 + 1 set of 2 | Five of a kind plus a pair |
| 10 | 1 set of 5 + 1 set of 3 | Five of a kind plus three of a kind |

## Round flow

Each player's row reads:

```
●  Maya                                  ●●●●○○○○○○        ✓  + 35 pts        72
   Phase 5 · 1 run of 8
```

- Left: dot + name (+ Dealer chip), the rule on its own line directly under the name (`Phase 5 · 1 run of 8`)
- Middle: the slim 10-step phase track, tappable to open the per-player phase popup
- Right: cleared toggle (square checkbox) + native numeric input + running total

The right panel surfaces a balanced summary:

- **Round X** hero number
- **Round total** — sum of all pending scores
- **Cleared this round** — count vs. player count
- **Phases done** — total phases completed across the table
- **Dealer** (if tracking is on)
- Primary **Commit round X** button + secondary **Clear entries**

`commitRound()` runs once per round:

1. Snapshots state for undo
2. For each player: if `pendingCleared`, push `currentPhase` onto `cleared[]` and advance to the next phase in their `phaseOrder` (or 11 = finished)
3. Adds `pendingScore` to `totalScore`
4. Records the round entry on `rounds[]`
5. Resets pending fields
6. Calls `finalizeRound()` — checks game-over (any `cleared.length >= 10`) and rotates the dealer

## Twisted Phases

Toggled at setup time via the player-list extras toggle. Effects:

- Each player gets a per-game random permutation of `[1..10]` as their `phaseOrder`.
- Their phase track displays slots in *that* order.
- `nextPhaseLabel(p)` looks up the next phase in their order rather than `currentPhase + 1`.
- Tap any player's track to open `showPlayerPhasesModal(playerId)` — full slot-by-slot list with cleared / current / locked states.
- The phasebook modal title notes "Twisted phases is on — each player works through their own randomized order."
- Game-over rule unchanged: first player to clear all 10 phases wins; ties broken by lowest total.

## Dealer tracking (optional)

Settings → "Track dealer" toggle. When on:

- Inline "Dealer" chip appears on the dealer's row
- After every commit, dealer rotates one seat to the left and a quiet toast announces it
- Settings modal exposes manual override (pick any player) + "Pass to next" button
- Dealer changes are pushed to the undo stack

## Modals

- **Phases** — official phase list. Headlines whether twisted is active.
- **Round history** — every round's entries, newest first, with cleared-phase markers.
- **Past games** — cross-game archive (last 50 finished games) with date, duration, winner pill, and standings podium. Includes "Clear all" with confirm.
- **Player phases** — opens on track click. Slot-by-slot view of one player's `phaseOrder` with cleared/current/locked states.
- **Settings** — dealer-tracking toggle + dealer override grid + rotate-now button.

All accessible from the topbar (book / clock / archive / cog icons).

## Persistence

| Key | Shape |
|----|----|
| `phase10.tracker.v1` | full state (auto-migrated for older saves) |
| `phase10.history.v1` | last 50 completed games |

Older saves missing `phaseOrder` / `twisted` / `dealerTracking` / `dealerIdx` are backfilled to defaults on load (standard order, dealer off).

## Keyboard

| Key | Action |
|----|----|
| `Enter` | Commit round |
| `Z` | Undo |
| `N` | New game |
| `T` / `M` / `?` | Theme / mute / shortcuts |
| `Esc` | Back to home |

The numeric inputs use `inputmode="numeric"` so mobile gets the native numpad. No custom keypad required.

## Undo

`pushHistory()` is called before each commit, dealer rotation, and settings change. The stack is capped at 50 entries. `undo()` pops the last snapshot and restores `players`, `round`, `rounds`, `gameOver`, `winnerId`, `dealerIdx`.

## Sounds

Uses the shared `SFX` library (defined in the Yahtzee module — kept module-level for reuse). Maps:

- Cleared phase → `SFX.full()`
- Going out at phase 10 → `SFX.yahtzee()` + 280-particle confetti
- Standard round commit → `SFX.toggle()`
- Per-digit add → `SFX.add(value)` when typing in the score field

## Sizing

Each row is ~56px. With ~36px topbar + ~36px panel header, 6-player rosters land around 460px — comfortable inside a 720px viewport on a 13" laptop at 100% zoom. The `.p10-main` grid is `align-items:start` so the left and right columns don't stretch each other vertically.
