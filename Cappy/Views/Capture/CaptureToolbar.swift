import SwiftUI

struct CaptureToolbar: View {
    let onCaptureRegion: () -> Void
    let onCaptureFullScreen: () -> Void
    let onCaptureWindow: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            toolbarButton(title: "Region", systemImage: "selection.pin.in.out", action: onCaptureRegion)
            toolbarButton(title: "Screen", systemImage: "rectangle.inset.filled", action: onCaptureFullScreen)
            toolbarButton(title: "Window", systemImage: "macwindow", action: onCaptureWindow)

            Rectangle()
                .fill(.separator.opacity(0.65))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 4)

            Button(action: onCancel) {
                Label("Cancel", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .help("Cancel")
            .accessibilityLabel("Cancel")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(0.16), radius: 4, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 0.5)
        }
    }

    private func toolbarButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .frame(minWidth: 82, minHeight: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .background(.quaternary.opacity(0.75), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 0.5)
        }
        .help(title)
    }
}
