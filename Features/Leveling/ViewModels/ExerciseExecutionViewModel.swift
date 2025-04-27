import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit // Для UIImage
import simd // Для KalmanFilter3D
import CoreMotion // Для MotionManager
import Combine // Для @Published

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
    func viewModelDidStartPreparation(initialValue: Int)
    func viewModelDidUpdateCountdown(value: Int)
    func viewModelDidFinishPreparation()
    func viewModelDidEncounterError(message: String)
    func viewModelDidLevelUp(newLevel: Int, newRank: String)
}

// MARK: - ExerciseExecutionViewModel
class ExerciseExecutionViewModel: NSObject {

    // MARK: - Dependencies
    private let exercise: Exercise
    private let userProfileService: UserProfileServiceProtocol
    private let progressService: ProgressServiceProtocol
    private let authService: AuthServiceProtocol
    
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
    private let kalmanMeasurementNoise: Double = 0.2
    private let modelPath = "pose_landmarker_lite.task"
    private let numPoses = 1
    private let minPoseDetectionConfidence: Float = 0.5

    // MARK: - Published State (для будущих расширений, пока не используются напрямую)
    @Published private var currentUser: User? = nil
    @Published private var currentProgressData: ProgressData? = nil
    @Published private var isLoading: Bool = false
    @Published private var errorMessage: String? = nil
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal State
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?
    private var visibilityLogTimer: Timer?
    private var lastVisibilityStatus: (allVisible: Bool, average: Float)?
    private(set) var isPreparing: Bool = false
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3
    private var progressiveSquatGoal: Int = 5
    private var squatsTowardsProgressiveGoal: Int = 0
    private var sessionRepCount: Int = 0
    private var currentFrameSize: CGSize = .zero
    private var kalmanFilters: [KalmanFilter3D?] = Array(repeating: nil, count: 33)
    private var lastFrameTimestamp: TimeInterval? = nil
    private var lastUpdateTime: [TimeInterval?] = Array(repeating: nil, count: 33)
    private var angleLogTimer: Timer?
    private let angleLogIntervalSecs: TimeInterval = 1.0

    // MARK: - Delegate
    weak var viewDelegate: ExerciseExecutionViewModelViewDelegate?

    // MARK: - Initialization
    init(exercise: Exercise, 
         poseLandmarkerHelper: PoseLandmarkerHelper?,
         authService: AuthServiceProtocol = AuthService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         progressService: ProgressServiceProtocol,
         viewDelegate: ExerciseExecutionViewModelViewDelegate?) {
        self.exercise = exercise
        self.authService = authService
        self.userProfileService = userProfileService
        self.progressService = progressService
        self.viewDelegate = viewDelegate
        self.poseLandmarkerHelper = poseLandmarkerHelper
        
        super.init()
        
        self.setupAnalyzer(for: exercise)
        self.analyzer?.delegate = self
        self.poseLandmarkerHelper?.liveStreamDelegate = self
        self.progressiveSquatGoal = 5
        
        fetchInitialData()
    }

    // MARK: - Lifecycle Methods
    func viewDidLoad() {
    }
    
    func viewDidAppear() {
        startPreparationTimer()
        motionManager.startUpdates()
    }
    
    func viewWillDisappear() {
        stopTimer()
        stopPreparationTimer()
        motionManager.stopUpdates()
    }
    
