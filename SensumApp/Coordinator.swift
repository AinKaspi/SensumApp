import UIKit

protocol Coordinator: AnyObject { // AnyObject нужен для weak ссылок на дочерние координаторы в будущем
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set } // Для управления дочерними координаторами

    func start()
    // Можно добавить функции для управления дочерними координаторами, если нужно
    // func addChild(_ coordinator: Coordinator)
    // func removeChild(_ coordinator: Coordinator)
}

// Базовая реализация для управления дочерними координаторами (опционально)
extension Coordinator {
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

// MARK: - Progress Service Protocol (Перенесено сюда для доступности)
// Импортируем необходимые типы
import Foundation // Для Result, Error
import FirebaseFirestore // Для ProgressData

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

// MARK: - Edit Profile Protocols (Перенесено сюда для доступности)

// Протокол для уведомления координатора о завершении редактирования VC
protocol EditProfileViewControllerDelegate: AnyObject {
    func editProfileDidFinish(didSave: Bool) // true если сохранили, false если отменили
}

// Протокол для уведомления координатора о завершении VM
protocol EditProfileViewModelDelegate: AnyObject {
    func editProfileDidFinish(didSave: Bool)
} 