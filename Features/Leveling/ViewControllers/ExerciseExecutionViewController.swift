import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - LevelingViewController Class

// Переименовываем класс в ExerciseExecutionViewController
class ExerciseExecutionViewController: UIViewController { // ВАЖНО: Имя класса должно совпадать с именем файла после переименования!

    // MARK: - Dependencies & Core Logic
    var selectedExercise: Exercise? // Добавляем свойство для хранения выбранного упражнения
    // Оставляем только объявление viewModel. Он будет установлен координатором.
    var viewModel: ExerciseExecutionViewModel!
    
    // Удаляем свойства, связанные с MediaPipe и анализом
    // private var poseLandmarkerHelper: PoseLandmarkerHelper?
    // private let squatAnalyzer: SquatAnalyzer = SquatAnalyzer() 

    // MARK: - AVFoundation Properties
    private var captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue")

    // Удаляем свойства MediaPipe
    /*
    private let modelPath = "pose_landmarker_full.task"
    // ... остальные параметры ... 
    */

    // MARK: - UI Elements
    // Отображение скелета
    private lazy var poseOverlayView: PoseOverlayView = {
        let overlayView = PoseOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.clearsContextBeforeDrawing = true
        return overlayView
    }()

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

    // Свойство для хранения текущего профиля пользователя
    private var userProfile: UserProfile?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Удаляем загрузку профиля, этим займется ViewModel
        // userProfile = DataManager.shared.getCurrentUserProfile()
        
        setupViews()
        setupConstraints()
        // Удаляем назначение делегата анализатору, ViewModel сама это сделает
        // squatAnalyzer.delegate = self
        // Удаляем resetSessionState, логика состояния переедет в ViewModel
        // resetSessionState()

        // Настраиваем AVFoundation (остается здесь, т.к. управляет View)
        setupAVSession()
        // Удаляем запуск настройки MediaPipe, ViewModel сама запустит
        /*
        sessionQueue.async { [weak self] in
            self?.setupPoseLandmarker()
        }
        */
        // Сообщаем ViewModel, что View загрузилась
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession() // Запускаем камеру (остается здесь)
        // Удаляем запуск таймера и сброс анализатора
        /*
        if sessionStartDate == nil { 
            startTimer()
            squatAnalyzer.reset() 
        }
        */
        // Сообщаем ViewModel
        viewModel.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession() // Останавливаем камеру (остается здесь)
        // Удаляем остановку таймера
        // stopTimer()
        // Сообщаем ViewModel
        viewModel.viewWillDisappear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем frame previewLayer при изменении layout'а
        previewLayer.frame = view.bounds
        poseOverlayView.frame = view.bounds // Обновляем frame overlay тоже
    }

    // MARK: - UI Setup

    private func setupViews() {
        view.backgroundColor = .black // Фон для камеры
        view.layer.addSublayer(previewLayer)
        view.addSubview(poseOverlayView) // Добавляем overlay

        view.addSubview(xpProgressBar)
        view.addSubview(bottomStatsStackView)
        
        // Поднимаем UI поверх слоя камеры
        view.bringSubviewToFront(xpProgressBar)
        view.bringSubviewToFront(bottomStatsStackView)
    }

    private func setupConstraints() {
        // Констрейнты для previewLayer (на весь экран)
        // previewLayer констрейнтов не имеет, устанавливается через frame
        
        // Констрейнты для poseOverlayView (раскомментировано)
        NSLayoutConstraint.activate([
            poseOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            poseOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poseOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poseOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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

    // MARK: - Session State Management (удаляем или переносим во ViewModel)
    // private func resetSessionState() { ... }
    // private func updateUI() { ... } // ViewModel будет давать команды на обновление

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

} // Конец class ExerciseExecutionViewController

// MARK: - ExerciseExecutionViewModelViewDelegate
extension ExerciseExecutionViewController: ExerciseExecutionViewModelViewDelegate {
    
    func viewModelDidUpdateTimer(timeString: String) {
        // Обновляем UI в главном потоке
        DispatchQueue.main.async {
            self.timerLabel.text = "Time: \(timeString)"
        }
    }
    
    func viewModelDidUpdateProgress(currentXP: Int, xpToNextLevel: Int) {
        // Обновляем UI в главном потоке
        DispatchQueue.main.async {
            let progress = xpToNextLevel > 0 ? Float(currentXP) / Float(xpToNextLevel) : 0
            let clampedProgress = max(0.0, min(1.0, progress))
            self.xpProgressBar.setProgress(clampedProgress, animated: true) // Можно анимировать
            // TODO: Возможно, обновить и текстовые метки XP, если они появятся
        }
    }
    
    func viewModelDidUpdateGoal(current: Int, target: Int) {
        // Обновляем UI в главном потоке
        DispatchQueue.main.async {
            self.progressiveGoalLabel.text = "Goal: \(current)/\(target)"
        }
    }
    
    // TODO: Реализовать другие методы делегата (level up, error, etc.)
}

// MARK: - Delegates

// AVCaptureVideoDataOutputSampleBufferDelegate остается здесь, но передает кадр во ViewModel
extension ExerciseExecutionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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

        // Передаем кадр во ViewModel для обработки
        viewModel.processVideoFrame(
            sampleBuffer: sampleBuffer, 
            orientation: orientation, 
            timeStamps: milliseconds
        )
    }
}

