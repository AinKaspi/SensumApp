import Foundation

class DataManager {

    // Singleton instance
    static let shared = DataManager()

    // Key for saving data in UserDefaults
    private let userProfileKey = "userProfileData"

    // Property to hold the current user profile
    private(set) var currentUserProfile: UserProfile? // private(set) - можно читать снаружи, менять только внутри

    // Private initializer to ensure singleton usage
    private init() {
        loadUserProfile() // Загружаем профиль при инициализации
    }

    // MARK: - Public Methods

    /// Возвращает текущий профиль пользователя. Если профиль еще не загружен или отсутствует,
    /// создает и возвращает профиль по умолчанию.
    func getCurrentUserProfile() -> UserProfile {
        if let profile = currentUserProfile {
            return profile
        } else {
            // Если профиль не загрузился (первый запуск), создаем дефолтный
            print("DataManager: No saved profile found. Creating default profile.")
            let defaultProfile = UserProfile()
            currentUserProfile = defaultProfile
            saveUserProfile() // Сохраняем дефолтный профиль
            return defaultProfile
        }
    }

    /// Обновляет текущий профиль пользователя и сохраняет его.
    /// - Parameter profile: Новый профиль пользователя.
    func updateUserProfile(_ profile: UserProfile) {
        currentUserProfile = profile
        saveUserProfile()
    }

    /// Принудительно сохраняет текущий профиль в UserDefaults.
    /// Обычно вызывается автоматически при обновлении, но может быть полезен.
    func saveUserProfile() {
        guard let profile = currentUserProfile else {
            print("DataManager: Attempted to save a nil profile.")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: userProfileKey)
            print("DataManager: User profile saved successfully.")
        } catch {
            print("DataManager: Failed to encode or save user profile: \(error.localizedDescription)")
        }
    }

    /// Сбрасывает профиль пользователя к значениям по умолчанию и сохраняет его.
    /// ОСТОРОЖНО: Удаляет все данные пользователя!
    func resetUserProfile() {
        print("DataManager: Resetting user profile to defaults.")
        let defaultProfile = UserProfile() // Создаем новый дефолтный профиль
        currentUserProfile = defaultProfile
        saveUserProfile()
        // TODO: Возможно, нужно уведомить другие части приложения о сбросе данных?
    }

    // MARK: - XP Calculation

    /// Рассчитывает количество XP, необходимое для перехода с указанного уровня на следующий.
    /// - Parameter level: Текущий уровень пользователя.
    /// - Returns: Количество XP для следующего уровня.
    static func calculateXPForLevel(_ level: Int) -> Int {
        // Предотвращаем уровень < 1
        let currentLevel = max(1, level)
        // Формула прогрессии: База + Модификатор * (Уровень - 1)^Степень
        let baseXP: Double = 100.0
        let modifier: Double = 10.0
        let exponent: Double = 1.8

        // Рассчитываем XP. Используем pow() для дробной степени.
        // Добавляем небольшое смещение к уровню перед возведением в степень, чтобы избежать 0^1.8 для первого уровня, хотя level-1 уже это решает.
        let requiredXP = baseXP + modifier * pow(Double(currentLevel - 1), exponent)

        // Округляем до ближайшего целого
        return Int(round(requiredXP))
    }

    // MARK: - Private Methods

    /// Загружает профиль пользователя из UserDefaults при инициализации.
    private func loadUserProfile() {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
            print("DataManager: No data found for user profile key.")
            // Профиль будет создан при первом вызове getCurrentUserProfile()
            return
        }

        do {
            let decoder = JSONDecoder()
            currentUserProfile = try decoder.decode(UserProfile.self, from: data)
            print("DataManager: User profile loaded successfully.")
        } catch {
            print("DataManager: Failed to decode user profile: \(error.localizedDescription)")
            // Если декодирование не удалось (например, структура изменилась),
            // старые данные будут проигнорированы, и новый профиль создастся при первом запросе.
             UserDefaults.standard.removeObject(forKey: userProfileKey) // Удаляем поврежденные данные
        }
    }
}
