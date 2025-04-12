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
    enum LandmarkIndex: Int { 
        case nose = 0
        case leftEyeInner = 1, leftEye = 2, leftEyeOuter = 3
        case rightEyeInner = 4, rightEye = 5, rightEyeOuter = 6
        case leftEar = 7, rightEar = 8
        case mouthLeft = 9, mouthRight = 10
        case leftShoulder = 11, rightShoulder = 12
        case leftElbow = 13, rightElbow = 14
        case leftWrist = 15, rightWrist = 16
        case leftPinky = 17, rightPinky = 18
        case leftIndex = 19, rightIndex = 20
        case leftThumb = 21, rightThumb = 22
        case leftHip = 23, rightHip = 24
        case leftKnee = 25, rightKnee = 26
        case leftAnkle = 27, rightAnkle = 28
        case leftHeel = 29, rightHeel = 30
        case leftFootIndex = 31, rightFootIndex = 32
    }
    
    // Соединения для отрисовки скелета
    static let connections: [(start: Int, end: Int)] = [
        // Торс
        (start: LandmarkIndex.leftShoulder.rawValue, end: LandmarkIndex.rightShoulder.rawValue),
        (start: LandmarkIndex.leftShoulder.rawValue, end: LandmarkIndex.leftHip.rawValue),
        (start: LandmarkIndex.rightShoulder.rawValue, end: LandmarkIndex.rightHip.rawValue),
        (start: LandmarkIndex.leftHip.rawValue, end: LandmarkIndex.rightHip.rawValue),
        // Руки
        (start: LandmarkIndex.leftShoulder.rawValue, end: LandmarkIndex.leftElbow.rawValue),
        (start: LandmarkIndex.leftElbow.rawValue, end: LandmarkIndex.leftWrist.rawValue),
        (start: LandmarkIndex.rightShoulder.rawValue, end: LandmarkIndex.rightElbow.rawValue),
        (start: LandmarkIndex.rightElbow.rawValue, end: LandmarkIndex.rightWrist.rawValue),
        // Ноги
        (start: LandmarkIndex.leftHip.rawValue, end: LandmarkIndex.leftKnee.rawValue),
        (start: LandmarkIndex.leftKnee.rawValue, end: LandmarkIndex.leftAnkle.rawValue),
        (start: LandmarkIndex.rightHip.rawValue, end: LandmarkIndex.rightKnee.rawValue),
        (start: LandmarkIndex.rightKnee.rawValue, end: LandmarkIndex.rightAnkle.rawValue),
        // (Опционально) Стопы
        // (start: LandmarkIndex.leftAnkle.rawValue, end: LandmarkIndex.leftHeel.rawValue),
        // (start: LandmarkIndex.leftHeel.rawValue, end: LandmarkIndex.leftFootIndex.rawValue),
        // (start: LandmarkIndex.rightAnkle.rawValue, end: LandmarkIndex.rightHeel.rawValue),
        // (start: LandmarkIndex.rightHeel.rawValue, end: LandmarkIndex.rightFootIndex.rawValue),
        // (Опционально) Соединение лодыжки и пальца стопы
        // (start: LandmarkIndex.leftAnkle.rawValue, end: LandmarkIndex.leftFootIndex.rawValue),
        // (start: LandmarkIndex.rightAnkle.rawValue, end: LandmarkIndex.rightFootIndex.rawValue)
    ]
}
