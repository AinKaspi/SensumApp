Файл: Features/Leveling/ViewControllers/ExerciseExecutionViewController.swift
Название файла: ExerciseExecutionViewController.swift
Назначение файла: UI экрана выполнения упражнения.
Описание: Основной экран тренировки. Настраивает и управляет AVCaptureSession для получения видео с фронтальной камеры. Отображает видеопоток в previewLayer. Использует PoseOverlayView для отрисовки 2D-скелета поверх видео. Отображает статистику (XP, цель, счетчик, таймер) и отладочную информацию. Реализует ExerciseExecutionViewModelViewDelegate для получения обновлений от ViewModel и отрисовки позы/статистики. Передает видеокадры в ViewModel для обработки.
Содержит: Класс ExerciseExecutionViewController, UI элементы (PoseOverlayView, AVCaptureVideoPreviewLayer, UILabel, UIProgressView и т.д.), реализация AVCaptureVideoDataOutputSampleBufferDelegate, ExerciseExecutionViewModelViewDelegate, методы setupAVSession, startSession, stopSession.
Технологии: UIKit, AVFoundation, MediaPipeTasksVision, SceneKit (частично, возможно, не используется).
Путь: LevelingCoordinator -> Создание и показ ExerciseExecutionViewController. Взаимодействует с ExerciseExecutionViewModel.
