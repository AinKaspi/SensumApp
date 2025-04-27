import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case follow = "follow"
    case like = "like"
    case comment = "comment"
    case newPost = "new_post" // Уведомление о новом посте от подписки
    case system = "system"   // Системные сообщения
    // Добавить другие типы по мере необходимости
}

struct AppNotification: Codable, Identifiable {
    @DocumentID var id: String?
    let recipientUserID: String // Кому предназначено уведомление
    let type: NotificationType
    let senderUserID: String?   // От кого (если применимо, например, для лайка/подписки)
    let senderUsername: String? // Денормализованное имя отправителя
    let senderAvatarURL: String?// Денормализованный аватар отправителя
    let postID: String?         // ID поста (для лайка, комментария, нового поста)
    let postImageURL: String?   // Денормализованное превью поста
    let commentText: String?    // Текст комментария (для уведомления о комментарии)
    var message: String?        // Текст системного уведомления или доп. инфо
    var isRead: Bool = false
    let createdAt: Timestamp = Timestamp()
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipientUserID = "recipient_user_id"
        case type
        case senderUserID = "sender_user_id"
        case senderUsername = "sender_username"
        case senderAvatarURL = "sender_avatar_url"
        case postID = "post_id"
        case postImageURL = "post_image_url"
        case commentText = "comment_text"
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}
