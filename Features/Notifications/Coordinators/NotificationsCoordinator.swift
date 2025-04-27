import UIKit

class NotificationsCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // TODO: Добавить зависимости (NotificationService, AuthService?)

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // Настроим стиль Navigation Bar для уведомлений
        setupNavigationBarAppearance()
    }

    func start() {
        let vc = NotificationsViewController() // Создаем заглушку VC
        // vc.viewModel = ... // Когда будет ViewModel
        vc.title = "Уведомления"
        // Добавляем кнопку закрытия, т.к. показываем модально
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissNotifications))
        
        // Мы используем переданный navigationController, который был создан для модального показа
        navigationController.setViewControllers([vc], animated: false)
        // AppCoordinator отвечает за present
    }
    
    @objc private func dismissNotifications() {
        // Уведомляем родительский координатор (AppCoordinator), что флоу завершен
        // AppCoordinator должен будет вызвать dismiss для navigationController
        // Пока просто печатаем
        print("NotificationsCoordinator: Dismiss requested.")
        navigationController.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func setupNavigationBarAppearance() {
        // Пример настройки: светлый стиль для модального окна
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .black // Или другой цвет фона
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance // Для маленьких заголовков
        
        navigationController.navigationBar.tintColor = .white // Цвет кнопок (например, Close)
    }
}
