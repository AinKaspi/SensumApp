import Foundation
import FirebaseAuth
import GoogleSignIn // Понадобится позже для Google Sign-In
import FirebaseCore // <-- Добавляем этот импорт
import Combine // Для публикации статуса аутентификации

// Протокол для AuthService, если захотим использовать Dependency Injection
protocol AuthServiceProtocol {
    var authenticationState: CurrentValueSubject<AuthenticationState, Never> { get }
    var currentUserID: String? { get }
    
    func checkAuthenticationState()
    func registerUser(email: String, password: String, completion: @escaping (Error?) -> Void)
    func signInUser(email: String, password: String, completion: @escaping (Error?) -> Void)
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Error?) -> Void)
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
    
    // Реализуем Google Sign-In
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Error?) -> Void) {
        // 1. Получаем Client ID из GoogleService-Info.plist
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(NSError(domain: "AuthService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Firebase client ID not found in GoogleService-Info.plist"])) 
            return
        }

        // 2. Конфигурируем Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 3. Запускаем процесс входа Google
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("AuthService Error (Google Sign In): \(error.localizedDescription)")
                completion(error)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                completion(NSError(domain: "AuthService", code: -11, userInfo: [NSLocalizedDescriptionKey: "Google Sign In failed to return user or ID token"])) 
                return
            }

            // 4. Создаем Firebase Credential с помощью Google ID token
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
                                                         
            // 5. Входим в Firebase с этими учетными данными
            self.auth.signIn(with: credential) { authResult, error in
                if let error = error {
                     print("AuthService Error (Firebase Sign In with Google Credential): \(error.localizedDescription)")
                 }
                 // TODO: После первого входа через Google, возможно, нужно создать профиль в Firestore, если его еще нет.
                 completion(error)
            }
        }
    }
    
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