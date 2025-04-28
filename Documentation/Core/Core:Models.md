Папка: Core/Models
Название папки: Models
Назначение папки: Определение структур данных (моделей), используемых во всем приложении, особенно для представления данных, хранящихся в Firestore.
Описание: Эта папка содержит основные модели данных приложения: User (информация о пользователе), Post (данные поста), Comment (данные комментария - ошибка: файл Comment.swift находится в Models/, а не Core/Models/), ProgressData (RPG-статистика), Attribute (атрибуты внутри ProgressData), AppNotification (уведомления), TrainingProgram и ProgramStep (программы тренировок). Эти модели реализуют Codable для легкого кодирования/декодирования при работе с Firestore. Они используются сервисами (Core/Services) для получения и сохранения данных, а также ViewModel'ями (Features/*) для отображения данных в UI.
Содержит:
User.swift
Post.swift
ProgressData.swift (включая Attribute и AttributeType)
AppNotification.swift (включая NotificationType)
TrainingProgram.swift (включая ProgramStep)
Chat.swift (включая LastMessage и ChatMessage)
Ожидается также Comment.swift (находится в /Models/)
Отсутствует: Exercise.swift (находится в Features/Leveling/Models/)
Технологии: Foundation, FirebaseFirestore.
Путь: Модели используются сервисами при получении данных из Firestore или перед их сохранением. ViewModel'и получают эти модели от сервисов и используют их для подготовки данных к отображению в ViewControllers.
Исправление: Модель Comment.swift находится в корневой папке Models/, а не в Core/Models/. Модель Exercise.swift находится в Features/Leveling/Models/. Это небольшое несоответствие в структуре.
