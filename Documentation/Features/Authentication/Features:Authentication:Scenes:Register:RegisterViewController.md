Файл: Features/Authentication/Scenes/Register/RegisterViewController.swift
Название файла: RegisterViewController.swift
Назначение файла: UI-представление экрана регистрации.
Описание: Отображает поля для ввода email, username, пароля, кнопку "Register", индикатор загрузки, лейбл ошибок. Настраивает UI программно. Связан с RegisterViewModel через Combine для обновления состояния UI и передачи введенных данных. При нажатии "Register" вызывает viewModel.attemptRegistration(). Показывает системную кнопку "Назад" в Navigation Bar.
Содержит: Класс RegisterViewController, протокол RegisterViewControllerDelegate, UI элементы, @objc методы-обработчики, setupBindings(), setupViews(), setupConstraints().
Технологии: UIKit, Combine.
Путь: AuthCoordinator.showRegisterScreen() -> Создание и показ RegisterViewController.
