import UIKit

class UserProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    // Добавляем ссылку на AppCoordinator
    weak var appCoordinator: AppCoordinatorProtocol?
    
    // Зависимости
    private let userID: String // ID пользователя, чей профиль показываем
    private let userProfileService: UserProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let followService: FollowServiceProtocol
    // Добавляем ProgressService
    private let progressService: ProgressServiceProtocol

    // Обновляем init - убираем значение по умолчанию для progressService
    init(navigationController: UINavigationController, 
         userID: String,
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         postService: PostServiceProtocol = PostService(),
         followService: FollowServiceProtocol = FollowService(),
         progressService: ProgressServiceProtocol, 
         appCoordinator: AppCoordinatorProtocol?) { 
        self.navigationController = navigationController
        self.userID = userID
        self.userProfileService = userProfileService
        self.postService = postService
        self.followService = followService
        self.progressService = progressService 
        self.appCoordinator = appCoordinator 
    }

    func start() {
        // Создаем контейнер и передаем зависимости
        let vc = UserProfileContainerViewController()
        vc.coordinator = self
        // Передаем userID, progressService и userProfileService
        vc.configure(with: userID, 
                     progressService: progressService, 
                     userProfileService: userProfileService) 
        navigationController.pushViewController(vc, animated: true)
    }
    
    // Добавляем метод для закрытия экрана профиля
    func dismissProfile() {
        print("--- UserProfileCoordinator: Dismiss profile requested ---")
        // Логика закрытия зависит от того, как был представлен контейнер
        // Вариант 1: Если был push в navigationController координатора
        navigationController.popViewController(animated: true)
        // Вариант 2: Если был present модально
        // navigationController.presentingViewController?.dismiss(animated: true, completion: nil)
        // Вариант 3: Если был push в navigationController ИЗ ДРУГОГО координатора (FeedCoordinator)
        // Нужно будет передать управление обратно родительскому координатору
        // parentCoordinator?.didFinishUserProfileFlow(self)
        
        // TODO: Реализовать правильную логику закрытия в зависимости от способа представления
    }

    // Убираем старый метод настройки ...
} 