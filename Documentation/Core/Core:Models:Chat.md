Файл: Core/Models/Chat.swift
Название файла: Chat.swift
Назначение файла: Определение моделей данных для чатов и сообщений.
Описание: Содержит структуру Chat (информация о диалоге между двумя пользователями, включая ID участников, их денормализованные данные и информацию о последнем сообщении LastMessage), структуру LastMessage и структуру ChatMessage (отдельное сообщение). Используются MessagingService (заглушка) и будут использоваться компонентами чата.
Содержит: Структура Chat (Codable, Identifiable), структура LastMessage (Codable), структура ChatMessage (Codable, Identifiable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Путь: (В будущем) MessagingService <-> Firestore. MessagingService -> ChatListViewModel, ChatViewModel -> ChatListViewController, ChatViewController.
