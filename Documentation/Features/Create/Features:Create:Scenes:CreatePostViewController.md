Файл: Features/Create/Scenes/CreatePostViewController.swift
Название файла: CreatePostViewController.swift
Назначение файла: UI-представление экрана создания нового поста.
Описание: Отображает выбранное изображение (postImageView), поле для ввода текста (captionTextView), кнопку "Поделиться" (shareButton) и кнопку отмены ("Назад"). Связан с CreatePostViewModel через Combine для отображения изображения, управления состоянием кнопки "Поделиться" и индикатора загрузки. При нажатии "Поделиться" вызывает viewModel.sharePost(). Уведомляет своего делегата (CreatePostViewControllerDelegate - реализуется UserProfileFeedViewController) о завершении (didFinishCreatingPost) или отмене (didCancelCreatingPost).
Содержит: Класс CreatePostViewController, протокол CreatePostViewControllerDelegate, UI элементы (UIImageView, UITextView, UIBarButtonItem), @objc методы, setupBindings(), setupViews(), setupConstraints().
Технологии: UIKit, Combine.
Путь: Создается и показывается модально из UserProfileFeedViewController.showCreatePostScreen(). Вызывает viewModel.sharePost(). Вызывает методы своего делегата (UserProfileFeedViewController) для закрытия.
