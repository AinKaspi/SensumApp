import UIKit

class ProgressCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // Добавляем зависимости
    private let authService: AuthServiceProtocol
    private let progressService: ProgressServiceProtocol

    // Обновляем init
    init(navigationController: UINavigationController,
         authService: AuthServiceProtocol, 
         progressService: ProgressServiceProtocol) {
        self.navigationController = navigationController
        self.authService = authService
        self.progressService = progressService
    }

    func start() {
        // Создаем ViewModel с зависимостями
        let viewModel = ProgressViewModel(authService: authService, progressService: progressService)
        
        // Создаем ViewController и инжектируем ViewModel
        let vc = ProgressViewController()
        vc.viewModel = viewModel 
        // vc.title = "Progress" // Title уже устанавливается в самом VC
        navigationController.setViewControllers([vc], animated: false)
    }
} 