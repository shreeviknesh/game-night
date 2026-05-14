# Design system

This is the canonical reference for the visual language, interaction patterns, and the things we explicitly *don't* do. The aesthetic was tuned across many iteration passes — including a deliberate "reduction pass" where decoration was traded for restraint.

## Design principles

1. **Subtraction over addition.** Every visual decision must justify its existence.
2. **Calm > clever.** No perpetual loops, no glow rings, no drift, no decoration without meaning.
3. **One signal per state.** Active rows get *one* accent — a tint, a rail, or a bar — not a stack.
4. **Editorial typography, not dashboard typography.** Sentence case, real weights, no uppercase-letter-spacing eyebrows.
5. **Player color supports hierarchy; it never owns the surface.** Used as small dots, thin underlines, soft tints — never as a fill.
6. **Motion communicates causality, not personality.** Reserve richer motion for celebrations.
7. **Mobile is not a compressed desktop.** Touch targets, native inputs, no hover-only affordances.
8. **The whole game must fit a 13" laptop viewport at 100% zoom.** No inner scrollbars, no zoom-to-fit. Each row, header, and panel is sized to a budget.

## Color tokens

All colors are CSS custom properties on `:root`. Each theme overrides them via `body[data-theme="…"]`.

### Default (Midnight)

| Token | Use | Value |
|----|----|----|
| `--bg` | Page base | `#0c0c10` |
| `--surface` | Primary chrome (panels, topbar, scorecard) | `#15151a` |
| `--surface-2` | Hover / row tint | `#1c1c22` |
| `--surface-3` | Pressed / segmented track | `#23232a` |
| `--border` | Hairline | `rgba(255,255,255,0.08)` |
| `--border-strong` | Emphasized hairline | `rgba(255,255,255,0.14)` |
| `--text` / `--text-2` / `--text-3` / `--text-4` | Solid greys (not opacity tricks) | `#ededf0` … `#3f3f47` |
| `--accent` | Single restrained accent (lavender) | `#a78bfa` |
| `--gold` | Winners, leaders | `#e0b86b` |
| `--green` | Cleared / safe / success | `#6ee7a8` |
| `--red` | Risk / no-score / sacrifice | `#f3a5a5` |

### Player palette

10 curated colors — desaturated, readable on dark. No rainbow, no neon.

```
lavender  #a78bfa   sky      #7dd3fc   sage     #86efac   amber    #fcd34d
rose      #fda4af   coral    #fdba74   teal     #5eead4   orchid   #f0abfc
sand      #d6c8a8   slate    #cbd5e1
```

## Typography

**One font family for everything.** SF Pro / Inter system stack.

The serif (`--font-serif`, NY/Charter) is reserved exclusively for the home hero italic phrase. Body, numerics, totals, modals — all sans.

### Type scale

Stick to these sizes. Don't introduce new ones.

| Use | Size | Weight |
|----|----|----|
| Hero (home only) | `clamp(28px, 3.4vw, 38px)` | 600, italic-mix |
| Section title | 17–18px | 600 |
| Body | 13–14px | 400–500 |
| Secondary | 12–12.5px | 400 |
| Numerics | match body, `font-variant-numeric:tabular-nums` | 500–600 |
| Tiny meta | 11–11.5px | 400 |

Letter-spacing: `-0.005em` for body, `-0.02em` to `-0.025em` for large numbers. **No positive letter-spacing** anywhere.

## Spacing rhythm

Multiples of 4. Pinned grid:

```
--s-1: 4   --s-2: 8   --s-3: 12   --s-4: 16
--s-5: 24  --s-6: 32  --s-7: 48   --s-8: 64
```

Use `clamp(small, vw-based, large)` for outer paddings so layouts breathe on widescreens but stay tight on phones.

## Radii

Two radii. That's the whole scale.

| Token | Value | Use |
|----|----|----|
| `--r-1` | 8px | Controls, chips, inputs, buttons, small cards |
| `--r-2` | 16px | Surfaces, panels, modals |

## Shadows

Almost everything is **flat with hairline borders**. There is one shadow token, used only for transient elevations (modals, toasts):

```
--shadow: 0 12px 32px rgba(0,0,0,0.45);
```

**Never** colored glow shadows. **Never** `box-shadow: 0 0 12px var(--pc-glow)` on dots, rails, or chips.

## Motion

Single curve for everything: `--ease: cubic-bezier(0.32, 0.72, 0, 1)`.

Default transition durations:

| Speed | Duration | Use |
|----|----|----|
| Snap | 100–140ms | Press states |
| Standard | 160–220ms | Hover, color, background |
| Settled | 240–340ms | View transitions, modal-in |

Things that should **never** animate:
- Player accent dots (no pulse, no glow loop)
- Active player rails or column tints (no shimmer)
- Brand mark (no hue rotation)
- Ambient blobs (none — page background is solid)
- Last-place scores (no wobble)
- Hero text on enter (no word-by-word reveal)

Things that *should* animate:
- View navigation (opacity-only fade)
- Score commits (one-shot pop)
- Cleared phase / Yahtzee (confetti + tone + check stamp)
- Cleared-toggle checkbox (color settle)
- Validation feedback when the user tries an invalid action — e.g. tapping a locked Phase 10 Commit triggers a 2.8s red box-shadow ripple on the offending rows. The action itself stays inert; the animation surfaces *which* rows are at fault.

## Active vs inactive states

