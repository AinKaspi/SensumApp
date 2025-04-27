import Foundation
import FirebaseFirestore // Для Timestamp

// Модель для хранения RPG-прогресса пользователя
struct ProgressData: Codable {
    // @DocumentID var userID: String? // ID документа будет равен userID, не дублируем
    var level: Int = 1
    var currentXP: Int = 0
    var xpToNextLevel: Int = 100 // Начальное значение для 1 уровня
    var rank: String = "E" // Начальный ранг
    var attributes: [Attribute] = AttributeType.allCases.map { Attribute(type: $0, value: 10) } // Начальные значения атрибутов
    var lastUpdated: Timestamp = Timestamp() // Время последнего обновления

    // CodingKeys могут понадобиться, если имена полей в Firestore отличаются
    enum CodingKeys: String, CodingKey {
        case level
        case currentXP = "current_xp"
        case xpToNextLevel = "xp_to_next_level"
        case rank
        case attributes
        case lastUpdated = "last_updated"
    }
    
    // Метод для безопасного получения значения атрибута
    func value(for attributeType: AttributeType) -> Int {
        return attributes.first { $0.type == attributeType }?.value ?? 0
    }
}

// Структура для представления одного атрибута
struct Attribute: Codable {
    let type: AttributeType
    var value: Int
}

// Перечисление возможных типов атрибутов
enum AttributeType: String, Codable, CaseIterable, Identifiable {
    case str = "STR" // Сила
    case con = "CON" // Выносливость
    case acc = "ACC" // Точность
    case spd = "SPD" // Скорость
    case bal = "BAL" // Баланс
    case flx = "FLX" // Гибкость
    
    var id: String { self.rawValue }
    
    // Можно добавить описание или иконку для каждого атрибута
    var description: String {
        switch self {
        case .str: return "Сила"
        case .con: return "Выносливость"
        case .acc: return "Точность"
        case .spd: return "Скорость"
        case .bal: return "Баланс"
        case .flx: return "Гибкость"
        }
    }
} 