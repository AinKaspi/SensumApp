Файл: Core/Models/User.swift
Название файла: User.swift
Назначение файла: Определение структуры данных для пользователя.
Описание: Представляет пользователя в системе. Содержит основные данные (ID, имя, email, URL аватара, статус), социальную статистику (подписчики, подписки) и дату создания. Реализует Codable и Identifiable. Использует @DocumentID для связи с ID документа Firestore. Поля followerCount и followingCount опциональны для совместимости с Firestore. Поля RPG (level, xp) удалены, так как они теперь в ProgressData. Используется UserProfileService для сохранения/загрузки и ViewModel'ями профиля для отображения.
Содержит: Структура User (Codable, Identifiable), свойства (id, username, email, avatarURL, status, followerCount?, followingCount?, createdAt), CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Путь: AuthService -> UserProfileService.createUserProfile (при регистрации). UserProfileService.fetchUserProfile -> ViewModel'и (UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, EditProfileViewModel).
