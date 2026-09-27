<p align="center">
  <img src="JustDoodle/Assets.xcassets/AppIcon.appiconset/JustDoodleAppIcon.png" width="120" alt="Just Doodle jd. handwritten monogram with a blue underline">
</p>

<h1 align="center">Just Doodle</h1>

<p align="center"><strong>One scribble. Your imagination. No eraser.</strong></p>
<p align="center">A little drawing game for iPhone and iPad, from The Doodler's Club.</p>

<p align="center">
  <a href="https://github.com/kushsarora/JustDoodle/actions/workflows/ios.yml"><img src="https://github.com/kushsarora/JustDoodle/actions/workflows/ios.yml/badge.svg?branch=master" alt="iOS Release Checks workflow status"></a>
</p>

<p align="center">
  <a href="#a-look-inside">Screenshots</a> &middot;
  <a href="#run-it-locally">Run the app</a> &middot;
  <a href="AppStore/ReviewScreenshots/README.md">Full gallery</a> &middot;
  <a href="AppStore/RELEASE.md">Release checklist</a>
</p>

---

Just Doodle starts with an imperfect line. Turn it into something unexpected before the timer runs out, then keep it in your Doodle Book or share it. Hand-inked windows, handwritten type, notebook paper, and little touches of blue and yellow carry through every screen.

**Native SwiftUI + PencilKit. iOS 16+. No accounts, ads, or external dependencies.**

The September 27 signature refresh includes a new app icon, transparent monogram, and matching wordmarks. See the [branding kit](Branding/README.md) for the assets and [Apple launch guide](AppStore/GETTING_STARTED.md) for the owner-facing release steps.

## A Look Inside

<table>
  <tr>
    <th>Welcome to the club</th>
    <th>Make the line your own</th>
    <th>Keep what you made</th>
  </tr>
  <tr>
    <td><a href="AppStore/ReviewScreenshots/iPhone-Home.png"><img src="AppStore/ReviewScreenshots/iPhone-Home.png" width="240" alt="Home screen with handwritten Just Doodle title, Start drawing, Doodle Book, and Challenges"></a></td>
    <td><a href="AppStore/ReviewScreenshots/iPhone-Drawing.png"><img src="AppStore/ReviewScreenshots/iPhone-Drawing.png" width="240" alt="Classic drawing screen with a scribble, countdown, Done button, and Idea Box"></a></td>
    <td><a href="AppStore/ReviewScreenshots/iPhone-Result.png"><img src="AppStore/ReviewScreenshots/iPhone-Result.png" width="240" alt="Finished drawing with save, share, and next-round actions"></a></td>
  </tr>
</table>

Actual simulator captures: home refreshed September 27, 2026; drawing and result from September 17-19. Drawings contain automated test strokes, not finished App Store artwork. Tap any image for full size, or browse the [complete gallery](AppStore/ReviewScreenshots/README.md) for challenges, the Doodle Book, settings, large text, and iPad layouts.

## One Line, Lots of Possibilities

1. **Start with a scribble.** A smooth, randomly generated line becomes the beginning of your drawing.
2. **Make something of it.** Classic gives you three minutes and one black pen. No erasing, no undo. Need a nudge? Tap the Idea Box for a fresh one-word prompt, as often as you like.
3. **Call it finished.** Tap **Done** whenever you're ready, or let the timer finish the round. Your drawing saves to the local Doodle Book.
4. **Keep going.** Save to Photos, share through the iOS share sheet, search your past drawings, or start another round with the same rules.

Unfinished sessions recover after relaunch, and the timer includes time spent in the background. Optional time-up vibration replaces sound effects. Brief transitions and pen feedback respect Reduce Motion.

## Change the Rules

Every mode keeps the original scribble and the no-eraser, no-undo rule.

| Mode | Time | Ink | Starting point |
| :--- | :--- | :--- | :--- |
| **Classic** | 3 min | Black | Turn the scribble into anything. |
| **Quick Spark** | 1 min | Black | Make it recognizable before time runs out. |
| **Build It** | 5 min | Black, blue | Invent something useful from the scribble. |
| **Mood Lines** | 5 min | Black, red | Draw the feeling your day left behind. |
| **Soundtrack Sketch** | 10 min | Black, blue, red | Let whatever you hear shape the scribble. |
| **Custom** | 1, 3, 5, 10, or 15 min | One, two, or three inks | Choose your own constraints. |

Soundtrack Sketch works with whatever you're already listening to. The app does not play music or connect to a streaming service. Public feeds, music integrations, and artist collaborations are not part of this build.

## Your Doodle Book Stays Yours

