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
    // Добавляем ProgressService для создания записи прогресса
    let progressService: ProgressServiceProtocol
    
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
    
    init(authService: AuthServiceProtocol, 
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         progressService: ProgressServiceProtocol) { // Убрали = ProgressService()
        self.authService = authService
        self.userProfileService = userProfileService
        self.progressService = progressService // Сохраняем зависимость
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
                    print("RegisterViewModel Error: Code=\(error.code), Domain=\(error.domain), UserInfo=\(error.userInfo)") 
                    self.errorMessage = "Registration failed: \(error.localizedDescription)"
                }
            } else {
                // Успешная регистрация в Auth, теперь создаем профиль и прогресс в Firestore
                print("RegisterViewModel: Auth registration successful. Creating Firestore profile & progress...")
                self.createUserDataInFirestore()
            }
        }
    }
    
    // Переименовываем и обновляем метод
    private func createUserDataInFirestore() {
        guard let userID = authService.currentUserID else {
             print("RegisterViewModel Error: Cannot get current user ID after registration.")
             DispatchQueue.main.async {
                 self.isLoading = false
                 self.errorMessage = "Failed to create profile (User ID error)."
             }
            return
        }
        
        // Создаем объект User (без level/xp)
        let newUser = User(id: userID,
                           username: self.username,
                           email: self.email,
                           avatarURL: nil,
                           status: "Hello! Welcome to Sensum.",
                           followerCount: 0,
                           followingCount: 0,
                           createdAt: Timestamp())
        
        // Создаем объект ProgressData (дефолтный)
        let newProgress = ProgressData() // Использует значения по умолчанию (level 1, rank E, etc.)
        
        // Используем DispatchGroup для параллельного сохранения
        let group = DispatchGroup()
        var userProfileError: Error? = nil
        var progressDataError: Error? = nil

        // 1. Сохраняем User
        group.enter()
        userProfileService.createUserProfile(user: newUser) { error in
            userProfileError = error
            group.leave()
        }
        
        // 2. Сохраняем ProgressData
        group.enter()
        // Используем прямой вызов updateProgressData, т.к. fetch не нужен для нового пользователя
        progressService.updateProgressData(userID: userID, data: newProgress) { error in
            progressDataError = error
            group.leave()
        }
        
        // 3. Обрабатываем результаты после завершения обеих операций
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false // Завершаем загрузку в любом случае
            if let error = userProfileError ?? progressDataError { // Берем первую возникшую ошибку
                self?.errorMessage = "Failed to complete registration: \(error.localizedDescription)"
                print("RegisterViewModel Error (Firestore Save): \(error.localizedDescription)")
                // TODO: Возможно, нужно откатить регистрацию в Auth или предложить пользователю повторить?
            } else {
                // Успех! AuthService уже должен был отправить .signedIn,
                // и AuthCoordinator закроет этот флоу.
                print("RegisterViewModel: Firestore user profile and progress data created successfully.")
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