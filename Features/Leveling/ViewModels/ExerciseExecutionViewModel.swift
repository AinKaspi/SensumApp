import Foundation
import AVFoundation // Для AVFoundation типов, если понадобятся
// Добавляем необходимые импорты
import MediaPipeTasksVision
import UIKit // Для UIImage

// Определяем протокол для связи ViewModel -> View
protocol ExerciseExecutionViewModelViewDelegate: AnyObject {
    func viewModelDidUpdateTimer(timeString: String)
    func viewModelDidUpdateProgress(currentXP: Int, xpToNextLevel: Int)
    func viewModelDidUpdateGoal(current: Int, target: Int)
    // Изменяем метод для передачи 2D-координат и размера кадра
    func viewModelDidUpdatePose(landmarks: [[NormalizedLandmark]]?, frameSize: CGSize)
    // Добавляем методы для отладочной информации
    func viewModelDidUpdateDebugState(_ state: String)
    func viewModelDidUpdateDebugAngles(knee: Float, hip: Float)
    func viewModelDidUpdateDebugRepCount(_ count: Int)
    // Обновляем метод видимости: передаем массив видимостей для всех точек
    func viewModelDidUpdateDebugVisibility(visibilities: [Float]?)
    // TODO: Добавить методы для сообщения о повышении уровня, ошибках и т.д.
}

class ExerciseExecutionViewModel: NSObject { // Наследуемся от NSObject для соответствия протоколам делегатов

    // MARK: - Dependencies
    private let exercise: Exercise
    private var userProfile: UserProfile?
    // Используем протокол ExerciseAnalyzer
    private var analyzer: ExerciseAnalyzer?
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue.execVM") // Отдельная очередь для VM
    
    // --- Параметры MediaPipe --- 
    private let modelPath = "pose_landmarker_full.task"
    private let numPoses = 1
    private let minPoseDetectionConfidence: Float = 0.5
    private let minPosePresenceConfidence: Float = 0.5
    private let minTrackingConfidence: Float = 0.5
    private let computeDelegate: Delegate = .GPU
    
    // MARK: - State
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?
    private let timerUpdateInterval: TimeInterval = 1.0
    // Троттлинг логов
    private var lastPoseLogTime: TimeInterval = 0
    private let poseLogInterval: TimeInterval = 0.5
    // Таймер для логгирования видимости
    private var visibilityLogTimer: Timer?
    private let visibilityLogInterval: TimeInterval = 0.5
    // Хранение последней известной информации о видимости (ВОЗВРАЩАЕМ)
    private var lastVisibilityStatus: (allVisible: Bool, average: Float)?
    
    // Состояние подготовки и обратного отсчета
    private(set) var isPreparing: Bool = false // Флаг, что идет подготовка
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3
    // Свойства для прогрессивной цели
    private var progressiveSquatGoal: Int = 5
    private let progressiveGoalIncrement: Int = 5
    private var squatsTowardsProgressiveGoal: Int = 0
    private let bonusXPForGoal: Int = 50 // Базовый бонус за цель
    // Добавляем свойство для хранения размера кадра
    private var currentFrameSize: CGSize = .zero
    
    // MARK: - Delegate
    weak var viewDelegate: ExerciseExecutionViewModelViewDelegate?

    init(exercise: Exercise, viewDelegate: ExerciseExecutionViewModelViewDelegate?) {
        self.exercise = exercise
        self.userProfile = DataManager.shared.getCurrentUserProfile()
        self.viewDelegate = viewDelegate // Сохраняем делегата
        super.init() // Нужно вызвать super.init(), так как наследуемся от NSObject
        print("[ViewModel INIT] viewDelegate is \(viewDelegate == nil ? "NIL" : "SET")") // Проверяем делегат
        
        // Создаем нужный анализатор в зависимости от упражнения
        setupAnalyzer(for: exercise)
        
        // Назначаем себя делегатом анализатора
        self.analyzer?.delegate = self 
        // Запускаем настройку MediaPipe в фоновой очереди
        sessionQueue.async {
            self.setupPoseLandmarker()
        }
        // Сообщаем View начальное время (00:00)
        viewDelegate?.viewModelDidUpdateTimer(timeString: "00:00")
    }
    
    // MARK: - Public Methods (для View Controller)
    func viewDidLoad() {
        // Логика viewDidLoad, если нужна (например, первичная загрузка данных)
    }
    
    func viewDidAppear() {
        // Запускаем таймер ПОДГОТОВКИ, а не основной
        startPreparationTimer()
        /*
        if sessionStartDate == nil {
            startTimer()
            analyzer?.reset()
        }
        */
        // TODO: Запустить сессию камеры (если она управляется отсюда)
    }
    
