# Sumi Hub

All-in-one study tool for students. Native macOS app (SwiftUI) built with one philosophy: **practice, not production** — no leaderboards, no gamified pressure. Track hours with honesty, review weekly, protect rest.

## Features

- **Focus room** — pomodoro + flow timer, focus goals, streak tracking, zen quotes, interruption-aware focus notice
- **Ambience** — fully synthesized rain / fireplace / white noise / deep focus (no audio files, generated live)
- **Stats & weekly review** — daily goals, "days at goal" marker, streak mercy, weekly narrative letter you can save to Notes
- **Notes** — Obsidian/Word-style markdown editor with formatting toolbar and preview
- **Schedule, habits, mood check-in** — quiet, structured, self-contained
- **Sumi theme** — warm-dark moss/rust look with bundled Shippori Mincho display type (Dark mode also included)

## Requirements

- macOS 14+ (Apple Silicon)
- Xcode 15+ to build

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project "Sumi Hub/Sumi Hub.xcodeproj" \
  -scheme "Sumi Hub" -configuration Release \
  -derivedDataPath build build
```

The built app is at `build/Build/Products/Release/Sumi Hub.app`.

## Releases

Binary releases (`.zip` of the app) are available under [Releases](../../releases). Betas are signed ad-hoc — on other Macs you may need to right-click → Open once to bypass Gatekeeper.

## License

[MIT](LICENSE)