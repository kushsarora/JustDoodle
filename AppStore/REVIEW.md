# Release Candidate Review

Core release-candidate verification completed September 9, 2026; release packaging resumed September 10. A subsequent home-screen design iteration is documented below. Nothing has been submitted to the App Store.

## Home Screen Iteration

The September 10-11 home redesign follows the owner's hand-drawn window reference: a double-stroked frame, compact club title bar, animated scribble, bold Start drawing control, and direct Doodle Book/Challenges rows. Resume, discard, settings, and saved-page counts remain connected to the existing game state. Other game screens and rules are unchanged.

The final simulator test build succeeded. `JustDoodle-InkWindow-Compact.xcresult` contains five passing UI tests covering home navigation and bounds, Classic save/delete, challenges, draft recovery, and large text on iPhone SE. Normal and large-text home screenshots were visually inspected and saved in `ReviewScreenshots/`. The initial iPhone runner was killed before connecting to the app; `JustDoodle-InkWindow-iPhone.xcresult` is not a passing report.

Visual review on iPad exposed excessive spacing between Start and navigation. The content now stays grouped and vertically centered. After that adjustment, `JustDoodle-InkWindow-iPad-Final-Verified.xcresult` passed the home navigation/bounds test on iPad Pro 13-inch; its screenshot was inspected and saved as `ReviewScreenshots/iPad-Home.png`.

`JustDoodle-InkWindow-Compact-Final.xcresult` then passed both final iPhone SE checks: home navigation/bounds and large-text home-to-drawing controls. Updated normal and large-text screenshots were inspected with no clipped labels or overlapping controls. Together with the five earlier workflow tests, these verify the home iteration; they do not replace physical-device release testing.

The owner approved the home direction, and this iteration was pushed as `522820a` on September 17. It is not included in the earlier Release archive below.

## App-Wide Ink Window Iteration

The September 17 iteration carries the approved home design across the splash, drawing workspace, results, challenges/custom builder, Doodle Book, saved-drawing preview, settings, and privacy. Shared frame/header/divider components keep spacing consistent. Settings now uses hand-drawn rows with the native vibration switch; privacy has an explicit return path. The empty Doodle Book can begin a Classic drawing directly. System share sheets, Photos permissions, and destructive confirmation dialogs remain native.

The simulator test build passed. `JustDoodle-September17-Compact-Final.xcresult` contains 27 passing unit tests and 14 passing UI tests on iPhone SE, with only the iPad-only rotation test skipped. Coverage includes saving/deleting, replay/search, challenge palettes, recovery, Photos allowed/denied, sharing, home/result bounds, settings/privacy return navigation, and large-text drawing/secondary pages. Final screenshots are in `ReviewScreenshots/`.

The first run exposed a gallery-width regression and permission-dialog test timing failures. The grid now fits two columns on iPhone SE, scroll content stays inside the ink-window border, and the Photos test waits for the system dialog to settle and confirms dismissal. The final passing run supersedes `JustDoodle-September17-Compact.xcresult`, which had three failures. No signing, hosted policy configuration, store metadata, or game rules changed.

`JustDoodle-September19-iPad.xcresult` passed all four selected UI tests on iPad Pro 13-inch: portrait/landscape drawing alignment, large-text secondary pages, result bounds, and share-sheet dismissal. Landscape and large-text settings captures were visually inspected and saved alongside the iPhone captures.

A final layout-hardening pass explicitly sizes result and saved-preview artwork within the space remaining between the header and actions. The safe-area tests now compare result/preview headers with the home header, rather than a fixed 20-point threshold. `JustDoodle-September19-iPhone-Sizing.xcresult` passed four follow-up tests on iPhone 17 Pro (save/delete, large text, result bounds, sharing); `JustDoodle-September19-Compact-Sizing.xcresult` passed three on iPhone SE (save/delete, large text, result bounds). Normal and large-text results were visually inspected at original capture size. The earlier three-test iPhone run also passed, but predates this hardening.

`JustDoodle-September19-iPad-Sizing.xcresult` also passed the strengthened result-bounds test on the final layout. These checks complete the simulator UI verification for this iteration. Physical-device and TestFlight verification remain release gates.

## Changes

