import SwiftUI
import PencilKit
import Photos
import UIKit

struct DoodlersClubSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            .scaleEffect(inkVisible || reduceMotion ? 1 : 0.94)
            .rotationEffect(.degrees(inkVisible || reduceMotion ? 0 : -4))
        }
        .modifier(InkWindow())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Doodler's Club")
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.82)) {
                inkVisible = true
            }
        }
    }
}

struct ScribbleSurface: View {
    let scribble: Scribble
    let revealProgress: CGFloat
    @Binding var drawing: PKDrawing
    let isDrawingEnabled: Bool
    let ink: DoodleInk
    let bridge: CanvasBridge

    var body: some View {
        GeometryReader { proxy in
            let scale = max(0.01, min(proxy.size.width / DrawingPage.size.width, proxy.size.height / DrawingPage.size.height))
            ZStack {
                Canvas { context, size in
                    context.withCGContext { NotebookRenderer.drawBackground(in: $0, size: size, scale: 1) }
                }
                .frame(width: DrawingPage.size.width, height: DrawingPage.size.height)
                ScribbleInk(scribble: scribble, progress: revealProgress)
                    .padding(DrawingPage.inset)
                    .frame(width: DrawingPage.size.width, height: DrawingPage.size.height)
                    .allowsHitTesting(false)
                InkOnlyCanvas(drawing: $drawing, isDrawingEnabled: isDrawingEnabled, ink: ink, bridge: bridge)
                    .frame(width: DrawingPage.size.width, height: DrawingPage.size.height)
            }
            .frame(width: DrawingPage.size.width, height: DrawingPage.size.height)
            .clipped()
            .overlay(Rectangle().strokeBorder(NotebookColors.rule, lineWidth: 0.75))
            .scaleEffect(scale)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DoodleArtworkPreview: View {
    let image: UIImage
    let label: String

    var body: some View {
        // Bound the image to the space left by the header and actions, not its ideal size.
        GeometryReader { bounds in
            Image(uiImage: image).resizable().scaledToFit()
                .frame(width: bounds.size.width, height: bounds.size.height)
                .accessibilityLabel(label)
        }
    }
}

struct ChallengePackButton: View {
    let pack: ChallengePack
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: pack.session.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Ink.black)
                    .frame(width: 44, height: 48)
                    .background(HandCircle().fill(accent.opacity(0.24)).frame(width: 40, height: 40))
                    .overlay(HandCircle().stroke(Ink.black, lineWidth: 1.3).frame(width: 42, height: 42))

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.session.title)
                        .font(.doodleTitle(21))
                        .foregroundStyle(Ink.black)

                    Text(pack.session.instruction)
                        .font(.doodleBody(16))
                        .foregroundStyle(Ink.black.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
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
            .padding(.horizontal, 4)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { InkDivider() }
        }
        .buttonStyle(InkPressStyle())
        .accessibilityIdentifier("challenge-\(pack.id)")
        .accessibilityLabel(
            "\(pack.session.title). \(pack.session.instruction). \(pack.session.shortDuration)."
        )
    }

    private var accent: Color {
        switch pack.session.inks.count {
        case 1: return .yellow
        case 2: return Ink.red
        default: return Ink.blue
        }
    }
}

struct CustomChallengeBuilder: View {
    @Binding var duration: ChallengeDuration
    @Binding var palette: InkPalette
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InkSectionTitle(title: "Make Your Own", symbol: "slider.horizontal.3")

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

                HStack(spacing: 12) {
                    ForEach(InkPalette.allCases) { choice in
                        Button { palette = choice } label: {
                            InkSwatches(inks: choice.inks, size: 16)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(HandDrawnBox().fill(palette == choice ? Ink.blue.opacity(0.08) : .clear))
                                .overlay(HandDrawnBox().stroke(palette == choice ? Ink.blue : Ink.black.opacity(0.2), lineWidth: 1.5))
                        }
                        .buttonStyle(InkPressStyle())
                        .accessibilityLabel(choice.label)
                        .accessibilityAddTraits(palette == choice ? .isSelected : [])
                    }
                }
            }

            Button(action: start) {
                Label("Start challenge", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkCommandStyle())
            .accessibilityIdentifier("startCustomChallenge")
        }
        .padding(.vertical, 6)
    }
}

struct InkPalettePicker: View {
    let inks: [DoodleInk]
    @Binding var selection: DoodleInk

    var body: some View {
        HStack(spacing: 10) {
            ForEach(inks) { ink in
                Button {
                    selection = ink
                } label: {
                    PenSwatch(ink: ink, selected: selection == ink)
                }
                .buttonStyle(InkPressStyle())
                .accessibilityLabel("\(ink.name) ink")
                .accessibilityIdentifier("ink-\(ink.rawValue)")
                .accessibilityAddTraits(selection == ink ? .isSelected : [])
            }
        }
        .padding(4)
    }
}