    // MARK: - Data Fetching
    private func fetchInitialData() {
        guard let userID = authService.currentUserID else {
            print("ExerciseExecutionVM Error: Cannot get current user ID.")
            self.errorMessage = "User not authenticated."
            viewDelegate?.viewModelDidEncounterError(message: "User not authenticated.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var fetchedUser: User? = nil
        var fetchedProgress: ProgressData? = nil
        var fetchError: Error? = nil
        
        group.enter()
        userProfileService.fetchUserProfile(userID: userID) { result in
            switch result {
            case .success(let user): fetchedUser = user
            case .failure(let error): fetchError = error
            }
            group.leave()
        }
        
        group.enter()
        progressService.fetchProgressData(userID: userID) { result in
            switch result {
            case .success(let progress): fetchedProgress = progress
            case .failure(let error): fetchError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if let error = fetchError {
                let message = "Failed to load user data: \(error.localizedDescription)"
                self.errorMessage = message
                print("ExerciseExecutionVM Error: \(message)")
                self.viewDelegate?.viewModelDidEncounterError(message: message)
            } else if let user = fetchedUser, let progress = fetchedProgress {
                self.currentUser = user
                self.currentProgressData = progress
                print("ExerciseExecutionVM: Initial data loaded successfully.")
                self.updateInitialUI()
            } else {
                let message = "Failed to load user data (unknown error)."
                self.errorMessage = message
                print("ExerciseExecutionVM Error: \(message)")
                self.viewDelegate?.viewModelDidEncounterError(message: message)
            }
        }
    }
    
    // MARK: - Initial UI Update
    private func updateInitialUI() {
        if let progress = currentProgressData {
            viewDelegate?.viewModelDidUpdateProgress(currentXP: progress.currentXP, xpToNextLevel: progress.xpToNextLevel)
            viewDelegate?.viewModelDidUpdateDebugRepCount(0)
        } else {
            viewDelegate?.viewModelDidUpdateProgress(currentXP: 0, xpToNextLevel: 100)
            viewDelegate?.viewModelDidUpdateDebugRepCount(0)
        }
        viewDelegate?.viewModelDidUpdateGoal(current: squatsTowardsProgressiveGoal, target: progressiveSquatGoal)
        viewDelegate?.viewModelDidUpdateTimer(timeString: "00:00")
        viewDelegate?.viewModelDidUpdateDebugState("Preparing")
        viewDelegate?.viewModelDidUpdateDebugAngles(knee: 0, hip: 0)
        viewDelegate?.viewModelDidUpdateDebugVisibility(visibilities: nil)
    }
    
    // MARK: - MediaPipe Handling
    func processVideoFrame(pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation, timeStamps: Int, frameSize: CGSize) {
        self.currentFrameSize = frameSize
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
        viewDelegate?.viewModelDidStartPreparation(initialValue: countdownValue)
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePreparationTimer), userInfo: nil, repeats: true)
    }
    
    private func stopPreparationTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    @objc private func updatePreparationTimer() {
        countdownValue -= 1
        if countdownValue > 0 {
            viewDelegate?.viewModelDidUpdateCountdown(value: countdownValue)
        } else {
            stopPreparationTimer()
            isPreparing = false
            viewDelegate?.viewModelDidFinishPreparation()
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
        startVisibilityLogTimer()
        startAngleLogTimer()
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopVisibilityLogTimer()
        stopAngleLogTimer()
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
        if let squatAnalyzer = analyzer as? SquatAnalyzer3D {
            print(String(format: "[ANGLES LOG] Knee: %.1f, Hip: %.1f",
                         squatAnalyzer.currentSmoothedKneeAngle,
                         squatAnalyzer.currentSmoothedHipAngle))
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
    
    private func attributeGainsForCurrentRep() -> (str: Int, con: Int, acc: Int, spd: Int, bal: Int, flx: Int) {
        switch exercise.id {
        case "squats":
            return (str: 2, con: 1, acc: 0, spd: 0, bal: 1, flx: 0)
        default:
            return (str: 0, con: 0, acc: 0, spd: 0, bal: 0, flx: 0)
        }
    }

    // MARK: - Analyzer Setup (ВОССТАНАВЛИВАЕМ МЕТОД)
    private func setupAnalyzer(for exercise: Exercise) {
        switch exercise.id {
        case "squats":
            self.analyzer = SquatAnalyzer3D(delegate: self)
            print("ExerciseExecutionVM: SquatAnalyzer3D initialized.")
        default:
            print("--- ExerciseExecutionVM ВНИМАНИЕ: Анализатор для '\(exercise.id)' не найден. ---")
            // Устанавливаем в nil, если нет подходящего анализатора
            self.analyzer = nil
            // Уведомляем об ошибке?
            // viewDelegate?.viewModelDidEncounterError(message: "Exercise type not supported yet.")
        }
        // Убедимся, что делегат установлен (хотя можно и в switch)
        self.analyzer?.delegate = self 
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
                
        guard let deviceAttitude = motionManager.currentAttitude else {
            print("[ViewModel] Warning: No device attitude data available. Skipping coordinate transformation.")
            processLandmarks(resultBundle: resultBundle, deviceAttitude: nil, currentTimestamp: Date().timeIntervalSince1970)
            return
        }
        
        processLandmarks(resultBundle: resultBundle, deviceAttitude: deviceAttitude, currentTimestamp: Date().timeIntervalSince1970)
    }
    
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
            
            for i in 0..<firstPoseWorldLandmarks.count {
                let measurement = firstPoseWorldLandmarks[i]
                var measurementVec = simd_float3(measurement.x, measurement.y, measurement.z)
                
                let visibilityValue = measurement.visibility?.floatValue ?? 0.0 
                let isVisible = visibilityValue > PoseConnections.visibilityThreshold
                
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

                if keyIndicesRawValues.contains(i) {
                   if isVisible {
                       visibleKeyPointsCount += 1
                       totalKeyPointsVisibility += visibilityValue
                   } else {
                       allKeyPointsVisible = false
                   }
                }

                if let filter = kalmanFilters[i] {
                    let filteredPosition = filter.filteredPosition
                    let filteredLandmark = Landmark(x: filteredPosition.x,
                                                    y: filteredPosition.y,
                                                    z: filteredPosition.z,
                                                    visibility: measurement.visibility, 
                                                    presence: measurement.presence)
                    poseFiltered.append(filteredLandmark)
                    
                    if i == PoseConnections.LandmarkIndex.nose.rawValue { 
                         let stdDev = filter.positionStandardDeviation
                         viewDelegate?.viewModelDidUpdateDebugStdDev(positionStdDev: stdDev)
                    }
                } 
            }
            filteredWorldLandmarks = poseFiltered 
            
            let averageVisibility = (visibleKeyPointsCount > 0) ? totalKeyPointsVisibility / Float(visibleKeyPointsCount) : 0.0
            self.lastVisibilityStatus = (allVisible: allKeyPointsVisible, average: averageVisibility)
            
            if !isPreparing, let validFilteredPose = filteredWorldLandmarks {
                 analyzer?.analyze(worldLandmarks: validFilteredPose)
            }
        } else {
             if !isPreparing { analyzer?.reset() }
             resetKalmanFilters()
             self.lastVisibilityStatus = nil
        }
        
        lastFrameTimestamp = currentTimestamp
        
        let allVisibilities = resultBundle.poseLandmarks?.first?.map { $0.visibility?.floatValue ?? 0.0 }
        viewDelegate?.viewModelDidUpdatePose(landmarks: resultBundle.poseLandmarks, frameSize: self.currentFrameSize)
        viewDelegate?.viewModelDidUpdateDebugVisibility(visibilities: allVisibilities)
    }
}

// MARK: - ExerciseAnalyzerDelegate
extension ExerciseExecutionViewModel: ExerciseAnalyzerDelegate {
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didCountRepetition newTotalCount: Int) {
        self.sessionRepCount = newTotalCount
        
        guard let userID = authService.currentUserID else {
            print("ExerciseExecutionVM Error: User not authenticated in didCountRepetition.")
            viewDelegate?.viewModelDidEncounterError(message: "User not authenticated.")
            return
        }

        let xpAmount = Int(round(baseXPPerRep))
        
        let gains = attributeGainsForCurrentRep()

        progressService.addXP(xpAmount, attributeGains: gains, forUserID: userID) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedProgress):
                    self.currentProgressData = updatedProgress
                    
                    self.viewDelegate?.viewModelDidUpdateProgress(currentXP: updatedProgress.currentXP, xpToNextLevel: updatedProgress.xpToNextLevel)
                    self.viewDelegate?.viewModelDidUpdateDebugRepCount(self.sessionRepCount)
                    
                    self.squatsTowardsProgressiveGoal = self.sessionRepCount % self.progressiveGoalIncrement
                    if self.squatsTowardsProgressiveGoal == 0 && self.sessionRepCount > 0 {
                        let goalReached = (self.sessionRepCount / self.progressiveGoalIncrement) * self.progressiveGoalIncrement
                        self.progressiveSquatGoal = goalReached + self.progressiveGoalIncrement
                        print("Progressive goal updated to: \(self.progressiveSquatGoal)")
                    }
                    self.viewDelegate?.viewModelDidUpdateGoal(current: self.squatsTowardsProgressiveGoal, target: self.progressiveSquatGoal)
                    
                case .failure(let error):
                    print("ExerciseExecutionVM Error (addXP callback): \(error.localizedDescription)")
                    self.viewDelegate?.viewModelDidEncounterError(message: "Failed to update progress: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func exerciseAnalyzer(_ analyzer: ExerciseAnalyzer, didChangeState newState: String) {
        viewDelegate?.viewModelDidUpdateDebugState(newState)
    }
}
