Файл: Core/Services/AuthService.swift
Название файла: AuthService.swift
Назначение файла: Управление аутентификацией пользователей.
Описание: Предоставляет методы для регистрации (registerUser), входа (signInUser, signInWithGoogle), выхода (signOut) и проверки текущего состояния аутентификации (checkAuthenticationState, currentUserID). Использует FirebaseAuth и GoogleSignIn. Публикует текущее состояние аутентификации (authenticationState) через CurrentValueSubject из Combine, что позволяет AppCoordinator реагировать на изменения.
Содержит: Протокол AuthServiceProtocol, класс AuthService, enum AuthenticationState, методы аутентификации, свойства authenticationState и currentUserID.
Технологии: Foundation, FirebaseAuth, GoogleSignIn, Combine, FirebaseCore.
Путь: Создается в DIContainer. Используется AppCoordinator (для подписки на состояние и вызова checkAuthenticationState/signOut), AuthCoordinator (для вызова signInUser/registerUser/signInWithGoogle), RegisterViewModel (вызывает registerUser), LoginViewModel (вызывает signInUser). Многие другие ViewModel'и и сервисы используют authService.currentUserID.
