import SwiftUI
import AppKit
import Carbon.HIToolbox

private var globalShortcutHandler: ((UInt32) -> Void)?

@main
struct CappyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Cappy", systemImage: "camera.viewfinder") {
            MenuBarView(appState: appState)
        }

        WindowGroup("Thumbnail", id: "thumbnail") {}  // unused — thumbnail is NSWindow-based
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var thumbnailImage: CGImage?
    private var lastCaptureImage: CGImage?
    private var lastCaptureURL: URL?
    private var dimOverlay: DimOverlay?
    private var globalMonitor: Any?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var hotKeyEventHandler: EventHandlerRef?
    private var editorWindow: NSWindow?

    init() {
        registerGlobalShortcuts()
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
                if index == 0 {
                    lastCaptureURL = fileURL
                    lastCaptureImage = cgImage
                }
            } catch {
                print("[Cappy] Save failed (\(suffix)): \(error.localizedDescription)")
            }
        }

        if let firstImage {
            showThumbnail(cgImage: firstImage)
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
            lastCaptureURL = fileURL
            lastCaptureImage = cgImage
        } catch {
            print("[Cappy] Save failed: \(error.localizedDescription)")
            showSaveFailure(error)
            return
        }
        showThumbnail(cgImage: cgImage)
    }

    private func showSaveFailure(_ error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private var thumbnailWindow: NSWindow?

    private func showThumbnail(cgImage: CGImage) {
        thumbnailWindow?.close()

        let thumbView = ThumbnailView(
            image: cgImage,
            onClick: { [weak self] in self?.openAnnotationEditor() },
            onDismiss: { [weak self] in self?.thumbnailWindow?.close() }
        )
        .frame(width: 240, height: 202)

        let hostingView = NSHostingView(rootView: thumbView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: 202)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 202),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hostingView
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let origin = NSPoint(
            x: screenFrame.maxX - 260,
            y: screenFrame.minY + 20
        )
        window.setFrameOrigin(origin)
        window.makeKeyAndOrderFront(nil)

        thumbnailWindow = window
    }

    func dismissThumbnail() {
        thumbnailWindow?.close()
        thumbnailWindow = nil
        thumbnailImage = nil
    }

    func openAnnotationEditor() {
        guard let image = lastCaptureImage, let fileURL = lastCaptureURL else { return }

        let contentView = AnnotationEditor(
            image: image,
            fileURL: fileURL,
            onClose: { [weak self] in
                self?.editorWindow = nil
            }
        )
        .frame(minWidth: 760, minHeight: 520)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 920, height: 680)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 680),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cappy"
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        editorWindow = window
    }

    func openScreenshotsFolder() {
        NSWorkspace.shared.open(FileService.saveDirectory)
    }

    // MARK: - Global Shortcuts

    private func registerGlobalShortcuts() {
        globalShortcutHandler = { [weak self] id in
            Task { @MainActor in
                self?.handleGlobalShortcut(id)
            }
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }

                DispatchQueue.main.async {
                    globalShortcutHandler?(hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &hotKeyEventHandler
        )

        guard handlerStatus == noErr else {
            print("[Cappy] Failed to install hotkey handler: \(handlerStatus)")
            return
        }

        registerHotKey(id: 1, keyCode: UInt32(kVK_ANSI_5), label: "Capture Region")
        registerHotKey(id: 2, keyCode: UInt32(kVK_ANSI_6), label: "Capture Full Screen")
        registerHotKey(id: 3, keyCode: UInt32(kVK_ANSI_7), label: "Capture Window")
    }

    private func registerHotKey(id: UInt32, keyCode: UInt32, label: String) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CAPY"), id: id)
        let status = RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
        } else {
            print("[Cappy] Failed to register \(label) hotkey: \(status)")
        }
    }

    private func handleGlobalShortcut(_ id: UInt32) {
        switch id {
        case 1: startRegionCapture()
        case 2: startFullScreenCapture()
        case 3: startWindowCapture()
        default: break
        }
    }

    private func fourCharCode(_ string: String) -> OSType {
        var result: OSType = 0
        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
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
