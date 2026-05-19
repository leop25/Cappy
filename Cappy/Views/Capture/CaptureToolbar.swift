import SwiftUI

struct CaptureToolbar: View {
    let onCaptureRegion: () -> Void
    let onCaptureFullScreen: () -> Void
    let onCaptureWindow: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            toolbarButton(title: "Region", action: onCaptureRegion)
            toolbarButton(title: "Full Screen", action: onCaptureFullScreen)
            toolbarButton(title: "Window", action: onCaptureWindow)
            Divider().frame(height: 20)
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func toolbarButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(minWidth: 70)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        )
    }
}
