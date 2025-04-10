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
