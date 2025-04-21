import Foundation
import Combine
import FirebaseFirestore // Для Timestamp

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
    // Добавляем UserProfileService
    let userProfileService: UserProfileServiceProtocol
    
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
    
    init(authService: AuthServiceProtocol, userProfileService: UserProfileServiceProtocol = UserProfileService()) {
        self.authService = authService
        self.userProfileService = userProfileService
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
            guard let self = self else { return }
            
            if let error = error as NSError? { // Приводим к NSError для доступа к userInfo
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Логируем больше деталей
                    print("RegisterViewModel Error: Code=\(error.code), Domain=\(error.domain), UserInfo=\(error.userInfo)") 
                    self.errorMessage = "Registration failed: \(error.localizedDescription)"
                }
            } else {
                // Успешная регистрация в Auth, теперь создаем профиль в Firestore
                print("RegisterViewModel: Auth registration successful. Creating Firestore profile...")
                self.createUserProfileInFirestore()
            }
        }
    }
    
    // Создает профиль в Firestore
    private func createUserProfileInFirestore() {
        guard let userID = authService.currentUserID else {
             // Эта ситуация не должна возникать сразу после успешной регистрации, но проверим
             print("RegisterViewModel Error: Cannot get current user ID after registration.")
             DispatchQueue.main.async {
                 self.isLoading = false
                 self.errorMessage = "Failed to create profile (User ID error)."
             }
            return
        }
        
        // Создаем объект User
        let newUser = User(id: userID, // Передаем ID из Auth
                           username: self.username,
                           email: self.email,
                           avatarURL: nil, // Аватар будет добавлен позже
                           status: "Hello! Welcome to Sensum.", // Статус по умолчанию
                           followerCount: 0,
                           followingCount: 0,
                           level: 1,
                           currentXP: 0,
                           xpToNextLevel: 100,
                           createdAt: Timestamp()) // Текущее время
        
        // Вызываем сервис для сохранения
        userProfileService.createUserProfile(user: newUser) { [weak self] error in
             DispatchQueue.main.async { // Обновляем UI в главном потоке
                 self?.isLoading = false // Завершаем загрузку в любом случае
                 if let error = error {
                     self?.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                     // TODO: Возможно, нужно откатить регистрацию в Auth или предложить пользователю повторить?
                 } else {
                     // Успех! AuthService уже должен был отправить .signedIn,
                     // и AuthCoordinator закроет этот флоу.
                     print("RegisterViewModel: Firestore profile created successfully.")
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