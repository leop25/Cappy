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
            header

            AnnotationCanvas(service: service, image: image)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .underPageBackgroundColor))

            footer
        }
        .frame(minWidth: 760, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
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

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.quaternary.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(fileURL.lastPathComponent)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(hasUnsavedChanges ? "Edited screenshot" : "Saved in Pictures/Cappy")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                iconButton("Undo", systemImage: "arrow.uturn.backward", action: {
                    service.undo()
                    markChanged()
                })
                .disabled(!service.canUndo)
                .keyboardShortcut("z", modifiers: [.command])

                iconButton("Redo", systemImage: "arrow.uturn.forward", action: {
                    service.redo()
                    markChanged()
                })
                .disabled(!service.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])

                Divider().frame(height: 24).padding(.horizontal, 4)

                iconButton("Copy", systemImage: "doc.on.doc", action: copyToClipboard)
                    .keyboardShortcut("c", modifiers: [.command, .shift])

                Button(action: save) {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.separator.opacity(0.55))
                .frame(height: 0.5)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            AnnotationToolbar(service: service)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 12, weight: .semibold))
                Text("Drag to draw. Drag an annotation to move it.")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.separator.opacity(0.55))
                .frame(height: 0.5)
        }
    }

    private func iconButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 28)
        }
        .buttonStyle(.plain)
        .background(.quaternary.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(title)
        .accessibilityLabel(title)
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

    private func copyToClipboard() {
        guard let annotated = service.commitToImage(baseImage: image) else { return }
        FileService.copyPNGToClipboard(image: annotated)
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
