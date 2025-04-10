import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - LevelingViewController Class

// Переименовываем класс в ExerciseExecutionViewController
class ExerciseExecutionViewController: UIViewController { // ВАЖНО: Имя класса должно совпадать с именем файла после переименования!

    // MARK: - Dependencies & Core Logic
    var selectedExercise: Exercise? // Добавляем свойство для хранения выбранного упражнения
    
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
        // Загружаем профиль пользователя
        userProfile = DataManager.shared.getCurrentUserProfile()
        
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

    // MARK: - Session State Management

    private func resetSessionState() {
        currentXP = 0 // Эта переменная теперь не нужна, XP берем из профиля
        progressiveSquatGoal = 5
        squatsTowardsProgressiveGoal = 0
        totalSquatsInSession = 0 // Счетчик приседаний *за сессию* оставляем
        sessionStartDate = nil
        stopTimer()
        squatAnalyzer.reset()
        
        // Обновляем userProfile на случай, если он был nil
        if userProfile == nil {
            userProfile = DataManager.shared.getCurrentUserProfile()
        }
        
        updateUI()
    }

    private func updateUI() {
        // Используем данные из userProfile
        guard let profile = userProfile else { return } // Защита, если профиль еще не загружен
        let progress = Float(profile.currentXP) / Float(profile.xpToNextLevel)
        xpProgressBar.setProgress(min(progress, 1.0), animated: true)
        progressiveGoalLabel.text = "Goal: \(squatsTowardsProgressiveGoal)/\(progressiveSquatGoal)"
        totalSquatsLabel.text = "Total: \(profile.totalSquats)"
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

} // Конец class ExerciseExecutionViewController

// MARK: - Delegates

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

        poseLandmarkerHelper?.detectAsync(
            sampleBuffer: sampleBuffer,
            orientation: orientation,
            timeStamps: milliseconds
        )
    }
}

extension ExerciseExecutionViewController: PoseLandmarkerHelperLiveStreamDelegate {
    // Обновляем имя параметра на resultBundle, как в протоколе
    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                              didFinishDetection resultBundle: ResultBundle?,
                              error: Error?) {
        // Вызывается из PoseLandmarkerHelper
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Обработка ошибки
            if let error = error {
                print("Ошибка детекции поз: \\(error.localizedDescription)")
                self.poseOverlayView.clearOverlay() // Очищаем старый оверлей при ошибке
                return
            }
            
            // Обработка результата
            guard let resultBundle = resultBundle else {
                self.poseOverlayView.clearOverlay() // Очищаем, если результата нет
                return
            }

            // --- ИЗВЛЕКАЕМ 3D КООРДИНАТЫ --- 
            // resultBundle.poseWorldLandmarks содержит [[Landmark]]?
            // Landmark содержит x, y, z в метрах
            if let worldLandmarks = resultBundle.poseWorldLandmarks,
               let firstPoseWorldLandmarks = worldLandmarks.first, // Берем первую обнаруженную позу
               !firstPoseWorldLandmarks.isEmpty {
                // Передаем 3D-координаты в анализатор
                // Раскомментируем вызов, так как SquatAnalyzer теперь принимает [Landmark]
                self.squatAnalyzer.analyze(worldLandmarks: firstPoseWorldLandmarks)
                print("--- LevelingVC: Получены 3D worldLandmarks (\\(firstPoseWorldLandmarks.count) точек). Переданы в анализатор. ---")
            } else {
                 // Поз не найдено или нет 3D точек
                 self.squatAnalyzer.reset() // Сбрасываем состояние анализатора
                 print("--- LevelingVC: Не найдены 3D worldLandmarks. Анализатор сброшен. ---")
            }
            
            // --- Отрисовка скелета (ПОКА ОТКЛЮЧАЕМ/УПРОЩАЕМ) ---
            // TODO: Обновить PoseOverlayView для отрисовки 3D-точек или временно отключить
            /* 
            guard let frameSize = self.lastFrameSize else {
                print("Warning: frameSize not available for drawing overlay.")
                return
            }
            // Сейчас PoseOverlayView ожидает старый ResultBundle и 2D точки.
            // Нужно либо передавать 2D точки (resultBundle.poseLandmarks), 
            // либо переделать PoseOverlayView для 3D.
            // Пока очистим, чтобы не было ошибок.
            */
            self.poseOverlayView.clearOverlay() 
            // Или временно передаем 2D, если хотим видеть хоть что-то:
            // self.poseOverlayView.drawResult(resultBundle.poseLandmarks, frameSize: frameSize)
            
        }
    }
}

