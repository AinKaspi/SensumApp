import Foundation
import FirebaseFirestore

// Модель программы тренировок
struct TrainingProgram: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    let createdByUserID: String // ID пользователя-создателя
    var steps: [ProgramStep] = []
    var isPublic: Bool = false // Доступна ли программа другим
    var createdAt: Timestamp = Timestamp()
    var lastUpdatedAt: Timestamp = Timestamp()

    // Опционально: можно добавить счетчик использований, рейтинг и т.д.
    
    // CodingKeys могут понадобиться
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdByUserID = "created_by_user_id"
        case steps
        case isPublic = "is_public"
        case createdAt = "created_at"
        case lastUpdatedAt = "last_updated_at"
    }
}

// Модель шага программы тренировок
struct ProgramStep: Codable, Identifiable, Hashable { // Hashable нужен для DiffableDataSource, если будем использовать
    var id = UUID().uuidString // Локальный ID для шага
    let exerciseID: String // ID упражнения из нашей базы Exercise
    var targetType: TargetType = .repetitions // Тип цели (повторения или время)
    var targetValue: Int = 10 // Значение цели (кол-во повторений или секунд)
    var order: Int = 0 // Порядок шага в программе

    enum TargetType: String, Codable {
        case repetitions = "reps"
        case duration = "time" // Секунды
    }
    
    // CodingKeys могут понадобиться
    enum CodingKeys: String, CodingKey {
        case id // Может не храниться в Firestore, если он часть массива
        case exerciseID = "exercise_id"
        case targetType = "target_type"
        case targetValue = "target_value"
        case order
    }
}
