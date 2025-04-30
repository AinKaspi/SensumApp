import Foundation
import CoreGraphics // For CGFloat

/// Enum defining aspect ratios for posts
enum PostAspectRatio: String, CaseIterable {
    case square = "1:1"     // Квадрат
    case portrait = "9:16"   // Вертикальный (старый был 4:5)
    case landscape = "1.91:1" // Горизонтальный (Instagram Landscape)
    
    /// String representation for UI display
    var stringValue: String {
        return self.rawValue
    }
    
    /// Actual CGFloat ratio value (width / height)
    var ratio: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .portrait:
            return 9.0 / 16.0 // ~0.5625
        case .landscape:
            return 1.91 / 1.0 // 1.91
        }
    }
} 