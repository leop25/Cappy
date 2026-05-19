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

    static func enumerateWindows() -> [[String: Any]] {
        guard let windowList = CGWindowListCopyWindowInfo(
            .optionOnScreenOnly,
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }
        return windowList.filter { dict in
            guard let layer = dict[kCGWindowLayer as String] as? Int else { return false }
            return layer < 1000
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
