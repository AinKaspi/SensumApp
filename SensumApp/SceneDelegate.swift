//
//  SceneDelegate.swift
//  SensumApp
//
//  Created by Ain on 07/04/2025.
//

import UIKit
import MediaPipeTasksVision

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
class AppCoordinator: Coordinator {
    
    var window: UIWindow
    var navigationController: UINavigationController // Не используется для TabBar
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController() // Заглушка для протокола
        // TODO: Добавить проверку статуса аутентификации. Если не вошел - запускать AuthCoordinator.
    }

    func start() {
        // Создаем TabBarController
        let tabBarController = UITabBarController()
        
        // --- Создаем и настраиваем координаторы для каждой вкладки ---
        
        // 1. Feed Coordinator (Tab 1)
        let feedNavController = UINavigationController()
        let feedCoordinator = FeedCoordinator(navigationController: feedNavController)
        addChild(feedCoordinator)
        feedCoordinator.start()
        feedNavController.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(systemName: "flame.fill"), tag: 0) // Иконка Огонь

        // 2. Current User Profile Coordinator (Tab 2)
        let profileNavController = UINavigationController()
        let currentUserProfileCoordinator = CurrentUserProfileCoordinator(navigationController: profileNavController)
        addChild(currentUserProfileCoordinator)
        currentUserProfileCoordinator.start()
        profileNavController.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 1) // Иконка Человек
        
        // 3. Leveling Coordinator (Tab 3)
        let levelingNavController = UINavigationController()
        let levelingCoordinator = LevelingCoordinator(navigationController: levelingNavController)
        addChild(levelingCoordinator)
        levelingCoordinator.start()
        // Используем кастомную иконку? Пока оставим системную.
        levelingNavController.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2) // Нужна иконка Круг?
        // TODO: Настроить внешний вид центральной кнопки таббара?

        // 4. Progress Coordinator (Tab 4)
        let progressNavController = UINavigationController()
        let progressCoordinator = ProgressCoordinator(navigationController: progressNavController)
        addChild(progressCoordinator)
        progressCoordinator.start()
        progressNavController.tabBarItem = UITabBarItem(title: "Progress", image: UIImage(systemName: "chart.bar.fill"), tag: 3) // Иконка Столбцы
        
        // 5. Store Coordinator (Tab 5)
        let storeNavController = UINavigationController()
        let storeCoordinator = StoreCoordinator(navigationController: storeNavController)
        addChild(storeCoordinator)
        storeCoordinator.start()
        storeNavController.tabBarItem = UITabBarItem(title: "Store", image: UIImage(systemName: "cart.fill"), tag: 4) // Иконка Корзина
        
        // --- Собираем TabBarController ---
        tabBarController.viewControllers = [
            feedNavController,
            profileNavController,
            levelingNavController,
            progressNavController,
            storeNavController
        ]
        
        // Настраиваем внешний вид TabBar (оставляем как было)
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

        // Устанавливаем TabBarController как корневой
        window.rootViewController = tabBarController
        // Убираем желтый фон окна
        window.backgroundColor = .black 
    }
}

// ----- Координаторы-заглушки (Events/Rank удалены, остальные используются) -----
// class EventsCoordinator: Coordinator { ... }
// class RankCoordinator: Coordinator { ... }

// LevelingCoordinator, StoreCoordinator теперь реальные координаторы в своих папках

