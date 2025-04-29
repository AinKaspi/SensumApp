import Foundation
import FirebaseFirestore // Добавляем импорт для Timestamp

struct Comment: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let postId: String // ID поста, к которому относится комментарий
    let authorUid: String // ID пользователя, оставившего комментарий
    let authorUsername: String // Имя пользователя
    let authorAvatarUrl: String? // URL аватара пользователя (опционально)
    let text: String // Текст комментария
    let timestamp: Timestamp // Время создания комментария
    
    // Для удобства можно добавить вычисляемое свойство для Date
    var date: Date {
        timestamp.dateValue()
    }
    
    // Реализация Equatable для сравнения
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }
}