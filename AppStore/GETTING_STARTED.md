# Getting Just Doodle onto the App Store

Owner's launch guide, checked against Apple's documentation on September 27, 2026. The app is not submitted or approved yet. The technical checklist lives in [RELEASE.md](RELEASE.md).

## 1. Enroll with Apple

Join the **Apple Developer Program**, not the Enterprise Program. Membership is **US$99 per year**, or local pricing. An individual membership shows your legal name as the seller. An organization membership requires a legal entity and usually a D-U-N-S Number. Individual enrollment requires the legal age of majority in your region and an Apple Account with two-factor authentication. [Apple enrollment guide](https://developer.apple.com/programs/enroll/).

Use the account that should own the app long-term. Do not send passwords, verification codes, or signing certificates through chat.

## 2. Connect Xcode to Your Team

Open `JustDoodle.xcodeproj`. Add your Apple Account in Xcode Settings, select the **JustDoodle** app target, then open **Signing & Capabilities**, enable automatic signing, and choose your paid developer team. Run on a connected iPhone first. Apple's [distribution guide](https://developer.apple.com/documentation/Xcode/distributing-your-app-for-beta-testing-and-releases) covers signing and distribution.

This project's bundle identifier is **`com.kusharora.JustDoodle`**. Confirm that your team can register/use it before creating the store record. Do not casually change it later: the identifier is part of the app's identity and local data container.

The repository currently uses Xcode 26.3. Apple's April 28, 2026 minimum is Xcode 26 with the iOS 26 SDK or later. Check the [current submission requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a) again at upload time. The minimum iOS version users can run remains a separate setting, currently iOS 16.

## 3. Create the App Store Connect Record

In [App Store Connect](https://appstoreconnect.apple.com), open **Apps**, choose **+**, then **New App**. Use the following starting values, confirming availability in your account. [Apple's new-app instructions](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/).

| Field | Value |
| :--- | :--- |
| Platform | iOS, covering this app's iPhone and iPad build |
| Name | Just Doodle, subject to availability |
| Primary language | English |
| Bundle ID | The registered identifier matching Xcode |
| SKU | An owner-chosen unique internal code, such as `justdoodle-ios-001` |

Only create the record once. Complete agreements and any account information Apple requests in your own account.

## 4. Publish Support and Privacy Pages

The files are already written: [support.html](../Website/support.html) and [privacy.html](../Website/privacy.html). Publish them on a public HTTPS website accessible without a login. A private GitHub file link is not a public support website.

Enter the hosted URLs in App Store Connect. Apple requires a privacy-policy URL for all apps. [App Privacy instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/).

In the app target's Release build settings, add the user-defined setting **`JUST_DOODLE_PRIVACY_URL`** with the full hosted privacy URL before archiving. This supplies the online policy link in Settings; the offline policy is already included. Support email is **kushsarora@gmail.com**.

## 5. Upload a Build and Test It

Run the repository checks first:

```bash
bash scripts/check.sh 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Then select the shared **JustDoodle** scheme and a generic iOS device destination in Xcode, choose **Product > Archive**, and use Organizer to validate and distribute the signed archive to **App Store Connect**. Increase the build number for subsequent uploads. The script's unsigned archive is not an uploadable substitute. [Apple upload instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev442d7f2ca.html).

Once the build has processed, configure TestFlight and invite testers. External testing may require beta review. [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).

For this app, verify these on real hardware before release:

- Finger drawing on iPhone and Apple Pencil on a supported iPad.
- Three-minute Classic, early **Done**, automatic finish, and time-up vibration.
- Backgrounding, force-quitting, and recovering a draft without losing the drawing.
- Photos access allowed and denied, share-sheet dismissal, and Doodle Book save/delete.
- Small screens, large text, Reduce Motion, and iPad rotation.
- New icon on the Home Screen and new branding throughout the app.

## 6. Finish the Store Listing

Start from [metadata.md](metadata.md), then confirm the name, subtitle, description, keywords, categories, copyright holder, pricing, territories, review contact, age-rating questionnaire, export compliance, and App Privacy answers. Use the actual release build's behavior; the current app has no backend, accounts, ads, or analytics. The owner must still review Apple's data-collection definitions and any support practices. [Apple's submission overview](https://developer.apple.com/app-store/submitting/).

Make real drawings and capture the final UI for the device sizes App Store Connect requests. The [review gallery](ReviewScreenshots/README.md) contains automated test strokes and is not the final store screenshot set. [Apple screenshot guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/).

## 7. Submit, Then Release

Select the tested build, complete the required metadata, and choose **Add for Review**, then submit the draft submission. We recommend **manual release** so you can coordinate launch after approval. Watch App Store Connect for reviewer questions. Approval and review timing are Apple's decision. [Apple submission instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/).

Before submission, run the repository's additional gate on the signed archive:

```bash
bash scripts/validate-archive.sh /path/to/JustDoodle.xcarchive --submission
```

This checks local signing-related prerequisites and the policy URL; it is not Apple's validation or a guarantee of acceptance.

## What to Bring Back

- Confirmation that your Apple Developer membership is active and whether it is individual or organization.
- Your selected team name/Team ID and confirmation of the bundle identifier, not credentials.
- The public support and privacy URLs.
- Your decisions on pricing, launch territories, and legal copyright-holder name.
- Your feedback after trying the build, especially the new branding.

No Apple enrollment, signing identity, store record, hosted website, or submission is created by this guide.
