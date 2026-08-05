import Combine
import PencilKit
import Photos
import SwiftUI
import UIKit

struct ContentView: View {
    private static let classicRoundLength = 180

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var archive = DoodleArchiveStore()

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    @State private var screen: AppScreen = .home
    @State private var archiveReturnScreen: AppScreen = .home
    @State private var drawing = PKDrawing()
    @State private var scribble = ScribbleLibrary.random()
    @State private var previousScribbleID: String?
    @State private var canvasSize: CGSize = .zero
    @State private var secondsRemaining = ContentView.classicRoundLength
    @State private var deadline: Date?
    @State private var revealProgress: CGFloat = 0
    @State private var resultImage: UIImage?
    @State private var savedRecord: DoodleRecord?
    @State private var selectedRecord: DoodleRecord?
    @State private var shareImage: ShareImage?
    @State private var notice: Notice?
    @State private var showExitOptions = false
    @State private var showSplash = true
    @State private var currentIdea: String?
    @State private var activeSession = DoodleSession.classic
    @State private var selectedInk = DoodleInk.black
    @State private var customDuration = ChallengeDuration.threeMinutes
    @State private var customPalette = InkPalette.black

    var body: some View {
        ZStack {
            NotebookBackground()

            switch screen {
            case .home:
                homeView
                    .transition(.opacity)
            case .revealing:
                revealView
                    .transition(.opacity)
            case .drawing:
                drawingView
                    .transition(.opacity)
            case .result:
                resultView
                    .transition(.opacity)
            case .archive:
                archiveView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .challenges:
                challengesView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showSplash {
                DoodlersClubSplash()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.light)
        .task {
            guard showSplash else { return }
            try? await Task.sleep(nanoseconds: 1_850_000_000)
            withAnimation(.easeInOut(duration: 0.65)) {
                showSplash = false
            }
        }
        .onReceive(timer) { now in
            updateTimer(now: now)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                updateTimer(now: Date())
            }
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image, item.caption])
        }
        .fullScreenCover(item: $selectedRecord) { record in
            ArchivePreviewView(
                record: record,
                image: archive.image(for: record),
                onDelete: {
                    archive.delete(record)
                    if savedRecord?.id == record.id {
                        savedRecord = nil
                    }
                    selectedRecord = nil
                }
            )
        }
        .alert(item: $notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Leave this scribble?",
            isPresented: $showExitOptions,
            titleVisibility: .visible
        ) {
            Button("Finish and save") { finishRound() }
            Button("Discard scribble", role: .destructive) { discardRound() }
            Button("Keep drawing", role: .cancel) {}
        } message: {
            Text("Finish this one now, or let it go?")
        }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !archive.records.isEmpty {
                    IconButton(systemName: "square.grid.2x2", label: "Open Doodle Book") {
                        openArchive(returningTo: .home)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer()

            VStack(spacing: 42) {
                VStack(spacing: 5) {
                    Text("Just Doodle.")
                        .font(.doodleTitle(52))
                        .foregroundStyle(Ink.black)

                    HandUnderline()
                        .stroke(Ink.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 220, height: 10)
                }

                StartDot(action: beginClassicRound)

                Text("Wanna scribble?")
                    .font(.doodleBody(25))
                    .foregroundStyle(Ink.black.opacity(0.86))

                Button {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        screen = .challenges
                    }
                } label: {
                    Label("Try a challenge", systemImage: "sparkles")
                        .font(.doodleTitle(19))
                        .foregroundStyle(Ink.black)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Ink.black.opacity(0.72), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }

    private var revealView: some View {
        VStack(spacing: 0) {
            roundHeader(showClose: false)

            if activeSession.isChallenge {
                sessionBanner
            }

            ScribbleSurface(
                scribble: scribble,
                revealProgress: revealProgress,
                drawing: $drawing,
                isDrawingEnabled: false,
                ink: selectedInk,
                canvasSize: $canvasSize
            )
        }
        .allowsHitTesting(false)
    }

    private var drawingView: some View {
        VStack(spacing: 0) {
            roundHeader(showClose: true)

            if activeSession.isChallenge {
                sessionBanner
            }

            ZStack(alignment: .bottomTrailing) {
                ScribbleSurface(
                    scribble: scribble,
                    revealProgress: 1,
                    drawing: $drawing,
                    isDrawingEnabled: true,
                    ink: selectedInk,
                    canvasSize: $canvasSize
                )

                IdeaBox(idea: currentIdea, action: refreshIdea)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)

                if activeSession.inks.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            InkPalettePicker(
                                inks: activeSession.inks,
                                selection: $selectedInk
                            )
                            Spacer()
                        }
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 18)
                }
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(savedRecord == nil ? "Finished." : "Saved.")
                        .font(.doodleTitle(27))
                        .foregroundStyle(Ink.black)

                    if activeSession.isChallenge {
                        Text(activeSession.title)
                            .font(.doodleBody(14))
                            .foregroundStyle(Ink.blue)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text("0:00")
                    .font(.doodleBody(23))
                    .monospacedDigit()
                    .foregroundStyle(Ink.black)
            }
            .padding(.horizontal, 20)
            .frame(height: 62)

            if let resultImage {
                Image(uiImage: resultImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 14)
                    .accessibilityLabel("Your finished doodle")
            } else {
                ScribbleSurface(
                    scribble: scribble,
                    revealProgress: 1,
                    drawing: $drawing,
                    isDrawingEnabled: false,
                    ink: selectedInk,
                    canvasSize: $canvasSize
                )
            }

            HStack(spacing: 14) {
                IconButton(systemName: "square.and.arrow.down", label: "Save to Photos", filled: false) {
                    saveResultToPhotos()
                }

                IconButton(systemName: "square.and.arrow.up", label: "Share doodle", filled: false) {
                    shareResult()
                }

                IconButton(systemName: "square.grid.2x2", label: "Open Doodle Book", filled: false) {
                    openArchive(returningTo: .result)
                }

                Spacer()

                Button(action: returnHome) {
                    ZStack {
                        Circle()
                            .fill(Ink.black)
                            .frame(width: 44, height: 44)
                        Circle()
                            .stroke(Ink.black.opacity(0.16), lineWidth: 2)
                            .frame(width: 54, height: 54)
                    }
                    .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start another scribble")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    private var archiveView: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(systemName: "chevron.left", label: "Back") {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        screen = archiveReturnScreen
                    }
                }

                Text("Doodle Book")
                    .font(.doodleTitle(32))
                    .foregroundStyle(Ink.black)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 62)

