import SwiftUI
import AppKit

@main
struct CappyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Cappy", systemImage: "camera.viewfinder") {
            Button("Capture Region") { appState.startRegionCapture() }
                .keyboardShortcut("5", modifiers: [.command, .shift])
            Button("Capture Full Screen") { appState.startFullScreenCapture() }
                .keyboardShortcut("6", modifiers: [.command, .shift])
            Button("Capture Window") { appState.startWindowCapture() }
                .keyboardShortcut("7", modifiers: [.command, .shift])
            Divider()
            Button("Open Screenshots Folder") { appState.openScreenshotsFolder() }
            Divider()
            Button("Quit Cappy") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: [.command])
        }

        WindowGroup("Thumbnail", id: "thumbnail") {
            if let image = appState.thumbnailImage {
                ThumbnailView(
                    image: image,
                    onClick: { appState.openAnnotationEditor() },
                    onDismiss: { appState.dismissThumbnail() }
                )
                .frame(width: 200, height: 160)
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var thumbnailImage: CGImage?
    private var dimOverlay: DimOverlay?
    private var globalMonitor: Any?

    init() {
        registerGlobalShortcuts()
        requestAccessibilityPermission()
    }

    private var currentScreen: NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main ?? NSScreen.screens[0]
    }

    // MARK: - Capture Modes

    func startRegionCapture() {
        let screen = currentScreen
        dimOverlay = DimOverlay()
        dimOverlay?.showForRegion(
            on: screen,
            onFullScreen: { [weak self] in self?.startFullScreenCapture() },
            onWindowCapture: { [weak self] in self?.startWindowCapture() }
        ) { [weak self] rect in
            guard let self, let rect else { return }
            self.captureRegion(rect: rect, screen: screen)
        }
    }

    func startFullScreenCapture() {
        let screens = NSScreen.screens
        let capture = Capture(mode: .fullScreen, sourceRect: nil, sourceWindowID: nil)

        var firstImage: CGImage?
        var captureCount = 0

        for (index, screen) in screens.enumerated() {
            let image: CGImage?
            if let displayCapture = CaptureService.captureDisplay(screen.displayID) {
                image = displayCapture
            } else {
                image = CaptureService.captureDesktop(screen.frame)
            }

            guard let cgImage = image else {
                print("[Cappy] FullScreen: display \(screen.displayID) capture returned nil")
                continue
            }
            captureCount += 1
            if index == 0 { firstImage = cgImage }

            let suffix = screens.count > 1 ? "Display\(index + 1)" : ""
            let filename = capture.timestampFilename(suffix: suffix)

            do {
                let fileURL = try FileService.savePNG(image: cgImage, filename: filename)
                print("[Cappy] Saved: \(fileURL.path)")
            } catch {
                print("[Cappy] Save failed (\(suffix)): \(error.localizedDescription)")
            }
        }

        if let firstImage {
            thumbnailImage = firstImage
        } else if captureCount == 0 {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Capture Failed"
                alert.informativeText = "Could not capture the display."
                alert.runModal()
            }
        }
    }

    func startWindowCapture() {
        let screen = currentScreen
        dimOverlay = DimOverlay()
        dimOverlay?.showForWindow(on: screen) { _ in
            // Region callback not used in window mode
        } onWindowPicked: { [weak self] windowID in
            guard let self, let windowID else { return }
            self.captureWindow(windowID: windowID)
        }
    }

    // MARK: - Pipeline

    private func captureRegion(rect: CGRect, screen: NSScreen) {
        let scale = screen.backingScaleFactor
        let displayID = screen.displayID

        guard let image = CaptureService.captureRegion(
            rect: rect,
            screenHeight: screen.frame.height,
            scale: scale,
            displayID: displayID
        ) else { return }

        saveAndShow(cgImage: image)
    }

    private func captureWindow(windowID: CGWindowID) {
        guard let image = CaptureService.captureWindow(windowID: windowID) else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Capture Failed"
                alert.informativeText = "Could not capture the selected window."
                alert.runModal()
            }
            return
        }
        saveAndShow(cgImage: image)
    }

    private func saveAndShow(cgImage: CGImage) {
        let filename = ImageExtensions.timestampFilename()
        do {
            let fileURL = try FileService.savePNG(image: cgImage, filename: filename)
            print("[Cappy] Saved: \(fileURL.path)")
        } catch {
            print("[Cappy] Save failed: \(error.localizedDescription)")
        }
        thumbnailImage = cgImage
    }

    func dismissThumbnail() {
        thumbnailImage = nil
    }

    func openAnnotationEditor() {
        print("[Cappy] Annotation editor placeholder")
    }

    func openScreenshotsFolder() {
        NSWorkspace.shared.open(FileService.saveDirectory)
    }

    // MARK: - Global Shortcuts

    private func registerGlobalShortcuts() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift] else {
            return
        }
        switch event.keyCode {
        case 23: startRegionCapture()  // 5
        case 22: startFullScreenCapture()  // 6
        case 26: startWindowCapture()  // 7
        default: break
        }
    }

    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        guard !AXIsProcessTrustedWithOptions(options) else { return }
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = "Cappy needs Accessibility access to detect global keyboard shortcuts. Please enable it in System Preferences."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as! CGDirectDisplayID
    }
}