    func viewWillDisappear() {
        stopTimer() // Останавливаем основной таймер
        stopPreparationTimer() // Останавливаем таймер подготовки
        // TODO: Остановить сессию камеры (если она управляется отсюда)
    }
    
    // MARK: - MediaPipe Handling
    // Переносим метод настройки
    private func setupPoseLandmarker() {
        // Убедимся, что файл модели существует
        guard let modelPath = Bundle.main.path(forResource: self.modelPath, ofType: nil) else {
            // TODO: Обработать ошибку (например, сообщить View)
            return
        }

        // Создаем хелпер
        self.poseLandmarkerHelper = PoseLandmarkerHelper.liveStreamPoseLandmarkerHelper(
            modelPath: modelPath,
            numPoses: self.numPoses,
            minPoseDetectionConfidence: self.minPoseDetectionConfidence,
            minPosePresenceConfidence: self.minPosePresenceConfidence,
            minTrackingConfidence: self.minTrackingConfidence,
            liveStreamDelegate: self, // Устанавливаем СЕБЯ делегатом
            computeDelegate: self.computeDelegate
        )
        
        if poseLandmarkerHelper == nil {
            // TODO: Обработать ошибку
        } else {
        }
    }
    
    // MARK: - Analyzer Setup
    /// Создает и настраивает анализатор для выбранного упражнения
    private func setupAnalyzer(for exercise: Exercise) {
        switch exercise.id {
        case "squats":
            self.analyzer = SquatAnalyzer3D(delegate: self)
        // TODO: Добавить кейсы для других упражнений
        // case "pushups":
        //    self.analyzer = PushupAnalyzer(delegate: self)
        default:
            self.analyzer = nil
        }
    }
    
    /// Метод для получения кадра от ViewController
    func processVideoFrame(pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation, timeStamps: Int, frameSize: CGSize) {
        // Сохраняем размер кадра
        self.currentFrameSize = frameSize
        
        // Передаем пиксельный буфер в хелпер 
         poseLandmarkerHelper?.detectAsync(
            pixelBuffer: pixelBuffer,
            orientation: orientation, 
            timeStamps: timeStamps
        )
    }

    // MARK: - Exercise Analysis Handling
    // TODO: Перенести логику обработки результатов анализатора, расчета XP/атрибутов

    // MARK: - Timer Handling
    
    // --- Таймер подготовки (Обратный отсчет) ---
    private func startPreparationTimer() {
        guard !isPreparing else { return } // Не запускаем, если уже идет
        
        isPreparing = true
        countdownValue = 3 // Начальное значение
        stopPreparationTimer() // На всякий случай остановим старый
        
        // Сообщаем View, чтобы показала обратный отсчет
        // TODO: viewDelegate?.viewModelDidStartPreparation(initialValue: countdownValue)
        
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                              target: self,
                                              selector: #selector(updatePreparationTimer),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    private func stopPreparationTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    @objc private func updatePreparationTimer() {
        countdownValue -= 1
        
        if countdownValue > 0 {
            // Сообщаем View новое значение
            // TODO: viewDelegate?.viewModelDidUpdateCountdown(value: countdownValue)
        } else {
            // Обратный отсчет завершен
            stopPreparationTimer()
            isPreparing = false
            print("--- ExerciseExecutionVM: Подготовка завершена --- ")
            startTimer()
             // Запускаем таймер видимости ПОСЛЕ подготовки
             startVisibilityLogTimer() 
             analyzer?.reset() 
        }
    }
    
    // --- Основной таймер сессии ---
    private func startTimer() {
        guard sessionTimer == nil else { return } // Не запускаем, если уже идет
        stopTimer() // Убедимся, что предыдущий остановлен
        sessionStartDate = Date()
        // Сообщаем View начальное время (00:00)
        // TODO: viewDelegate?.viewModelDidUpdateTime(timeString: "00:00")
        
        sessionTimer = Timer.scheduledTimer(timeInterval: timerUpdateInterval,
                                            target: self,
                                            selector: #selector(updateTimer),
                                            userInfo: nil,
                                            repeats: true)
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopVisibilityLogTimer()
    }

    @objc private func updateTimer() {
        guard let startDate = sessionStartDate else { return }
        let elapsedTime = Int(Date().timeIntervalSince(startDate))
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        // Сообщаем View обновленное время
        viewDelegate?.viewModelDidUpdateTimer(timeString: timeString)
    }

    // --- Таймер логгирования видимости ---
    private func startVisibilityLogTimer() {
        stopVisibilityLogTimer() // Остановим предыдущий, если был
        print("[ViewModel TIMER] Starting visibility log timer...") // Лог запуска таймера
        visibilityLogTimer = Timer.scheduledTimer(timeInterval: visibilityLogInterval,
                                              target: self,
                                              selector: #selector(logVisibility),
                                              userInfo: nil,
                                              repeats: true)
    }

