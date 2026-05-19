import SwiftUI

struct AnnotationCanvas: View {
    @ObservedObject var service: AnnotationService
    let image: CGImage

    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var isDragging: Bool = false
    @State private var textInput: String = ""
    @State private var textPosition: CGPoint?
    @State private var showTextInput: Bool = false
    @State private var movingAnnotationID: UUID?
    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        ZStack {
            Color(nsColor: .underPageBackgroundColor)

            Canvas { context, size in
                let imageSize = CGSize(width: CGFloat(image.width), height: CGFloat(image.height))
                let drawingRect = CGRect(origin: .zero, size: size).insetBy(dx: 28, dy: 28)
                let fittedRect = fitRect(imageSize, in: drawingRect)
                let imagePath = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: fittedRect)

                context.fill(imagePath, with: .color(.black.opacity(0.08)))
                context.draw(Image(decorative: image, scale: 1.0), in: fittedRect)
                context.stroke(imagePath, with: .color(.white.opacity(0.32)), lineWidth: 0.5)

                for annotation in service.annotations {
                    let color = swiftUIColor(for: annotation.color)
                    if annotation.type == .text, let text = annotation.text {
                        context.draw(
                            Text(text).foregroundColor(color).font(.system(size: 18)),
                            at: annotation.origin,
                            anchor: .topLeading
                        )
                    } else {
                        drawAnnotation(annotation, in: context, color: color)
                    }
                }

                if isDragging, let start = dragStart, let current = dragCurrent, movingAnnotationID == nil {
                    drawPreview(from: start, to: current, in: context)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            dragStart = value.startLocation
                            isDragging = true
                            lastTranslation = .zero
                            if let id = findAnnotation(near: value.startLocation) {
                                movingAnnotationID = id
                            }
                        }
                        dragCurrent = value.location

                        if let id = movingAnnotationID {
                            let delta = CGPoint(
                                x: value.translation.width - lastTranslation.width,
                                y: value.translation.height - lastTranslation.height
                            )
                            service.moveAnnotation(id: id, by: delta)
                            lastTranslation = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false

                        if movingAnnotationID != nil {
                            movingAnnotationID = nil
                            lastTranslation = .zero
                            dragStart = nil
                            dragCurrent = nil
                            return
                        }

                        guard let start = dragStart else { return }
                        let end = value.location

                        if service.selectedTool == .text {
                            textPosition = value.location
                            textInput = ""
                            showTextInput = true
                            dragStart = nil
                            dragCurrent = nil
                            return
                        }

                        let rect = makeRect(from: start, to: end)
                        if service.selectedTool == .arrow, distance(start, end) < 5 {
                            dragStart = nil; dragCurrent = nil; return
                        }
                        if service.selectedTool != .arrow, (rect.width < 2 || rect.height < 2) {
                            dragStart = nil; dragCurrent = nil; return
                        }

                        let annotation = Annotation(
                            type: service.selectedTool,
                            origin: service.selectedTool == .arrow ? start : rect.origin,
                            size: rect.size,
                            endPoint: service.selectedTool == .arrow ? end : nil,
                            color: service.selectedColor,
                            lineWidth: service.selectedLineWidth,
                            text: nil,
                            zIndex: service.annotations.count
                        )
                        service.addAnnotation(annotation)
                        dragStart = nil
                        dragCurrent = nil
                    }
            )

            if showTextInput {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField("Type here", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)

                    HStack(spacing: 8) {
                        Button("Cancel") { showTextInput = false }
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
    }

    private func fitRect(_ contentSize: CGSize, in container: CGRect) -> CGRect {
        guard contentSize.width > 0, contentSize.height > 0 else { return container }
        let scale = min(container.width / contentSize.width, container.height / contentSize.height)
        let w = contentSize.width * scale
        let h = contentSize.height * scale
        return CGRect(
            x: container.minX + (container.width - w) / 2,
            y: container.minY + (container.height - h) / 2,
            width: w,
            height: h
        )
    }

    private func findAnnotation(near point: CGPoint, threshold: CGFloat = 20) -> UUID? {
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

    private func commitText() {
        showTextInput = false
        guard let pos = textPosition, !textInput.isEmpty else { return }
        let annotation = Annotation(
            type: .text, origin: pos, size: .zero, endPoint: nil,
            color: service.selectedColor, lineWidth: service.selectedLineWidth,
            text: textInput, zIndex: service.annotations.count
        )
        service.addAnnotation(annotation)
        textInput = ""
        textPosition = nil
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
