import UIKit

class CurrentUserProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // Добавляем зависимости
    private let authService: AuthServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let followService: FollowServiceProtocol
    private let storageService: StorageServiceProtocol

    // Обновляем init
    init(navigationController: UINavigationController, 
         authService: AuthServiceProtocol = AuthService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         postService: PostServiceProtocol = PostService(),
         followService: FollowServiceProtocol = FollowService(),
         storageService: StorageServiceProtocol = StorageService()
         ) {
        self.navigationController = navigationController
        self.authService = authService
        self.userProfileService = userProfileService
        self.postService = postService
        self.followService = followService
        self.storageService = storageService
        // TODO: Настроить стиль Navigation Bar для профиля?
        // Возможно, он будет таким же, как у Feed, или тоже скрыт?
    }

    func start() {
        guard let currentUserID = authService.currentUserID else {
            print("CurrentUserProfileCoordinator Error: Cannot get current user ID. Is user logged in?")
            // TODO: Показать ошибку или перенаправить на Login?
            // Может быть, AppCoordinator не должен был запускать этот координатор, если ID нет.
            return
        }
        
        // Создаем ViewModel
        let viewModel = UserProfileFeedViewModel(
            userID: currentUserID,
            isCurrentUser: true, // Важно!
            userProfileService: userProfileService,
            postService: postService,
            followService: followService
            // StorageService пока не передаем, он может понадобиться внутри VM для загрузки аватара?
        )
        
        let vc = UserProfileFeedViewController()
        // Передаем viewModel в vc
        vc.viewModel = viewModel
        
        // Скрываем Navigation Bar для этого экрана (т.к. есть кастомная шапка в макете)
        // Но можно оставить для заголовка "Profile"?
        navigationController.isNavigationBarHidden = true // Пока скроем
        // vc.title = "Profile" // Если бар видимый
        
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // TODO: Добавить методы для навигации (например, на экран редактирования профиля)
} 