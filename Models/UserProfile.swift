import Foundation

// MARK: - Rank Enum -

enum Rank: String, Codable, CaseIterable { // Codable для сохранения/загрузки, CaseIterable для удобства
    case E
    case D
    case C
    case B
    case A
    case S
    case R
}

// MARK: - User Profile Struct -

struct UserProfile: Codable { // Codable для сохранения/загрузки
    let userID: UUID // Используем UUID для уникальной идентификации
    var username: String? // Может быть опциональным
    var level: Int
    var currentXP: Int
    var xpToNextLevel: Int
    var rank: Rank
    var totalSquats: Int
    // TODO: Заменить String на более конкретные типы для предметов
    var inventoryItemIDs: [String]
    var equippedEffectIDs: [String]
    var lastLoginDate: Date?
    let registrationDate: Date

    // MARK: - Initializer

    // Дефолтный инициализатор для нового пользователя
    init(userID: UUID = UUID(),
         username: String? = nil,
         level: Int = 1,
         currentXP: Int = 0,
         xpToNextLevel: Int = 100, // Начальное значение XP для уровня 2
         rank: Rank = .E,
         totalSquats: Int = 0,
         inventoryItemIDs: [String] = [],
         equippedEffectIDs: [String] = [],
         lastLoginDate: Date? = nil,
         registrationDate: Date = Date()) {
        self.userID = userID
        self.username = username
        self.level = level
        self.currentXP = currentXP
        self.xpToNextLevel = xpToNextLevel
        self.rank = rank
        self.totalSquats = totalSquats
        self.inventoryItemIDs = inventoryItemIDs
        self.equippedEffectIDs = equippedEffectIDs
        self.lastLoginDate = lastLoginDate
        self.registrationDate = registrationDate
    }

    // MARK: - Data Management Methods

    /// Добавляет опыт пользователю и обрабатывает повышение уровня.
    /// - Parameter amount: Количество добавляемого опыта.
    /// - Returns: True, если пользователь повысил уровень, иначе false.
    mutating func addXP(_ amount: Int) -> Bool {
        guard amount > 0 else { return false } // Не добавляем отрицательный опыт
        
        currentXP += amount
        var leveledUp = false
        
        // Проверяем повышение уровня (может быть несколько за раз)
        while currentXP >= xpToNextLevel {
            leveledUp = true
            // Вычитаем XP, необходимый для текущего уровня
            currentXP -= xpToNextLevel
            // Повышаем уровень
            level += 1
            // Рассчитываем XP для НОВОГО следующего уровня
            xpToNextLevel = DataManager.calculateXPForLevel(level)
            print("LEVEL UP! Reached level \(level). Next level at \(xpToNextLevel) XP.")
            // TODO: Добавить уведомление или вызов делегата о повышении уровня?
        }
        return leveledUp
    }

    // TODO: Добавить другие методы, например:
    // mutating func levelUp() { ... } // Если нужен отдельный метод
    // mutating func addItem(_ itemID: String) { ... }
    // mutating func equipEffect(_ effectID: String) { ... }
}
