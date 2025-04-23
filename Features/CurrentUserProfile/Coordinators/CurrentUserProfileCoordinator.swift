import UIKit

// Добавляем соответствие UserProfileFeedViewControllerDelegate
class CurrentUserProfileCoordinator: Coordinator, UserProfileFeedViewControllerDelegate, UserPostScrollViewControllerDelegate {
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
        vc.viewModel = viewModel
        vc.delegate = self // Устанавливаем себя делегатом VC
        
        // Скрываем Navigation Bar для этого экрана (т.к. есть кастомная шапка в макете)
        // Но можно оставить для заголовка "Profile"?
        navigationController.isNavigationBarHidden = true // Пока скроем
        // vc.title = "Profile" // Если бар видимый
        
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // MARK: - UserProfileFeedViewControllerDelegate
    
    func didTapEditProfileButton() {
        print("CurrentUserProfileCoordinator: Edit profile requested")
        // TODO: Реализовать навигацию на экран редактирования
    }
    
    func didTapFollowButton() {
        // Не должно вызываться для CurrentUserProfile
        print("CurrentUserProfileCoordinator Warning: didTapFollowButton called unexpectedly")
    }
    
    func didTapMessageButton() {
        // Не должно вызываться для CurrentUserProfile
        print("CurrentUserProfileCoordinator Warning: didTapMessageButton called unexpectedly")
    }
    
    func didRequestSignOut() {
        print("CurrentUserProfileCoordinator: Sign out requested. Calling AuthService...")
        authService.signOut { [weak self] error in
            if let error = error {
                print("CurrentUserProfileCoordinator Error: Sign out failed: \(error.localizedDescription)")
                // TODO: Показать ошибку пользователю?
            } else {
                print("CurrentUserProfileCoordinator: Sign out successful. AppCoordinator should handle state change.")
                // AppCoordinator должен автоматически переключиться на AuthFlow 
                // из-за изменения authenticationState в AuthService
            }
        }
    }
    
    // TODO: Добавить методы для навигации (например, на экран редактирования профиля)
    
    // MARK: - Post Navigation
    
    func showUserPostScroll(posts: [Post], startIndex: Int) {
        print("CurrentUserProfileCoordinator: showUserPostScroll вызван с \(posts.count) постами, индекс: \(startIndex)")
        
        // Проверка, что массив не пуст
        guard !posts.isEmpty else {
            print("CurrentUserProfileCoordinator: ОШИБКА - массив постов пуст!")
            return
        }
        
        // Проверка, что индекс в пределах массива
        guard startIndex >= 0 && startIndex < posts.count else {
            print("CurrentUserProfileCoordinator: ОШИБКА - индекс \(startIndex) вне границ массива (0...\(posts.count-1))")
            return
        }
        
        // Перед показом следующего экрана делаем Navigation Bar видимым
        navigationController.isNavigationBarHidden = false
        
        let userPostScrollVC = UserPostScrollViewController(posts: posts, startIndex: startIndex)
        userPostScrollVC.delegate = self // Устанавливаем себя в качестве делегата
        print("CurrentUserProfileCoordinator: Переход на UserPostScrollViewController")
        navigationController.pushViewController(userPostScrollVC, animated: true)
    }
    
    // MARK: - UserPostScrollViewControllerDelegate
    
    func didTapUsername(userID: String) {
        print("CurrentUserProfileCoordinator: User profile requested for userID: \(userID)")
        // TODO: Реализовать навигацию на профиль пользователя
    }
} 