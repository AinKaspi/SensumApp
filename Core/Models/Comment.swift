import Foundation
import FirebaseFirestore // Добавляем импорт для Timestamp

struct Comment: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // Автоматически заполняется Firestore
    let postId: String // ID поста, к которому относится комментарий
    let userId: String // ID пользователя, оставившего комментарий
    let text: String
    let timestamp: Timestamp // Время создания комментария
    var user: User? // Информация о пользователе (денормализованная)
    var parentCommentId: String? // ID комментария, на который отвечают (для вложенности)

    // Для соответствия Hashable (если user используется для сравнения)
    // Если user не нужен для Hashable, можно убрать
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(postId)
        hasher.combine(userId)
        hasher.combine(text)
        hasher.combine(timestamp)
        hasher.combine(parentCommentId) // Добавляем в хеширование
        // hasher.combine(user) // User может быть не Hashable или меняться
    }

    // Для соответствия Equatable (если user используется для сравнения)
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.postId == rhs.postId &&
               lhs.userId == rhs.userId &&
               lhs.text == rhs.text &&
               lhs.timestamp == rhs.timestamp &&
               lhs.parentCommentId == rhs.parentCommentId // Добавляем в сравнение
               // lhs.user == rhs.user // User может быть не Equatable или меняться
    }
}
