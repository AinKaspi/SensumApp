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
    
    // Статус лайка (вычисляется на клиенте, не хранится в Firestore)
    var isLiked: Bool = false
    
    // Денормализованные данные автора (для эффективности ленты)
    var authorUsername: String? 
    var authorAvatarURL: String?
    
    // Опционально: можно добавить соотношение сторон (aspect ratio) для фото
    // var aspectRatio: CGFloat?
    
    // Опционально: ссылка на связанное упражнение/тренировку?
    // var relatedExerciseID: String?
    
    // Определяем ключи для кодирования/декодирования, исключая isLiked
    enum CodingKeys: String, CodingKey {
        case id // @DocumentID обрабатывается автоматически
        case userID
        case imageURL
        case caption
        case createdAt
        case likeCount
        case commentCount
        case authorUsername
        case authorAvatarURL
        // isLiked не включаем сюда
    }
    
    // Ручная реализация декодера
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Декодируем @DocumentID (может быть nil до сохранения)
        // Пытаемся декодировать id, если не получается - оставляем nil
        self.id = try? container.decodeIfPresent(String.self, forKey: .id)
        
        self.userID = try container.decode(String.self, forKey: .userID)
        self.imageURL = try container.decode(String.self, forKey: .imageURL)
        self.caption = try container.decodeIfPresent(String.self, forKey: .caption)
        self.createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        self.likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0 // Значение по умолчанию
        self.commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0 // Значение по умолчанию
        self.authorUsername = try container.decodeIfPresent(String.self, forKey: .authorUsername)
        self.authorAvatarURL = try container.decodeIfPresent(String.self, forKey: .authorAvatarURL)
        
        // isLiked инициализируется значением по умолчанию false и не декодируется
        self.isLiked = false
    }
    
    // Ручная реализация кодера
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // @DocumentID id не кодируется вручную
        try container.encode(self.userID, forKey: .userID)
        try container.encode(self.imageURL, forKey: .imageURL)
        try container.encodeIfPresent(self.caption, forKey: .caption)
        try container.encode(self.createdAt, forKey: .createdAt)
        try container.encode(self.likeCount, forKey: .likeCount)
        try container.encode(self.commentCount, forKey: .commentCount)
        try container.encodeIfPresent(self.authorUsername, forKey: .authorUsername)
        try container.encodeIfPresent(self.authorAvatarURL, forKey: .authorAvatarURL)
        // isLiked не кодируем
    }
    
    // Оставляем пустой init для возможности создания объекта без декодирования
    // (например, при создании нового поста на клиенте до отправки)
    init(id: String? = nil, userID: String, imageURL: String, caption: String?, createdAt: Timestamp, likeCount: Int = 0, commentCount: Int = 0, isLiked: Bool = false, authorUsername: String?, authorAvatarURL: String?) {
        self.id = id
        self.userID = userID
        self.imageURL = imageURL
        self.caption = caption
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.authorUsername = authorUsername
        self.authorAvatarURL = authorAvatarURL
    }
} 
