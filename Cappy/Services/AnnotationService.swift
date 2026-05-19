import AppKit

@MainActor
final class AnnotationService: ObservableObject {
    @Published var annotations: [Annotation] = []
    @Published var selectedTool: AnnotationType = .arrow
    @Published var selectedColor: AnnotationColor = .red
    @Published var selectedLineWidth: CGFloat = 3

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private let maxUndo = 20

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func pushState() {
        undoStack.append(annotations)
        if undoStack.count > maxUndo { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func addAnnotation(_ annotation: Annotation) {
        pushState()
        annotations.append(annotation)
    }

    func moveAnnotation(id: UUID, by delta: CGPoint) {
        guard let idx = annotations.firstIndex(where: { $0.id == id }) else { return }
        pushState()
        annotations[idx].origin.x += delta.x
        annotations[idx].origin.y += delta.y
        if var ep = annotations[idx].endPoint {
            ep.x += delta.x
            ep.y += delta.y
            annotations[idx].endPoint = ep
        }
    }

    func removeAnnotation(id: UUID) {
        pushState()
        annotations.removeAll { $0.id == id }
    }

    func undo() {
        guard canUndo else { return }
        redoStack.append(annotations)
        annotations = undoStack.removeLast()
    }

    func redo() {
        guard canRedo else { return }
        undoStack.append(annotations)
        annotations = redoStack.removeLast()
    }

    func commitToImage(baseImage: CGImage) -> CGImage? {
        let width = baseImage.width
        let height = baseImage.height
        let imageSize = CGSize(width: CGFloat(width), height: CGFloat(height))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(baseImage, in: CGRect(origin: .zero, size: imageSize))

        for annotation in annotations {
            drawAnnotation(annotation, in: context)
        }

        return context.makeImage()
    }

    private func drawAnnotation(_ annotation: Annotation, in context: CGContext) {
        context.setStrokeColor(annotation.color.cgColor)
        context.setFillColor(annotation.color.cgColor)
        context.setLineWidth(annotation.lineWidth)

        switch annotation.type {
        case .arrow:
            guard let end = annotation.endPoint else { return }
            let angle = atan2(end.y - annotation.origin.y, end.x - annotation.origin.x)
            let offset = annotation.lineWidth * 1.2
            let lineEnd = CGPoint(x: end.x - offset * cos(angle), y: end.y - offset * sin(angle))

            context.move(to: annotation.origin)
            context.addLine(to: lineEnd)
            context.strokePath()

            let arrowLength: CGFloat = max(10, annotation.lineWidth * 3)
            let arrowAngle: CGFloat = .pi / 6
            let p1 = CGPoint(x: end.x - arrowLength * cos(angle - arrowAngle),
                             y: end.y - arrowLength * sin(angle - arrowAngle))
            let p2 = CGPoint(x: end.x - arrowLength * cos(angle + arrowAngle),
                             y: end.y - arrowLength * sin(angle + arrowAngle))
            context.move(to: end)
            context.addLine(to: p1)
            context.move(to: end)
            context.addLine(to: p2)
            context.strokePath()

        case .rectangle:
            context.stroke(CGRect(origin: annotation.origin, size: annotation.size))

        case .circle:
            context.strokeEllipse(in: CGRect(origin: annotation.origin, size: annotation.size))

        case .text:
            guard let text = annotation.text else { return }
            let nsText = text as NSString
            let font = NSFont.systemFont(ofSize: 24)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: annotation.color.nsColor
            ]
            nsText.draw(at: annotation.origin, withAttributes: attrs)
        }
    }
}
