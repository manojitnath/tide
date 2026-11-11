# Task 02 · Categories and goals

Brief for the coding model. Claude reviews the result. Do the steps **in order** and stop after each **STOP**.

## What we're building

The owner logs focus sessions by topic (for example "Interview Prep", "Scripting", "Research"). Now they want to:
1. **Create categories**, such as Learning or Content.
2. **Assign categories to topics.** A topic can have **several** categories, or none.
3. **Set a goal per category**, per day or per week, for example Learning 2h a day or Content 6h a week. Goals are optional.

A session counts toward every category its topic belongs to. So with "Research" in both Learning and Content, a 1-hour Research session adds 1h to each.

Decisions already made (don't change them):
- **The streak doesn't change.** It still depends only on the overall daily focus goal. Category goals show progress, and missing one never breaks anything.
- **Progress updates when a session is saved**, the same as the daily goal today. There's nothing new at session start.
- **No new screens.** Categories are managed in Settings, progress shows as one card in the Progress tab, and the end-of-session question gets category chips. The panel's game card stays as it is (owner rule: game features stay quiet).
- Weeks start on Monday, like the streak week.

## The app, in 60 seconds

- `src/game.js`: the goal, streak, level and badge rules, shared by the panel and the dashboard (`window.Game`). Its settings live in `tide.game` (`Game.settings(g)` fills in defaults: `{goalMin: 120, vacation: []}`). Both pages may save `tide.game`, and the app syncs it to the other page (`__syncGame`). **So no Swift changes are needed in this task.**
- The log: `logs` = array of `{id, start, end, ms, topic}` (`ms` = focused time). Topics are free text. Match topics **trimmed and lowercased**, as the topic colours do (`colorTopics()` in the dashboard).
- `src/dashboard.html`: the Settings tab (`.group` / `.set` rows, `renderSettings()`, `toast(text, undo)`), the Progress tab (`#progress`: `.g3` with level, Daily goal and streak cards, then Focus and Badges), `topicColor(topic)` and `TOPIC_PALETTE`, `fmtDur`-style helpers (use the existing ones).
- `src/panel.html`: the end-of-session question `topic: () => ({title: 'What did you work on?', … chips: recentTopics(4) …})`, `askPress`, `#askInput`, `saveGame()`.
- Preview: `python3 -m http.server 8765 --directory src`, then `dashboard.html?demo&tab=settings`, `dashboard.html?demo&tab=progress` and `panel.html?demo=idle`.

## The data (in `tide.game`)

```js
{
  goalMin: 120, vacation: [], ...,          // as today, untouched
  categories: [
    {id: 'k3x9a1b2', name: 'Learning', color: '#2fae5a', goalMin: 120, per: 'day'},
    {id: 'k3x9c3d4', name: 'Content',  color: '#e8336b', goalMin: 360, per: 'week'},
    {id: 'k3x9e5f6', name: 'Admin',    color: '#5a6a86', goalMin: 0,   per: 'day'}   // goalMin 0 = no goal
  ],
  topicCats: {'interview prep': ['k3x9a1b2'], 'research': ['k3x9a1b2', 'k3x9c3d4']}
}
```

- `Game.settings()` defaults: `categories: []`, `topicCats: {}`. Make sure both are the right type (an array and a plain object), as it already does for `vacation`.
- A new category's colour is the next colour from `TOPIC_PALETTE` that no other category uses yet (wrap around if all are used). Move the palette into `game.js` as `Game.PALETTE` and have the dashboard use it, so both pages agree.
- `topicCats` only keeps ids that exist. Deleting a category removes its id everywhere, and a topic with an empty list is removed from `topicCats`.

## Rules

- Files you may change: `src/game.js`, `src/dashboard.html`, `src/panel.html`, `README.md`, `CONTRIBUTING.md` (Step 5), and the mockup in Step 0. **No Swift.**
- Don't change the shape of `logs` or `studyradio.state`. In `tide.game`, only add the two keys above.
- Match the existing look (cards, 14px dashboard corners, bevel shadows, `var(--font)` Manrope, the existing grey pill `.badge`), in light and dark mode.
- Short, clear text. No emoji. `esc()` every user-typed name before it goes into HTML.
- Comments only where the *why* isn't obvious, one line, in the existing style. No `console.log` left behind.
- One commit per step, imperative message, ending with a blank line and `Co-Authored-By: DeepSeek <noreply@deepseek.com>`.

---

## Step 0 · Mockup (no app code)

Create `docs/mockups/categories/index.html`, a static picture in **light and dark** of:
1. **Settings → Categories** (a new group, placed after Streaks and goals):
   - One row per category: a colour dot, the name (click to rename), its goal as a small select (`No goal`, then `30m`…`4h` **a day** or `1h`…`20h` **a week**, see Step 2), and × to delete.
   - An **Add category** row: a name field and an **Add** button.
   - Below that, a **Topics** list: each topic (most recently used first) with one small toggle chip per category. A chip is filled with the category's colour when on, and outlined when off. Show 3 categories and 6 topics, one of them in two categories.
2. **Progress tab, new "Category goals" card** (full width, between the `.g3` row and Focus): one line per category **with a goal**, showing the colour dot, the name, a thin progress bar in the category's colour, and `1h 20m of 2h today` or `3h 10m of 6h this week`. A reached goal shows a check and `Done`. Categories without a goal don't show here.
3. **Panel, end-of-session question** for a topic that has no categories yet: under the topic field and recent-topic chips, a row "Category" with one toggle chip per category. Show it filled in once with one chip on.

**STOP.** Report the path; Claude renders it for the owner.

## Step 1 · The rules (`src/game.js` only)

- `settings()` defaults and type checks for `categories` and `topicCats`, as above.
- `Game.PALETTE`: the 10 colours now in the dashboard's `TOPIC_PALETTE`, in the same order.
- `Game.topicKey(topic)` → trimmed, lowercased string.
- `Game.categoriesOf(g, topic)` → the category objects for that topic, in `g.categories` order. Unknown ids are skipped.
- `Game.categoryProgress(logs, g, now = Date.now())` → one item per category **that has a goal** (`goalMin > 0`), in `g.categories` order:
  `{id, name, color, per, goal (ms), ms, p (0..1, capped at 1), done (bool)}`.
  `ms` is the focused time today (`per: 'day'`) or this week, Monday to now (`per: 'week'`), from logs whose topic belongs to that category. A session counts by its `start` time, as the streak does.
- `Game.nextColor(g)` → the first `PALETTE` colour no category uses, else `PALETTE[g.categories.length % PALETTE.length]`.

Check in the browser console on `dashboard.html?demo`: build a small `g` with 2 categories (one daily, one weekly) and a topic in both, then call `Game.categoryProgress(DEMO_LOGS_OR_logs, g)`. Report the numbers, and confirm by hand that one of them is right.

**STOP** (commit "Add category rules to the game").

## Step 2 · Settings → Categories (`src/dashboard.html`)

- New group **Categories** after Streaks and goals. Empty state: "Group your topics, like Learning or Content, and set a goal for each."
- **Add category:** a name field plus **Add**. Refuse an empty name, and refuse a duplicate name (case-insensitive) with "You already have that category." Colour from `Game.nextColor(G)`. Save with the existing `saveGame()`, then `toast('Added <name>', undo)`.
- **Category rows:** colour dot, name (click to rename inline: Enter saves, Esc cancels, the same as station names), goal select, ×.
  - Goal select options: `No goal`, then `30m a day`, `1h a day`, `1.5h a day`, `2h a day`, `3h a day`, `4h a day`, then `1h a week`, `2h a week`, `3h a week`, `5h a week`, `8h a week`, `10h a week`, `15h a week`, `20h a week`. It stores `goalMin` and `per`.
  - × deletes the category and removes it from every topic, with `toast('Deleted <name>', undo)`. Undo puts back both the category and its topic links.
- **Topics list** (only when there's at least one category): every topic in the log, most recently used first, trimmed and shown as last typed. Each has a toggle chip per category. A chip is `role="switch"` with `aria-checked`, filled with the category colour when on and outlined when off. Clicking saves immediately. Show the first 12 topics and a **Show all N topics** text button for the rest.
- `__syncGame` already re-renders. Make sure the Categories group updates when the panel saves (Step 4).

**Done when:** in the preview you can add, rename, set goals on and delete categories (with Undo), toggle topics into one or more categories, and everything survives a reload. Checked in light and dark.

**STOP** (commit "Add categories to Settings").

## Step 3 · Category goals card (`src/dashboard.html`, Progress tab)

- New full-width `.panel` card **Category goals**, between the `.g3` row and the Focus card, built from `Game.categoryProgress(logs, G)`.
- One line per item: colour dot, name, a thin bar (6px, rounded, track `var(--field)`, fill the category colour, width `p`), and the text `1h 20m of 2h today` or `3h 10m of 6h this week`. When `done`: a small check and `Done` instead of the text.
- Hide the whole card when no category has a goal.
- It re-renders with the rest of the Progress tab (`renderAll`) and after `__syncGame`.

**Done when:** in the demo, with 2–3 categories and goals set in Settings, the card shows the right numbers for today and this week (check one by hand and say which). The card is hidden with no goals. Checked in light and dark.

**STOP** (commit "Show category goals in Progress").

## Step 4 · Categories in the end-of-session question (`src/panel.html`)

- In the `topic` notice, when the user has at least one category, add a row **Category** under the topic chips: one toggle chip per category, in the same style as Settings.
- Fill the chips from the typed topic as it changes (`input` event): a known topic shows its saved categories, and a new topic shows them all off. Clicking a recent-topic chip updates them too.
- On **Save**, if the chosen categories differ from what's saved for that topic, update `G.topicCats[Game.topicKey(topic)]` (remove the key when none are on) and call `saveGame()`. Discard changes nothing.
- No categories at all → no row, and the question looks exactly like today.
- Keep the panel height right: the panel already resizes itself (`ResizeObserver`). Check the notice doesn't get cut off with 5 categories (chips wrap onto a second line).

**Done when:** in `panel.html?demo=idle`, finishing a session shows the row, a new topic gets the chosen categories, a known topic shows its saved ones, and the dashboard's Settings → Topics list matches after the save. In the browser both pages use localStorage, so reload the dashboard to see it. Checked in light and dark.

**STOP** (commit "Ask for categories when saving a session").

## Step 5 · Docs

- `README.md`: a bullet **Categories and goals**: group topics into categories (a topic can be in several), set a daily or weekly goal per category in Settings → Categories, see progress in the Progress tab, and pick categories when you save a session with a new topic. The streak still depends only on the daily focus goal.
- `README.md` data list: `tide.game.json` now also holds your categories and goals.
- `CONTRIBUTING.md`: in the game section, `categories`, `topicCats` (keys are `Game.topicKey`), `Game.categoryProgress` (a session counts toward every category of its topic, by start time, with weeks starting Monday), and `Game.PALETTE`.

**STOP** (commit "Document categories and goals").

---

## How to report back after each step

1. Commit hash and a 2–4 line summary.
2. What you checked (light and dark), and anything you weren't sure about or left out.
3. Stop the preview server and clear any test data from localStorage.
4. Don't start the next step until told to.
