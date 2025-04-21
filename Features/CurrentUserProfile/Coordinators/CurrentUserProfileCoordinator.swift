import UIKit

class CurrentUserProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // TODO: Настроить стиль Navigation Bar для профиля?
        // Возможно, он будет таким же, как у Feed, или тоже скрыт?
    }

    func start() {
        // Здесь мы будем использовать UserProfileFeedViewController
        // Нужно передать ID текущего пользователя
        let currentUserID = "USER_ID_PLACEHOLDER" // TODO: Получить реальный ID из AuthService
        
        // Создаем VC напрямую, без контейнера пока?
        let vc = UserProfileFeedViewController()
        // TODO: Передать ViewModel, сконфигурированную с currentUserID и флагом isCurrentUser
        // vc.viewModel = UserProfileFeedViewModel(userID: currentUserID, isCurrentUser: true)
        
        // Можно добавить заголовок, если Navigation Bar будет видимым
        // vc.title = "Profile"
        
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // TODO: Добавить методы для навигации (например, на экран редактирования профиля)
} 