import Foundation
import FirebaseFirestore

// Модель поста для Firestore
struct Post: Codable, Identifiable {
    
    @DocumentID var id: String?
    let userID: String        // ID автора поста
    let imageURL: String      // URL фото в Firebase Storage
    var caption: String?      // Текст под фото
    let createdAt: Timestamp  // Дата создания
    
    // Статистика поста
    var likeCount: Int = 0
    var commentCount: Int = 0
    
    // Денормализованные данные автора (для эффективности ленты)
    var authorUsername: String? 
    var authorAvatarURL: String?
    
    // Опционально: можно добавить соотношение сторон (aspect ratio) для фото
    // var aspectRatio: CGFloat?
    
    // Опционально: ссылка на связанное упражнение/тренировку?
    // var relatedExerciseID: String?
    
    /*
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case imageURL = "image_url"
        case caption
        case createdAt = "created_at"
        case likeCount = "like_count"
        case commentCount = "comment_count"
    }
    */
} 
