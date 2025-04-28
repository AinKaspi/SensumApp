Папка: Features/Leveling/Helpers
Название папки: Helpers
Содержит: PoseLandmarkerHelper.swift.
Файл: Features/Leveling/Helpers/PoseLandmarkerHelper.swift
Название файла: PoseLandmarkerHelper.swift
Назначение файла: Класс-обертка для упрощения работы с PoseLandmarker из MediaPipe.
Описание: Инкапсулирует создание и настройку PoseLandmarker (из MediaPipeTasksVision). Предоставляет метод detectAsync для асинхронной обработки видеокадров (CVPixelBuffer). Получает результаты детекции поз (2D и 3D координаты, сегментацию) и передает их своему делегату (PoseLandmarkerHelperLiveStreamDelegate - реализуется ExerciseExecutionViewModel) через метод poseLandmarkerHelper(_:didFinishDetection:error:). Обрабатывает ошибки MediaPipe.
Содержит: Класс PoseLandmarkerHelper, протокол PoseLandmarkerHelperLiveStreamDelegate, структура ResultBundle, методы для инициализации (liveStreamPoseLandmarkerHelper), детекции (detectAsync), реализация PoseLandmarkerLiveStreamDelegate.
Технологии: Foundation, MediaPipeTasksVision, AVFoundation, UIKit (для UIImage.Orientation).
Путь: Создается в LevelingCoordinator. Передается и используется в ExerciseExecutionViewModel.
