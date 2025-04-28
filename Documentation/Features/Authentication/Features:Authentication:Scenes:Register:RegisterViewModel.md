Файл: Features/Authentication/Scenes/Register/RegisterViewModel.swift
Название файла: RegisterViewModel.swift
Назначение файла: Бизнес-логика и управление состоянием экрана регистрации.
Описание: Содержит логику регистрации нового пользователя. Хранит введенные email/username/password (@Published). Метод attemptRegistration() вызывает authService.registerUser. При успехе вызывает createUserDataInFirestore() для создания записей в коллекциях users (через UserProfileService) и progress (через ProgressService). Обновляет состояния @Published (isLoading, errorMessage).
Содержит: Класс RegisterViewModel, @Published свойства, вычисляемое свойство isRegisterButtonEnabled, методы attemptRegistration(), createUserDataInFirestore().
Технологии: Combine, Foundation, FirebaseFirestore.
Путь: AuthCoordinator.showRegisterScreen() -> Создание RegisterViewModel. RegisterViewController -> viewModel.attemptRegistration().
