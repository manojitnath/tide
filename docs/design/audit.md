# Design audit

Scope: the `<style>` blocks in `src/panel.html`, `src/dashboard.html` and `src/island.html`. Values below are the final cascade (a declaration that is overridden later is not counted twice). Widths, heights, transforms, animations and grid columns are outside this audit except where they set type, colour, radius, spacing or a shadow. Browser-preview-only rules are marked **preview**.

Abbreviations: **P** = panel, **D** = dashboard, **I** = Island.

## 1. Text

Line height is shown as written. `font: 600 16px` means `line-height: normal`; a rule that only sets `font-size`/`font-weight` inherits the page body leading (1.35 on P/I, 1.4 on D) unless another rule sets it.

### 1.1 Existing combinations

| Size | Weight | Leading | Where |
|---:|---:|---|---|
| 52 | 600 | 1.05 | P `.time` (timer) |
| 44 | 600 | 1.05 | P `.time.long` (long timer) |
| 40 | 700 | 1.1 | D `.lvl b` (level name) |
| 34 | 600 | 1.1 | D `.card b` (stat value) |
| 30 | 600 | 1.1 | D `h1` (page title) |
| 26 | 700 | 1.1 | D `.sk b` (streak count) |
| 26 | 700 | normal | D `.big b` (daily goal value) |
| 20 | 800 | normal | D `.streakchip b` (streak chip) |
| 19 | 700 | 1.15 | I `h1` (Island title) |
| 19 | 700 | 1.1 | P `.trow b` (streak count) |
| 19 | 700 | normal | D `.sheetcard h2` (edit dialog title) |
| 18 | 600 | normal | D `.ph h2` (card title) |
| 17 | 700 | normal | P `.goalrow b`; D `.dcenter b` (goal and donut values) |
| 17 | 580 | 1 | D `.wstep button` (week arrows, glyph) |
| 16 | 600 | normal | P `.duo button`, `.ask h2` (question title) |
| 16 | 580 | 1 | D `.del`, `.radioBtn.del` (× glyph) |
| 15 | 700 | normal | P `.greet b`; I `.btns button` |
| 15 | 580 | normal | I `input` |
| 14 | 700 | normal | P `.timecard .fchip` (streak chip number) |
| 14 | 700 | 1.1 | D `.sk b span` (DAYS unit) |
| 14 | 600 | normal | D `.group h3` (settings group title), `.sheetcard input` |
| 14 | 580 | 1.35 (inherited) | P `.ask input` |
| 13.5 | 700 | 1.3 | D `.bgrid .bd::after` (unlocked badge label) |
| 13.5 | 600 | normal | D `.catName`, `.catNameInput` |
| 13.5 | 580 | body | D `.title p`, `.card small`, `.lvl small` |
| 13 | 600 | normal | D `.radioName`, `.radioNameInput`, `.radioFields input`, `.catAdd input` |
| 13 | 600 | body | D tabs/range buttons, `.menu .apply`, `.btn`, `.set b`, `.radioAddTitle`, `td.t`, `.wstep span`, `.catTopicName` |
| 13 | 700 | body | D `.toast button`, checked menu item checkmark |
| 13 | 580 | body | D body text, `td`, `.empty`, `.menu button`, `.toast`, `.sheetcard .mins span` |
| 13 | 580 | 1 | D `.radioBtn` |
| 13 | 580 | 1.35 | P body, I body |
| 12.5 | 700 | body | D `.bgrid .bd b` (badge name) |
| 12.5 | 600 | body | D `.tlist .tn`, `.radioRestore`, `.catShowAll`, `.streakchip span`, `.cgName` |
| 12.5 | 580 | body | D `.ph span`, `.set span`, `.big span`, `.sheetcard > p` |
| 12 | 700 | 1.1 | P `.trow b span` (DAY unit) |
| 12 | 700 | body | P `.goalrow em`; D `.lvl em`, `.sheetcard label` |
| 12 | 600 | 1.35 | P `.state` |
| 12 | 600 | normal | P `.goalrow b span` |
| 12 | 600 | body | D `.card span`, `.radioErr.info`, `.catGoal`, `.sk em` |
| 12 | 580 | 1.35 | P `.chips button`; I `.chips button` |
| 12 | 580 | body | D `.menu .dates label`, `.lweek`, `.vac`, `.lvl span`, `.sheetcard .hint` |
| 12 | 400 | normal | D `.set code` (`ui-monospace` log folder) |
| 11.5 | 700 | body | D `.bd::after`, `.cgDone` |
| 11.5 | 600 | 28px | D `.tllabel` (timeline block label) |
| 11.5 | 600 | body | D `.cgMeta` |
| 11.5 | 580 | 15px | P `.progmeta` (progress line) |
| 11.5 | 580 | 1.35 | P `.ptxt small`, `.greet span` |
| 11.5 | 580 | body | D `.yax span`, `.legend`, `.xax span`, `.tlist .tv`, `.catTopicsHead span` |
| 11 | 700 | 1.5 | P `.askCatChip`; D `.catChip` |
| 11 | 700 | body | D `.fbars i span`, `.sk small` |
| 11 | 600 | body | D `th` |
| 11 | 580 | 1.15 | D `.yax .avgLabel` |
| 11 | 580 | body | D chart/timeline tooltips, `.hlab`, `.tlhour`, `.fbars small`, `.week small` |
| 10.5 | 700 | 1.35 | P `.trow small`, `.goalrow small` |
| 10.5 | 700 | body | D `.catTopicsHead b` |
| 10.5 | 580 | body | D `.dcenter span` |
| 10 | 700 | 1.5 | D `.badge`, `.set .badge` |
| 10 | 700 | 1.35 | P `.askCats > span` (Category label) |
| 9.5 | 600 | 1.4 | P `.stations button .badge` |
| 9.5 | 580 | 1.35 | P `.wk .d > small` (weekday letters) |

