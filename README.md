# Just Doodle

Just Doodle is a SwiftUI iOS app for turning one imperfect line into something unexpected.

## Core Flow

- Fade from "The Doodler's Club" into a hand-inked app window with a signature masthead and animated scribble.
- Tap Start drawing to reveal a smoothly generated scribble.
- Draw in the three-minute Classic Mode with one black pen and no eraser or undo.
- Tap the hand-drawn Idea Box whenever inspiration runs dry for a fresh one-word prompt.
- Tap the visible Done button to finish early, or save automatically when time expires.
- Recover an unfinished drawing after relaunch. The timer includes background time.
- Start another round with the same rules directly from the saved result.
- Browse completed drawings in a date-ordered local Doodle Book, searchable by challenge, idea, or displayed date.
- Save finished work to Photos or share it with a social-ready caption.

## Challenge Mode

- Pick a local Doodle Pack with its own instruction, timer, and ink constraints.
- Try Quick Spark, Build It, Mood Lines, or Soundtrack Sketch.
- Build a custom challenge with a 1, 3, 5, 10, or 15 minute timer.
- Choose black-only, two-ink, or three-ink palettes while keeping erasing and undo locked.
- Feel a warning haptic when time expires; the app intentionally has no sound effects.
- Keep challenge, elapsed time, ink palette, and Idea Box context in the local Doodle Book.

Music services, public feeds, and artist collaborations are intentionally outside the local-first build. Soundtrack Sketch lets people bring their own music without requiring accounts, tracking, or licensed partner content.

The interface uses Apple's built-in Noteworthy face, double-stroked window borders, blue ink accents, and a yellow Idea Box. The ink-window design extends from home to drawing, results, challenges, the Doodle Book, saved-page previews, settings, and privacy. Compact title bars, drawn dividers, and consistent action strips keep navigation recognizable. An empty Doodle Book can start a drawing directly. Brief spring transitions, selected-pen feedback, and a drawn countdown ring respect Reduce Motion. Only the artwork surface is ruled, so page margins remain aligned across screen sizes and exports.

The app icon carries the same ruled-paper, red-margin, handwritten signature used throughout the game.

## Development

Open `JustDoodle.xcodeproj` in Xcode 26.3 or later and run the shared `JustDoodle` scheme. The minimum supported OS is iOS 16. Device builds require your own developer team and signing identity. There are no external packages or API keys.

```bash
bash scripts/check.sh 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The script runs unit/UI tests and builds an unsigned Release archive. Results are printed at completion. The GitHub Actions workflow runs the same checks with Xcode 26.3; it does not publish the app.

## Structure

- `ContentView.swift`, `DoodleViews.swift`: screens, controls, and Reduce Motion-aware transitions.
- `DoodleGame.swift`: session lifecycle, timer, draft recovery, and finish/save coordination.
- `DoodleModels.swift`: compatible archive models and challenge rules.
- `DrawingCanvas.swift`: locked PencilKit canvas and smooth, bounded scribble generation.
- `DoodleRenderer.swift`, `NotebookStyle.swift`: a shared 360 x 480 drawing coordinate system for screen and export. Resizing cannot move the player's ink relative to the scribble.
- `DoodleArchiveStore.swift`: actor-isolated, atomic local storage, thumbnail decoding, and error recovery.
- `Sharing.swift`, `ArchivePreviewView.swift`, `SettingsView.swift`: exports, saved drawings, privacy, and preferences.
- `Tests/`, `UITests/`: model/storage/rendering regressions and device workflows, with screenshot attachments.

Test sessions use isolated Application Support directories in Debug builds. Production has no test switches, tracking SDKs, network services, sound playback, eraser, or undo tool.

## Release

See [release steps](AppStore/RELEASE.md) and [draft store listing](AppStore/metadata.md). Public policy/support pages are in `Website/`; they still need an HTTPS host. Public support email: `kushsarora@gmail.com`.

A successful unsigned build is not a submitted app. Developer signing, hosted policy URLs, physical-device/TestFlight checks, owner metadata, and Apple's validation remain required before release.
