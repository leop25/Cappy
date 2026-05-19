import SwiftUI
import AppKit

struct AnnotationEditor: View {
    @StateObject private var service = AnnotationService()
    let image: CGImage
    let fileURL: URL
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hasUnsavedChanges = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AnnotationCanvas(service: service, image: image)
            }

            HStack {
                AnnotationToolbar(service: service)

                Spacer()

                HStack(spacing: 8) {
                    Button("Undo") { service.undo() }
                        .disabled(!service.canUndo)
                        .keyboardShortcut("z", modifiers: [.command])

                    Button("Redo") { service.redo() }
                        .disabled(!service.canRedo)
                        .keyboardShortcut("z", modifiers: [.command, .shift])

                    Divider().frame(height: 20)

                    Button("Save") { save() }
                        .keyboardShortcut("s", modifiers: [.command])
                        .buttonStyle(.borderedProminent)
                }
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            if hasUnsavedChanges {
                save()
            }
            NSApp.setActivationPolicy(.accessory)
            onClose()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            if hasUnsavedChanges { save() }
        }
    }

    private func save() {
        guard let annotated = service.commitToImage(baseImage: image) else { return }
        do {
            try FileService.overwritePNG(image: annotated, at: fileURL)
            hasUnsavedChanges = false
        } catch {
            print("[Cappy] Annotation save failed: \(error)")
        }
    }
}
