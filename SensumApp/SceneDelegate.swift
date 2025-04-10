//
//  SceneDelegate.swift
//  SensumApp
//
//  Created by Ain on 07/04/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator? // Добавляем свойство для главного координатора

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        print("--- SceneDelegate: scene(_:willConnectTo:options:) CALLED ---")
        
        // Первое, получаем "сцену" - это как бы экран, на котором всё будет происходить.
        guard let windowScene = (scene as? UIWindowScene) else { 
            print("--- SceneDelegate: FAILED to get windowScene ---")
            return 
        }
        print("--- SceneDelegate: Got windowScene ---")
        
        // Создаем самое ГЛАВНОЕ ОКНО для нашего приложения.
        let window = UIWindow(windowScene: windowScene)
        print("--- SceneDelegate: Created UIWindow ---")
        
        // Создаем главный координатор и запускаем его
        appCoordinator = AppCoordinator(window: window)
        print("--- SceneDelegate: Created AppCoordinator ---")
        appCoordinator?.start()
        print("--- SceneDelegate: Called appCoordinator.start() ---")

        // Устанавливаем фон окна в желтый для отладки
        window.backgroundColor = .systemYellow 
        print("--- SceneDelegate: Set window background to YELLOW ---")

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
class AppCoordinator: Coordinator { // Делаем AppCoordinator соответствующим нашему протоколу
    
    // AppCoordinator владеет главным окном, а не UINavigationController напрямую
    var window: UIWindow
    
    // Реализация требований протокола Coordinator
    var navigationController: UINavigationController // Этот navController будет общим или не использоваться напрямую AppCoordinator'ом
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController() // Создаем "пустой" navController для соответствия протоколу, но можем не использовать его
    }

    func start() {
        // 1. Создаем TabBarController
        let tabBarController = UITabBarController()
        
        // 2. Создаем КООРДИНАТОРЫ для каждой вкладки
        // Важно: Убедись, что пути импорта для PersonCoordinator и других будут правильными,
        // когда ты разнесешь координаторы по папкам. Возможно, понадобится @testable import SensumApp
        let personCoordinator = PersonCoordinator(navigationController: UINavigationController()) // Даем каждому координатору СВОЙ UINavigationController
        let eventsCoordinator = EventsCoordinator(navigationController: UINavigationController())
        let levelingCoordinator = LevelingCoordinator(navigationController: UINavigationController())
        let rankCoordinator = RankCoordinator(navigationController: UINavigationController())
        let storeCoordinator = StoreCoordinator(navigationController: UINavigationController())
        
        // Сохраняем дочерние координаторы
        addChild(personCoordinator)
        addChild(eventsCoordinator)
        addChild(levelingCoordinator)
        addChild(rankCoordinator)
        addChild(storeCoordinator)
        
        // 3. ЗАПУСКАЕМ каждый дочерний координатор
        personCoordinator.start()
        eventsCoordinator.start()
        levelingCoordinator.start()
        rankCoordinator.start()
        storeCoordinator.start()

        // 4. Настраиваем вкладки TabBarController, используя navigationController'ы координаторов
        personCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 0)
        eventsCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Events", image: UIImage(systemName: "calendar"), tag: 1)
        levelingCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2)
        rankCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Rank", image: UIImage(systemName: "list.star"), tag: 3)
        storeCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Store", image: UIImage(systemName: "cart.fill"), tag: 4)

        // 5. Добавляем НАВИГАЦИОННЫЕ КОНТРОЛЛЕРЫ координаторов в TabBarController
        tabBarController.viewControllers = [
            personCoordinator.navigationController,
            eventsCoordinator.navigationController,
            levelingCoordinator.navigationController,
            rankCoordinator.navigationController,
            storeCoordinator.navigationController
        ]
        
        print("--- AppCoordinator: Assigned viewControllers to TabBarController: \(tabBarController.viewControllers?.count ?? 0) items ---")
        
        // 6. Настраиваем внешний вид TabBar с помощью Appearance API
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Делаем фон непрозрачным
        print("--- AppCoordinator: Configuring TabBar Appearance ---")
        appearance.backgroundColor = UIColor(white: 0.1, alpha: 1.0) // Цвет фона (темно-серый, как у карточек)

        // Настройка цвета иконок и текста
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .lightGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
        itemAppearance.selected.iconColor = .white
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBarController.tabBar.standardAppearance = appearance
        // Добавляем 적용 для iOS 15+ скролл-эдж
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }

        // Старые свойства можно закомментировать или удалить
        // tabBarController.tabBar.backgroundColor = .darkGray
        // tabBarController.tabBar.tintColor = .white
        // tabBarController.tabBar.unselectedItemTintColor = .lightGray
        
        // 7. Устанавливаем TabBarController как корневой для окна
        window.rootViewController = tabBarController
        print("--- AppCoordinator: SET TabBarController as rootViewController for window ---")
    }
}

