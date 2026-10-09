# Tennis 🎾

Court-club tennis by Wajiha — drag along the baseline, time your swings, and
win the set with real tennis scoring (15-30-40, deuce, tiebreaks).

## Play

- **Vs CPU** (Easy / Medium / Hard) or **2-player pass-and-play** on one device.
- Drag to slide, tap SERVE / HIT (or tap your half) to swing.
- First to 4 games (win by 2); 3–3 goes to a 7-point tiebreak.

## Project layout

- `lib/engine/tennis_engine.dart` — match state machine, ball physics, AI,
  watchdog. The engine owns ALL phases; the UI only renders and forwards input.
- `lib/screens/` — splash (company moment → game splash), menu, match,
  settings, Pro, custom court creator.
- `lib/services/` — `TennisAudio` (synthesized WAV music/SFX, cached, busy-guarded),
  `TennisSettings` (persisted settings incl. order-safe player-name JSON),
  `StoreService` (real `in_app_purchase`: `tennispro` / `tenniscoffee` / `tennischocolate`).
- `lib/theme/` — 14 court themes, 8 racket styles, 8 ball styles + custom theme creator.
- `RULES.md` — the authoritative rules document (13 sections).

## Build

CI (`.github/workflows/build.yml`, manual dispatch) runs `flutter pub get`,
`flutter analyze`, then release-signs and builds APK + AAB.

Package: `com.gameswajiha.tennis`
