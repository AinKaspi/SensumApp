import UIKit
import Combine

// Протокол для делегата, который будет уведомлен об успешной аутентификации
protocol AuthCoordinatorDelegate: AnyObject {
    func didFinishAuthentication(coordinator: AuthCoordinator)
}

// Убираем AuthCoordinatorDelegate из списка протоколов для самого AuthCoordinator
class AuthCoordinator: Coordinator, LoginViewControllerDelegate, LoginViewModelCoordinatorDelegate, RegisterViewControllerDelegate {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: AuthCoordinatorDelegate?
    
    // Сервис аутентификации
    private let authService: AuthServiceProtocol
    
    // Для подписки на состояние аутентификации
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationController: UINavigationController, authService: AuthServiceProtocol) {
        self.navigationController = navigationController
        self.authService = authService
        // Убираем подписку отсюда, она нужна только после успешного входа?
        // Или оставить, чтобы сразу перейти, если пользователь уже вошел где-то?
        // Пока оставим.
        setupAuthenticationSubscription()
    }

    func start() {
        showLoginScreen()
    }
    
    // Подписываемся на изменения состояния аутентификации от AuthService
    private func setupAuthenticationSubscription() {
        authService.authenticationState
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .signedIn:
                    // Пользователь вошел (возможно, после регистрации/входа), 
                    // сообщаем главному координатору
                    print("AuthCoordinator: Authentication successful, notifying delegate.")
                    self.delegate?.didFinishAuthentication(coordinator: self)
                case .signedOut, .unknown:
                    // Остаемся в флоу аутентификации
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // Показывает экран входа
    func showLoginScreen() {
        let vm = LoginViewModel(authService: authService)
        vm.coordinatorDelegate = self
        let vc = LoginViewController()
        vc.delegate = self
        // TODO: Pass vm to vc and set up bindings
        navigationController.setViewControllers([vc], animated: false) // Не анимируем первый экран
    }
    
    // Показывает экран регистрации
    func showRegisterScreen() {
        // Создаем реальные VC и ViewModel
        let vm = RegisterViewModel(authService: authService)
        // vm.coordinatorDelegate не нужен для RegisterViewModel
        
        let vc = RegisterViewController()
        vc.delegate = self // Мы делегат для ViewController
        // TODO: Pass vm to vc and set up bindings
        
        navigationController.pushViewController(vc, animated: true)
    }
    
    // MARK: - LoginViewControllerDelegate
    
    func didTapRegisterButton() {
        showRegisterScreen()
    }
    
    func didTapLoginButton(email: String?, password: String?) {
        // Передаем данные в ViewModel для попытки входа
        // TODO: Связать текстовые поля с @Published свойствами ViewModel напрямую,
        // чтобы не передавать email/password здесь.
        // vm.email = email ?? ""
        // vm.password = password ?? ""
        // vm.attemptLogin()
        print("AuthCoordinator: Login button tapped (should be handled by ViewModel binding)")
        // Пока оставим так, нужно реализовать биндинг VC <-> VM
    }
    
    // MARK: - LoginViewModelCoordinatorDelegate
    
    func loginViewModelDidRequestRegistration() {
        showRegisterScreen()
    }
    
    // MARK: - RegisterViewControllerDelegate
    
    func didTapRegisterButton(email: String?, username: String?, password: String?) {
        // Передаем данные в ViewModel для попытки регистрации
        // TODO: Связать текстовые поля с @Published свойствами ViewModel напрямую.
        // vm.email = email ?? ""
        // vm.username = username ?? ""
        // vm.password = password ?? ""
        // vm.attemptRegistration()
        print("AuthCoordinator: Register button tapped (should be handled by ViewModel binding)")
        // Пока оставим так, нужно реализовать биндинг VC <-> VM
    }
    
    // TODO: Добавить методы-делегаты для ViewModel (например, didTapRegister, didTapLogin)
} 