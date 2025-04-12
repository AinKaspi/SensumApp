import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit // Для UIImage
import simd // Для KalmanFilter3D

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
        // TODO: Рассмотреть запуск AVCaptureSession отсюда, если VC не должен этим управлять
    }

    func viewWillDisappear() {
        stopTimer()
        stopPreparationTimer()
        // TODO: Рассмотреть остановку AVCaptureSession
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
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopVisibilityLogTimer()
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
            // TODO: Сообщить View об ошибке
            return
        }
        
        guard let resultBundle = resultBundle else {
             viewDelegate?.viewModelDidUpdatePose(landmarks: nil, frameSize: self.currentFrameSize)
             lastFrameTimestamp = nil
             analyzer?.reset() // Сбрасываем анализатор, если нет результата
            return
        }
                
        var filteredWorldLandmarks: [Landmark]? = nil
        let currentTimestamp = Date().timeIntervalSince1970 
        let deltaTime = (lastFrameTimestamp != nil) ? currentTimestamp - lastFrameTimestamp! : 0.0
        
        // Переменные для сбора информации о видимости ключевых точек
        var allKeyPointsVisible = true
        var visibleKeyPointsCount = 0
        var totalVisibility: Float = 0.0
        // Определяем ключевые индексы как массив Enum
        let keyIndices: [PoseConnections.LandmarkIndex] = [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .leftShoulder, .rightShoulder]
        // Создаем Set из rawValue для быстрой проверки contains
        let keyIndicesRawValues = Set(keyIndices.map { $0.rawValue })
        
        // Массив для отфильтрованных 3D точек
        var poseFiltered: [Landmark] = []
        
        if let worldLandmarks = resultBundle.poseWorldLandmarks,
           let firstPoseWorldLandmarks = worldLandmarks.first,
           !firstPoseWorldLandmarks.isEmpty {
            
            // Итерируем по всем точкам для фильтрации Калмана
            for i in 0..<firstPoseWorldLandmarks.count {
                let measurement = firstPoseWorldLandmarks[i]
                let measurementVec = simd_float3(measurement.x, measurement.y, measurement.z)
                let visibilityValue = measurement.visibility?.floatValue ?? 0.0 
                let isVisible = visibilityValue > PoseConnections.visibilityThreshold
                
                // --- Логика Калмана (Инициализация/Предсказание/Обновление) --- 
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
                // ----------------------------------------------------------

                // --- Сбор информации о видимости КЛЮЧЕВЫХ точек --- 
                // Проверяем, является ли текущий Int индекс `i` одним из ключевых
                if keyIndicesRawValues.contains(i) { 
                   if isVisible {
                       visibleKeyPointsCount += 1
                       totalVisibility += visibilityValue
                   } else {
                       allKeyPointsVisible = false
                   }
                }
                // -------------------------------------------------

                // --- Формирование отфильтрованной позы --- 
                if let filter = kalmanFilters[i] {
                    let filteredPosition = filter.filteredPosition
                    // Создаем отфильтрованный Landmark
                    let filteredLandmark = Landmark(x: filteredPosition.x,
                                                    y: filteredPosition.y,
                                                    z: filteredPosition.z,
                                                    visibility: measurement.visibility, // Важно: видимость берем из исходного измерения
                                                    presence: measurement.presence)
                    poseFiltered.append(filteredLandmark)
                    
                    // Передаем отладочные данные StdDev для носа
                    // Сравниваем Int `i` с Int `rawValue` из enum
                    if i == PoseConnections.LandmarkIndex.nose.rawValue { 
                         let stdDev = filter.positionStandardDeviation
                         viewDelegate?.viewModelDidUpdateDebugStdDev(positionStdDev: stdDev)
                    }
                } 
                // -----------------------------------------
            }
            filteredWorldLandmarks = poseFiltered // Сохраняем отфильтрованную позу
            
            // Сохраняем общий статус видимости ключевых точек
            let averageVisibility = (visibleKeyPointsCount > 0) ? totalVisibility / Float(visibleKeyPointsCount) : 0.0
            self.lastVisibilityStatus = (allVisible: allKeyPointsVisible, average: averageVisibility)
            
            // Передаем ОТФИЛЬТРОВАННЫЕ 3D точки в анализатор
            if !isPreparing, let validFilteredPose = filteredWorldLandmarks { // Передаем только если они есть
                 analyzer?.analyze(worldLandmarks: validFilteredPose)
            }
        } else {
             // Если нет world landmarks
             if !isPreparing { analyzer?.reset() }
             resetKalmanFilters()
             self.lastVisibilityStatus = nil
        }
        
        lastFrameTimestamp = currentTimestamp
        
        // Передаем ИСХОДНЫЕ 2D-данные для отрисовки и массив ВИДИМОСТЕЙ (всех точек)
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
        if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
           viewDelegate?.viewModelDidUpdateDebugAngles(knee: squatAnalyzer.currentSmoothedKneeAngle, hip: squatAnalyzer.currentSmoothedHipAngle)
        } 
    }
}
