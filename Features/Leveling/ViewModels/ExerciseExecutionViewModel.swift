import Foundation
import AVFoundation // Для AVFoundation типов, если понадобятся
// Добавляем необходимые импорты
import MediaPipeTasksVision
import UIKit // Для UIImage

// TODO: Определить протокол для связи ViewModel -> View
// protocol ExerciseExecutionViewModelViewDelegate: AnyObject { ... }

class ExerciseExecutionViewModel: NSObject { // Наследуемся от NSObject для соответствия протоколам делегатов

    // MARK: - Dependencies
    private let exercise: Exercise
    private var userProfile: UserProfile?
    // Переносим анализатор и хелпер сюда
    // TODO: Инициализировать анализатор в зависимости от exercise.id
    private var analyzer: SquatAnalyzer? = SquatAnalyzer() // Пока оставляем SquatAnalyzer
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
    // Свойства для троттлинга логов MediaPipe
    private var lastPoseLogTime: TimeInterval = 0
    private let poseLogInterval: TimeInterval = 0.5 // Интервал вывода лога (в секундах)
    // TODO: Добавить свойства для счетчиков прогрессивной цели
    // private var progressiveSquatGoal: Int = 5 ...

    // MARK: - Delegate
    // weak var viewDelegate: ExerciseExecutionViewModelViewDelegate?

    init(exercise: Exercise) {
        self.exercise = exercise
        self.userProfile = DataManager.shared.getCurrentUserProfile()
        super.init() // Нужно вызвать super.init(), так как наследуемся от NSObject
        print("ExerciseExecutionViewModel initialized for exercise: \(exercise.name)")
        // Назначаем себя делегатом анализатора
        self.analyzer?.delegate = self 
        // Запускаем настройку MediaPipe в фоновой очереди
        sessionQueue.async {
            self.setupPoseLandmarker()
        }
    }
    
    // MARK: - Public Methods (для View Controller)
    func viewDidLoad() {
        print("ExerciseExecutionViewModel: viewDidLoad")
        // Логика viewDidLoad, если нужна (например, первичная загрузка данных)
    }
    
    func viewDidAppear() {
        print("ExerciseExecutionViewModel: viewDidAppear")
        // Запускаем таймер, если сессия новая
        if sessionStartDate == nil {
            startTimer()
            analyzer?.reset() // Сбрасываем счетчик при начале новой сессии
        }
        // TODO: Запустить сессию камеры (если она управляется отсюда)
    }
    
    func viewWillDisappear() {
        print("ExerciseExecutionViewModel: viewWillDisappear")
        stopTimer() // Останавливаем таймер
        // TODO: Остановить сессию камеры (если она управляется отсюда)
    }
    
    // MARK: - MediaPipe Handling
    // Переносим метод настройки
    private func setupPoseLandmarker() {
        // Убедимся, что файл модели существует
        guard let modelPath = Bundle.main.path(forResource: self.modelPath, ofType: nil) else {
            print("ExerciseExecutionViewModel Ошибка: Файл модели MediaPipe не найден (\(self.modelPath)).")
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
            print("ExerciseExecutionViewModel Ошибка: Ошибка инициализации PoseLandmarkerHelper.")
            // TODO: Обработать ошибку
        } else {
            print("ExerciseExecutionViewModel: PoseLandmarkerHelper успешно инициализирован.")
        }
    }
    
    /// Метод для получения кадра от ViewController
    func processVideoFrame(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation, timeStamps: Int) {
        // Передаем кадр в хелпер (выполняется в очереди ViewController'а, но сам detectAsync - асинхронный)
         poseLandmarkerHelper?.detectAsync(
            sampleBuffer: sampleBuffer,
            orientation: orientation,
            timeStamps: timeStamps
        )
    }

    // MARK: - Exercise Analysis Handling
    // TODO: Перенести логику обработки результатов анализатора, расчета XP/атрибутов

    // MARK: - Timer Handling
    private func startTimer() {
        stopTimer() // Убедимся, что предыдущий таймер остановлен
        sessionStartDate = Date()
        // Сообщаем View начальное время (00:00)
        // TODO: viewDelegate?.viewModelDidUpdateTime(timeString: "00:00")
        print("--- ExerciseExecutionVM: Таймер запущен --- ")
        
        sessionTimer = Timer.scheduledTimer(timeInterval: timerUpdateInterval,
                                            target: self,
                                            selector: #selector(updateTimer),
                                            userInfo: nil,
                                            repeats: true)
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        print("--- ExerciseExecutionVM: Таймер остановлен --- ")
    }

    @objc private func updateTimer() {
        guard let startDate = sessionStartDate else { return }
        let elapsedTime = Int(Date().timeIntervalSince(startDate))
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        // Сообщаем View обновленное время
        // TODO: viewDelegate?.viewModelDidUpdateTime(timeString: timeString)
        print("--- ExerciseExecutionVM: Тик таймера: \(timeString) ---")
    }
}

// TODO: Добавить реализацию делегатов (PoseLandmarkerHelper, ExerciseAnalyzer) в extension

