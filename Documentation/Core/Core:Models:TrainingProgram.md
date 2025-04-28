Файл: Core/Models/TrainingProgram.swift
Название файла: TrainingProgram.swift
Назначение файла: Определение моделей данных для программ тренировок.
Описание: Содержит структуру TrainingProgram (основная информация о программе, включая массив шагов [ProgramStep]) и структуру ProgramStep (один шаг программы с указанием упражнения и цели). Модели реализуют Codable. Используются ProgramService (заглушка) и будут использоваться соответствующими ViewModel/VC для создания, просмотра и выполнения программ.
Содержит: Структура TrainingProgram (Codable, Identifiable), структура ProgramStep (Codable, Identifiable, Hashable), enum ProgramStep.TargetType (String, Codable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Путь: (В будущем) CreateProgramViewModel/VC -> ProgramService.createProgram/updateProgram. ProgramService.fetchUserPrograms/fetchProgram -> ViewModel'и (UserProfileFeedViewModel?, ProgramListViewModel?) -> ViewControllers. LevelingCoordinator/ViewModel -> ProgramService.fetchProgram для запуска.
