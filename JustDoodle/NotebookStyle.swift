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

struct HandCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.addCurve(to: CGPoint(x: rect.maxX - 2, y: rect.midY),
            control1: CGPoint(x: rect.maxX * 0.83, y: rect.minY - 1),
            control2: CGPoint(x: rect.maxX + 1, y: rect.height * 0.23))
        path.addCurve(to: CGPoint(x: rect.midX - 2, y: rect.maxY - 2),
            control1: CGPoint(x: rect.maxX - 1, y: rect.height * 0.81),
            control2: CGPoint(x: rect.width * 0.77, y: rect.maxY + 1))
        path.addCurve(to: CGPoint(x: rect.minX + 2, y: rect.midY - 2),
            control1: CGPoint(x: rect.width * 0.20, y: rect.maxY),
            control2: CGPoint(x: rect.minX - 1, y: rect.height * 0.78))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + 2),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.25, y: rect.minY + 1))
        path.closeSubpath()
        return path
    }
}

struct SketchWindowOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 3, y: 27))
        path.addQuadCurve(to: CGPoint(x: 27, y: 3), control: CGPoint(x: 2, y: 3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 24, y: 5), control: CGPoint(x: rect.midX, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 4, y: 27), control: CGPoint(x: rect.maxX - 3, y: 4))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 5))
        path.addQuadCurve(to: CGPoint(x: 5, y: rect.maxY - 3), control: CGPoint(x: rect.midX, y: rect.maxY - 1))
        path.closeSubpath()
        // A second short pen pass keeps the frame deliberately imperfect.
        path.move(to: CGPoint(x: 9, y: 72))
        path.addLine(to: CGPoint(x: 10, y: rect.maxY - 17))
        path.move(to: CGPoint(x: 22, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.maxX * 0.52, y: rect.maxY - 9))
        return path
    }
}

struct InkWindow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NotebookColors.paper)
            .clipped()
            .overlay {
                SketchWindowOutline()
                    .stroke(Ink.black, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

struct InkDivider: View {
    var body: some View {
        HandUnderline().stroke(Ink.black, lineWidth: 1.5)
            .frame(height: 4).accessibilityHidden(true)
    }
}

struct InkPageHeader: View {
    let title: String
    var symbol: String = "chevron.left"
    var backLabel: String = "Back to home"
    let back: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            IconButton(systemName: symbol, label: backLabel, action: back)
            Text(title).font(.doodleTitle(24)).lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Ink.black)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 6)
        .overlay(alignment: .bottom) { InkDivider() }
    }
}

struct InkSectionTitle: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.doodleTitle(21)).foregroundStyle(Ink.black)
            .padding(.vertical, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

struct InkArrival: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(arrived ? 1 : 0)
            .offset(y: arrived || reduceMotion ? 0 : 10)
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85).delay(delay)) {
                    arrived = true
                }
            }
    }
}

extension Font {
    static func doodleTitle(_ size: CGFloat) -> Font {
        .custom("Noteworthy-Bold", size: size, relativeTo: .title)
    }

    static func doodleBody(_ size: CGFloat) -> Font {
        .custom("Noteworthy", size: size, relativeTo: .body)
    }
}
