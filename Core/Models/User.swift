import Foundation
import FirebaseFirestore // Для Timestamp

// Модель пользователя для Firestore
struct User: Codable, Identifiable {
    
    @DocumentID var id: String? // Автоматически связывается с ID документа Firestore
    let username: String
    let email: String
    var avatarURL: String? // URL аватара в Firebase Storage
    var status: String?
    
    // Статистика профиля
    var followerCount: Int = 0
    var followingCount: Int = 0
    
    // Система уровней
    var level: Int = 1
    var currentXP: Int = 0
    var xpToNextLevel: Int = 100 // Начальное значение для 1 уровня
    
    // Метаданные
    let createdAt: Timestamp // Используем Timestamp из Firebase
    
    // Можно добавить другие поля: дата рождения, пол, настройки приватности и т.д.
    
    // Пример CodingKeys, если имена полей в Firestore отличаются от Swift
    /*
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case avatarURL = "avatar_url" // Пример
        case status
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case level
        case currentXP = "current_xp"
        case xpToNextLevel = "xp_to_next_level"
        case createdAt = "created_at"
    }
    */
} 