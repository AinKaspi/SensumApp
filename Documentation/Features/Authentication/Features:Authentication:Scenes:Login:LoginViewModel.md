Файл: Features/Authentication/Scenes/Login/LoginViewModel.swift
Название файла: LoginViewModel.swift
Назначение файла: Бизнес-логика и управление состоянием экрана входа.
Описание: Содержит логику для входа пользователя. Хранит введенные email/пароль (@Published). Предоставляет вычисляемое свойство isLoginButtonEnabled. Метод attemptLogin() вызывает AuthService.signInUser и обновляет состояния @Published (isLoading, errorMessage). При нажатии "Register" уведомляет координатора через coordinatorDelegate. Не обрабатывает Google Sign In напрямую (делегирует AuthCoordinator).
Содержит: Класс LoginViewModel, протокол LoginViewModelCoordinatorDelegate, @Published свойства (email, password, isLoading, errorMessage), вычисляемое свойство isLoginButtonEnabled, методы attemptLogin(), didTapRegister().
Технологии: Combine, Foundation.
Путь: AuthCoordinator.showLoginScreen() -> Создание LoginViewModel. LoginViewController -> viewModel.attemptLogin().
