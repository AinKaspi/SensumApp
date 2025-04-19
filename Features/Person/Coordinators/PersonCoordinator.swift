import UIKit

// Протокол для навигации из VC (только для настроек)
protocol PersonViewControllerDelegate: AnyObject {
    func personViewControllerDidTapSettings(_ controller: UIViewController) // Используем UIViewController
}

class PersonCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // Настраиваем внешний вид Navigation Bar для этого координатора
        setupNavigationBarAppearance()
    }

    func start() {
        // Новый код: Метод start теперь ничего не делает, так как 
        // PersonContainerViewController создается и устанавливается в AppCoordinator.
        // Координатор просто существует, чтобы быть назначенным в containerVC.
        print("--- PersonCoordinator started (now managed by AppCoordinator/TabBar) ---")
    }
    
    // Приватный метод для настройки Navigation Bar
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black // Фон бара - черный
        appearance.shadowColor = .clear // Убираем тень (линию)
        // appearance.isTranslucent = false // <-- Комментируем из-за ошибки компиляции
        // Устанавливаем белый цвет для заголовка и кнопок, если они понадобятся
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance // Для маленьких баров
        // Устанавливаем цвет кнопок (например, "Назад"), если нужно
        navigationController.navigationBar.tintColor = .white 
    }

    // Метод для показа настроек (вызывается из PersonContainerViewController)
    func showSettings() {
        print("--- PersonCoordinator: Show Settings Tapped --- ")
        let settingsVC = SettingsViewController() // Предполагаем, что есть такой VC
        settingsVC.title = "Настройки"
        // Прячем TabBar при пуше
        settingsVC.hidesBottomBarWhenPushed = true 
        navigationController.pushViewController(settingsVC, animated: true)
    }
    
    // Удаляем неиспользуемый метод showStats
    /*
    // Показывает экран статистики
    func showStats() {
        let statsVC = StatsViewController() // Создаем заглушку
        // Можно настроить presentation style, если нужно (например, modal)
        navigationController.pushViewController(statsVC, animated: true)
    }
    */
    
    // Удаляем TODO для Achievements
    // TODO: Добавить метод для показа Achievements, когда он вернется
    // func showAchievements() { ... }
}

// Удаляем старое расширение
/*
extension PersonCoordinator: PersonViewControllerDelegate { ... }
*/ 