            if archive.records.isEmpty {
                VStack(spacing: 22) {
                    Spacer()
                    Circle()
                        .fill(Ink.black)
                        .frame(width: 30, height: 30)
                    Text("Nothing here yet.")
                        .font(.doodleBody(24))
                        .foregroundStyle(Ink.black.opacity(0.78))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 16
                    ) {
                        ForEach(archive.records) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    if let image = archive.image(for: record) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(0.78, contentMode: .fit)
                                            .clipped()
                                            .background(Color.white.opacity(0.5))
                                    }

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(record.sessionTitle ?? "Classic")
                                            .font(.doodleTitle(16))
                                            .foregroundStyle(Ink.black)
                                            .lineLimit(1)

                                        Text(record.createdAt.doodleDate)
                                            .font(.doodleBody(14))
                                            .foregroundStyle(Ink.black.opacity(0.66))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Doodle from \(record.createdAt.doodleDate)")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var challengesView: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(systemName: "chevron.left", label: "Back to home") {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        screen = .home
                    }
                }

                Text("Doodle Packs")
                    .font(.doodleTitle(31))
                    .foregroundStyle(Ink.black)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 62)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ChallengeLibrary.packs) { pack in
                        ChallengePackButton(pack: pack) {
                            beginRound(pack.session)
                        }
                    }

                    CustomChallengeBuilder(
                        duration: $customDuration,
                        palette: $customPalette,
                        start: beginCustomChallenge
                    )
                    .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
    }

    private var sessionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: activeSession.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Ink.blue)

            VStack(alignment: .leading, spacing: 1) {
                Text(activeSession.title)
                    .font(.doodleTitle(17))
                    .foregroundStyle(Ink.black)
                Text(activeSession.instruction)
                    .font(.doodleBody(15))
                    .foregroundStyle(Ink.black.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(Color.white.opacity(0.52))
        .accessibilityElement(children: .combine)
    }

    private func roundHeader(showClose: Bool) -> some View {
        HStack {
            if showClose {
                IconButton(systemName: "xmark", label: "End or discard session") {
                    showExitOptions = true
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            Text(formattedTime)
                .font(.doodleBody(24))
                .monospacedDigit()
                .foregroundStyle(secondsRemaining <= 20 ? Ink.red : Ink.black)
                .accessibilityLabel("\(secondsRemaining) seconds remaining")
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }

    private var formattedTime: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    private func beginClassicRound() {
        beginRound(.classic)
    }

    private func beginCustomChallenge() {
        beginRound(
            DoodleSession(
                title: "My Challenge",
                instruction: "Make anything from the scribble.",
                symbol: "slider.horizontal.3",
                duration: customDuration.seconds,
                inks: customPalette.inks,
                isChallenge: true
            )
        )
    }

    private func beginRound(_ session: DoodleSession) {
        let next = ScribbleLibrary.random(excluding: previousScribbleID)
        previousScribbleID = next.id
        scribble = next
        activeSession = session
        selectedInk = session.inks.first ?? .black
        drawing = PKDrawing()
        secondsRemaining = session.duration
        deadline = nil
        resultImage = nil
        savedRecord = nil
        currentIdea = nil
        revealProgress = 0

        withAnimation(.easeOut(duration: 0.22)) {
            screen = .revealing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 1.05)) {
                revealProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.18) {
            guard screen == .revealing else { return }
            deadline = Date().addingTimeInterval(TimeInterval(session.duration))
            withAnimation(.easeOut(duration: 0.18)) {
                screen = .drawing
            }
        }
    }

    private func updateTimer(now: Date) {
        guard screen == .drawing, let deadline else { return }
        let remaining = max(0, Int(ceil(deadline.timeIntervalSince(now))))
        if remaining != secondsRemaining {
            secondsRemaining = remaining
        }
        if remaining == 0 {
            finishRound(timedOut: true)
        }
    }

    private func finishRound(timedOut: Bool = false) {
        guard screen == .drawing || screen == .revealing else { return }
        deadline = nil
        secondsRemaining = 0

        if timedOut {
            Haptics.timeUp()
        }

        let image = renderedDrawing()
        resultImage = image
        if let image {
            if let record = archive.save(
                image: image,
                drawing: drawing,
                sessionTitle: activeSession.archiveTitle,
                prompt: currentIdea
            ) {
                savedRecord = record
            } else {
                notice = Notice(
                    title: "Couldn’t Save",
                    message: "This doodle is still on screen, but it was not added to the Doodle Book."
                )
            }
        }

        withAnimation(.easeInOut(duration: 0.24)) {
            screen = .result
        }
    }

    private func discardRound() {
        deadline = nil
        drawing = PKDrawing()
        resultImage = nil
        savedRecord = nil
        returnHome()
    }

    private func refreshIdea() {
        currentIdea = IdeaBank.random(excluding: currentIdea)
    }

    private func returnHome() {
        deadline = nil
        withAnimation(.easeInOut(duration: 0.24)) {
            screen = .home
        }
    }

    private func openArchive(returningTo returnScreen: AppScreen) {
        archiveReturnScreen = returnScreen
        withAnimation(.easeInOut(duration: 0.24)) {
            screen = .archive
        }
    }

    private func shareResult() {
        guard let image = resultImage ?? renderedDrawing() else { return }
        shareImage = ShareImage(image: image, caption: shareCaption)
    }

    private func saveResultToPhotos() {
        guard let image = resultImage ?? renderedDrawing() else { return }
        PhotoSaver.save(image) { outcome in
            notice = outcome
        }
    }

    private var shareCaption: String {
        let session = activeSession.isChallenge ? "the \(activeSession.title) challenge" : "one random scribble"
        let idea = currentIdea.map { " My idea was \($0)." } ?? ""
        return "I turned \(session) into this with Just Doodle.\(idea) #JustDoodle"
    }

    private func renderedDrawing() -> UIImage? {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }

        let outputWidth: CGFloat = 1200
        let headerHeight: CGFloat = 150
        let outputCanvasHeight = outputWidth * (canvasSize.height / canvasSize.width)
        let outputSize = CGSize(width: outputWidth, height: headerHeight + outputCanvasHeight)
        let renderer = UIGraphicsImageRenderer(size: outputSize)

        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            NotebookRenderer.drawBackground(in: context, size: outputSize, scale: outputWidth / canvasSize.width)

            let titleFont = UIFont(name: "Noteworthy-Bold", size: 52)
                ?? UIFont.systemFont(ofSize: 52, weight: .bold)
            "Just Doodle.".draw(
                at: CGPoint(x: 62, y: 36),
                withAttributes: [
                    .font: titleFont,
                    .foregroundColor: UIColor(white: 0.08, alpha: 1)
                ]
            )

            if activeSession.isChallenge || currentIdea != nil {
                let detailFont = UIFont(name: "Noteworthy", size: 29)
                    ?? UIFont.systemFont(ofSize: 29)
                let detail = currentIdea.map { "\(activeSession.title) / \($0)" }
                    ?? activeSession.title
                detail.draw(
                    at: CGPoint(x: 390, y: 48),
                    withAttributes: [
                        .font: detailFont,
                        .foregroundColor: UIColor(white: 0.22, alpha: 1)
                    ]
                )
            }

            let canvasRect = CGRect(x: 0, y: headerHeight, width: outputWidth, height: outputCanvasHeight)

            context.saveGState()
            context.translateBy(x: 0, y: headerHeight)
            ScribbleRenderer.draw(scribble, in: context, size: canvasRect.size, inset: 78)
            context.restoreGState()

            let sourceRect = CGRect(origin: .zero, size: canvasSize)
            drawing.image(from: sourceRect, scale: 2).draw(in: canvasRect)
        }
    }
}

