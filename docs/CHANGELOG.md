# Changelog

The project evolved across many iteration passes — this log captures the major ones.

## v5.2 — Sanity checks + scorecard polish (current)

- **Yahtzee scorecard medals restored.** The grand-total row now shows a 1/2/3 pill in gold/silver/bronze whenever distinct totals exist. Useful as a running leaderboard, not just at game end. (The old pip was a `display:none` casualty of the v4 reduction.)
- **Yahtzee preview cells reskinned.** Score previews on the active player's column are now italic, dashed-pill outlines tinted by player color — clearly tentative, never confused with locked scores. Removed the auto-highlight on the highest-scoring preview; picking the play is the player's call, not the engine's.
- **Roll Insights collapsed by default.** The 1-line bar no longer leaks the recommended play. Collapsed shows just the label "Roll Insights" and the chevron; expanded reveals mood dot + phrase + odds as before. Saved state preserved.
- **Yahtzee dice bounds.** `addDieValue` now silently rejects non-integers and out-of-range values (1–6). Hail Mary cancel verified safe (no half-applied mutations between start and cancel).
- **Phase 10 round-validity gate.** Commit Round is now disabled unless the round is well-formed: at most one player may go out (0 pts + cleared), and every other non-finished player needs a non-zero score. Inline hint underneath the disabled button explains why ("Each remaining player needs a score above 0" / "Only one player can go out per round" / "Enter scores or mark who went out"). Tapping a locked Commit pulses a red ring on the offending rows for ~2.8s — two ripples, long enough to actually look at.
- **Phase 10 Commit now flushes focused inputs.** Tapping Commit while still focused on a score field can no longer drop the just-typed value — the field is blurred first so its `input` handler flushes.
- **Setup: duplicate-name guard.** Identical player names (case-insensitive) get caught at confirm time. Offending rows show a red bottom border + "Name already in use" hint. Editing the name clears the error live. Covers both Yahtzee and Phase 10 setup.
- **Phase 10 dealer-idx clamp.** A malformed save with `dealerIdx >= players.length` no longer crashes rendering — clamped on `loadState`.
- **Snapshots directory removed.** `v1.html`, `v2.html`, `yahtzee-standalone.html` are no longer carried in the working tree (history lives in the external git repo). README file map and CHANGELOG snapshot table pruned to match.
- **Doc-sync infrastructure.** New `CLAUDE.md` at the repo root maps each kind of change to the markdown files that document it (e.g. visual changes → `DESIGN.md`, Phase 10 internals → `PHASE10.md`). New `.claude/settings.json` Stop hook nudges future Claude sessions to verify docs are in sync before ending a turn. `CONTRIBUTING.md` cross-links to both.

## v5.1 — Theme tune-up

- **Cricket theme removed.** Six themes now: Midnight, Retro 98, Casino, Cyberpunk, Gameboy, Newsprint. Saved cricket preferences fall back to Midnight.
- **Newsprint repaired** on the home tiles and across all screens — it had been written against the v3 token contract and broke in v4. Solid paper-tone surfaces, restrained newspaper-red accent, italic em in the hero phrase.
- **Midnight refined.** Subtle deep-blue undertone (`#0a0c14` page) with a warm lavender accent for chromatic tension. Borders pick up a faint blue tint.
- **Cyberpunk rewritten.** Solid violet surfaces, no animated drift, no scan lines, no glow rings on chrome. Cyan-tinted pips on dark dice + cyan italic hero are the signature.
- **Roll Insights bug fixes.** Collapse now actually hides the body (the `[hidden]` attribute was being overridden by a `display:flex` rule — switched to a `.open` class as the single source of truth). Selecting a near-miss chip preserves the original best as the first chip in the strip, marked with a small accent dot, so users can return.

## v5 — Roll Insights + viewport fit

