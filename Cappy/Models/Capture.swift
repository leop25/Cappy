import AppKit

enum CaptureMode {
    case region
    case fullScreen
    case window
}

struct Capture {
    let id = UUID()
    let mode: CaptureMode
    let sourceRect: CGRect?
    let sourceWindowID: CGWindowID?
    let timestamp = Date()
    var fileURL: URL?
    var image: CGImage?

    func timestampFilename(suffix: String = "") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let base = "Cappy_\(formatter.string(from: timestamp))"
        return suffix.isEmpty ? "\(base).png" : "\(base)_\(suffix).png"
    }
}
