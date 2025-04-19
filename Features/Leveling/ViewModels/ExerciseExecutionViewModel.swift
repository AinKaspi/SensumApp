import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit // Для UIImage
import simd // Для KalmanFilter3D
import CoreMotion // Для MotionManager

// MARK: - ExerciseExecutionViewModelViewDelegate
protocol ExerciseExecutionViewModelViewDelegate: AnyObject {
    func viewModelDidUpdateTimer(timeString: String)
    func viewModelDidUpdateProgress(currentXP: Int, xpToNextLevel: Int)
    func viewModelDidUpdateGoal(current: Int, target: Int)
    func viewModelDidUpdatePose(landmarks: [[NormalizedLandmark]]?, frameSize: CGSize)
    func viewModelDidUpdateDebugState(_ state: String)
    func viewModelDidUpdateDebugAngles(knee: Float, hip: Float)
    func viewModelDidUpdateDebugRepCount(_ count: Int)
    func viewModelDidUpdateDebugVisibility(visibilities: [Float]?)
    func viewModelDidUpdateDebugStdDev(positionStdDev: simd_float3)
    // Добавляем методы для подготовки
    func viewModelDidStartPreparation(initialValue: Int)
    func viewModelDidUpdateCountdown(value: Int)
    func viewModelDidFinishPreparation()
    // TODO: Добавить методы для Level Up, Error
}

// MARK: - ExerciseExecutionViewModel
class ExerciseExecutionViewModel: NSObject {

    // MARK: - Dependencies
    private let exercise: Exercise
    private var userProfile: UserProfile?
    private var analyzer: ExerciseAnalyzer?
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue.execVM")
    private let motionManager = MotionManager.shared

    // MARK: - Constants
    private let baseXPPerRep: Double = 10.0
    private let bonusXPForGoal: Int = 50
    private let progressiveGoalIncrement: Int = 5
    private let timerUpdateInterval: TimeInterval = 1.0
    private let poseLogInterval: TimeInterval = 0.5
    private let visibilityLogInterval: TimeInterval = 0.5
    private let maxOcclusionTime: TimeInterval = 0.4
    private let lowVisibilityThresholdForVelocityReset: Float = 0.4
    private let kalmanInitialUncertainty: Double = 10.0
    private let kalmanProcessNoise: Double = 0.01
    private let kalmanMeasurementNoise: Double = 0.2 // Базовый шум (для visibility = 1.0)

    // --- Параметры MediaPipe --- 
    // Пробуем lite-модель для ускорения инициализации
    private let modelPath = "pose_landmarker_lite.task" 
    private let numPoses = 1
    private let minPoseDetectionConfidence: Float = 0.5
    
    // MARK: - State
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?
    private var visibilityLogTimer: Timer?
    private var lastVisibilityStatus: (allVisible: Bool, average: Float)?
    private(set) var isPreparing: Bool = false
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3
    private var progressiveSquatGoal: Int = 5
    private var squatsTowardsProgressiveGoal: Int = 0
    private var currentFrameSize: CGSize = .zero
    private var kalmanFilters: [KalmanFilter3D?] = Array(repeating: nil, count: 33)
    private var lastFrameTimestamp: TimeInterval? = nil
    private var lastUpdateTime: [TimeInterval?] = Array(repeating: nil, count: 33)
    // Таймер и интервал для логгирования углов
    private var angleLogTimer: Timer?
    private let angleLogIntervalSecs: TimeInterval = 1.0

    // MARK: - Delegate
    weak var viewDelegate: ExerciseExecutionViewModelViewDelegate?

    // MARK: - Initialization
    init(exercise: Exercise, poseLandmarkerHelper: PoseLandmarkerHelper?, viewDelegate: ExerciseExecutionViewModelViewDelegate?) {
        self.exercise = exercise
        self.userProfile = DataManager.shared.getCurrentUserProfile()
        self.viewDelegate = viewDelegate
        self.poseLandmarkerHelper = poseLandmarkerHelper
        super.init()
        setupAnalyzer(for: exercise)
        self.analyzer?.delegate = self
        self.poseLandmarkerHelper?.liveStreamDelegate = self // Назначаем себя делегатом ПОСЛЕ super.init()
        // Устанавливаем начальную цель (можно из профиля или упражнения)
        self.progressiveSquatGoal = 5 // Пока хардкод
    }

