import Photos
import SwiftUI
import UIKit

struct PhotoExportButton: View {
    let image: UIImage
    @State private var isSaving = false
    @State private var message: String?
    @State private var showAlert = false
    @State private var needsSettings = false

    var body: some View {
        Button {
            guard !isSaving else { return }
            isSaving = true
            Task {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    isSaving = false
                    needsSettings = status == .denied
                    message = status == .restricted
                        ? "Photos access is restricted on this device."
                        : "Allow Just Doodle to add photos in Settings, then try again."
                    showAlert = true
                    return
                }
                do {
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                    message = "Your drawing is now in Photos."
                    needsSettings = false
                } catch {
                    message = error.localizedDescription
                    needsSettings = false
                }
                isSaving = false
                showAlert = true
            }
        } label: {
            ZStack {
                if isSaving { ProgressView() }
                else { Image(systemName: "square.and.arrow.down").font(.system(size: 18, weight: .semibold)) }
            }
            .foregroundStyle(Ink.black)
            .frame(width: 44, height: 44)
            .background(HandCircle().fill(Color.yellow.opacity(0.2)))
            .overlay(HandCircle().stroke(Ink.black, lineWidth: 1.2))
        }
        .buttonStyle(InkPressStyle())
        .disabled(isSaving)
        .accessibilityLabel(isSaving ? "Saving to Photos" : "Save to Photos")
        .accessibilityIdentifier("saveToPhotos")
        .help("Save to Photos")
        .alert("Photos", isPresented: $showAlert) {
            if needsSettings {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            Button("OK", role: .cancel) { }
        } message: { Text(message ?? "") }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let caption: String
}

enum Haptics {
    static func timeUp() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}

struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct CanvasSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension Date {
    var doodleDate: String {
        Self.doodleDateFormatter.string(from: self)
    }

    static let doodleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