- **"Stats for Geeks" → Roll Insights.** Replaced the dashboard-feeling stats panel with a compact tactical companion. Collapsed: a one-line headline ("Large Straight live · 62%"). Expanded: ~140px card with mood-tinted progress bar, near-miss chips (tap to swap focus), and a tiny rolls-left segment. All the underlying probability math is unchanged.
- **Viewport-fit constraint.** Sized every page so a 13" MacBook at 100% browser zoom never needs to scroll. Tighter row heights, tighter topbar, tighter section dividers. Each row, header, panel padded against a calculated budget.
- **Phase 10 row redesign.** Single horizontal line: dot + name + `Phase X · rule` in muted text under the name + slim 10-step track + cleared toggle + score input + running total. Long phase rules fit because the head column has a 220px min-width.
- **Yahtzee category labels.** Each row now displays the scoring rule next to the name (`Three of a Kind · sum of dice`, `Full House · 25`, etc.), so users don't have to translate "what's a Full House score?"
- **Per-player phase popup.** Tap any phase track to see that player's full slot-by-slot order — useful in twisted mode.
- **Past games archive.** New topbar icon surfaces previously-saved completed games (was persisted, never reachable).
- **Twisted Phases mode.** Setup-time toggle. Each player gets a random permutation of all 10 phases.
- **Dealer tracking.** Optional setting. Rotates each round, manual override + rotate-now in settings.
- **Distinct view separation.** Views can no longer stack — `display:none !important` enforced because `.home` had its own `display:flex` that leaked through.

## v4 — Reduction pass

- 5 radii → 2 (`--r-1: 8px`, `--r-2: 16px`).
- 3 shadows → 1.
- 4 ease curves → 1 (`--ease`).
- 2 accent variants → 1.
- Translucent rgba surfaces → 4 solid tonal layers.
- Opacity-based text colors → 4 solid greys.
- All `backdrop-filter: blur()` removed (22 occurrences).
- Multi-stop gradient backgrounds on chrome panels removed.
- Brand mark gradient + inner radial highlight → flat surface tile.
- Tile art gradient + inset highlight → flat surface tile.
- Ambient blobs (animated drift) → solid page background.
- Film-grain overlay removed.
- Decorative serif sprinkled across totals/modals/keypads → reserved for the home hero only.
- Sentence-case sweep of remaining uppercase metadata.
- Tiny 9–11px labels bumped to 12–13 with regular weight.
- Hero word-by-word reveal animation removed.
- Phase 10 row goal text removed from default rows (still in popups + phasebook).
- Phase 10 row → bordered hairline list inside panel.
- Side panel → vertically stacked label/value rows separated by hairlines.

## v3 — Round-based Phase 10 + restraint pass

- **Phase 10 model fixed**: was per-player turn rotation, now round-based — every player has an inline entry on their row; "Commit round" applies all entries at once.
- **All players visible at all times**: no click-to-expand. Each row shows track + entry inline.
- **Phasebook + round history → modals**: removed inline accordions that pushed the panel into awkward scrolls.
- **Symmetric right panel.**
- **Twisted Phases.**
- **Per-player phase popup.**
- **Past games archive.** (surfaced UI for previously-persisted history)
- **Dealer tracking.**

## v2 — Refinement / restraint

- Cut typography to ~3 sizes and 2 weights. Serif reserved for the home hero only.
- Stripped uppercase letter-spaced metadata across the entire app.
- Curated player palette down from 18 rainbow colors to 10 muted tones.
- Removed every perpetual decorative animation.
- Active-state highlights consolidated to one signal per state.
- Removed cursor-spotlight on tiles, dice-randomize-on-hover, dot-ripple.
- Mobile-first audit: bigger touch targets, native numeric inputs, `@media (hover:none)` rules, stacked layouts.

## v1 — Cohesive multi-game build

- Wrapped the standalone Yahtzee tracker into a "Game Night" shell with home + view router.
- Built Phase 10 from scratch as a second module (originally turn-based; refactored later).
- Generalized setup modal to handle Yahtzee (max 9) and Phase 10 (max 10).
- Single-file HTML preserved; no build step.
- Persistent theme + mute shared across both games.

## v0 — Standalone Yahtzee tracker

- Original `yahtzee-tracker.html` standalone build (history retained in the external git repo; was previously archived in-tree as `snapshots/yahtzee-standalone.html` until v5.2).
- Full Hasbro scoring, Joker rule, multi-Yahtzee bonuses, Hail Mary house rule.
- 7 themes (Midnight, Retro 98, Casino, Cricket, Cyberpunk, Gameboy, Newsprint).
- Web Audio synthesized SFX with theme-flavored voicing.
- Closed-form expected-value stats panel ("Stats for Geeks" — later replaced by Roll Insights).
- PNG export of the final scorecard.
- Game history (last 50) + confetti celebrations.
