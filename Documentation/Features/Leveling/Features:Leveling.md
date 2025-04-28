Папка: Features/Leveling
Название папки: Leveling
Назначение папки: Реализация основного игрового цикла - выбор и выполнение упражнений с AI-анализом для получения XP и прокачки.
Описание: Это одна из самых сложных фичей. Содержит координатор, экраны выбора и выполнения упражнения, ViewModel'и для них, модели данных (Exercise), специализированные классы-анализаторы для конкретных упражнений (Analyzers), хелперы для работы с MediaPipe (Helpers) и другие утилиты (например, фильтры Калмана). ViewModel (ExerciseExecutionViewModel) тесно интегрирована с PoseLandmarkerHelper, анализаторами и ProgressService для обработки позы, подсчета повторений и начисления наград.
Содержит: Папки Analyzers/, Coordinators/, Helpers/, Models/, Utils/, ViewControllers/, ViewModels/, Views/.
Технологии: UIKit, Combine, MediaPipeTasksVision, AVFoundation, CoreMotion, simd.
Путь: AppCoordinator -> LevelingCoordinator.start() -> ExerciseSelectionViewController -> (выбор упражнения) -> LevelingCoordinator.exerciseSelectionViewModelDidSelect() -> ExerciseExecutionViewController.
