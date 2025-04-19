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
        let personCoordinator = PersonCoordinator(navigationController: UINavigationController()) // Создаем, но не будем добавлять его NC в таббар
        let eventsCoordinator = EventsCoordinator(navigationController: UINavigationController())
        let levelingCoordinator = LevelingCoordinator(navigationController: UINavigationController())
        let rankCoordinator = RankCoordinator(navigationController: UINavigationController())
        let storeCoordinator = StoreCoordinator(navigationController: UINavigationController())
        
        // Создаем PersonContainerViewController отдельно
        let personContainerVC = PersonContainerViewController()
        personContainerVC.coordinator = personCoordinator // Назначаем координатора
        
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

        // 4. Настраиваем вкладки TabBarController
        // Для Person используем напрямую personContainerVC
        personContainerVC.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 0)
        // Для остальных используем navigationController'ы координаторов
        eventsCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Events", image: UIImage(systemName: "calendar"), tag: 1)
        levelingCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2)
        rankCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Rank", image: UIImage(systemName: "list.star"), tag: 3)
        storeCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Store", image: UIImage(systemName: "cart.fill"), tag: 4)

        // 5. Добавляем контроллеры в TabBarController
        tabBarController.viewControllers = [
            personContainerVC, // <-- Добавляем контейнер напрямую
            eventsCoordinator.navigationController,
            levelingCoordinator.navigationController,
            rankCoordinator.navigationController,
            storeCoordinator.navigationController
        ]
        
        
        // 6. Настраиваем внешний вид TabBar с помощью Appearance API
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() 
        // Устанавливаем черный цвет фона
        appearance.backgroundColor = .black 

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

class LevelingCoordinator: Coordinator, ExerciseSelectionViewModelCoordinatorDelegate {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // Создаем и храним PoseLandmarkerHelper на уровне координатора
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let sessionQueue = DispatchQueue(label: "com.sensum.poseHelperQueue") // Очередь для хелпера
    
    init(navigationController: UINavigationController) { 
        self.navigationController = navigationController
        // Запускаем инициализацию хелпера в фоне при создании координатора
        setupPoseLandmarkerHelperInBackground()
    }
    
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
        // Создаем и показываем экран выполнения
        let executionVC = ExerciseExecutionViewController()
        // Создаем ViewModel, передавая упражнение, ГОТОВЫЙ хелпер и делегата VC
        let executionViewModel = ExerciseExecutionViewModel(exercise: exercise, 
                                                          poseLandmarkerHelper: self.poseLandmarkerHelper,
                                                          viewDelegate: executionVC)
        executionVC.viewModel = executionViewModel 
        executionVC.title = exercise.name
        navigationController.pushViewController(executionVC, animated: true)
    }
    
    // Метод для инициализации PoseLandmarkerHelper в фоне
    private func setupPoseLandmarkerHelperInBackground() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Параметры инициализации (можно вынести в константы)
            let modelPathString = "pose_landmarker_full.task"
            let numPoses = 1
            let minPoseDetectionConfidence: Float = 0.5
            let minPosePresenceConfidence: Float = 0.5
            let minTrackingConfidence: Float = 0.5
            let computeDelegate: Delegate = .GPU
            
            guard let modelPath = Bundle.main.path(forResource: modelPathString, ofType: nil) else {
                print("LevelingCoordinator Ошибка: Файл модели MediaPipe не найден ('\(modelPathString)').")
                return
            }
            
            // Используем тот же статический инициализатор, но liveStreamDelegate будет nil
            // Делегат будет назначен позже во ViewModel
            self.poseLandmarkerHelper = PoseLandmarkerHelper.liveStreamPoseLandmarkerHelper(
                modelPath: modelPath, 
                numPoses: numPoses,
                minPoseDetectionConfidence: minPoseDetectionConfidence, 
                minPosePresenceConfidence: minPosePresenceConfidence, 
                minTrackingConfidence: minTrackingConfidence, 
                liveStreamDelegate: nil, // Делегат будет назначен во ViewModel
                computeDelegate: computeDelegate
            )
            
            if self.poseLandmarkerHelper == nil {
                 print("LevelingCoordinator Ошибка: Ошибка инициализации PoseLandmarkerHelper.")
            } else {
                 print("--- LevelingCoordinator: PoseLandmarkerHelper инициализирован в фоне. ---")
            }
        }
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

// Удаляем закомментированные заглушки ViewController'ов
/*
// ----- ViewController'ы-заглушки для других вкладок -----
// TODO: Перенести эти классы в соответствующие папки Features/.../Scenes/

// Удаляем эти заглушки, так как реальные классы существуют или будут созданы
// class EventsViewController: UIViewController {}
// class LevelingViewController: UIViewController {}
// class RankViewController: UIViewController {}
// class StoreViewController: UIViewController {}
*/

