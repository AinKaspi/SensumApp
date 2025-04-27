//
//  SceneDelegate.swift
//  SensumApp
//
//  Created by Ain on 07/04/2025.
//

import UIKit
import MediaPipeTasksVision
import Combine // Добавляем Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator? // Добавляем свойство для главного координатора

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        
        // Первое, получаем "сцену" - это как бы экран, на котором всё будет происходить.
        guard let windowScene = (scene as? UIWindowScene) else { 
            return 
        }
        
        // Создаем самое ГЛАВНОЕ ОКНО для нашего приложения.
        let window = UIWindow(windowScene: windowScene)
        
        // Создаем главный координатор и запускаем его
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()

        // Устанавливаем фон окна в желтый для отладки
        window.backgroundColor = .systemYellow 

        // Сохраняем ссылку на это окно, чтобы оно не пропало.
        self.window = window

        // Делаем окно видимым на экране телефона.
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}

// ----- Главный Координатор Приложения -----
// Добавляем соответствие AuthCoordinatorDelegate
class AppCoordinator: Coordinator, AuthCoordinatorDelegate {
    
    var window: UIWindow
    var navigationController: UINavigationController // Не используется для TabBar
    var childCoordinators: [Coordinator] = []
    
    // Добавляем AuthService
    private let authService: AuthServiceProtocol = AuthService()
    
    // Храним ссылку на AuthCoordinator, если он активен
    private var authCoordinator: AuthCoordinator?
    private var cancellables = Set<AnyCancellable>() // Для подписки

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController() // Заглушка для протокола
        setupAuthenticationSubscription() // Подписываемся СРАЗУ
    }

    func start() {
        // Просто вызываем проверку начального состояния
        // Подписка сама решит, какой flow показать
        authService.checkAuthenticationState()
        window.makeKeyAndVisible()
        window.backgroundColor = .black 
    }
    
    // Настраиваем подписку на состояние аутентификации
    private func setupAuthenticationSubscription() {
        authService.authenticationState
            .receive(on: DispatchQueue.main) // Переключаем на главный поток для UI
            // Убираем дублирующиеся значения (чтобы не переключать флоу лишний раз)
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                print("AppCoordinator: Received auth state: \(state)")
                switch state {
                case .signedIn:
                    self.showMainAppFlow()
                case .signedOut, .unknown:
                    // Показываем флоу аутентификации, только если он еще не показан
                    // (чтобы избежать зацикливания при выходе)
                    if self.authCoordinator == nil {
                        self.showAuthenticationFlow()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Показывает основной TabBar интерфейс
    private func showMainAppFlow() {
        // Убираем AuthCoordinator, если он был
        if let authCoordinator = authCoordinator {
            removeChild(authCoordinator)
            self.authCoordinator = nil
            print("AppCoordinator: Removed AuthCoordinator")
        }
        
        // Проверяем, не показываем ли мы уже TabBar
        if window.rootViewController is UITabBarController {
            print("AppCoordinator: Main flow (TabBar) already presented.")
            return
        }
        
        print("AppCoordinator: Setting up Main flow (TabBar)...")
        // --- Код создания TabBarController ---
        let tabBarController = UITabBarController()
        
        // 1. Feed Coordinator
        let feedNavController = UINavigationController()
        let feedCoordinator = FeedCoordinator(navigationController: feedNavController, postService: PostService())
        addChild(feedCoordinator)
        feedCoordinator.start()
        feedNavController.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(systemName: "flame.fill"), tag: 0)

        // 2. Current User Profile Coordinator
        let profileNavController = UINavigationController()
        let currentUserProfileCoordinator = CurrentUserProfileCoordinator(
            navigationController: profileNavController,
            authService: authService,
            userProfileService: UserProfileService(),
            postService: PostService(),
            followService: FollowService(),
            storageService: StorageService(),
            progressService: ProgressService()
        )
        addChild(currentUserProfileCoordinator)
        currentUserProfileCoordinator.start()
        profileNavController.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 1)
        
        // 3. Leveling Coordinator
        let levelingNavController = UINavigationController()
        let levelingCoordinator = LevelingCoordinator(navigationController: levelingNavController)
        addChild(levelingCoordinator)
        levelingCoordinator.start()
        levelingNavController.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2)

        // 4. Progress Coordinator
        let progressNavController = UINavigationController()
        let progressCoordinator = ProgressCoordinator(
            navigationController: progressNavController,
            authService: authService,
            progressService: ProgressService()
        )
        addChild(progressCoordinator)
        progressCoordinator.start()
        progressNavController.tabBarItem = UITabBarItem(title: "Progress", image: UIImage(systemName: "chart.bar.fill"), tag: 3)
        
        // 5. Store Coordinator
        let storeNavController = UINavigationController()
        let storeCoordinator = StoreCoordinator(navigationController: storeNavController)
        addChild(storeCoordinator)
        storeCoordinator.start()
        storeNavController.tabBarItem = UITabBarItem(title: "Store", image: UIImage(systemName: "cart.fill"), tag: 4)
        
        tabBarController.viewControllers = [
            feedNavController,
            profileNavController,
            levelingNavController,
            progressNavController,
            storeNavController
        ]
        
        // Настройка внешнего вида TabBar (оставляем)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .lightGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
        itemAppearance.selected.iconColor = .white
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        // --- Конец кода создания TabBarController ---

        // Устанавливаем TabBarController как корневой
        window.rootViewController = tabBarController
        window.makeKeyAndVisible() // Делаем видимым
        window.backgroundColor = .black
    }
    
    // Показывает флоу аутентификации
    private func showAuthenticationFlow() {
        // Проверяем, не показываем ли мы уже Auth флоу
        if authCoordinator != nil, window.rootViewController === authCoordinator?.navigationController {
             print("AppCoordinator: Auth flow already presented.")
            return
        }
        
        print("AppCoordinator: Setting up Auth flow...")
        // Убираем старые дочерние координаторы таббара
        childCoordinators.removeAll()
        
        let authNavController = UINavigationController()
        authCoordinator = AuthCoordinator(navigationController: authNavController, authService: authService)
        authCoordinator?.delegate = self
        addChild(authCoordinator!)
        authCoordinator?.start()
        
        window.rootViewController = authNavController
    }
    
    // MARK: - AuthCoordinatorDelegate
    
    // Вызывается, когда AuthCoordinator завершает работу (пользователь вошел)
    func didFinishAuthentication(coordinator: AuthCoordinator) {
        print("AppCoordinator: Auth flow finished notification received.")
        // AuthService уже должен был переключить состояние на .signedIn,
        // подписка в setupAuthenticationSubscription должна вызвать showMainAppFlow()
        // Не нужно вызывать showMainAppFlow() прямо отсюда, чтобы избежать двойного вызова.
    }
}

// ----- Координаторы-заглушки (Events/Rank удалены, остальные используются) -----
// class EventsCoordinator: Coordinator { ... }
// class RankCoordinator: Coordinator { ... }

// LevelingCoordinator, StoreCoordinator теперь реальные координаторы в своих папках

