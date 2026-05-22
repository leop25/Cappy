import SwiftUI

struct AnnotationCanvas: View {
    @ObservedObject var service: AnnotationService
    let image: CGImage

    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var isDragging: Bool = false
    @State private var textInput: String = ""
    @State private var textPosition: CGPoint?
    @State private var pendingTextOrigin: CGPoint?
    @State private var showTextInput: Bool = false
    @State private var movingAnnotationID: UUID?
    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            annotationSurface(layout: imageLayout(for: proxy.size))
        }
    }

    private func annotationSurface(layout: ImageAnnotationLayout) -> some View {
        ZStack {
            Color(nsColor: .underPageBackgroundColor)
            annotationCanvas(layout: layout)
            textInputPopover
        }
    }

    private func annotationCanvas(layout: ImageAnnotationLayout) -> some View {
        Canvas { context, size in
            let layout = imageLayout(for: size)
            let fittedRect = layout.imageRect
            let imagePath = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: fittedRect)

            context.fill(imagePath, with: .color(.black.opacity(0.08)))
            context.draw(Image(decorative: image, scale: 1.0), in: fittedRect)
            context.stroke(imagePath, with: .color(.white.opacity(0.32)), lineWidth: 0.5)

            for annotation in service.annotations {
                let viewAnnotation = layout.annotationToView(annotation)
                let color = swiftUIColor(for: annotation.color)
                if annotation.type == .text, let text = annotation.text {
                    context.draw(
                        Text(text).foregroundColor(color).font(.system(size: viewAnnotation.fontSize)),
                        at: viewAnnotation.origin,
                        anchor: .topLeading
                    )
                } else {
                    drawAnnotation(viewAnnotation, in: context, color: color)
                }
            }

            if isDragging, let start = dragStart, let current = dragCurrent, movingAnnotationID == nil {
                drawPreview(from: layout.viewPoint(for: start), to: layout.viewPoint(for: current), in: context)
            }
        }
        .gesture(annotationDragGesture(layout: layout))
    }

    private func annotationDragGesture(layout: ImageAnnotationLayout) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !isDragging {
                    guard let start = layout.imagePoint(for: value.startLocation) else { return }
                    dragStart = start
                    isDragging = true
                    lastTranslation = .zero
                    if let id = findAnnotation(near: start, threshold: 20 / layout.scale) {
                        movingAnnotationID = id
                    }
                }
                dragCurrent = layout.clampedImagePoint(for: value.location)

                if let id = movingAnnotationID {
                    let delta = CGPoint(
                        x: (value.translation.width - lastTranslation.width) / layout.scale,
                        y: (value.translation.height - lastTranslation.height) / layout.scale
                    )
                    service.moveAnnotation(id: id, by: delta)
                    lastTranslation = value.translation
                }
            }
            .onEnded { value in
                finishDrag(value, layout: layout)
            }
    }

    @ViewBuilder
    private var textInputPopover: some View {
        if showTextInput {
            VStack(alignment: .leading, spacing: 10) {
                Text("Text")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Type here", text: $textInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)

                HStack(spacing: 8) {
                    Button("Cancel") { cancelTextInput() }
                    Spacer()
                    Button("Add") { commitText() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 10)
            .position(textPosition ?? .zero)
        }
    }

    private func imageLayout(for size: CGSize) -> ImageAnnotationLayout {
        let imageSize = CGSize(width: CGFloat(image.width), height: CGFloat(image.height))
        let drawingRect = CGRect(origin: .zero, size: size).insetBy(dx: 28, dy: 28)
        return ImageAnnotationLayout(imageSize: imageSize, container: drawingRect)
    }

    private func findAnnotation(near point: CGPoint, threshold: CGFloat) -> UUID? {
        for annotation in service.annotations.reversed() {
            if isPoint(point, nearAnnotation: annotation, threshold: threshold) {
                return annotation.id
            }
        }
        return nil
    }

    private func isPoint(_ point: CGPoint, nearAnnotation annotation: Annotation, threshold: CGFloat) -> Bool {
        switch annotation.type {
        case .arrow:
            guard let end = annotation.endPoint else { return false }
            return distanceToLine(point: point, lineStart: annotation.origin, lineEnd: end) < threshold
        default:
            let rect = annotation.boundsRect().insetBy(dx: -8, dy: -8)
            return rect.contains(point)
        }
    }

    private func distanceToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else { return distance(point, lineStart) }
        var t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lenSq
        t = max(0, min(1, t))
        let proj = CGPoint(x: lineStart.x + t * dx, y: lineStart.y + t * dy)
        return distance(point, proj)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }

    private func finishDrag(_ value: DragGesture.Value, layout: ImageAnnotationLayout) {
        isDragging = false

        if movingAnnotationID != nil {
            movingAnnotationID = nil
            lastTranslation = .zero
            dragStart = nil
            dragCurrent = nil
            return
        }

        guard let start = dragStart else { return }
        let end = layout.clampedImagePoint(for: value.location)

        if service.selectedTool == .text {
            pendingTextOrigin = end
            textPosition = layout.viewPoint(for: end)
            textInput = ""
            showTextInput = true
            dragStart = nil
            dragCurrent = nil
            return
        }

        let rect = makeRect(from: start, to: end)
        if service.selectedTool == .arrow, distance(start, end) < 5 {
            dragStart = nil
            dragCurrent = nil
            return
        }
        if service.selectedTool != .arrow, (rect.width < 2 || rect.height < 2) {
            dragStart = nil
            dragCurrent = nil
            return
        }

        let annotation = Annotation(
            type: service.selectedTool,
            origin: service.selectedTool == .arrow ? start : rect.origin,
            size: rect.size,
            endPoint: service.selectedTool == .arrow ? end : nil,
            color: service.selectedColor,
            lineWidth: service.selectedLineWidth / layout.scale,
            text: nil,
            zIndex: service.annotations.count
        )
        service.addAnnotation(annotation)
        dragStart = nil
        dragCurrent = nil
    }

    private func cancelTextInput() {
        showTextInput = false
        textInput = ""
        textPosition = nil
        pendingTextOrigin = nil
    }

    private func commitText() {
        showTextInput = false
        guard let pos = pendingTextOrigin, !textInput.isEmpty else { return }
        let annotation = Annotation(
            type: .text, origin: pos, size: .zero, endPoint: nil,
            color: service.selectedColor, lineWidth: service.selectedLineWidth,
            fontSize: 24,
            text: textInput, zIndex: service.annotations.count
        )
        service.addAnnotation(annotation)
        textInput = ""
        textPosition = nil
        pendingTextOrigin = nil
    }

    private func makeRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let w = abs(end.x - start.x)
        let h = abs(end.y - start.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func drawAnnotation(_ annotation: Annotation, in context: GraphicsContext, color: Color) {
        let lw = annotation.lineWidth
        switch annotation.type {
        case .arrow:
            guard let end = annotation.endPoint else { return }
            let angle = atan2(end.y - annotation.origin.y, end.x - annotation.origin.x)
            let offset = lw * 1.2
            let lineEnd = CGPoint(x: end.x - offset * cos(angle), y: end.y - offset * sin(angle))

            var path = Path()
            path.move(to: annotation.origin)
            path.addLine(to: lineEnd)
            context.stroke(path, with: .color(color), lineWidth: lw)

            let len: CGFloat = max(10, lw * 3)
            let a: CGFloat = .pi / 6
            let p1 = CGPoint(x: end.x - len * cos(angle - a), y: end.y - len * sin(angle - a))
            let p2 = CGPoint(x: end.x - len * cos(angle + a), y: end.y - len * sin(angle + a))
            var head = Path()
            head.move(to: end); head.addLine(to: p1); head.addLine(to: p2); head.closeSubpath()
            context.fill(head, with: .color(color))

        case .rectangle:
            context.stroke(Path(CGRect(origin: annotation.origin, size: annotation.size)), with: .color(color), lineWidth: lw)

        case .circle:
            context.stroke(Path(ellipseIn: CGRect(origin: annotation.origin, size: annotation.size)), with: .color(color), lineWidth: lw)

        case .text: break
        }
    }

    private func drawPreview(from start: CGPoint, to current: CGPoint, in context: GraphicsContext) {
        let color = swiftUIColor(for: service.selectedColor).opacity(0.5)
        let lw = service.selectedLineWidth
        if service.selectedTool == .arrow {
            var path = Path(); path.move(to: start); path.addLine(to: current)
            context.stroke(path, with: .color(color), lineWidth: lw)
        } else {
            let rect = makeRect(from: start, to: current)
            let path: Path = service.selectedTool == .circle ? Path(ellipseIn: rect) : Path(rect)
            context.stroke(path, with: .color(color), lineWidth: lw)
        }
    }

    private func swiftUIColor(for c: AnnotationColor) -> Color {
        switch c {
        case .red: .red; case .yellow: .yellow; case .blue: .blue
        case .green: .green; case .white: .white; case .black: .black
        }
    }
}

private struct ImageAnnotationLayout {
    let imageSize: CGSize
    let imageRect: CGRect
    let scale: CGFloat

    init(imageSize: CGSize, container: CGRect) {
        self.imageSize = imageSize
        guard imageSize.width > 0, imageSize.height > 0 else {
            imageRect = container
            scale = 1
            return
        }

        scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        imageRect = CGRect(
            x: container.minX + (container.width - width) / 2,
            y: container.minY + (container.height - height) / 2,
            width: width,
            height: height
        )
    }

    func imagePoint(for viewPoint: CGPoint) -> CGPoint? {
        guard imageRect.contains(viewPoint), scale > 0 else { return nil }
        return CGPoint(
            x: (viewPoint.x - imageRect.minX) / scale,
            y: (viewPoint.y - imageRect.minY) / scale
        )
    }

    func clampedImagePoint(for viewPoint: CGPoint) -> CGPoint {
        guard scale > 0 else { return .zero }
        let x = min(max(viewPoint.x, imageRect.minX), imageRect.maxX)
        let y = min(max(viewPoint.y, imageRect.minY), imageRect.maxY)
        return CGPoint(x: (x - imageRect.minX) / scale, y: (y - imageRect.minY) / scale)
    }

    func viewPoint(for imagePoint: CGPoint) -> CGPoint {
        CGPoint(
            x: imageRect.minX + imagePoint.x * scale,
            y: imageRect.minY + imagePoint.y * scale
        )
    }

    func viewSize(for imageSize: CGSize) -> CGSize {
        CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    func annotationToView(_ annotation: Annotation) -> Annotation {
        var converted = annotation
        converted.origin = viewPoint(for: annotation.origin)
        converted.size = viewSize(for: annotation.size)
        if let endPoint = annotation.endPoint {
            converted.endPoint = viewPoint(for: endPoint)
        }
        converted.lineWidth = annotation.lineWidth * scale
        converted.fontSize = annotation.fontSize * scale
        return converted
    }
}
