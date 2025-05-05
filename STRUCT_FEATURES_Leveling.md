### Features/Leveling

_Модуль отвечает за выполнение упражнений с использованием анализа движений (Pose Estimation) и связанную с этим логику._

*   `/Users/inga/Desktop/SensumApp/Features/Leveling`:
    *   `Analyzers/`: Содержит протоколы и конкретные реализации анализаторов упражнений.
        *   `ExerciseAnalyzerProtocols.swift`: Определяет основные протоколы для системы анализа упражнений: `ExerciseAnalyzerDelegate` (для уведомления о подсчете повторений и смене состояния) и `ExerciseAnalyzer` (интерфейс для конкретных анализаторов, требует метод `analyze(worldLandmarks:)` и `reset()`). Также содержит перечисление `PoseConnections` с индексами ключевых точек MediaPipe (`LandmarkIndex`) и списком соединений (`connections`) для отрисовки скелета.
        *   `SquatAnalyzer3D.swift`: Реализация `ExerciseAnalyzer` для анализа приседаний с использованием 3D-координат ключевых точек тела. Отслеживает состояния (вверх/вниз), углы суставов и считает повторения.
    *   `Coordinators/`: Координаторы для управления навигацией в фиче.
        *   `LevelingCoordinator.swift`: `class`. Координирует навигацию между экраном выбора упражнения (`ExerciseSelectionViewController`) и экраном выполнения (`ExerciseExecutionViewController`). Управляет запуском и завершением сессии упражнения, передает необходимые зависимости (сервисы, анализаторы) во ViewModel'и.
    *   `Helpers/`: Вспомогательные классы для работы с Pose Estimation.
        *   `PoseLandmarkerHelper.swift`: `class`. Обертка над `PoseLandmarker` от MediaPipe. Отвечает за инициализацию модели, конфигурацию, обработку входных данных (видеокадры или изображения) и асинхронное получение результатов (`PoseLandmarkerResult`). Уведомляет делегата (`PoseLandmarkerHelperDelegate`) о результатах или ошибках.
    *   `Utils/`: Утилиты, используемые в фиче Leveling.
        *   `KalmanFilter3D.swift`: `struct`. Реализация фильтра Калмана для сглаживания 3D-координат (вероятно, ключевых точек скелета), уменьшая шум и дрожание.
        *   `MotionManager.swift`: `class`. Обертка над `CMMotionManager` для получения данных об ориентации устройства (аттитюд). Используется для компенсации движения камеры.
        *   `PoseValidator.swift`: `class`. Проверяет валидность обнаруженной позы, например, наличие всех необходимых ключевых точек и их видимость.
    *   `ViewControllers/`: Экраны (ViewController'ы) фичи.
        *   `ExerciseExecutionViewController.swift`: `UIViewController`. Экран выполнения упражнения. Отображает видеопоток с камеры, наложение скелета (`PoseOverlayView`), счетчик повторений, таймер и другую информацию. Управляется `ExerciseExecutionViewModel`.
        *   `ExerciseSelectionViewController.swift`: `UIViewController`. Экран выбора упражнения (например, приседания). Вероятно, отображает список доступных упражнений. Управляется `ExerciseSelectionViewModel`.
    *   `ViewModels/`: ViewModel'и для экранов фичи.
        *   `ExerciseExecutionViewModel.swift`: `@MainActor ObservableObject`. Логика представления для `ExerciseExecutionViewController`. Обрабатывает данные от `PoseLandmarkerHelper`, передает их в `ExerciseAnalyzer`, получает результаты анализа (повторения, состояние), управляет таймером, состоянием UI (загрузка, выполнение, пауза, завершение).
        *   `ExerciseSelectionViewModel.swift`: `@MainActor ObservableObject`. Логика представления для `ExerciseSelectionViewController`. Отвечает за загрузку списка упражнений и передачу выбранного упражнения координатору.
    *   `Views/`: Кастомные View для фичи.
        *   `PoseOverlayView.swift`: `UIView`. Кастомное представление для отрисовки скелета (линии и точки) поверх видеопотока на основе данных `PoseLandmarkerResult`.