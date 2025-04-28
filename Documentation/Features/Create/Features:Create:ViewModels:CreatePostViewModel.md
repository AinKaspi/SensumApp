Файл: Features/Create/ViewModels/CreatePostViewModel.swift
Название файла: CreatePostViewModel.swift
Назначение файла: Управление состоянием и логикой экрана создания поста.
Описание: Хранит выбранное изображение (selectedImage) и введенный текст (captionText). Содержит метод sharePost(), который:
Вызывает StorageService для загрузки selectedImage в Firebase Storage.
При успешной загрузке вызывает PostService.createPost, передавая URL загруженного изображения и captionText.
Управляет состоянием загрузки (isLoading) и ошибками (errorMessage).
Уведомляет делегата (delegate) об успешном завершении или ошибке.
Содержит: Класс CreatePostViewModel, протокол CreatePostViewModelDelegate, @Published свойства, метод sharePost().
Технологии: Combine, Foundation, UIKit (для UIImage).
Путь: Создается в UserProfileFeedViewController.showCreatePostScreen(). Вызывается sharePost() из CreatePostViewController. Взаимодействует с StorageService и PostService.
