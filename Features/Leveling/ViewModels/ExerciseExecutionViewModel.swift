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
    // TODO: Добавить свойства для таймера, счетчиков и т.д.

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
        // TODO: Запустить сессию камеры/таймер?
         print("ExerciseExecutionViewModel: viewDidAppear")
    }
    
    func viewWillDisappear() {
        // TODO: Остановить сессию камеры/таймер?
         print("ExerciseExecutionViewModel: viewWillDisappear")
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
    // TODO: Перенести логику таймера
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
        print("--- ExerciseExecutionVM: Получен результат от PoseLandmarkerHelper ---")
        
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
             print("--- ExerciseExecutionVM: 3D worldLandmarks переданы в анализатор. ---")
        } else {
            analyzer?.reset() // Сбрасываем анализатор, если точек нет
             print("--- ExerciseExecutionVM: Не найдены 3D worldLandmarks. Анализатор сброшен. ---")
        }
        
        // TODO: Передать данные для отрисовки (2D или 3D) во View Controller
        // viewDelegate?.viewModelDidUpdatePose(landmarks: resultBundle.poseLandmarks, worldLandmarks: resultBundle.poseWorldLandmarks)
    }
}

// Добавляем extension для делегата SquatAnalyzer
extension ExerciseExecutionViewModel: SquatAnalyzerDelegate {
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat newTotalCount: Int) {
        // TODO: Перенести сюда логику расчета XP, атрибутов, обновления профиля
        print("--- ExerciseExecutionVM: SquatAnalyzer засчитал приседание #\(newTotalCount) ---")
        // Обновляем userProfile?
        // Рассчитываем XP?
        // Даем команду View обновить UI?
    }
    
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) {
        // TODO: Передать информацию об изменении состояния во View?
         print("--- ExerciseExecutionVM: SquatAnalyzer сменил состояние на \(newState) ---")
    }
}
