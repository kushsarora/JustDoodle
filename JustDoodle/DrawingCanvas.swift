import SwiftUI
import PencilKit
import Photos
import UIKit

enum DrawingPage {
    static let size = CGSize(width: 360, height: 480)
    static let inset: CGFloat = 28
    static let lineWidth: CGFloat = 5
    static let penWidth: CGFloat = 5.5

    static func mappedPoints(_ scribble: Scribble) -> [CGPoint] {
        scribble.points.map {
            CGPoint(x: inset + $0.x * (size.width - 2 * inset),
                    y: inset + $0.y * (size.height - 2 * inset))
        }
    }
}

@MainActor
final class CanvasBridge {
    weak var canvas: LockedInkCanvasView?

    func freeze() -> PKDrawing? {
        canvas?.isUserInteractionEnabled = false
        return canvas?.drawing
    }
}

struct InkOnlyCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let isDrawingEnabled: Bool
    let ink: DoodleInk
    let bridge: CanvasBridge

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> LockedInkCanvasView {
        let canvas = LockedInkCanvasView()
        bridge.canvas = canvas
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.isScrollEnabled = false
        canvas.contentInset = .zero
        canvas.contentOffset = .zero
        canvas.contentSize = DrawingPage.size
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.tool = PKInkingTool(.pen, color: ink.uiColor, width: DrawingPage.penWidth)
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        context.coordinator.ink = ink
        canvas.isUserInteractionEnabled = isDrawingEnabled
        canvas.accessibilityIdentifier = "drawingCanvas"
        canvas.isAccessibilityElement = true
        canvas.accessibilityLabel = "Drawing canvas"
        return canvas
    }

    func updateUIView(_ canvas: LockedInkCanvasView, context: Context) {
        context.coordinator.drawing = $drawing
        bridge.canvas = canvas
        if canvas.drawing != drawing {
            context.coordinator.isSynchronizing = true
            canvas.drawing = drawing
            context.coordinator.isSynchronizing = false
        }
        canvas.contentInset = .zero
        canvas.contentOffset = .zero
        canvas.contentSize = DrawingPage.size
        if context.coordinator.ink != ink {
            canvas.tool = PKInkingTool(.pen, color: ink.uiColor, width: DrawingPage.penWidth)
            context.coordinator.ink = ink
        }
        canvas.isUserInteractionEnabled = isDrawingEnabled
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        var ink: DoodleInk?
        var isSynchronizing = false

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isSynchronizing, drawing.wrappedValue != canvasView.drawing else { return }
            drawing.wrappedValue = canvasView.drawing
        }
    }
}

final class LockedInkCanvasView: PKCanvasView {
    override var undoManager: UndoManager? { nil }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}

struct ScribbleInk: View, Animatable {
    let scribble: Scribble
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let first = mapped(scribble.points.first ?? .zero, in: proxy.size)
            let last = mapped(scribble.points.last ?? .zero, in: proxy.size)

            ZStack(alignment: .topLeading) {
                ScribbleShape(points: scribble.points)
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(
                        Ink.scribble,
                        style: StrokeStyle(lineWidth: DrawingPage.lineWidth, lineCap: .round, lineJoin: .round)
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
                    .opacity(Double(min(1, max(0, (progress - 0.94) / 0.06))))
            }
        }
    }

    private func mapped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

struct ScribbleShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        let mappedPoints = points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        return ScribblePath.path(points: mappedPoints)
    }
}

enum ScribblePath {
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
        // End on the same tangent as the preceding segment, without doubling back.
        if points.count > 1, let last = points.last {
            path.addQuadCurve(to: last, control: last)
        }
        return path
    }
}

struct Scribble: Codable, Equatable {
    let id: String
    let points: [CGPoint]
}

enum ScribbleLibrary {
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
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator, excluding: excludedID)
    }

    static func random<R: RandomNumberGenerator>(using generator: inout R, excluding excludedID: String? = nil) -> Scribble {
        var baseIndex = Int.random(in: bases.indices, using: &generator)
        var variant = Int.random(in: 0..<4, using: &generator)
        var id = "\(baseIndex)-\(variant)"

        if id == excludedID {
            baseIndex = (baseIndex + 1) % bases.count
            variant = (variant + 1) % 4
            id = "\(baseIndex)-\(variant)"
        }

        let flipX = variant == 1 || variant == 3
        let flipY = variant == 2 || variant == 3
        let angle = CGFloat.random(in: -0.16...0.16, using: &generator)
        let scale = CGFloat.random(in: 0.90...1.0, using: &generator)
        let transformed = bases[baseIndex].map { point in
            let x = (flipX ? 1 - point.x : point.x) - 0.5 + CGFloat.random(in: -0.035...0.035, using: &generator)
            let y = (flipY ? 1 - point.y : point.y) - 0.5 + CGFloat.random(in: -0.035...0.035, using: &generator)
            return CGPoint(
                x: min(0.94, max(0.06, 0.5 + scale * (x * cos(angle) - y * sin(angle)))),
                y: min(0.94, max(0.06, 0.5 + scale * (x * sin(angle) + y * cos(angle))))
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

enum ScribbleRenderer {
    static func draw(_ scribble: Scribble, in context: CGContext) {
        let points = DrawingPage.mappedPoints(scribble)
        guard let first = points.first, let last = points.last else { return }
        context.addPath(ScribblePath.path(points: points).cgPath)
        context.setStrokeColor(UIColor(red: 0.34, green: 0.34, blue: 0.33, alpha: 1).cgColor)
        context.setLineWidth(DrawingPage.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.setFillColor(UIColor(Ink.black).cgColor)
        context.fillEllipse(in: CGRect(x: first.x - 7.5, y: first.y - 7.5, width: 15, height: 15))
        let end = CGRect(x: last.x - 8.5, y: last.y - 8.5, width: 17, height: 17)
        context.setFillColor(NotebookColors.uiPaper.cgColor)
        context.fillEllipse(in: end)
        context.setStrokeColor(UIColor(Ink.black).cgColor)
        context.setLineWidth(4)
        context.strokeEllipse(in: end)
    }
}
