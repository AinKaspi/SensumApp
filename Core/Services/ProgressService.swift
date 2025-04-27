import Foundation
import FirebaseFirestore

// MARK: - Progress Service Protocol
protocol ProgressServiceProtocol {
    /// Асинхронно загружает данные прогресса для указанного пользователя.
    func fetchProgressData(userID: String, completion: @escaping (Result<ProgressData, Error>) -> Void)

    /// Асинхронно обновляет (или создает) данные прогресса для указанного пользователя.
    /// Важно: Этот метод должен вызываться осторожно, обычно изменения происходят через addXP.
    func updateProgressData(userID: String, data: ProgressData, completion: @escaping (Error?) -> Void)

    /// Добавляет очки опыта пользователю, обрабатывает повышение уровня, ранга и атрибутов.
    func addXP(_ amount: Int,
             attributeGains: (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int),
             forUserID userID: String,
             completion: @escaping (Result<ProgressData, Error>) -> Void)

    /// Рассчитывает ранг на основе уровня.
    func calculateRank(level: Int) -> String
}

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
                do {
                    let progressData = try document.data(as: ProgressData.self)
                    print("ProgressService: Fetched progress data for user \(userID)")
                    completion(.success(progressData))
                } catch {
                    print("ProgressService Error (Fetch): Failed to decode progress data for user \(userID) - \(error.localizedDescription)")
                     if let decodingError = error as? DecodingError {
                         print("Decoding error details: \(decodingError)")
                     }
                    completion(.failure(error))
                }
            } else {
                print("ProgressService: No progress data found for user \(userID). Creating default.")
                let defaultProgress = ProgressData()
                self.updateProgressData(userID: userID, data: defaultProgress) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(defaultProgress))
                    }
                }
            }
        }
    }

    // --- Update Data ---
    func updateProgressData(userID: String, data: ProgressData, completion: @escaping (Error?) -> Void) {
        let docRef = progressCollection.document(userID)
        do {
            var mutableData = data
            mutableData.lastUpdated = Timestamp()
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

    // --- Add XP ---
    func addXP(_ amount: Int,
             attributeGains: (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int),
             forUserID userID: String,
             completion: @escaping (Result<ProgressData, Error>) -> Void) {

        fetchProgressData(userID: userID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(var currentProgress):
                let oldLevel = currentProgress.level
                let xpBonusMultiplier = self.calculateXpBonus(from: currentProgress.attributes)
                let finalXpAmount = Int(round(Double(amount) * xpBonusMultiplier))
                

                currentProgress.currentXP += finalXpAmount

                var didLevelUp = false
                while currentProgress.currentXP >= currentProgress.xpToNextLevel {
                    didLevelUp = true
                    currentProgress.currentXP -= currentProgress.xpToNextLevel
                    currentProgress.level += 1
                    currentProgress.xpToNextLevel = self.calculateXPForLevel(currentProgress.level)
                }

                if didLevelUp {
                    currentProgress.rank = self.calculateRank(level: currentProgress.level)
                    print("ProgressService: User \(userID) LEVELED UP to \(currentProgress.level)! New rank: \(currentProgress.rank)")
                }

                currentProgress.attributes = self.applyAttributeGains(currentProgress.attributes, gains: attributeGains)

                self.updateProgressData(userID: userID, data: currentProgress) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        print("ProgressService: Added \(finalXpAmount) XP (incl. bonus) for user \(userID). New level: \(currentProgress.level), XP: \(currentProgress.currentXP)/\(currentProgress.xpToNextLevel)")
                        completion(.success(currentProgress))
                    }
                }
            }
        }
    }

    // --- Rank Calculation ---
    func calculateRank(level: Int) -> String {
        if level <= 10 { return "E" }
        if level <= 20 { return "D" }
        if level <= 30 { return "C" }
        if level <= 40 { return "B" }
        if level <= 50 { return "A" }
        if level <= 60 { return "S" }
        let rRank = (level - 61) / 10 + 1
        return "R\(rRank)"
    }

    // --- Helpers ---
    private func calculateXPForLevel(_ level: Int) -> Int {
        let currentLevel = max(1, level)
        let baseXP: Double = 100.0
        let modifier: Double = 10.0
        let exponent: Double = 1.8
        let requiredXP = baseXP + modifier * pow(Double(currentLevel - 1), exponent)
        return Int(round(requiredXP))
    }

    private func calculateXpBonus(from attributes: [Attribute]) -> Double {
        let strValue = attributes.first { $0.type == .str }?.value ?? 10
        let conValue = attributes.first { $0.type == .con }?.value ?? 10
        let normalizedStr = Double(max(0, strValue - 10))
        let normalizedCon = Double(max(0, conValue - 10))
        let bonusPercentage = (normalizedStr + normalizedCon) / 20.0 * 0.10
        let cappedBonusPercentage = min(0.50, bonusPercentage)
        return 1.0 + cappedBonusPercentage
    }

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
            }
        }
        return updatedAttributes
    }
}
