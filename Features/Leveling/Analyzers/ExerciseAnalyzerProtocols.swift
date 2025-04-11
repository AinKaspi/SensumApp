import Foundation
import MediaPipeTasksVision // Нужен для типа Landmark

// MARK: - Exercise Analyzer Delegate Protocol

/**
 Протокол для уведомления о событиях во время анализа УПРАЖНЕНИЯ.
 */
protocol ExerciseAnalyzerDelegate: AnyObject {
    /**
     Вызывается, когда засчитано одно ПОЛНОЕ ПОВТОРЕНИЕ упражнения.
     - Parameter analyzer: Экземпляр ExerciseAnalyzer, который засчитал повторение.
     - Parameter totalCount: Общее количество засчитанных повторений за сессию.
     */
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didCountRepetition totalCount: Int)

    /**
     Вызывается при смене состояния выполнения упражнения.
     - Parameter analyzer: Экземпляр ExerciseAnalyzer.
     - Parameter newState: Новое состояние (зависит от конкретного упражнения).
     */
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didChangeState newState: String)
    
    // TODO: Можно добавить другие методы, например, для ошибок или промежуточных событий
}

// MARK: - Exercise Analyzer Protocol

/**
 Протокол, определяющий интерфейс для анализаторов конкретных упражнений.
 */
protocol ExerciseAnalyzer {
    /// Делегат для получения уведомлений о событиях анализа.
    var delegate: ExerciseAnalyzerDelegate? { get set }
    
    /**
     Анализирует переданный набор 3D точек тела.
     - Parameter worldLandmarks: Массив 3D точек тела (`Landmark` из MediaPipe).
     */
    func analyze(worldLandmarks: [Landmark])
    
    /**
     Сбрасывает внутреннее состояние анализатора (счетчики, текущее состояние).
     */
    func reset()
}

// Добавляем константы для соединений и индексов
enum PoseConnections {
    static let visibilityThreshold: Float = 0.1 // Порог видимости
    
    // Индексы ключевых точек MediaPipe Pose
    enum LandmarkIndex { 
        static let nose = 0
        static let leftEyeInner = 1
        static let leftEye = 2
        static let leftEyeOuter = 3
        static let rightEyeInner = 4
        static let rightEye = 5
        static let rightEyeOuter = 6
        static let leftEar = 7
        static let rightEar = 8
        static let mouthLeft = 9
        static let mouthRight = 10
        static let leftShoulder = 11
        static let rightShoulder = 12
        static let leftElbow = 13
        static let rightElbow = 14
        static let leftWrist = 15
        static let rightWrist = 16
        static let leftPinky = 17
        static let rightPinky = 18
        static let leftIndex = 19
        static let rightIndex = 20
        static let leftThumb = 21
        static let rightThumb = 22
        static let leftHip = 23
        static let rightHip = 24
        static let leftKnee = 25
        static let rightKnee = 26
        static let leftAnkle = 27
        static let rightAnkle = 28
        static let leftHeel = 29
        static let rightHeel = 30
        static let leftFootIndex = 31
        static let rightFootIndex = 32
    }
    
    // Соединения для отрисовки скелета
    static let connections: [(start: Int, end: Int)] = [
        // Торс
        (start: LandmarkIndex.leftShoulder, end: LandmarkIndex.rightShoulder),
        (start: LandmarkIndex.leftShoulder, end: LandmarkIndex.leftHip),
        (start: LandmarkIndex.rightShoulder, end: LandmarkIndex.rightHip),
        (start: LandmarkIndex.leftHip, end: LandmarkIndex.rightHip),
        // Руки
        (start: LandmarkIndex.leftShoulder, end: LandmarkIndex.leftElbow),
        (start: LandmarkIndex.leftElbow, end: LandmarkIndex.leftWrist),
        (start: LandmarkIndex.rightShoulder, end: LandmarkIndex.rightElbow),
        (start: LandmarkIndex.rightElbow, end: LandmarkIndex.rightWrist),
        // Ноги
        (start: LandmarkIndex.leftHip, end: LandmarkIndex.leftKnee),
        (start: LandmarkIndex.leftKnee, end: LandmarkIndex.leftAnkle),
        (start: LandmarkIndex.rightHip, end: LandmarkIndex.rightKnee),
        (start: LandmarkIndex.rightKnee, end: LandmarkIndex.rightAnkle),
        // (Опционально) Стопы
        // (start: LandmarkIndex.leftAnkle, end: LandmarkIndex.leftHeel),
        // (start: LandmarkIndex.leftHeel, end: LandmarkIndex.leftFootIndex),
        // (start: LandmarkIndex.rightAnkle, end: LandmarkIndex.rightHeel),
        // (start: LandmarkIndex.rightHeel, end: LandmarkIndex.rightFootIndex),
        // (Опционально) Соединение лодыжки и пальца стопы
        // (start: LandmarkIndex.leftAnkle, end: LandmarkIndex.leftFootIndex),
        // (start: LandmarkIndex.rightAnkle, end: LandmarkIndex.rightFootIndex)
    ]
}
