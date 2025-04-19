import UIKit

// Переносим протокол сюда
protocol PersonViewControllerDelegate: AnyObject {
    func personViewControllerDidTapSettings(_ controller: PersonViewController)
    // Методы для Achievements/Feed больше не нужны здесь
    // func personViewControllerDidRequestShowAllAchievements(_ controller: PersonViewController)
    // func personViewControllerDidRequestShowAllFeed(_ controller: PersonViewController)
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
        // Создаем ViewModel (если она нужна координатору или для DI)
        let viewModel = PersonViewModel()
        
        // Создаем ViewController
        let vc = PersonViewController()
        vc.viewModel = viewModel // Инъекция ViewModel
        vc.coordinator = self // Передаем ссылку на координатор (если VC ее ожидает)
        
        // Устанавливаем VC как корневой для UINavigationController координатора
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // Приватный метод для настройки Navigation Bar
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black // Фон бара - черный
        appearance.shadowColor = .clear // Убираем тень (линию)
        // Устанавливаем белый цвет для заголовка и кнопок, если они понадобятся
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance // Для маленьких баров
        // Устанавливаем цвет кнопок (например, "Назад"), если нужно
        navigationController.navigationBar.tintColor = .white 
    }

    // Реализация метода делегата
    func showSettings() {
        // TODO: Реализовать навигацию к экрану настроек
        print("--- PersonCoordinator: Show Settings Tapped --- ")
        // Закомментируем создание VC, пока он не существует
        /*
        let settingsVC = SettingsViewController() // Предполагаем, что есть такой VC
        settingsVC.title = "Настройки"
        navigationController.pushViewController(settingsVC, animated: true)
        */
    }
    
    // TODO: Добавить другие методы координатора, если нужны (например, для показа Stats/Achievements)
}

// Удаляем старое расширение для делегата
/*
extension PersonCoordinator: PersonViewControllerDelegate {
    func personViewControllerDidRequestShowAllAchievements(...) { ... }
    func personViewControllerDidRequestShowAllFeed(...) { ... }
    // Метод personViewControllerDidTapSettings теперь прямо в классе
}
*/ 
