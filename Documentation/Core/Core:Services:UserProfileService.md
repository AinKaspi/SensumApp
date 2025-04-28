Файл: Core/Services/UserProfileService.swift
Название файла: UserProfileService.swift
Назначение файла: Управление базовыми данными профиля пользователя (User) в Firestore.
Описание: Предоставляет методы для создания документа пользователя (createUserProfile), загрузки профиля по ID (fetchUserProfile) и частичного обновления профиля (updateUserProfile). Работает с коллекцией users в Firestore и моделью User.
Содержит: Протокол UserProfileServiceProtocol, класс UserProfileService, методы createUserProfile, fetchUserProfile, updateUserProfile.
Технологии: Foundation, FirebaseFirestore.
Путь: Создается в DIContainer. Используется RegisterViewModel (для createUserProfile), PostService (для fetchUserProfile при создании поста), EditProfileViewModel (для fetchUserProfile и updateUserProfile), UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel (для fetchUserProfile).
