# Contributing to Tide

## Files

| Path | What it is |
|---|---|
| `src/panel.html` | The menu bar panel: timer, radio, today's stats, and the end-of-session questions. Markup, styles and script in one file. |
| `src/dashboard.html` | The dashboard window: Stats, Sessions and Settings tabs. |
| `src/game.js` | The game and bedtime rules (goal, streak, levels, badges and their coin pictures, sleep facts), shared by the panel and the dashboard. The app adds it to both pages; in a browser preview they load it themselves. |
| `src/island.html` | **The Island**: a card that drops from the notch at the top of the screen, blue in light mode and near-black in dark mode. It only displays what the panel sends and reports button presses back. |
| `src/main.swift` | The native app: menu bar item, the panel window, the dashboard window, file storage, YouTube stream lookup, notifications, the global shortcut, open at login, the update check. |
| `src/AppIcon.icns` | The app icon, made by `docs/icon/make-icns.sh` from `docs/icon/icon.html`. |
| `build.sh` | Builds `build.noindex/Tide.app`. `--install` copies it to `/Applications` and opens it; `--zip` makes the release zip. |
| `src/fonts/` | Manrope, the bundled font, and its licence. |
| `docs/screenshots/` | README images, rendered from the pages' `?demo` modes. |

## How it fits together

- **The panel** is a borderless window with 20pt rounded corners (an `NSVisualEffectView` masked to the corners, with a `WKWebView` on top; the page paints its own background) placed under the menu bar item. It hides when it loses focus, like a menu, but is never closed, so the timer keeps running and the radio keeps playing.
- **Keeping the hidden page alive:** WebKit suspends pages in hidden windows, which froze the timer. The app sets `inactiveSchedulingPolicy = .none`, holds a `ProcessInfo` activity against App Nap, and calls `tick()` every second as a backstop. Keep all three.
- **Questions** (block done, break done, the topic, what next) are built by the panel page (`present()`, the `N` object). With the panel open they show in it; when it closes, the app shows the same question in the Island (`notice` message), and the Island's answer comes back through `noticeAction(id, topic)`.
- **Both pages** are loaded with base URL `https://localhost/`, because YouTube's player refuses file pages. The app injects `window.__NATIVE` and the saved files (`window.__STORE`) before the page's script runs; the dashboard also gets `window.__SETTINGS` and `window.__TAB`.
- **Page to app:** `window.webkit.messageHandlers.native.postMessage({type, ...})`. Types:
  - `store`: save a key to disk. Log saves are mirrored to the other page via `__syncLogs`.
  - `resize` (panel or Island height), `showPanel`, `hidePanel`, `clock` (menu bar text), `notice` (show or clear the Island), `notify`.
  - `resolve`: find a YouTube stream ID; answered with `ytResolved(i, id)`.
  - `openDashboard` (with a `tab`), `quit`, `copy`, `csv`.
  - Dashboard settings: `setLaunchAtLogin`, `chooseLogFolder`, `revealLogFolder`, `checkUpdates`; answered with `settingsChanged({...})`.
- **App to page:** `start()` (the ⌃⌥Space shortcut), `tick()`, `panelVisible()`, `noticeAction()`, `ytResolved()`, `__syncLogs()`, `settingsChanged()`, `showTab()`.

## Timer rules

