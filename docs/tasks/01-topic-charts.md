# Task 01 · Topic colours, stacked chart, donut, day timeline

Brief for the coding model. Claude reviews the result. Do the steps **in order**, and stop after each **STOP** so the work can be checked.

## The app, in 60 seconds

Tide is a macOS menu bar focus timer (Pomodoro / count up) with a lofi radio. A Swift shell (`src/main.swift`) hosts HTML pages in WebKit. **This task only touches `src/dashboard.html`** (one file: HTML, a `<style>` block, one `<script>`). No frameworks, no libraries, no build step. Vanilla JS, plain CSS, inline SVG.

- Data: `logs` is an array of sessions `{id, start, end, ms, topic}`. `start`/`end` are epoch milliseconds. `ms` is focused time (it can be less than `end - start` when the session was paused). `topic` is a free-text string.
- Helpers already in the file: `$`, `$$`, `dur(ms)` ("1h 20m"), `dayStart(ts)`, `fmtDate`, `fmtTime`, `isoDay`, `esc(s)` (HTML-escape; **use it on every topic you put into HTML**), `plural`, `inRange()` (sessions in the selected range), `bounds()` (`[from, to]` of the range), `buckets(a, b)` (chart buckets), `niceMax(ms)`.
- `renderStats()` draws the **Stats** tab: four cards, the **Focused Time** bar chart (`#yax`, `#plot`, `#bars`, `#xax`), the **Topics** card (`#topics`) and **Best Hours** (`#hours`). `renderAll()` redraws everything.
- Styling: use the CSS variables already defined (`--ink`, `--muted`, `--card`, `--cardFill`, `--soft`, `--line`, `--accent`, `--shadow`, `--track`, `--font`). Every new thing must look right in **light and dark mode** (`prefers-color-scheme`). Font is Manrope via `var(--font)`. Cards use 14px corners in the dashboard.
- Preview without the app: from the repo root run `python3 -m http.server 8765 --directory src` and open `http://127.0.0.1:8765/dashboard.html?demo` (sample data). `&tab=sessions` opens the Sessions tab. Browser data lives in localStorage, never in the user's real log.

## Rules

- Change **only** `src/dashboard.html` (and, in step 0, the new mockup file). Don't touch `panel.html`, `island.html`, `game.js`, `main.swift`.
- Never write to the user's data. Don't change how `logs` are saved (`store.set('studyradio.logs', logs)`) or their shape.
- Keep the existing look: same cards, spacing, corners, bevel shadows. New UI must look like it was always there.
- Short, clear text. No emoji in the UI.
- Comments: only where the *why* isn't obvious, one line, in the style already used.
- No `console.log` left behind. No new global names unless needed; prefer `function` declarations next to the code that uses them.
- Each step ends with one git commit, message in the imperative ("Add topic colours to the dashboard"), ending with a blank line and `Co-Authored-By: DeepSeek <noreply@deepseek.com>`.

---

## Step 0 · Mockup first (no app code)

The owner wants to see new screens before they're built. Create `docs/mockups/charts/index.html`: a **static** copy of how the Stats tab and Sessions tab will look with steps 1–4 done, using the sample topics below. Copy the dashboard's CSS variables and card styles so it looks real. Show light mode on top and the same thing in dark mode below (force dark with a `.dark` wrapper that redefines the variables).

Sample topics: AWS AI Practitioner, Linear algebra, System design, Security+ notes, Reading.

**STOP.** Report the file path. Claude renders it and gets the owner's OK.

## Step 1 · A colour per topic

Add `topicColor(topic)` returning a stable colour for a topic string.
- Palette of 10 colours that work on white and on near-black (suggested: `#1f5cf2 #8a5cf6 #2fae5a #e0a23a #e8336b #1fa9d6 #ff7a3d #5a6a86 #16a3a3 #c2410c`).
- Same topic → same colour every time, across reloads and in both modes: hash the lowercased, trimmed topic (simple string hash, e.g. djb2) and index the palette.
- Use it in the **Topics** card: each row's bar (`.track i`) gets its topic's colour instead of the `nth-child` colours. Remove the four `.trow:nth-child(4n+…) .track i` rules.

**Done when:** the Topics card shows one colour per topic, the same after reload, and the same topic has the same colour in every place it appears in later steps.

**STOP** (commit).

## Step 2 · Stacked Focused Time chart + average line

In `renderStats()`, each bar in `#bars` becomes a **stack of segments, one per topic**, in `topicColor`, ordered the same way in every bar (biggest topic over the whole range at the bottom). Total bar height stays exactly as now.
- Each segment has a tooltip (`title` or the existing `data-tip` pattern): "System design · 1h 20m".
- The bar's existing hover tip (date · total) must keep working.
- Draw a dashed **average line** across the plot at the average per bucket that has focus (ignore empty buckets), with a small label on the right: "avg 2h 10m". Use `var(--muted)` for the line, 1.5px dashed. Hide it when there are fewer than 2 non-empty buckets.
- Under the chart, a one-line **legend** of the top 5 topics in the range (colour dot + name), "+N more" if there are more. Text in `var(--muted)`, 11.5px.
- Rounded top corners only on the **top** segment of each bar (as today); inner segments are square.

**Done when:** Today (hourly), 7D (daily) and 30 Days all show stacked bars whose heights match the old totals, the average line and legend appear, and nothing overflows in light or dark.

**STOP** (commit).

## Step 3 · Topics card becomes a donut

Replace the Topics card's list with a **donut chart plus a list**, side by side (donut ~140px on the left, list on the right; stack vertically if the card is narrower than 420px).
- Donut: inline SVG, one arc per topic in `topicColor`, gaps of 1.5px between arcs, total focus in the middle ("12h 40m", with "total" under it in `var(--muted)`).
- List: up to 6 rows, each `● Topic name ……… 3h 20m · 26%`. Remaining topics merge into one grey "Other" row and one grey arc (`var(--muted)` at 50% opacity).
- Hovering an arc or a row highlights both (the others fade to 35%).
- Empty state stays: "Topics show up here once you log a session."

**Done when:** percentages add up to 100 (rounding aside), Other appears only with more than 6 topics, hover links arc and row, it works in both modes.

**STOP** (commit).

## Step 4 · Day timeline in the Sessions tab

Above the sessions table, add a card **Timeline** showing one day as a horizontal strip, like a calendar day view turned sideways.
- Header: `‹ Thursday 30 Oct ›` to step days (› disabled on today), and the day's total focus on the right.
- Axis: from the earliest session's hour (default 8 AM) to the latest's end (default 8 PM), at least 8 hours wide; hour ticks with labels "9 am", "12 pm" (every 3 hours if crowded).
- Each session is a rounded block from `start` to `end`, in its `topicColor`, height 28px. If `ms < end - start` (paused), draw the block at full opacity for the focused share and the rest hatched or at 40% opacity — keep it simple, a lighter tail is fine.
- Topic name inside the block if it fits (≥ 56px), otherwise only in the tooltip. Tooltip: "System design · 9:10 – 10:40 · 1h 20m focus".
- Clicking a block opens the existing edit dialog for that session (`openEdit(id)`).
- Overlapping sessions (shouldn't happen, but can): put the later one on a second row.
- The table below is unchanged.

**Done when:** stepping through days works, blocks line up with their times, clicking opens edit, empty day says "Nothing logged on this day.", and it looks right in both modes.

**STOP** (commit).

---

## How to report back after each step

1. The commit hash and a 2–4 line summary of what changed.
2. Anything you weren't sure about or left out.
3. Do not start the next step until told to.