Letter-spacing values: `-.01em` (P timer and duo buttons, D titles and donut value), `.06em` (P unit label, D table headers and streak unit), `.08em` (P labels, D card labels/group headers), `.1em` (D Topics label and streak label), `0` (D group titles and card labels after overrides).

### 1.2 Proposed type scale

The scale keeps the existing display/metric sizes, which are part of the product's character. It collapses the many half-steps into named sizes and separates size from weight and leading.

| Token | Value | Role |
|---|---|---|
| `--text-display` | 52 | panel timer |
| `--text-display-sm` | 44 | long timer |
| `--text-metric-lg` | 40 | level name |
| `--text-metric` | 34 | dashboard stat value |
| `--text-title` | 30 | page title |
| `--text-metric-sm` | 26 | streak and daily-goal values |
| `--text-heading` | 18 | card titles, dialog titles |
| `--text-subheading` | 15 | group titles, question title, greeting, buttons |
| `--text-body` | 13 | body text, names, inputs |
| `--text-small` | 12 | secondary text and metadata |
| `--text-caption` | 11 | labels, table headers, chips |
| `--text-micro` | 10 | badges and micro labels |

Weights become `--weight-regular: 580`, `--weight-semibold: 600`, `--weight-bold: 700`, `--weight-heavy: 800`. No element changes weight.

Leading tokens: `--leading-none: 1`, `--leading-display: 1.05`, `--leading-tight: 1.1`, `--leading-heading: 1.2`, `--leading-snug: 1.3`, `--leading-body: 1.4`. The 15px progress line and 28px timeline label stay fixed component line heights. Tracking becomes `--tracking-tight: -.01em` and `--tracking-wide: .08em`.

### 1.3 Type changes (old → new)

| Old | New | Where |
|---:|---|---|
| 9.5 | 10 micro | P station badge; P weekday letters |
| 10.5 | 10 micro | P STREAK/FOCUS GOAL labels; D donut caption, Topics label |
| 11.5 | 11 caption | P progress line, station sub line, greeting sub; D axis/legend/topic values, Topics right label, timeline label, badge tooltip, category meta and Done |
| 12.5 | 12 small | D card headings, settings descriptions, Topics rows, radio restore, Show all, badge names, streak chip, goal/level sub lines, category names, edit dialog description |
| 13.5 | 13 body | D page description, stat labels, level caption, badge label, category names and inline editor |
| 14 | 13 body; 15 subheading for D `.group h3` | P question input, streak chip number; D edit input, DAYS unit, settings group title |
| 16 | 15 subheading | P question title, question buttons; × glyphs stay 16 component-specific |
| 17 | 18 heading | P goal value; D donut value; week arrow glyphs stay 17 component-specific |
| 19 | 18 heading | P streak value, D edit dialog title, Island title |
| 20 | 18 heading | D streak chip number |
| 24 | — | overridden by 34 in the current cascade; no effective value |
| 18, 15, 13, 12, 11, 10 | unchanged | heading, subheading, body, small, caption and micro tokens above |
| 26, 30, 34, 40, 44, 52 | unchanged | metric, title and display tokens above |

Leading changes: P/I body 1.35 → 1.4; Island title 1.15 → 1.2; chips/badges 1.5 → 1.4; the `--leading-snug` 1.3 badge tooltip stays. Tracking changes: `.1em` and `.06em` become `.08em`; `0` and `-.01em` stay.

## 2. Colour

### 2.1 Existing variables

The three pages already share most of their colour vocabulary, but P and D keep separate copies and I has no colour variables.

