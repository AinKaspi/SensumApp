import Foundation
import UIKit // Для UIImage и UIColor
import Combine // Для возможной реактивности в будущем

class PersonViewModel {
    // TODO: Добавить логику для экрана Person
    
    // --- Свойства для хранения данных ---
    private var userProfile: UserProfile?
    private(set) var avatarImage: UIImage? // Делаем доступным для чтения
    
    // --- Вычисляемые свойства для UI ---
    var usernameText: String {
        return userProfile?.username ?? "Username"
    }
    
    var statusText: String {
        // TODO: Загружать/сохранять реальный статус
        return userProfile?.status ?? "Hello! Welcome to Sensum."
    }
    
    var levelText: String {
        return "Level \(userProfile?.level ?? 0)"
    }
    
    var xpText: String {
        let current = userProfile?.currentXP ?? 0
        let next = userProfile?.xpToNextLevel ?? 1 // Избегаем деления на ноль
        return "\(current)/\(next) XP"
    }
    
    var xpProgress: Float {
        guard let profile = userProfile, profile.xpToNextLevel > 0 else { return 0.0 }
        let progress = Float(profile.currentXP) / Float(profile.xpToNextLevel)
        return max(0.0, min(1.0, progress))
    }
    
    // --- Инициализация и Загрузка данных ---
    init() {
        loadUserProfile()
    }
    
    func loadUserProfile() {
        self.userProfile = DataManager.shared.getCurrentUserProfile()
        // Загружаем аватар
        if let profile = self.userProfile {
            self.avatarImage = loadAvatarImage(forUserID: profile.userID)
        } else {
            self.avatarImage = nil
        }
        // TODO: Уведомить View Controller об обновлении данных (если используем Combine/Callbacks)
    }
    
    // --- Сохранение Аватара ---
    func saveNewAvatar(_ image: UIImage) {
        guard let profile = userProfile else { return }
        // Обновляем текущее изображение
        self.avatarImage = image
        // Сохраняем в файл (используем хелпер, который нужно будет перенести сюда или сделать общим)
        if !saveAvatarImageToFile(image, forUserID: profile.userID) {
            print("PersonViewModel Ошибка: Не удалось сохранить аватар.")
        }
        // TODO: Уведомить View Controller об обновлении аватара
    }
    
    // --- Сохранение Статуса --- 
    func saveNewStatus(_ newStatus: String) {
        guard userProfile != nil else { 
            print("PersonViewModel Ошибка: Попытка сохранить статус для nil профиля.")
            return 
        }
        // Обновляем статус в локальной копии профиля
        userProfile?.status = newStatus
        // Сохраняем обновленный профиль через DataManager
        DataManager.shared.updateUserProfile(userProfile!)
        // print("PersonViewModel: Статус обновлен и сохранен: \(newStatus)")
        // TODO: Уведомить View Controller об обновлении статуса (если нужно, сейчас он сам обновляется через updateProfileDisplay)
    }
    
    // MARK: - Private File Management Helpers (Перенести из VC)
    // TODO: Вынести эти методы в отдельный FileManagerHelper или DataManager
    
    private func getAvatarFileURL(forUserID userID: UUID) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "avatar_\(userID.uuidString).png"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private func saveAvatarImageToFile(_ image: UIImage, forUserID userID: UUID) -> Bool {
        guard let fileURL = getAvatarFileURL(forUserID: userID), let imageData = image.pngData() else { return false }
        do {
            try imageData.write(to: fileURL, options: .atomic)
            return true
        } catch {
            print("Error saving avatar image: \(error)")
            return false
        }
    }
    
    private func loadAvatarImage(forUserID userID: UUID) -> UIImage? {
        guard let fileURL = getAvatarFileURL(forUserID: userID),
              FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading avatar image: \(error)")
            return nil
        }
    }
    
    // TODO: Добавить методы для предоставления данных View Controller'у
}