private struct DoodlersClubSplash: View {
    @State private var inkVisible = false

    var body: some View {
        ZStack {
            NotebookBackground()

            VStack(spacing: 18) {
                Image("DoodlersClubMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 154)
                    .accessibilityHidden(true)

                Text("The Doodler's Club")
                    .font(.doodleTitle(39))
                    .foregroundStyle(Ink.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .opacity(inkVisible ? 1 : 0)
            .scaleEffect(inkVisible ? 1 : 0.96)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Doodler's Club")
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                inkVisible = true
            }
        }
    }
}

private struct ScribbleSurface: View {
    let scribble: Scribble
    let revealProgress: CGFloat
    @Binding var drawing: PKDrawing
    let isDrawingEnabled: Bool
    let ink: DoodleInk
    @Binding var canvasSize: CGSize

    var body: some View {
        ZStack {
            ScribbleInk(scribble: scribble, progress: revealProgress)
                .padding(28)
                .allowsHitTesting(false)

            InkOnlyCanvas(
                drawing: $drawing,
                isDrawingEnabled: isDrawingEnabled,
                ink: ink
            )
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CanvasSizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(CanvasSizePreferenceKey.self) { canvasSize = $0 }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel("Scribble drawing canvas")
    }
}

private struct ChallengePackButton: View {
    let pack: ChallengePack
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: pack.session.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Ink.blue)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.session.title)
                        .font(.doodleTitle(21))
                        .foregroundStyle(Ink.black)

                    Text(pack.session.instruction)
                        .font(.doodleBody(16))
                        .foregroundStyle(Ink.black.opacity(0.72))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 9) {
                        Label(pack.session.shortDuration, systemImage: "timer")
                            .font(.doodleBody(14))
                            .foregroundStyle(Ink.black.opacity(0.68))

                        InkSwatches(inks: pack.session.inks, size: 12)
                    }
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Ink.black.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .background(Color.white.opacity(0.56))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Ink.black.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(pack.session.title). \(pack.session.instruction). \(pack.session.shortDuration)."
        )
    }
}

