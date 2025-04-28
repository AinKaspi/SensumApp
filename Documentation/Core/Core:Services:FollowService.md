Файл: Core/Services/FollowService.swift
Название файла: FollowService.swift
Назначение файла: Управление логикой подписок между пользователями.
Описание: Предоставляет методы для подписки (follow), отписки (unfollow) и проверки статуса подписки (checkIfFollowing, fetchFollowers, fetchFollowing). Работает с Firestore, обновляя счетчики followerCount и followingCount в документах пользователей (users collection) и создавая/удаляя документы в подколлекциях user-followers и user-following для хранения связей. Используется ViewModel'ями профиля (UserProfileFeedViewModel, UserProfileCardViewModel).
Содержит: Протокол FollowServiceProtocol, класс FollowService, методы follow, unfollow, checkIfFollowing, fetchFollowers, fetchFollowing.
Технологии: Foundation, FirebaseFirestore.
Путь: Создается в DIContainer. Используется UserProfileFeedViewModel, UserProfileCardViewModel для проверки и обновления статуса подписки.
