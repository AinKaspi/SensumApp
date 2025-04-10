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
    // Добавляем базовое значение для статов
    static let baseStatValue = 20
    
    let userID: UUID // Используем UUID для уникальной идентификации
    var username: String? // Может быть опциональным
    var level: Int
    var currentXP: Int
    var xpToNextLevel: Int
    var rank: Rank
    var totalSquats: Int // Оставляем общий счетчик приседаний
    
    // --- Базовые Атрибуты (0-100) ---
    var strength: Int      // STR: Сила
    var constitution: Int  // CON: Выносливость
    var accuracy: Int      // ACC: Точность
    var speed: Int         // SPD: Скорость
    var balance: Int       // BAL: Баланс
    var flexibility: Int   // FLX: Гибкость

    // --- Главные Статы (Вычисляемые) ---
    /// Мощь (PWR) = База + (STR/10) + (SPD/10).
    var power: Int { UserProfile.baseStatValue + (strength / 10) + (speed / 10) }
    /// Контроль (CTL) = База + (ACC/10) + (BAL/10).
    var control: Int { UserProfile.baseStatValue + (accuracy / 10) + (balance / 10) }
    /// Стойкость (END) = База + (CON/10) + (STR/10).
    var endurance: Int { UserProfile.baseStatValue + (constitution / 10) + (strength / 10) }
    /// Проворство (AGI) = База + (SPD/10) + (BAL/10).
    var agility: Int { UserProfile.baseStatValue + (speed / 10) + (balance / 10) }
    /// Мобильность (MOB) = База + (FLX/10) + (ACC/10).
    var mobility: Int { UserProfile.baseStatValue + (flexibility / 10) + (accuracy / 10) }
    /// Здоровье (WLN) = База + (CON/10) + (FLX/10).
    var wellness: Int { UserProfile.baseStatValue + (constitution / 10) + (flexibility / 10) }

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
         // Устанавливаем начальные значения атрибутов в 0
         strength: Int = 0,
         constitution: Int = 0,
         accuracy: Int = 0,
         speed: Int = 0,
         balance: Int = 0,
         flexibility: Int = 0,
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
        // Сохраняем начальные атрибуты
        self.strength = max(0, min(100, strength)) // Ограничиваем 0-100 при инициализации
        self.constitution = max(0, min(100, constitution))
        self.accuracy = max(0, min(100, accuracy))
        self.speed = max(0, min(100, speed))
        self.balance = max(0, min(100, balance))
        self.flexibility = max(0, min(100, flexibility))
        self.inventoryItemIDs = inventoryItemIDs
        self.equippedEffectIDs = equippedEffectIDs
        self.lastLoginDate = lastLoginDate
        self.registrationDate = registrationDate
    }

    // MARK: - Data Management Methods

    /// Добавляет опыт пользователю и обрабатывает повышение уровня.
    /// - Parameter amount: Количество добавляемого опыта.
    /// - Returns: `true`, если пользователь повысил уровень, иначе `false`.
    mutating func addXP(_ amount: Int) -> Bool {
        guard amount > 0 else { return false }
        
        currentXP += amount
        var leveledUp = false
        
        while currentXP >= xpToNextLevel {
            leveledUp = true
            currentXP -= xpToNextLevel
            level += 1
            xpToNextLevel = DataManager.calculateXPForLevel(level)
            // Опционально: Можно добавить логирование повышения уровня здесь
            // print("LEVEL UP! Reached level \(level). Next level at \(xpToNextLevel) XP.")
        }
        return leveledUp
    }

    /// Добавляет очки к базовым атрибутам, ограничивая их максимальным значением 100.
    mutating func gainAttributes(strGain: Int = 0, conGain: Int = 0, accGain: Int = 0, spdGain: Int = 0, balGain: Int = 0, flxGain: Int = 0) {
        // print("--- UserProfile gainAttributes: Попытка добавить очки атрибутов...") // Убираем лог
        
        strength = min(100, strength + strGain)
        constitution = min(100, constitution + conGain)
        accuracy = min(100, accuracy + accGain)
        speed = min(100, speed + spdGain)
        balance = min(100, balance + balGain)
        flexibility = min(100, flexibility + flxGain)
        
        // print("--- UserProfile gainAttributes: Новые атрибуты: ...") // Убираем лог
    }

    // TODO: Добавить другие методы, например:
    // mutating func levelUp() { ... } // Если нужен отдельный метод
    // mutating func addItem(_ itemID: String) { ... }
    // mutating func equipEffect(_ effectID: String) { ... }
}
