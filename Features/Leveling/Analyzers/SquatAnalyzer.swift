import Foundation
import MediaPipeTasksVision // Импортируем для доступа к типам вроде NormalizedLandmark

// MARK: - Squat Analyzer Delegate Protocol -

/**
 Протокол для уведомления о событиях во время анализа приседаний.
 */
protocol SquatAnalyzerDelegate: AnyObject {
    /**
     Вызывается, когда засчитано одно полное приседание.
     - Parameter analyzer: Экземпляр SquatAnalyzer, который засчитал повторение.
     - Parameter totalCount: Общее количество засчитанных приседаний.
     */
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat totalCount: Int)

    /**
     Вызывается при смене состояния (например, из "вверху" в "внизу" или наоборот).
     - Parameter analyzer: Экземпляр SquatAnalyzer.
     - Parameter newState: Новое состояние пользователя (например, "up", "down", "transitioning").
     */
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) // Тип состояния можно будет уточнить
}

// MARK: - Squat Analyzer Class -

/**
 Класс для анализа координат точек тела (landmarks) с целью определения
 выполнения приседаний и подсчета их количества.
 */
class SquatAnalyzer {

    // MARK: - Types
    // Вводим enum для состояний для большей ясности и безопасности
    enum State: String {
        case up = "up"
        case down = "down"
        case unknown = "unknown"
        // Можно добавить .transitioning, если нужна более сложная логика
    }

    // MARK: - Properties

    /// Делегат для получения уведомлений о событиях анализа.
    weak var delegate: SquatAnalyzerDelegate?

    /// Счетчик выполненных приседаний.
    private var squatCount: Int = 0

    /// Текущее состояние пользователя.
    private var currentState: State = .unknown

    // MARK: - Constants (для индексов точек)
    private enum Landmark { // Используем вложенный enum для ясности
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
        static let kneeDown: Float = 95.0
        static let hipUp: Float = 165.0
        static let hipDown: Float = 95.0
    }

    // MARK: - Initialization

    init(delegate: SquatAnalyzerDelegate? = nil) {
        self.delegate = delegate
        // Здесь можно будет добавить начальную настройку, если потребуется
        print("SquatAnalyzer initialized.")
    }

    // MARK: - Analysis Method

    /**
     Анализирует переданный набор точек тела (landmarks).
     Этот метод будет вызываться для каждого кадра с результатами от MediaPipe.
     - Parameter landmarks: Массив точек тела (`NormalizedLandmark`) для одного обнаруженного человека.
                            Предполагается, что это `result.landmarks[0]`, если `numPoses = 1`.
     */
    func analyze(landmarks: [NormalizedLandmark]) {
        // Убедимся, что у нас достаточно точек для анализа
        guard landmarks.count > Landmark.rightAnkle else { // Проверяем по максимальному индексу
            // print("SquatAnalyzer: Not enough landmarks to analyze (\(landmarks.count))")
            // Возможно, стоит сбросить состояние или уведомить об ошибке
            // updateState(newState: "error: not enough landmarks")
            return
        }

        // --- 1. Извлекаем необходимые точки --- 
        // Получаем точки по индексам. Они NormalizedLandmark, содержат x, y, z, visibility, presence.
        let leftHip = landmarks[Landmark.leftHip]
        let rightHip = landmarks[Landmark.rightHip]
        let leftKnee = landmarks[Landmark.leftKnee]
        let rightKnee = landmarks[Landmark.rightKnee]
        let leftAnkle = landmarks[Landmark.leftAnkle]
        let rightAnkle = landmarks[Landmark.rightAnkle]
        // Плечи нужны для расчета угла наклона корпуса (или угла бедра относительно плеча)
        let leftShoulder = landmarks[Landmark.leftShoulder]
        let rightShoulder = landmarks[Landmark.rightShoulder]

        // TODO: Добавить проверку visibility/presence для ключевых точек?
        // Если, например, колено не видно (visibility < порога), расчет угла будет неверным.

        // --- 2. Рассчитываем углы --- 
        // Рассчитаем углы для левой и правой стороны тела
        let leftKneeAngle = angle(
            firstPoint: leftHip,
            midPoint: leftKnee, // Угол в колене
            lastPoint: leftAnkle
        )
        
        let rightKneeAngle = angle(
            firstPoint: rightHip,
            midPoint: rightKnee, // Угол в колене
            lastPoint: rightAnkle
        )
        
        let leftHipAngle = angle(
            firstPoint: leftShoulder,
            midPoint: leftHip,    // Угол в бедре (относительно плеча)
            lastPoint: leftKnee
        )
        
        let rightHipAngle = angle(
            firstPoint: rightShoulder,
            midPoint: rightHip,    // Угол в бедре (относительно плеча)
            lastPoint: rightKnee
        )
        
        // Можно использовать средние углы или минимальный/максимальный для робастности
        let averageKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0
        let averageHipAngle = (leftHipAngle + rightHipAngle) / 2.0

        // Выводим углы для отладки
        // print(String(format: "Angles - Knee: %.1f, Hip: %.1f", averageKneeAngle, averageHipAngle))

        // --- 3. Определяем потенциальное новое состояние --- 
        let potentialState: State
        if averageKneeAngle >= Thresholds.kneeUp && averageHipAngle >= Thresholds.hipUp {
            potentialState = .up
        } else if averageKneeAngle <= Thresholds.kneeDown && averageHipAngle <= Thresholds.hipDown {
            potentialState = .down
        } else {
            // Находимся в промежуточном состоянии, сохраняем предыдущее известное
            potentialState = currentState != .unknown ? currentState : .unknown 
            // или можно ввести .transitioning
            // potentialState = .transitioning 
        }

        // --- 4. Обнаружение перехода и подсчет --- 
        // Проверяем переход из состояния "down" в "up" для подсчета
        if currentState == .down && potentialState == .up {
            countSquat() // Засчитываем приседание при подъеме
        }

        // --- 5. Обновляем текущее состояние --- 
        // Вызываем метод обновления, который также уведомит делегата при изменении
        updateState(newState: potentialState)
    }