| Role | Light | Dark | Used by |
|---|---|---|---|
| `--bg` | P gradient `#f7f8fc → #eceff6`; D `#eaeef6` | P `#161616`; D `#121212` | page backgrounds |
| `--ink` | `#16181d` | `#f2f2f2` | P, D text |
| `--muted` | `#6b7183` | `#8a8a8a` | P, D secondary text |
| `--line` | `rgba(20,40,90,.08)` | `rgba(255,255,255,.08)` P; `.07` D | borders and dividers |
| `--soft` | `#eef2fb` | `#262626` | D subtle surfaces |
| `--field` | `#eef2fb` | `#2a2a2a` | P fields; D field/track |
| `--card` | `#fff` / gradient | `#1c1c1c` / gradient | P, D cards |
| `--cardFill` | `#fff → #f6f7fb` | `#202020 → #1a1a1a` | D cards and controls |
| `--accent` | `#1f5cf2` | `#3a73ff` | P, D, I primary |
| `--accentFill` | `#3a72ff → #1f5cf2` | `#4a7fff → #2f66f0` | D primary controls |
| `--pill` / `--pillInk` | `#1f5cf2` / `#fff` | `#3a73ff` / `#fff` | D selected pills |
| `--tagInk` | `#fff` | `#121212` | P/D state and pastel tags |
| `--pReady`, `--pFocus`, `--pBreak` | `#fbf0d9`, `#d6e6fd`, `#e5f5cd` | `#1f1f1f` each | P timer card |
| `--tReady`, `--tFocus`, `--tBreak` | `#4c3b19`, `#0f2b4f`, `#21400f` | `#f4d38f`, `#9ec2ff`, `#b4e38a` | P state text/tag |
| `--timeInk` | `var(--tag)` | `var(--ink)` | P timer text |
| `--glow` | state RGB triplets | state RGB triplets | P timer and D card glows |
| `--sheen` | white sheen | white 3% sheen | P, D cards |
| `--bevel` | beveled card shadow | beveled card shadow | P cards |
| `--chip` / `--chipShadow` | white chip gradient / shadow | dark chip gradient / shadow | P chips and icons |
| `--track`, `--trackBg` | inset track / white 70% | inset track / white 8% | P progress, volume, bars |
| `--pBlue`, `--pGreen`, `--pCream` | `#d6e6fd`, `#e5f5cd`, `#fbf0d9` | `#1c1c1c` each | D pastel stats |
| `--tBlue`, `--tGreen`, `--tCream` | `#0f2b4f`, `#21400f`, `#4c3b19` | `#9ec2ff`, `#b4e38a`, `#f4d38f` | D pastel tags |
| `--blue`, `--blueShadow` | `#1f5cf2` | `#2f66f0` | D level card and first stat |
| `--purpleFill` | `#a07dff → #8a5cf6` | `#a888ff → #8f68f5` | D Focus week bars |
| `--shadow` | D card shadow | D card shadow | D cards, menus, controls |
| `--track` | inset track | inset track | P/D progress tracks |

`Game.PALETTE` (in `src/game.js`) is already the single source for the 10 topic/category colours: `#1f5cf2`, `#8a5cf6`, `#2fae5a`, `#e0a23a`, `#e8336b`, `#1fa9d6`, `#ff7a3d`, `#5a6a86`, `#16a3a3`, `#c2410c`. It is not duplicated in CSS.

### 2.2 Literal colours outside variables

