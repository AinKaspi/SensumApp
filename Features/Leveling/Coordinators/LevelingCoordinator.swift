import UIKit
import MediaPipeTasksVision // Нужен для PoseLandmarkerHelper

// Координатор для фичи Leveling
class LevelingCoordinator: Coordinator, ExerciseSelectionViewModelCoordinatorDelegate {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // Добавляем зависимости
    private let authService: AuthServiceProtocol
    private let progressService: ProgressServiceProtocol
    
    // Создаем и храним PoseLandmarkerHelper на уровне координатора
    // (Как было в старом коде SceneDelegate)
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let sessionQueue = DispatchQueue(label: "com.sensum.leveling.poseHelperQueue", qos: .userInitiated)
    
    init(navigationController: UINavigationController,
         authService: AuthServiceProtocol, 
         progressService: ProgressServiceProtocol) {
        self.navigationController = navigationController
        self.authService = authService
        self.progressService = progressService
        // Запускаем инициализацию хелпера в фоне при создании координатора
        setupPoseLandmarkerHelperInBackground()
        // TODO: Настроить стиль Navigation Bar для Leveling?
    }
    
    func start() {
        // Стартуем с экрана выбора упражнений
        let selectionVC = ExerciseSelectionViewController()
        // Создаем ViewModel и передаем себя как делегата
        let viewModel = ExerciseSelectionViewModel(coordinatorDelegate: self) 
        selectionVC.viewModel = viewModel // Передаем ViewModel во ViewController
        selectionVC.title = "Упражнения"
        navigationController.setViewControllers([selectionVC], animated: false)
    }
    
    // MARK: - ExerciseSelectionViewModelCoordinatorDelegate
    
    // Реализуем метод делегата для перехода к выполнению
    func exerciseSelectionViewModelDidSelect(exercise: Exercise) {
        // Перед переходом убедимся, что хелпер готов (или покажем индикатор загрузки)
        guard let helper = self.poseLandmarkerHelper else {
            print("LevelingCoordinator Ошибка: PoseLandmarkerHelper еще не готов.")
            // TODO: Показать пользователю сообщение об ошибке или индикатор загрузки
            return
        }
        
        // Создаем и показываем экран выполнения
        let executionVC = ExerciseExecutionViewController()
        // Создаем ViewModel, передавая все зависимости
        let executionViewModel = ExerciseExecutionViewModel(
            exercise: exercise, 
            poseLandmarkerHelper: helper,
            authService: authService, // Передаем
            progressService: progressService, // Передаем
            viewDelegate: executionVC
        )
        executionVC.viewModel = executionViewModel 
        executionVC.title = exercise.name
        // Прячем TabBar при пуше на экран выполнения
        executionVC.hidesBottomBarWhenPushed = true 
        navigationController.pushViewController(executionVC, animated: true)
    }
    
    // MARK: - Private Helpers
    
    // Метод для инициализации PoseLandmarkerHelper в фоне
    // (Как было в старом коде SceneDelegate)
    private func setupPoseLandmarkerHelperInBackground() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Параметры инициализации (можно вынести в константы или настройки)
            let modelPathString = "pose_landmarker_full.task"
            let numPoses = 1
            let minPoseDetectionConfidence: Float = 0.5
            let minPosePresenceConfidence: Float = 0.5
            let minTrackingConfidence: Float = 0.5
            let computeDelegate: Delegate = .GPU // Используем GPU
            
            guard let modelPath = Bundle.main.path(forResource: modelPathString, ofType: nil) else {
                print("LevelingCoordinator Ошибка: Файл модели MediaPipe не найден ('\(modelPathString)').")
                // TODO: Обработать ошибку (например, показать alert)
                return
            }
            
            // Используем инициализатор PoseLandmarkerHelper
            // Важно: liveStreamDelegate будет устанавливаться в ExerciseExecutionViewModel
            self.poseLandmarkerHelper = PoseLandmarkerHelper.liveStreamPoseLandmarkerHelper(
                modelPath: modelPath, 
                numPoses: numPoses,
                minPoseDetectionConfidence: minPoseDetectionConfidence, 
                minPosePresenceConfidence: minPosePresenceConfidence, 
                minTrackingConfidence: minTrackingConfidence, 
                liveStreamDelegate: nil, // Делегат будет назначен во ViewModel
                computeDelegate: computeDelegate
            )
            
            if self.poseLandmarkerHelper == nil {
                 print("LevelingCoordinator Ошибка: Ошибка инициализации PoseLandmarkerHelper.")
                 // TODO: Обработать ошибку
            } else {
                 print("--- LevelingCoordinator: PoseLandmarkerHelper инициализирован в фоне. ---")
            }
        }
    }
} 