    // MARK: - Lifecycle Methods
    func viewDidLoad() {
        updateInitialUI()
    }
    
    func viewDidAppear() {
        startPreparationTimer()
        // Запускаем отслеживание ориентации
        motionManager.startUpdates()
    }
    
    func viewWillDisappear() {
        stopTimer()
        stopPreparationTimer()
        // Останавливаем отслеживание ориентации
        motionManager.stopUpdates()
    }
    
    // MARK: - Initial UI Update
    private func updateInitialUI() {
        if let profile = userProfile {
            viewDelegate?.viewModelDidUpdateProgress(currentXP: profile.currentXP, xpToNextLevel: profile.xpToNextLevel)
            viewDelegate?.viewModelDidUpdateDebugRepCount(profile.totalSquats)
        }
        viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        viewDelegate?.viewModelDidUpdateTimer(timeString: "00:00")
        viewDelegate?.viewModelDidUpdateDebugState("Preparing")
        viewDelegate?.viewModelDidUpdateDebugAngles(knee: 0, hip: 0)
        viewDelegate?.viewModelDidUpdateDebugVisibility(visibilities: nil)
    }
    
    // MARK: - MediaPipe Handling
    // setupPoseLandmarker убран, т.к. helper передается извне

    // MARK: - Analyzer Setup
    private func setupAnalyzer(for exercise: Exercise) {
        switch exercise.id {
        case "squats":
            self.analyzer = SquatAnalyzer3D(delegate: self)
        default:
            print("--- ExerciseExecutionVM ВНИМАНИЕ: Анализатор для '\(exercise.id)' не найден. ---")
            self.analyzer = nil
        }
    }

    // MARK: - Frame Processing
    func processVideoFrame(pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation, timeStamps: Int, frameSize: CGSize) {
        self.currentFrameSize = frameSize
        // Передаем в хелпер; результат придет в метод делегата poseLandmarkerHelper
        poseLandmarkerHelper?.detectAsync(
            pixelBuffer: pixelBuffer,
            orientation: orientation, 
            timeStamps: timeStamps
        )
    }

