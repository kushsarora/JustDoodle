import XCTest
import PencilKit
@testable import JustDoodle

@MainActor
final class DoodleTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func draft() -> DoodleDraft {
        DoodleDraft(id: UUID(), createdAt: Date(), session: .classic,
            scribble: Scribble(id: "test", points: [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.7)]),
            drawingData: PKDrawing().dataRepresentation(), clock: SessionClock(duration: 180), ink: .black)
    }

    func testClockStartsOnceAndIncludesBackgroundTime() async {
        let now = Date(timeIntervalSince1970: 1_000)
        var clock = SessionClock(duration: 180)
        XCTAssertEqual(clock.remaining(at: now), 180)
        clock.start(at: now)
        clock.start(at: now.addingTimeInterval(30))
        XCTAssertEqual(clock.remaining(at: now.addingTimeInterval(60.1)), 120)
        XCTAssertEqual(clock.remaining(at: now.addingTimeInterval(181)), 0)
    }

    func testEarlyFinishPreservesElapsedAndIsIdempotent() async {
        let now = Date()
        var clock = SessionClock(duration: 180)
        clock.start(at: now)
        clock.finish(at: now.addingTimeInterval(41))
        XCTAssertEqual(clock.finishedElapsed, 41)
        clock.finish(at: now.addingTimeInterval(170))
        XCTAssertEqual(clock.finishedElapsed, 41)
        XCTAssertEqual(clock.remaining(at: now.addingTimeInterval(900)), 139)
        XCTAssertNil(clock.deadline)
    }

    func testClockClampsInvalidDurationAndClockRollback() async {
        let now = Date()
        var clock = SessionClock(duration: 0)
        XCTAssertEqual(clock.duration, 1)
        XCTAssertEqual(SessionClock(duration: 9_999).duration, 900)
        clock.start(at: now)
        XCTAssertEqual(clock.remaining(at: now.addingTimeInterval(-1_000)), 1)
    }

    func testLegacyArchiveWithoutMetadataDecodes() async throws {
        let id = UUID()
        let data = try JSONSerialization.data(withJSONObject: [
            "id": id.uuidString, "createdAt": 0,
            "imageFilename": "legacy.png", "drawingFilename": "legacy.drawing"
        ])
        let record = try JSONDecoder().decode(DoodleRecord.self, from: data)
        XCTAssertEqual(record.id, id)
        XCTAssertNil(record.elapsed)
        XCTAssertNil(record.inks)
        XCTAssertNil(record.sessionTitle)
    }

    func testChallengeRulesAndClassicRemainValid() async {
        XCTAssertEqual(DoodleSession.classic.duration, 180)
        XCTAssertEqual(DoodleSession.classic.inks, [.black])
        XCTAssertFalse(DoodleSession.classic.isChallenge)
        XCTAssertEqual(Set(ChallengeLibrary.packs.map(\.id)).count, ChallengeLibrary.packs.count)
        for pack in ChallengeLibrary.packs {
            XCTAssertTrue((60...900).contains(pack.session.duration))
            XCTAssertFalse(pack.session.inks.isEmpty)
            XCTAssertFalse(pack.session.instruction.isEmpty)
        }
    }

    func testIdeaAndScribbleDoNotImmediatelyRepeat() async {
        var idea: String?
        var id: String?
        for _ in 0..<200 {
            let next = IdeaBank.random(excluding: idea)
            XCTAssertNotEqual(next, idea)
            XCTAssertFalse(next.contains(" "))
            idea = next
            let scribble = ScribbleLibrary.random(excluding: id)
            XCTAssertNotEqual(scribble.id, id)
            XCTAssertTrue(scribble.points.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
            id = scribble.id
        }
    }

    func testDraftRejectsInvalidInkAndCoordinates() async {
        var invalid = draft()
        invalid.ink = .red
        XCTAssertFalse(invalid.isValid)
        invalid.ink = .black
        XCTAssertTrue(invalid.isValid)
        invalid.drawingData = Data([0, 1, 2])
        XCTAssertFalse(invalid.isValid)
    }

    func testScribbleEndpointKeepsForwardTangent() async throws {
        let points = [CGPoint(x: 10, y: 80), CGPoint(x: 90, y: 10), CGPoint(x: 70, y: 90)]
        var controls: [CGPoint] = []
        ScribblePath.path(points: points).cgPath.applyWithBlock { pointer in
            if pointer.pointee.type == .addQuadCurveToPoint { controls.append(pointer.pointee.points[0]) }
        }
        XCTAssertEqual(controls.last, points.last)
        XCTAssertEqual(controls.count, points.count)
    }

    func testScribbleGenerationIsReproducibleVariedAndBounded() async {
        struct Seeded: RandomNumberGenerator {
            var state: UInt64 = 42
            mutating func next() -> UInt64 {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return state
            }
        }
        var first = Seeded()
        var second = Seeded()
        var previous: Scribble?
        for _ in 0..<500 {
            let value = ScribbleLibrary.random(using: &first, excluding: previous?.id)
            XCTAssertEqual(value, ScribbleLibrary.random(using: &second, excluding: previous?.id))
            XCTAssertNotEqual(value.points, previous?.points)
            XCTAssertTrue(value.points.allSatisfy { (0.06...0.94).contains($0.x) && (0.06...0.94).contains($0.y) })
            let bounds = ScribblePath.path(points: DrawingPage.mappedPoints(value)).boundingRect
            XCTAssertTrue(CGRect(origin: .zero, size: DrawingPage.size).contains(bounds))
            previous = value
        }
    }

    func testInterruptedDeleteRestoresUncommittedFiles() async throws {
        let directory = try temporaryDirectory()
        let repository = DoodleRepository(directory: directory)
        let value = draft()
        let png = try XCTUnwrap(try DoodleRenderer.render(value).pngData())
        let record = try await repository.save(draft: value, imageData: png)
        let trash = directory.appendingPathComponent(".trash-\(record.id.uuidString)")
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: directory.appendingPathComponent(record.imageFilename),
            to: trash.appendingPathComponent(record.imageFilename))
        let records = try await DoodleRepository(directory: directory).loadRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent(record.imageFilename)), png)
        XCTAssertFalse(FileManager.default.fileExists(atPath: trash.path))
    }

    func testInterruptedDeleteCleansCommittedTrash() async throws {
        let directory = try temporaryDirectory()
        let trash = directory.appendingPathComponent(".trash-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try Data([1, 2]).write(to: trash.appendingPathComponent("deleted.png"))
        try JSONEncoder().encode([DoodleRecord]()).write(to: directory.appendingPathComponent("doodles.json"))
        let records = try await DoodleRepository(directory: directory).loadRecords()
        XCTAssertTrue(records.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: trash.path))
    }

    func testInvalidDraftCannotOverwriteRecoverableDraft() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        var value = draft()
        try await repository.saveDraft(value)
        value.ink = .red
        value.revision += 1
        do {
            try await repository.saveDraft(value)
            XCTFail("Invalid state must not overwrite a valid draft")
        } catch { }
        let recovered = try await repository.loadDraft()
        XCTAssertEqual(recovered?.ink, .black)
    }

    func testSaveRoundTripAndDuplicateFinishDoesNotDuplicateRecord() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        var value = draft()
        value.clock.start(at: value.createdAt)
        value.clock.finish(at: value.createdAt.addingTimeInterval(20))
        let png = try XCTUnwrap(try DoodleRenderer.render(value).pngData())
        let first = try await repository.save(draft: value, imageData: png)
        let second = try await repository.save(draft: value, imageData: png)
        let records = try await repository.loadRecords()
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.elapsed, 20)
        XCTAssertEqual(records.first?.scribbleID, "test")
        let stored = await repository.imageData(for: first)
        XCTAssertEqual(stored, png)
    }

    func testCorruptArchiveIsPreservedAndCannotBeOverwritten() async throws {
        let directory = try temporaryDirectory()
        let index = directory.appendingPathComponent("doodles.json")
        let bad = Data("not valid JSON".utf8)
        try bad.write(to: index)
        let repository = DoodleRepository(directory: directory)
        do {
            _ = try await repository.save(draft: draft(), imageData: Data())
            XCTFail("Saving must fail when the existing index is unreadable")
        } catch { }
        XCTAssertEqual(try Data(contentsOf: index), bad)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["doodles.json"])
    }

    func testMissingImageRemainsVisibleAndCanBeDeleted() async throws {
        let directory = try temporaryDirectory()
        let record = DoodleRecord(id: UUID(), createdAt: Date(), imageFilename: "missing.png",
            drawingFilename: "missing.drawing", sessionTitle: nil, prompt: nil)
        try JSONEncoder().encode([record]).write(to: directory.appendingPathComponent("doodles.json"))
        let repository = DoodleRepository(directory: directory)
        let records = try await repository.loadRecords()
        XCTAssertEqual(records.count, 1)
        let missing = await repository.imageData(for: record)
        XCTAssertNil(missing)
        try await repository.delete(record)
        let empty = try await repository.loadRecords()
        XCTAssertTrue(empty.isEmpty)
    }

    func testArchiveRejectsPathsOutsideItsDirectory() async throws {
        XCTAssertFalse(DoodleRepository.safeFilename("../outside.png"))
        XCTAssertFalse(DoodleRepository.safeFilename("/tmp/outside.png"))
        XCTAssertTrue(DoodleRepository.safeFilename("drawing.png"))
        let directory = try temporaryDirectory()
        let record = DoodleRecord(id: UUID(), createdAt: Date(), imageFilename: "../outside.png",
            drawingFilename: "ok.drawing", sessionTitle: nil, prompt: nil)
        try JSONEncoder().encode([record]).write(to: directory.appendingPathComponent("doodles.json"))
        do {
            _ = try await DoodleRepository(directory: directory).loadRecords()
            XCTFail("Unsafe filenames must not be accepted")
        } catch { }
    }

    func testDraftRoundTripIgnoresStaleAutosaves() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        var value = draft()
        value.revision = 3
        value.idea = "rocket"
        try await repository.saveDraft(value)
        value.revision = 1
        value.idea = "clock"
        try await repository.saveDraft(value)
        let recovered = try await repository.loadDraft()
        XCTAssertEqual(recovered?.idea, "rocket")
        XCTAssertEqual(recovered?.revision, 3)
    }

    func testDiscardPreventsQueuedAutosaveFromResurrectingDraft() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        let value = draft()
        try await repository.saveDraft(value)
        try await repository.removeDraft(matching: value.id)
        try await repository.saveDraft(value)
        let recovered = try await repository.loadDraft()
        XCTAssertNil(recovered)
    }

    func testCompletedDrawingRemovesDraftAndIgnoresLateCheckpoint() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        let value = draft()
        try await repository.saveDraft(value)
        let png = try XCTUnwrap(try DoodleRenderer.render(value).pngData())
        _ = try await repository.save(draft: value, imageData: png)
        try await repository.saveDraft(value)
        let recovered = try await repository.loadDraft()
        XCTAssertNil(recovered)
    }

    func testDeleteRemovesImageDrawingAndIndexEntry() async throws {
        let directory = try temporaryDirectory()
        let repository = DoodleRepository(directory: directory)
        let value = draft()
        let png = try XCTUnwrap(try DoodleRenderer.render(value).pngData())
        let record = try await repository.save(draft: value, imageData: png)
        try await repository.delete(record)
        let records = try await repository.loadRecords()
        XCTAssertTrue(records.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent(record.imageFilename).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent(record.drawingFilename).path))
    }

    func testThumbnailIsDownsampled() async throws {
        let repository = DoodleRepository(directory: try temporaryDirectory())
        let value = draft()
        let png = try XCTUnwrap(try DoodleRenderer.render(value).pngData())
        let record = try await repository.save(draft: value, imageData: png)
        let data = await repository.thumbnailData(for: record)
        let image = try XCTUnwrap(data.flatMap(UIImage.init(data:)))
        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 600)
    }

    func testExportDimensionsAndScribbleAlignment() async throws {
        let value = draft()
        let image = try DoodleRenderer.render(value)
        XCTAssertEqual(image.size, CGSize(width: 1200, height: 1760))
        XCTAssertEqual(image.scale, 1)
        let point = try XCTUnwrap(DrawingPage.mappedPoints(value.scribble).first)
        let scale = DoodleRenderer.exportWidth / DrawingPage.size.width
        let pixel = try sample(image, x: Int(point.x * scale), y: Int(DoodleRenderer.headerHeight + point.y * scale))
        XCTAssertLessThan(pixel[0], 60)
        XCTAssertLessThan(pixel[1], 60)
        XCTAssertLessThan(pixel[2], 60)
        XCTAssertEqual(pixel[3], 255)
    }

    func testExportPreservesPlayerStrokePosition() async throws {
        var value = draft()
        let points = [CGPoint(x: 170, y: 360), CGPoint(x: 210, y: 360)].map {
            PKStrokePoint(location: $0, timeOffset: 0, size: CGSize(width: 8, height: 8),
                opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
        }
        let stroke = PKStroke(ink: PKInk(.pen, color: .red),
            path: PKStrokePath(controlPoints: points, creationDate: Date()))
        value.drawingData = PKDrawing(strokes: [stroke]).dataRepresentation()
        let image = try DoodleRenderer.render(value)
        let pixel = try sample(image, x: Int(190 * 1200.0 / 360), y: 160 + 1200)
        XCTAssertGreaterThan(pixel[0], 180)
        XCTAssertLessThan(pixel[1], 100)
    }

    func testExpiredDraftFinishesOnceAfterRelaunch() async throws {
        let archive = DoodleArchiveStore(directory: try temporaryDirectory())
        var value = draft()
        let now = Date()
        value.clock.start(at: now.addingTimeInterval(-300))
        try await archive.repository.saveDraft(value)
        let game = DoodleGame(archive: archive)
        await game.load()
        XCTAssertEqual(game.draft?.id, value.id)
        game.resume(now: now)
        XCTAssertEqual(game.screen, .result)
        XCTAssertEqual(game.elapsed, 180)
        for _ in 0..<100 where game.isSaving {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertNotNil(game.savedRecord)
        game.tick(now: now.addingTimeInterval(900))
        XCTAssertEqual(archive.records.count, 1)
    }

    func testInvalidInkCannotChangeClassicSession() async throws {
        let archive = DoodleArchiveStore(directory: try temporaryDirectory())
        try await archive.repository.saveDraft(draft())
        let game = DoodleGame(archive: archive)
        await game.load()
        game.resume()
        game.selectInk(.red)
        XCTAssertEqual(game.selectedInk, .black)
        await game.discard()
    }

    private func sample(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
        let cropped = try XCTUnwrap(image.cgImage?.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)))
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(data: &pixel, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return pixel
    }
}
