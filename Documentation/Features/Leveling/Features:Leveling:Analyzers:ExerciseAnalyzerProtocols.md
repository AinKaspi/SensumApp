Файл: Features/Leveling/Analyzers/ExerciseAnalyzerProtocols.swift
Название файла: ExerciseAnalyzerProtocols.swift
Назначение файла: Определение протоколов и констант для анализаторов упражнений.
Описание: Содержит протокол ExerciseAnalyzerDelegate (для обратной связи от анализатора к ViewModel о повторениях и смене состояния) и протокол ExerciseAnalyzer (основной интерфейс анализатора с методами analyze и reset). Также содержит enum PoseConnections с индексами ключевых точек MediaPipe и связями для отрисовки скелета.
Содержит: Протокол ExerciseAnalyzerDelegate, протокол ExerciseAnalyzer, enum PoseConnections (с вложенным LandmarkIndex).
Технологии: Foundation, MediaPipeTasksVision.
Путь: Протоколы реализуются классами анализаторов (SquatAnalyzer3D) и их делегатами (ExerciseExecutionViewModel).
