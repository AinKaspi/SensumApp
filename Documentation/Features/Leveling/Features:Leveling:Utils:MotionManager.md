Файл: Features/Leveling/Utils/MotionManager.swift
Название файла: MotionManager.swift
Назначение файла: Обёртка для работы с CMMotionManager.
Описание: Singleton (shared), предоставляющий доступ к данным гироскопа и акселерометра через CoreMotion. Запускает (startUpdates) и останавливает (stopUpdates) получение данных об ориентации устройства (currentAttitude). Используется для получения кватерниона ориентации, который (пока закомментировано) может применяться для преобразования координат позы в мировую систему.
Содержит: Класс MotionManager, свойства motionManager, currentAttitude, методы startUpdates, stopUpdates.
Технологии: CoreMotion, simd.
Путь: Используется ExerciseExecutionViewModel для получения deviceAttitude.