private struct CustomChallengeBuilder: View {
    @Binding var duration: ChallengeDuration
    @Binding var palette: InkPalette
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make Your Own")
                .font(.doodleTitle(26))
                .foregroundStyle(Ink.black)

            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.doodleTitle(17))
                    .foregroundStyle(Ink.black)

                Picker("Challenge time", selection: $duration) {
                    ForEach(ChallengeDuration.allCases) { choice in
                        Text(choice.label).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ink")
                    .font(.doodleTitle(17))
                    .foregroundStyle(Ink.black)

                Picker("Available inks", selection: $palette) {
                    ForEach(InkPalette.allCases) { choice in
                        Text(choice.label).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button(action: start) {
                Label("Start challenge", systemImage: "play.fill")
                    .font(.doodleTitle(19))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Ink.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

private struct InkPalettePicker: View {
    let inks: [DoodleInk]
    @Binding var selection: DoodleInk

    var body: some View {
        HStack(spacing: 10) {
            ForEach(inks) { ink in
                Button {
                    selection = ink
                } label: {
                    Circle()
                        .fill(ink.color)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selection == ink ? 3 : 0)
                                .padding(3)
                        )
                        .overlay(Circle().stroke(Ink.black.opacity(0.65), lineWidth: 1))
                        .frame(width: 36, height: 36)
                        .scaleEffect(selection == ink ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(ink.name) ink")
                .accessibilityAddTraits(selection == ink ? .isSelected : [])
            }
        }
        .padding(8)
        .background(NotebookColors.paper.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Ink.black.opacity(0.55), lineWidth: 1.5)
        )
    }
}

private struct InkSwatches: View {
    let inks: [DoodleInk]
    let size: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(inks) { ink in
                Circle()
                    .fill(ink.color)
                    .overlay(Circle().stroke(Ink.black.opacity(0.45), lineWidth: 0.75))
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct IdeaBox: View {
    let idea: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HandDrawnBox()
                    .fill(NotebookColors.paper.opacity(0.96))

                HandDrawnBox()
                    .stroke(
                        Ink.black,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                VStack(spacing: 4) {
                    Text("Idea Box")
                        .font(.doodleTitle(18))
                        .foregroundStyle(Ink.black)

                    HandUnderline()
                        .stroke(Ink.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 58, height: 5)

                    Text(idea ?? "tap for idea")
                        .font(.doodleBody(17))
                        .foregroundStyle(idea == nil ? Ink.black.opacity(0.65) : Ink.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(maxWidth: 86)
                }
                .padding(9)
            }
            .frame(width: 112, height: 112)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(idea.map { "Idea Box. Current idea: \($0). Tap for another idea." }
            ?? "Idea Box. Tap for a drawing idea.")
    }
}

private struct HandDrawnBox: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 7, y: rect.minY + 4),
            control: CGPoint(x: rect.midX, y: rect.minY + 1)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 7),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 7, y: rect.maxY - 4),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 5, y: rect.minY + 8),
            control: CGPoint(x: rect.minX + 1, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

private struct StartDot: View {
    let action: () -> Void
    @State private var breathing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Ink.black.opacity(0.14), lineWidth: 2)
                    .frame(width: 86, height: 86)
                    .scaleEffect(breathing ? 1.05 : 0.92)
                    .opacity(breathing ? 0.35 : 0.8)

                Circle()
                    .fill(Ink.black)
                    .frame(width: 58, height: 58)
            }
            .frame(width: 94, height: 94)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Begin a three minute scribble")
        .onAppear {
            breathing = false
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}

private struct IconButton: View {
    let systemName: String
    let label: String
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(filled ? Color.white : Ink.black)
                .frame(width: 44, height: 44)
                .background(filled ? Ink.black : Color.white.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct InkOnlyCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let isDrawingEnabled: Bool
    let ink: DoodleInk

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> LockedInkCanvasView {
        let canvas = LockedInkCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.isScrollEnabled = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.tool = PKInkingTool(.pen, color: ink.uiColor, width: 5.5)
        return canvas
    }

    func updateUIView(_ canvas: LockedInkCanvasView, context: Context) {
        if canvas.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvas.drawing = drawing
        }
        canvas.tool = PKInkingTool(.pen, color: ink.uiColor, width: 5.5)
        canvas.isUserInteractionEnabled = isDrawingEnabled
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding private var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}

private final class LockedInkCanvasView: PKCanvasView {
    override var undoManager: UndoManager? { nil }
}

private struct ScribbleInk: View {
    let scribble: Scribble
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let first = mapped(scribble.points.first ?? .zero, in: proxy.size)
            let last = mapped(scribble.points.last ?? .zero, in: proxy.size)

            ZStack(alignment: .topLeading) {
                ScribbleShape(points: scribble.points)
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(
                        Ink.scribble,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )

                Circle()
                    .fill(Ink.black)
                    .frame(width: 15, height: 15)
                    .position(first)
                    .opacity(progress > 0 ? 1 : 0)

                Circle()
                    .fill(NotebookColors.paper)
                    .overlay(Circle().stroke(Ink.black, lineWidth: 4))
                    .frame(width: 17, height: 17)
                    .position(last)
                    .opacity(progress > 0.96 ? 1 : 0)
            }
        }
    }

    private func mapped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

private struct ScribbleShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        let mappedPoints = points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        return ScribblePath.path(points: mappedPoints)
    }
}