| Value | Where | Proposal |
|---|---|---|
| `#0a0a0a` | P preview dark backdrop | preview-only, stays local |
| `#0e2a12` | P/D checkmark ink on green | `--on-success` |
| `#161616` | P dark menu/background; I dark logo | `--bg` dark |
| `#16181d` | P light state text; D tooltip and bar-label background | `--ink` / `--tooltip-bg` |
| `#1c1c1c` | P player background; I dark card | `--player-bg` / `--card` dark |
| `#1d1d1f` | D toast background | `--toast-bg` |
| `#1f5cf2` | P light timer, primary gradients; I card/logo/button | `--accent` |
| `#232323` | P dark station list | `--menu-bg` |
| `#2fae5a` | P/D success checks, rings, done gradients | `--success` |
| `#333` | P cover placeholder | `--media-bg` |
| `#34c759` | D switch on | `--switch-on` |
| `#3a3a3e` | D locked badge background, dark | `--locked-bg` |
| `#3a72ff` | P/D/I primary gradient start | `--accent-fill` |
| `#4a5068` | D locked badge ink, light | `--locked-ink` |
| `#5b8cff` | P progress bar gradient end; D week bar start | part of `--accent-fill` / bar recipe |
| `#5fd068` | P done-day gradient start | part of `--success-fill` |
| `#6ad874` | D done-streak gradient start | part of `--success-fill` |
| `#6cc4f7`, `#9bd6f8` | I preview backdrop | preview-only, stays local |
| `#9ec2ff` | D toast Undo link | `--toast-link` |
| `#bdea92` | P light break tag | state token |
| `#c2dcff` | P light focus tag | state token |
| `#c3c8d4` | D locked badge background, light | `--locked-bg` |
| `#c9c9cf` | D locked badge ink, dark | `--locked-ink` |
| `#dde5f8` | P preview backdrop | preview-only, stays local |
| `#e5484d` | D form errors | `--danger` |
| `#eef1f7` | P light menu | `--menu-bg` |
| `#eef3ff` | I primary button gradient end | primary button recipe |
| `#f6cf7e` | P light ready tag | state token |
| `#ff4d2e` | P/D streak flame gradient end | `--flame-end` (SVG) |
| `#ffb347` | P/D streak flame gradient start | `--flame-start` (SVG) |
| `#fff3c4` | P/D flame inner highlight | `--flame-core` (SVG) |
| `#ff3b30` | D delete hover | `--alert` (value changes to `#ff453a`) |
| `#ff453a` | P quit hover/live dot | `--alert` (live dot uses `--live` alias) |
| `#fff` | text on accent/gradient cards, chips, Island, switch knob | `--on-accent` / `--tagInk` / `--white` |
| `rgba(10,15,30,.28)` | D dialog scrim | `--scrim` |
| `rgba(128,128,128,.35)` | D scrollbar thumb | `--scrollbar` |
| `rgba(20,40,90,.07)` | P light control hover | part of shared button recipe |
| `rgba(20,40,90,.14)` | P light volume track | part of volume recipe |
| `rgba(240,244,252,.7)` | P light player glass | part of player recipe |
| `rgba(255,255,255,.04)` | I dark card gradient | part of Island card recipe |
| `rgba(255,255,255,.045)` | P/I ring pattern | part of card ring recipe |
| `rgba(255,255,255,.06)` | P/I ring pattern | part of card ring recipe |
| `rgba(255,255,255,.07)` | P light timer rings; I dark input; D first card rings | part of card/input recipes |
| `rgba(255,255,255,.08)` | I dark chip background | part of chip recipe |
| `rgba(255,255,255,.12)` | P light timer rings, control hover; D first card/level rings; I chip hover | part of card/button recipes |
| `rgba(255,255,255,.14)` | P light timer gradient; D first card/level rings; I input | part of card/input recipes |
| `rgba(255,255,255,.15)` | I dark chip hover | part of chip recipe |
| `rgba(255,255,255,.16)` | P light timer rings; D first card/level rings; I card rings/chips | part of card/chip recipes |
| `rgba(255,255,255,.2)` | D first stat tag, level next pill | part of tag recipe |
| `rgba(255,255,255,.22)` | P volume track | part of volume recipe |
| `rgba(255,255,255,.25)` | P light progress track; D XP track | part of progress recipe |
| `rgba(255,255,255,.26)` | I light chip hover | part of chip recipe |
| `rgba(255,255,255,.5)` | P light player surface | part of player recipe |
| `rgba(255,255,255,.6)` | P player gradient; I input placeholder | part of player/field recipes |
| `rgba(255,255,255,.65)` | I dark description | `--on-dark-muted` |
| `rgba(255,255,255,.78)` | P light progress meta | `--on-accent-muted` |
| `rgba(255,255,255,.8)` | I light description | `--on-dark-muted` |
| `rgba(255,255,255,.82)` | P player glass | part of player recipe |
| `rgba(255,255,255,0)` | gradients (transparent stop) | part of gradient recipes |
| `rgba(58,115,255,.28)` | I dark glow | part of Island recipe |
| `rgba(var(--glow), α)` | P timer / D stat glows | keep the `--glow` channel token |

### 2.3 Proposed colour tokens and changes

Keep the existing names and values, and add semantic roles: `--on-accent`, `--on-accent-muted`, `--on-dark-muted`, `--success`, `--on-success`, `--danger`, `--alert`, `--live`, `--tooltip-bg`, `--tooltip-ink`, `--toast-bg`, `--toast-link`, `--media-bg`, `--player-bg`, `--menu-bg`, `--locked-bg`, `--locked-ink`, `--switch-on`, `--scrim`, `--scrollbar`, `--white`, `--flame-start`, `--flame-end`, `--flame-core`. `--pill`/`--pillInk` become `--accent`/`--on-accent`, and `--blue`/`--blueShadow` become `--accent-deep`/`--shadow-accent`; the values do not change. Decorative translucent whites stay inside the shared card/player/chip/field recipes rather than becoming dozens of global tokens.

Actual colour changes:

- D dark `--line` `rgba(255,255,255,.07)` → `rgba(255,255,255,.08)` (all dashboard dividers; matches P).
- P dark `--field` `#2a2a2a` → `#262626` (panel inputs; matches D `--soft`/field).
- D delete hover `#ff3b30` → `--alert` `#ff453a` (two buttons).
- P quit hover `#ff453a` and live dot `#ff453a` keep the same value through `--alert`/`--live`.

Everything else is a rename or a move into a shared component recipe with no visual change.

## 3. Corner radii

### 3.1 Existing values

