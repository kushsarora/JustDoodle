# Release Procedure

This repository can produce a tested release candidate. An unsigned local archive is not an App Store upload.

## Local Verification

Use Xcode 26 or later. iOS 16 remains the minimum supported operating system; the build SDK is newer.

```bash
bash scripts/check.sh 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Run the UI tests on a small iPhone and an iPad as well, using English-language simulators for system permission-dialog assertions. Screenshots are attached to the xcresult bundle. Test storage uses a separate UUID directory in Debug builds and never overwrites the user's Doodle Book. The latest review is in REVIEW.md.

## Before Submission

1. Publish Website/privacy.html and Website/support.html on a public HTTPS host. Verify both are accessible without a login.
2. Add the owner's Apple Developer account in Xcode and choose the correct paid developer team under Signing & Capabilities. Confirm ownership of com.kusharora.JustDoodle before changing it: an identifier change creates a separate app/data container.
3. Set JUST_DOODLE_PRIVACY_URL in the release build to the hosted policy address. The app displays that link in Settings. The local policy remains available offline.
4. Confirm the build number is higher than any previously uploaded build. Confirm app name, pricing, territories, age rating, App Privacy responses, export compliance, rights-holder name, and review contact.
5. Run tests and archive Release for Any iOS Device. Use Organizer to validate the signed archive and upload to App Store Connect.
6. Distribute through TestFlight. Verify finger drawing and Apple Pencil, stroke alignment after rotation, early Done, timeout vibration on a real iPhone, background/termination recovery, Photos allowed/denied, and share-sheet dismissal on iPhone and iPad.
7. Capture current app screenshots in the sizes required by App Store Connect, including a supported large iPhone and iPad. Review the captures for unfinished drawings, alerts, and test artifacts before uploading.
8. Run the submission gate on the signed archive:

```bash
bash scripts/validate-archive.sh /path/to/JustDoodle.xcarchive --submission
```

9. Complete Apple's validation and select a manual release after approval. Submit only after the owner has reviewed the listing and TestFlight build.

## Privacy Implementation

- No network calls, accounts, ads, tracking, analytics, or third-party SDKs in the app.
- UserDefaults stores only the time-up vibration preference. PrivacyInfo.xcprivacy declares CA92.1.
- Drawings and the recoverable draft stay in Application Support. Apple-managed device backups may include them.
- Photos permission is add-only and requested on explicit export.
- System sharing passes the chosen image and caption to a user-selected destination.
- Public policy and contact content are provided in Website/. No public hosting has been provisioned by this code change.

## Sources Checked September 6, 2026

- SDK submission requirement: https://developer.apple.com/app-store/submitting/
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Privacy: https://developer.apple.com/app-store/app-privacy-details/
- Required reason APIs: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- Age rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
