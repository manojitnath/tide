# Task 03 · Your own stations (YouTube videos, live streams, playlists)

Brief for the coding model. Claude reviews the result. Do the steps **in order** and stop after each **STOP**.

## What we're building

Today the radio plays a fixed list of 10 lofi live streams (`STATIONS` in `src/panel.html`). The owner wants to add their own: paste a YouTube link in **Settings → Radio**, give it a name, and it joins the station list. The built-in ones can be hidden.

Controls in the panel's player:
- **Pick a station:** click the station name (`#stationBtn`) to open the list, then click one. This is how you jump between stations.
- **Back / forward** (`#prevSt` / `#nextSt`): if the current station is a **playlist**, they skip to the previous / next song in it. Otherwise (built-in or custom video) they go to the previous / next station, as today.

Supported links (YouTube only; that's what the player embeds):

| Paste | Kind | Plays |
|---|---|---|
| `youtube.com/watch?v=ID`, `youtu.be/ID`, `youtube.com/live/ID`, `music.youtube.com/watch?v=ID` | `video` (or a live stream; same thing to the player) | that video; a normal video **loops** when it ends |
| `youtube.com/playlist?list=LIST`, or any link with `list=` (also `watch?v=ID&list=LIST`) | `playlist` | the playlist in order, then from the top again |

Anything else is refused with: "That isn't a YouTube video or playlist link."

## The app, in 60 seconds

- Swift shell `src/main.swift` hosts HTML pages in WebKit. Pages talk to it with `native({type, ...})`, and it calls back with `evaluateJavaScript`.
- **Storage**: pages use `store.get(key, default)` / `store.set(key, value)`. In the app these become JSON files in `~/Library/Application Support/Tide/<key>.json`; in a browser, localStorage. The app hands the saved data to every page at load (`window.__STORE`), only for the keys listed in `pageConfig()` in `main.swift` (`for key in ["studyradio.logs", "studyradio.state", "tide.game"]`).
- The dashboard may only save some keys: see `case "store":` in `userContentController` (`if fromDash && key != "studyradio.logs" && key != "tide.game" { return }`). After a save, the app tells the **other** page (`__syncLogs`, `__syncGame`).
- `src/panel.html` radio code: `STATIONS` (array of `{name, f, ch, match, yt}`), `ytId(st)`, `makePlayer()` (YouTube IFrame API player), `playYT(id)` (`player.loadVideoById(id)`), `showStation()` (name, `FM 88.6 · LIVE`, cover art from `i.ytimg.com/vi/<id>/…`), `tuneTo(i)`, `playStation(i)`, the station list (`#stationBtn` → `#stations`), `resolveStation(i)` (finds a channel's current live stream; **built-ins only**, the ones with `ch`).
- `src/dashboard.html` → Settings tab: groups of `.group` / `.set` rows; `renderSettings()`; buttons `.btn` / `.btn.dark`; `toast(text, undo)` for messages with Undo.
- Preview: `python3 -m http.server 8765 --directory src`, then `panel.html?demo=idle` and `dashboard.html?demo&tab=settings`. The real YouTube player only runs inside the app.

## Rules

- Files you may change: `src/panel.html`, `src/dashboard.html`, `src/main.swift` (only the two small edits in step 2), and the mockup file in step 0.
- Don't change the user's existing files or the shape of `logs`, `studyradio.state`, `tide.game`.
- New UI must match the existing look (cards, 14px dashboard corners, bevel shadows, Manrope via `var(--font)`), in light and dark mode.
- Short, clear text. No emoji. `esc()` every user-typed name before it goes into HTML.
- Comments only where the *why* isn't obvious, one line, in the existing style. No `console.log` left behind.
- One commit per step, imperative message, ending with a blank line and `Co-Authored-By: DeepSeek <noreply@deepseek.com>`.

---

## Step 0 · Mockup (no app code)

Create `docs/mockups/radio/index.html`, a static picture of:
1. **Settings → Radio** group (light and dark): a list of custom stations (name, a small grey badge `Video` or `Playlist` (live streams count as `Video`; owner dropped a separate Live badge), ↑ ↓ to reorder, × to delete), an **Add station** row (URL field, optional Name field, **Add** button), and a switch **Include built-in stations** ("10 lofi live streams").
2. **The panel's station list** open, showing built-in stations with their FM numbers and custom ones with their badge instead.
3. **The player with a playlist playing:** sub line `Playlist · Playing`, and the back / forward buttons labelled (in a note beside it) "previous / next song".

**STOP.** Report the path; Claude renders it for the owner.

## Step 1 · Settings → Radio (dashboard only, saved in the browser)

In `src/dashboard.html`:
- New settings group **Radio**, placed after **General**.
- Data: `stations = store.get('tide.stations', {custom: [], builtIn: true})`. Each custom station: `{id, name, url, kind: 'video' | 'playlist', video: 'ID' or '', list: 'LIST' or ''}`. `id` like the log ids (`Date.now().toString(36) + random`).
- `parseYouTube(url)` → `{kind, video, list}` or `null`, covering every row of the table above (ignore extra params like `t=` and `si=`, `www.`/`m.`/`music.` hosts, `http`/`https`, no scheme).
- **Add**: parse, refuse bad links (show the error under the field in red, as the edit dialog does), refuse duplicates ("That station is already in your list."). Name: what was typed, else "Custom 1", "Custom 2"… Save with `store.set('tide.stations', stations)`, then `toast('Added <name>', undo)`.
- Rows: ↑ ↓ reorder, × delete (toast with Undo), names editable by clicking the name (inline input, Enter saves, Esc cancels).
- Switch **Include built-in stations** → `stations.builtIn`. If it's off and there are no custom stations, keep it on and say "Add a station first."
- Empty list text: "Paste a YouTube video, live stream or playlist link."

**Done when:** in the browser preview you can add each kind of link, see the right badge, reorder, rename, delete with Undo, and the data survives a reload.

**STOP** (commit).

## Step 2 · Let the app keep and share it (`main.swift`, two edits)

1. In `pageConfig()`, add `"tide.stations"` to the list of keys handed to pages.
2. In `case "store":`, allow the dashboard to save `"tide.stations"`, and after it's saved tell the panel: `web.evaluateJavaScript("window.__syncStations && __syncStations(\(value))")` (same pattern as `__syncGame`).

Nothing else in Swift.

**STOP** (commit).

## Step 3 · The panel plays them

In `src/panel.html`:
- Keep the built-in list as `BUILT_IN` (rename `STATIONS`). Build the live list with a function `stationList()`: built-ins (if `builtIn`) followed by custom ones, as objects the rest of the code understands. Use `let STATIONS = stationList()` and rebuild it in `window.__syncStations = data => {...}`.
- When the list changes, keep playing the same station if it still exists (match by name for built-ins, `id` for custom); otherwise go to index 0. Clamp `S.station`.
- **Playing**:
  - `video` → `player.loadVideoById(video)`. When it **ends** (`YT.PlayerState.ENDED`), replay it (`seekTo(0)` + `playVideo()`), so a 2-hour lofi mix keeps going.
  - `playlist` → `player.loadPlaylist({list, listType: 'playlist', index: 0})` and `player.setLoop(true)`.
  - Built-ins: unchanged (including `resolveStation` / `ytIds`; never call it for custom stations).
- **Showing**: the sub line under the name is `FM 88.6 · LIVE` for built-ins as today, and for custom stations `Video`, `Playlist` (plus ` · Playing` while it plays). The station list shows the badge where built-ins show their FM number.
- **Cover art**: video → `https://i.ytimg.com/vi/<video>/hqdefault.jpg`. Playlist → after it starts, use the current video's id (`player.getVideoData().video_id`); before that, the plain card background.
- **Back / forward buttons:**
  - Playlist playing → `player.previousVideo()` / `player.nextVideo()`; with `setLoop(true)`, next on the last song wraps to the first. Titles become "Previous song" / "Next song".
  - Anything else → previous / next station through the whole combined list, as today. Titles "Previous station" / "Next station".
- The station list (click the name) lists the whole combined list and is the only way to leave a playlist for another station. If a custom video fails (`onError`), show "Can't play this video. Try another station." (no live-stream lookup).

**Done when:** in the app (Claude will build and test it), each kind plays, a short video loops, a playlist moves on to the next video by itself, back / forward skip songs in a playlist and change station otherwise, the station list switches between built-in and custom stations, hiding built-ins works, and editing the list in Settings updates the panel without restarting.

**STOP** (commit).

---

## How to report back after each step

1. Commit hash and a 2–4 line summary.
2. Anything you weren't sure about or left out.
3. Don't start the next step until told to.