    private func stopVisibilityLogTimer() {
        if visibilityLogTimer != nil { print("[ViewModel TIMER] Stopping visibility log timer.") }
        visibilityLogTimer?.invalidate()
        visibilityLogTimer = nil
    }

    @objc private func logVisibility() {
        if let status = lastVisibilityStatus {
            let statusText = status.allVisible ? "OK" : "BAD"
            // Раскомментируем лог видимости
            print(String(format: "[VISIBILITY LOG] Status: %@, Average: %.2f", statusText, status.average))
        } else {
            // print("[VISIBILITY LOG] No visibility data yet.")
        }
    }
}

// TODO: Добавить реализацию делегатов (PoseLandmarkerHelper, ExerciseAnalyzer) в extension

// Добавляем extension для делегата PoseLandmarkerHelper
extension ExerciseExecutionViewModel: PoseLandmarkerHelperLiveStreamDelegate {
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper, 
                              didFinishDetection resultBundle: ResultBundle?, 
                              error: Error?) {
        // print("[ViewModel DELEGATE] poseLandmarkerHelper callback received.")
        
        guard !isPreparing else { return }
        
        if let error = error {
            print("ExerciseExecutionVM Ошибка детекции поз: \(error.localizedDescription)")
            return
        }
        
        // --- Логируем результат --- 
        guard let resultBundle = resultBundle else {
             print("[ViewModel DELEGATE] resultBundle is NIL")
            // Передаем nil во View для очистки
            viewDelegate?.viewModelDidUpdatePose(landmarks: nil, frameSize: self.currentFrameSize)
            return
        }
        
        let landmarksForLog = resultBundle.poseLandmarks
        let worldLandmarksForLog = resultBundle.poseWorldLandmarks
        let landmarksCount = landmarksForLog?.first?.count ?? 0
        let worldLandmarksCount = worldLandmarksForLog?.first?.count ?? 0
        // --- ТЕПЕРЬ ОБРАБАТЫВАЕМ РЕЗУЛЬТАТ, Т.К. ОН НЕ NIL ---
        
        // Передаем 3D точки в анализатор и получаем информацию для отладки
        if let worldLandmarks = resultBundle.poseWorldLandmarks,
           let firstPoseWorldLandmarks = worldLandmarks.first,
           !firstPoseWorldLandmarks.isEmpty {
            
            // Перемещаем проверку видимости СЮДА, после guard let resultBundle
            // --- Собираем информацию о видимости --- 
            var visibleCount = 0
            var totalVisibility: Float = 0.0
            // Используем PoseConnections.LandmarkIndex
            let keyIndices = [PoseConnections.LandmarkIndex.leftHip, PoseConnections.LandmarkIndex.rightHip, 
                              PoseConnections.LandmarkIndex.leftKnee, PoseConnections.LandmarkIndex.rightKnee, 
                              PoseConnections.LandmarkIndex.leftAnkle, PoseConnections.LandmarkIndex.rightAnkle, 
                              PoseConnections.LandmarkIndex.leftShoulder, PoseConnections.LandmarkIndex.rightShoulder]
            var allKeyPointsVisible = true
            for index in keyIndices {
                if index < firstPoseWorldLandmarks.count {
                    // Используем PoseConnections.visibilityThreshold
                    let visibility = firstPoseWorldLandmarks[index].visibility?.floatValue ?? 0.0
                    if visibility > PoseConnections.visibilityThreshold {
                        visibleCount += 1
                        totalVisibility += visibility
                    } else {
                        allKeyPointsVisible = false
                    }
                } else {
                    allKeyPointsVisible = false
                }
            }
            let averageVisibility = (visibleCount > 0) ? totalVisibility / Float(visibleCount) : 0.0
            // Сообщаем View о видимости
            // viewDelegate?.viewModelDidUpdateDebugVisibility(keyPointsVisible: allKeyPointsVisible, averageVisibility: averageVisibility)
            // Передаем массив видимостей всех 2D точек (если они есть)
            let allVisibilities = resultBundle.poseLandmarks?.first?.map { $0.visibility?.floatValue ?? 0.0 }
            viewDelegate?.viewModelDidUpdateDebugVisibility(visibilities: allVisibilities)
            // -----------------------------------------
            
            // Добавляем явную проверку isPreparing перед вызовом анализа
            if !isPreparing {
                // --- Вызываем анализ --- 
                analyzer?.analyze(worldLandmarks: firstPoseWorldLandmarks)
                
                // --- Передаем углы для отладки ПОСЛЕ анализа --- 
                if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
                   viewDelegate?.viewModelDidUpdateDebugAngles(knee: squatAnalyzer.currentSmoothedKneeAngle, hip: squatAnalyzer.currentSmoothedHipAngle)
                } // ------------------------------------------------
            }
            
            // Сохраняем последнюю информацию о видимости
            self.lastVisibilityStatus = (allVisible: allKeyPointsVisible, average: averageVisibility)
             // -----------------------------------------
        } else {
             // Добавляем явную проверку isPreparing перед сбросом
             if !isPreparing {
                analyzer?.reset() // Сбрасываем анализатор, если точек нет
            }
        }
        
        // Передаем 2D-данные и РАЗМЕР КАДРА для отрисовки во View Controller
        // Используем сохраненный размер кадра self.currentFrameSize
        viewDelegate?.viewModelDidUpdatePose(landmarks: resultBundle.poseLandmarks, frameSize: self.currentFrameSize)
    }
}

