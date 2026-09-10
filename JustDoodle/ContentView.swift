import Combine
import PencilKit
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var archive: DoodleArchiveStore
    @StateObject private var game: DoodleGame
    @State private var showSplash = true
    @State private var showExitOptions = false
    @State private var confirmDiscard = false
    @State private var selectedRecord: DoodleRecord?
    @State private var shareImage: ShareImage?
    @State private var customDuration = ChallengeDuration.threeMinutes
    @State private var customPalette = InkPalette.black
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init() {
        let archive = DoodleArchiveStore()
        _archive = StateObject(wrappedValue: archive)
        _game = StateObject(wrappedValue: DoodleGame(archive: archive))
    }

    var body: some View {
        ZStack {
            NotebookBackground()
            screenContent
                .id(game.screen == .revealing ? AppScreen.drawing : game.screen)
                .transition(.opacity)
                .disabled(showSplash || game.isDiscarding)
                .accessibilityHidden(showSplash)
            if showSplash {
                DoodlersClubSplash()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.light)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: game.screen == .revealing ? AppScreen.drawing : game.screen)
        .tint(Ink.blue)
        .task {
            await game.load()
            do { try await Task.sleep(nanoseconds: reduceMotion ? 1 : 800_000_000) }
            catch { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { showSplash = false }
        }
        .onReceive(timer) { game.tick(now: $0) }
        .onChange(of: scenePhase) { game.sceneChanged($0) }
        .sheet(item: $shareImage) { ShareSheet(items: [$0.image, $0.caption]) }
        .fullScreenCover(item: $selectedRecord) { record in
            ArchivePreviewView(record: record, archive: archive)
        }
        .alert(item: $game.notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("OK")))
        }
        .alert("Leave this drawing?", isPresented: $showExitOptions) {
            Button("Finish and save") { game.finish() }
            Button("Discard drawing", role: .destructive) { Task { await game.discard() } }
            Button("Keep drawing", role: .cancel) { }
        }
        .confirmationDialog("Discard unfinished drawing?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard drawing", role: .destructive) { Task { await game.discard() } }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: game.screen) { next in
            if next == .result { showExitOptions = false }
        }
    }

    @ViewBuilder private var screenContent: some View {
        switch game.screen {
        case .home: homeView
        case .revealing, .drawing: drawingView
        case .result: resultView
        case .challenges: challengesView
        case .archive: archiveView
        case .settings: SettingsView { game.screen = .home }
        }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(systemName: "gearshape", label: "Settings") { game.screen = .settings }
                    .accessibilityIdentifier("settings")
                Spacer()
                Button { game.screen = .archive } label: {
                    Label("Doodle Book", systemImage: "square.grid.2x2")
                        .font(.doodleTitle(18))
                        .foregroundStyle(Ink.black)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("doodleBook")
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        Image("DoodlersClubMark")
                            .resizable().scaledToFit()
                            .frame(width: 88, height: 88)
                            .accessibilityHidden(true)
                        Text("Just Doodle.")
                            .font(.doodleTitle(44))
                            .foregroundStyle(Ink.black)
                            .lineLimit(1).minimumScaleFactor(0.65)
                        HandUnderline().stroke(Ink.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 190, height: 8)
                    }
                    if let error = game.recoveryError ?? archive.loadError {
                        Text(error).font(.body).foregroundStyle(Ink.red)
                        Link("Contact support", destination: ReleaseInfo.supportMailURL)
                    } else if game.draft != nil {
                        Button { game.resume() } label: {
                            Label("Resume drawing", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(InkCommandStyle())
                        .accessibilityIdentifier("resumeDrawing")
                        Button("Discard unfinished drawing", role: .destructive) { confirmDiscard = true }
                            .frame(minHeight: 44)
                    } else {
                        StartDot { game.begin(.classic, reduceMotion: reduceMotion) }
                            .disabled(!game.canBegin)
                        Button { game.screen = .challenges } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles").foregroundStyle(Ink.blue)
                                Text("Challenges").font(.doodleTitle(22))
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(Ink.black)
                            .padding(.vertical, 18)
                            .contentShape(Rectangle())
                            .overlay(alignment: .top) { Rectangle().fill(NotebookColors.rule).frame(height: 1) }
                            .overlay(alignment: .bottom) { Rectangle().fill(NotebookColors.rule).frame(height: 1) }
                        }
                        .buttonStyle(InkPressStyle())
                        .disabled(!game.canBegin)
                        .accessibilityIdentifier("challenges")
                    }
                    Text("The Doodler's Club")
                        .font(.doodleBody(18)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var drawingView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                IconButton(systemName: "xmark", label: "Leave drawing") { showExitOptions = true }
                    .disabled(game.screen != .drawing)
                    .accessibilityIdentifier("leaveDrawing")
                Spacer(minLength: 0)
                Button { game.finish() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Done").font(.doodleTitle(18))
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }
                        .padding(.horizontal, 8)
                        .frame(width: 88, height: 44)
                        .background(game.screen == .drawing ? Ink.black : Ink.black.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(InkPressStyle())
                .disabled(game.screen != .drawing)
                .accessibilityLabel("Done, finish and save drawing")
                .accessibilityIdentifier("finishDrawing")
            }
            .overlay {
                Text(DoodleTime.string(game.secondsRemaining))
                    .font(.doodleBody(26)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(width: 96)
                    .foregroundStyle(game.secondsRemaining <= 20 ? Ink.red : Ink.black)
                    .accessibilityLabel("\(game.secondsRemaining) seconds remaining")
                    .accessibilityIdentifier("roundTimer")
                    .allowsHitTesting(false)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.horizontal, 16).padding(.vertical, 6)

            if game.session.isChallenge {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.session.title).font(.doodleTitle(19))
                    Text(game.session.instruction).font(.doodleBody(16))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Ink.black)
                .frame(maxWidth: 640, alignment: .leading)
                .padding(.horizontal, 18).padding(.bottom, 6)
                .accessibilityElement(children: .combine)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }

            if let draft = game.draft {
                ScribbleSurface(scribble: draft.scribble, revealProgress: game.revealProgress,
                    drawing: $game.drawing,
                    isDrawingEnabled: game.screen == .drawing && game.isActive && !game.isDiscarding,
                    ink: game.selectedInk, bridge: game.canvas)
                    .padding(.horizontal, 16).padding(.vertical, 10)
            }

            HStack(alignment: .center, spacing: 8) {
                if game.session.inks.count > 1 {
                    InkPalettePicker(inks: game.session.inks,
                        selection: Binding(get: { game.selectedInk }, set: { game.selectInk($0) }))
                } else {
                    HStack(spacing: 10) {
                        Circle().fill(Ink.black).frame(width: 26, height: 26)
                        Text("Black ink").font(.doodleBody(16)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(Ink.black)
                    .accessibilityElement(children: .combine)
                }
                Spacer(minLength: 0)
                IdeaBox(idea: game.idea, action: game.refreshIdea)
            }
            .disabled(game.screen != .drawing)
            .padding(.horizontal, 20).padding(.vertical, 6)
            .frame(maxWidth: 680)
        }
    }

    private var resultView: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.isSaving ? "Saving..." : (game.savedRecord == nil ? "Finished." : "Saved."))
                        .font(.doodleTitle(28))
                        .accessibilityIdentifier("resultStatus")
                    Text(game.session.title).font(.doodleBody(17)).foregroundStyle(.secondary)
                }
                Spacer()
                if game.isSaving { ProgressView().accessibilityLabel("Saving drawing") }
                Label(DoodleTime.string(game.elapsed), systemImage: "timer")
                    .font(.doodleBody(20)).monospacedDigit()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Drawing time: \(game.elapsed) seconds")
            }
            .foregroundStyle(Ink.black)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.horizontal, 20).padding(.top, 8)

            if let image = game.resultImage {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 14)
                    .accessibilityLabel("Finished drawing")
                    .accessibilityIdentifier("finishedImage")
                HStack(spacing: 20) {
                    PhotoExportButton(image: image)
                    IconButton(systemName: "square.and.arrow.up", label: "Share drawing") {
                        shareImage = ShareImage(image: image, caption: game.savedRecord?.shareCaption ?? "Made with Just Doodle. #JustDoodle")
                    }
                    .accessibilityIdentifier("shareDrawing")
                    IconButton(systemName: "square.grid.2x2", label: "Doodle Book") {
                        game.returnHome()
                        game.screen = .archive
                    }
                    .disabled(game.savedRecord == nil || game.isSaving)
                }
            } else {
                Spacer()
                Text("Your drawing could not be prepared.").foregroundStyle(Ink.red)
                Spacer()
            }

            if game.savedRecord == nil && !game.isSaving {
                Button { game.retrySave() } label: { Label("Retry saving", systemImage: "arrow.clockwise") }
                    .buttonStyle(InkCommandStyle())
                Button("Discard drawing", role: .destructive) { confirmDiscard = true }.frame(minHeight: 44)
            } else {
                Button { game.returnHome() } label: { Label("Back to home", systemImage: "house") }
                    .buttonStyle(InkCommandStyle())
                    .disabled(game.isSaving)
                    .accessibilityIdentifier("backHome")
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private var challengesView: some View {
        VStack(spacing: 0) {
            pageHeader("Challenges")
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ChallengeLibrary.packs) { pack in
                        ChallengePackButton(pack: pack) { game.begin(pack.session, reduceMotion: reduceMotion) }
                    }
                    CustomChallengeBuilder(duration: $customDuration, palette: $customPalette) {
                        game.begin(DoodleSession(title: "My Challenge",
                            instruction: "Make anything from the scribble.", symbol: "slider.horizontal.3",
                            duration: customDuration.seconds, inks: customPalette.inks, isChallenge: true),
                            reduceMotion: reduceMotion)
                    }
                    .padding(.top, 28)
                }
                .frame(maxWidth: 620).padding(16).frame(maxWidth: .infinity)
            }
        }
    }

    private var archiveView: some View {
        VStack(spacing: 0) {
            pageHeader("Doodle Book")
            if let error = archive.loadError {
                Text(error).foregroundStyle(Ink.red).padding()
                Button("Retry") { Task { await archive.load() } }.frame(minHeight: 44)
            } else if archive.records.isEmpty {
                Spacer()
                Image("DoodlersClubMark").resizable().scaledToFit().frame(width: 100, height: 100)
                Text("Nothing here yet.").font(.doodleBody(24)).padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145, maximum: 280), spacing: 16)], spacing: 20) {
                        ForEach(archive.records) { record in
                            Button { selectedRecord = record } label: {
                                DoodleThumbnail(record: record, archive: archive)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(record.sessionTitle ?? "Classic") drawing, \(record.createdAt.doodleDate)")
                            .accessibilityIdentifier("archiveDrawing")
                        }
                    }
                    .padding(16)
                }
                .refreshable { await archive.load() }
            }
        }
        .task { await archive.load() }
    }

    private func pageHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            IconButton(systemName: "chevron.left", label: "Back to home") { game.screen = .home }
            Text(title).font(.doodleTitle(30)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Ink.black).padding(.horizontal, 16).padding(.vertical, 6)
    }
}

struct DoodleThumbnail: View {
    let record: DoodleRecord
    let archive: DoodleArchiveStore
    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Color.white.opacity(0.6)
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                } else if loaded {
                    Image(systemName: "photo.badge.exclamationmark")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Image unavailable")
                } else {
                    ProgressView()
                }
            }
            .aspectRatio(1200.0 / 1760.0, contentMode: .fit)
            Text(record.sessionTitle ?? "Classic")
                .font(.doodleTitle(17)).foregroundStyle(Ink.black).lineLimit(1)
            Text(record.createdAt.doodleDate)
                .font(.doodleBody(14)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task(id: record.id) {
            image = await archive.thumbnail(for: record)
            loaded = true
        }
    }
}
