# Game Night

A premium, single-file score tracker for tabletop game night. Currently ships with **Yahtzee** and **Phase 10**.

No build step, no dependencies, no accounts. Open the HTML file in a browser and play.

## Quick start

Open `index.html` in any modern browser:

```sh
open index.html      # macOS
xdg-open index.html  # Linux
start index.html     # Windows
```

Or serve the folder if you prefer:

```sh
python3 -m http.server 8080 --directory .
```

State is autosaved to `localStorage` on the device. Closing the tab and re-opening picks up exactly where you left off.

## Games included

### Yahtzee
- 2–9 players, full official Hasbro scoring
- Joker rule + multi-Yahtzee bonuses, with auto-detected constraints
- "Hail Mary" house rule (once-per-game zero swap)
- Type dice via keypad or `1`–`6` shortcuts
- **Roll Insights** — a compact tactical companion that fits next to the tray. Collapsed by default (one-line label + chevron, no spoilers). Expand for the best-play card, near-miss chips, and the roll-planner segment. Powered by closed-form probability where possible, Monte Carlo otherwise.
- Preview cells in the active column are italic dashed pills — clearly tentative, never confused with locked scores. The grand-total row shows 1/2/3 pills in gold/silver/bronze whenever totals diverge.
- 6 themes (Midnight default, Retro 98, Casino, Cyberpunk, Gameboy, Newsprint) with theme-flavored audio
- PNG export of the final scorecard

### Phase 10
- 2–10 players
- **Round-based scoring** — every player's score for the round is entered inline on their roster row, then committed in one shot. No turn rotation pretense; matches how the game actually plays.
- **Round-validity gate** — Commit is disabled unless exactly one player goes out (0 pts + cleared) and every other non-finished player has a non-zero score. Inline hint explains why; tapping a locked Commit pulses the offending rows red.
- All ten official phases — the rule is shown next to the phase number on every row
- **Twisted Phases** variant — each player gets a randomized order of all ten phases. Tap any player's phase track to see their full per-slot order.
- Optional **dealer tracking** with auto-rotation each round (Settings → Track dealer)
- Round-by-round history modal + cross-game archive of completed games
- Quick-add chips (+5 / +10 / +15 / +25 / +50) for typical card values
- Native numeric input on mobile (`inputmode="numeric"`)
- Setup blocks duplicate player names with an inline hint (covers Yahtzee setup too)

## File map

```
game-night/
├── index.html               # The entire app (HTML + CSS + JS)
├── README.md                # You are here
└── docs/
    ├── DESIGN.md            # Visual + interaction design system
    ├── ARCHITECTURE.md      # State, router, modules, persistence
    ├── YAHTZEE.md           # Yahtzee module specifics
    ├── PHASE10.md           # Phase 10 module specifics
    ├── CHANGELOG.md         # Major iteration passes
    └── CONTRIBUTING.md      # Editing conventions
```

## Browser support

Targeting recent evergreen browsers (Safari 16.4+, Chrome 110+, Firefox 110+). Uses:

- `color-mix()` and CSS custom properties extensively
- `:has()` selector
- `localStorage`
- Web Audio API for synthesized SFX
- Web Share API where available; falls back to file download

## Keyboard shortcuts

Press `?` (or the help icon in the topbar) on any screen for a context-aware list. Common bindings:

| Key | Action |
|----|----|
| `Esc` | Back to home / close modal |
| `T` | Theme picker |
| `M` | Mute / unmute SFX |
| `?` / `/` | Keyboard cheatsheet |
| `Z` | Undo (in a game) |
| `N` | New game (in a game) |
| `Enter` | Commit round (Phase 10) |
| `1`–`6` | Add die value (Yahtzee) |
| `R` | Random fill (Yahtzee) |
| `H` | Hail Mary swap (Yahtzee) |

## Local data

The app writes to `localStorage`:

| Key | Purpose |
|---|---|
| `yahtzee.tracker.v1` | Current Yahtzee game |
| `yahtzee.history.v1` | Last 50 completed Yahtzee games |
| `yahtzee.settings.v1` | Roll Insights state (rolls-left default + open/closed) |
| `yahtzee.theme.v1` | Active theme (shared with Phase 10) |
| `yahtzee.sound.v1` | Mute state (shared with Phase 10) |
| `phase10.tracker.v1` | Current Phase 10 game |
| `phase10.history.v1` | Last 50 completed Phase 10 games |

Clearing site data resets everything.

## Updating the in-place copy in `~/Downloads`

If you've copied `index.html` to `~/Downloads/` on your Mac and you're playing from there, you can pull updates without losing saves — `localStorage` is keyed by file URL, so as long as the destination path is unchanged the existing games persist.

A handy shell alias:

```sh
alias gn-pull='scp clouddesk:/local/home/shreevks/game-night/index.html ~/Downloads/game-night.html'
```

Then: `gn-pull` from your local terminal, **Cmd-Shift-R** in the browser tab.

## License

Personal project. No warranty. Use however you like.
