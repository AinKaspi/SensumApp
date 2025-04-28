Папка: Features/UserProfile/Coordinators
Название папки: Coordinators
Содержит: UserProfileCoordinator.swift.
Файл: Features/UserProfile/Coordinators/UserProfileCoordinator.swift
Название файла: UserProfileCoordinator.swift
Назначение файла: Управление флоу просмотра профиля другого пользователя.
Описание: Инициализируется с userID пользователя, чей профиль нужно показать, и необходимыми сервисами. В методе start создает и показывает UserProfileContainerViewController, передавая ему userID и сервисы. Реализует метод dismissProfile для возврата назад (например, в ленту).
Содержит: Класс UserProfileCoordinator, методы start, dismissProfile.
Технологии: UIKit.
Путь: FeedCoordinator.showUserProfile() -> Создание и запуск UserProfileCoordinator.
