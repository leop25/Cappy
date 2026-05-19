import SwiftUI
import AppKit

enum OverlayMode {
    case region
    case windowPicker
}

class DimOverlay {
    private var window: NSWindow?
    private var hostingView: NSHostingView<DimOverlayContent>?
    private var onComplete: ((CGRect?) -> Void)?
    private var onWindowPicked: ((CGWindowID?) -> Void)?
    private var screen: NSScreen?
    private var localMonitor: Any?
    private var cancelAction: (() -> Void)?

    func showForRegion(
        on screen: NSScreen,
        onFullScreen: @escaping () -> Void,
        onWindowCapture: @escaping () -> Void,
        onComplete: @escaping (CGRect?) -> Void
    ) {
        show(mode: .region, screen: screen, onComplete: onComplete, onWindowPicked: nil, onFullScreen: onFullScreen, onWindowCapture: onWindowCapture)
    }

    func showForWindow(
        on screen: NSScreen,
        onComplete: @escaping (CGRect?) -> Void,
        onWindowPicked: @escaping (CGWindowID?) -> Void
    ) {
        show(mode: .windowPicker, screen: screen, onComplete: onComplete, onWindowPicked: onWindowPicked, onFullScreen: {}, onWindowCapture: {})
    }

    private func show(
        mode: OverlayMode,
        screen: NSScreen,
        onComplete: @escaping (CGRect?) -> Void,
        onWindowPicked: ((CGWindowID?) -> Void)?,
        onFullScreen: @escaping () -> Void,
        onWindowCapture: @escaping () -> Void
    ) {
        self.screen = screen
        self.onComplete = onComplete
        self.onWindowPicked = onWindowPicked

        let screenRect = screen.frame
        let viewModel = OverlayViewModel()
        viewModel.mode = mode

        window = NSWindow(contentRect: screenRect,
                          styleMask: .borderless,
                          backing: .buffered,
                          defer: false)
        window?.level = .screenSaver
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        let content = DimOverlayContent(
            viewModel: viewModel,
            screen: screen,
            screenRect: screenRect,
            onCancel: { [weak self] in
                if mode == .windowPicker {
                    self?.completeWindow(windowID: nil)
                } else {
                    self?.complete(rect: nil)
                }
            },
            onSelectRegion: { [weak self] in
                guard let self else { return }
                let flipped = self.flipY(viewModel.selectionRect, screenHeight: screenRect.height)
                self.complete(rect: flipped)
            },
            onFullScreen: { [weak self] in
                self?.completeAndTrigger(action: onFullScreen)
            },
            onWindowCapture: { [weak self] in
                self?.completeAndTrigger(action: onWindowCapture)
            },
            onWindowPicked: { [weak self] windowID in
                self?.completeWindow(windowID: windowID)
            }
        )

        hostingView = NSHostingView(rootView: content)
        hostingView?.autoresizingMask = [.width, .height]
        window?.contentView = hostingView
        hostingView?.frame = window?.contentView?.bounds ?? screenRect
        window?.makeKeyAndOrderFront(nil)

        cancelAction = {
            if mode == .windowPicker { self.completeWindow(windowID: nil) }
            else { self.complete(rect: nil) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.cancelAction?(); return nil }
            return event
        }

        NSCursor.crosshair.push()
    }

    private func complete(rect: CGRect?) {
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor); localMonitor = nil }
        NSCursor.crosshair.pop()
        window?.orderOut(nil)
        window = nil
        hostingView = nil
        DispatchQueue.main.async {
            self.onComplete?(rect)
            self.onComplete = nil
        }
    }

    private func completeWindow(windowID: CGWindowID?) {
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor); localMonitor = nil }
        NSCursor.crosshair.pop()
        window?.orderOut(nil)
        window = nil
        hostingView = nil
        DispatchQueue.main.async {
            self.onWindowPicked?(windowID)
            self.onWindowPicked = nil
        }
    }

    private func completeAndTrigger(action: @escaping () -> Void) {
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor); localMonitor = nil }
        NSCursor.crosshair.pop()
        window?.orderOut(nil)
        window = nil
        hostingView = nil
        action()
    }

    private func flipY(_ rect: CGRect, screenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}

class OverlayViewModel: ObservableObject {
    @Published var selectionRect: CGRect = .zero
    @Published var mode: OverlayMode = .region
    @Published var hoveredWindowGlobalRect: CGRect = .zero
    @Published var hoveredWindowID: CGWindowID = 0
    @Published var hoveredWindowName: String = ""
}

struct DimOverlayContent: View {
    @ObservedObject var viewModel: OverlayViewModel
    let screen: NSScreen
    let screenRect: CGRect
    let onCancel: () -> Void
    let onSelectRegion: () -> Void
    let onFullScreen: () -> Void
    let onWindowCapture: () -> Void
    let onWindowPicked: (CGWindowID) -> Void

    @State private var startPoint: CGPoint?
    @State private var currentRect: CGRect = .zero
    @State private var tracking: Bool = false
    @State private var hoverTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                dimCanvas(size: geometry.size)

                VStack {
                    captureHint
                        .padding(.top, 34)
                    Spacer()
                }

