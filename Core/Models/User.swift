import Foundation
import FirebaseFirestore // Для Timestamp

// Модель пользователя для Firestore
struct User: Codable, Identifiable {
    
    @DocumentID var id: String? // Автоматически связывается с ID документа Firestore
    let username: String
    let email: String
    var avatarURL: String? // URL аватара в Firebase Storage
    var status: String?
    
    // Статистика профиля - Делаем опциональными
    var followerCount: Int? 
    var followingCount: Int?
    
    // УДАЛЯЕМ ПОЛЯ УРОВНЕЙ/XP - они теперь в ProgressData
    // var level: Int = 1
    // var currentXP: Int = 0
    // var xpToNextLevel: Int = 100 // Начальное значение для 1 уровня
    
    // Метаданные
    let createdAt: Timestamp // Используем Timestamp из Firebase
    
    // Можно добавить другие поля: дата рождения, пол, настройки приватности и т.д.
    
    // Пример CodingKeys, если имена полей в Firestore отличаются от Swift
    // Обновляем CodingKeys, чтобы они соответствовали Firestore
    enum CodingKeys: String, CodingKey {
        case id // @DocumentID не кодируется вручную
        case username
        case email
        case avatarURL // Исправлено
        case status
        case followerCount // Исправлено
        case followingCount // Исправлено
        case createdAt // Исправлено
    }
    
    // Обновляем init, чтобы соответствовать опциональным полям
    init(id: String? = nil, username: String, email: String, avatarURL: String? = nil, status: String? = nil, followerCount: Int? = 0, followingCount: Int? = 0, createdAt: Timestamp) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.status = status
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.createdAt = createdAt
    }
} 