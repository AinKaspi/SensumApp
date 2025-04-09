import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - Protocols (Нужны для PoseLandmarkerHelperDelegate)
// Убедись, что эти структуры/протоколы доступны
// (Либо определены здесь, либо импортированы из PoseLandmarkerHelper)

// Примерная структура, используемая в делегате MediaPipe
struct ResultBundle {
    let inferenceTime: Double
    let poseLandmarkerResults: [PoseLandmarkerResult?
    // Добавляем размер кадра, так как он нужен для отрисовки
    let frameSize: CGSize
}

// Протокол делегата от PoseLandmarkerHelper
protocol PoseLandmarkerHelperLiveStreamDelegate: AnyObject {
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                              didFinishDetection result: ResultBundle?,
                              error: Error?)
}

// MARK: - LevelingViewController Class

// ИСПОЛЬЗУЕМ СТАРОЕ ИМЯ КЛАССА, ПОКА НЕ ПЕРЕИМЕНОВАЛИ ФАЙЛ
// ПОТОМ НУЖНО БУДЕТ ВЕРНУТЬ LevelingViewController
class LevelingViewController: UIViewController { // ВАЖНО: Имя класса должно совпадать с именем файла после переименования!

    // MARK: - Dependencies & Core Logic
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let squatAnalyzer: SquatAnalyzer = SquatAnalyzer() // Явный тип

    // MARK: - AVFoundation Properties
    private var captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue")

    // MARK: - MediaPipe Properties
    private let modelPath = "pose_landmarker_full.task" // Убедись, что имя верное
    // --- Параметры для инициализации хелпера (могут быть в DefaultConstants) ---
    private let numPoses = 1
    private let minPoseDetectionConfidence: Float = 0.5
    private let minPosePresenceConfidence: Float = 0.5
    private let minTrackingConfidence: Float = 0.5
    private let computeDelegate: Delegate = .GPU // Или .CPU
    // -------------------------------------------------------

    // MARK: - UI Elements
    // TODO: Добавить PoseOverlayView, если нужен для отрисовки скелета
    // private lazy var poseOverlayView: PoseOverlayView = { ... }()

