Файл: Features/Authentication/Scenes/Login/LoginViewController.swift
Название файла: LoginViewController.swift
Назначение файла: UI-представление экрана входа.
Описание: Отображает поля для ввода email/пароля, кнопки "Login", "Register", "Sign in with Google", индикатор загрузки и лейбл ошибок. Настраивает UI программно. Связан с LoginViewModel через Combine для обновления состояния UI (активность кнопки, индикатор, ошибки) и передачи введенных данных. Вызывает методы делегата (LoginViewControllerDelegate - реализуется AuthCoordinator) при нажатии кнопок "Register" и "Google Sign In" для инициирования навигации или специфичных действий. При нажатии "Login" вызывает метод viewModel.attemptLogin().
Содержит: Класс LoginViewController, протокол LoginViewControllerDelegate, UI элементы (UILabel, UITextField, UIButton, UIActivityIndicatorView, UIStackView), @objc методы-обработчики нажатий, setupBindings(), setupViews(), setupConstraints().
Технологии: UIKit, Combine.
Путь: AuthCoordinator.showLoginScreen() -> Создание и показ LoginViewController.
