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

    /// Время последнего вывода углов в лог (для троттлинга).
    private var lastAngleLogTime: TimeInterval = 0
    private let angleLogInterval: TimeInterval = 0.25 // Интервал вывода лога (в секундах)

    // --- Свойства для сглаживания углов ---
    /// Размер окна для скользящего среднего.
    private let smoothingWindowSize = 3
    /// История последних углов колена для сглаживания.
    private var kneeAngleHistory: [Float] = []
    /// История последних углов бедра для сглаживания.
    private var hipAngleHistory: [Float] = []

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
        static let kneeDown: Float = 125.0 // Порог для перехода UP -> DOWN
        static let kneeUpTransition: Float = 140.0 // Порог для перехода DOWN -> UP
        static let hipUp: Float = 165.0
        static let hipDown: Float = 125.0 // Порог для перехода UP -> DOWN
        static let hipUpTransition: Float = 145.0 // Порог для перехода DOWN -> UP
        // Порог видимости точки (0.0 - 1.0)
        static let visibility: Float = 0.5
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
        // Рассчитаем углы, только если все точки видны
        let leftKneeAngle = angle(
            firstPoint: leftHip,
            midPoint: leftKnee,
            lastPoint: leftAnkle
        )
        
        let rightKneeAngle = angle(
            firstPoint: rightHip,
            midPoint: rightKnee,
            lastPoint: rightAnkle
        )
        
        let leftHipAngle = angle(
            firstPoint: leftShoulder,
            midPoint: leftHip,
            lastPoint: leftKnee
        )
        
        let rightHipAngle = angle(
            firstPoint: rightShoulder,
            midPoint: rightHip,
            lastPoint: rightKnee
        )
        
        // Собираем валидные углы
        var validKneeAngles: [Float] = []
        if let angle = leftKneeAngle { validKneeAngles.append(angle) }
        if let angle = rightKneeAngle { validKneeAngles.append(angle) }
        
        var validHipAngles: [Float] = []
        if let angle = leftHipAngle { validHipAngles.append(angle) }
        if let angle = rightHipAngle { validHipAngles.append(angle) }

        // Если нет валидных углов для коленей или бедер, пропускаем анализ этого кадра
        guard !validKneeAngles.isEmpty, !validHipAngles.isEmpty else {
            // print("SquatAnalyzer: Skipping frame due to invisible key landmarks.")
            // Возможно, стоит установить состояние .unknown или оставить как есть?
            // updateState(newState: .unknown)
            return
        }

        // Используем средние из ВАЛИДНЫХ углов
        let averageKneeAngle = validKneeAngles.reduce(0, +) / Float(validKneeAngles.count)
        let averageHipAngle = validHipAngles.reduce(0, +) / Float(validHipAngles.count)

        // --- Сглаживание углов ---
        addAngleToHistory(&kneeAngleHistory, angle: averageKneeAngle)
        addAngleToHistory(&hipAngleHistory, angle: averageHipAngle)

        let smoothedKneeAngle = calculateSmoothedAngle(from: kneeAngleHistory)
        let smoothedHipAngle = calculateSmoothedAngle(from: hipAngleHistory)

        // Вывод углов для отладки (с троттлингом) - теперь выводим сглаженные!
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastAngleLogTime >= angleLogInterval {
            print(String(format: "Smoothed Angles - Knee: %.1f, Hip: %.1f", smoothedKneeAngle, smoothedHipAngle))
            lastAngleLogTime = currentTime // Обновляем время последнего лога
        }

        // --- 3. Определяем потенциальное новое состояние (используем сглаженные углы) --- 
        let potentialState: State
        if smoothedKneeAngle >= Thresholds.kneeUp && smoothedHipAngle >= Thresholds.hipUp {
            potentialState = .up
        } else if smoothedKneeAngle <= Thresholds.kneeDown && smoothedHipAngle <= Thresholds.hipDown {
            potentialState = .down
        } else {
            // Находимся в промежуточном состоянии, сохраняем предыдущее известное
            potentialState = currentState != .unknown ? currentState : .unknown 
            // или можно ввести .transitioning
            // potentialState = .transitioning 
        }

        // --- 4. Обновляем состояние и счетчик --- 
        switch currentState {
        case .unknown:
            // Начальное состояние, пытаемся определить как UP
            if potentialState == .up { // Начинаем всегда с UP
                currentState = .up
                print("--- Состояние приседания: UP ---")
            }
            
        case .up:
            // Если были вверху, проверяем, не опустились ли достаточно низко
            if potentialState == .down {
                currentState = .down
                print("--- Состояние приседания: DOWN ---")
            }
            
        case .down:
            // Если были внизу, проверяем, не поднялись ли достаточно высоко
            if smoothedKneeAngle >= Thresholds.kneeUpTransition && smoothedHipAngle >= Thresholds.hipUpTransition {
                currentState = .up
                // --- СЧИТАЕМ ПРИСЕДАНИЕ! --- 
                squatCount += 1
                delegate?.squatAnalyzer(self, didCountSquat: squatCount)
                print("--- Состояние приседания: UP ---")
                print(" >>>>> ПРИСЕДАНИЕ #\(squatCount) ЗАСЧИТАНО! <<<<< ")
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
     - Returns: Угол в градусах (0-180) или `nil`, если одна из точек не видна.
     */
    private func angle(firstPoint: NormalizedLandmark, midPoint: NormalizedLandmark, lastPoint: NormalizedLandmark) -> Float? {
        // Проверяем видимость всех трех точек
        // ОСТАВЛЯЕМ ЭТО ПОКА
        guard firstPoint.visibility as! Float > Thresholds.visibility,
              midPoint.visibility as! Float > Thresholds.visibility,
              lastPoint.visibility as! Float > Thresholds.visibility else {
            return nil // Возвращаем nil, если хотя бы одна точка не видна
        }
        
        // Напрямую используем координаты, так как они должны быть Float
        let fx = firstPoint.x
        let fy = firstPoint.y
        let mx = midPoint.x
        let my = midPoint.y
        let lx = lastPoint.x
        let ly = lastPoint.y
        
        // Явно преобразуем к Float прямо перед использованием в atan2,
        // чтобы обойти ошибку компилятора
        let radians = atan2(Float(ly - my), Float(lx - mx)) - atan2(Float(fy - my), Float(fx - mx))
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
