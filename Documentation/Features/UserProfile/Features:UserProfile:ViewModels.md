Папка: Features/UserProfile/ViewModels
Название папки: ViewModels
Содержит: UserProfileCardViewModel.swift, UserProfileFeedViewModel.swift, UserProfileStatsViewModel.swift. (Файл PersonViewModel.swift должен быть удален).
Файл: Features/UserProfile/ViewModels/UserProfileCardViewModel.swift
Название файла: UserProfileCardViewModel.swift
Назначение файла: Логика и состояние для UserProfileCardViewController.
Описание: Загружает User и ProgressData для указанного userID с помощью UserProfileService и ProgressService. Проверяет статус подписки через FollowService (если это не профиль текущего пользователя). Обрабатывает нажатие кнопки Follow, вызывая FollowService и оптимистично обновляя состояние isFollowing. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileCardViewModel, @Published свойства, методы fetchCardData, checkFollowingStatus, followButtonTapped, refreshData.
Технологии: Combine, Foundation.
Путь: Создается в UserProfileContainerViewController. Используется UserProfileCardViewController. Взаимодействует с UserProfileService, ProgressService, FollowService.
