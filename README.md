# Just Doodle

Just Doodle is a SwiftUI iOS app for turning one imperfect line into something unexpected.

## Core Flow

- Fade from a handwritten "The Doodler's Club" splash into the home screen.
- Tap the central dot to reveal a curated scribble.
- Draw in the three-minute Classic Mode with one black pen and no eraser or undo.
- Tap the hand-drawn Idea Box whenever inspiration runs dry for a fresh one-word prompt.
- Freeze and save the drawing automatically when time expires.
- Browse completed drawings in a date-ordered local Doodle Book.
- Save finished work to Photos or share it with a social-ready caption.

## Challenge Mode

- Pick a local Doodle Pack with its own instruction, timer, and ink constraints.
- Try Quick Spark, Build It, Mood Lines, or Soundtrack Sketch.
- Build a custom challenge with a 1, 3, 5, 10, or 15 minute timer.
- Choose black-only, two-ink, or three-ink palettes while keeping erasing and undo locked.
- Feel a warning haptic when time expires; the app intentionally has no sound effects.
- Keep challenge and Idea Box context attached to saved Doodle Book entries and shares.

Music services, public feeds, and artist collaborations are intentionally outside the local-first build. Soundtrack Sketch lets people bring their own music without requiring accounts, tracking, or licensed partner content.

The opening uses Apple's built-in Noteworthy face as a temporary handwritten font. A custom Just Doodle typeface can replace it later without changing the screen flow.

The app icon carries the same ruled-paper, red-margin, handwritten signature used throughout the game.

Open `JustDoodle.xcodeproj` in Xcode and run the `JustDoodle` target on an iPhone simulator or device.