- Look: light mode is a soft blue-grey; the clock card is bright blue (`#1f5cf2`) with rings in the corner; the state shows in its pill, progress line and a soft glow (none when ready, light blue focusing, amber paused, green on a break). Dark mode is near-black (`#161616`), the clock card black with a soft glow of the state's colour. The radio is a compact card: the station's cover art (its YouTube thumbnail) in a square on the left, the station name (click for the list) and controls beside it, with a blurred copy of the cover tinting the card. Volume is a button that slides a short slider open beside it, pushing the other controls right (scrolling over it works too). Cards use 20px corners, the same as the panel. The YouTube player only plays the sound: it stays a normal size but hidden, since YouTube won't play in a tiny player. Every gap between cards is 12px. Both use the same bevel: a lit top edge, a soft lower edge and a shadow below each card. All text uses Manrope (`--font`), except the log folder path (system monospace).
- Game (`game.js`), all worked out from the log: the **streak** counts days that reach the daily goal (`goalMin`, 120 by default); vacation days (`vacation` date ranges) are skipped, and today can still be closed. **Levels**: 1 XP per focused minute, level n needs 150·(n−1)² XP. **Badges**: lights-out nights (7 to 365), focus hours (10 to 1,000), best streak (7 to 365) and specials; a new one, a new level or a reached goal shows in the Island once nothing else is asked (`checkUnlocks`, remembered in the state as `badgesSeen`, `levelSeen`, `goalSeen`).
- Bedtime: `tide.game` holds `bedOn`, `bedAt` (22:00), `factsAt` (22:01) and `nightOff` (the night taken off). A night runs until 5 AM. After bedtime the timer can't start (a running session finishes), and every 25 seconds the app (`bedtimeCheck`) records the latest time the Mac is in use from 6 PM in `tide.nights` and, while it's in use, asks the panel for a reminder every 5 minutes (`bedtimeNudge`). A night counts as lights out when the Mac was last used within 30 minutes of bedtime. From that time (`isLockTime`) the Island only offers **Lock now** (the app calls `SACLockScreenImmediate`, falling back to `pmset displaysleepnow`), stays up, and gives a small shake every 25 seconds with the next sleep fact.
- Clicking the time cycles count up → Pomodoro 30 → 60 → 90. Breaks: 5, 15 and 20 minutes (`BREAK_FOR`); a break started from count up is 5 minutes. Naming: **the Island** is the card that drops from the notch; **notifications** are macOS's own (the idle nudge, updates).
- Buttons by state: idle *Start Focus*; focusing *Pause*; paused *Resume, End focus*; break *Pause, Skip break*; break paused *Resume, Start Focus*. There is no manual break: breaks aren't logged, so ending focus and starting again later does the same. A break is only offered after a finished Pomodoro block.
- Buttons sit side by side (`.duo`): the main action solid blue, a second one a raised pill.
- Short notes ("Under 1 min, so not logged.") replace the line under the clock for a few seconds (`say()`). Dashboard, Settings, Theme and Quit are in the round-button menu at the top right of the panel, next to the greeting; the streak chip sits in the clock card. Theme cycles Match the Mac → Light → Dark; the app saves it (`theme` in UserDefaults) and sets `NSApp.appearance`, so every window follows.
- A finished block asks *Log it / Keep going*. Log it asks the topic, then *Take break / Start Focus*. Keep going adds a 30-minute block, logged as one session with the first; ending it early asks *Log it / Keep going* again.
- Ending a Pomodoro early isn't logged; count-up under a minute isn't logged; breaks aren't logged. A finished break asks *Start Focus / +5 min*.
- A session running when the app quits comes back paused, counting time up to the last save.
- After 30 minutes idle (no timer, no break, no open question) the panel sends a `nudge`; the app posts a notification in the `NUDGE` category, whose **Let's start** action calls `startCountUp()`. It repeats every 30 minutes while idle.

## Stations

Each station in `STATIONS` (in `panel.html`) stores a channel, title words to match, and a last known video ID. At launch the app reads each channel's `/streams` page, finds the live stream whose title matches, and saves the current ID (`S.ytIds`). If a stream fails, it looks it up again and retries once. The player is created idle at launch, because a freshly created YouTube player starts muted.

## Design

- Manrope for all text; light and dark mode through `prefers-color-scheme`.
- Manrope is bundled (`src/fonts/Manrope.ttf`, SIL Open Font License in `src/fonts/OFL.txt`, shipped with the app as `Manrope-OFL.txt`). Pages are loaded from a web address and can't read files, so the app adds the font as data at page start (`fontScript` in `main.swift`); the pages' own `@font-face` ("Manrope Preview") is only for the browser preview. Keep the panel short: it should fit under the menu bar on a small laptop screen.
- Show a mockup (a PNG rendered with headless Chrome) before building a new screen.

## Testing

- Browser previews: `python3 -m http.server 8765 --directory src`, then:
  - `panel.html?demo` (focusing), `?demo=idle`, `?demo=paused`, `?demo=break`, `?demo=done`, `?demo=topic`
  - `panel.html?demo=night` (after bedtime)
  - `dashboard.html?demo&tab=progress`
  - `island.html?demo=break`, `?demo=done`, `?demo=topic`, `?demo=bed`
- The real Island, without a real session: restart the app with a test question. It waits for the old copy to exit and retries `open`, which fails with error -600 while macOS is still closing the app. Any button just closes the Island; nothing is logged and the timer isn't touched.
  ```bash
  osascript -e 'quit app "Tide"'; while pgrep -xq "Tide"; do sleep 0.2; done; until open -a "Tide" --args --test-island done 2>/dev/null; do sleep 0.5; done    # or break, topic, bed, lock, badge
  ```
  - `dashboard.html?demo` (two weeks of sample sessions), `&tab=sessions`, `&tab=settings`
- In a browser, data is kept in localStorage, not in your real log.
- After `./build.sh --install`, check the real app: the panel opens from the menu bar, a session logs, the radio keeps playing with the panel closed.
- README screenshots: render the demo pages with headless Chrome, for example:

  ```bash
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --force-device-scale-factor=2 --window-size=380,580 --screenshot=docs/screenshots/panel-focus.png "http://127.0.0.1:8765/panel.html?demo"
  ```

  Add `--force-dark-mode` for dark screenshots.
