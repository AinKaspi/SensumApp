import UIKit
// Удаляем некорректные импорты
// import Features.Feed.ViewModels
// import Features.Feed.Scenes

// Добавляем соответствие UserProfileFeedViewControllerDelegate и EditProfileViewControllerDelegate
// Добавляем EditProfileViewModelDelegate
class CurrentUserProfileCoordinator: Coordinator, UserProfileFeedViewControllerDelegate, EditProfileViewControllerDelegate, EditProfileViewModelDelegate/*, UserPostScrollViewControllerDelegate*/ {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // Добавляем зависимости
    private let authService: AuthServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let followService: FollowServiceProtocol
    private let storageService: StorageServiceProtocol
    // Добавляем ProgressService, т.к. он может понадобиться для дочерних VM
    private let progressService: ProgressServiceProtocol

    // Обновляем init
    init(navigationController: UINavigationController,
         authService: AuthServiceProtocol = AuthService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         postService: PostServiceProtocol = PostService(),
         followService: FollowServiceProtocol = FollowService(),
         storageService: StorageServiceProtocol = StorageService(),
         progressService: ProgressServiceProtocol = ProgressService() // Добавляем ProgressService
         ) {
        self.navigationController = navigationController
        self.authService = authService
        self.userProfileService = userProfileService
        self.postService = postService
        self.followService = followService
        self.storageService = storageService
        self.progressService = progressService // Сохраняем
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
        
        // Создаем ViewModel (передаем все зависимости)
        let viewModel = UserProfileFeedViewModel(
            userID: currentUserID,
            isCurrentUser: true, // Важно!
            userProfileService: userProfileService,
            postService: postService,
            followService: followService,
            progressService: progressService // Передаем ProgressService
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
        showEditProfile()
    }
    
    func didTapFollowButton() {
        print("CurrentUserProfileCoordinator Warning: didTapFollowButton called unexpectedly")
    }
    
    func didTapMessageButton() {
        print("CurrentUserProfileCoordinator Warning: didTapMessageButton called unexpectedly")
    }
    
    func didRequestSignOut() {
        print("CurrentUserProfileCoordinator: Sign out requested. Calling AuthService...")
        authService.signOut { [weak self] error in
            if let error = error {
                print("CurrentUserProfileCoordinator Error: Sign out failed: \(error.localizedDescription)")
            } else {
                print("CurrentUserProfileCoordinator: Sign out successful. AppCoordinator should handle state change.")
            }
        }
    }
    
    // Добавляем реализацию нового метода делегата
    func didTapNewProgramButton() {
        print("CurrentUserProfileCoordinator: New program requested - Navigation Placeholder")
        // TODO: Реализовать навигацию на экран создания программы ([P3.PRG.4])
    }
    
    // MARK: - Navigation

    func showEditProfile() {
        print("CurrentUserProfileCoordinator: Showing Edit Profile screen.")
        // Создаем ViewModel, передавая необходимые сервисы
        let viewModel = EditProfileViewModel(
            authService: authService,
            userProfileService: userProfileService,
            storageService: storageService
        )
        viewModel.delegate = self // Назначаем себя делегатом ViewModel

        // Создаем ViewController
        let vc = EditProfileViewController()
        // Раскомментируем инъекцию ViewModel
        vc.viewModel = viewModel
        vc.delegate = self // Назначаем себя делегатом ViewController

        // Показываем экран (например, push)
        // Сначала сделаем Navigation Bar видимым для экрана редактирования
        navigationController.isNavigationBarHidden = false
        navigationController.pushViewController(vc, animated: true)
    }
    
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
        
        // TODO: Раскомментировать и реализовать UserPostScrollViewController
        /*
        let userPostScrollVC = UserPostScrollViewController(posts: posts, startIndex: startIndex)
        userPostScrollVC.delegate = self // Устанавливаем себя в качестве делегата
        print("CurrentUserProfileCoordinator: Переход на UserPostScrollViewController")
        navigationController.pushViewController(userPostScrollVC, animated: true)
        */
        print("CurrentUserProfileCoordinator: Навигация на UserPostScrollViewController закомментирована.")
    }
    
    // MARK: - EditProfileViewControllerDelegate
    
    func editProfileDidFinish(didSave: Bool) {
        print("CurrentUserProfileCoordinator: Edit profile finished. Did save: \(didSave)")
        // Просто закрываем экран редактирования (возвращаемся назад)
        navigationController.popViewController(animated: true)
        // Делаем Navigation Bar снова скрытым для экрана профиля
        navigationController.isNavigationBarHidden = true
        // TODO: Если сохранили (didSave = true), нужно ли обновить данные на экране профиля?
        // Можно вызвать viewModel.fetchAllUserData() у UserProfileFeedViewController,
        // но нужно получить на него ссылку.
    }
    
    // MARK: - UserPostScrollViewControllerDelegate (Закомментировано)
    // Раскомментируем делегат и его методы
    /* // Убираем начало комментария
    func didTapUsername(userID: String) {
        print("CurrentUserProfileCoordinator: User profile requested for userID: \(userID)")
        // TODO: Реализовать навигацию на профиль пользователя
    }
    
    @MainActor // Добавляем MainActor для инициализации CommentsViewModel
    func didTapCommentsButton(forPostID postID: String) {
        print("CurrentUserProfileCoordinator: Comments requested for post ID: \(postID)")
        // Раскомментируем создание CommentsViewModel и CommentsViewController
        let viewModel = CommentsViewModel(postId: postID, postService: postService) // Используем имеющийся PostService
        let commentsVC = CommentsViewController(postId: postID, viewModel: viewModel)
        commentsVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(commentsVC, animated: true)
        // print("CurrentUserProfileCoordinator: Навигация на CommentsViewController закомментирована.") // Удаляем лог
    }
    */ // Убираем конец комментария
}
