import SwiftUI

enum ReleaseInfo {
    static let supportEmail = "kushsarora@gmail.com"
    static let supportMailURL = URL(string: "mailto:kushsarora@gmail.com?subject=Just%20Doodle%20Support")!
    static var privacyURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "JustDoodlePrivacyURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingPrivacy = false
    let close: () -> Void

    var body: some View {
        Group {
            if showingPrivacy {
                PrivacyPolicyView { showingPrivacy = false }
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    InkPageHeader(title: "Settings", back: close)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 10) {
                                InkSectionTitle(title: "Drawing", symbol: "pencil.tip")
                                Toggle(isOn: $hapticsEnabled) {
                                    Text("Time-up vibration").font(.doodleBody(20))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .tint(Ink.blue).frame(minHeight: 52)
                                .accessibilityIdentifier("hapticsToggle")
                                InkDivider()
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                InkSectionTitle(title: "Privacy & Support", symbol: "hand.raised")
                                HomeNavigationRow(title: "Privacy policy", symbol: "lock", detail: nil, accent: .yellow) {
                                    showingPrivacy = true
                                }
                                .accessibilityLabel("Privacy policy")
                                Link(destination: ReleaseInfo.supportMailURL) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "envelope").font(.system(size: 24))
                                            .frame(width: 42, height: 44)
                                        Text("Contact support").font(.doodleTitle(21))
                                            .lineLimit(1).minimumScaleFactor(0.65)
                                        Spacer(minLength: 0)
                                        Image(systemName: "arrow.up.right").font(.system(size: 15))
                                    }
                                    .frame(minHeight: 56)
                                    .overlay(alignment: .top) { InkDivider() }
                                }
                                .buttonStyle(InkPressStyle())
                            }
                            VStack(spacing: 10) {
                                Image("DoodlersClubMark").resizable().scaledToFit()
                                    .frame(width: 72, height: 72).accessibilityHidden(true)
                                Text("The Doodler's Club").font(.doodleTitle(23))
                                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                    .font(.doodleBody(16)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                        }
                        .frame(maxWidth: 580).padding(24).frame(maxWidth: .infinity)
                    }
                    .clipped().padding(.bottom, 14)
                }
                .foregroundStyle(Ink.black)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .modifier(InkWindow())
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showingPrivacy)
    }
}

struct PrivacyPolicyView: View {
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            InkPageHeader(title: "Privacy Policy", backLabel: "Back to settings", back: close)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your drawings belong to you.").font(.doodleTitle(29))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Just Doodle does not collect or send your drawings, personal information, or usage data to us. There are no accounts, ads, analytics, or tracking SDKs.")
                    Text("Drawings, unfinished drafts, and preferences are stored on your device. They may be included in backups managed by Apple according to your device settings. Just Doodle does not operate a cloud storage service.")
                    Text("Photos access is requested only when you choose Save to Photos. The app can add the drawing you select; it does not read your photo library.")
                    Text("Sharing is optional. When you use the system share sheet, the drawing and caption are sent to the app or recipient you choose. That service's privacy policy applies. Just Doodle does not upload drawings automatically.")
                    Text("Delete drawings in the Doodle Book, or discard an unfinished draft. Removing Just Doodle from your device removes its local data. Copies already exported, shared, or backed up must be managed in those locations.")
                    Text("Support emails are used to respond to your request. Do not include sensitive information or private drawings unless you intend to share them with support.")
                    Link(ReleaseInfo.supportEmail, destination: ReleaseInfo.supportMailURL)
                    if let url = ReleaseInfo.privacyURL { Link("Privacy policy on the web", destination: url) }
                    Text("Effective September 6, 2026").font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(24).frame(maxWidth: .infinity)
            }
            .clipped().padding(.bottom, 14)
        }
        .foregroundStyle(Ink.black)
        .modifier(InkWindow())
    }
}
