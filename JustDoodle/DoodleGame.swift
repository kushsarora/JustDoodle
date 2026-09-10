import Combine
import PencilKit
import SwiftUI
import UIKit

@MainActor
final class DoodleGame: ObservableObject {
    @Published var screen: AppScreen = .home
    @Published private(set) var draft: DoodleDraft?
    @Published var drawing = PKDrawing() {
        didSet { scheduleCheckpoint() }
    }
    @Published private(set) var secondsRemaining = 180
    @Published private(set) var revealProgress: CGFloat = 0
    @Published private(set) var resultImage: UIImage?
    @Published private(set) var savedRecord: DoodleRecord?
    @Published private(set) var isSaving = false
    @Published private(set) var isDiscarding = false
    @Published private(set) var isLoading = true
    @Published private(set) var recoveryError: String?
    @Published var notice: Notice?
    @Published var isActive = true

    let archive: DoodleArchiveStore
    let canvas = CanvasBridge()
    private var revealTask: Task<Void, Never>?
    private var checkpointTask: Task<Void, Never>?
    private var previousScribbleID: String?
    private var didLoad = false
    private var reportedCheckpointFailure = false

    init(archive: DoodleArchiveStore) { self.archive = archive }

    var session: DoodleSession { draft?.session ?? .classic }
    var selectedInk: DoodleInk { draft?.ink ?? .black }
    var idea: String? { draft?.idea }
    var elapsed: Int { draft?.clock.finishedElapsed ?? 0 }
    var canBegin: Bool { !isLoading && recoveryError == nil && archive.loadError == nil && draft == nil }

    func load() async {
        guard !didLoad else { return }
        didLoad = true
        await archive.load()
        do {
            if let restored = try await archive.repository.loadDraft() {
                if archive.records.contains(where: { $0.id == restored.id }) {
                    try await archive.repository.removeDraft(matching: restored.id)
                } else {
                    draft = restored
                    previousScribbleID = restored.scribble.id
                }
            }
        } catch {
            recoveryError = error.localizedDescription
        }
        isLoading = false
    }