private enum ScribblePath {
    static func path(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: midpoint, control: previous)
        }
        if let previous = points.dropLast().last, let last = points.last {
            path.addQuadCurve(to: last, control: previous)
        }
        return path
    }
}

private struct Scribble: Equatable {
    let id: String
    let points: [CGPoint]
}

private enum ScribbleLibrary {
    private static let bases: [[CGPoint]] = [
        points([0.12, 0.64, 0.22, 0.22, 0.43, 0.18, 0.36, 0.52, 0.57, 0.78, 0.70, 0.48, 0.55, 0.30, 0.83, 0.36, 0.88, 0.68]),
        points([0.10, 0.28, 0.32, 0.18, 0.26, 0.58, 0.48, 0.76, 0.62, 0.40, 0.42, 0.22, 0.70, 0.17, 0.88, 0.50]),
        points([0.14, 0.74, 0.20, 0.32, 0.44, 0.26, 0.54, 0.66, 0.34, 0.78, 0.30, 0.48, 0.64, 0.34, 0.84, 0.62]),
        points([0.10, 0.48, 0.24, 0.16, 0.52, 0.20, 0.40, 0.55, 0.22, 0.76, 0.58, 0.79, 0.76, 0.52, 0.60, 0.32, 0.88, 0.25]),
        points([0.13, 0.23, 0.40, 0.18, 0.46, 0.46, 0.22, 0.58, 0.18, 0.82, 0.55, 0.72, 0.72, 0.40, 0.56, 0.22, 0.86, 0.30]),
        points([0.09, 0.68, 0.28, 0.74, 0.34, 0.40, 0.20, 0.20, 0.58, 0.22, 0.74, 0.48, 0.52, 0.70, 0.82, 0.78]),
        points([0.14, 0.42, 0.31, 0.18, 0.55, 0.28, 0.72, 0.18, 0.82, 0.44, 0.61, 0.58, 0.44, 0.42, 0.30, 0.72, 0.87, 0.70]),
        points([0.10, 0.18, 0.24, 0.52, 0.48, 0.65, 0.56, 0.26, 0.78, 0.22, 0.88, 0.54, 0.72, 0.78, 0.40, 0.70, 0.16, 0.82]),
        points([0.12, 0.55, 0.30, 0.26, 0.52, 0.18, 0.68, 0.40, 0.50, 0.60, 0.28, 0.47, 0.38, 0.78, 0.82, 0.71]),
        points([0.11, 0.32, 0.34, 0.18, 0.60, 0.25, 0.84, 0.18, 0.76, 0.54, 0.54, 0.72, 0.38, 0.44, 0.18, 0.76, 0.88, 0.68]),
        points([0.12, 0.80, 0.20, 0.37, 0.42, 0.18, 0.65, 0.30, 0.76, 0.62, 0.56, 0.78, 0.36, 0.56, 0.53, 0.37, 0.88, 0.46]),
        points([0.09, 0.47, 0.22, 0.22, 0.44, 0.33, 0.61, 0.16, 0.84, 0.28, 0.73, 0.57, 0.48, 0.47, 0.32, 0.72, 0.86, 0.78]),
        points([0.13, 0.67, 0.28, 0.20, 0.54, 0.18, 0.43, 0.52, 0.64, 0.76, 0.81, 0.51, 0.63, 0.33, 0.28, 0.41, 0.18, 0.80]),
        points([0.11, 0.24, 0.29, 0.72, 0.47, 0.47, 0.65, 0.76, 0.86, 0.54, 0.69, 0.22, 0.43, 0.20, 0.22, 0.42, 0.54, 0.61, 0.88, 0.31]),
        points([0.10, 0.62, 0.23, 0.18, 0.50, 0.32, 0.73, 0.17, 0.88, 0.42, 0.70, 0.72, 0.45, 0.62, 0.28, 0.77, 0.16, 0.48, 0.54, 0.43]),
        points([0.14, 0.30, 0.34, 0.16, 0.57, 0.34, 0.80, 0.22, 0.86, 0.58, 0.62, 0.78, 0.42, 0.56, 0.20, 0.73, 0.27, 0.38, 0.74, 0.45]),
        points([0.09, 0.72, 0.30, 0.75, 0.45, 0.46, 0.24, 0.25, 0.58, 0.18, 0.82, 0.34, 0.67, 0.62, 0.43, 0.74, 0.51, 0.31, 0.88, 0.68]),
        points([0.13, 0.50, 0.25, 0.19, 0.48, 0.22, 0.69, 0.44, 0.83, 0.24, 0.89, 0.61, 0.66, 0.79, 0.47, 0.58, 0.25, 0.78, 0.17, 0.42])
    ]