struct InkSwatches: View {
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

struct IdeaBox: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let idea: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HandDrawnBox()
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.74))

                HandDrawnBox()
                    .stroke(
                        Ink.black,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                VStack(spacing: 4) {
                    Text("Idea Box")
                        .font(.doodleTitle(17))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(Ink.black)

                    HandUnderline()
                        .stroke(Ink.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 58, height: 5)

                    Text(idea ?? "?")
                        .font(.doodleBody(17))
                        .foregroundStyle(idea == nil ? Ink.black.opacity(0.65) : Ink.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(maxWidth: 86)
                        .id(idea)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 5)), removal: .opacity))
                }
                .padding(9)
            }
            .frame(width: 100, height: 100)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.8), value: idea)
        }
        .buttonStyle(InkPressStyle())
        .accessibilityIdentifier("ideaBox")
        .accessibilityValue(idea ?? "No idea selected")
        .accessibilityLabel(idea.map { "Idea Box. Current idea: \($0). Tap for another idea." }
            ?? "Idea Box. Tap for a drawing idea.")
    }
}

struct HandDrawnBox: Shape {
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

struct StartDot: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil").font(.system(size: 22, weight: .medium))
                    Text("Start drawing").font(.doodleTitle(24)).lineLimit(1).minimumScaleFactor(0.65)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right").font(.system(size: 19, weight: .medium))
                }
                .foregroundStyle(.white).padding(.horizontal, 24).padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(HandDrawnBox().fill(Ink.black))
                .overlay { HandDrawnBox().stroke(Ink.black, lineWidth: 1).padding(-3) }
                Text("Classic / 3 min").font(.doodleBody(16)).foregroundStyle(Ink.black.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel("Begin a three minute scribble")
        .accessibilityIdentifier("startClassic")
    }
}

struct IconButton: View {
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
                .background(HandCircle().fill(filled ? Ink.black : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(label)
        .help(label)
    }
}

struct InkCommandStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.doodleTitle(20))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 48)
            .background(HandDrawnBox().fill(Ink.black.opacity(!isEnabled ? 0.3 : configuration.isPressed ? 0.75 : 1)))
            .overlay { HandDrawnBox().stroke(Ink.black.opacity(isEnabled ? 1 : 0.3), lineWidth: 1).padding(-3) }
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct InkPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.65 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

struct HomeMasthead: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var signed = false

    var body: some View {
        VStack(spacing: 0) {
            Image("JustDoodleWordmark")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 330)
                .frame(height: 82)
                .accessibilityLabel("Just Doodle")
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("brandWordmark")
            HandUnderline().trim(from: 0, to: signed ? 1 : 0)
                .stroke(Ink.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 176, height: 8)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.7).delay(0.15)) { signed = true }
        }
    }
}

struct HomeInkStudy: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    private let study = Scribble(id: "home-study", points: [
        CGPoint(x: 0.10, y: 0.70), CGPoint(x: 0.24, y: 0.08),
        CGPoint(x: 0.53, y: 0.14), CGPoint(x: 0.69, y: 0.82),
        CGPoint(x: 0.41, y: 0.93), CGPoint(x: 0.36, y: 0.27),
        CGPoint(x: 0.68, y: 0.20), CGPoint(x: 0.88, y: 0.45)
    ])

    var body: some View {
        ScribbleInk(scribble: study, progress: progress)
            .padding(12).frame(maxWidth: 260)
            .accessibilityHidden(true).allowsHitTesting(false)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.0).delay(0.15)) { progress = 1 }
            }
    }
}

struct HomeNavigationRow: View {
    let title: String
    let symbol: String
    let detail: String?
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.system(size: 26, weight: .regular))
                    .frame(width: 42, height: 44)
                    .background(HandCircle().fill(accent.opacity(0.22)).frame(width: 35, height: 31).offset(x: 3, y: 3))
                Text(title).font(.doodleTitle(21)).lineLimit(1).minimumScaleFactor(0.65)
                Spacer(minLength: 4)
                if let detail {
                    Text(detail).font(.doodleBody(17)).lineLimit(1).minimumScaleFactor(0.65)
                        .frame(width: 34).accessibilityLabel("\(detail) saved drawings")
                }
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Ink.black).padding(.vertical, 6).padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
            .overlay(alignment: .top) { HandUnderline().stroke(Ink.black, lineWidth: 1.3).frame(height: 4) }
        }
        .buttonStyle(InkPressStyle())
    }
}

struct PenSwatch: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let ink: DoodleInk
    let selected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "pencil.tip.crop.circle.fill")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(ink.color)
                .rotationEffect(.degrees(selected ? -12 : 0))
                .offset(y: selected ? -3 : 0)
            HandUnderline().stroke(ink.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 24, height: 4).opacity(selected ? 1 : 0)
        }
        .frame(width: 44, height: 52)
        .contentShape(Rectangle())
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.7), value: selected)
    }
}

struct RoundClock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let remaining: Int
    let duration: Int

    var body: some View {
        ZStack {
            HandCircle().stroke(Ink.black.opacity(0.09), lineWidth: 1.5)
            HandCircle().trim(from: 0, to: CGFloat(max(0, remaining)) / CGFloat(max(1, duration)))
                .stroke(remaining <= 20 ? Ink.red : Ink.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .animation(reduceMotion ? nil : .linear(duration: 0.35), value: remaining)
            Text(DoodleTime.string(remaining))
                .font(.doodleBody(24)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                .foregroundStyle(remaining <= 20 ? Ink.red : Ink.black)
                .padding(.horizontal, 7)
                .accessibilityLabel("\(remaining) seconds remaining")
                .accessibilityIdentifier("roundTimer")
        }
        .frame(width: 94, height: 52)
        .allowsHitTesting(false)
    }
}
