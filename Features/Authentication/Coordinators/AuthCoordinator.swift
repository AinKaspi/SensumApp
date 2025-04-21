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
        vc.viewModel = vm
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // Показывает экран регистрации
    func showRegisterScreen() {
        let vm = RegisterViewModel(authService: authService)
        // Делегат координатора для VM не нужен
        let vc = RegisterViewController()
        vc.delegate = self
        vc.viewModel = vm // <-- Передаем ViewModel
        navigationController.pushViewController(vc, animated: true)
    }
    
    // MARK: - LoginViewControllerDelegate
    
    func didTapRegisterButton() {
        showRegisterScreen()
    }
    
    func didTapLoginButton(email: String?, password: String?) {
        // Логика теперь в ViewModel
        print("AuthCoordinator: didTapLoginButton called (DEPRECATED - use ViewModel binding)")
    }
    
    // Обработка нажатия кнопки Google
    func didTapGoogleSignInButton() {
        print("AuthCoordinator: Google Sign In button tapped.")
        // Нужен view controller для представления окна входа Google
        guard let presentingVC = navigationController.topViewController else {
            print("AuthCoordinator Error: Cannot get presenting view controller for Google Sign In.")
            return
        }
        
        authService.signInWithGoogle(presentingViewController: presentingVC) { [weak self] error in
            // Ошибки обрабатываются внутри AuthService и LoginViewModel (через errorMessage)
            // Успешный вход обработается через подписку на authenticationState
            if let error = error {
                print("AuthCoordinator: Google Sign In completed with error: \(error.localizedDescription)")
                // Можно показать Alert здесь, если нужно общее сообщение об ошибке
            } else {
                print("AuthCoordinator: Google Sign In process initiated successfully (waiting for state change)...")
            }
        }
    }
    
    // MARK: - LoginViewModelCoordinatorDelegate
    
    func loginViewModelDidRequestRegistration() {
        showRegisterScreen()
    }
    
    // MARK: - RegisterViewControllerDelegate
    
    func didTapRegisterButton(email: String?, username: String?, password: String?) {
        // Этот метод больше не нужен, используем биндинги и viewModel.attemptRegistration()
        print("AuthCoordinator: didTapRegisterButton called (DEPRECATED - use ViewModel binding)")
    }
    
    // TODO: Добавить методы-делегаты для ViewModel (например, didTapRegister, didTapLogin)
} 