// Добавляем extension для делегата PoseLandmarkerHelper
extension ExerciseExecutionViewModel: PoseLandmarkerHelperLiveStreamDelegate {
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper, 
                              didFinishDetection resultBundle: ResultBundle?, 
                              error: Error?) {
        // Этот метод теперь будет вызываться здесь, в ViewModel
        // Выполняется в основном потоке (или в потоке, заданном хелпером)
        // TODO: Нужно решить, в каком потоке выполнять анализ и обновление UI
        
        // --- Троттлинг логов --- 
        let currentTime = Date().timeIntervalSince1970
        let shouldLog = (currentTime - lastPoseLogTime >= poseLogInterval)
        if shouldLog { 
            print("--- ExerciseExecutionVM: Получен результат от PoseLandmarkerHelper (Time: \(String(format: "%.2f", currentTime))) ---") 
            lastPoseLogTime = currentTime // Обновляем время последнего лога
        }
        // -----------------------
        
        // Обработка ошибки
        if let error = error {
            print("ExerciseExecutionVM Ошибка детекции поз: \(error.localizedDescription)")
            // TODO: Сообщить View об ошибке? Очистить оверлей?
            return
        }
        
        // Обработка результата
        guard let resultBundle = resultBundle else {
             print("--- ExerciseExecutionVM: Результат детекции пуст (nil). ---")
            // TODO: Очистить оверлей?
            return
        }
        
        // Передаем 3D точки в анализатор
        if let worldLandmarks = resultBundle.poseWorldLandmarks,
           let firstPoseWorldLandmarks = worldLandmarks.first,
           !firstPoseWorldLandmarks.isEmpty {
            // TODO: Убедиться, что analyzer инициализирован
            analyzer?.analyze(worldLandmarks: firstPoseWorldLandmarks)
            // Логируем передачу в анализатор только если логируем сам результат
            if shouldLog {
                 print("--- ExerciseExecutionVM: 3D worldLandmarks переданы в анализатор. ---")
            }
        } else {
            analyzer?.reset() // Сбрасываем анализатор, если точек нет
            // Логируем сброс анализатора только если логируем сам результат
            if shouldLog {
                 print("--- ExerciseExecutionVM: Не найдены 3D worldLandmarks. Анализатор сброшен. ---")
            }
        }
        
        // TODO: Передать данные для отрисовки (2D или 3D) во View Controller
        // viewDelegate?.viewModelDidUpdatePose(landmarks: resultBundle.poseLandmarks, worldLandmarks: resultBundle.poseWorldLandmarks)
    }
}

// Добавляем extension для делегата SquatAnalyzer
extension ExerciseExecutionViewModel: SquatAnalyzerDelegate {
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat newTotalCount: Int) {
        print("--- ExerciseExecutionVM: SquatAnalyzer засчитал приседание #\(newTotalCount) ---")
        
        // Получаем текущий профиль (он должен быть загружен в init)
        guard var profile = userProfile else {
            print("ExerciseExecutionVM Ошибка: User profile is nil в squatAnalyzer delegate.")
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
        
        print("--- ExerciseExecutionVM: Расчет XP: База=\(Int(baseXP)), Мощь=\(powerStat), БазСтат=\(baseStatValue), Множ=x\(String(format: "%.2f", xpMultiplier)), Итог=\(finalXP) ---")
        
        // 3. Добавляем опыт
        let didLevelUpBasic = profile.addXP(finalXP)
        if didLevelUpBasic {
            print("--- ExerciseExecutionVM: Обнаружено повышение уровня после базового XP! ---")
            // TODO: Сообщить View о повышении уровня
        }
        
        // 4. Определяем прирост атрибутов (зависит от упражнения)
        // TODO: Получать прирост атрибутов из модели Exercise
        let strGain = 2 // Пример для приседаний
        let conGain = 1
        let balGain = 1
        profile.gainAttributes(strGain: strGain, conGain: conGain, balGain: balGain)
        
        // 5. Продвигаем сессионную прогрессивную цель (эту логику тоже нужно перенести)
        // TODO: Перенести сюда свойства progressiveSquatGoal, squatsTowardsProgressiveGoal и логику бонуса
        // squatsTowardsProgressiveGoal += 1
        // if squatsTowardsProgressiveGoal >= progressiveSquatGoal { ... profile.addXP(bonusXPForGoal) ... }
        
        // 6. Сохраняем обновленный профиль
        DataManager.shared.updateUserProfile(profile)
        // Обновляем локальную копию во ViewModel
        self.userProfile = profile 
        
        // 7. Сообщаем View об обновлении данных (количество приседаний, XP)
        // TODO: Определить и вызвать метод делегата View
        // viewDelegate?.viewModelDidUpdateProgress(totalSquats: profile.totalSquats, currentXP: profile.currentXP, xpToNextLevel: profile.xpToNextLevel)
    }
    
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) {
        print("--- ExerciseExecutionVM: SquatAnalyzer сменил состояние на \(newState) ---")
        // TODO: Передать информацию об изменении состояния во View?
        // viewDelegate?.viewModelDidChangeState(newState)
    }
}
