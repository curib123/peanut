# Release browser smoke test

`tool/browser_smoke.cjs` exercises the compiled Flutter web app with Playwright. It checks real navigation, setting persistence across reload, individual map actions, a valid board drag, portrait/landscape/tablet layout, pause/resume state preservation, packaged audio playback and browser errors. It writes nine captures and `results.json` under ignored `tmp/browser-smoke/`. Actual level wins and saved unlocks are covered by `test/integration/victory_continuation_test.dart`.

Build and serve the release in one terminal:

```powershell
flutter build web --release --no-pub --no-wasm-dry-run
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

In a second terminal:

```powershell
npm.cmd install --prefix tmp/browser-tools playwright
node tmp/browser-tools/node_modules/playwright/cli.js install chromium
node tool/browser_smoke.cjs
```

Optional environment variables: `GAME_URL`, `SMOKE_OUTPUT`, `PLAYWRIGHT_MODULE` (a module path), and `CHROMIUM_EXECUTABLE` (a browser executable). An installed Chromium headless shell works when the normal desktop browser cannot launch in automation. The script uses a fresh isolated browser context and does not change a personal browser profile.

Level 1's seeded opening move and the board's 12-pixel padding are intentionally explicit in this smoke scenario. Update that scenario if level generation or board layout changes.
