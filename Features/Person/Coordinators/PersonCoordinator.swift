import UIKit

class PersonCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // Настраиваем внешний вид Navigation Bar для этого координатора
        setupNavigationBarAppearance()
    }

    func start() {
        let personVC = PersonViewController() // Создаем наш главный экран
        personVC.delegate = self // Устанавливаем себя делегатом
        // Устанавливаем его как корневой viewController для этого navigationController
        // НЕ используем push, если это первый экран в UINavigationController внутри таббара
        // Используем setViewControllers для установки корневого экрана
        navigationController.setViewControllers([personVC], animated: false)
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
}

// Расширение для соответствия протоколу делегата PersonViewControllerDelegate
extension PersonCoordinator: PersonViewControllerDelegate {

    func personViewControllerDidRequestShowAllAchievements(_ controller: PersonViewController) {
        print("PersonCoordinator: Запрос на показ всех достижений получен!")
        // Создаем и показываем экран всех достижений
        let allAchievementsVC = AllAchievementsViewController()
        navigationController.pushViewController(allAchievementsVC, animated: true)
    }

    func personViewControllerDidRequestShowAllFeed(_ controller: PersonViewController) {
        print("PersonCoordinator: Запрос на показ всей ленты получен!")
        // Создаем и показываем экран полной ленты
        let fullFeedVC = FullFeedViewController()
        navigationController.pushViewController(fullFeedVC, animated: true)
    }
} 