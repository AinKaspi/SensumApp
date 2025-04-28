Папка: Features/UserProfile/Scenes/FeedGrid
Название папки: FeedGrid
Содержит: UserProfileFeedViewController.swift.
Файл: Features/UserProfile/Scenes/FeedGrid/UserProfileFeedViewController.swift
Название файла: UserProfileFeedViewController.swift
Назначение файла: UI для вкладки "Person" профиля (и свой, и чужой).
Описание: Отображает основной контент профиля в контейнере 86% ширины: шапка (аватар, статы), имя, статус, кнопки действий (Edit/New Post/New Program для своего профиля, Follow/Message для чужого), переключатель Posts/Programs и сетку постов (UICollectionView с PostGridCell). Использует UIScrollView для корректного отступа под TopMenuView. Реализует флоу создания нового поста (выбор фото через PHPicker, показ CreatePostViewController). Связан с UserProfileFeedViewModel через Combine для отображения данных и состояний. Реализует делегаты для обработки нажатий на кнопки, сегменты, ячейки сетки, завершения создания поста.
Содержит: Класс UserProfileFeedViewController, протокол UserProfileFeedViewControllerDelegate, UI элементы, lazy var свойства, @objc методы, setupBindings, configureActionButtons, логика PHPicker, реализация делегатов UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, CreatePostViewControllerDelegate.
Технологии: UIKit, Combine, Kingfisher, PhotosUI.
Путь: CurrentUserProfileCoordinator.start() ИЛИ UserProfileContainerViewController -> displayChildViewController(personFeedVC).
