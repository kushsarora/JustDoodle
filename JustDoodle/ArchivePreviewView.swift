import SwiftUI

struct ArchivePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let record: DoodleRecord
    let archive: DoodleArchiveStore
    @State private var image: UIImage?
    @State private var loaded = false
    @State private var deleting = false
    @State private var confirmDelete = false
    @State private var shareImage: ShareImage?
    @State private var notice: Notice?

    var body: some View {
        ZStack {
            NotebookBackground()
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    IconButton(systemName: "xmark", label: "Close drawing") { dismiss() }
                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        Text(record.sessionTitle ?? "Classic").font(.doodleTitle(20))
                        Text(record.createdAt.doodleDate).font(.doodleBody(14))
                    }
                    .lineLimit(1).minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    IconButton(systemName: "trash", label: "Delete saved drawing") { confirmDelete = true }
                        .disabled(deleting)
                        .accessibilityIdentifier("deleteDrawing")
                }
                .foregroundStyle(Ink.black)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 8)
                .overlay(alignment: .bottom) { InkDivider() }

                if let image {
                    DoodleArtworkPreview(image: image, label: "Saved drawing")
                        .padding(.horizontal, 18)
                    HStack(spacing: 24) {
                        PhotoExportButton(image: image)
                        IconButton(systemName: "square.and.arrow.up", label: "Share drawing") {
                            shareImage = ShareImage(image: image, caption: record.shareCaption)
                        }
                        .accessibilityIdentifier("shareDrawing")
                    }
                    .frame(maxWidth: 420).padding(.top, 8)
                    .overlay(alignment: .top) { InkDivider() }
                    .padding(.horizontal, 24)
                } else {
                    Spacer()
                    if loaded {
                        Label("Drawing image unavailable", systemImage: "photo.badge.exclamationmark")
                            .foregroundStyle(.secondary)
                    } else { ProgressView() }
                    Spacer()
                }
                if deleting { ProgressView("Deleting...") }
            }
            .padding(.bottom, 16)
            .modifier(InkWindow())
        }
        .preferredColorScheme(.light)
        .task {
            image = await archive.image(for: record)
            loaded = true
        }
        .sheet(item: $shareImage) { ShareSheet(items: [$0.image, $0.caption]) }
        .confirmationDialog("Delete this drawing?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete drawing", role: .destructive) {
                deleting = true
                Task {
                    defer { deleting = false }
                    do {
                        try await archive.delete(record)
                        dismiss()
                    } catch {
                        notice = Notice(title: "Could Not Delete", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert(item: $notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("OK")))
        }
    }
}