- Replaced the overlapping notebook backgrounds with one ruled drawing page. The timer is centered independently of the side controls.
- Refreshed the home, challenge list, drawing tools, results, Doodle Book, and settings while retaining Noteworthy and the existing club/app artwork.
- Fixed the reversed tangent at scribble endpoints. Bounded rotation, scale, and point variation make the generator less repetitive. Native PencilKit handles the player's stroke smoothing.
- Added short screen fades and press feedback, an end marker timed to the reveal, and Reduce Motion support. Removed continuous decorative animation.
- Exposed Done in Classic and challenges, with an explicit keep/finish/discard dialog. Early finish preserves actual elapsed time.
- Unified on-screen and exported drawing coordinates. Rotation and resizing preserve the relationship between the original scribble and the player's strokes.
- Added atomic, revision-ordered draft recovery and idempotent finish/save behavior. The timer includes background time.
- Preserved corrupt archives, surfaced storage failures, downsampled thumbnails, and recovered interrupted deletion transactions.
- Added accessible tool labels and full-size touch targets, large-text handling, Photos progress and denial recovery, and offline privacy/support settings.
- Added native unit/UI targets, a shared Xcode scheme, CI checks, a privacy manifest, public-policy source pages, listing copy, and archive validation scripts.
- Added a stitched sketchbook cover, two-line handwritten masthead, ink-on-paper entrance, drawn countdown ring, selected-pen feedback, and yellow Idea Box. The home entrance starts after the splash, not behind it.
- Added Draw again with the same challenge rules and a fresh scribble, searchable Doodle Book metadata, and visual ink-palette selection for custom challenges.

## Verification

Results are kept in native xcresult bundles under `/private/tmp/`. These are local verification artifacts, not App Store upload receipts.

- `JustDoodle-September9-iPhone.xcresult`: 27 unit tests and 10 UI tests passed on iPhone 17 Pro, with no failures. The iPad-only test was skipped. Coverage includes replay/search, recovery, Photos allowed/denied, sharing, early finish, archive deletion, settings, and large text.
- `JustDoodle-September9-Compact.xcresult`: four UI tests passed on iPhone SE (3rd generation): Classic save/delete, custom challenge palette, large-text drawing, and leave/cancel/discard.
- `JustDoodle-September9-Insets.xcresult`: the additional result-screen bounds check passed on the compact iPhone.
- `JustDoodle-September10-iPhoneInsets.xcresult`: the same result-screen bounds check also passed on iPhone 17 Pro after resuming verification.
- `JustDoodle-September9-iPad.xcresult`: four UI tests passed on iPad Pro 13-inch: portrait/landscape drawing geometry, large text, result-screen bounds, and share dismissal.
- Inspected actual home, challenge, drawing, result, large-text, and iPad landscape captures. Done is readable; the drawing page maintains its 3:4 aspect ratio; no duplicate notebook margins remain. Representative captures are in `ReviewScreenshots/`.
- These completed runs supersede the interrupted September 8 verification attempts. The old incomplete result bundle and archive are not release evidence.

- Xcode 26.3, build 17C529; SDK iOS 26.2; simulator runtime iOS 26.3.1.
- The pre-home-redesign unsigned arm64 Release archive built successfully at `/private/tmp/JustDoodle-September10-Release.xcarchive`. Structural validation passed: device SDK, executable architecture, packaged privacy manifest, and asset catalog. The older September 6 archive predates this UI overhaul and must not be used for the current release.
- The submission gate correctly rejects the current archive because `JUST_DOODLE_PRIVACY_URL` is not configured with a published HTTPS policy. This is expected, not a successful submission validation; distribution signing is also still required.
- The source App Store icon is 1024 x 1024 with no alpha channel. The hosted privacy URL and distribution signing remain unconfigured.
- Shell syntax, project/plist validation, workflow YAML parsing, and `git diff --check` passed.

The initial UI runs exposed test assumptions about PencilKit's accessibility type and iOS 26 dialogs. A separate test simulator was used after the open simulator's test-runner service failed. A genuine SwiftUI publishing-during-update warning was corrected in the PencilKit bridge; it did not recur in the subsequent full iPhone run.

## Remaining Release Gates

1. The owner must supply a paid Apple Developer team and distribution signing. No valid signing identity was available locally during this review.
2. Host `Website/privacy.html` and `Website/support.html` on public HTTPS URLs. Set `JUST_DOODLE_PRIVACY_URL` for the signed archive and enter both URLs in App Store Connect. The supplied support address is `kushsarora@gmail.com`.
3. Verify physical-device finger/Apple Pencil feel, time-up vibration, interruptions, and long sessions through TestFlight. Test the oldest supported iOS version as well as the current release; the local runtime only covers iOS 26.3.1.
4. Confirm listing ownership, age-rating/privacy answers, export compliance, pricing, territories, and the next unused build number. Capture store screenshots using real finished artwork at Apple's required sizes.
5. Review the hosted CI results after pushing; the local verification above does not establish hosted CI success. Validate and upload the signed archive through Xcode Organizer, then obtain App Review approval.

## GitHub

The pre-overhaul changes (`ff4523d`) and verified UI overhaul (`4f4362c`) were pushed to `kushsarora/JustDoodle` on September 10. The initial suspension error came from a different active GitHub account, not the verified `kushsarora` identity. Switching to the intended account resolved authentication; retrying with HTTP/1.1 and a buffered upload resolved a subsequent transport error. No App Store record was changed and no release was submitted.