| Radius | Where |
|---:|---|
| 2 | P equalizer bars (graphic) |
| 3px 3px 1px 1px | D Best Hours bars (chart) |
| 5px 5px 2px 2px | D Focus week bars (chart) |
| 6 | D tooltips, delete/radio buttons, `kbd` |
| 7 | D timeline block |
| 8 | D menu buttons, date field, badge tooltip |
| 9 | P progress/volume/goal bars (pill-like), station rows; D XP bars, scrollbar thumb |
| 10 | P timer hover; D inputs, Focus bars |
| 12 | P cover art, question input |
| 13 | D unlocked badge label |
| 14 | D menu, cards, panels, groups, level card; I input |
| 16 | P station list |
| 20 | P timer, player, question and today cards, preview panel; D edit dialog |
| 24 | I card |
| 50% | all circular dots, icon buttons, switch knob, logo |
| 99px | all pills, chips, tags, segmented controls, bars |
| inherit | clipped player layers |

### 3.2 Proposed scale

`--radius-sm: 6px`, `--radius-md: 10px`, `--radius-card: 14px`, `--radius-lg: 20px`, `--radius-pill: 99px`, `--radius-round: 50%`. Chart bars, the 2px equalizer caps and `inherit` stay component-specific.

Owner choices preserved: P cards 20, D cards 14, pills fully round, P card gaps 12.

### 3.3 Radius changes

| Old | New | Where |
|---:|---|---|
| 7 | 6 | D timeline block |
| 8 | 10 | D menu button, date input, badge tooltip |
| 9 | 10 | P station rows |
| 9 | pill | P progress/volume/goal bars; D XP bars, scrollbar thumb |
| 12 | 10 | P cover art, question input |
| 13 | 14 | D unlocked badge label |
| 14 | 10 | I input (all fields share the input radius) |
| 16 | 20 | P station list |
| 24 | 20 | I card |
| 18 | — | D card base value is overridden by 14; no effective change |
| 3/5 chart corners | unchanged | chart-specific |

## 4. Spacing

### 4.1 Values in use

Spacing is built from these scalar values. Composite shorthands (for example `14px 16px 12px`) combine them.

| Value | Gap | Padding | Margin |
|---:|---|---|---|
| 0 | P volume-open controls | P/D button resets; D `.tlist`, `.radioName`, `.radioRestore`, `.catName`, `.catShowAll` | body/heading resets; D `.catAdd .btn`, `.g2/.g3 .panel`, `.vac`; I `h1` |
| 1px | — | P Category row top adjustment | D topic dotted leader |
| 2 | P week dots; D tabs/range/radio tools | D segmented pills | D apply top, donut caption top, I button top |
| 2.5 | P equalizer | — | — |
| 3 | P streak chip, week days; D Best Hours, week days | D bar/timeline tooltips, `kbd`, Focus bar labels; P Category chip | — |
| 4 | P Category row/chips, week strip; D Done gap | P chips, streak chip; D tabs/range, category chips, level pill, stat tag, toggle rows, badge-grid top | D menu more icon, timeline rows, dialog buttons; P control bleed (negative) |
| 5 | P station dot gap; D streak dots, dialog labels | P menu, Category label top; D date field, badge tooltip; I chips | — |
| 6 | P menu, chips; D menu dates/labels, bars, legend, x-axis, topic chips, week step, badge grid, Focus bars, streak chip; I chips | P station list; D menu, hours top | P progress line, goal bar; D hours labels, timeline hours |
| 7 | D tab buttons, vacation dot | P station rows, menu buttons, category name input; D menu/date fields, timeline label sides | D Add station title |
| 8 | P player text; D topic rows, radio names/fields, dialog minutes/buttons | D radio name input, `.btn` | D level caption |
| 9 | P question card | P question input; D radio/dialog inputs, category field, Island input, badge tooltip, toast, table cells | — |
| 10 | P today values; D tools, filters, category name, Focus bars, category rows, dialog columns; I buttons | D radio rows | P timer, progress wrap; D stat value |
| 11 | — | D category topic rows | — |
| 12 | P panel, player, controls, buttons; D category rows/add/topic rows, toast, streak header, dialog; I top | P panel; D settings/category rows, empty state | P goal row; D Show all |
| 13 | — | P question card | — |
| 14 | D cards, split, topic gap, toolbar, grids, big value; I card | P timer card, today card; D stat card bottom, badge tooltip sides | D cards/panels/section headers/streak week |
| 16 | D title, settings rows | P timer card sides; D stat cards; I card | D settings group |
| 18 | D topic card, badge grid | D group headers, settings/category rows, radio rows, add row, Topics header, empty states | D page title |
| 20 | — | D panels (vertical 20), level card (horizontal 20) | — |
| 22 | — | D page top, edit dialog | P weekday letters |
| 24 | — | — | D Add station button |
| 26 | — | — | D tabs bottom |
| 30 | — | P preview | — |
| 32 | — | D page sides | — |
| 40 | — | D page bottom | — |
| 56 | — | D chart legend and x-axis left inset | — |
| auto | — | — | P stop/week, D timeline summary, D wrap, I island |
| 100% | — | P marquee animation | — |
| calc(var(--top,0px)+8px) | — | I notch spacing | — |
| -4 / -8 | — | — | P question copy and control bleed; D dialog/week copy |

