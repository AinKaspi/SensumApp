//
//  SceneDelegate.swift
//  SensumApp
//
//  Created by Ain on 07/04/2025.
//

import UIKit
import MediaPipeTasksVision
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let container = DIContainer()
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { 
            return 
        }
        
        let window = UIWindow(windowScene: windowScene)
        
        appCoordinator = AppCoordinator(window: window, container: container)
        appCoordinator?.start()

        self.window = window
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

// ----- Протокол для Главного Координатора -----
protocol AppCoordinatorProtocol: AnyObject {
    func showNotifications()
    // Добавьте сюда другие методы, которые должны быть доступны дочерним координаторам
}

// ----- Главный Координатор Приложения -----
class AppCoordinator: Coordinator, AuthCoordinatorDelegate, AppCoordinatorProtocol {
    
    var window: UIWindow
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    private let container: DIContainer
    private var authService: AuthServiceProtocol { container.authService }
    private var userProfileService: UserProfileServiceProtocol { container.userProfileService }
    private var postService: PostServiceProtocol { container.postService }
    private var followService: FollowServiceProtocol { container.followService }
    private var storageService: StorageServiceProtocol { container.storageService }
    private var progressService: ProgressServiceProtocol { container.progressService }
    
    private var authCoordinator: AuthCoordinator?
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, container: DIContainer) {
        self.window = window
        self.container = container
        self.navigationController = UINavigationController()
        setupAuthenticationSubscription()
    }

    func start() {
        authService.checkAuthenticationState()
        window.makeKeyAndVisible()
        window.backgroundColor = .black 
    }
    
    private func setupAuthenticationSubscription() {
        authService.authenticationState
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                print("AppCoordinator: Received auth state: \(state)")
                switch state {
                case .signedIn:
                    self.showMainAppFlow()
                case .signedOut, .unknown:
                    if self.authCoordinator == nil {
                        self.showAuthenticationFlow()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func showMainAppFlow() {
        if let authCoordinator = authCoordinator {
            removeChild(authCoordinator)
            self.authCoordinator = nil
            print("AppCoordinator: Removed AuthCoordinator")
        }
        
        if window.rootViewController is UITabBarController {
            print("AppCoordinator: Main flow (TabBar) already presented.")
            return
        }
        
        print("AppCoordinator: Setting up Main flow (TabBar)...")
        let tabBarController = UITabBarController()
        
        // 1. Feed Coordinator
        let feedNavController = UINavigationController()
        let feedCoordinator = FeedCoordinator(
            navigationController: feedNavController,
            postService: postService,
            userProfileService: userProfileService,
            followService: followService,
            progressService: progressService,
            appCoordinator: self as AppCoordinatorProtocol
        )
        addChild(feedCoordinator)
        feedCoordinator.start()
        feedNavController.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(systemName: "flame.fill"), tag: 0)

        // 2. Current User Profile Coordinator
        let profileNavController = UINavigationController()
        let currentUserProfileCoordinator = CurrentUserProfileCoordinator(
            navigationController: profileNavController,
            authService: authService,
            userProfileService: userProfileService,
            postService: postService,
            followService: followService,
            storageService: storageService,
            progressService: progressService
        )
        addChild(currentUserProfileCoordinator)
        currentUserProfileCoordinator.start()
        profileNavController.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 1)
        
        // 3. Leveling Coordinator
        let levelingNavController = UINavigationController()
        let levelingCoordinator = LevelingCoordinator(
            navigationController: levelingNavController,
            authService: authService,
            progressService: progressService
        )
        addChild(levelingCoordinator)
        levelingCoordinator.start()
        levelingNavController.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2)

        // 4. Progress Coordinator
        let progressNavController = UINavigationController()
        let progressCoordinator = ProgressCoordinator(
            navigationController: progressNavController,
            authService: authService,
            progressService: progressService
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

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        window.backgroundColor = .black
    }
    
    private func showAuthenticationFlow() {
        if authCoordinator != nil, window.rootViewController === authCoordinator?.navigationController {
             print("AppCoordinator: Auth flow already presented.")
            return
        }
        
        print("AppCoordinator: Setting up Auth flow...")
        childCoordinators.removeAll()
        
        let authNavController = UINavigationController()
        authCoordinator = AuthCoordinator(
            navigationController: authNavController,
            authService: authService,
            progressService: progressService
        )
        authCoordinator?.delegate = self
        addChild(authCoordinator!)
        authCoordinator?.start()
        
        window.rootViewController = authNavController
    }
    
    // MARK: - AuthCoordinatorDelegate
    
    // Вызывается, когда AuthCoordinator завершает работу (пользователь вошел)
    func didFinishAuthentication(coordinator: AuthCoordinator) {
        print("AppCoordinator: Auth flow finished notification received.")
    }
    
    // MARK: - Public Navigation Triggers
    
    // Метод для показа экрана уведомлений (вызывается из других координаторов)
    func showNotifications() {
        print("AppCoordinator: Showing Notifications screen...")
        // Создаем отдельный Navigation Controller для модального показа
        let notificationsNavController = UINavigationController()
        // TODO: Передать зависимости в NotificationsCoordinator, если нужны
        let notificationsCoordinator = NotificationsCoordinator(navigationController: notificationsNavController)
        // Добавляем в дочерние, чтобы управлять им?
        // addChild(notificationsCoordinator) 
        notificationsCoordinator.start() // Start покажет VC
        
        // Показываем модально
        if let rootVC = window.rootViewController {
             // Настройка внешнего вида модального окна (опционально)
             notificationsNavController.modalPresentationStyle = .pageSheet // или .formSheet, .fullScreen
             if let sheet = notificationsNavController.sheetPresentationController {
                 // Настройка sheet (iOS 15+)
                 sheet.detents = [.large()] // Можно добавить .medium()
                 sheet.prefersGrabberVisible = true
             }
             rootVC.present(notificationsNavController, animated: true, completion: nil)
         } else {
             print("AppCoordinator Error: RootViewController not found to present notifications.")
         }
    }
}

// ----- Координаторы-заглушки (Events/Rank удалены, остальные используются) -----
// class EventsCoordinator: Coordinator { ... }
// class RankCoordinator: Coordinator { ... }

// LevelingCoordinator, StoreCoordinator теперь реальные координаторы в своих папках
