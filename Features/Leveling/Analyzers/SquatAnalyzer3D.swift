import Foundation
import MediaPipeTasksVision // Импортируем для доступа к типам вроде NormalizedLandmark
// Импортируем simd для работы с 3D-векторами
import simd

// MARK: - Squat Analyzer Delegate Protocol -

/**
 Протокол для уведомления о событиях во время анализа приседаний.
 */
// Удаляем старый протокол SquatAnalyzerDelegate, используем ExerciseAnalyzerDelegate
/*
protocol SquatAnalyzerDelegate: AnyObject {
    /**
     Вызывается, когда засчитано одно полное приседание.
     - Parameter analyzer: Экземпляр ExerciseAnalyzer, который засчитал повторение.
     - Parameter totalCount: Общее количество засчитанных приседаний.
     */
    func squatAnalyzer(_ analyzer: ExerciseAnalyzer, didCountRepetition totalCount: Int)

    /**
     Вызывается при смене состояния (например, из "вверху" в "внизу" или наоборот).
     - Parameter analyzer: Экземпляр ExerciseAnalyzer.
     - Parameter newState: Новое состояние пользователя (например, "up", "down", "transitioning").
     */
    func squatAnalyzer(_ analyzer: ExerciseAnalyzer, didChangeState newState: String)
}
*/

// MARK: - Squat Analyzer Class -

/**
 Класс для анализа координат точек тела (landmarks) с целью определения
 выполнения приседаний и подсчета их количества.
 */
class SquatAnalyzer3D: ExerciseAnalyzer {

    // MARK: - Types
    // Вводим enum для состояний для большей ясности и безопасности
    enum State: String {
        case up = "up"
        case down = "down"
        case unknown = "unknown"
        // Можно добавить .transitioning, если нужна более сложная логика
    }

    // MARK: - Properties

    /// Делегат для получения уведомлений о событиях анализа (теперь нового типа)
    weak var delegate: ExerciseAnalyzerDelegate?

    /// Счетчик выполненных приседаний.
    private var squatCount: Int = 0

    /// Текущее состояние пользователя.
    private var currentState: State = .unknown

    // --- Свойства для сглаживания углов ---
    /// Размер окна для скользящего среднего.
    private let smoothingWindowSize = 3
    /// История последних углов колена для сглаживания.
    private var kneeAngleHistory: [Float] = []
    /// История последних углов бедра для сглаживания.
    private var hipAngleHistory: [Float] = []

    // Добавляем публичные свойства для доступа к последним углам
    private(set) var currentSmoothedKneeAngle: Float = 0.0
    private(set) var currentSmoothedHipAngle: Float = 0.0

    // MARK: - Constants (для индексов точек)
    // Переименовываем enum, чтобы избежать конфликта с типом Landmark из MediaPipe
    private enum LandmarkIndex { // Используем вложенный enum для ясности
        static let leftShoulder = 11
        static let rightShoulder = 12
        static let leftHip = 23
        static let rightHip = 24
        static let leftKnee = 25
        static let rightKnee = 26
        static let leftAnkle = 27
        static let rightAnkle = 28
        // Добавим запястья для возможного контроля рук в будущем
        static let leftWrist = 15
        static let rightWrist = 16
    }

    // Пороговые значения углов (в градусах) - НУЖНО БУДЕТ ПОДБИРАТЬ ЭКСПЕРИМЕНТАЛЬНО!
    private enum Thresholds {
        static let kneeUp: Float = 160.0
        static let kneeDown: Float = 125.0 // Порог для перехода UP -> DOWN
        static let kneeUpTransition: Float = 140.0 // Порог для перехода DOWN -> UP
        static let hipUp: Float = 165.0
        static let hipDown: Float = 125.0 // Порог для перехода UP -> DOWN
        static let hipUpTransition: Float = 145.0 // Порог для перехода DOWN -> UP
        // Значительно понижаем порог видимости для теста
        static let visibility: Float = 0.1
    }

    // MARK: - Initialization

    init(delegate: ExerciseAnalyzerDelegate? = nil) {
        self.delegate = delegate
        // Здесь можно будет добавить начальную настройку, если потребуется
    }

