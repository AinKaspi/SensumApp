Файл: Features/Leveling/Analyzers/SquatAnalyzer3D.swift
Название файла: SquatAnalyzer3D.swift
Назначение файла: Анализатор для распознавания и подсчета приседаний.
Описание: Реализует протокол ExerciseAnalyzer. Принимает 3D-координаты позы (worldLandmarks), рассчитывает углы в коленях и бедрах с помощью angle3D, сглаживает их скользящим средним, определяет состояние пользователя (up/down) на основе пороговых значений углов и засчитывает повторение при переходе из down в up. Уведомляет своего делегата (ExerciseExecutionViewModel) о смене состояния и засчитанных повторениях.
Содержит: Класс SquatAnalyzer3D, enum State, enum LandmarkIndex (дублирует?), enum Thresholds, свойства для состояния и сглаживания, методы analyze, reset, angle3D, updateState, addAngleToHistory, calculateSmoothedAngle.
Технологии: Foundation, MediaPipeTasksVision, simd.
Путь: Создается и используется ExerciseExecutionViewModel.
