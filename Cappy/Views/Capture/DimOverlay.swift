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

        NSCursor.crosshair.push()
    }

    private func complete(rect: CGRect?) {
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
                    Spacer()
                    if viewModel.mode == .windowPicker && !viewModel.hoveredWindowName.isEmpty {
                        Text(viewModel.hoveredWindowName)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak viewModel] _ in
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
                    context.stroke(border, with: .color(.white.opacity(0.8)), lineWidth: 0.5)
                }
            } else {
                context.fill(Path(fullRect), with: .color(.black.opacity(0.2)))

                let global = viewModel.hoveredWindowGlobalRect
                if !global.isEmpty && global.width > 0 {
                    let localRect = CGRect(
                        x: global.origin.x - screenRect.origin.x,
                        y: global.origin.y - screenRect.origin.y,
                        width: global.width,
                        height: global.height
                    )
                    let highlight = Path(localRect)
                    context.stroke(highlight, with: .color(.blue), lineWidth: 3)
                }
            }
        }
    }
}