Notes: the panel's `.panel` gap is 12 (owner choice). The dashboard grid gap and card gaps are 14 and are kept as a named layout step to avoid changing the current density. The settings row inset is 18 and is kept; this is the spacing just approved for Categories.

### 4.2 Proposed scale

Core steps: `--space-0: 0`, `--space-1: 2px`, `--space-2: 4px`, `--space-3: 8px`, `--space-4: 12px`, `--space-5: 16px`, `--space-6: 20px`, `--space-7: 24px`, `--space-8: 32px`, `--space-9: 40px`.

Layout constants kept as named roles: `--space-grid: 14px` (dashboard grids) and `--space-row-x: 18px` (settings/category row inset). The 1px Category alignment, 56px chart legend indent, 100% marquee padding and notch `calc()` stay component-specific. Negative spacing uses `calc(-1 * var(--space-n))`.

### 4.3 Spacing changes

| Old | New | Where |
|---:|---|---|
| 2.5 | 2 | P equalizer bar gap |
| 3 | 4 | P streak chip and week dots; D Best Hours and week dots |
| 5 | 4 | P station dot gap; D streak dots and dialog label gap |
| 6 | 8 | P menu/chips; D menu dates, bars, legend, x-axis, topic chips, week controls, badge grid, Focus bars, streak chip; I chips; all 6px margins (progress line, goal bar, hours labels, timeline hours) |
| 7 | 8 | D tab-button and vacation-dot gaps; Add station title margin |
| 9 | 8 | P question-card gap |
| 10 | 12 | P today row; D tools, filters, category name, Focus bars, category rows, dialog columns; I action buttons; P timer/progress margins; D card value margins |
| 11 | 12 | D category topic-row padding |
| 13 | 12 | P question-card padding |
| 22 | 24 | D page top padding, edit-dialog padding |
| 26 | 24 | D tabs bottom margin |
| 30 | 32 | P preview padding |
| others | unchanged | 0, 1, 2, 4, 8, 12, 14, 16, 18, 20, 24, 32, 40; `auto`, 100%, `calc()` |

## 5. Shadows

### 5.1 Existing values

Repeated elevation tokens:

| Shadow | Where |
|---|---|
| `var(--bevel)` | P timer, player, secondary question button, question card, streak chip, today card |
| `var(--shadow)` | D tabs/range/round, cards, panels, select, buttons, groups, streak chip, time input |
| `var(--blueShadow)` | D first stat card, level card |
| `var(--chipShadow)` | P idle state, icon buttons, chips |
| `var(--track)` | P progress/question input/goal bar; D radio/category/dialog inputs, badge week dots, category bar |

One-off and composite shadows, grouped by purpose:

- **Popovers and dialogs:** P station list `var(--bevel) + 0 14px 34px rgba(0,0,0,.25)`; D menu `var(--shadow) + 0 14px 34px rgba(0,0,0,.18)`; D edit dialog `var(--shadow) + 0 30px 60px -20px rgba(0,0,0,.4)`.
- **Toasts and switches:** D toast `0 8px 24px rgba(0,0,0,.2)`; D switch knob `0 1px 2px rgba(0,0,0,.3)`.
- **Focus rings:** P/D fields `var(--track) + 0 0 0 3px color-mix(in srgb, var(--accent) 35%, transparent)`; D bad URL `var(--track) + 0 0 0 3px color-mix(in srgb, #e5484d 25%, transparent)`; P gear `var(--chipShadow) + 0 0 0 1.5px var(--accent)`.
- **Cards and player:** P preview panel (light/dark two-part shadow); P menu list (light/dark); P timer light shadow; P player light glass; P art light/dark; P player dark ring; P timer progress light inset; P state light inset; P done-day glow; P goal-bar glow; P category chip inset/checked; D first stat rings; D level card; D week completed/current; D badge label (unlocked/locked light/dark); D bar labels; D tooltip; D category chip inset/checked; I card light/dark; I logo; I input inset/focus; I chips; I buttons.
- **Primary actions:** P `.duo .primary` and hover; D selected tabs/pills/button, dark button hover; I primary button, hover, dark variants.
- Exact composite values are listed below; no behaviour depends on them.

Distinct box-shadow values (final cascade; token shadows already listed above):

