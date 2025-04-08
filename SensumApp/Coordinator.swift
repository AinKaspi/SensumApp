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