import Foundation
import Combine

// Делегат для LoginViewModel, чтобы сообщать координатору о навигации
protocol LoginViewModelCoordinatorDelegate: AnyObject {
    func loginViewModelDidRequestRegistration()
    // func loginViewModelDidSignInSuccessfully() // Успешный вход обрабатывается через подписку в AuthCoordinator
}

class LoginViewModel {
    
    weak var coordinatorDelegate: LoginViewModelCoordinatorDelegate?
    let authService: AuthServiceProtocol
    
    // Состояния для UI
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Можно ли нажимать кнопку Login
    var isLoginButtonEnabled: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                return !email.isEmpty && !password.isEmpty // Простая проверка
            }
            .eraseToAnyPublisher()
    }
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // Вызывается при нажатии кнопки Login
    func attemptLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        authService.signInUser(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async { // Обновляем UI в главном потоке
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                } else {
                    // Успех! AuthService сам изменит authenticationState,
                    // AuthCoordinator это увидит и закроет флоу.
                    print("LoginViewModel: Sign in successful (AuthService will notify coordinator)")
                }
            }
        }
    }
    
    // Вызывается при нажатии кнопки Register
    func didTapRegister() {
        coordinatorDelegate?.loginViewModelDidRequestRegistration()
    }
    
    // TODO: Добавить метод для Google Sign In
} 