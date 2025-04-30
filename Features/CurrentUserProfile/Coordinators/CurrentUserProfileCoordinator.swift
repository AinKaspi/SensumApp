import UIKit
import AVFoundation // Добавляем для AVAsset
// Удаляем некорректные импорты
// import Features.Feed.ViewModels
// import Features.Feed.Scenes

// Добавляем соответствие UserProfileFeedViewControllerDelegate и EditProfileViewControllerDelegate
// Добавляем EditProfileViewModelDelegate
// Раскомментируем UserPostScrollViewControllerDelegate
// Удаляем CreatePostViewControllerDelegate, добавляем PostMediaSelectionDelegate и PostCropViewControllerDelegate
// Добавляем PostReviewViewControllerDelegate
class CurrentUserProfileCoordinator: Coordinator, UserProfileFeedViewControllerDelegate, EditProfileViewControllerDelegate, EditProfileViewModelDelegate, UserPostScrollViewControllerDelegate, PostMediaSelectionDelegate, PostCropViewControllerDelegate, PostReviewViewControllerDelegate {
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
         progressService: ProgressServiceProtocol) {
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

    // 1. Переименовываем showCreatePost в showPostMediaSelection
    // Он будет показывать первый экран нового флоу
    func showPostMediaSelection(with mediaItems: [MediaItem]) {
        print("➡️ Coordinator: Showing Post Media Selection screen with \(mediaItems.count) items.")
        guard !mediaItems.isEmpty else {
            print("❌ Coordinator Error: Cannot show Post Media Selection screen with empty media items.")
            // TODO: Показать алерт пользователю?
            return
        }

        // Создаем ViewController
        let vc = PostMediaSelectionViewController(media: mediaItems)
        // TODO: Установить делегата (vc.delegate = self), когда протокол будет определен
        vc.delegate = self
        
        // Показываем экран (push в текущий стек)
        navigationController.isNavigationBarHidden = false // Показываем навбар для этого флоу
        navigationController.pushViewController(vc, animated: true)
    }
    
    // 2. Добавляем showPostCrop
    func showPostCrop(item: EditableMediaItem, aspectRatio: PostAspectRatio /*, delegate: PostCropViewControllerDelegate */) {
        print("✂️ Coordinator: Showing Post Crop screen for item \(item.id).")
        let vc = PostCropViewController(item: item, aspectRatio: aspectRatio)
        // TODO: Установить делегата (vc.delegate = delegate), когда протокол будет определен
        vc.delegate = self // Устанавливаем координатор делегатом для PostCropVC
        
        // Представляем модально в новом NavigationController для своего навбара
        let cropNavController = UINavigationController(rootViewController: vc)
        cropNavController.modalPresentationStyle = .fullScreen
        navigationController.present(cropNavController, animated: true)
    }
    
    // 3. Добавляем showPostReview
    func showPostReview(items: [EditableMediaItem], aspectRatio: PostAspectRatio) {
         print("✍️ Coordinator: Showing Post Review screen with \(items.count) items.")
         guard !items.isEmpty else {
             print("❌ Coordinator Error: Cannot show Post Review screen with empty items.")
             return
         }
         
         // Создаем ViewController
         // Он сам создаст ViewModel
         let vc = PostReviewViewController(items: items, aspectRatio: aspectRatio)
         // TODO: Установить делегата для обработки закрытия?
         vc.delegate = self // <-- Устанавливаем делегата
         
         // Показываем экран (push)
         navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - Post Navigation
    
    func showUserPostScroll(posts: [Post], startIndex: Int) {
        print("CurrentUserProfileCoordinator: showUserPostScroll вызван с \(posts.count) постами, индекс: \(startIndex)")
        
        guard !posts.isEmpty else {
            print("CurrentUserProfileCoordinator: ОШИБКА - массив постов пуст!")
            return
        }
        
        guard startIndex >= 0 && startIndex < posts.count else {
            print("CurrentUserProfileCoordinator: ОШИБКА - индекс \(startIndex) вне границ массива (0...\(posts.count-1))")
            return
        }
        
        navigationController.isNavigationBarHidden = false
        
        // Создаем ViewModel для UserPostScroll
        // TODO: Передать lastDocumentSnapshot, если он доступен после загрузки сетки?
        // Пока передаем nil, пагинация начнется с начала при необходимости.
        let userPostScrollViewModel = UserPostScrollViewModel(
            userID: posts[0].userID, // Берем userID из первого поста (они все от одного юзера)
            initialPosts: posts,
            initialSnapshot: nil, // TODO: Передать?
            postService: postService, // Передаем сервисы
            authService: authService
        )
        
        // Создаем и показываем ViewController
        let userPostScrollVC = UserPostScrollViewController(viewModel: userPostScrollViewModel, startIndex: startIndex)
        userPostScrollVC.delegate = self // Устанавливаем себя в качестве делегата
        print("CurrentUserProfileCoordinator: Переход на UserPostScrollViewController")
        navigationController.pushViewController(userPostScrollVC, animated: true)
        // print("CurrentUserProfileCoordinator: Навигация на UserPostScrollViewController закомментирована.") // Удаляем
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
    // Восстанавливаем объявление соответствия UserPostScrollViewControllerDelegate
    // Убираем комментарии
    func didTapUsername(userID: String) {
        print("CurrentUserProfileCoordinator: User profile requested for userID: \(userID)")
        // TODO: Реализовать навигацию на профиль пользователя (возможно, через AppCoordinator?)
        // showUserProfile(userID: userID) // Рекурсия!
    }
    
    @MainActor // Добавляем MainActor для инициализации CommentsViewModel
    func didTapCommentsButton(forPostID postID: String) {
        print("CurrentUserProfileCoordinator: Comments requested for post ID: \(postID)")
        // Раскомментируем создание CommentsViewModel и CommentsViewController
        let viewModel = CommentsViewModel(postId: postID, postService: postService) // Используем имеющийся PostService
        let commentsVC = CommentsViewController(postId: postID, viewModel: viewModel) 
        commentsVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(commentsVC, animated: true)
    }

    // Удаляем реализацию CreatePostViewControllerDelegate
    /*
    // MARK: - CreatePostViewControllerDelegate

    func didFinishCreatingPost(_ controller: CreatePostViewController) {
        print("CurrentUserProfileCoordinator: Create Post finished successfully.")
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Обновляем профиль и ленту после создания поста
            print("CurrentUserProfileCoordinator: Updating profile and feed after post creation")
            
            // 1. Отправляем уведомление для обновления ленты и профиля
            // Это вызовет обновление данных во всех подписанных ViewModel
            NotificationCenter.default.post(name: .didCreateNewPost, object: nil)
            print("CurrentUserProfileCoordinator: Notification .didCreateNewPost posted")
            
            // 2. Для надежности явно обновляем данные профиля текущего пользователя
            // через первый экран в стеке навигации
            if let profileVC = self.navigationController.viewControllers.first(where: { $0 is UserProfileFeedViewController }) as? UserProfileFeedViewController {
                print("CurrentUserProfileCoordinator: Explicitly triggering fetchAllUserData()")
                profileVC.viewModel.fetchAllUserData()
                
                // 3. Принудительно перезагружаем коллекцию с небольшой задержкой, чтобы данные успели загрузиться
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("CurrentUserProfileCoordinator: Forcing collectionView reload")
                    profileVC.postsCollectionView.reloadData()
                }
            } else {
                print("CurrentUserProfileCoordinator: Warning - couldn't find UserProfileFeedViewController in navigation stack")
            }
            
            print("CurrentUserProfileCoordinator: Create Post controller dismissed.")
        }
    }
    
    func didCancelCreatingPost(_ controller: CreatePostViewController) {
         print("CurrentUserProfileCoordinator: Create Post cancelled.")
         controller.dismiss(animated: true)
     }
    */
     
     // TODO: Реализовать методы делегатов PostMediaSelectionDelegate и PostCropViewControllerDelegate
     // func postMediaSelectionDidTapNext(items: [EditableMediaItem], aspectRatio: PostAspectRatio) { ... }
     // func postMediaSelectionDidCancel() { ... }
     // func postCropDidFinish(item: EditableMediaItem) { ... }

    // MARK: - PostMediaSelectionDelegate
    
    func postMediaSelectionDidTapNext(items: [EditableMediaItem], aspectRatio: PostAspectRatio) {
        // Переходим к экрану ревью
        showPostReview(items: items, aspectRatio: aspectRatio)
    }

    func postMediaSelectionDidTapItem(at index: Int, currentItems: [EditableMediaItem], aspectRatio: PostAspectRatio) {
        guard index >= 0 && index < currentItems.count else { return }
        let itemToCrop = currentItems[index]
        // Переходим к экрану кропа для выбранного элемента
        showPostCrop(item: itemToCrop, aspectRatio: aspectRatio)
    }

    func postMediaSelectionDidCancel() {
        // Закрываем экран выбора формата (возвращаемся к профилю)
        navigationController.popViewController(animated: true)
        navigationController.isNavigationBarHidden = true // Скрываем навбар снова
    }

    // MARK: - PostCropViewControllerDelegate

    func postCropDidFinish(item: EditableMediaItem) {
        // Закрываем модальный экран кропа
        navigationController.dismiss(animated: true) { [weak self] in
            // Находим PostMediaSelectionViewController в стеке навигации
            if let selectionVC = self?.navigationController.viewControllers.last as? PostMediaSelectionViewController {
                // Находим индекс обновленного элемента (по ID)
                if let updatedIndex = selectionVC.editableMedia.firstIndex(where: { $0.id == item.id }) {
                    // Обновляем элемент в массиве selectionVC
                    selectionVC.updateEditableItem(at: updatedIndex, with: item)
                    print("✅ Coordinator: Updated item at index \(updatedIndex) after cropping.")
                }
            }
        }
    }
    
    func postCropDidCancel() {
        // Просто закрываем модальный экран кропа
        navigationController.dismiss(animated: true)
    }

    // MARK: - PostReviewViewControllerDelegate
    
    func postReviewDidFinishSuccessfully() {
        print("✅ Coordinator: Post review finished successfully. Navigating back to profile.")
        // Возвращаемся к корневому контроллеру (UserProfileFeedViewController)
        navigationController.popToRootViewController(animated: true)
        // Снова скрываем навбар для экрана профиля
        navigationController.isNavigationBarHidden = true
        
        // Опционально: Обновить данные профиля после публикации
        // Можно отправить NotificationCenter.default.post(name: .didCreateNewPost, object: nil)
        // Или получить ссылку на VC и вызвать обновление явно, как это делалось раньше
        if let profileVC = navigationController.viewControllers.first as? UserProfileFeedViewController {
            print("Coordinator: Triggering profile refresh after successful post.")
            profileVC.viewModel?.fetchAllUserData() // Вызываем обновление данных
        } else {
            print("Coordinator: Warning - Could not find UserProfileFeedViewController to refresh.")
        }
    }

}
