Файл: Core/Models/AppNotification.swift
Название файла: AppNotification.swift
Назначение файла: Определение структуры данных для уведомлений внутри приложения.
Описание: Представляет уведомление. Содержит ID, ID получателя, тип уведомления (NotificationType), информацию об отправителе (опционально), связанном посте (опционально), тексте комментария (опционально), системное сообщение (опционально), статус прочтения и дату создания. Используется NotificationService (заглушка) и будет использоваться NotificationsViewModel/ViewController.
Содержит: Enum NotificationType (String, Codable), структура AppNotification (Codable, Identifiable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Путь: (В будущем) Бэкенд/Cloud Functions -> Firestore. NotificationService.fetchNotifications -> NotificationsViewModel -> NotificationsViewController.
