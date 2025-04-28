Папка: Features/Leveling/ViewModels
Название папки: ViewModels
Содержит: ExerciseExecutionViewModel.swift, ExerciseSelectionViewModel.swift.
Файл: Features/Leveling/ViewModels/ExerciseExecutionViewModel.swift
Название файла: ExerciseExecutionViewModel.swift
Назначение файла: Основная логика выполнения упражнения.
Описание: Сердце фичи Leveling. Инициализируется с выбранным упражнением и PoseLandmarkerHelper. Обрабатывает видеокадры (processVideoFrame), передавая их в PoseLandmarkerHelper. Получает результаты детекции поз через PoseLandmarkerHelperLiveStreamDelegate. Применяет фильтр Калмана к 3D координатам. Передает сглаженные координаты в соответствующий ExerciseAnalyzer. Реализует ExerciseAnalyzerDelegate для получения событий о повторениях и смене состояния. Вызывает ProgressService.addXP для начисления опыта и обновления прогресса. Управляет таймерами и состояниями (подготовка, выполнение). Уведомляет ExerciseExecutionViewController об изменениях UI через ExerciseExecutionViewModelViewDelegate.
Содержит: Класс ExerciseExecutionViewModel, протокол ExerciseExecutionViewModelViewDelegate, реализация PoseLandmarkerHelperLiveStreamDelegate, ExerciseAnalyzerDelegate, методы processVideoFrame, fetchInitialData, startTimer, stopTimer и т.д.
Технологии: Combine, Foundation, AVFoundation, MediaPipeTasksVision, CoreMotion, simd.
Путь: Создается в LevelingCoordinator. Взаимодействует с ExerciseExecutionViewController, PoseLandmarkerHelper, ExerciseAnalyzer, ProgressService, UserProfileService, AuthService, MotionManager, KalmanFilter3D.
