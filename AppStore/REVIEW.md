# Release Candidate Review

UI and simulator verification completed September 9, 2026; release packaging resumed September 10. This is a local release candidate for owner playtesting, not an App Store submission.

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
- The current unsigned arm64 Release archive built successfully at `/private/tmp/JustDoodle-September10-Release.xcarchive`. Structural validation passed: device SDK, executable architecture, packaged privacy manifest, and asset catalog. The older September 6 archive predates this UI overhaul and must not be used for the current release.
- The submission gate correctly rejects the current archive because `JUST_DOODLE_PRIVACY_URL` is not configured with a published HTTPS policy. This is expected, not a successful submission validation; distribution signing is also still required.
- The source App Store icon is 1024 x 1024 with no alpha channel. The hosted privacy URL and distribution signing remain unconfigured.
- Shell syntax, project/plist validation, workflow YAML parsing, and `git diff --check` passed.

The initial UI runs exposed test assumptions about PencilKit's accessibility type and iOS 26 dialogs. A separate test simulator was used after the open simulator's test-runner service failed. A genuine SwiftUI publishing-during-update warning was corrected in the PencilKit bridge; it did not recur in the subsequent full iPhone run.

## Remaining Release Gates

1. The owner must supply a paid Apple Developer team and distribution signing. No valid signing identity was available locally during this review.
2. Host `Website/privacy.html` and `Website/support.html` on public HTTPS URLs. Set `JUST_DOODLE_PRIVACY_URL` for the signed archive and enter both URLs in App Store Connect. The supplied support address is `kushsarora@gmail.com`.
3. Verify physical-device finger/Apple Pencil feel, time-up vibration, interruptions, and long sessions through TestFlight. Test the oldest supported iOS version as well as the current release; the local runtime only covers iOS 26.3.1.
4. Confirm listing ownership, age-rating/privacy answers, export compliance, pricing, territories, and the next unused build number. Capture store screenshots using real finished artwork at Apple's required sizes.
5. Run the CI workflow after pushing; the hosted GitHub job has not run for these unpushed changes. Validate and upload the signed archive through Xcode Organizer, then obtain App Review approval.

## GitHub

The pre-overhaul changes were committed locally as `ff4523d`. The requested push was rejected with HTTP 403: "Your account is suspended." GitHub Support must resolve the account restriction before publishing these commits. No remote branch was updated, no App Store record was changed, and no release was submitted.