    // MARK: - Timer Handling
    private func startPreparationTimer() {
        guard !isPreparing else { return }
        isPreparing = true
        countdownValue = 3 
        stopPreparationTimer()
        viewDelegate?.viewModelDidStartPreparation(initialValue: countdownValue) // Уведомляем View
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePreparationTimer), userInfo: nil, repeats: true)
    }
    
    private func stopPreparationTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    @objc private func updatePreparationTimer() {
        countdownValue -= 1
        if countdownValue > 0 {
            viewDelegate?.viewModelDidUpdateCountdown(value: countdownValue) // Уведомляем View
        } else {
            stopPreparationTimer()
            isPreparing = false
            viewDelegate?.viewModelDidFinishPreparation() // Уведомляем View
            startTimer()
            analyzer?.reset() 
            startVisibilityLogTimer() 
        }
    }
    
    private func startTimer() {
        guard sessionTimer == nil else { return }
        stopTimer()
        sessionStartDate = Date()
        viewDelegate?.viewModelDidUpdateTimer(timeString: "00:00")
        sessionTimer = Timer.scheduledTimer(timeInterval: timerUpdateInterval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        // Запускаем логгеры вместе с основным таймером
        startVisibilityLogTimer()
        startAngleLogTimer()
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopVisibilityLogTimer()
        stopAngleLogTimer() // Останавливаем и таймер углов
    }
    
    private func startVisibilityLogTimer() {
        stopVisibilityLogTimer()
        visibilityLogTimer = Timer.scheduledTimer(timeInterval: visibilityLogInterval, target: self, selector: #selector(logVisibility), userInfo: nil, repeats: true)
    }

    private func stopVisibilityLogTimer() {
        visibilityLogTimer?.invalidate()
        visibilityLogTimer = nil
    }

    @objc private func logVisibility() {
        if let status = lastVisibilityStatus {
            let statusText = status.allVisible ? "OK" : "BAD"
            print(String(format: "[VISIBILITY LOG] Status: %@, Average: %.2f", statusText, status.average))
        }
    }

    // --- Таймер логгирования Углов --- 
    private func startAngleLogTimer() {
        stopAngleLogTimer()
        angleLogTimer = Timer.scheduledTimer(timeInterval: angleLogIntervalSecs,
                                             target: self, 
                                             selector: #selector(logAngles),
                                             userInfo: nil, 
                                             repeats: true)
    }
    
    private func stopAngleLogTimer() {
        angleLogTimer?.invalidate()
        angleLogTimer = nil
    }
    
    @objc private func logAngles() {
        // Получаем анализатор и кастуем к типу с углами
        if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
            print(String(format: "[ANGLES LOG] Knee: %.1f, Hip: %.1f", 
                         squatAnalyzer.currentSmoothedKneeAngle, 
                         squatAnalyzer.currentSmoothedHipAngle))
        } else {
            // print("[ANGLES LOG] Analyzer not available or not SquatAnalyzer3D.")
        }
    }

    @objc private func updateTimer() {
        guard let startDate = sessionStartDate else { return }
        let elapsedTime = Int(Date().timeIntervalSince(startDate))
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        viewDelegate?.viewModelDidUpdateTimer(timeString: timeString)
    }
    
    private func resetKalmanFilters() {
        kalmanFilters = Array(repeating: nil, count: 33)
        lastFrameTimestamp = nil
        lastUpdateTime = Array(repeating: nil, count: 33)
    }
    
    // MARK: - Attribute Gain Logic
    /// Определяет прирост атрибутов для выполненного повторения
    private func attributeGainsForCurrentRep() -> (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int) {
        // TODO: Логика должна зависеть от self.exercise.id
        switch exercise.id {
        case "squats":
            return (str: 2, con: 1, acc: 0, spd: 0, bal: 1, flx: 0)
        // case "pushups":
        //    return (str: 3, con: 1, acc: 1, spd: 0, bal: 0, flx: 0)
        default:
            return (str: 0, con: 0, acc: 0, spd: 0, bal: 0, flx: 0)
        }
    }
}

