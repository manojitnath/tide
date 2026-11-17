# Task 05: remove the radio

The owner has decided Tide is a focus timer only. Music now comes from a separate app. Remove the radio completely: the panel's player card, Settings → Radio, the YouTube code in the native app, and the docs that describe it. Nothing else changes.

## Rules

- Remove; don't redesign. With the player card gone, the panel's other cards keep their current look and gaps. The panel already resizes to its content (`resize` message), so nothing else is needed for its height.
- Never touch user data in `~/Library/Application Support/Tide/`. Leave `tide.stations.json` and the old radio fields in `studyradio.state.json` (`station`, `stationKey`, `vol`, `ytIds`) on disk. The app just stops reading them. Don't write code that deletes them.
- Keep the timer, sessions, questions, Island, streak, goal, badges, categories, Progress, sounds, the global shortcut, the update check and keep-awake working exactly as before.
- Keep loading pages from base URL `https://localhost/`. Changing the origin could change where the pages' storage lives. Only update the comment that says it's for YouTube.
- Use the tokens in `src/tide.css` if any CSS has to change.
- One commit per step, with the message given.

## Step 1: the panel (`src/panel.html`)

Remove:
- The player card markup (`<div class="player" id="disc">` … its closing tag) and the station list (`<div class="stations" id="stations" …>`).
- All radio CSS: `.player`, `.bgclip`, `.bgart`, `.art`, `.cover`, `.ytbox`, `.pmain`, `.prow`, `.ptxt`, `.marq`, `.eq` and its keyframes, `.playing …`, `.ctrls`, `.play`, `.side`, `.volwrap`, `.volslide`, `.vbar`, `.stations`, and any dark-mode or light-mode variants of them. Check each selector with grep before deleting, so you don't remove a rule the rest of the panel uses.
- All radio JavaScript: the YouTube/stations comment and `BUILT_IN`, `BUILT_IN_NAMES`, `readStations()`, the station list building, `stationIndex`, `__syncStations`, the `S.station`/`S.stationKey` setup, and the whole `/* ---------- radio … ---------- */` section (`loadYT`, `makePlayer`, `playYT`, `playCurrent`, `resolveStation`, `ytResolved`, `ytFailed`, `showStation`, `tuneTo`, `playPause`, `stopRadio`, volume, cover art, the station menu, and their event handlers). Remove `radioOn`/`radioPaused` and every use of them, including the line in the `?demo` block.
- `vol`, `station`, `stationKey` and `ytIds` from the state defaults, if they're there. Old saved values are simply ignored.

Check:
- `grep -n -i "radio\|station\|youtube\|\byt\b\|ytimg" src/panel.html` finds nothing (or only unrelated words; list any in your report).
- `panel.html?demo`, `?demo=idle`, `?demo=paused`, `?demo=break`, `?demo=done` and `?demo=topic` all render in light and dark, with no console errors.
- In the built app (`./build.sh --install`), start, pause and finish a short session. The topic question shows, and the session is logged.

Commit: "Remove the radio from the panel"

## Step 2: Settings → Radio (`src/dashboard.html`)

Remove:
- The whole `<div class="group"><h3>Radio</h3> …` group in Settings.
- Its CSS (`.radio*` rules and anything used only by them).
- Its JavaScript: `BUILT_IN_NAMES`, `BUILT_IN_FM`, `readStations()`, `stations`, `saveStations`, `renderRadio`, the YouTube link parsing, the channel lookup (`channelSeq`, `channelWait`, `channelTimer`, the `channel` reply handler), `addStation`, rename/move/delete handlers, and any `tide.stations` reads or writes.

Check:
- `grep -n -i "radio\|station\|youtube" src/dashboard.html` finds nothing.
- `dashboard.html?demo`: every tab (including Settings and Progress) renders in light and dark, with no console errors.

Commit: "Remove Settings → Radio"

## Step 3: the native app (`src/main.swift`)

Remove:
- The `resolve` and `channel` message cases, `findLiveStream(...)` and `findChannel(...)`.
- `tide.stations` from the stored keys list and from the page-to-page sync (the `__syncStations` branch).
- `config.mediaTypesRequiringUserActionForPlayback = []`.
- Radio wording in comments: the file header becomes "a focus timer in the menu bar", and "the timer and radio" becomes "the timer". Keep the code that keeps pages running while hidden, because the timer needs it.

Check: `./build.sh --install` builds without warnings. `grep -n -i "radio\|station\|youtube" src/main.swift` only finds the `studyradio.*` file names and the old folder name `"Study Radio"` (both must stay). The app opens, runs a session, and the dashboard opens.

Commit: "Remove the YouTube code from the app"

## Step 4: docs

- `README.md`: Tide is "a focus timer that lives in your Mac's menu bar". Remove the Radio feature bullet, the "About the YouTube streams" section, and the `tide.stations.json` line. Change `studyradio.state.json` to "timer mode and settings". Add one line under the features saying music isn't built in, and that any music app works alongside Tide.
- `CONTRIBUTING.md`: remove the Stations section, the `resolve`/`channel` messages, the YouTube reasons, and the radio from the file table, the testing checklist and the page-local design notes (the 16px station list).
- `CLAUDE.md`: the first line and the owner rule become "a focus timer and Pomodoro" (no lofi radio). Add to the out-of-scope line: "Music: use a separate app."
- `docs/promo/shot.html`: remove the cover-art handling if it's only for the player.
- Screenshots in `docs/screenshots/` and `docs/promo/` that show the player: list them in your report. Don't regenerate them in this step.

Check: `grep -rn -i "radio\|station\|youtube\|lofi" README.md CONTRIBUTING.md CLAUDE.md` only finds `studyradio.*` file names and the old app name.

Commit: "Docs: Tide no longer has a radio"
