# Game Night

A premium, single-file score tracker for tabletop game night. Currently ships with **Yahtzee** and **Phase 10**.

No build step, no dependencies, no accounts. Serve the file over HTTP and play.

## Quick start

The app needs to be reached over `http(s)://` (the Supabase fetch is blocked
on `file://`). Two easy options:

```sh
python3 -m http.server 8080 --directory .   # open http://localhost:8080
```

Or push the repo to GitHub Pages — `https://USER.github.io/game-night/`
works as-is. The app degrades gracefully to localStorage-only if you
haven't configured a Supabase project yet, so it's playable from the moment
you open it.

State is saved to a Supabase Postgres database keyed by a short share code.
A localStorage cache backs the first paint and keeps the current game
playable offline; failed writes queue and retry on reconnect.

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
├── .gitignore               # Excludes .claude/settings.local.json, .env*, scratch files
├── supabase/
│   └── schema.sql           # Postgres schema + RPCs (run once in SQL editor)
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

## Data storage

Game state lives in Supabase Postgres (one `games` table, keyed by share
code). A localStorage cache backs the first paint:

| Key | Purpose |
|---|---|
| `gn.cache.<code>` | Per-game cache (state + rev) |
| `gn.current.yahtzee` / `gn.current.phase10` | Active code per game |
| `gn.codes.v1` | Every code this device has touched |
| `gn.queue.v1` | Offline write queue |
| `gn.migrated.v1` | One-shot migration flag |
| `yahtzee.theme.v1` | Active theme (shared with Phase 10) |
| `yahtzee.sound.v1` | Mute state (shared with Phase 10) |
| `yahtzee.settings.v1` | Roll Insights state (rolls-left default + open/closed) |

Clearing site data on this device only loses cache + UI prefs — game data
is recoverable via the share URL.

## Setting up Supabase

The app works with `SUPABASE_URL` / `SUPABASE_ANON_KEY` left as `null`
(localStorage-only mode). To enable cloud sync:

1. Create a free Supabase project.
2. Run `supabase/schema.sql` in the SQL editor.
3. Copy `Project URL` + `anon public` key into the constants near the top
   of the `<script>` block in `index.html`.
4. In Supabase → Auth → URL Configuration, add the origin you serve from
   (e.g. `https://USER.github.io`) to the allowed list.

The anon key is safe to ship in the HTML — RLS revokes direct table
access, and the four `security definer` RPCs are the only attack surface.

## Sharing games

Each new game gets a 6-character share code (e.g. `XK7P-2M`) and stamps
the URL as `#g/XK7P-2M`. A topbar button copies the link. Anyone with the
URL can view + edit — no accounts.

## License

Personal project. No warranty. Use however you like.
