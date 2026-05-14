# Yahtzee module

Hasbro-correct scoring with the Joker rule, multi-Yahtzee bonuses, and the optional Hail Mary house rule.

## Game flow

1. Setup: 2–9 players, each picks a name and a color.
2. On each turn the active player physically rolls 5 dice. The user types the resulting dice into the keypad on the tray.
3. With 5 dice entered, every open category shows a live preview score in that player's column. Tap one to commit.
4. Score commits flash, advance the turn, reset the dice.
5. Game ends when every player has filled all 13 categories. The winner modal shows the podium with PNG export.

## Scoring engine

`scoreFor(catKey, dice, player)` is a pure function:

| Category | Logic |
|----|----|
| Ones–Sixes | `count(face) × face` |
| 3 of a Kind / 4 of a Kind | sum of all dice if any face has count ≥ 3 / 4, else 0 |
| Full House | 25 if exactly one triple + one pair, else 0 |
| Small Straight | 30 if any 4 consecutive, else 0 |
| Large Straight | 40 if all 5 consecutive, else 0 |
| Yahtzee | 50 if all 5 dice match, else 0 |
| Chance | sum of all dice |

### Joker rule

When the dice are a Yahtzee *and* the player has already filled the Yahtzee box (with 50 OR 0):

1. If the matching upper-section box is open, the player **must** use it (and scores `5 × face`).
2. If that upper box is filled, the player picks any open lower-section box, which scores **full fixed value**: 25 / 30 / 40 / chance-sum.
3. If both are filled, the player must zero an open upper-section box.

`jokerConstraint(dice, player)` returns one of `{require: key}` / `{choose: [keys]}` / `{force0: [upperKeys]}` and the renderer disables non-matching cells.

### Multi-Yahtzee bonus

Per official rules: each Yahtzee *after* the first scores **+100**, but only if the original Yahtzee box was 50. A zeroed Yahtzee forfeits all subsequent bonuses. `bonusOnCommit(catKey, dice, player)` returns whether the next commit triggers a +100 stack.

## Hail Mary house rule

Once per game, a player can swap a category that's currently 0 to another empty category (preserving the 0). Practical effect: free a category that was zeroed out for a worse-luck consolation slot. The flow is two-stage:

1. Click "Hail Mary" → enters source-pick mode (zeroed cells become tappable).
2. Click the source 0 → enters target-pick mode (empty cells become tappable).
3. Click a target → state mutates: source becomes empty (re-rollable), target becomes 0, `hailMaryUsed = true`.

Once used per player. Toggleable, undoable.

## Roll Insights

The compact tactical companion that lives next to the dice tray. Replaces the older "Stats for Geeks" panel.

### Collapsed (default, ~38px)

A single neutral line: just the label "Roll Insights" + chevron. The collapsed bar deliberately does **not** leak the recommended play — users opt in by expanding. The mood dot, phrase, and odds only render once the panel is open.

(Earlier builds surfaced the headline phrase like `● Large Straight live · 62%` on the collapsed bar. That was rejected as a tactical spoiler — the panel exists for users who want hints, not for ones who don't.)

### Expanded (~140px)

- **Best card**: category name, a slim mood-tinted progress bar, value to the right, odds line below
- **Near-miss chips**: up to three alternative categories. Tapping a chip swaps the focus and updates the bar live.
- **Plan-for segment**: tiny rolls-left selector (`2 rolls / 1 / 0`) that re-runs the math.

### Mood mapping

`computeInsight()` reduces `computeStats` results into a single `{focus, mood, phrase, value, odds, others, exact}` object. The mood drives the dot + bar tint:

| Mood | Color | Triggers |
|----|----|----|
| `strong` | green | binary category with odds ≥ 60% |
| `safe` | green | variable category with `pNonzero ≥ 70%` |
| `locked` | green | `rollsLeft === 0` and value > 0 |
| `live` | lavender | binary 30–60%, or fallback variable |
| `upside` | lavender | variable EV ≥ 25 |
| `long` | gold | binary 10–30% (long shot) |
| `sacrifice` | red | only zero options remain |

### Lock semantics (critical)

Typed dice are the **current roll state**, not held permanently. The optimal strategy may reroll any of them. Specifically:

- 0 rolls left → deterministic score.
- N rolls left → typed dice can be rerolled N times; empty slots get an initial roll first, so they have N+1 chances.

Earlier versions assumed typed dice were locked. That was rejected — strategy couldn't optimize away bad dice. Don't bring it back.

### Closed-form vs. Monte Carlo

| Category | Method |
|----|----|
| Upper section | Closed-form binomial convolution |
| Yahtzee | Closed-form (single best face → all match) |
| Full House / Small / Large | Monte Carlo binary outcome (4000 trials) |
| 3 / 4 of a Kind | Monte Carlo distribution over sums |
| Chance | Dropped — trivially "EV ≈ 22–24" provides no signal |

## Themes

6 themes, each bundling colors + font + dice material + audio voicing:

| ID | Vibe |
|----|----|
| (default) `midnight` | Cool dark with subtle blue undertone, warm lavender accent |
| `retro98` | Windows 98 chrome, MS Sans Serif, hard 2px shadows |
| `casino` | Emerald felt + gold leaf, Playfair Display |
| `cyberpunk` | Deep violet night sky, magenta + cyan accents |
| `gameboy` | Lavender plastic shell + green LCD panels, VT323 |
| `newsprint` | Cream paper, Iowan Old Style serif, ink-on-paper |

A theme is a coherent personality, not a color swap. See `DESIGN.md`.

## Persistence

| Key | Shape |
|----|----|
| `yahtzee.tracker.v1` | full game state |
| `yahtzee.history.v1` | last 50 finished games (date, winner, full scorecard) |
| `yahtzee.settings.v1` | `{statsRollsLeft, statsPanelOpen}` (Roll Insights) |

Theme and mute state are shared with Phase 10 (`yahtzee.theme.v1`, `yahtzee.sound.v1`).

## Export

`exportFinalCard()` renders the final game state to a `<canvas>` PNG (header brand, podium, full scorecard table, gold-tinted grand total row, footer with Hail-Mary attribution if any). Mobile uses Web Share API when available; desktop triggers a download.

## Category labels

Each category row's left column shows the name *and* the scoring rule, right-aligned in a muted tone:

```
Ones                         sum of 1s
Three of a Kind         sum of dice
Full House                          25
Yahtzee                              50
```

This avoids users having to translate "what's a Full House score?" mid-play.

## Scorecard cell visuals

Three distinct states, deliberately easy to tell apart at a glance:

- **Locked** (committed score) — solid number, normal weight, `--text` color. Looks like data.
- **Preview** (active player, dice complete, allowed by Joker) — italic, dashed-pill outline tinted by player color, muted fill. Looks tappable and tentative; never elevated above its peers (no "suggested" highlight).
- **Empty** — `·` middle-dot in `--text-4`. Looks unfilled.

The grand-total row also renders 1/2/3 medal pills (gold/silver/bronze) when at least two distinct totals exist. They appear during play — not just at game end — so the row reads as a running leaderboard.

## Sanity checks

- `addDieValue(v)` rejects non-integer or out-of-range values silently. `1`–`6` keys remain the canonical input path.
- `commitScore(catKey)` requires `diceComplete()`, blocks double-commits and Joker-forbidden cells with an inline toast + `SFX.invalid()`.
- `cancelHailMary()` is safe to call at any point in the flow — source/target are only mutated atomically inside `selectHailMaryTarget()`.
