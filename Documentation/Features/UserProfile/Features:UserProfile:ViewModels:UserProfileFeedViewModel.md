Файл: Features/UserProfile/ViewModels/UserProfileFeedViewModel.swift
Название файла: UserProfileFeedViewModel.swift
Назначение файла: Логика и состояние для UserProfileFeedViewController.
Описание: Загружает User, ProgressData и посты ([Post]) для указанного userID с помощью UserProfileService, ProgressService и PostService. Не реализует пагинацию для постов (загружает только первую страницу). Проверяет и обрабатывает статус подписки (isFollowing, followButtonTapped) через FollowService. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileFeedViewModel, @Published свойства, методы fetchAllUserData, checkFollowingStatus, followButtonTapped.
Технологии: Combine, Foundation.
Путь: Создается в CurrentUserProfileCoordinator или UserProfileContainerViewController. Используется UserProfileFeedViewController. Взаимодействует с UserProfileService, PostService, FollowService, ProgressService.
