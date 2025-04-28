Папка: Features/Authentication/Coordinators
Название папки: Coordinators
Назначение папки: Координатор для флоу аутентификации.
Содержит: AuthCoordinator.swift.
Файл: Features/Authentication/Coordinators/AuthCoordinator.swift
Название файла: AuthCoordinator.swift
Назначение файла: Управление навигацией в рамках флоу аутентификации.
Описание: Реализует протокол Coordinator. Отвечает за показ экрана входа (showLoginScreen) и переход на экран регистрации (showRegisterScreen). Создает и связывает LoginViewModel с LoginViewController и RegisterViewModel с RegisterViewController. Реализует делегаты (LoginViewControllerDelegate, LoginViewModelCoordinatorDelegate, RegisterViewControllerDelegate) для обработки пользовательских действий (нажатие кнопок "Register", "Google Sign In") и инициирования навигации или вызова AuthService. Уведомляет родительский AppCoordinator (через AuthCoordinatorDelegate) об успешном завершении аутентификации (хотя сейчас основная логика переключения флоу завязана на AuthService.authenticationState). Получает зависимости (AuthService, ProgressService) через init.
Содержит: Класс AuthCoordinator, протокол AuthCoordinatorDelegate, методы start, showLoginScreen, showRegisterScreen, реализации методов делегатов.
Технологии: UIKit.
Путь: AppCoordinator -> AuthCoordinator.start() -> showLoginScreen() / showRegisterScreen().
