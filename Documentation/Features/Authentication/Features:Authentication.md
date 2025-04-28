Папка: Features/Authentication
Название папки: Authentication
Назначение папки: Реализация флоу аутентификации пользователя (вход и регистрация).
Описание: Содержит все компоненты, необходимые для аутентификации: координатор (AuthCoordinator), который управляет навигацией между экранами входа и регистрации, и сами экраны (Scenes), реализованные по MVVM (LoginViewController/LoginViewModel, RegisterViewController/RegisterViewModel). ViewModel'и взаимодействуют с AuthService и UserProfileService для выполнения операций и создания пользователя.
Содержит: Папки Coordinators/, Scenes/.
Технологии: UIKit, Combine, Foundation.
Путь: AppCoordinator (при состоянии .signedOut или .unknown) -> AuthCoordinator.start() -> AuthCoordinator.showLoginScreen() (создает LoginViewModel, LoginViewController) -> (при нажатии "Register") AuthCoordinator.showRegisterScreen() (создает RegisterViewModel, RegisterViewController).
