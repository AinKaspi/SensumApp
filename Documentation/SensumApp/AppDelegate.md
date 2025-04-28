Файл: AppDelegate.swift
Название файла: AppDelegate.swift
Назначение файла: Управление глобальным жизненным циклом приложения и первичная настройка.
Описание: Класс, отвечающий за основные события жизненного цикла приложения (запуск, переход в фон и т.д.). В данном проекте он инициализирует Firebase (FirebaseApp.configure()) при запуске и настраивает конфигурацию сцен (UISceneConfiguration) для SceneDelegate. Не содержит сложной логики, делегируя управление UI сценам. Связан с SceneDelegate через конфигурацию сцен.
Содержит: Класс AppDelegate, реализующий UIApplicationDelegate, методы application(_:didFinishLaunchingWithOptions:), application(_:configurationForConnecting:options:).
Технологии: UIKit, FirebaseCore.
Путь: Является точкой входа приложения после системного запуска. Вызывает FirebaseApp.configure().
