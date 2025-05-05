import UIKit
// Импортируем CommentsViewModel
import FirebaseFirestore

// Добавляем FeedViewControllerDelegate в список протоколов
class FeedCoordinator: Coordinator, FeedViewControllerDelegate {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    // Используем протокол для ссылки на AppCoordinator
    weak var appCoordinator: AppCoordinatorProtocol?

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
         appCoordinator: AppCoordinatorProtocol?) {
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
        // vc.coordinator = self // Удаляем эту строку
        vc.delegate = self // Устанавливаем себя делегатом
        vc.viewModel = viewModel // <-- Передаем ViewModel
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // MARK: - FeedViewControllerDelegate

    // Адаптируем существующий метод под протокол
    func feedViewController(_ controller: FeedViewController, didTapUsername userID: String) {
        print("FeedCoordinator: Show user profile for ID: \(userID)")
        let userProfileCoordinator = UserProfileCoordinator(
            navigationController: self.navigationController,
            userID: userID, // Передаем userID
            userProfileService: userProfileService, // Передаем сервисы
            postService: postService,
            followService: followService,
            progressService: progressService,
            appCoordinator: self.appCoordinator // Передаем AppCoordinator
        )
        childCoordinators.append(userProfileCoordinator)
        userProfileCoordinator.start()
    }
    
    // Добавляем заглушку для комментариев
    func feedViewController(_ controller: FeedViewController, didTapCommentsForPostID postID: String) {
        print("FeedCoordinator: Show comments for post ID: \(postID) - (Not Implemented)")
        // TODO: Реализовать переход к экрану комментариев
        // Например, создать CommentsCoordinator и запустить его:
        // let commentsCoordinator = CommentsCoordinator(navigationController: navigationController, postID: postID)
        // childCoordinators.append(commentsCoordinator)
        // commentsCoordinator.start()
    }

    // Добавляем заглушку для уведомлений
    func feedViewControllerDidTapNotifications(_ controller: FeedViewController) {
        print("FeedCoordinator: Show notifications - (Not Implemented)")
        // TODO: Реализовать переход к экрану уведомлений
    }

    // Добавляем заглушку для сообщений
    func feedViewControllerDidTapMessages(_ controller: FeedViewController) {
        print("FeedCoordinator: Show messages - (Not Implemented)")
        // TODO: Реализовать переход к экрану сообщений
    }

    // НОВЫЙ МЕТОД: Показ экрана комментариев
    @MainActor // Добавляем аннотацию для вызова MainActor-изолированного init
    func showComments(for postId: String) {
        print("FeedCoordinator: Showing comments for post ID: \(postId)")
        /* // Временно комментируем до создания CommentsCoordinator
        let commentsCoordinator = CommentsCoordinator(
            navigationController: navigationController,
            postId: postId,
            postService: postService // Передаем postService
        )
        childCoordinators.append(commentsCoordinator)
        commentsCoordinator.start()
        */
        print("FeedCoordinator: CommentsCoordinator not implemented yet.") // Добавляем лог
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
