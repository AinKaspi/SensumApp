import Foundation
import FirebaseFirestore // Импортируем основной фреймворк

// MARK: - Progress Service Implementation
class ProgressService: ProgressServiceProtocol {

    private let db = Firestore.firestore()
    private var progressCollection: CollectionReference { db.collection("progress") }

    // --- Fetch Data ---
    func fetchProgressData(userID: String, completion: @escaping (Result<ProgressData, Error>) -> Void) {
        let docRef = progressCollection.document(userID)

        docRef.getDocument { (document, error) in
            if let error = error {
                print("ProgressService Error (Fetch): Failed to get document for user \(userID) - \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let document = document, document.exists {
                // Пытаемся декодировать существующие данные
                do {
                    // Используем Codable поддержку Firestore
                    let progressData = try document.data(as: ProgressData.self)
                    print("ProgressService: Fetched progress data for user \(userID)")
                    completion(.success(progressData))
                } catch {
                    print("ProgressService Error (Fetch): Failed to decode progress data for user \(userID) - \(error.localizedDescription)")
                    // Дополнительный лог для деталей ошибки декодирования
                    if let decodingError = error as? DecodingError {
                         print("Decoding error details: \(decodingError)")
                     }
                    completion(.failure(error))
                }
            } else {
                // Документа нет, создаем и возвращаем дефолтные данные
                print("ProgressService: No progress data found for user \(userID). Creating default.")
                let defaultProgress = ProgressData() // Создаем дефолтный объект
                // Используем updateProgressData для сохранения дефолтных данных
                self.updateProgressData(userID: userID, data: defaultProgress) { error in
                    if let error = error {
                        // Ошибка при попытке сохранить дефолтные данные
                        completion(.failure(error))
                    } else {
                        // Успешно создали и сохранили дефолт
                        completion(.success(defaultProgress))
                    }
                }
            }
        }
    }

    // --- Update Data (Прямое обновление) ---
    func updateProgressData(userID: String, data: ProgressData, completion: @escaping (Error?) -> Void) {
        let docRef = progressCollection.document(userID)
        do {
            // Обновляем время последнего изменения перед сохранением
            var mutableData = data
            mutableData.lastUpdated = Timestamp()
            // Используем setData(from:merge:) для сохранения Codable объекта
            try docRef.setData(from: mutableData, merge: true) { error in
                if let error = error {
                    print("ProgressService Error (Update): Failed to set data for user \(userID) - \(error.localizedDescription)")
                } else {
                    print("ProgressService: Successfully updated progress data for user \(userID)")
                }
                completion(error)
            }
        } catch {
            print("ProgressService Error (Update): Failed to encode progress data for user \(userID) - \(error.localizedDescription)")
            completion(error)
        }
    }

    // --- Add XP (Основная логика прогресса) ---
    func addXP(_ amount: Int,
             attributeGains: (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int),
             forUserID userID: String,
             completion: @escaping (Result<ProgressData, Error>) -> Void) {

        // 1. Загружаем текущие данные прогресса
        fetchProgressData(userID: userID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error)) // Передаем ошибку загрузки дальше

            case .success(var currentProgress):
                // Запоминаем старый уровень для проверки Level Up
                let oldLevel = currentProgress.level

                // 2. Добавляем XP
                currentProgress.currentXP += amount

                // 3. Проверяем Level Up
                var didLevelUp = false
                while currentProgress.currentXP >= currentProgress.xpToNextLevel {
                    didLevelUp = true
                    currentProgress.currentXP -= currentProgress.xpToNextLevel
                    currentProgress.level += 1
                    currentProgress.xpToNextLevel = self.calculateXPForLevel(currentProgress.level)
                    // TODO: Начислить награды за уровень, если есть
                }

                // 4. Обновляем Ранг, если был Level Up
                if didLevelUp {
                    currentProgress.rank = self.calculateRank(level: currentProgress.level)
                    print("ProgressService: User \(userID) LEVELED UP to \(currentProgress.level)! New rank: \(currentProgress.rank)")
                    // TODO: Возможно, здесь стоит уведомить ViewModel/View о Level Up?
                    // Можно добавить в completion handler флаг или доп. данные.
                }

                // 5. Применяем прирост атрибутов
                currentProgress.attributes = self.applyAttributeGains(currentProgress.attributes, gains: attributeGains)

                // 6. Сохраняем обновленные данные
                self.updateProgressData(userID: userID, data: currentProgress) { error in
                    if let error = error {
                        completion(.failure(error)) // Ошибка сохранения
                    } else {
                        // Успешное добавление XP и сохранение
                        print("ProgressService: Added \(amount) XP for user \(userID). New level: \(currentProgress.level), XP: \(currentProgress.currentXP)/\(currentProgress.xpToNextLevel)")
                        completion(.success(currentProgress))
                    }
                }
            }
        }
    }

    // --- Rank Calculation (`[P1.RPG.1]`) ---
    func calculateRank(level: Int) -> String {
        // Простая логика E-R+ (по 10 уровней на ранг, R+ начинается с 61)
        if level <= 10 { return "E" }
        if level <= 20 { return "D" }
        if level <= 30 { return "C" }
        if level <= 40 { return "B" }
        if level <= 50 { return "A" }
        if level <= 60 { return "S" }
        // Ранги R+ (R1, R2, R3...)
        let rRank = (level - 61) / 10 + 1 // Каждые 10 уровней после 60 - новый R ранг
        return "R\(rRank)"
    }

    // --- Вспомогательные функции ---

    /// Переносим сюда логику расчета XP для уровня из DataManager
    private func calculateXPForLevel(_ level: Int) -> Int {
        let currentLevel = max(1, level)
        let baseXP: Double = 100.0
        let modifier: Double = 10.0
        let exponent: Double = 1.8
        let requiredXP = baseXP + modifier * pow(Double(currentLevel - 1), exponent)
        return Int(round(requiredXP))
    }

    /// Применяет прирост к текущим атрибутам
    private func applyAttributeGains(_ currentAttributes: [Attribute], gains: (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int)) -> [Attribute] {
        var updatedAttributes = currentAttributes
        let gainsMap: [AttributeType: Int] = [
            .str: gains.str, .con: gains.con, .acc: gains.acc,
            .spd: gains.spd, .bal: gains.bal, .flx: gains.flx
        ]

        for i in 0..<updatedAttributes.count {
            let attributeType = updatedAttributes[i].type
            if let gain = gainsMap[attributeType] {
                updatedAttributes[i].value += gain
                // TODO: Добавить логику максимального значения атрибута?
            }
        }
        return updatedAttributes
    }
}