| Value | Where |
|---|---|
| `none` | I illustrated logo |
| `0 1px 2px rgba(0,0,0,.3)` | D switch knob |
| `0 8px 24px rgba(0,0,0,.2)` | D toast |
| `0 3px 10px rgba(0,0,40,.25)` | I logo |
| `inset 0 0 0 3px var(--soft)` | D current streak day |
| `0 0 10px rgba(58,114,255,.6)` | P goal bar |
| `inset 0 0 0 .5px var(--line)` | D selected tab, date field, badge, `kbd` |
| `inset 0 1px 2px rgba(0,0,40,.2)` | P light progress track |
| `0 0 10px -2px rgba(47,174,90,.7)` | P done weekday |
| `0 8px 18px -6px rgba(31,92,242,.7)` | D current Focus bar |
| `inset 0 1px 0 rgba(255,255,255,.2)` | I chips |
| `inset 0 1px 0 rgba(255,255,255,.3)` | D last Focus bar |
| `inset 0 1px 0 rgba(255,255,255,.4)` | P light state pill |
| `inset 0 0 0 1.5px rgba(255,255,255,.5)` | I outlined buttons |
| `inset 0 0 0 1.5px rgba(255,255,255,.22)` | I dark outlined buttons |
| `var(--bevel), 0 14px 34px rgba(0,0,0,.25)` | P station list |
| `var(--shadow), 0 14px 34px rgba(0,0,0,.18)` | D menu |
| `var(--chipShadow), 0 0 0 1.5px var(--accent)` | P open menu button |
| `var(--shadow), 0 30px 60px -20px rgba(0,0,0,.4)` | D edit dialog |
| `var(--shadow), 0 6px 14px -6px rgba(20,40,90,.35)` | D button hover |
| `inset 0 0 0 1px color-mix(in srgb, var(--c) 45%, var(--line))` | P category chip (off) |
| `inset 0 0 0 .5px color-mix(in srgb, var(--c) 45%, var(--line))` | D category chip (off) |
| `inset 0 -1px 0 rgba(0,0,40,.1), 0 6px 14px -6px rgba(0,0,40,.45)` | I primary button |
| `inset 0 -1px 0 rgba(0,0,40,.1), 0 10px 20px -6px rgba(0,0,40,.5)` | I primary button hover |
| `inset 0 1px 0 rgba(255,255,255,.3), inset 0 -1px 0 rgba(0,0,40,.2)` | I card |
| `var(--track), 0 0 0 3px color-mix(in srgb, #e5484d 25%, transparent)` | D bad URL field |
| `0 6px 14px -5px rgba(20,40,90,.45), inset 0 0 0 1px rgba(0,0,0,.06)` | P light cover art |
| `inset 0 1px 0 rgba(255,255,255,.5), 0 6px 16px -6px rgba(20,40,90,.3)` | D locked badge label, light |
| `inset 0 1px 0 rgba(255,255,255,.08), 0 6px 16px -6px rgba(0,0,0,.6)` | D locked badge label, dark |
| `inset 0 1px 0 rgba(255,255,255,.25), 0 6px 16px -4px rgba(0,0,0,.35)` | D badge label |
| `inset 0 1px 2px rgba(0,0,0,.5), inset 0 0 0 1px rgba(255,255,255,.1)` | I dark input |
| `inset 0 1px 0 rgba(255,255,255,.3), 0 3px 8px -2px rgba(31,92,242,.5)` | D primary controls |
| `0 6px 14px -4px rgba(0,0,0,.45), inset 0 0 0 1px rgba(255,255,255,.12)` | P dark cover art |
| `inset 0 1px 0 rgba(255,255,255,.3), 0 8px 16px -6px rgba(31,92,242,.6)` | D dark button hover |
| `inset 0 1px 0 rgba(255,255,255,.3), 0 8px 18px -8px rgba(31,92,242,.8)` | I dark primary button |
| `inset 0 1px 0 rgba(255,255,255,.35), 0 0 12px -2px rgba(47,174,90,.75)` | D done streak day |
| `inset 0 1px 2px rgba(0,0,40,.25), inset 0 0 0 1px rgba(255,255,255,.2)` | I input |
| `inset 0 1px 2px rgba(0,0,40,.25), inset 0 0 0 1px rgba(255,255,255,.6)` | I focused input |
| `inset 0 1px 0 rgba(255,255,255,.3), 0 12px 22px -8px rgba(31,92,242,.9)` | I dark primary button hover |
| `var(--track), 0 0 0 3px color-mix(in srgb, var(--accent) 35%, transparent)` | P/D focused fields |
| `inset 0 0 0 1px rgba(255,255,255,.12), inset 0 1px 0 rgba(255,255,255,.08)` | P dark player edge |
| `inset 0 1px 0 rgba(255,255,255,.08), inset 0 0 0 1px rgba(255,255,255,.08)` | I dark card |
| `inset 0 1px 0 #fff, 0 0 0 .5px rgba(20,40,90,.12), 0 14px 30px -8px rgba(20,40,90,.35)` | P light menu |
| `inset 0 1px 0 rgba(255,255,255,.06), 0 0 0 .5px rgba(255,255,255,.1), 0 14px 30px -8px rgba(0,0,0,.8)` | P dark menu |
| `inset 0 1px 0 rgba(255,255,255,.25), 0 2px 5px -2px color-mix(in srgb, var(--c) 60%, transparent)` | P/D checked category chip |
| `inset 0 1px 0 rgba(255,255,255,.9), 0 0 0 .5px rgba(20,40,90,.12), 0 22px 50px rgba(20,40,90,.25)` | P preview panel, light |
| `inset 0 1px 0 rgba(255,255,255,.06), 0 0 0 .5px rgba(255,255,255,.1), 0 22px 50px rgba(0,0,0,.6)` | P preview panel, dark |
| `inset 0 1px 0 rgba(255,255,255,.3), inset 0 -1px 0 rgba(0,0,40,.15), 0 8px 18px -8px rgba(31,92,242,.7)` | P primary button |
| `inset 0 1px 0 rgba(255,255,255,.3), inset 0 -1px 0 rgba(0,0,40,.15), 0 12px 22px -8px rgba(31,92,242,.8)` | P primary button hover |
| `inset 0 1px 0 rgba(255,255,255,.35), inset 0 -1px 0 rgba(0,0,40,.15), 0 0 0 .5px rgba(20,40,90,.12), 0 16px 30px -12px rgba(31,92,242,.6)` | P light timer |
| `inset 0 0 0 1px rgba(255,255,255,.75), inset 0 1px 0 #fff, 0 0 0 .5px rgba(20,40,90,.1), 0 1px 2px rgba(20,40,90,.06), 0 10px 24px -8px rgba(20,40,90,.18)` | P light player |

