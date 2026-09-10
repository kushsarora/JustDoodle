import SwiftUI
import PencilKit
import Photos
import UIKit

struct DoodlersClubSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inkVisible = false

    var body: some View {
        ZStack {
            NotebookBackground(ruled: true)

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
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
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

struct ChallengePackButton: View {
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
            .overlay(alignment: .bottom) { Rectangle().fill(NotebookColors.rule).frame(height: 1) }
        }
        .buttonStyle(InkPressStyle())
        .accessibilityIdentifier("challenge-\(pack.id)")
        .accessibilityLabel(
            "\(pack.session.title). \(pack.session.instruction). \(pack.session.shortDuration)."
        )
    }
}

struct CustomChallengeBuilder: View {
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
                    Circle()
                        .fill(ink.color)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selection == ink ? 3 : 0)
                                .padding(3)
                        )
                        .overlay(Circle().stroke(Ink.black.opacity(0.65), lineWidth: 1))
                        .frame(width: 30, height: 30)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                    .fill(NotebookColors.paper.opacity(0.96))

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
                        .transition(.opacity)
                }
                .padding(9)
            }
            .frame(width: 100, height: 100)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: idea)
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
            VStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Ink.black.opacity(0.12), lineWidth: 1)
                        .frame(width: 92, height: 92)
                    Circle().fill(Ink.black).frame(width: 64, height: 64)
                    Image(systemName: "pencil.tip").font(.system(size: 25, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text("Start drawing").font(.doodleTitle(28)).foregroundStyle(Ink.black)
                Text("Classic · 3 minutes").font(.doodleBody(17)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
                .background(filled ? Ink.black : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(label)
        .help(label)
    }
}

struct InkCommandStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.doodleTitle(20))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .background(Ink.black.opacity(!isEnabled ? 0.3 : configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct InkPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.65 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
