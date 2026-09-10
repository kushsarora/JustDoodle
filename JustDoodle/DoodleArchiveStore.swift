import Combine
import Foundation
import ImageIO
import UIKit

enum DoodleStorageError: LocalizedError {
    case invalidArchive
    case invalidDraft
    case imageEncoding

    var errorDescription: String? {
        switch self {
        case .invalidArchive: return "The Doodle Book could not be read. Your saved files have been kept. Please contact support."
        case .invalidDraft: return "The unfinished drawing could not be read. Its saved file has been kept."
        case .imageEncoding: return "The drawing could not be prepared for saving. Please try again."
        }
    }
}

actor DoodleRepository {
    let directory: URL
    private let files = FileManager.default
    private var closedDrafts = Set<UUID>()
    private var draftRevisions: [UUID: Int] = [:]

    init(directory: URL) { self.directory = directory }

    static var applicationDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JustDoodle", isDirectory: true)
        #if DEBUG
        if let testID = ProcessInfo.processInfo.environment["JUST_DOODLE_TEST_ID"],
           UUID(uuidString: testID) != nil {
            return directory.appendingPathComponent("UITests/\(testID)", isDirectory: true)
        }
        #endif
        return directory
    }

    private var indexURL: URL { directory.appendingPathComponent("doodles.json") }
    private var draftURL: URL { directory.appendingPathComponent("draft.json") }

    private func prepare() throws {
        try files.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func safeFilename(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\\")
    }

    func loadRecords() throws -> [DoodleRecord] {
        try prepare()
        guard files.fileExists(atPath: indexURL.path) else { return [] }
        guard let records = try? JSONDecoder().decode([DoodleRecord].self, from: Data(contentsOf: indexURL)),
              Set(records.map(\.id)).count == records.count,
              Set(records.flatMap { [$0.imageFilename, $0.drawingFilename] }).count == records.count * 2,
              records.allSatisfy({ Self.safeFilename($0.imageFilename) && $0.imageFilename.hasSuffix(".png")
                && Self.safeFilename($0.drawingFilename) && $0.drawingFilename.hasSuffix(".drawing") }) else {
            throw DoodleStorageError.invalidArchive
        }
        try recoverInterruptedDeletions(records: records)
        // Keep entries with missing images visible so the player can identify and delete them.
        return records.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist(_ records: [DoodleRecord]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(records).write(to: indexURL, options: .atomic)
    }

    private func recoverInterruptedDeletions(records: [DoodleRecord]) throws {
        for trash in try files.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            where trash.lastPathComponent.hasPrefix(".trash-") {
            guard let id = UUID(uuidString: String(trash.lastPathComponent.dropFirst(7))) else { continue }
            if let record = records.first(where: { $0.id == id }) {
                // The index is the commit point. Restore files if the deletion never committed.
                for name in [record.imageFilename, record.drawingFilename] {
                    let source = trash.appendingPathComponent(name)
                    let destination = directory.appendingPathComponent(name)
                    if files.fileExists(atPath: source.path) && !files.fileExists(atPath: destination.path) {
                        try files.moveItem(at: source, to: destination)
                    }
                }
            }
            try files.removeItem(at: trash)
        }
    }

    func save(draft: DoodleDraft, imageData: Data) throws -> DoodleRecord {
        var records = try loadRecords()
        if let existing = records.first(where: { $0.id == draft.id }) {
            closedDrafts.insert(draft.id)
            try? removeDraft(matching: draft.id)
            return existing
        }
        let record = DoodleRecord(
            id: draft.id, createdAt: draft.createdAt,
            imageFilename: "\(draft.id.uuidString).png",
            drawingFilename: "\(draft.id.uuidString).drawing",
            sessionTitle: draft.session.archiveTitle, prompt: draft.idea,
            duration: draft.session.duration, elapsed: draft.clock.finishedElapsed,
            scribbleID: draft.scribble.id, instruction: draft.session.instruction, inks: draft.session.inks
        )
        let imageURL = directory.appendingPathComponent(record.imageFilename)
        let drawingURL = directory.appendingPathComponent(record.drawingFilename)
        do {
            try imageData.write(to: imageURL, options: .atomic)
            try draft.drawingData.write(to: drawingURL, options: .atomic)
            records.insert(record, at: 0)
            try persist(records)
        } catch {
            try? files.removeItem(at: imageURL)
            try? files.removeItem(at: drawingURL)
            throw error
        }
        closedDrafts.insert(draft.id)
        try? removeDraft(matching: draft.id)
        return record
    }

    func delete(_ record: DoodleRecord) throws {
        var records = try loadRecords()
        guard let record = records.first(where: { $0.id == record.id }) else { return }
        let trash = directory.appendingPathComponent(".trash-\(record.id.uuidString)", isDirectory: true)
        try files.createDirectory(at: trash, withIntermediateDirectories: true)
        var moved: [(URL, URL)] = []
        do {
            for name in [record.imageFilename, record.drawingFilename] {
                guard Self.safeFilename(name) else { throw DoodleStorageError.invalidArchive }
                let source = directory.appendingPathComponent(name)
                if files.fileExists(atPath: source.path) {
                    let destination = trash.appendingPathComponent(name)
                    try files.moveItem(at: source, to: destination)
                    moved.append((source, destination))
                }
            }
            records.removeAll { $0.id == record.id }
            try persist(records)
        } catch {
            for (source, destination) in moved.reversed() {
                try? files.moveItem(at: destination, to: source)
            }
            // Retain any failed rollback files for recovery on the next successful index load.
            throw error
        }
        try? files.removeItem(at: trash)
    }

    func loadDraft() throws -> DoodleDraft? {
        guard files.fileExists(atPath: draftURL.path) else { return nil }
        guard let draft = try? JSONDecoder().decode(DoodleDraft.self, from: Data(contentsOf: draftURL)),
              draft.isValid else { throw DoodleStorageError.invalidDraft }
        return draft
    }

    func saveDraft(_ draft: DoodleDraft) throws {
        guard !closedDrafts.contains(draft.id),
              draft.revision >= (draftRevisions[draft.id] ?? -1) else { return }
        guard draft.isValid else { throw DoodleStorageError.invalidDraft }
        try prepare()
        try JSONEncoder().encode(draft).write(to: draftURL, options: .atomic)
        draftRevisions[draft.id] = draft.revision
    }

    func removeDraft(matching id: UUID) throws {
        if let current = try loadDraft(), current.id == id {
            try files.removeItem(at: draftURL)
        }
        closedDrafts.insert(id)
    }

    func imageData(for record: DoodleRecord) -> Data? {
        guard Self.safeFilename(record.imageFilename) else { return nil }
        return try? Data(contentsOf: directory.appendingPathComponent(record.imageFilename))
    }

    func thumbnailData(for record: DoodleRecord) -> Data? {
        guard Self.safeFilename(record.imageFilename),
              let source = CGImageSourceCreateWithURL(directory.appendingPathComponent(record.imageFilename) as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 600,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

@MainActor
final class DoodleArchiveStore: ObservableObject {
    @Published private(set) var records: [DoodleRecord] = []
    @Published private(set) var loadError: String?
    let repository: DoodleRepository

    init(directory: URL = DoodleRepository.applicationDirectory) {
        repository = DoodleRepository(directory: directory)
    }

    func load() async {
        do {
            records = try await repository.loadRecords()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func save(_ draft: DoodleDraft, image: UIImage) async throws -> DoodleRecord {
        guard let data = image.pngData() else { throw DoodleStorageError.imageEncoding }
        let record = try await repository.save(draft: draft, imageData: data)
        await load()
        return record
    }

    func delete(_ record: DoodleRecord) async throws {
        try await repository.delete(record)
        await load()
    }

    func image(for record: DoodleRecord) async -> UIImage? {
        guard let data = await repository.imageData(for: record) else { return nil }
        return UIImage(data: data)
    }

    func thumbnail(for record: DoodleRecord) async -> UIImage? {
        guard let data = await repository.thumbnailData(for: record) else { return nil }
        return UIImage(data: data)
    }
}
