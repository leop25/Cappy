import SwiftUI
import AppKit

struct AnnotationEditor: View {
    @StateObject private var service = AnnotationService()
    let image: CGImage
    let fileURL: URL
    let onClose: () -> Void

    @State private var hasUnsavedChanges = false
    @State private var showCloseAlert = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AnnotationCanvas(service: service, image: image)
            }

            HStack {
                AnnotationToolbar(service: service)

                Spacer()

                HStack(spacing: 8) {
                    Button("Undo") { service.undo(); markChanged() }
                        .disabled(!service.canUndo)
                        .keyboardShortcut("z", modifiers: [.command])

                    Button("Redo") { service.redo(); markChanged() }
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
            NSApp.setActivationPolicy(.accessory)
            onClose()
        }
        .alert("Unsaved Changes", isPresented: $showCloseAlert) {
            Button("Save") { save(); closeWindow() }
            Button("Discard") { closeWindow() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved annotations. Save before closing?")
        }
        .onChange(of: service.annotations) { _, _ in markChanged() }
    }

    private func markChanged() {
        hasUnsavedChanges = true
    }

    private func save() {
        guard let annotated = service.commitToImage(baseImage: image) else { return }
        do {
            try FileService.overwritePNG(image: annotated, at: fileURL)
            hasUnsavedChanges = false
        } catch {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