// MARK: - PoseLandmarkerHelperLiveStreamDelegate
extension ExerciseExecutionViewModel: PoseLandmarkerHelperLiveStreamDelegate {
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper, 
                              didFinishDetection resultBundle: ResultBundle?, 
                              error: Error?) {
        
        guard !isPreparing else { return }
        
        if let error = error {
            print("ExerciseExecutionVM Ошибка детекции поз: \(error.localizedDescription)") 
            lastFrameTimestamp = nil
            return
        }
        
        guard let resultBundle = resultBundle else {
             viewDelegate?.viewModelDidUpdatePose(landmarks: nil, frameSize: self.currentFrameSize)
             lastFrameTimestamp = nil
             analyzer?.reset()
            return
        }
                
        // Получаем текущую ориентацию устройства
        guard let deviceAttitude = motionManager.currentAttitude else {
            print("[ViewModel] Warning: No device attitude data available. Skipping coordinate transformation.")
            // Можно либо пропустить кадр, либо обработать без преобразования
            // return 
            // Пока продолжим без преобразования, если ориентация недоступна
            // TODO: решить, как обрабатывать отсутствие ориентации
            processLandmarks(resultBundle: resultBundle, deviceAttitude: nil, currentTimestamp: Date().timeIntervalSince1970)
            return
        }
        
        processLandmarks(resultBundle: resultBundle, deviceAttitude: deviceAttitude, currentTimestamp: Date().timeIntervalSince1970)
    }
    
    // Выносим логику обработки landmarks в отдельный метод
    private func processLandmarks(resultBundle: ResultBundle, deviceAttitude: simd_quatd?, currentTimestamp: TimeInterval) {
        var filteredWorldLandmarks: [Landmark]? = nil
        let deltaTime = (lastFrameTimestamp != nil) ? currentTimestamp - lastFrameTimestamp! : 0.0
        
        if let worldLandmarks = resultBundle.poseWorldLandmarks,
           let firstPoseWorldLandmarks = worldLandmarks.first,
           !firstPoseWorldLandmarks.isEmpty {
            
            var poseFiltered: [Landmark] = []
            var allKeyPointsVisible = true 
            var visibleKeyPointsCount = 0
            var totalKeyPointsVisibility: Float = 0.0
            let keyIndices: [PoseConnections.LandmarkIndex] = [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .leftShoulder, .rightShoulder]
            let keyIndicesRawValues = Set(keyIndices.map { $0.rawValue })
            
            // --- Преобразование координат с учетом ориентации устройства --- 
            // ВРЕМЕННО ОТКЛЮЧАЕМ ПРЕОБРАЗОВАНИЕ ДЛЯ ОТЛАДКИ
            /*
            // Получаем обратный кватернион ориентации
            let inverseDeviceAttitude = deviceAttitude?.inverse
            */
            
            for i in 0..<firstPoseWorldLandmarks.count {
                let measurement = firstPoseWorldLandmarks[i]
                var measurementVec = simd_float3(measurement.x, measurement.y, measurement.z)
                
                // --- Преобразуем координаты в мировую систему --- 
                // ОТКЛЮЧЕНО
                /*
                if let invAttitude = inverseDeviceAttitude {
                    let rotatedVec = invAttitude.act(simd_double3(measurementVec))
                    measurementVec = simd_float3(rotatedVec) 
                } 
                */
                // -------------------------------------------------
                
                let visibilityValue = measurement.visibility?.floatValue ?? 0.0 
                let isVisible = visibilityValue > PoseConnections.visibilityThreshold
                
                // --- Логика Калмана --- 
                var needsReset = false
                if let lastUpdate = lastUpdateTime[i], !isVisible {
                    if currentTimestamp - lastUpdate > maxOcclusionTime {
                        needsReset = true
                        kalmanFilters[i] = nil 
                        lastUpdateTime[i] = nil 
                    }
                }
                
                if kalmanFilters[i] == nil && isVisible && !needsReset {
                    kalmanFilters[i] = KalmanFilter3D(initialMeasurement: measurementVec,
                                                      initialUncertainty: kalmanInitialUncertainty,
                                                      processNoise: kalmanProcessNoise, 
                                                      measurementNoise: kalmanMeasurementNoise)
                    lastUpdateTime[i] = currentTimestamp
                } else if kalmanFilters[i] != nil { 
                    kalmanFilters[i]!.predict(deltaTime: deltaTime)
                }
                
                if isVisible, kalmanFilters[i] != nil { 
                    kalmanFilters[i]!.update(measurement: measurementVec, measurementVisibility: visibilityValue)
                    lastUpdateTime[i] = currentTimestamp
                }
                // ----------------------

                // --- Сбор видимости ключевых точек --- 
                if keyIndicesRawValues.contains(i) {
                   if isVisible {
                       visibleKeyPointsCount += 1
                       totalKeyPointsVisibility += visibilityValue
                   } else {
                       allKeyPointsVisible = false
                   }
                }
                // -----------------------------------

                // --- Формирование отфильтрованной позы --- 
                if let filter = kalmanFilters[i] {
                    let filteredPosition = filter.filteredPosition
                    // Создаем Landmark с отфильтрованной мировой позицией
                    let filteredLandmark = Landmark(x: filteredPosition.x,
                                                    y: filteredPosition.y,
                                                    z: filteredPosition.z,
                                                    visibility: measurement.visibility, 
                                                    presence: measurement.presence)
                    poseFiltered.append(filteredLandmark)
                    
                    // Отладка StdDev для носа
                    if i == PoseConnections.LandmarkIndex.nose.rawValue { 
                         let stdDev = filter.positionStandardDeviation
                         viewDelegate?.viewModelDidUpdateDebugStdDev(positionStdDev: stdDev)
                    }
                } 
                // -----------------------------------------
            }
            filteredWorldLandmarks = poseFiltered 
            
            let averageVisibility = (visibleKeyPointsCount > 0) ? totalKeyPointsVisibility / Float(visibleKeyPointsCount) : 0.0
            self.lastVisibilityStatus = (allVisible: allKeyPointsVisible, average: averageVisibility)
            
            // Передаем отфильтрованные и ПРЕОБРАЗОВАННЫЕ 3D точки в анализатор
            if !isPreparing, let validFilteredPose = filteredWorldLandmarks {
                 analyzer?.analyze(worldLandmarks: validFilteredPose)
            }
        } else {
             if !isPreparing { analyzer?.reset() }
             resetKalmanFilters()
             self.lastVisibilityStatus = nil
        }
        
        lastFrameTimestamp = currentTimestamp
        
        // Передаем ИСХОДНЫЕ 2D-данные и ВИДИМОСТИ для отрисовки
        let allVisibilities = resultBundle.poseLandmarks?.first?.map { $0.visibility?.floatValue ?? 0.0 }
        viewDelegate?.viewModelDidUpdatePose(landmarks: resultBundle.poseLandmarks, frameSize: self.currentFrameSize)
        viewDelegate?.viewModelDidUpdateDebugVisibility(visibilities: allVisibilities)
    }
}

