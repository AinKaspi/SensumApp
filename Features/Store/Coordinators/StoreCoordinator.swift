import UIKit

class StoreCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        // Проверяем, существует ли StoreViewController
        // Если нет, создаем базовый placeholder
        if let scenesDir = Bundle.main.path(forResource: "Storefront", ofType: nil, inDirectory: "Features/Store/Scenes"),
           FileManager.default.fileExists(atPath: scenesDir) {
            // Предполагаем, что VC называется StoreViewController и лежит в Scenes/Storefront
             let vc = StoreViewController() // TODO: Убедиться, что класс существует и правильно инициализируется
             vc.title = "Store"
             navigationController.setViewControllers([vc], animated: false)
        } else {
             print("Warning: StoreViewController not found at expected path. Creating placeholder.")
             let vc = UIViewController()
             vc.title = "Store (Placeholder)"
             vc.view.backgroundColor = .systemPurple
             let placeholderLabel = UILabel()
             placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
             placeholderLabel.text = "Store Tab Placeholder"
             placeholderLabel.textColor = .white
             placeholderLabel.textAlignment = .center
             vc.view.addSubview(placeholderLabel)
             NSLayoutConstraint.activate([
                 placeholderLabel.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                 placeholderLabel.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
             ])
             navigationController.setViewControllers([vc], animated: false)
        }
    }
} 