// Обновляем extension для НОВОГО делегата ExerciseAnalyzerDelegate
extension ExerciseExecutionViewModel: ExerciseAnalyzerDelegate {
    // Метод вызывается новым протоколом
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didCountRepetition newTotalCount: Int) {
        
        // Получаем текущий профиль (он должен быть загружен в init)
        guard var profile = userProfile else {
            print("ExerciseExecutionVM Ошибка: User profile is nil...") // Оставляем ошибку
            return
        }
        
        // 1. Обновляем ОБЩЕЕ количество приседаний в профиле
        profile.totalSquats += 1
        
        // 2. Рассчитываем XP за приседание (логика уже здесь правильная)
        let powerStat = profile.power
        let baseStatValue = UserProfile.baseStatValue
        let statDifference = powerStat - baseStatValue
        let xpMultiplier = 1.0 + (Double(statDifference) / 100.0)
        let baseXP = Double(10) // TODO: Вынести xpPerSquat в константы или модель Exercise
        let calculatedXP = Int(round(baseXP * xpMultiplier))
        let finalXP = max(1, calculatedXP)
        
        
        // 3. Добавляем опыт
        let didLevelUpBasic = profile.addXP(finalXP)
        if didLevelUpBasic {
            // TODO: Сообщить View о повышении уровня
        }
        
        // 4. Определяем прирост атрибутов (зависит от упражнения)
        // TODO: Получать прирост атрибутов из модели Exercise
        let strGain = 2 // Пример для приседаний
        let conGain = 1
        let balGain = 1
        profile.gainAttributes(strGain: strGain, conGain: conGain, balGain: balGain)
        
        // 5. Продвигаем сессионную прогрессивную цель
        squatsTowardsProgressiveGoal += 1
        
        if squatsTowardsProgressiveGoal >= progressiveSquatGoal {
            // Добавляем бонусный опыт
            let didLevelUpBonus = profile.addXP(bonusXPForGoal)
            if didLevelUpBonus {
                // TODO: Сообщить View о повышении уровня (возможно, особым образом)
            }
            
            // Увеличиваем следующую цель и сбрасываем счетчик
            progressiveSquatGoal += progressiveGoalIncrement
            squatsTowardsProgressiveGoal = 0
            // TODO: Сообщить View об обновлении цели
            viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        } else {
            // Если цель не достигнута, просто сообщаем View текущий прогресс к цели
             // TODO: Сообщить View об обновлении цели
             viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        }
        
        // 6. Сохраняем обновленный профиль (после всех изменений XP и атрибутов)
        DataManager.shared.updateUserProfile(profile)
        // Обновляем локальную копию во ViewModel
        self.userProfile = profile 
        
        // 7. Сообщаем View об обновлении данных (количество приседаний, XP)
        // TODO: Определить и вызвать метод делегата View
        // viewDelegate?.viewModelDidUpdateProgress(totalSquats: profile.totalSquats, currentXP: profile.currentXP, xpToNextLevel: profile.xpToNextLevel)
        // Сообщаем View об обновлении прогресса XP
        viewDelegate?.viewModelDidUpdateProgress(currentXP: profile.currentXP, xpToNextLevel: profile.xpToNextLevel)
        // Сообщаем View об обновлении цели (после if/else)
        viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        // Сообщаем View о новом счетчике повторений
        viewDelegate?.viewModelDidUpdateDebugRepCount(newTotalCount)
    }
    
    // Метод вызывается новым протоколом
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didChangeState newState: String) {
        // Передаем информацию об изменении состояния во View
        viewDelegate?.viewModelDidUpdateDebugState(newState)
        
        // Удаляем передачу углов отсюда
        /*
        if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
           viewDelegate?.viewModelDidUpdateDebugAngles(knee: squatAnalyzer.currentSmoothedKneeAngle, hip: squatAnalyzer.currentSmoothedHipAngle)
        } else {
            // ...
        }
        */
    }
}