extension ExerciseExecutionViewController: SquatAnalyzerDelegate {
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat newTotalCount: Int) {
        // Убедимся, что профиль загружен
        guard var profile = userProfile else {
            print("Error: User profile is nil in squatAnalyzer delegate.")
            return
        }
        
        // 1. Обновляем ОБЩЕЕ количество приседаний в профиле
        profile.totalSquats += 1 // Счетчик обновляем здесь
        
        // 2. Рассчитываем модификатор опыта на основе статов
        // Для приседаний используем Мощь (PWR)
        // Базовое значение стата берем из UserProfile.baseStatValue (20)
        // Отклонение = Текущий_стат - Базовый_стат
        // Модификатор = 1.0 + (Отклонение / 100.0) (т.е. +/- 1% за каждое очко отклонения от базы 20)
        let powerStat = profile.power // Получаем Мощь
        let baseStatValue = UserProfile.baseStatValue // Используем базу из UserProfile
        let statDifference = powerStat - baseStatValue
        let xpMultiplier = 1.0 + (Double(statDifference) / 100.0)
        
        // Рассчитываем итоговый опыт, но не меньше 1
        let baseXP = Double(xpPerSquat)
        let calculatedXP = Int(round(baseXP * xpMultiplier))
        let finalXP = max(1, calculatedXP) // Опыт не может быть меньше 1
        
        // Добавляем baseStatValue обратно в лог
        print("--- LevelingVC squatAnalyzer: Расчет XP: База=\(xpPerSquat), Мощь=\(powerStat), БазСтат=\(baseStatValue), Множ=x\(String(format: "%.2f", xpMultiplier)), Итог=\(finalXP) ---")
        
        // 3. Добавляем РАССЧИТАННЫЙ опыт через метод addXP
        let didLevelUpBasic = profile.addXP(finalXP)
        if didLevelUpBasic {
            print("--- LevelingVC squatAnalyzer: Обнаружено повышение уровня после базового XP! ---")
            // TODO: Показать эффект повышения уровня?
        }
        
        // 4. Определяем прирост атрибутов для приседания (примерные значения)
        // Приседания качают силу ног и кора (STR), выносливость (CON), баланс (BAL)
        let strGain = 2
        let conGain = 1
        let balGain = 1
        // Вызываем метод прокачки атрибутов
        profile.gainAttributes(strGain: strGain, conGain: conGain, balGain: balGain)
        
        // 5. Продвигаем сессионную прогрессивную цель
        squatsTowardsProgressiveGoal += 1

        if squatsTowardsProgressiveGoal >= progressiveSquatGoal {
            
            // Добавляем бонусный опыт через метод addXP (бонус не модифицируем статами, он фиксированный)
            let didLevelUpBonus = profile.addXP(bonusXPForGoal)
            if didLevelUpBonus {
                // TODO: Показать эффект повышения уровня (может сработать и после базового)?
            }
            
            // Исправляем баг: увеличиваем ЦЕЛЬ, а не ИНКРЕМЕНТ
            progressiveSquatGoal += progressiveGoalIncrement 
            squatsTowardsProgressiveGoal = 0
        }
        
        // 6. Сохраняем обновленный профиль (после всех изменений XP и атрибутов)
        DataManager.shared.updateUserProfile(profile)
        // Обновляем локальную копию на всякий случай (хотя DataManager должен обновить свою)
        self.userProfile = profile 
        
        // 7. Обновляем UI
        updateUI()
    }
    
    // Добавим этот метод, чтобы можно было реализовать delegate
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) {
        // Пока можно просто вывести в лог
        print("(Delegate) Squat State Changed: \(newState)")
    }
}

// MARK: - PoseOverlayView (Добавляем определение сюда)

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
