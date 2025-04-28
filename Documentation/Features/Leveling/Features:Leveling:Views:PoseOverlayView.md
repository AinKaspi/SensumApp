Файл: Features/Leveling/Views/PoseOverlayView.swift
Название файла: PoseOverlayView.swift
Назначение файла: Кастомный UIView для отрисовки 2D-скелета поверх видео.
Описание: Получает нормализованные 2D-координаты точек позы (NormalizedLandmark) и размер кадра через метод drawResult. В методе draw(_:) рисует точки (круги) и линии (соединения) скелета, преобразуя нормализованные координаты в координаты View. Использует константы PoseConnections для определения связей.
Содержит: Класс PoseOverlayView, метод drawResult, метод draw.
Технологии: UIKit, CoreGraphics.
Путь: Создается и используется в ExerciseExecutionViewController.