- Drawings, challenge details, and a recoverable draft live on the device. Apple-managed device backups may include them.
- No app accounts, tracking, analytics, advertising, or backend services.
- Photos access is add-only and requested when you explicitly save an image.
- Sharing sends the selected image and caption to the destination you choose in the system share sheet.

The app includes an offline privacy page. Public-facing [privacy](Website/privacy.html) and [support](Website/support.html) pages are also provided in this repo; hosting is still a release task.

## Run It Locally

**You'll need:** a Mac, Xcode 26.3 or later, and an installed iOS simulator. Xcode 26.3 is the currently configured CI toolchain. Physical-device builds also need your own Apple developer team and signing identity.

Clone the repository, then open the Xcode project:

```bash
git clone https://github.com/kushsarora/JustDoodle.git
cd JustDoodle
open JustDoodle.xcodeproj
```

For private-repository access, your GitHub account must have access and Git must be authenticated. If using GitHub CLI, run `gh auth login` and `gh auth setup-git` first, or clone with `gh repo clone kushsarora/JustDoodle`.

In Xcode, select the shared **JustDoodle** scheme, choose an iPhone or iPad simulator, and run. There are no package installs, API keys, or backend setup steps.

## Check a Build

From the repository root:

```bash
bash scripts/check.sh 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Use the name of an installed simulator if yours differs. The script:

1. Validates property lists, asset-catalog JSON, and diff whitespace.
2. Runs unit and UI tests, saving an `.xcresult` bundle.
3. Builds an unsigned device Release archive.
4. Checks the archive's structure, binary, assets, and privacy manifest.

The output directory is printed when the script finishes. Set `RESULTS_DIR` to a fresh directory to choose where results go. Debug UI tests use isolated storage so they don't overwrite a personal Doodle Book.

The [iOS Release Checks workflow](.github/workflows/ios.yml) runs the same script on pushes to `master` and pull requests. It **does not sign, upload, or publish the app**. See [Actions](https://github.com/kushsarora/JustDoodle/actions/workflows/ios.yml) for current run results and [review notes](AppStore/REVIEW.md) for recorded local iPhone/iPad checks.

## Find Your Way Around

| Area | Start here |
| :--- | :--- |
| Screens and navigation | [ContentView.swift](JustDoodle/ContentView.swift), [DoodleViews.swift](JustDoodle/DoodleViews.swift) |
| Hand-drawn design system | [NotebookStyle.swift](JustDoodle/NotebookStyle.swift) |
| Timer, session lifecycle, and recovery | [DoodleGame.swift](JustDoodle/DoodleGame.swift) |
| Challenge rules and archive models | [DoodleModels.swift](JustDoodle/DoodleModels.swift) |
| PencilKit canvas and scribble generation | [DrawingCanvas.swift](JustDoodle/DrawingCanvas.swift) |
| Image rendering and export | [DoodleRenderer.swift](JustDoodle/DoodleRenderer.swift), [Sharing.swift](JustDoodle/Sharing.swift) |
| Atomic local storage | [DoodleArchiveStore.swift](JustDoodle/DoodleArchiveStore.swift) |
| Saved drawings and preferences | [ArchivePreviewView.swift](JustDoodle/ArchivePreviewView.swift), [SettingsView.swift](JustDoodle/SettingsView.swift) |
| Regression coverage | [Tests](Tests/), [UITests](UITests/) |

The canvas and renderer share a **360 x 480 drawing coordinate system**, keeping the player's ink aligned with the original scribble across screen sizes and exports.

## Release Status

**In development, with a locally verified release candidate. Not yet submitted to the App Store.**

The September 20 handoff records passing local iPhone/iPad checks and an unsigned Release archive validation. Those checks do not replace signed-build validation, physical-device testing, or Apple's review.

| In the repository | Still needed before release |
| :--- | :--- |
| Playable app, app icon, privacy manifest | Owner's Apple signing team and App Store Connect setup |
| Unit/UI tests and unsigned archive checks | Physical-device and TestFlight verification |
| Privacy and support HTML | Public HTTPS hosting and release privacy URL |
| Draft listing and UI review captures | Final metadata and screenshots with real drawings |
| Release checklist and submission-check script | Signed archive, Apple validation, and submission |

**Release documents:** [Checklist](AppStore/RELEASE.md) &middot; [Draft listing](AppStore/metadata.md) &middot; [Verification record](AppStore/REVIEW.md) &middot; [Screenshot gallery](AppStore/ReviewScreenshots/README.md)

**Support:** [kushsarora@gmail.com](mailto:kushsarora@gmail.com)
