Папка: Features/UserProfile/Scenes
Название папки: Scenes
Содержит: Папки Card/, Container/, FeedGrid/, Stats/.
Папка: Features/UserProfile/Scenes/Container
Название папки: Container
Содержит: UserProfileContainerViewController.swift.
Файл: Features/UserProfile/Scenes/Container/UserProfileContainerViewController.swift
Название файла: UserProfileContainerViewController.swift
Назначение файла: Контейнерный ViewController, управляющий переключением между вкладками Card, Person, Stats.
Описание: Получает userID и сервисы через метод configure. Создает экземпляры дочерних VC (UserProfileCardViewController, UserProfileFeedViewController, UserProfileStatsViewController) и их ViewModel'и (кроме Card VC). Отображает TopMenuView поверх контента и использует его делегата (TopMenuViewDelegate) для переключения между дочерними VC с помощью displayChildViewController. Обрабатывает нажатие кнопки "Назад" в TopMenuView, вызывая coordinator.dismissProfile().
Содержит: Класс UserProfileContainerViewController, lazy var для дочерних VC, lazy var для TopMenuView, метод configure, метод displayChildViewController, реализация TopMenuViewDelegate.
Технологии: UIKit.
Путь: UserProfileCoordinator.start() -> Создание и показ UserProfileContainerViewController.