// Удаляем реализацию PoseLandmarkerHelperLiveStreamDelegate отсюда
/*
extension ExerciseExecutionViewController: PoseLandmarkerHelperLiveStreamDelegate {
    func poseLandmarkerHelper(...) { ... }
}
*/

// Удаляем реализацию SquatAnalyzerDelegate отсюда
/*
extension ExerciseExecutionViewController: SquatAnalyzerDelegate {
    func squatAnalyzer(...) { ... }
}
*/

// MARK: - PoseOverlayView (остается здесь, т.к. это View)

// TODO: Этот код можно вынести в отдельный файл Views/PoseOverlayView.swift
class PoseOverlayView: UIView {

    private var currentResult: ResultBundle?
    // Добавляем свойство для хранения размера кадра
    private var currentFrameSize: CGSize = .zero

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Используем Optional Chaining и guard для безопасности
        // Изменяем доступ к данным: берем 2D poseLandmarks из ResultBundle
        guard let landmarks2D = currentResult?.poseLandmarks else { return }

        // Отрисовка позы
        // Используем currentFrameSize для нормализации
        // Передаем landmarks2D вместо poseResult.landmarks
        drawLandmarks(landmarks2D, in: rect, imageSize: currentFrameSize)
        drawConnections(landmarks2D, in: rect, imageSize: currentFrameSize)
    }

    /**
     Рисует точки (landmarks) на вью.
     - Parameters:
       - landmarks: Массив точек [[NormalizedLandmark]].
       - rect: Границы текущего UIView.
       - imageSize: Размер исходного изображения/кадра, к которому нормализованы landmarks.
     */
    private func drawLandmarks(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext(), !landmarks.isEmpty else { return }

        context.saveGState()
        context.setFillColor(Constants.pointFillColor.cgColor)

        // Landmarks - это [[NormalizedLandmark]], итерируем по внешнему массиву (хотя у нас он один)
        for poseLandmarks in landmarks {
            for landmark in poseLandmarks {
                // Пропускаем отрисовку, если точка не видна достаточно хорошо (опционально)
                guard landmark.visibility?.floatValue ?? 0 > 0.1 else { continue }
                
                let viewPoint = normalizedPoint(from: landmark, imageSize: imageSize, viewRect: rect)
                let pointRect = CGRect(x: viewPoint.x - Constants.pointRadius, y: viewPoint.y - Constants.pointRadius, width: Constants.pointRadius * 2, height: Constants.pointRadius * 2)
                context.fillEllipse(in: pointRect)
            }
        }
        context.restoreGState()
    }

    /**
     Рисует линии соединений между точками.
     - Parameters:
       - landmarks: Массив точек [[NormalizedLandmark]].
       - rect: Границы текущего UIView.
       - imageSize: Размер исходного изображения/кадра, к которому нормализованы landmarks.
     */
    private func drawConnections(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext(), !landmarks.isEmpty else { return }

        context.saveGState()
        context.setLineWidth(Constants.lineWidth)
        context.setStrokeColor(Constants.lineColor.cgColor)

        // Итерируем по внешнему массиву поз
        for poseLandmarks in landmarks { // poseLandmarks здесь типа [NormalizedLandmark]
            for connection in Constants.poseConnections {
                guard let startLandmark = poseLandmarks[safe: connection.start],
                      let endLandmark = poseLandmarks[safe: connection.end] else {
                    continue // Пропускаем, если индексы некорректны
                }
                
                // Проверяем видимость обеих точек для соединения (опционально)
                guard startLandmark.visibility?.floatValue ?? 0 > 0.1,
                      endLandmark.visibility?.floatValue ?? 0 > 0.1 else {
                    continue
                }

                let startPoint = normalizedPoint(from: startLandmark, imageSize: imageSize, viewRect: rect)
                let endPoint = normalizedPoint(from: endLandmark, imageSize: imageSize, viewRect: rect)

                context.move(to: startPoint)
                context.addLine(to: endPoint)
                context.strokePath()
            }
        }
        context.restoreGState()
    }

    // MARK: - Public Methods
    /**
     Устанавливает результат для отрисовки и вызывает перерисовку.
     - Parameter result: Результат от PoseLandmarkerHelper.
     */
    func drawResult(_ result: ResultBundle?, frameSize: CGSize) {
        self.currentResult = result
        // Сохраняем размер кадра
        self.currentFrameSize = frameSize
        self.setNeedsDisplay()
    }

    /**
     Очищает текущий результат и перерисовывает (становится пустым).
     */
    func clearOverlay() {
        self.currentResult = nil
        self.setNeedsDisplay()
    }

    // MARK: - Helper Methods
    /**
     Преобразует нормализованную точку из координат изображения в координаты UIView.
     */
    private func normalizedPoint(from normalizedLandmark: NormalizedLandmark, imageSize: CGSize, viewRect: CGRect) -> CGPoint {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let absoluteX = CGFloat(normalizedLandmark.x) * imageSize.width
        let absoluteY = CGFloat(normalizedLandmark.y) * imageSize.height

        let viewWidth = viewRect.width
        let viewHeight = viewRect.height
        let scaleX = viewWidth / imageSize.width
        let scaleY = viewHeight / imageSize.height
        let scale = max(scaleX, scaleY) // .resizeAspectFill

        let offsetX = (viewWidth - imageSize.width * scale) / 2.0
        let offsetY = (viewHeight - imageSize.height * scale) / 2.0

        let viewPointX = absoluteX * scale + offsetX
        let viewPointY = absoluteY * scale + offsetY

        return CGPoint(x: viewPointX, y: viewPointY)
    }

    // MARK: - Constants
    private enum Constants {
        static let pointRadius: CGFloat = 5.0
        static let pointFillColor: UIColor = .yellow
        static let lineWidth: CGFloat = 2.0
        static let lineColor: UIColor = .green

        static let poseConnections: [(start: Int, end: Int)] = [
            (start: 11, end: 12), (start: 11, end: 23), (start: 12, end: 24), (start: 23, end: 24),
            (start: 11, end: 13), (start: 13, end: 15), (start: 12, end: 14), (start: 14, end: 16),
            (start: 23, end: 25), (start: 25, end: 27), (start: 24, end: 26), (start: 26, end: 28)
            // Добавь другие соединения при необходимости
        ]
    }
}

// Добавляем утилиту безопасного доступа к массиву, если ее нет в другом месте
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