Active player highlight uses *one* of these patterns, never multiple:

- Yahtzee scorecard column: a calm `color-mix(--pc 6%)` tint + an underline on the player head
- Yahtzee tray: thin 3×14px color rail beside the name
- Phase 10 row: dot + name (no extra rail unless it's the leader)

Avoid: side rails *plus* tinted bg *plus* glow ring. Pick one.

## Mode clarity

When a user might be confused about what they're looking at, surface it:

- Phase 10 right panel hero: "Round X" big number
- Each player row: phase chip + the rule text right next to it ("Phase 4 · 1 run of 7")
- Player phase track is a tappable button — `title` attribute reads "{name}'s phase order — tap for details"

No silent affordances. If something opens a modal on click, it should look clickable.

## Icons

Lucide-ish line icons, 1.6–2px stroke, 13–16px display size. Color is `currentColor`. Never colored icons except the gold trophy on the past-games archive.

## Surfaces

Solid surfaces only:

- Panels: `var(--surface)` with a `1px var(--border)` hairline
- Hover: `var(--surface-2)`
- Pressed / active: `var(--surface-3)`
- Modals: same `var(--surface)` over a translucent backdrop

**Never** `backdrop-filter: blur()`. **Never** multi-stop linear-gradient panel backgrounds.

## Scrolling

Page-level scroll only when needed. Inner panels never have their own scrollbars except modal lists (which have `max-height: 60vh`).

## Yahtzee scorecard cells

Three states, visually unmistakable:

- **Locked** — solid number, normal weight, full text color. Reads as data.
- **Preview** (active player + dice complete) — italic, dashed pill outline tinted by player color, soft player-tinted fill. Reads as "click to commit." No single preview is elevated above its peers — picking the play is the player's call.
- **Empty** — `·` middle-dot in `--text-4`. Reads as unfilled.

The grand-total row renders 1/2/3 medal pills in gold/silver/bronze whenever totals diverge. They appear during play, not just at game end — a running leaderboard.

Inline validation pattern (used by Phase 10 Commit and the setup-modal duplicate-name guard): the offending input gets a red bottom-border or dashed ring + a small red hint text. No popups, no toasts — the user fixes it in place.

## Roll Insights aesthetic

The Yahtzee tactical companion lives by these rules:

- **Opt-in.** Collapsed bar shows just "Roll Insights" + chevron — no spoilers. Users who don't want hints don't have to read them.
- **Small expanded.** ~140px max — no scroll, no dashboard.
- **Mood, not data.** Once expanded, a status dot maps to a tone (`strong`, `live`, `upside`, `safe`, `long`, `locked`, `sacrifice`). The phrase tells the story; the percentage is supporting.
- **Chips for alternatives.** Up to three near-miss options as compact chips. Tapping a chip swaps focus.
- **Plan-for segment.** Tiny rolls-left segmented control. Not a labeled slider, not a stepper.

Don't reintroduce: per-category cards, stat tiers, percentage bars per category, a "Stats for Geeks" header, dashboard grids, or surfacing the recommended play on the collapsed bar.

## Anti-patterns rejected over multiple iterations

These were tried and removed; don't bring them back without explicit user approval:

**Decoration**
- ❌ Hue-shifting brand mark animation
- ❌ Floating ambient blob drift (now: solid page background)
- ❌ Active-player pulse ring loop
- ❌ Leader gold-dot breathing
- ❌ Last-place 😭 wobble
- ❌ Suggested-cell glow pulse
- ❌ Hover-to-zoom on rows or cells
- ❌ Cursor-follow tonal spotlight on tiles
- ❌ Dice mini-roll on tile hover
- ❌ Word-by-word hero reveal animation
- ❌ Dot-ripple on hero meta

**Surfaces**
- ❌ `backdrop-filter: blur()` on chrome panels
- ❌ Multi-stop linear-gradient backgrounds on chrome
- ❌ Translucent rgba surfaces (use solid tonal layers)
- ❌ Decorative serif sprinkled across totals, modals, keypads
- ❌ Box-shadow glows around dots and chips
- ❌ Film-grain overlay

**Typography**
- ❌ Uppercase letter-spaced eyebrows on every label
- ❌ 18-color rainbow player palette (replaced with 10 muted)
- ❌ "Stats for Geeks" header (replaced by Roll Insights)

**Layout**
- ❌ Always-visible Roll Insights body (must collapse)
- ❌ Roll Insights collapsed bar leaking the recommended play (must be neutral until expanded)
- ❌ Auto-highlighted "suggested" preview cell on the scorecard (all previews look equally tentative)
- ❌ Inner-scrolling accordions for phasebook + history (now modals)
- ❌ Page-level vertical scrolling on Yahtzee or Phase 10 (sized to fit)
- ❌ Per-category stat cards in a 2-col grid (replaced by chips)
- ❌ Side rails + tint + glow stacked on the same active state

## Touch targets

Mobile minimum 36×36px tap target. Touch-only rules live in `@media (hover:none)`:

- Tiles drop their hover background
- Score input uses native `inputmode="numeric"`
- Toggles get bigger padding

## Themes

6 themes share the token contract above. Each theme bundles:

- Base colors
- Font family
- Dice material (gradient, shadow, pip color, radius)
- Audio voicing (oscillator type, harmonics, filter, reverb)

A theme is a coherent personality, not a color swap. Don't add a theme unless you can give it a real one.
