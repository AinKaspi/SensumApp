//
//  SceneDelegate.swift
//  SensumApp
//
//  Created by Ain on 07/04/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Первое, получаем "сцену" - это как бы экран, на котором всё будет происходить.
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Создаем самое ГЛАВНОЕ ОКНО для нашего приложения.
        let window = UIWindow(windowScene: windowScene)
        
        // 1. Создаем TabBarController - это контейнер для наших вкладок
        let tabBarController = UITabBarController()
        
        // 2. Создаем экземпляры ViewController'ов для КАЖДОЙ вкладки
        let personVC = PersonViewController()
        let eventsVC = EventsViewController() // Убедись, что имя класса совпадает с созданным файлом
        let levelingVC = LevelingViewController() // Убедись, что имя класса совпадает
        let rankVC = RankViewController()       // Убедись, что имя класса совпадает
        let storeVC = StoreViewController()  // Убедись, что имя класса совпадает
        
        // 3. Настраиваем ИКОНКИ и ЗАГОЛОВКИ для каждой вкладки (пока используем системные иконки)
        personVC.tabBarItem = UITabBarItem(title: "Person", image: UIImage(systemName: "person.fill"), tag: 0)
        eventsVC.tabBarItem = UITabBarItem(title: "Events", image: UIImage(systemName: "calendar"), tag: 1)
        levelingVC.tabBarItem = UITabBarItem(title: "Leveling", image: UIImage(systemName: "figure.walk"), tag: 2)
        rankVC.tabBarItem = UITabBarItem(title: "Rank", image: UIImage(systemName: "list.star"), tag: 3)
        storeVC.tabBarItem = UITabBarItem(title: "Store", image: UIImage(systemName: "cart.fill"), tag: 4)
        
        // 4. Добавляем ViewController'ы в TabBarController
        tabBarController.viewControllers = [personVC, eventsVC, levelingVC, rankVC, storeVC]
        
        // 5. Опционально: Настраиваем внешний вид TabBar (например, цвет фона и выбранного элемента)
        tabBarController.tabBar.backgroundColor = .darkGray // Пример цвета фона
        tabBarController.tabBar.tintColor = .white          // Цвет выбранной иконки/текста
        tabBarController.tabBar.unselectedItemTintColor = .lightGray // Цвет невыбранных
        
        // Говорим нашему главному окну: "Вот этот TabBarController будет твоим содержимым по умолчанию".
        window.rootViewController = tabBarController

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