    // MARK: - Reset Method

    /**
     Сбрасывает счетчик и внутреннее состояние анализатора.
     */
    func reset() {
        squatCount = 0
        // Устанавливаем начальное состояние
        currentState = .unknown // Или .up, если предполагаем, что начинаем сверху
        print("SquatAnalyzer reset.")
        // Уведомляем делегата об изменении состояния на начальное
        delegate?.squatAnalyzer(self, didChangeState: currentState.rawValue)
        // Можно также уведомить о сбросе счетчика
        // delegate?.squatAnalyzerDidReset(self)
    }

    // MARK: - Private Helper Methods
    
    /**
     Рассчитывает угол между тремя точками (в градусах).
     Угол измеряется в `midPoint`.
     - Parameters:
       - firstPoint: Первая точка.
       - midPoint: Центральная точка (вершина угла).
       - lastPoint: Конечная точка.
     - Returns: Угол в градусах (0-180) или 0, если точки совпадают или лежат на одной линии некорректно.
     */
    private func angle(firstPoint: NormalizedLandmark, midPoint: NormalizedLandmark, lastPoint: NormalizedLandmark) -> Float {
        // Используем координаты x и y (z можно добавить для 3D анализа, если нужно)
        // Расчет угла через atan2 для большей стабильности, чем acos
        
        let radians = atan2(lastPoint.y - midPoint.y, lastPoint.x - midPoint.x) - atan2(firstPoint.y - midPoint.y, firstPoint.x - midPoint.x)
        var degrees = abs(radians * 180.0 / .pi)
        
        // Угол должен быть <= 180
        if degrees > 180.0 {
            degrees = 360.0 - degrees
        }
        
        return degrees
    }
    
    /**
     Обновляет текущее состояние и уведомляет делегата, если состояние изменилось.
     */
    private func updateState(newState: State) {
        // Не обновляем, если новое состояние неизвестно и текущее уже было установлено
        if newState == .unknown && currentState != .unknown {
            return 
        }
        
        if newState != currentState {
            currentState = newState
            // Передаем rawValue (строку) делегату
            delegate?.squatAnalyzer(self, didChangeState: currentState.rawValue)
            // print("SquatAnalyzer: State changed to \(currentState.rawValue)")
        }
    }
    
    /**
     Увеличивает счетчик приседаний и уведомляет делегата.
     */
    private func countSquat() {
        squatCount += 1
        delegate?.squatAnalyzer(self, didCountSquat: squatCount)
         print("SquatAnalyzer: Squat counted! Total: \(squatCount)")
    }

} 