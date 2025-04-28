Файл: Core/Services/ProgressService.swift
Название файла: ProgressService.swift
Назначение файла: Управление RPG-прогрессом пользователя.
Описание: Предоставляет методы для загрузки (`fetchProgressData`) и обновления (`updateProgressData`, `addXP`) данных `ProgressData` в Firestore. Метод `addXP` инкапсулирует логику добавления опыта (с учетом бонуса XP, рассчитываемого функцией `calculateXpBonus` на основе атрибутов STR и CON), повышения уровня (с расчетом `xpToNextLevel`), обновления ранга (`calculateRank`) и применения прироста атрибутов (`applyAttributeGains`). Используется ViewModel'ями, связанными с отображением или изменением прогресса.
Содержит: Протокол `ProgressServiceProtocol`, класс `ProgressService`, методы `fetchProgressData`, `updateProgressData`, `addXP`, `calculateRank`, `calculateXPForLevel`, `calculateXpBonus`, `applyAttributeGains`.
Технологии: Foundation, FirebaseFirestore, FirebaseFirestoreSwift.
Путь: Создается в DIContainer. Используется RegisterViewModel (для создания), ExerciseExecutionViewModel (для addXP), UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel (для fetchProgressData).
