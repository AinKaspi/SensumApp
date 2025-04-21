import Foundation
import Combine

// Делегат не нужен, т.к. успешная регистрация отслеживается через 
// подписку на authenticationState в AuthCoordinator
/*
protocol RegisterViewModelCoordinatorDelegate: AnyObject {
    // func registrationSuccessful()
}
*/

class RegisterViewModel {
    
    // weak var coordinatorDelegate: RegisterViewModelCoordinatorDelegate?
    let authService: AuthServiceProtocol
    
    // Состояния для UI
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Можно ли нажимать кнопку Register
    var isRegisterButtonEnabled: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3($email, $username, $password)
            .map { email, username, password in
                return !email.isEmpty && !username.isEmpty && !password.isEmpty // Простая проверка
            }
            .eraseToAnyPublisher()
    }
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // Вызывается при нажатии кнопки Register
    func attemptRegistration() {
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        authService.registerUser(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async { // Обновляем UI в главном потоке
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Registration failed: \(error.localizedDescription)"
                } else {
                    // Успех! AuthService сам изменит authenticationState,
                    // AuthCoordinator это увидит и закроет флоу.
                    print("RegisterViewModel: Registration successful (AuthService will notify coordinator)")
                    // TODO: Здесь же нужно сохранить username и другие данные в Firestore для нового пользователя
                    // self?.saveUserProfileData(username: self.username)
                }
            }
        }
    }
    
    // TODO: Метод для сохранения данных профиля в Firestore
    /*
    private func saveUserProfileData(username: String) {
        guard let userID = authService.currentUserID else { return }
        // ... вызов UserProfileService для создания записи в Firestore ...
    }
    */
} 