    static func random(excluding excludedID: String? = nil) -> Scribble {
        var baseIndex = Int.random(in: bases.indices)
        var variant = Int.random(in: 0..<4)
        var id = "\(baseIndex)-\(variant)"

        if id == excludedID {
            baseIndex = (baseIndex + 1) % bases.count
            variant = (variant + 1) % 4
            id = "\(baseIndex)-\(variant)"
        }

        let flipX = variant == 1 || variant == 3
        let flipY = variant == 2 || variant == 3
        let transformed = bases[baseIndex].map { point in
            CGPoint(
                x: flipX ? 1 - point.x : point.x,
                y: flipY ? 1 - point.y : point.y
            )
        }

        return Scribble(id: id, points: transformed)
    }

    private static func points(_ values: [CGFloat]) -> [CGPoint] {
        stride(from: 0, to: values.count, by: 2).map {
            CGPoint(x: values[$0], y: values[$0 + 1])
        }
    }
}

private enum ScribbleRenderer {
    static func draw(_ scribble: Scribble, in context: CGContext, size: CGSize, inset: CGFloat) {
        let rect = CGRect(
            x: inset,
            y: inset,
            width: max(1, size.width - inset * 2),
            height: max(1, size.height - inset * 2)
        )
        let points = scribble.points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        guard let first = points.first else { return }

        context.beginPath()
        context.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            context.addQuadCurve(to: midpoint, control: previous)
        }
        if let previous = points.dropLast().last, let last = points.last {
            context.addQuadCurve(to: last, control: previous)
        }
        context.setStrokeColor(UIColor(white: 0.34, alpha: 1).cgColor)
        context.setLineWidth(13)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()

        context.setFillColor(UIColor.black.cgColor)
        context.fillEllipse(in: CGRect(x: first.x - 17, y: first.y - 17, width: 34, height: 34))

        if let last = points.last {
            context.setFillColor(NotebookColors.uiPaper.cgColor)
            context.fillEllipse(in: CGRect(x: last.x - 18, y: last.y - 18, width: 36, height: 36))
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(9)
            context.strokeEllipse(in: CGRect(x: last.x - 18, y: last.y - 18, width: 36, height: 36))
        }
    }
}

private struct NotebookBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                NotebookColors.paper

                PaperLines(spacing: 32)
                    .stroke(NotebookColors.rule, lineWidth: 1)

                Rectangle()
                    .fill(NotebookColors.margin)
                    .frame(width: 1.5)
                    .offset(x: min(42, proxy.size.width * 0.12))
            }
        }
        .ignoresSafeArea()
    }
}

private struct PaperLines: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.minY + spacing
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return path
    }
}

private struct HandUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.midY + 1))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 2, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.28, y: rect.maxY),
            control2: CGPoint(x: rect.width * 0.67, y: rect.minY)
        )
        return path
    }
}

private enum NotebookRenderer {
    static func drawBackground(in context: CGContext, size: CGSize, scale: CGFloat) {
        context.setFillColor(NotebookColors.uiPaper.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        context.setStrokeColor(UIColor(red: 0.58, green: 0.69, blue: 0.75, alpha: 0.24).cgColor)
        context.setLineWidth(2)
        var y: CGFloat = 52
        while y < size.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            y += 32 * scale
        }
        context.strokePath()

        context.setStrokeColor(UIColor(red: 0.82, green: 0.30, blue: 0.29, alpha: 0.56).cgColor)
        context.setLineWidth(3)
        let marginX = min(82, size.width * 0.12)
        context.move(to: CGPoint(x: marginX, y: 0))
        context.addLine(to: CGPoint(x: marginX, y: size.height))
        context.strokePath()
    }
}

