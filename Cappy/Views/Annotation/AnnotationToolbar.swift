import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var service: AnnotationService

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                ForEach(AnnotationType.allCases, id: \.self) { tool in
                    toolButton(for: tool)
                }
            }
            .padding(3)
            .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Divider().frame(height: 28)

            HStack(spacing: 7) {
                ForEach(AnnotationColor.allCases, id: \.self) { color in
                    colorButton(for: color)
                }
            }

            Divider().frame(height: 28)

            HStack(spacing: 8) {
                Image(systemName: "line.diagonal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Slider(value: Binding(
                    get: { Double(service.selectedLineWidth) },
                    set: { service.selectedLineWidth = CGFloat($0) }
                ), in: 1...10, step: 1)
                .frame(width: 92)

                Text("\(Int(service.selectedLineWidth)) pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 0.5)
        }
    }

    private func toolButton(for tool: AnnotationType) -> some View {
        let selected = service.selectedTool == tool

        return Button {
            service.selectedTool = tool
        } label: {
            Image(systemName: iconName(for: tool))
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 28)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? Color.accentColor : .primary)
        .background(selected ? Color.accentColor.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.28), lineWidth: 0.75)
            }
        }
        .help(toolName(for: tool))
        .accessibilityLabel(toolName(for: tool))
    }

    private func colorButton(for color: AnnotationColor) -> some View {
        let selected = service.selectedColor == color
        let fill = swiftUIColor(for: color)

        return Button {
            service.selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle()
                            .stroke(color == .white ? Color.black.opacity(0.18) : Color.white.opacity(0.25), lineWidth: 0.75)
                    }

                if selected {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
            .frame(width: 28, height: 28)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(colorName(for: color))
        .accessibilityLabel(colorName(for: color))
    }

    private func iconName(for tool: AnnotationType) -> String {
        switch tool {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .text: return "textformat"
        }
    }

    private func toolName(for tool: AnnotationType) -> String {
        switch tool {
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .circle: return "Oval"
        case .text: return "Text"
        }
    }

    private func colorName(for color: AnnotationColor) -> String {
        color.rawValue.capitalized
    }

    private func swiftUIColor(for color: AnnotationColor) -> Color {
        switch color {
        case .red: return Color(red: 1.0, green: 0.18, blue: 0.22)
        case .yellow: return Color(red: 1.0, green: 0.78, blue: 0.0)
        case .blue: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .green: return Color(red: 0.18, green: 0.78, blue: 0.36)
        case .white: return .white
        case .black: return .black
        }
    }
}