// MARK: - ExerciseAnalyzerDelegate
extension ExerciseExecutionViewModel: ExerciseAnalyzerDelegate {
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didCountRepetition newTotalCount: Int) {
        guard var profile = userProfile else {
            print("ExerciseExecutionVM Ошибка: User profile is nil в exerciseAnalyzer delegate.")
            return
        }
        profile.totalSquats += 1
        let sessionRepCount = newTotalCount

        // Расчет XP
        let powerStat = profile.power
        let baseStatValue = UserProfile.baseStatValue
        let statDifference = powerStat - baseStatValue
        let xpMultiplier = 1.0 + (Double(statDifference) / 100.0)
        let calculatedXP = Int(round(baseXPPerRep * xpMultiplier))
        let finalXP = max(1, calculatedXP)

        let didLevelUpBasic = profile.addXP(finalXP)
        if didLevelUpBasic { /* TODO: Notify View Level Up */ }

        // Прирост атрибутов
        let gains = attributeGainsForCurrentRep()
        profile.gainAttributes(strGain: gains.str, conGain: gains.con, accGain: gains.acc, spdGain: gains.spd, balGain: gains.bal, flxGain: gains.flx)

        // Прогрессивная цель
        squatsTowardsProgressiveGoal = sessionRepCount % progressiveGoalIncrement 
        if squatsTowardsProgressiveGoal == 0 && sessionRepCount > 0 {
             let goalReached = (sessionRepCount / progressiveGoalIncrement) * progressiveGoalIncrement
             progressiveSquatGoal = goalReached + progressiveGoalIncrement
             let didLevelUpBonus = profile.addXP(bonusXPForGoal)
             if didLevelUpBonus { /* TODO: Notify View Level Up (Bonus) */ }
        }
        viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        
        DataManager.shared.updateUserProfile(profile)
        self.userProfile = profile 
        
        viewDelegate?.viewModelDidUpdateProgress(currentXP: profile.currentXP, xpToNextLevel: profile.xpToNextLevel)
        viewDelegate?.viewModelDidUpdateDebugRepCount(profile.totalSquats)
    }
    
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didChangeState newState: String) {
        viewDelegate?.viewModelDidUpdateDebugState(newState)
        // Убираем передачу углов в View отсюда
        /*
        if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
           viewDelegate?.viewModelDidUpdateDebugAngles(knee: squatAnalyzer.currentSmoothedKneeAngle, hip: squatAnalyzer.currentSmoothedHipAngle)
        } 
        */
    }
}