                VStack {
                    Spacer()
                    if viewModel.mode == .windowPicker && !viewModel.hoveredWindowName.isEmpty {
                        Label(viewModel.hoveredWindowName, systemImage: "macwindow")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                            }
                            .padding(.bottom, 8)
                    }
                    CaptureToolbar(
                        onCaptureRegion: {},
                        onCaptureFullScreen: onFullScreen,
                        onCaptureWindow: onWindowCapture,
                        onCancel: onCancel
                    )
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard viewModel.mode == .region else { return }
                        if !tracking {
                            startPoint = value.startLocation
                            tracking = true
                        }
                        updateRect(start: startPoint ?? value.startLocation,
                                   current: value.location)
                    }
                    .onEnded { _ in
                        if viewModel.mode == .windowPicker {
                            if viewModel.hoveredWindowID != 0 {
                                onWindowPicked(viewModel.hoveredWindowID)
                            }
                            return
                        }
                        guard viewModel.mode == .region else { return }
                        tracking = false
                        if currentRect.width > 5 && currentRect.height > 5 {
                            viewModel.selectionRect = currentRect
                            onSelectRegion()
                        }
                        startPoint = nil
                    }
            )
            .onAppear {
                if viewModel.mode == .windowPicker {
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        DispatchQueue.main.async {
                            updateHoveredWindow()
                        }
                    }
                }
            }
            .onDisappear {
                hoverTimer?.invalidate()
                hoverTimer = nil
            }
        }
    }

    private var captureHint: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.mode == .region ? "plus.viewfinder" : "macwindow")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 14, weight: .semibold))

            Text(viewModel.mode == .region ? "Drag to capture a region" : "Click a window to capture it")
                .font(.system(size: 13, weight: .semibold))

            Text("Esc")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.22), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    private func updateRect(start: CGPoint, current: CGPoint) {
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let maxX = max(start.x, current.x)
        let maxY = max(start.y, current.y)
        currentRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func updateHoveredWindow() {
        let mouseLocation = NSEvent.mouseLocation
        let allWindows = CaptureService.enumerateWindows(for: screen)

        let desktopRect = NSScreen.screens.map { $0.frame }.reduce(CGRect.zero) { $0.union($1) }
        let flippedMouseY = desktopRect.maxY - mouseLocation.y
        let mouseInTopLeft = CGPoint(x: mouseLocation.x, y: flippedMouseY)

        var bestWindow: (rect: CGRect, id: CGWindowID, name: String, layer: Int)?
        let screenArea = screen.frame.width * screen.frame.height

        for dict in allWindows {
            guard let bounds = dict[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let w = bounds["Width"] as? CGFloat,
                  let h = bounds["Height"] as? CGFloat,
                  let windowID = dict[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            let globalRect = CGRect(x: x, y: y, width: w, height: h)
            guard globalRect.contains(mouseInTopLeft) else { continue }

            if w * h > screenArea * 0.95 { continue }

            let layer = dict[kCGWindowLayer as String] as? Int ?? 0
            let name = dict[kCGWindowOwnerName as String] as? String ?? ""

            if let current = bestWindow {
                if layer > current.layer { bestWindow = (globalRect, windowID, name, layer) }
            } else {
                bestWindow = (globalRect, windowID, name, layer)
            }
        }

        if let best = bestWindow {
            viewModel.hoveredWindowGlobalRect = best.rect
            viewModel.hoveredWindowID = best.id
            viewModel.hoveredWindowName = best.name
        } else {
            viewModel.hoveredWindowGlobalRect = .zero
            viewModel.hoveredWindowID = 0
            viewModel.hoveredWindowName = ""
        }
    }

    @ViewBuilder
    private func dimCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let fullRect = CGRect(origin: .zero, size: canvasSize)

            if viewModel.mode == .region {
                var path = Path(fullRect)
                path.addRect(currentRect)
                context.fill(path, with: .color(.black.opacity(0.45)), style: FillStyle(eoFill: true))

                if currentRect.width > 0 || currentRect.height > 0 {
                    let border = Path(currentRect)
                    context.stroke(border, with: .color(.white.opacity(0.92)), lineWidth: 1)
                    context.stroke(border, with: .color(.blue.opacity(0.82)), lineWidth: 2)

                    let handleSize: CGFloat = 9
                    for point in [
                        currentRect.origin,
                        CGPoint(x: currentRect.maxX, y: currentRect.minY),
                        CGPoint(x: currentRect.minX, y: currentRect.maxY),
                        CGPoint(x: currentRect.maxX, y: currentRect.maxY)
                    ] {
                        let handle = CGRect(
                            x: point.x - handleSize / 2,
                            y: point.y - handleSize / 2,
                            width: handleSize,
                            height: handleSize
                        )
                        context.fill(Path(ellipseIn: handle), with: .color(.white))
                        context.stroke(Path(ellipseIn: handle), with: .color(.blue), lineWidth: 1)
                    }
                }
            } else {
                context.fill(Path(fullRect), with: .color(.black.opacity(0.28)))

                let global = viewModel.hoveredWindowGlobalRect
                if !global.isEmpty && global.width > 0 {
                    let localRect = CGRect(
                        x: global.origin.x - screenRect.origin.x,
                        y: global.origin.y - screenRect.origin.y,
                        width: global.width,
                        height: global.height
                    )
                    let highlight = Path(localRect)
                    context.stroke(highlight, with: .color(.white.opacity(0.9)), lineWidth: 1)
                    context.stroke(highlight, with: .color(.blue.opacity(0.95)), lineWidth: 4)
                }
            }
        }
    }
}
