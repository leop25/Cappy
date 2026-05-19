import AppKit

enum CaptureService {

    static func captureRegion(rect: CGRect, screenHeight: CGFloat, scale: CGFloat, displayID: CGDirectDisplayID) -> CGImage? {
        guard let displayImage = CGDisplayCreateImage(displayID) else { return nil }

        let imageHeight = CGFloat(displayImage.height)

        let pixelX = rect.origin.x * scale
        let pixelY = imageHeight - (rect.origin.y + rect.height) * scale
        let pixelW = rect.size.width * scale
        let pixelH = rect.size.height * scale

        let pixelRect = CGRect(x: pixelX, y: pixelY, width: pixelW, height: pixelH)

        return displayImage.cropping(to: pixelRect)
    }

    static func captureFullScreen() -> CGImage? {
        let windowListOptions = CGWindowListOption.optionOnScreenOnly
        return CGWindowListCreateImage(
            .null,
            windowListOptions,
            kCGNullWindowID,
            .bestResolution
        )
    }

    static func captureDisplay(_ displayID: CGDirectDisplayID) -> CGImage? {
        return CGDisplayCreateImage(displayID)
    }

    static func captureDesktop(_ screenFrame: CGRect) -> CGImage? {
        guard let fullImage = captureFullScreen() else { return nil }
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let screenRect = NSScreen.screens.map { $0.frame }.reduce(CGRect.zero) { $0.union($1) }

        let x = (screenFrame.origin.x - screenRect.origin.x) * scale
        let y = (screenRect.height - (screenFrame.origin.y - screenRect.origin.y) - screenFrame.height) * scale
        let w = screenFrame.width * scale
        let h = screenFrame.height * scale

        let cropRect = CGRect(x: x, y: y, width: w, height: h)
        return fullImage.cropping(to: cropRect)
    }

    static func enumerateWindows(for screen: NSScreen? = nil) -> [[String: Any]] {
        guard let windowList = CGWindowListCopyWindowInfo(
            .optionOnScreenOnly,
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }
        let activeScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenArea = (activeScreen?.frame.width ?? 2560) * (activeScreen?.frame.height ?? 1440)

        return windowList.filter { dict in
            guard let layer = dict[kCGWindowLayer as String] as? Int,
                  layer < 1000 else { return false }

            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? ""
            guard !ownerName.isEmpty else { return false }
            if ownerName == "Cappy" { return false }

            guard let bounds = dict[kCGWindowBounds as String] as? [String: Any],
                  let w = bounds["Width"] as? CGFloat,
                  let h = bounds["Height"] as? CGFloat else { return false }

            if w * h > screenArea * 0.8 { return false }

            return true
        }
    }

    static func captureWindow(windowID: CGWindowID) -> CGImage? {
        let options = CGWindowImageOption.boundsIgnoreFraming
        return CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [options, .nominalResolution]
        )
    }
}