    // MARK: - Analysis Method

    /**
     Анализирует переданный набор 3D точек тела (world landmarks).
     - Parameter worldLandmarks: Массив 3D точек тела (`Landmark` из MediaPipe) для одного обнаруженного человека.
                                Landmark содержит x, y, z в метрах и visibility/presence.
     */
    // Уточняем тип параметра, используя полное имя с модулем
    func analyze(worldLandmarks: [MediaPipeTasksVision.Landmark]) {
        // Убедимся, что у нас достаточно точек для анализа
        // Используем новое имя enum для индексов
        guard worldLandmarks.count > LandmarkIndex.rightAnkle else {
            return
        }

        // --- 1. Извлекаем необходимые точки (теперь типа Landmark) --- 
        // Используем новое имя enum для индексов
        let leftHip = worldLandmarks[LandmarkIndex.leftHip]
        let rightHip = worldLandmarks[LandmarkIndex.rightHip]
        let leftKnee = worldLandmarks[LandmarkIndex.leftKnee]
        let rightKnee = worldLandmarks[LandmarkIndex.rightKnee]
        let leftAnkle = worldLandmarks[LandmarkIndex.leftAnkle]
        let rightAnkle = worldLandmarks[LandmarkIndex.rightAnkle]
        let leftShoulder = worldLandmarks[LandmarkIndex.leftShoulder]
        let rightShoulder = worldLandmarks[LandmarkIndex.rightShoulder]

        // Проверяем видимость ключевых точек (теперь используем visibility из Landmark)
        // Порог можно оставить прежним или скорректировать
        // Используем .floatValue для конвертации NSNumber? в Float
        guard (leftHip.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (rightHip.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (leftKnee.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (rightKnee.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (leftAnkle.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (rightAnkle.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (leftShoulder.visibility?.floatValue ?? 0.0) > Thresholds.visibility,
              (rightShoulder.visibility?.floatValue ?? 0.0) > Thresholds.visibility else
        {
            // Если ключевые точки не видны, пропускаем кадр
            // Можно также сбросить состояние или установить в .unknown
             updateState(newState: .unknown) // Сбрасываем в unknown для надежности
            return
        }

        // --- 2. Рассчитываем углы в 3D --- 
        // Используем новую функцию angle3D
        let leftKneeAngle = angle3D(
            firstPoint: leftHip,
            midPoint: leftKnee,
            lastPoint: leftAnkle
        )
        
        let rightKneeAngle = angle3D(
            firstPoint: rightHip,
            midPoint: rightKnee,
            lastPoint: rightAnkle
        )
        
        let leftHipAngle = angle3D(
            firstPoint: leftShoulder,
            midPoint: leftHip,
            lastPoint: leftKnee
        )
        
        let rightHipAngle = angle3D(
            firstPoint: rightShoulder,
            midPoint: rightHip,
            lastPoint: rightKnee
        )
        
        // Используем средние из рассчитанных углов (теперь они не опциональны, т.к. видимость проверена)
        let averageKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0
        let averageHipAngle = (leftHipAngle + rightHipAngle) / 2.0

        // --- Сглаживание углов ---
        addAngleToHistory(&kneeAngleHistory, angle: averageKneeAngle)
        addAngleToHistory(&hipAngleHistory, angle: averageHipAngle)

        // Сохраняем последние сглаженные углы
        currentSmoothedKneeAngle = calculateSmoothedAngle(from: kneeAngleHistory)
        currentSmoothedHipAngle = calculateSmoothedAngle(from: hipAngleHistory)

        // Определение состояния
        let potentialState: State
        if currentSmoothedKneeAngle >= Thresholds.kneeUp && currentSmoothedHipAngle >= Thresholds.hipUp {
            potentialState = .up
        } else if currentSmoothedKneeAngle <= Thresholds.kneeDown && currentSmoothedHipAngle <= Thresholds.hipDown {
            potentialState = .down
        } else {
            potentialState = currentState != .unknown ? currentState : .unknown 
        }
        
        // Обновляем состояние и счетчик (без лишних логов)
         switch currentState {
         case .unknown:
             if potentialState == .up {
                 updateState(newState: .up)
             } else if potentialState == .down {
                 updateState(newState: .down)
             }
         case .up:
             if potentialState == .down {
                 updateState(newState: .down)
             }
         case .down:
             if potentialState == .up { // Проверяем переход в .up по potentialState
                 // Только если переход действительно в UP (по порогам), считаем присед
                 if currentSmoothedKneeAngle >= Thresholds.kneeUpTransition && currentSmoothedHipAngle >= Thresholds.hipUpTransition {
                     updateState(newState: .up)
                     squatCount += 1
                     delegate?.exerciseAnalyzer(self, didCountRepetition: squatCount)
                 }
             }
         }
    }

    // MARK: - Reset Method

    /**
     Сбрасывает счетчик и внутреннее состояние анализатора.
     */
    func reset() {
        squatCount = 0
        // Устанавливаем начальное состояние
        currentState = .unknown // Или .up, если предполагаем, что начинаем сверху
        // Вызываем новый метод делегата
        delegate?.exerciseAnalyzer(self, didChangeState: currentState.rawValue)
        // Можно также уведомить о сбросе счетчика
        // delegate?.squatAnalyzerDidReset(self)
    }

    // MARK: - Private Helper Methods
    
    /**
     Рассчитывает угол между тремя 3D точками (в градусах).
     Угол измеряется в `midPoint`.
     - Parameters:
       - firstPoint: Первая точка (Landmark).
       - midPoint: Центральная точка (Landmark, вершина угла).
       - lastPoint: Конечная точка (Landmark).
     - Returns: Угол в градусах (0-180).
     */
    // Уточняем тип параметров, используя полное имя с модулем
    private func angle3D(firstPoint: MediaPipeTasksVision.Landmark, midPoint: MediaPipeTasksVision.Landmark, lastPoint: MediaPipeTasksVision.Landmark) -> Float {
        // Конвертируем точки в 3D векторы (используя simd)
        let firstVec = simd_float3(firstPoint.x, firstPoint.y, firstPoint.z)
        let midVec = simd_float3(midPoint.x, midPoint.y, midPoint.z)
        let lastVec = simd_float3(lastPoint.x, lastPoint.y, lastPoint.z)
        
        // Находим векторы от mid к first и от mid к last
        let vector1 = firstVec - midVec
        let vector2 = lastVec - midVec
        
        // Рассчитываем скалярное произведение
        let dotProduct = simd_dot(vector1, vector2)
        
        // Рассчитываем длины векторов
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)
        
        // Избегаем деления на ноль, если точки совпадают
        guard magnitude1 > .ulpOfOne && magnitude2 > .ulpOfOne else {
            // Если длина одного из векторов близка к нулю, угол не определен или 0
            return 0.0
        }
        
        // Рассчитываем косинус угла
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        
        // Ограничиваем значение косинуса диапазоном [-1, 1] из-за возможных ошибок точности
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        // Находим угол в радианах с помощью арккосинуса
        let angleRad = acos(clampedCosAngle)
        
        // Конвертируем радианы в градусы
        let angleDeg = angleRad * (180.0 / .pi)
        
        return angleDeg
    }
    
    /**
     Обновляет текущее состояние и уведомляет делегата, если состояние изменилось.
     */
    private func updateState(newState: State) {
        if newState == .unknown && currentState != .unknown { return }
        if newState != currentState {
            currentState = newState
            delegate?.exerciseAnalyzer(self, didChangeState: currentState.rawValue)
        }
    }

    // MARK: - Smoothing Helper Methods

    /// Добавляет угол в историю и удаляет старые значения, если история превышает размер окна.
    private func addAngleToHistory(_ history: inout [Float], angle: Float) {
        history.append(angle)
        if history.count > smoothingWindowSize {
            history.removeFirst()
        }
    }

    /// Рассчитывает сглаженный угол (среднее арифметическое) из истории.
    private func calculateSmoothedAngle(from history: [Float]) -> Float {
        guard !history.isEmpty else { return 0 } // Или другое значение по умолчанию?
        return history.reduce(0, +) / Float(history.count)
    }

} 
