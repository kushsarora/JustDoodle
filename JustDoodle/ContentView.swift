import Combine
import PencilKit
import Photos
import SwiftUI
import UIKit

struct ContentView: View {
    private static let roundLength = 240
    private static let prompts = [
        "Airplane", "Backpack", "Bicycle", "Birthday", "Camera", "Castle",
        "Cat", "Cloud", "Crown", "Dinosaur", "Dragon", "Flower", "Guitar",
        "Hamburger", "Hat", "House", "Icecream", "Jellyfish", "Key", "Lamp",
        "Lighthouse", "Monster", "Moon", "Octopus", "Pineapple", "Robot",
        "Rocket", "Sandwich", "Shark", "Sneaker", "Spaceship", "Teapot",
        "Tree", "Umbrella", "Volcano", "Whale"
    ]

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let inkChoices = InkChoice.all
    private let penWidths: [CGFloat] = [4, 7, 11]

    @State private var prompt = ContentView.prompts.randomElement() ?? "Robot"
    @State private var scribble = Scribble.random()
    @State private var drawing = PKDrawing()
    @State private var canvasSize: CGSize = .zero
    @State private var secondsRemaining = ContentView.roundLength
    @State private var isFinished = false
    @State private var selectedInk = InkChoice.all[0]
    @State private var selectedWidth: CGFloat = 7
    @State private var shareImage: ShareImage?
    @State private var notice: Notice?

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.94, blue: 0.90)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                promptStrip
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                drawingBoard
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)

                if isFinished {
                    finishedControls
                } else {
                    drawingControls
                }
            }
            .padding(.bottom, 10)
        }
        .preferredColorScheme(.light)
        .onReceive(timer) { _ in
            guard !isFinished else { return }
            if secondsRemaining > 1 {
                secondsRemaining -= 1
            } else {
                secondsRemaining = 0
                finishRound()
            }
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image])
        }
        .alert(item: $notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("JUST")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.88, green: 0.22, blue: 0.16))
                Text("DOODLE")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.12))
            }

            Spacer()

            Label(formattedTime, systemImage: "timer")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(secondsRemaining <= 30 ? Color.red : Color.primary)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Button(action: newRound) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
            .background(Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .accessibilityLabel("New round")
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var promptStrip: some View {
        HStack(spacing: 10) {
            Text(isFinished ? "YOUR DOODLE" : "DRAW A")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.secondary)

            Text(prompt.uppercased())
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.88, green: 0.22, blue: 0.16))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            if isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(red: 0.11, green: 0.55, blue: 0.34))
                    .accessibilityLabel("Round finished")
            }
        }
        .frame(height: 42)
    }

    private var drawingBoard: some View {
        ZStack {
            Color.white

            PaperLines()
                .stroke(Color(red: 0.36, green: 0.66, blue: 0.78).opacity(0.12), lineWidth: 1)
                .allowsHitTesting(false)

            ScribbleShape(points: scribble.points)
                .stroke(
                    Color(red: 0.22, green: 0.22, blue: 0.22),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                .padding(24)
                .allowsHitTesting(false)

            DrawingCanvas(
                drawing: $drawing,
                inkColor: selectedInk.uiColor,
                lineWidth: selectedWidth,
                isDrawingEnabled: !isFinished
            )
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CanvasSizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(CanvasSizePreferenceKey.self) { canvasSize = $0 }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.11), radius: 8, y: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Drawing canvas for \(prompt)")
    }

    private var drawingControls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(inkChoices) { ink in
                    Button {
                        selectedInk = ink
                    } label: {
                        Circle()
                            .fill(ink.color)
                            .frame(width: 27, height: 27)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedInk.id == ink.id ? 3 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(selectedInk.id == ink.id ? 0.75 : 0.18), lineWidth: 1)
                                    .padding(selectedInk.id == ink.id ? -3 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(ink.name) ink")
                }
            }

            Divider()
                .frame(height: 30)

            Menu {
                ForEach(penWidths, id: \.self) { width in
                    Button {
                        selectedWidth = width
                    } label: {
                        Label(
                            width == 4 ? "Fine" : (width == 7 ? "Medium" : "Bold"),
                            systemImage: selectedWidth == width ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                Image(systemName: "lineweight")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .foregroundStyle(Color.primary)
            .accessibilityLabel("Pen width")

            Spacer(minLength: 0)

            Button(action: finishRound) {
                Label("Done", systemImage: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(Color(red: 0.88, green: 0.22, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
    }

    private var finishedControls: some View {
        HStack(spacing: 10) {
            Button(action: saveToPhotos) {
                Label("Save", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(ActionButtonStyle(filled: false))

            Button(action: shareDrawing) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(ActionButtonStyle(filled: true))

            Button(action: newRound) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 48, height: 46)
            }
            .buttonStyle(ActionButtonStyle(filled: false))
            .accessibilityLabel("Start new round")
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
    }

    private var formattedTime: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    private func finishRound() {
        isFinished = true
    }

    private func newRound() {
        var nextPrompt = prompt
        while nextPrompt == prompt && ContentView.prompts.count > 1 {
            nextPrompt = ContentView.prompts.randomElement() ?? "Robot"
        }

        prompt = nextPrompt
        scribble = .random()
        drawing = PKDrawing()
        secondsRemaining = ContentView.roundLength
        isFinished = false
    }

    private func shareDrawing() {
        guard let image = renderedDrawing() else { return }
        shareImage = ShareImage(image: image)
    }

    private func saveToPhotos() {
        guard let image = renderedDrawing() else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    notice = Notice(
                        title: "Photos Access Needed",
                        message: "Allow Just Doodle to add photos in Settings, then try again."
                    )
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    notice = Notice(
                        title: success ? "Doodle Saved" : "Couldn’t Save",
                        message: success
                            ? "Your finished drawing is now in Photos."
                            : (error?.localizedDescription ?? "Please try again.")
                    )
                }
            }
        }
    }

    private func renderedDrawing() -> UIImage? {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }

        let outputWidth: CGFloat = 1200
        let headerHeight: CGFloat = 180
        let outputCanvasHeight = outputWidth * (canvasSize.height / canvasSize.width)
        let outputSize = CGSize(width: outputWidth, height: headerHeight + outputCanvasHeight)
        let renderer = UIGraphicsImageRenderer(size: outputSize)

        return renderer.image { context in
            let cg = context.cgContext
            UIColor(red: 0.95, green: 0.94, blue: 0.90, alpha: 1).setFill()
            cg.fill(CGRect(origin: .zero, size: outputSize))

            let title = "JUST DOODLE"
            title.draw(
                at: CGPoint(x: 54, y: 34),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 30, weight: .black),
                    .foregroundColor: UIColor(red: 0.88, green: 0.22, blue: 0.16, alpha: 1)
                ]
            )
            prompt.uppercased().draw(
                at: CGPoint(x: 54, y: 82),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 58, weight: .black),
                    .foregroundColor: UIColor(white: 0.10, alpha: 1)
                ]
            )

            let outputCanvasRect = CGRect(x: 0, y: headerHeight, width: outputWidth, height: outputCanvasHeight)
            UIColor.white.setFill()
            cg.fill(outputCanvasRect)

            cg.saveGState()
            cg.translateBy(x: 0, y: headerHeight)
            drawPaperLines(in: cg, size: outputCanvasRect.size)
            drawScribble(in: cg, size: outputCanvasRect.size)
            cg.restoreGState()

            let sourceRect = CGRect(origin: .zero, size: canvasSize)
            let drawingImage = drawing.image(from: sourceRect, scale: 2)
            drawingImage.draw(in: outputCanvasRect)
        }
    }

    private func drawPaperLines(in context: CGContext, size: CGSize) {
        context.setStrokeColor(UIColor(red: 0.36, green: 0.66, blue: 0.78, alpha: 0.12).cgColor)
        context.setLineWidth(2)
        var y: CGFloat = 72
        while y < size.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            y += 72
        }
        context.strokePath()
    }

    private func drawScribble(in context: CGContext, size: CGSize) {
        let inset: CGFloat = 68
        let rect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
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
        context.setStrokeColor(UIColor(white: 0.22, alpha: 1).cgColor)
        context.setLineWidth(14)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
    }
}

private struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let inkColor: UIColor
    let lineWidth: CGFloat
    let isDrawingEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.isScrollEnabled = false
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: lineWidth)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvas.drawing = drawing
        }
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: lineWidth)
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

private struct ScribbleShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mapped = points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        guard let first = mapped.first else { return path }

        path.move(to: first)
        for index in 1..<mapped.count {
            let previous = mapped[index - 1]
            let current = mapped[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: midpoint, control: previous)
        }
        if let previous = mapped.dropLast().last, let last = mapped.last {
            path.addQuadCurve(to: last, control: previous)
        }
        return path
    }
}

private struct PaperLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.minY + 24
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += 24
        }
        return path
    }
}

private struct Scribble {
    let points: [CGPoint]

    static func random() -> Scribble {
        let count = Int.random(in: 7...11)
        var points: [CGPoint] = []
        var previous = CGPoint(x: CGFloat.random(in: 0.15...0.85), y: CGFloat.random(in: 0.15...0.85))
        points.append(previous)

        for _ in 1..<count {
            var candidate = CGPoint.zero
            repeat {
                candidate = CGPoint(x: CGFloat.random(in: 0.08...0.92), y: CGFloat.random(in: 0.08...0.92))
            } while hypot(candidate.x - previous.x, candidate.y - previous.y) < 0.22
            points.append(candidate)
            previous = candidate
        }

        return Scribble(points: points)
    }
}

private struct InkChoice: Identifiable {
    let id: String
    let name: String
    let color: Color
    let uiColor: UIColor

    static let all = [
        InkChoice(id: "charcoal", name: "Charcoal", color: Color(red: 0.09, green: 0.09, blue: 0.10), uiColor: UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1)),
        InkChoice(id: "red", name: "Red", color: Color(red: 0.88, green: 0.22, blue: 0.16), uiColor: UIColor(red: 0.88, green: 0.22, blue: 0.16, alpha: 1)),
        InkChoice(id: "blue", name: "Blue", color: Color(red: 0.10, green: 0.38, blue: 0.75), uiColor: UIColor(red: 0.10, green: 0.38, blue: 0.75, alpha: 1)),
        InkChoice(id: "green", name: "Green", color: Color(red: 0.08, green: 0.52, blue: 0.31), uiColor: UIColor(red: 0.08, green: 0.52, blue: 0.31, alpha: 1))
    ]
}

private struct ActionButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(filled ? Color.white : Color.primary)
            .background(filled ? Color(red: 0.88, green: 0.22, blue: 0.16) : Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .opacity(configuration.isPressed ? 0.72 : 1)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