    func begin(_ session: DoodleSession, reduceMotion: Bool = false) {
        guard canBegin else { return }
        let scribble = ScribbleLibrary.random(excluding: previousScribbleID)
        previousScribbleID = scribble.id
        drawing = PKDrawing()
        draft = DoodleDraft(id: UUID(), createdAt: Date(), session: session, scribble: scribble,
            drawingData: drawing.dataRepresentation(), clock: SessionClock(duration: session.duration),
            ink: session.inks.first ?? .black)
        secondsRemaining = session.duration
        savedRecord = nil
        resultImage = nil
        reportedCheckpointFailure = false
        revealProgress = reduceMotion ? 1 : 0
        screen = .revealing
        checkpoint()
        let id = draft?.id
        revealTask?.cancel()
        revealTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 80_000_000)
                guard let self, self.draft?.id == id, self.screen == .revealing else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) { self.revealProgress = 1 }
                try await Task.sleep(nanoseconds: reduceMotion ? 1 : 850_000_000)
                guard self.draft?.id == id, self.screen == .revealing else { return }
                self.draft?.clock.start(at: Date())
                self.screen = .drawing
                self.checkpoint()
                self.updateIdleTimer()
            } catch { /* A discarded or replaced round must never start a timer. */ }
        }
    }

    func resume(now: Date = Date()) {
        guard let draft else { return }
        do {
            drawing = try PKDrawing(data: draft.drawingData)
            revealProgress = 1
            if draft.clock.finishedElapsed == nil {
                self.draft?.clock.start(at: now)
            }
            secondsRemaining = self.draft?.clock.remaining(at: now) ?? 0
            screen = .drawing
            if draft.clock.finishedElapsed != nil || secondsRemaining == 0 {
                finish(now: now, timedOut: draft.clock.finishedElapsed == nil)
            } else {
                updateIdleTimer()
            }
        } catch { notice = Notice(title: "Could Not Resume", message: error.localizedDescription) }
    }

    func tick(now: Date = Date()) {
        guard screen == .drawing, let clock = draft?.clock, isActive, !isDiscarding else { return }
        let remaining = clock.remaining(at: now)
        if secondsRemaining != remaining { secondsRemaining = remaining }
        if secondsRemaining == 0 { finish(now: now, timedOut: true) }
    }

    func finish(now: Date = Date(), timedOut: Bool = false) {
        guard screen == .drawing, !isSaving, !isDiscarding, draft != nil else { return }
        checkpointTask?.cancel()
        screen = .result
        if let latest = canvas.freeze() { drawing = latest }
        draft?.drawingData = drawing.dataRepresentation()
        draft?.clock.finish(at: now)
        secondsRemaining = draft?.clock.remaining(at: now) ?? 0
        updateIdleTimer()
        if timedOut && isActive && (UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true) {
            Haptics.timeUp()
        }
        guard let draft else { return }
        checkpoint()
        do {
            resultImage = try DoodleRenderer.render(draft)
            retrySave()
        } catch { notice = Notice(title: "Could Not Finish", message: error.localizedDescription) }
    }

    func retrySave() {
        guard let draft, !isSaving, !isDiscarding, savedRecord == nil else { return }
        if resultImage == nil {
            do { resultImage = try DoodleRenderer.render(draft) }
            catch {
                notice = Notice(title: "Could Not Finish", message: error.localizedDescription)
                return
            }
        }
        guard let image = resultImage else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                savedRecord = try await archive.save(draft, image: image)
            } catch {
                notice = Notice(title: "Doodle Not Saved", message: "Your drawing is still here. Retry saving or export it before leaving.\n\n" + error.localizedDescription)
            }
        }
    }

    func returnHome() {
        guard !isSaving, savedRecord != nil else { return }
        draft = nil
        drawing = PKDrawing()
        resultImage = nil
        savedRecord = nil
        screen = .home
        updateIdleTimer()
    }

    func discard() async {
        guard !isSaving, !isDiscarding else { return }
        isDiscarding = true
        defer { isDiscarding = false }
        if let latest = canvas.freeze(), screen == .drawing { drawing = latest }
        revealTask?.cancel()
        checkpointTask?.cancel()
        if let draft {
            do { try await archive.repository.removeDraft(matching: draft.id) }
            catch {
                notice = Notice(title: "Could Not Discard", message: error.localizedDescription)
                return
            }
        }
        draft = nil
        drawing = PKDrawing()
        resultImage = nil
        savedRecord = nil
        screen = .home
        updateIdleTimer()
    }

    func refreshIdea() {
        guard screen == .drawing, !isDiscarding else { return }
        tick()
        guard screen == .drawing else { return }
        draft?.idea = IdeaBank.random(excluding: draft?.idea)
        checkpoint()
    }

    func selectInk(_ ink: DoodleInk) {
        guard screen == .drawing, !isDiscarding, session.inks.contains(ink) else { return }
        draft?.ink = ink
        checkpoint()
    }

    func sceneChanged(_ phase: ScenePhase) {
        isActive = phase == .active
        if isActive { tick() }
        else if screen == .drawing || screen == .revealing {
            if let latest = canvas.freeze() { drawing = latest }
            checkpoint()
        }
        updateIdleTimer()
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = screen == .drawing && isActive
    }

    private func scheduleCheckpoint() {
        guard screen == .drawing else { return }
        checkpointTask?.cancel()
        checkpointTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                self?.checkpoint()
            } catch { }
        }
    }

    private func checkpoint() {
        guard draft != nil else { return }
        draft?.drawingData = drawing.dataRepresentation()
        draft?.revision += 1
        guard let snapshot = draft else { return }
        // Give the atomic draft write time to finish when iOS backgrounds the app.
        let taskID = UIApplication.shared.beginBackgroundTask(withName: "Save doodle draft")
        Task {
            defer {
                if taskID != .invalid { UIApplication.shared.endBackgroundTask(taskID) }
            }
            do { try await archive.repository.saveDraft(snapshot) }
            catch {
                if !reportedCheckpointFailure {
                    reportedCheckpointFailure = true
                    notice = Notice(title: "Draft Not Saved", message: error.localizedDescription)
                }
            }
        }
    }
}
