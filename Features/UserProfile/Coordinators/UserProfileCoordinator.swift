import UIKit

class UserProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var userID: String
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController, userID: String) {
        self.navigationController = navigationController
        self.userID = userID
    }

    func start() {
        // ... (placeholder logic) ...
        print("--- UserProfileCoordinator started for userID: \(userID) (Needs presentation logic) ---")
        // ... (example presentation logic)
    }
    
    // Добавляем метод для закрытия экрана профиля
    func dismissProfile() {
        print("--- UserProfileCoordinator: Dismiss profile requested ---")
        // Логика закрытия зависит от того, как был представлен контейнер
        // Вариант 1: Если был push в navigationController координатора
        // navigationController.popViewController(animated: true)
        // Вариант 2: Если был present модально
        navigationController.presentingViewController?.dismiss(animated: true, completion: nil)
        // Вариант 3: Если был push в navigationController ИЗ ДРУГОГО координатора (FeedCoordinator)
        // Нужно будет передать управление обратно родительскому координатору
        // parentCoordinator?.didFinishUserProfileFlow(self)
        
        // TODO: Реализовать правильную логику закрытия в зависимости от способа представления
    }

    // Убираем старый метод настройки ...
} 