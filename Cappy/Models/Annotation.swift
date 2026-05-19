import Foundation
import CoreGraphics

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
}

struct Annotation: Identifiable {
    let id = UUID()
    var type: AnnotationType
    var origin: CGPoint
    var size: CGSize
    var endPoint: CGPoint?
    var color: AnnotationColor = .red
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
}