    private lazy var xpProgressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = .darkGray
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var progressiveGoalLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .left
        label.text = "Goal: 0/5"
        return label
    }()

    private lazy var totalSquatsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.text = "Total: 0"
        return label
    }()

    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .right
        label.text = "Time: 00:00"
        return label
    }()

    private lazy var bottomStatsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [progressiveGoalLabel, totalSquatsLabel, timerLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    // MARK: - State Properties

    private var currentXP: Int = 0
    private var xpForNextLevel: Int = 100
    private let xpPerSquat: Int = 10
    private let bonusXPForGoal: Int = 50

    private var progressiveSquatGoal: Int = 5
    private let progressiveGoalIncrement: Int = 5
    private var squatsTowardsProgressiveGoal: Int = 0

    private var totalSquatsInSession: Int = 0

    private var sessionStartDate: Date?
    private var sessionTimer: Timer?
    private let timerUpdateInterval: TimeInterval = 1.0
    
    // Для передачи размера кадра в делегат
    private var lastFrameSize: CGSize? 

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        squatAnalyzer.delegate = self
        resetSessionState()

        // Настраиваем AVFoundation и MediaPipe
        setupAVSession()
        sessionQueue.async { [weak self] in
            self?.setupPoseLandmarker()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession() // Запускаем камеру
        if sessionStartDate == nil { // Запускаем таймер, если сессия новая
            startTimer()
            squatAnalyzer.reset() // Сбрасываем счетчик при начале новой сессии
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession() // Останавливаем камеру
        stopTimer()   // Останавливаем таймер
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем frame previewLayer при изменении layout'а
        previewLayer.frame = view.bounds
        // poseOverlayView.frame = view.bounds // Если используется
    }

    // MARK: - UI Setup

    private func setupViews() {
        view.backgroundColor = .black // Фон для камеры
        view.layer.addSublayer(previewLayer)
        // view.addSubview(poseOverlayView) // Если используется

        view.addSubview(xpProgressBar)
        view.addSubview(bottomStatsStackView)
        
        // Поднимаем UI поверх слоя камеры
        view.bringSubviewToFront(xpProgressBar)
        view.bringSubviewToFront(bottomStatsStackView)
    }

    private func setupConstraints() {
        // Констрейнты для previewLayer (на весь экран)
        // previewLayer констрейнтов не имеет, устанавливается через frame
        
        // Констрейнты для poseOverlayView (если используется)
        /*
        NSLayoutConstraint.activate([
            poseOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            poseOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poseOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poseOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        */

        // Constraints for XP Progress Bar
        NSLayoutConstraint.activate([
            xpProgressBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            xpProgressBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            xpProgressBar.bottomAnchor.constraint(equalTo: bottomStatsStackView.topAnchor, constant: -12),
            xpProgressBar.heightAnchor.constraint(equalToConstant: 8)
        ])

        // Constraints for Bottom Stats Stack View
        NSLayoutConstraint.activate([
            bottomStatsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bottomStatsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            bottomStatsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
        ])
    }

    // MARK: - Session State Management

    private func resetSessionState() {
        currentXP = 0
        progressiveSquatGoal = 5
        squatsTowardsProgressiveGoal = 0
        totalSquatsInSession = 0
        sessionStartDate = nil
        stopTimer() // Убедимся, что таймер остановлен
        squatAnalyzer.reset() // Сбрасываем анализатор
        updateUI()
    }

    private func updateUI() {
        let progress = Float(currentXP) / Float(xpForNextLevel)
        xpProgressBar.setProgress(min(progress, 1.0), animated: true)
        progressiveGoalLabel.text = "Goal: \(squatsTowardsProgressiveGoal)/\(progressiveSquatGoal)"
        totalSquatsLabel.text = "Total: \(totalSquatsInSession)"
        if sessionStartDate == nil {
            timerLabel.text = "Time: 00:00"
        }
    }

    // MARK: - Camera Setup & Control
    
    private func setupAVSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let captureDevice = self.getDefaultCamera(),
                  let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
                  self.captureSession.canAddInput(captureDeviceInput)
            else {
                print("Ошибка: Не удалось настроить ввод камеры.")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(captureDeviceInput)

            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.captureSession.addOutput(self.videoDataOutput)
                self.updateVideoOutputOrientation()
            } else {
                print("Ошибка: Не удалось добавить вывод видео данных.")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.commitConfiguration()
        }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
             // Проверка прав доступа к камере (упрощенная для примера, добавь полную обработку)
             switch AVCaptureDevice.authorizationStatus(for: .video) {
             case .authorized:
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("AVCaptureSession запущена.")
                }
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted { self?.startSession() } // Повторный вызов после получения прав
                    else { print("Доступ к камере запрещен.") }
                }
            default:
                 print("Доступ к камере запрещен или ограничен.")
             }
        }
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("AVCaptureSession остановлена.")
            }
        }
    }

    // MARK: - MediaPipe Setup

    private func setupPoseLandmarker() {
        // Убедимся, что вызывается из sessionQueue
        guard let modelPath = Bundle.main.path(forResource: self.modelPath, ofType: nil) else {
            print("Ошибка: Файл модели MediaPipe не найден (\(self.modelPath)).")
            return
        }

        self.poseLandmarkerHelper = PoseLandmarkerHelper.liveStreamPoseLandmarkerHelper(
            modelPath: modelPath,
            numPoses: self.numPoses,
            minPoseDetectionConfidence: self.minPoseDetectionConfidence,
            minPosePresenceConfidence: self.minPosePresenceConfidence,
            minTrackingConfidence: self.minTrackingConfidence,
            liveStreamDelegate: self,
            computeDelegate: self.computeDelegate
        )
        
        if poseLandmarkerHelper == nil {
            print("Ошибка инициализации PoseLandmarkerHelper.")
        } else {
            print("PoseLandmarkerHelper успешно инициализирован.")
        }
    }

    // MARK: - Timer Logic

    private func startTimer() {
        stopTimer()
        sessionStartDate = Date()
        timerLabel.text = "Time: 00:00"
        sessionTimer = Timer.scheduledTimer(timeInterval: timerUpdateInterval,
                                            target: self,
                                            selector: #selector(updateTimerLabel),
                                            userInfo: nil,
                                            repeats: true)
    }

    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    @objc private func updateTimerLabel() {
        guard let startDate = sessionStartDate else { return }
        let elapsedTime = Int(Date().timeIntervalSince(startDate))
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        timerLabel.text = String(format: "Time: %02d:%02d", minutes, seconds)
    }
    
    // MARK: - Helper Methods
    
    private func getDefaultCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        return nil
    }
    
    private func updateVideoOutputOrientation() {
        guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
        if connection.isVideoMirroringSupported, let input = captureSession.inputs.first as? AVCaptureDeviceInput, input.device.position == .front {
            connection.isVideoMirrored = true
        }
    }
    
    private func uiImageOrientation(from videoOrientation: AVCaptureVideoOrientation) -> UIImage.Orientation {
        switch videoOrientation {
            case .portrait: return .right // MediaPipe ожидает right для портрета с фронталки
            case .portraitUpsideDown: return .left
            case .landscapeRight: return .down
            case .landscapeLeft: return .up
            @unknown default: return .up
        }
    }

} // Конец class LevelingViewController

