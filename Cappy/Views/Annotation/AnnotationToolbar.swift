import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var service: AnnotationService

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AnnotationType.allCases, id: \.self) { tool in
                toolButton(for: tool)
            }

            Divider().frame(height: 24)

            ForEach(AnnotationColor.allCases, id: \.self) { color in
                colorButton(for: color)
            }

            Divider().frame(height: 24)

            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
                Slider(value: Binding(
                    get: { Double(service.selectedLineWidth) },
                    set: { service.selectedLineWidth = CGFloat($0) }
                ), in: 1...8, step: 1)
                .frame(width: 60)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func toolButton(for tool: AnnotationType) -> some View {
        Button {
            service.selectedTool = tool
        } label: {
            Image(systemName: iconName(for: tool))
                .font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 28)
        }
        .buttonStyle(.plain)
        .background(service.selectedTool == tool ? Color.accentColor.opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .help(toolName(for: tool))
    }

    private func colorButton(for color: AnnotationColor) -> some View {
        Button {
            service.selectedColor = color
        } label: {
            Circle()
                .fill(swiftUIColor(for: color))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(service.selectedColor == color ? Color.primary : .clear, lineWidth: 2)
                        .frame(width: 22, height: 22)
                )
        }
        .buttonStyle(.plain)
        .help(colorName(for: color))
    }

    private func iconName(for tool: AnnotationType) -> String {
        switch tool {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .text: return "character.textbox"
        }
    }

    private func toolName(for tool: AnnotationType) -> String {
        switch tool {
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .text: return "Text"
        }
    }

    private func colorName(for color: AnnotationColor) -> String {
        color.rawValue.capitalized
    }

    private func swiftUIColor(for color: AnnotationColor) -> Color {
        switch color {
        case .red: return .red
        case .yellow: return .yellow
        case .blue: return .blue
        case .green: return .green
        case .white: return .white
        case .black: return .black
        }
    }
}
