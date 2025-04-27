import UIKit
// Импортируем CommentsViewModel

class FeedCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // Добавляем зависимости для VM
    private let postService: PostServiceProtocol
    
    init(navigationController: UINavigationController, 
         postService: PostServiceProtocol = PostService()) {
        self.navigationController = navigationController
        self.postService = postService
        // TODO: Настроить внешний вид Navigation Bar для ленты? Или он будет скрыт?
    }

    func start() {
        // Создаем ViewModel
        let viewModel = FeedViewModel(postService: postService)
        
        let vc = FeedViewController()
        vc.coordinator = self // Передаем себя для навигации (например, на профиль юзера)
        vc.viewModel = viewModel // <-- Передаем ViewModel
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
    
    // НОВЫЙ МЕТОД: Показ экрана комментариев
    @MainActor // Добавляем аннотацию для вызова MainActor-изолированного init
    func showComments(for postId: String) {
        print("FeedCoordinator: Show comments for post ID: \(postId)")
        // Раскомментируем создание ViewModel и ViewController
        let viewModel = CommentsViewModel(postId: postId, postService: postService) // Передаем зависимости
        let vc = CommentsViewController(postId: postId, viewModel: viewModel) 
        vc.hidesBottomBarWhenPushed = true // Скрываем TabBar
        navigationController.pushViewController(vc, animated: true)
    }
    
    // Метод для показа сообщений
    func showMessages() {
        print("FeedCoordinator: Show messages")
        // TODO: Запустить MessagingCoordinator?
    }
} 
