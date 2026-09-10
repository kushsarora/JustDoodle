# Release Candidate Review

Reviewed September 6, 2026; verification resumed September 8, 2026. This is a local release candidate, not an App Store submission.

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

## Verification

Results are kept in native xcresult bundles under `/private/tmp/`. These are local verification artifacts, not App Store upload receipts.

- `JustDoodle-Compact-1.xcresult`: all 25 unit tests passed on iPhone SE (3rd generation). Eight UI tests passed, including Photos allowed/denied, drawing recovery, sharing, and large text. One leave-dialog test was terminated; the iPad-only test was correctly skipped.
- `JustDoodle-iPad-1.xcresult`: rotation and large-text tests passed on iPad Pro 13-inch. The share test required a case-insensitive match for the native "close" button.
- Screenshot inspection caught a truncated Done label at the largest text size. Its symbol and text now size independently within the stable touch target.
- September 8 rerun: simulator installation/launch and archive build operations stalled. The two review commands were interrupted; `JustDoodle-Final-Dialogs.xcresult` is not a passing report and `JustDoodle-Release-Final.xcarchive` is not a completed archive. The final Done-label adjustment still needs a completed build and visual check. Rerun the compact-iPhone leave dialog, iPad share dismissal, and iPad full-screen landscape capture.

- Xcode 26.3, build 17C529; SDK iOS 26.2; simulator runtime iOS 26.3.1.
- The September 6 unsigned arm64 Release archive built successfully at `/private/tmp/JustDoodle-Release.xcarchive`. It predates the final Done-label adjustment.
- Structural archive validation passed. The packaged privacy manifest and iPhone/iPad icons are present. The source App Store icon is 1024 x 1024 with no alpha channel.
- The submission gate correctly rejects the archive because the hosted privacy URL has not been configured. Signing is also still required.
- Shell syntax, project/plist validation, workflow YAML parsing, and `git diff --check` passed.

The initial UI runs exposed test assumptions about PencilKit's accessibility type and iOS 26 dialogs. A separate test simulator was used after the open simulator's test-runner service failed. A genuine SwiftUI publishing-during-update warning was corrected in the PencilKit bridge; it did not recur in the subsequent full iPhone run.

## Remaining Release Gates

1. The owner must supply a paid Apple Developer team and distribution signing. No valid signing identity was available locally during this review.
2. Host `Website/privacy.html` and `Website/support.html` on public HTTPS URLs. Set `JUST_DOODLE_PRIVACY_URL` for the signed archive and enter both URLs in App Store Connect. The supplied support address is `kushsarora@gmail.com`.
3. Verify physical-device finger/Apple Pencil feel, time-up vibration, interruptions, and long sessions through TestFlight. Test the oldest supported iOS version as well as the current release; the local runtime only covers iOS 26.3.1.
4. Confirm listing ownership, age-rating/privacy answers, export compliance, pricing, territories, and the next unused build number. Capture store screenshots using real finished artwork at Apple's required sizes.
5. Run the CI workflow after pushing; the hosted GitHub job has not run for these unpushed changes. Validate and upload the signed archive through Xcode Organizer, then obtain App Review approval.

No code was published, no App Store record was changed, and no release was submitted during this review.
