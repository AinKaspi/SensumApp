Файл: Features/UserProfile/Scenes/Card/UserProfileCardViewController.swift
Название файла: UserProfileCardViewController.swift
Назначение файла: UI для вкладки "Card" профиля пользователя.
Описание: Отображает фоновое изображение (аватар на весь экран) и информационный блок внизу (86% ширины) с мини-аватаром, именем, статусом, кнопкой Follow/Following, уровнем и XP. Использует UserProfileCardViewModel для получения данных и состояния подписки. Обновляет UI через Combine (setupBindings). Обрабатывает нажатие кнопки Follow, вызывая метод ViewModel.
Содержит: Класс UserProfileCardViewController, UI элементы, @objc методы, setupBindings, updateAvatar, configureFollowButton.
Технологии: UIKit, Combine, Kingfisher.
Путь: UserProfileContainerViewController -> displayChildViewController(cardVC).
