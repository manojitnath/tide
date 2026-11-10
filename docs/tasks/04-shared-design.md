# Task 04 · One shared design system for every page

Brief for the coding model. Claude reviews the result. Do the steps **in order** and stop after each **STOP**.

**Start only after Tasks 01 and 03 are finished and committed**: this task touches every page.

## Why

Tide has three pages: the menu bar panel (`src/panel.html`), the dashboard (`src/dashboard.html`) and the Island (`src/island.html`). Each has its own `<style>` block and its own copy of the colour variables, and the sizes are typed by hand (12px, 14px, 20px…). They already look alike, but nothing keeps them alike. The goal: **one shared stylesheet** with named values for colour, type, spacing, corners and shadows, plus the shared parts (card, button, chip, input, switch, segmented control, toast), so every heading, description, gap and corner comes from the same place.

**This is a refactor, not a redesign.** After it, the app must look the same as before, except for the small unifications Claude approves in step 0.

## How the pages load (important)

- The app loads each page with `loadHTMLString(..., baseURL: https://localhost/)`, so a page **cannot** load a local `.css` file with `<link>`. That's why `game.js` is injected by the app: `main.swift` reads the bundled file and adds it as a `WKUserScript` at document start (`gameScript`, next to `fontScript` in `pageConfig()`), and `build.sh` copies it into the app bundle.
- In a browser preview (`python3 -m http.server 8765 --directory src`), the pages load `game.js` themselves: `<script>if (!window.Game) document.write('<script src="game.js"><\/script>');</script>`.
- The shared stylesheet works the same way: `src/tide.css`, injected by the app as a `<style>` element at document start (before the page's own `<style>`), and loaded with a `<link>` in the preview.

## Rules

- Files you may change: `src/tide.css` (new), `src/panel.html`, `src/dashboard.html`, `src/island.html`, `src/main.swift` (only the injection in step 1), `build.sh` (only the copy line), `CONTRIBUTING.md`, `CLAUDE.md`, and the audit file in step 0.
- Don't change any behaviour or JavaScript logic, only styles, and class names where a page switches to a shared part.
- Light and dark mode stay exactly as they are now (`prefers-color-scheme`, plus the app's theme switch, which sets the appearance natively).
- Font stays Manrope via `var(--font)`.
- Comments: one short line per section of `tide.css` saying what it's for; nothing else.
- One commit per step, imperative message, ending with a blank line and `Co-Authored-By: DeepSeek <noreply@deepseek.com>`.
- **Screenshots before and after**: before step 2, take light and dark screenshots of every page and state listed under "Checking" and keep them in `docs/design/before/`. Each later step must match them, apart from approved changes.

---

## Step 0 · Audit (no code changes)

Write `docs/design/audit.md`, listing every distinct value used today in the three pages, with where it's used:
1. **Text**: every font-size + weight + line-height combination (for example "30/600: page titles (dashboard h1)", "11.5/580: progress line under the clock").
2. **Colours**: every hex/rgba not already a variable.
3. **Corner radii**, 4. **Gaps / padding / margins**, 5. **Shadows**.

Then propose the **scale** each group should collapse to, and list which current values would change (old → new) and where. Keep the owner's deliberate choices: the panel's cards use 20px corners (matching the panel window), the dashboard's cards use 14px, pills are fully round, the panel's gaps between cards are 12px.

Proposed starting point (adjust to what the audit finds):
- Type: `display` 52 (the panel timer), `title` 30/600 (page titles), `heading` 18/600 (card titles), `subheading` 15/600, `body` 13/580, `small` 12/580, `caption` 11/600 (labels, table headers), plus `muted` colour for descriptions.
- Spacing: 4, 8, 12, 16, 20, 24, 32.
- Radius: 6 (small controls), 10 (inputs, chips), 14 (dashboard cards), 20 (panel cards, Island card), pill.
- Colours: the existing light and dark sets (`--ink`, `--muted`, `--line`, `--soft`, `--card`, `--cardFill`, `--accent`, plus the state colours for focus / paused / break, and the topic palette from Task 01).

**STOP.** Report the path. Claude reviews the proposal with the owner, and tells you which changes are approved.

## Step 1 · Create `src/tide.css` and load it everywhere (no visual change yet)

- `src/tide.css` sections: **tokens** (`:root` light, `@media (prefers-color-scheme: dark)` dark: colours, type, spacing, radius, shadows), **base** (body font, text colours), **parts** (`.t-title`, `.t-heading`, `.t-body`, `.t-small`, `.t-caption`, `.t-muted`; `.card` / `.card.panel-card`; `.btn`, `.btn.primary`; `.chip`; `.field` inputs; `.switch`; `.seg` segmented control; `.toast`). Name tokens `--space-1…7`, `--radius-sm/md/card/lg/pill`, `--text-*` (size) and `--weight-*`, colours as they're named today.
- Load it: in each page's `<head>`, before its `<style>`, add `<link rel="stylesheet" href="tide.css">` (harmless in the app; the request just fails). In `main.swift` add `cssScript`, like `gameScript`, which injects the file's text as a `<style id="tide-css">` into `document.documentElement` at document start, and add it to `pageConfig()` **before** the other scripts. In `build.sh` copy `src/tide.css` into Resources with the other files.
- Pages don't use it yet, so nothing should look different.

**STOP** (commit).

## Step 2 · Dashboard uses the shared values

Replace hand-typed values in `dashboard.html`'s `<style>` with the tokens, and switch its cards, buttons, chips, inputs, switches, segmented controls and toast to the shared parts. Delete page CSS that the shared parts now cover. Keep only what's truly dashboard-specific (charts, badges, the edit dialog layout).

**Done when:** every tab (Stats, Progress, Sessions, Settings, the edit dialog, the range menu) matches the "before" screenshots in light and dark, apart from approved changes, and `dashboard.html` has no raw font sizes, radii or spacing numbers left outside the dashboard-specific parts.

**STOP** (commit).

## Step 3 · Panel uses the shared values

The same for `panel.html`: clock card, player, buttons (`.duo`), streak card, question card, menu, station list.

**STOP** (commit).

## Step 4 · Island uses the shared values

The same for `island.html` (the card, title, text, input, chips, buttons).

**STOP** (commit).

## Step 5 · Write the rules down

- `CONTRIBUTING.md`: a short **Design** section: where tokens live, the type scale with what each level is for, the spacing and radius scales, and "use a token or a shared part; don't type sizes".
- `CLAUDE.md`, under "Rules from the owner": one line, "Use the shared tokens and parts in `src/tide.css`; no hand-typed sizes, colours, spacing or corners."

**STOP** (commit).

---

## Checking (for every step from 2 on)

Serve `src` and screenshot at 2x, light and dark:
- `panel.html?demo=idle`, `?demo=focus`, `?demo=paused`, `?demo=break`, `?demo=topic`
- `dashboard.html?demo` (Stats), `&tab=progress`, `&tab=sessions`, `&tab=settings`
- `island.html?demo=done`, `?demo=break`, `?demo=topic`, `?demo=badge`

Compare with `docs/design/before/`. Report any difference, and whether it was approved.

## How to report back after each step

1. Commit hash and a 2–4 line summary.
2. Any visual differences against the "before" screenshots.
3. Don't start the next step until told to.
