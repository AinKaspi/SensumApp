Папка: Features/Leveling/Coordinators
Название папки: Coordinators
Содержит: LevelingCoordinator.swift.
Файл: Features/Leveling/Coordinators/LevelingCoordinator.swift
Название файла: LevelingCoordinator.swift
Назначение файла: Управление навигацией в рамках флоу выполнения упражнений (Таб 3).
Описание: Реализует Coordinator. В start показывает экран выбора упражнения (ExerciseSelectionViewController), создавая для него ExerciseSelectionViewModel. Реализует ExerciseSelectionViewModelCoordinatorDelegate: при выборе упражнения (exerciseSelectionViewModelDidSelect) создает ExerciseExecutionViewModel (передавая ему упражнение, PoseLandmarkerHelper, сервисы) и ExerciseExecutionViewController, а затем показывает экран выполнения упражнения (pushViewController). Инициализирует PoseLandmarkerHelper в фоновом потоке при своем создании. Получает зависимости (AuthService, ProgressService) через init.
Содержит: Класс LevelingCoordinator, реализация ExerciseSelectionViewModelCoordinatorDelegate, методы start, exerciseSelectionViewModelDidSelect, setupPoseLandmarkerHelperInBackground.
Технологии: UIKit, MediaPipeTasksVision.
Путь: AppCoordinator -> LevelingCoordinator.start() -> ExerciseSelectionViewController. ExerciseSelectionViewModel -> LevelingCoordinator.exerciseSelectionViewModelDidSelect() -> ExerciseExecutionViewController.