private enum NotebookColors {
    static let paper = Color(red: 0.985, green: 0.975, blue: 0.92)
    static let rule = Color(red: 0.42, green: 0.57, blue: 0.66).opacity(0.20)
    static let margin = Color(red: 0.82, green: 0.30, blue: 0.29).opacity(0.58)
    static let uiPaper = UIColor(red: 0.985, green: 0.975, blue: 0.92, alpha: 1)
}

private enum Ink {
    static let black = Color(red: 0.07, green: 0.07, blue: 0.065)
    static let scribble = Color(red: 0.34, green: 0.34, blue: 0.33)
    static let blue = Color(red: 0.10, green: 0.35, blue: 0.60)
    static let red = Color(red: 0.78, green: 0.16, blue: 0.14)
}

private extension Font {
    static func doodleTitle(_ size: CGFloat) -> Font {
        .custom("Noteworthy-Bold", size: size, relativeTo: .title)
    }

    static func doodleBody(_ size: CGFloat) -> Font {
        .custom("Noteworthy", size: size, relativeTo: .body)
    }
}

private enum AppScreen {
    case home
    case revealing
    case drawing
    case result
    case archive
    case challenges
}

private struct DoodleSession: Equatable {
    let title: String
    let instruction: String
    let symbol: String
    let duration: Int
    let inks: [DoodleInk]
    let isChallenge: Bool

    static let classic = DoodleSession(
        title: "Classic",
        instruction: "Turn the scribble into anything.",
        symbol: "scribble",
        duration: 180,
        inks: [.black],
        isChallenge: false
    )

    var archiveTitle: String? {
        isChallenge ? title : nil
    }

    var shortDuration: String {
        duration < 60 ? "\(duration) sec" : "\(duration / 60) min"
    }
}

private struct ChallengePack: Identifiable {
    let id: String
    let session: DoodleSession
}

private enum ChallengeLibrary {
    static let packs = [
        ChallengePack(
            id: "quick-spark",
            session: DoodleSession(
                title: "Quick Spark",
                instruction: "Make it recognizable before time runs out.",
                symbol: "bolt.fill",
                duration: 60,
                inks: [.black],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "build-it",
            session: DoodleSession(
                title: "Build It",
                instruction: "Invent something useful from the scribble.",
                symbol: "hammer.fill",
                duration: 300,
                inks: [.black, .blue],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "mood-lines",
            session: DoodleSession(
                title: "Mood Lines",
                instruction: "Draw the feeling your day left behind.",
                symbol: "heart.fill",
                duration: 300,
                inks: [.black, .red],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "soundtrack-sketch",
            session: DoodleSession(
                title: "Soundtrack Sketch",
                instruction: "Let whatever you hear shape the scribble.",
                symbol: "headphones",
                duration: 600,
                inks: [.black, .blue, .red],
                isChallenge: true
            )
        )
    ]
}

private enum DoodleInk: String, CaseIterable, Identifiable, Equatable {
    case black
    case blue
    case red

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .black:
            return Ink.black
        case .blue:
            return Ink.blue
        case .red:
            return Ink.red
        }
    }

    var uiColor: UIColor {
        switch self {
        case .black:
            return UIColor(red: 0.07, green: 0.07, blue: 0.065, alpha: 1)
        case .blue:
            return UIColor(red: 0.10, green: 0.35, blue: 0.60, alpha: 1)
        case .red:
            return UIColor(red: 0.78, green: 0.16, blue: 0.14, alpha: 1)
        }
    }
}

private enum InkPalette: String, CaseIterable, Identifiable {
    case black
    case duo
    case trio

    var id: String { rawValue }

    var label: String {
        switch self {
        case .black: return "Black"
        case .duo: return "Two"
        case .trio: return "Three"
        }
    }

    var inks: [DoodleInk] {
        switch self {
        case .black: return [.black]
        case .duo: return [.black, .blue]
        case .trio: return [.black, .blue, .red]
        }
    }
}

private enum ChallengeDuration: Int, CaseIterable, Identifiable {
    case oneMinute = 60
    case threeMinutes = 180
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900

    var id: Int { rawValue }
    var seconds: Int { rawValue }

    var label: String {
        "\(rawValue / 60)m"
    }
}

private enum IdeaBank {
    private static let ideas = [
        "airplane", "clock", "anchor", "astronaut", "backpack", "balloon",
        "bicycle", "cupcake", "camera", "castle", "catapult", "cactus",
        "dragon", "drum", "flashlight", "flowerpot", "fountain", "guitar",
        "hamburger", "helicopter", "jellyfish", "kite", "lighthouse", "mailbox",
        "microscope", "monster", "mushroom", "octopus", "pirate", "popcorn",
        "racecar", "rainbow", "robot", "rocket", "sandcastle", "sandwich",
        "seahorse", "sneaker", "spaceship", "submarine", "teapot", "telescope",
        "treehouse", "trophy", "umbrella", "volcano", "whale", "windmill"
    ]

    static func random(excluding excluded: String?) -> String {
        let choices = ideas.filter { $0 != excluded }
        return choices.randomElement() ?? ideas[0]
    }
}

private struct DoodleRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let imageFilename: String
    let drawingFilename: String
    let sessionTitle: String?
    let prompt: String?

