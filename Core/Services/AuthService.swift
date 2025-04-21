import Foundation
import FirebaseAuth
// import GoogleSignIn // Понадобится позже для Google Sign-In
import Combine // Для публикации статуса аутентификации

// Протокол для AuthService, если захотим использовать Dependency Injection
protocol AuthServiceProtocol {
    var authenticationState: CurrentValueSubject<AuthenticationState, Never> { get }
    var currentUserID: String? { get }
    
    func checkAuthenticationState()
    func registerUser(email: String, password: String, completion: @escaping (Error?) -> Void)
    func signInUser(email: String, password: String, completion: @escaping (Error?) -> Void)
    // func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Error?) -> Void) // Добавим позже
    func signOut(completion: @escaping (Error?) -> Void)
}

// Перечисление для состояний аутентификации
enum AuthenticationState {
    case unknown
    case signedIn
    case signedOut
}

class AuthService: AuthServiceProtocol {
    
    // Публикует текущее состояние аутентификации
    var authenticationState = CurrentValueSubject<AuthenticationState, Never>(.unknown)
    
    // Ссылка на Firebase Auth
    private var auth: Auth
    
    // Обработчик изменений состояния Auth
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // Возвращает ID текущего пользователя или nil
    var currentUserID: String? {
        return auth.currentUser?.uid
    }
    
    init(auth: Auth = Auth.auth()) {
        self.auth = auth
        setupAuthStateHandler()
    }
    
    deinit {
        // Удаляем обработчик при деинициализации
        if let handle = authStateHandler {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // Настраивает обработчик для отслеживания входа/выхода
    private func setupAuthStateHandler() {
        authStateHandler = auth.addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            if user != nil {
                print("AuthService: User signed in (", user?.uid ?? "N/A", ")")
                self.authenticationState.send(.signedIn)
            } else {
                print("AuthService: User signed out")
                self.authenticationState.send(.signedOut)
            }
        }
    }
    
    // Проверяет начальное состояние (вызывать при старте AppCoordinator)
    func checkAuthenticationState() {
        if auth.currentUser != nil {
            authenticationState.send(.signedIn)
        } else {
            authenticationState.send(.signedOut)
        }
    }
    
    // MARK: - Auth Methods
    
    func registerUser(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("AuthService Error (Register): \(error.localizedDescription)")
            }
            completion(error)
            // TODO: После успешной регистрации, возможно, нужно создать запись в Firestore
        }
    }
    
    func signInUser(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("AuthService Error (Sign In): \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    // TODO: Реализовать Google Sign-In
    /*
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Error?) -> Void) {
        // ... Логика Google Sign-In с использованием GIDSignIn ...
    }
    */
    
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try auth.signOut()
            completion(nil)
        } catch let signOutError as NSError {
            print("AuthService Error (Sign Out): \(signOutError)")
            completion(signOutError)
        }
    }
} 