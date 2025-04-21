import UIKit

class FeedCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // TODO: Настроить внешний вид Navigation Bar для ленты? Или он будет скрыт?
    }

    func start() {
        let vc = FeedViewController()
        // TODO: Создать и передать FeedViewModel
        vc.coordinator = self // Передаем себя для навигации (например, на профиль юзера)
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // Метод для показа профиля другого пользователя
    func showUserProfile(userID: String) {
        // TODO: Реализовать представление UserProfileCoordinator
        print("FeedCoordinator: Show user profile for ID: \(userID)")
        // let userProfileCoordinator = UserProfileCoordinator(navigationController: self.navigationController, userID: userID) // Или модально?
        // addChild(userProfileCoordinator)
        // userProfileCoordinator.start() // Start должен инициировать представление (modal/push)
    }
    
    // Метод для показа сообщений
    func showMessages() {
        print("FeedCoordinator: Show messages")
        // TODO: Запустить MessagingCoordinator?
    }
} 