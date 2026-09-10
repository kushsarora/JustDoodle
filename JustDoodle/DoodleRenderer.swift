import PencilKit
import UIKit

@MainActor
enum DoodleRenderer {
    static let exportWidth: CGFloat = 1200
    static let headerHeight: CGFloat = 160

    static func render(_ draft: DoodleDraft) throws -> UIImage {
        let drawing = try PKDrawing(data: draft.drawingData)
        let scale = exportWidth / DrawingPage.size.width
        let size = CGSize(width: exportWidth, height: headerHeight + DrawingPage.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            context.setFillColor(NotebookColors.uiPaper.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            let titleFont = UIFont(name: "Noteworthy-Bold", size: 48) ?? .boldSystemFont(ofSize: 48)
            ("Just Doodle." as NSString).draw(in: CGRect(x: 48, y: 16, width: 1104, height: 66),
                withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
            let detailFont = UIFont(name: "Noteworthy", size: 28) ?? .systemFont(ofSize: 28)
            let elapsed = draft.clock.finishedElapsed ?? 0
            let detail = "\(draft.session.title)  |  \(DoodleTime.string(elapsed))  |  No erasing"
            (detail as NSString).draw(in: CGRect(x: 48, y: 88, width: 1104, height: 48),
                withAttributes: [.font: detailFont, .foregroundColor: UIColor.darkGray])
            context.saveGState()
            context.translateBy(x: 0, y: headerHeight)
            context.scaleBy(x: scale, y: scale)
            context.clip(to: CGRect(origin: .zero, size: DrawingPage.size))
            NotebookRenderer.drawBackground(in: context, size: DrawingPage.size, scale: 1)
            ScribbleRenderer.draw(draft.scribble, in: context)
            drawing.image(from: CGRect(origin: .zero, size: DrawingPage.size), scale: scale)
                .draw(in: CGRect(origin: .zero, size: DrawingPage.size))
            context.restoreGState()
        }
    }
}
