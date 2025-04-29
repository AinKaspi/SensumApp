import Foundation
import UIKit

// MARK: - Версия для UI (не Codable)

/// Используем enum для представления типа медиа в UI, но пока только с image
/// Эта версия используется в UI/View и не хранится в Firestore
enum MediaItem: Hashable {
    case image(UIImage)
    // case video(AVAsset) // Убрали видео

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .image(let image):
            hasher.combine("image")
            hasher.combine(image)
        }
    }

    // Equatable conformance (нужно для Hashable)
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.image(let lImage), .image(let rImage)):
            return lImage == rImage
        }
    }
}

// MARK: - Версия для хранения (Codable)

/// MediaItemDTO - версия MediaItem для хранения в Firestore, которая поддерживает Codable
struct MediaItemDTO: Codable, Hashable {
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    let type: MediaType
    let url: String
    let width: Int?
    let height: Int?
    
    init(type: MediaType, url: String, width: Int? = nil, height: Int? = nil) {
        self.type = type
        self.url = url
        self.width = width
        self.height = height
    }
}

// Примечание: Эта структура MediaItem отличается от той, что была в Core/Models.
// Та была Codable и хранила URL. Эта используется для передачи UIImage/AVAsset
// из PHPicker в ViewModel. Нужно будет унифицировать или четко разделить их назначение.
