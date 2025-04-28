Файл: Core/Models/ProgressData.swift
Название файла: ProgressData.swift
Назначение файла: Определение структуры данных для RPG-прогресса пользователя.
Описание: Хранит всю информацию, связанную с RPG-прогрессом: уровень, текущий опыт, опыт до следующего уровня, ранг и массив атрибутов. Также содержит структуру Attribute и перечисление AttributeType. Реализует Codable. Используется ProgressService для загрузки/обновления и ViewModel'ями (ExerciseExecutionViewModel, UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel) для отображения статистики.
Содержит: Структура ProgressData (Codable), структура Attribute (Codable), enum AttributeType (String, Codable, CaseIterable, Identifiable), свойства, CodingKeys, метод value(for:).
Технологии: Foundation, FirebaseFirestore.
Путь: ProgressService.fetchProgressData/updateProgressData/addXP <-> Firestore. ProgressService -> ViewModel'и (ExerciseExecutionViewModel, UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel) -> ViewControllers.
