# Tide: notes for Claude Code

A focus timer and lofi radio in the macOS menu bar. How it fits together, the timer rules and testing are in **`CONTRIBUTING.md`**: read it before changing anything.

## Build and run
- `./build.sh --install` builds `build.noindex/Tide.app`, copies it to `/Applications` and opens it. `--zip` also makes the release zip.
- UI previews without rebuilding: `python3 -m http.server 8765 --directory src`, then `panel.html?demo` or `dashboard.html?demo`.
- Raise `version=` in `build.sh` for every release; the GitHub release tag must match (`v2.1` for 2.1), because the in-app update check compares them.

## Files
- `src/panel.html`: the menu bar panel. `src/dashboard.html`: the dashboard window. `src/game.js`: the goal, streak, level, badge and bedtime rules both use. `src/main.swift`: the native app.
- User data lives in `~/Library/Application Support/Tide/` (`Study Log.json`, `studyradio.state.json`, `tide.game.json`, `tide.nights.json`). Never overwrite it in tests; back it up first and restore it after.

## Rules from the owner
- Keep it simple. This is a personal tool: no skins. Game features stay quiet (a daily goal, streak, levels, badges), shown in one panel card and the Progress tab; no habit tracker (that lives in Notion).
- Bedtime is a firm rule: after bedtime the timer is off and the Island reminds every 5 minutes; nothing rewards staying up late.
- Font: Manrope (bundled in `src/fonts/`) for all text. Light and dark mode, short and clear text.
- Show a PNG mockup before building any new screen.

## Working style
- Small, focused changes; commit each working step with a clear message.
- Test pages in the browser preview, and the app itself after `./build.sh --install`. Say what was and wasn't checked.
- Keep README, CONTRIBUTING and this file up to date when behaviour changes.
