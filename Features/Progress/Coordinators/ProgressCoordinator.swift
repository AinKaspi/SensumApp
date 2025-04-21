import UIKit

class ProgressCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = ProgressViewController()
        vc.title = "Progress"
        navigationController.setViewControllers([vc], animated: false)
    }
} 