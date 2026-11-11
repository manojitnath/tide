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

---

# Part 2 · One station list, and channel links

Owner feedback after Step 3: everything works. Two changes:
1. **One list.** Show the 10 built-in stations by name in **Settings → Radio**, in the same list as the custom ones, under them. Each can be moved up or down and removed, like a custom station. This **replaces** the "Include built-in stations" switch.
2. **Channel links.** Pasting a YouTube channel link adds a station that plays the channel's videos, newest first, like a playlist: back and forward skip songs, and the cover shows the current song. There's no song picker.

No mockup needed: Settings keeps the same rows, with more of them.

## The new data (`tide.stations`, version 2)

```js
{v: 2, list: [
  {id: 'k3x9a1b2', name: 'Coding mix', kind: 'video',    video: 'ID', list: '',      url: '...'},
  {id: 'k3x9c3d4', name: 'Deep focus', kind: 'playlist', video: '',   list: 'PL...', url: '...'},
  {id: 'k3x9e5f6', name: 'Some artist', kind: 'channel', video: '',   list: 'UU...', channel: 'UC...', url: '...'},
  {id: 'b:Lofi Girl: Study', name: 'Lofi Girl: Study', kind: 'live', builtIn: 'Lofi Girl: Study'},
  ...
]}
```

- A built-in item only points at its `BUILT_IN` entry by its original name (`builtIn`). Its `name` can be renamed like any other. `S.ytIds` and the live-stream lookup keep using the original name.
- Station keys in the panel stay the same (`'b:' + builtIn` and `'c:' + id`), so the saved current station keeps working.
- **Upgrading from version 1** (`{custom, builtIn}`): `list` = the custom stations in their order, then, if `builtIn` was true, all 10 built-ins in `BUILT_IN` order. If it was false, leave them out. No file yet: all 10 built-ins.
- Both pages must read either version, because the panel can load before the dashboard saves. Write one small function `readStations(data, BUILT_IN_NAMES)` → version 2, the same in both files. The dashboard has no `BUILT_IN`, so give it a plain array of the 10 names with a comment saying it must match the panel's `BUILT_IN`. Only the dashboard writes the file. The panel never saves `tide.stations`.
- The list may never be empty: removing the last station is refused with "Keep at least one station."

## Step 4 · One list (dashboard + panel, no Swift)

`src/dashboard.html`, Settings → Radio:
- The rows show the whole `list` in order: the custom ones you've added, then the built-ins (after an upgrade). Every row has the name (click to rename), a badge, ↑ ↓ and ×, with Undo on delete as now.
- Badges: `Video`, `Playlist`, `Channel` (Step 5), and for built-ins their FM number (`88.6`) in the same grey pill.
- New stations are added at the **top** of the list, so they come before the built-ins.
- Remove the "Include built-in stations" switch, `#builtInHint` and the code that used them.
- When any built-in is missing from the list, show a small text button under the rows: **Add built-in stations back**. It appends the missing ones at the end, in `BUILT_IN` order, with `toast('Added N stations', undo)`. Hide it when all 10 are there.
- The duplicate check covers built-ins too (a built-in can only be in the list once).

`src/panel.html`:
- `stationList()` builds from `readStations(...).list`. Built-in items take `f`, `ch`, `match` and `yt` from `BUILT_IN` (look them up by `builtIn`) and use the item's `name` for display. A `builtIn` name not found in `BUILT_IN` is skipped.
- Remove the `builtIn` flag handling. Everything else from Step 3 stays (keys, keep the current station after a sync, back/forward rules).

**Done when:** in the preview:
- A version 1 file upgrades correctly: customs first, then the built-ins, or no built-ins if the switch was off.
- Built-ins can be moved, renamed and removed, and the list keeps the new order after a reload.
- **Add built-in stations back** works, and removing the last station is refused.
- The panel's station list shows the same order and names after `__syncStations(...)`.

**STOP** (commit "Show all stations in one list").

## Step 5 · Channel links

Links to accept (`www.`/`m.`/`music.` hosts as before):

| Paste | What we know |
|---|---|
| `youtube.com/channel/UC…` | the channel ID directly |
| `youtube.com/@handle` (with or without `/videos`, `/featured`, etc. after it), `youtube.com/c/name`, `youtube.com/user/name` | needs a lookup |

`parseYouTube` returns `{kind: 'channel', channel: 'UC…'}` or `{kind: 'channel', path: '@handle' | 'c/name' | 'user/name'}`. Video and playlist links keep winning: a `watch?v=` or `list=` link is never a channel. The error text becomes "That isn't a YouTube video, playlist or channel link." Update the empty-list text to "Paste a YouTube video, playlist or channel link."

**The lookup** (`src/main.swift`, the only Swift change):
- New message from the **dashboard**: `native({type: 'channel', req, path})`. Fetch `https://www.youtube.com/<path>` with the same User-Agent and Accept-Language as `findLiveStream`. Read the channel ID from `<meta itemprop="identifier" content="UC…">` (fall back to `"externalId":"UC…"`), and the channel's name from `<meta property="og:title" content="…">`. Accept only IDs that match `^UC[\w-]{22}$`.
- Reply on the main thread to the dashboard: `channelFound(req, id, name)`, or `channelFound(req, null, null)` if nothing was found. Pass the values through `JSONSerialization` (or escape them), never raw string interpolation: the name comes from a web page.
- For `/channel/UC…` links, skip the lookup but still ask for the name the same way (use the ID even if the name lookup fails).

**Adding** (`src/dashboard.html`):
- On Add with a channel link: disable Add and show "Looking up the channel…" under the field. On success, save `{kind: 'channel', channel: 'UC…', list: 'UU' + id.slice(2), video: ''}`. The `UU…` list is YouTube's uploads playlist for that channel, newest first. Use the typed name, else the channel's name, else "Custom N". On failure: "Couldn't find that channel. Check the link." Time out after 20 seconds with the same message.
- Duplicate check by `channel`.
- In the browser preview there's no Swift. If `NATIVE` is false, pretend the lookup worked after 500 ms, with id `UCSJ4gkVC6NrvII8umztf0Ow` and name "Demo channel", so the flow can be checked.

**Playing** (`src/panel.html`): a `channel` station plays exactly like a `playlist` (it has a `list`): `loadPlaylist`, `setLoop(true)`, back/forward skip songs, cover from the current song. The sub line and the station list show `Channel`. A playback error says "Can't play this channel. Try another station."

**Done when:**
- In the preview: each channel link form is accepted, a bad link and a failed lookup show their messages, and the badge reads `Channel`.
- In the app (Claude builds and tests): a channel added by `@handle` plays its newest video, then the next one, and forward/back skip.

**STOP** (commit "Add channel links as stations").

## Step 6 · Docs

- `README.md`, the **Radio** bullet: you can add your own YouTube videos, playlists and channels in Settings → Radio, and reorder or remove any station, built-in ones included.
- `README.md`, the data file list: add `tide.stations.json: your station list`.
- `CONTRIBUTING.md`, **Stations**: `BUILT_IN` and `tide.stations` (version 2, upgraded from version 1), how a channel becomes its `UU…` uploads playlist, and the back/forward rules.

**STOP** (commit "Document custom stations").
