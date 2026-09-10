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
    let close: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Drawing") {
                    Toggle("Time-up vibration", isOn: $hapticsEnabled)
                        .accessibilityIdentifier("hapticsToggle")
                }
                Section("Privacy & Support") {
                    NavigationLink { PrivacyPolicyView() } label: {
                        Label("Privacy policy", systemImage: "hand.raised")
                    }
                    Link(destination: ReleaseInfo.supportMailURL) {
                        Label("Contact support", systemImage: "envelope")
                    }
                }
                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    Text("The Doodler's Club").font(.doodleTitle(21))
                }
            }
            .scrollContentBackground(.hidden)
            .background(NotebookColors.paper)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: close) { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Back to home")
                        .frame(width: 44, height: 44)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your drawings belong to you.").font(.doodleTitle(29))
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
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
