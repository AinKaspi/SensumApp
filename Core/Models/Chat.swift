import Foundation
import FirebaseFirestore

// Модель для представления чата между пользователями
struct Chat: Codable, Identifiable {
    @DocumentID var id: String? // ID чата
    let userIDs: [String]      // Массив ID двух пользователей чата
    // Денормализованные данные участников для списка чатов
    var usernames: [String: String] = [:] // [userID: username]
    var userAvatarURLs: [String: String?] = [:] // [userID: avatarURL]
    var lastMessage: LastMessage? // Информация о последнем сообщении для превью
    var lastUpdatedAt: Timestamp = Timestamp() // Время последнего сообщения

    // Вычисляемое свойство для получения ID собеседника
    func otherUserID(currentUser ID: String) -> String? {
        return userIDs.first(where: { $0 != ID })
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userIDs = "user_ids"
        case usernames
        case userAvatarURLs = "user_avatar_urls"
        case lastMessage = "last_message"
        case lastUpdatedAt = "last_updated_at"
    }
}

// Структура для последнего сообщения в чате
struct LastMessage: Codable {
    let text: String
    let senderID: String
    let timestamp: Timestamp
    var isRead: Bool // Прочитано ли последнее сообщение получателем
    
    enum CodingKeys: String, CodingKey {
       case text
       case senderID = "sender_id"
       case timestamp
       case isRead = "is_read"
   }
}

// Модель для отдельного сообщения в чате
struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String? // ID сообщения
    let chatID: String         // ID чата, к которому принадлежит сообщение
    let senderID: String       // ID отправителя
    let text: String           // Текст сообщения
    let timestamp: Timestamp   // Время отправки
    
    // Опционально: статус прочтения для каждого сообщения? (усложняет)
    // var isReadByRecipient: Bool = false
    
    // Для удобства работы с датой
    var date: Date {
        timestamp.dateValue()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chatID = "chat_id"
        case senderID = "sender_id"
        case text
        case timestamp
    }
}