    var shareCaption: String {
        let session = sessionTitle.map { "the \($0) challenge" } ?? "one random scribble"
        let idea = prompt.map { " My idea was \($0)." } ?? ""
        return "I turned \(session) into this with Just Doodle.\(idea) #JustDoodle"
    }
}

@MainActor
private final class DoodleArchiveStore: ObservableObject {
    @Published private(set) var records: [DoodleRecord] = []

    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let directoryURL: URL
    private let indexURL: URL

    init() {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directoryURL = applicationSupport.appendingPathComponent("JustDoodle", isDirectory: true)
        indexURL = directoryURL.appendingPathComponent("doodles.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func save(
        image: UIImage,
        drawing: PKDrawing,
        sessionTitle: String?,
        prompt: String?
    ) -> DoodleRecord? {
        let previousRecords = records
        var createdURLs: [URL] = []

        do {
            try prepareDirectory()
            let id = UUID()
            let imageFilename = "\(id.uuidString).png"
            let drawingFilename = "\(id.uuidString).drawing"
            guard let imageData = image.pngData() else { return nil }

            let imageURL = directoryURL.appendingPathComponent(imageFilename)
            let drawingURL = directoryURL.appendingPathComponent(drawingFilename)

            try imageData.write(to: imageURL, options: .atomic)
            createdURLs.append(imageURL)
            try drawing.dataRepresentation().write(
                to: drawingURL,
                options: .atomic
            )
            createdURLs.append(drawingURL)

            let record = DoodleRecord(
                id: id,
                createdAt: Date(),
                imageFilename: imageFilename,
                drawingFilename: drawingFilename,
                sessionTitle: sessionTitle,
                prompt: prompt
            )
            records.insert(record, at: 0)
            try persist()
            return record
        } catch {
            records = previousRecords
            createdURLs.forEach { try? fileManager.removeItem(at: $0) }
            return nil
        }
    }

    func image(for record: DoodleRecord) -> UIImage? {
        UIImage(contentsOfFile: directoryURL.appendingPathComponent(record.imageFilename).path)
    }

    func delete(_ record: DoodleRecord) {
        let previousRecords = records
        records.removeAll { $0.id == record.id }
        do {
            try persist()
            try? fileManager.removeItem(at: directoryURL.appendingPathComponent(record.imageFilename))
            try? fileManager.removeItem(at: directoryURL.appendingPathComponent(record.drawingFilename))
        } catch {
            records = previousRecords
        }
    }

    private func load() {
        do {
            try prepareDirectory()
            guard fileManager.fileExists(atPath: indexURL.path) else { return }
            records = try decoder.decode([DoodleRecord].self, from: Data(contentsOf: indexURL))
                .filter { fileManager.fileExists(atPath: directoryURL.appendingPathComponent($0.imageFilename).path) }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            records = []
        }
    }

    private func persist() throws {
        try encoder.encode(records).write(to: indexURL, options: .atomic)
    }

    private func prepareDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}

private struct ArchivePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let record: DoodleRecord
    let image: UIImage?
    let onDelete: () -> Void

    @State private var shareImage: ShareImage?
    @State private var notice: Notice?
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            NotebookBackground()

            VStack(spacing: 0) {
                HStack {
                    IconButton(systemName: "xmark", label: "Close") { dismiss() }
                    Spacer()
                    VStack(spacing: 1) {
                        Text(record.sessionTitle ?? "Classic")
                            .font(.doodleTitle(18))
                            .foregroundStyle(Ink.black)
                            .lineLimit(1)
                        Text(record.createdAt.doodleDate)
                            .font(.doodleBody(14))
                            .foregroundStyle(Ink.black.opacity(0.66))
                            .lineLimit(1)
                    }
                    Spacer()
                    IconButton(systemName: "trash", label: "Delete doodle") {
                        confirmDelete = true
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 60)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 14)
                }

                HStack(spacing: 16) {
                    Spacer()
                    IconButton(systemName: "square.and.arrow.down", label: "Save to Photos") {
                        guard let image else { return }
                        PhotoSaver.save(image) { notice = $0 }
                    }
                    IconButton(systemName: "square.and.arrow.up", label: "Share doodle") {
                        guard let image else { return }
                        shareImage = ShareImage(image: image, caption: record.shareCaption)
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
        .preferredColorScheme(.light)
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image, item.caption])
        }
        .alert(item: $notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog("Delete this doodle?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private enum PhotoSaver {
    static func save(_ image: UIImage, completion: @escaping (Notice) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(
                        Notice(
                            title: "Photos Access Needed",
                            message: "Allow Just Doodle to add photos in Settings, then try again."
                        )
                    )
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    completion(
                        Notice(
                            title: success ? "Doodle Saved" : "Couldn’t Save",
                            message: success
                                ? "Your drawing is now in Photos."
                                : (error?.localizedDescription ?? "Please try again.")
                        )
                    )
                }
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let caption: String
}

private enum Haptics {
    static func timeUp() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}

private struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct CanvasSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension Date {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