// ----- Координаторы-заглушки для других вкладок -----
// TODO: Перенести эти классы в соответствующие папки Features/.../Coordinators/

class EventsCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    init(navigationController: UINavigationController) { self.navigationController = navigationController }
    func start() {
        let vc = EventsViewController() // Используем твой ViewController или заглушку
        vc.view.backgroundColor = .darkGray // Пример фона
        vc.title = "Events (stub)" // Пример заголовка
        navigationController.setViewControllers([vc], animated: false)
    }
}

class LevelingCoordinator: Coordinator, ExerciseSelectionViewModelCoordinatorDelegate { // Добавляем соответствие протоколу
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    init(navigationController: UINavigationController) { self.navigationController = navigationController }
    
    func start() {
        // Стартуем с экрана выбора упражнений
        let selectionVC = ExerciseSelectionViewController()
        // Создаем ViewModel и передаем себя как делегата
        let viewModel = ExerciseSelectionViewModel(coordinatorDelegate: self) 
        selectionVC.viewModel = viewModel // Передаем ViewModel во ViewController
        selectionVC.title = "Упражнения"
        navigationController.setViewControllers([selectionVC], animated: false)
    }
    
    // Реализуем метод делегата
    func exerciseSelectionViewModelDidSelect(exercise: Exercise) {
        print("--- LevelingCoordinator: Получено событие выбора упражнения: \(exercise.name) ---")
        // Создаем и показываем экран выполнения
        let executionVC = ExerciseExecutionViewController()
        // Создаем ViewModel, передавая упражнение и делегата (сам VC)
        let executionViewModel = ExerciseExecutionViewModel(exercise: exercise, viewDelegate: executionVC)
        executionVC.viewModel = executionViewModel // Устанавливаем ViewModel для VC
        executionVC.selectedExercise = exercise // Передаем выбранное упражнение (может быть уже не нужно, если VM всем рулит)
        executionVC.title = exercise.name // Устанавливаем заголовок
        navigationController.pushViewController(executionVC, animated: true)
    }
}

class RankCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    init(navigationController: UINavigationController) { self.navigationController = navigationController }
    func start() {
        let vc = RankViewController() // Используем твой ViewController или заглушку
        vc.view.backgroundColor = .darkGray
        vc.title = "Rank (stub)"
        navigationController.setViewControllers([vc], animated: false)
    }
}

class StoreCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    init(navigationController: UINavigationController) { self.navigationController = navigationController }
    func start() {
        let vc = StoreViewController() // Используем твой ViewController или заглушку
        vc.view.backgroundColor = .darkGray
        vc.title = "Store (stub)"
        navigationController.setViewControllers([vc], animated: false)
    }
}

// ----- ViewController'ы-заглушки для других вкладок -----
// TODO: Перенести эти классы в соответствующие папки Features/.../Scenes/

// Удаляем эти заглушки, так как реальные классы существуют или будут созданы
// class EventsViewController: UIViewController {}
// class LevelingViewController: UIViewController {}
// class RankViewController: UIViewController {}
// class StoreViewController: UIViewController {}

