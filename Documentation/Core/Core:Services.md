Папка: Core/Services
Название папки: Services
Назначение папки: Содержит классы, инкапсулирующие логику взаимодействия с внешними системами (в основном Firebase) и выполняющие основные операции бизнес-логики.
Описание: Эта папка является сердцем бэкенд-взаимодействия приложения. Каждый сервис отвечает за определенную область данных или функциональности (аутентификация, профили, посты, прогресс, хранилище и т.д.). Они предоставляют четкие API (через протоколы) для ViewModel, скрывая детали реализации работы с Firestore, Firebase Storage и Firebase Auth. Сервисы создаются и управляются через DIContainer.
Содержит:
AuthService.swift
FollowService.swift
MessagingService.swift (заглушка)
NotificationService.swift (заглушка)
PostService.swift
ProgramService.swift (заглушка)
ProgressService.swift
StorageService.swift
UserProfileService.swift
Технологии: Foundation, FirebaseFirestore, FirebaseAuth, FirebaseStorage, Combine (в AuthService).
Путь: DIContainer создает экземпляры сервисов. ViewModel'и (в Features/*) получают экземпляры сервисов (через координаторы или DI) и вызывают их методы для загрузки/сохранения данных или выполнения действий.
