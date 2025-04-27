import Foundation
import UIKit // Для UIImage и UIColor
import Combine // Для возможной реактивности в будущем

class PersonViewModel {
    // TODO: Добавить логику для экрана Person
    // ВАЖНО: Этот ViewModel устарел и использует DataManager / UserProfile.
    // Требуется рефакторинг UserProfileCardViewController для использования UserProfileFeedViewModel или нового CardViewModel.
    
    // --- Свойства для хранения данных ---
    // private var userProfile: UserProfile?
    private var userProfile: Any? // Временная заглушка типа, чтобы код компилировался
    private(set) var avatarImage: UIImage? // Делаем доступным для чтения
    
    // --- Вычисляемые свойства для UI (Будут возвращать плейсхолдеры) ---
    var usernameText: String {
        // return userProfile?.username ?? "Username"
        return "Username" // Placeholder
    }
    
    var statusText: String {
        // return userProfile?.status ?? "Hello! Welcome to Sensum."
        return "Status..." // Placeholder
    }
    
    var levelText: String {
        // return "Level \(userProfile?.level ?? 0)"
        return "Level 1" // Placeholder
    }
    
    var xpText: String {
        // let current = userProfile?.currentXP ?? 0
        // let next = userProfile?.xpToNextLevel ?? 1 // Избегаем деления на ноль
        // return "\(current)/\(next) XP"
        return "0/100 XP" // Placeholder
    }
    
    var xpProgress: Float {
        /*
        guard let profile = userProfile, profile.xpToNextLevel > 0 else { return 0.0 }
        let progress = Float(profile.currentXP) / Float(profile.xpToNextLevel)
        return max(0.0, min(1.0, progress))
        */
        return 0.0 // Placeholder
    }
    
    // --- Инициализация и Загрузка данных ---
    init() {
        // loadUserProfile() // Закомментируем вызов
        print("PersonViewModel initialized (Data loading disabled due to DataManager removal)")
    }
    
    func loadUserProfile() {
        // Закомментируем использование DataManager
        /*
        self.userProfile = DataManager.shared.getCurrentUserProfile()
        // Загружаем аватар
        if let profile = self.userProfile {
            self.avatarImage = loadAvatarImage(forUserID: profile.userID)
        } else {
            self.avatarImage = nil
        }
        */
        print("PersonViewModel: loadUserProfile called (functionality disabled).")
        // TODO: Уведомить View Controller об обновлении данных (если используем Combine/Callbacks)
    }
    
    // --- Сохранение Аватара ---
    func saveNewAvatar(_ image: UIImage) {
        /*
        guard let profile = userProfile else { return }
        // Обновляем текущее изображение
        self.avatarImage = image
        // Сохраняем в файл (используем хелпер, который нужно будет перенести сюда или сделать общим)
        if !saveAvatarImageToFile(image, forUserID: profile.userID) {
            print("PersonViewModel Ошибка: Не удалось сохранить аватар.")
        }
        */
        print("PersonViewModel: saveNewAvatar called (functionality disabled).")
        // TODO: Уведомить View Controller об обновлении аватара
    }
    
    // --- Сохранение Статуса --- 
    func saveNewStatus(_ newStatus: String) {
        /*
        guard userProfile != nil else { 
            print("PersonViewModel Ошибка: Попытка сохранить статус для nil профиля.")
            return 
        }
        // Обновляем статус в локальной копии профиля
        userProfile?.status = newStatus
        // Сохраняем обновленный профиль через DataManager
        DataManager.shared.updateUserProfile(userProfile!)
        // print("PersonViewModel: Статус обновлен и сохранен: \(newStatus)")
        */
        print("PersonViewModel: saveNewStatus called (functionality disabled).")
        // TODO: Уведомить View Controller об обновлении статуса (если нужно, сейчас он сам обновляется через updateProfileDisplay)
    }
    
    // MARK: - Private File Management Helpers (Перенести из VC)
    // Оставляем, но они не будут вызываться
    
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