Text shadow: D timeline label `0 1px 2px rgba(0,0,0,.35)`.

Filter shadows: P performance indicator `drop-shadow(0 0 8px rgba(255,90,40,.55))`; D streak chip `drop-shadow(0 0 6px rgba(255,90,40,.5))`; D streak flame `drop-shadow(0 0 12px rgba(255,80,40,.6))`; D badge coin `drop-shadow(0 8px 10px rgba(20,40,90,.22))`; I illustrated logo `drop-shadow(0 4px 8px rgba(0,0,40,.35))`.

### 5.2 Proposed shadow scale

Keep the existing shadow values; give the repeated elevations names:

- `--shadow-card` = current `--shadow`
- `--shadow-panel` = current `--bevel`
- `--shadow-accent` = current `--blueShadow`
- `--shadow-chip` = current `--chipShadow`
- `--shadow-track` = current `--track`
- `--shadow-popover` = `0 14px 34px rgba(0,0,0,.18)`
- `--shadow-popover-strong` = `0 14px 34px rgba(0,0,0,.25)`
- `--shadow-dialog` = `0 30px 60px -20px rgba(0,0,0,.4)`
- `--shadow-toast` = `0 8px 24px rgba(0,0,0,.2)`
- `--shadow-switch` = `0 1px 2px rgba(0,0,0,.3)`
- `--shadow-focus` = `0 0 0 3px color-mix(in srgb, var(--accent) 35%, transparent)`
- `--shadow-focus-danger` = `0 0 0 3px color-mix(in srgb, var(--danger) 25%, transparent)`

All current shadow values can be preserved exactly. The remaining inset, gradient and primary-action shadows move into the shared parts (`card`, `button`, `field`, `switch`, `toast`) as component recipes; they are not exposed as global elevation tokens.

### 5.3 Shadow changes

No value needs to change. The old token names map 1:1 to the new names above; popover/dialog/toast/switch/focus shadows are extracted with their current values.

## 6. Summary of visual changes to approve

- Text: 9.5/10.5 → 10, 11.5 → 11, 12.5 → 12, 13.5 → 13, most 14 → 13, 16 → 15, 17/19/20 → 18, D group titles 14 → 15. Panel/Island body leading 1.35 → 1.4; Island title 19/1.15 → 18/1.2; chip leading 1.5 → 1.4. Weights stay.
- Colour: dashboard dark divider `.07` → `.08`; panel dark field `#2a2a2a` → `#262626`; delete hover `#ff3b30` → `#ff453a`. Everything else is a token rename or a shared recipe.
- Radius: island card 24 → 20; panel station list 16 → 20; small 12/13px radii → 10/14; 7/8/9px controls → 6/10 or pill. Panel cards stay 20; dashboard cards stay 14; pills stay fully round.
- Spacing: 2.5 → 2, 3 → 4, 5 → 4, 6 → 8, 7 → 8, 9 → 8, 10 → 12, 11 → 12, 13 → 12, 22 → 24, 26 → 24, 30 → 32. Panel card gaps stay 12; dashboard 14px grids and 18px settings-row insets stay.
- Shadows: names only, no value change.

The Categories (`.cat*`) and Progress (`.cg*`) styles are included in the type, colour, radius, spacing and shadow tables above.
