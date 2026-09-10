import SwiftUI
import PencilKit
import Photos
import UIKit

struct NotebookBackground: View {
    var ruled = false

    var body: some View {
        ZStack {
            NotebookColors.paper
            if ruled {
                Canvas { context, size in
                    context.withCGContext { NotebookRenderer.drawBackground(in: $0, size: size, scale: 1) }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct PaperLines: Shape {
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

struct HandUnderline: Shape {
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

enum NotebookRenderer {
    static func drawBackground(in context: CGContext, size: CGSize, scale: CGFloat) {
        context.setFillColor(NotebookColors.uiPaper.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        context.setStrokeColor(UIColor(NotebookColors.rule).cgColor)
        context.setLineWidth(scale)
        var y: CGFloat = 32 * scale
        while y < size.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            y += 32 * scale
        }
        context.strokePath()

        context.setStrokeColor(UIColor(NotebookColors.margin).cgColor)
        context.setLineWidth(1.5 * scale)
        let marginX = min(42 * scale, size.width * 0.12)
        context.move(to: CGPoint(x: marginX, y: 0))
        context.addLine(to: CGPoint(x: marginX, y: size.height))
        context.strokePath()
    }
}

enum NotebookColors {
    static let paper = Color(uiPaper)
    static let rule = Color(red: 0.42, green: 0.57, blue: 0.66).opacity(0.20)
    static let margin = Color(red: 0.82, green: 0.30, blue: 0.29).opacity(0.58)
    static let uiPaper = UIColor(red: 0.99, green: 0.99, blue: 0.985, alpha: 1)
}

enum Ink {
    static let black = Color(red: 0.07, green: 0.07, blue: 0.065)
    static let scribble = Color(red: 0.34, green: 0.34, blue: 0.33)
    static let blue = Color(red: 0.10, green: 0.35, blue: 0.60)
    static let red = Color(red: 0.78, green: 0.16, blue: 0.14)
}

extension Font {
    static func doodleTitle(_ size: CGFloat) -> Font {
        .custom("Noteworthy-Bold", size: size, relativeTo: .title)
    }

    static func doodleBody(_ size: CGFloat) -> Font {
        .custom("Noteworthy", size: size, relativeTo: .body)
    }
}
