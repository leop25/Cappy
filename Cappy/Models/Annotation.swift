import Foundation
import CoreGraphics
import AppKit

enum AnnotationType: CaseIterable {
    case arrow
    case rectangle
    case circle
    case text
}

enum AnnotationColor: String, CaseIterable {
    case red
    case yellow
    case blue
    case green
    case white
    case black

    var cgColor: CGColor {
        switch self {
        case .red:    return CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
        case .yellow: return CGColor(red: 1, green: 0.8, blue: 0, alpha: 1)
        case .blue:   return CGColor(red: 0.2, green: 0.4, blue: 1, alpha: 1)
        case .green:  return CGColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
        case .white:  return CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        case .black:  return CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }

    var nsColor: NSColor {
        NSColor(cgColor: cgColor) ?? .red
    }
}

struct Annotation: Identifiable {
    var id = UUID()
    var type: AnnotationType
    var origin: CGPoint
    var size: CGSize
    var endPoint: CGPoint?
    var color: AnnotationColor = .red
    var lineWidth: CGFloat = 3
    var text: String?
    var zIndex: Int = 0

    var isValid: Bool {
        switch type {
        case .rectangle, .circle:
            return size.width >= 1 && size.height >= 1
        case .text:
            return text?.isEmpty == false
        case .arrow:
            return endPoint != nil
        }
    }

    func boundsRect() -> CGRect {
        switch type {
        case .rectangle, .circle:
            return CGRect(origin: origin, size: size)
        case .arrow:
            guard let end = endPoint else { return .zero }
            let mx = min(origin.x, end.x)
            let my = min(origin.y, end.y)
            return CGRect(x: mx, y: my, width: abs(end.x - origin.x), height: abs(end.y - origin.y))
        case .text:
            return CGRect(origin: origin, size: CGSize(width: 100, height: 30))
        }
    }

    mutating func move(by delta: CGPoint) {
        origin.x += delta.x
        origin.y += delta.y
        if var ep = endPoint {
            ep.x += delta.x
            ep.y += delta.y
            endPoint = ep
        }
    }
}
