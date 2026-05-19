import SwiftUI
import AppKit

class DimOverlay {
    private var window: NSWindow?
    private var hostingView: NSHostingView<DimOverlayContent>?
    private var onComplete: ((CGRect?) -> Void)?
    private var screen: NSScreen?

    func show(on screen: NSScreen, onComplete: @escaping (CGRect?) -> Void) {
        self.screen = screen
        self.onComplete = onComplete

        let screenRect = screen.frame
        let viewModel = OverlayViewModel()

        let content = DimOverlayContent(
            viewModel: viewModel,
            onCancel: { [weak self] in
                self?.complete(rect: nil)
            },
            onSelectRegion: { [weak self] in
                guard let self else { return }
                let flipped = self.flipY(viewModel.selectionRect, screenHeight: screenRect.height)
                self.complete(rect: flipped)
            }
        )

        hostingView = NSHostingView(rootView: content)
        hostingView?.frame = CGRect(origin: .zero, size: screenRect.size)

        window = NSWindow(contentRect: screenRect,
                          styleMask: .borderless,
                          backing: .buffered,
                          defer: false)
        window?.level = .screenSaver
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window?.makeKeyAndOrderFront(nil)
        window?.contentView = hostingView

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
    @Published var isSelecting: Bool = false
}

struct DimOverlayContent: View {
    @ObservedObject var viewModel: OverlayViewModel
    let onCancel: () -> Void
    let onSelectRegion: () -> Void

    @State private var startPoint: CGPoint?
    @State private var currentRect: CGRect = .zero
    @State private var tracking: Bool = false

    var body: some View {
        ZStack {
            dimCanvas

            VStack {
                Spacer()
                CaptureToolbar(
                    onCaptureRegion: {},
                    onCaptureFullScreen: {},
                    onCaptureWindow: {},
                    onCancel: onCancel
                )
                .padding(.bottom, 40)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !tracking {
                        startPoint = value.startLocation
                        tracking = true
                    }
                    updateRect(start: startPoint ?? value.startLocation,
                               current: value.location)
                }
                .onEnded { _ in
                    tracking = false
                    if currentRect.width > 5 && currentRect.height > 5 {
                        viewModel.selectionRect = currentRect
                        onSelectRegion()
                    }
                    startPoint = nil
                }
        )
    }

    private func updateRect(start: CGPoint, current: CGPoint) {
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let maxX = max(start.x, current.x)
        let maxY = max(start.y, current.y)
        currentRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    @ViewBuilder
    private var dimCanvas: some View {
        Canvas { context, size in
            let fullRect = CGRect(origin: .zero, size: size)

            var path = Path(fullRect)
            path.addRect(currentRect)
            context.fill(path, with: .color(.black.opacity(0.45)), style: FillStyle(eoFill: true))

            if currentRect.width > 0 || currentRect.height > 0 {
                let border = Path(currentRect)
                context.stroke(border, with: .color(.white.opacity(0.8)), lineWidth: 0.5)
            }
        }
    }
}
