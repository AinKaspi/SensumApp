import UIKit
// Импортируем CommentsViewModel
import FirebaseFirestore

class FeedCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    // Добавляем ссылку на AppCoordinator
    weak var appCoordinator: AppCoordinator?

    // Добавляем зависимости для VM
    private let postService: PostServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let followService: FollowServiceProtocol
    private let progressService: ProgressServiceProtocol
    
    init(navigationController: UINavigationController, 
         postService: PostServiceProtocol = PostService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         followService: FollowServiceProtocol = FollowService(),
         progressService: ProgressServiceProtocol,
         appCoordinator: AppCoordinator?) {
        self.navigationController = navigationController
        self.postService = postService
        self.userProfileService = userProfileService
        self.followService = followService
        self.progressService = progressService
        self.appCoordinator = appCoordinator
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
        print("FeedCoordinator: Show user profile for ID: \(userID)")
        let userProfileCoordinator = UserProfileCoordinator(
            navigationController: self.navigationController,
            userID: userID,
            userProfileService: userProfileService,
            postService: postService,
            followService: followService,
            progressService: progressService
        )
        userProfileCoordinator.start()
    }
    
    // НОВЫЙ МЕТОД: Показ экрана комментариев
    @MainActor // Добавляем аннотацию для вызова MainActor-изолированного init
    func showComments(for postId: String) {
        print("FeedCoordinator: Show comments for post ID: \(postId)")
        let viewModel = CommentsViewModel(postId: postId, postService: postService)
        let vc = CommentsViewController(postId: postId, viewModel: viewModel) 
        vc.hidesBottomBarWhenPushed = true // Скрываем TabBar
        navigationController.pushViewController(vc, animated: true)
    }
    
    // Метод для показа сообщений
    func showMessages() {
        print("FeedCoordinator: Requesting AppCoordinator to show messages")
        // TODO: Вызвать appCoordinator?.showMessages()
    }
    
    func showNotifications() {
        print("FeedCoordinator: Requesting AppCoordinator to show notifications")
        appCoordinator?.showNotifications()
    }
} 