// MARK: - Delegates

extension LevelingViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Выполняется в sessionQueue
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Error: Failed to get CVPixelBuffer from CMSampleBuffer.")
            return
        }
        // Сохраняем размер кадра для отрисовки
        lastFrameSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))

        let orientation = uiImageOrientation(from: connection.videoOrientation)
        let frameTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let milliseconds = Int(CMTimeGetSeconds(frameTimestamp) * 1000)

        poseLandmarkerHelper?.detectAsync(
            sampleBuffer: sampleBuffer,
            orientation: orientation,
            timeStamps: milliseconds
        )
    }
}

extension LevelingViewController: PoseLandmarkerHelperLiveStreamDelegate {
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                              didFinishDetection result: ResultBundle?,
                              error: Error?) {
        // Вызывается из PoseLandmarkerHelper
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Обработка ошибки
            if let error = error {
                print("Ошибка детекции поз: \(error.localizedDescription)")
                // self.poseOverlayView?.clearOverlay() // Если используется
                return
            }
            
            // Обработка результата
            guard let result = result else {
                // self.poseOverlayView?.clearOverlay() // Если используется
                return
            }

            // Извлекаем landmarks из результата (предполагаем одну позу)
            if let poseLandmarksArray = result.poseLandmarkerResults.first??.landmarks,
               let firstPoseLandmarks = poseLandmarksArray.first, !firstPoseLandmarks.isEmpty {
                 self.squatAnalyzer.analyze(landmarks: firstPoseLandmarks)
            } else {
                 // Поз не найдено или нет точек
                 // Можно сбросить состояние анализатора, если нужно
                 // self.squatAnalyzer.reset()
            }
            
            // Отрисовка (если используется PoseOverlayView)
            // guard let frameSize = self.lastFrameSize else { return }
            // self.poseOverlayView?.drawResult(result, frameSize: frameSize)
        }
    }
}

extension LevelingViewController: SquatAnalyzerDelegate {
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat newTotalCount: Int) {
        // Этот код мы уже реализовали
        totalSquatsInSession = newTotalCount
        currentXP += xpPerSquat
        squatsTowardsProgressiveGoal += 1

        if squatsTowardsProgressiveGoal >= progressiveSquatGoal {
            print("--- Progressive Goal #\(progressiveSquatGoal) Reached! ---")
            currentXP += bonusXPForGoal
            // Исправляем баг: увеличиваем ЦЕЛЬ, а не ИНКРЕМЕНТ
            progressiveSquatGoal += progressiveGoalIncrement 
            squatsTowardsProgressiveGoal = 0
        }
        updateUI()
    }
    
    // Добавим этот метод, чтобы можно было реализовать delegate
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) {
        // Пока можно просто вывести в лог
        print("(Delegate) Squat State Changed: \(newState)")
    }
}
