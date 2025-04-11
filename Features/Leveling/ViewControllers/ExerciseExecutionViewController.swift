import AVFoundation
import MediaPipeTasksVision
// Удаляем импорты AR, добавляем SceneKit
// import RealityKit
// import ARKit
import SceneKit

// MARK: - LevelingViewController Class

// Переименовываем класс в ExerciseExecutionViewController
class ExerciseExecutionViewController: UIViewController { // ВАЖНО: Имя класса должно совпадать с именем файла после переименования!

    // MARK: - Dependencies & Core Logic
    var selectedExercise: Exercise? // Добавляем свойство для хранения выбранного упражнения
    // Оставляем только объявление viewModel. Он будет установлен координатором.
    var viewModel: ExerciseExecutionViewModel!
    
    // Возвращаем свойства AVFoundation, включая previewLayer
    private var captureSession = AVCaptureSession()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue.exec") // Новая очередь

    // Свойства для SceneKit и скелета
    private var skeletonNode: SCNNode? // Корневой узел для всего скелета
    private var jointNodes: [Int: SCNNode] = [:] // Словарь для узлов суставов [Индекс: Узел]
    private var boneNodes: [Int: SCNNode] = [:] // Словарь для узлов костей [Хэш_пары_индексов: Узел]

    // MARK: - UI Elements
    // Возвращаем PoseOverlayView для 2D отрисовки
    private lazy var poseOverlayView: PoseOverlayView = { // Используем имя PoseOverlayView
        let overlayView = PoseOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.clearsContextBeforeDrawing = true
        return overlayView
    }()
    
    // Возвращаем AVCaptureVideoPreviewLayer для фона
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
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

    // Добавляем лейблы для отладочной информации
    private lazy var debugStateLabel: UILabel = createDebugLabel()
    private lazy var debugAnglesLabel: UILabel = createDebugLabel()
    private lazy var debugRepCountLabel: UILabel = createDebugLabel()
    private lazy var debugVisibilityLabel: UILabel = createDebugLabel()
    
    private lazy var debugStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            debugStateLabel,
            debugAnglesLabel,
            debugRepCountLabel,
            debugVisibilityLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        stackView.layer.cornerRadius = 5
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
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
        // Удаляем вызов addTapGestures
        // addTapGestures()
        
        // Возвращаем настройку AVCaptureSession
        setupAVSession()
        
        // Сообщаем ViewModel, что View загрузилась
        viewModel.viewDidLoad()
        
        // Удаляем setupSkeletonNodes
        // setupSkeletonNodes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Возвращаем запуск AVCaptureSession
        startSession() 
        
        // Сообщаем ViewModel
        viewModel.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Возвращаем остановку AVCaptureSession
        stopSession() 
        // Удаляем паузу AR сессии
        // pauseARSession()
        
        // Сообщаем ViewModel
        viewModel.viewWillDisappear()
    }
    
    // Возвращаем viewDidLayoutSubviews для установки frame previewLayer
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем frame previewLayer
        previewLayer.frame = view.bounds
        // Обновляем frame overlayView (хотя он должен растягиваться констрейнтами, но на всякий случай)
        poseOverlayView.frame = view.bounds
    }

    // MARK: - UI Setup

    private func setupViews() {
        view.backgroundColor = .black // Фон для камеры
        // Добавляем previewLayer
        view.layer.addSublayer(previewLayer)
        // Добавляем poseOverlayView
        view.addSubview(poseOverlayView)

        view.addSubview(xpProgressBar)
        view.addSubview(bottomStatsStackView)
        
        // Добавляем стек отладки поверх всего
        view.addSubview(debugStackView)
        view.bringSubviewToFront(debugStackView)
        // Поднимаем UI поверх слоя камеры и оверлея
        view.bringSubviewToFront(xpProgressBar)
        view.bringSubviewToFront(bottomStatsStackView)
    }

    private func setupConstraints() {
        // Констрейнты для poseOverlayView
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

        // Constraints for Debug Stack View (в левом верхнем углу)
        NSLayoutConstraint.activate([
            debugStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            debugStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            // Ограничим ширину, чтобы не растягивался сильно
            debugStackView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6)
        ])
    }

    // MARK: - Camera Setup & Control
    
    private func setupAVSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            // Устанавливаем качество
            self.captureSession.sessionPreset = .high // Или другое подходящее

            // --- ЯВНО ВЫБИРАЕМ ФРОНТАЛЬНУЮ КАМЕРУ ---
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                              for: .video, 
                                                              position: .front), // Ищем фронтальную
                  let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
                  self.captureSession.canAddInput(captureDeviceInput)
            else {
                print("ExerciseExecutionVC Ошибка: Не удалось найти или настроить фронтальную камеру.")
                // TODO: Показать ошибку пользователю
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(captureDeviceInput)
            print("--- ExerciseExecutionVC: Фронтальная камера добавлена --- ")
            // ----------------------------------------

            // Настраиваем вывод видео данных
            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                // Оставляем BGRA, т.к. MediaPipe его ожидает, и конвертация из CVPixelBuffer работала
                // Если возникнут проблемы с производительностью, можно попробовать получить YUV 
                // и передавать его в MPImage (pixelBuffer:), но BGRA надежнее для старта.
                self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.captureSession.addOutput(self.videoDataOutput)
                // Настраиваем ориентацию вывода (важно для фронталки)
                self.updateVideoOutputOrientation(for: self.videoDataOutput.connection(with: .video))
                 print("--- ExerciseExecutionVC: Вывод видео настроен (BGRA) --- ")
            } else {
                print("ExerciseExecutionVC Ошибка: Не удалось добавить вывод видео данных.")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.commitConfiguration()
        }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
             // Проверка прав доступа к камере 
             switch AVCaptureDevice.authorizationStatus(for: .video) {
             case .authorized:
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("--- ExerciseExecutionVC: AVCaptureSession запущена --- ")
                }
             case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted { 
                        self?.startSession() // Повторный вызов после получения прав
                    } else { 
                        print("ExerciseExecutionVC Ошибка: Доступ к камере запрещен.")
                        // TODO: Показать пользователю сообщение
                    }
                }
             default:
                 print("ExerciseExecutionVC Ошибка: Доступ к камере запрещен или ограничен.")
                 // TODO: Показать пользователю сообщение
             }
        }
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("--- ExerciseExecutionVC: AVCaptureSession остановлена --- ")
            }
        }
    }
    
    // MARK: - Helper Methods
    // Удаляем getDefaultCamera
    
    // Возвращаем updateVideoOutputOrientation
    private func updateVideoOutputOrientation(for connection: AVCaptureConnection?) {
        guard let connection = connection, connection.isVideoOrientationSupported else { return }
        
        // Устанавливаем портретную ориентацию
        connection.videoOrientation = .portrait
        
        // Включаем зеркалирование для фронтальной камеры
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
            print("--- ExerciseExecutionVC: Зеркалирование видео включено --- ")
        }
    }
    
    // Оставляем uiImageOrientation, но теперь он используется в captureOutput
    private func uiImageOrientation(from videoOrientation: AVCaptureVideoOrientation) -> UIImage.Orientation {
        switch videoOrientation {
            case .portrait: return .right 
            case .portraitUpsideDown: return .left
            case .landscapeLeft: return .up
            case .landscapeRight: return .down
            @unknown default: return .up
        }
    }

    // MARK: - SceneKit Setup (Новый раздел)
    private func setupSceneKitScene(scnView: SCNView) {
        print("--- ExerciseExecutionVC: Настройка сцены SceneKit --- ")
        let scene = SCNScene()
        
        // 2. Создаем и добавляем камеру
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 80 
        // Вернем камеру чуть ближе для начала
        cameraNode.position = SCNVector3(x: 0, y: 0.3, z: 1.8) 
        scene.rootNode.addChildNode(cameraNode)
        
        // 3. Назначаем сцену для view
        scnView.scene = scene
        
        // 4. НЕ устанавливаем previewLayer как фон сцены, он будет под ней
        // scene.background.contents = self.previewLayer
        
        // 5. (Опционально) Добавляем простой свет
        // let lightNode = SCNNode()
        // lightNode.light = SCNLight()
        // lightNode.light!.type = .omni
        // lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        // scene.rootNode.addChildNode(lightNode)
        
        print("--- ExerciseExecutionVC: Сцена SceneKit настроена с видеофоном --- ")
        
        // TODO: Создать корневой узел для скелета и узлы для суставов/костей
        // setupSkeletonNodes()
    }
    
    /// Создает начальные узлы для суставов и костей скелета
    private func setupSkeletonNodes() {
        print("--- ExerciseExecutionVC: Создание узлов скелета SceneKit --- ")
        // 1. Удаляем старый скелет, если он был
        skeletonNode?.removeFromParentNode()
        jointNodes.removeAll()
        boneNodes.removeAll()
        
        // 2. Создаем корневой узел
        let rootNode = SCNNode()
        self.skeletonNode = rootNode
        // Удаляем добавление узла в scnView.scene, т.к. scnView больше нет
        // scnView.scene?.rootNode.addChildNode(rootNode)
        // Вместо этого, нужно будет добавить его в сцену, которая будет рендериться (если вернем SceneKit)
        
        // 3. Создаем материалы (можно вынести в константы)
        let jointMaterial = SCNMaterial()
        jointMaterial.diffuse.contents = UIColor.yellow.withAlphaComponent(0.8)
        
        let boneMaterial = SCNMaterial()
        boneMaterial.diffuse.contents = UIColor.cyan.withAlphaComponent(0.8)
        
        // 4. Создаем узлы для СУСТАВОВ (33 точки)
        let jointRadius: CGFloat = 0.015 // Радиус сферы сустава в метрах
        for i in 0..<33 { // Предполагаем 33 точки, как в MediaPipe Pose
            let jointSphere = SCNSphere(radius: jointRadius)
            jointSphere.materials = [jointMaterial]
            let jointNode = SCNNode(geometry: jointSphere)
            jointNode.isHidden = true // Изначально скрыты, пока не придут данные
            rootNode.addChildNode(jointNode)
            jointNodes[i] = jointNode
        }
        print("--- ExerciseExecutionVC: Создано \(jointNodes.count) узлов суставов --- ")
        
        // 5. Создаем узлы для КОСТЕЙ
        let boneRadius: CGFloat = 0.01 // Радиус цилиндра кости
        for connection in PoseConnections.connections { // Используем константы соединений
            guard let startNode = jointNodes[connection.start],
                  let endNode = jointNodes[connection.end] else { continue }
            
            // Создаем узел для кости (пока просто пустой, геометрия будет обновляться)
            let boneNode = SCNNode()
            boneNode.isHidden = true // Изначально скрыты
            // Используем цилиндр как базовую геометрию, его длину и ориентацию будем менять
            // Длина 1.0 - нормализованная, будем масштабировать
            let boneGeometry = SCNCylinder(radius: boneRadius, height: 1.0)
            boneGeometry.materials = [boneMaterial]
            boneNode.geometry = boneGeometry
            // Поворачиваем цилиндр, чтобы он лежал вдоль оси Z (по умолчанию он вдоль Y)
            boneNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            
            rootNode.addChildNode(boneNode)
            // Сохраняем узел кости по уникальному ключу (хэш пары индексов)
            let connectionHash = connection.start * 100 + connection.end // Простой способ хеширования
            boneNodes[connectionHash] = boneNode
        }
         print("--- ExerciseExecutionVC: Создано \(boneNodes.count) узлов костей --- ")
    }
    
    // Обновляем узлы скелета на основе новых данных landmarks
    private func updateSkeletonNodes(with landmarks: [Landmark]) {
        guard let skeletonNode = skeletonNode else { return }
        
        // Масштабный коэффициент - ставим большой для видимости
        let skeletonScaleFactor: Float = 400.0 
        
        // 1. Обновляем позиции и видимость СУСТАВОВ
        for (index, jointNode) in jointNodes {
            guard index < landmarks.count else { continue }
            
            let landmark = landmarks[index]
            let isVisible = (landmark.visibility?.floatValue ?? 0.0) > PoseConnections.visibilityThreshold
            
            jointNode.isHidden = !isVisible
            
            if isVisible {
                // Применяем преобразование координат (X, -Y, -Z) и масштаб
                jointNode.position = SCNVector3(
                    landmark.x * skeletonScaleFactor, 
                    -landmark.y * skeletonScaleFactor, 
                    -landmark.z * skeletonScaleFactor 
                )
            }
        }
        
        // 2. ВРЕМЕННО ОТКЛЮЧАЕМ обновление костей
        for connection in PoseConnections.connections {
             let connectionHash = connection.start * 100 + connection.end
             if let boneNode = boneNodes[connectionHash] {
                 boneNode.isHidden = true // Просто скрываем все кости
             }
        }
        /* // Старый код обновления костей
        for connection in PoseConnections.connections {
           ...
        }
        */
    }

    // Вспомогательная функция для создания лейблов отладки
    private func createDebugLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0 // Для возможного переноса строк
        label.text = "--"
        return label
    }
}

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
    
    // Новый метод для приема 2D-координат от ViewModel
    func viewModelDidUpdatePose(landmarks: [[NormalizedLandmark]]?, frameSize: CGSize) {
        // Логируем получение данных
        // let landmarksCount = landmarks?.first?.count ?? 0
        // print("--- ExerciseExecutionVC: Получены данные от VM -> Landmarks: \(landmarksCount > 0 ? "OK (\(landmarksCount))" : "NIL или пусто"), FrameSize: \(frameSize) ---") // Убираем лог
            
        // Обновляем UI в главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Передаем 2D-данные в PoseOverlayView для отрисовки
            // print("--- ExerciseExecutionVC: Вызов poseOverlayView.drawResult --- ") // Убираем лог
            self.poseOverlayView.drawResult(landmarks: landmarks, frameSize: frameSize)
        }
    }
    
    // MARK: - Debug Info Updates
    
    func viewModelDidUpdateDebugState(_ state: String) {
        DispatchQueue.main.async {
            self.debugStateLabel.text = "State: \(state)"
        }
    }
    
    func viewModelDidUpdateDebugAngles(knee: Float, hip: Float) {
        DispatchQueue.main.async {
            self.debugAnglesLabel.text = String(format: "Angles: K=%.1f H=%.1f", knee, hip)
        }
    }
    
    func viewModelDidUpdateDebugRepCount(_ count: Int) {
        DispatchQueue.main.async {
            self.debugRepCountLabel.text = "Reps: \(count)"
        }
    }
    
    // Обновляем метод для приема массива видимостей
    func viewModelDidUpdateDebugVisibility(visibilities: [Float]?) {
        DispatchQueue.main.async {
            guard let visibilities = visibilities, !visibilities.isEmpty else {
                self.debugVisibilityLabel.text = "Vis: N/A"
                self.debugVisibilityLabel.textColor = .white
                return
            }
            // Проверяем видимость ключевых точек (индексы из PoseConnections)
            let keyIndices = [PoseConnections.LandmarkIndex.leftHip, PoseConnections.LandmarkIndex.rightHip, 
                              PoseConnections.LandmarkIndex.leftKnee, PoseConnections.LandmarkIndex.rightKnee, 
                              PoseConnections.LandmarkIndex.leftAnkle, PoseConnections.LandmarkIndex.rightAnkle, 
                              PoseConnections.LandmarkIndex.leftShoulder, PoseConnections.LandmarkIndex.rightShoulder]
            var allKeyPointsVisible = true
            var visibleCount = 0
            var totalVisibility: Float = 0.0
            
            for index in keyIndices {
                if index < visibilities.count {
                    let visibility = visibilities[index]
                    if visibility > PoseConnections.visibilityThreshold {
                        visibleCount += 1
                        totalVisibility += visibility
                    } else {
                        allKeyPointsVisible = false
                    }
                } else {
                    allKeyPointsVisible = false // Индекс вне диапазона
                }
            }
            let averageVisibility = (visibleCount > 0) ? totalVisibility / Float(visibleCount) : 0.0
            
            let visibilityText = allKeyPointsVisible ? "OK" : "BAD (\(visibleCount)/\(keyIndices.count))"
            self.debugVisibilityLabel.text = String(format: "Vis: %@ (avg %.2f)", visibilityText, averageVisibility)
            self.debugVisibilityLabel.textColor = allKeyPointsVisible ? .green : .orange // Оранжевый вместо красного
        }
    }
    
    // TODO: Реализовать другие методы делегата (level up, error, etc.)
}

// MARK: - Delegates

// Возвращаем AVCaptureVideoDataOutputSampleBufferDelegate (оставляем ТОЛЬКО здесь)
extension ExerciseExecutionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Выполняется в sessionQueue
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("ExerciseExecutionVC Error: Failed to get CVPixelBuffer from CMSampleBuffer.")
            return
        }
        
        // СНАЧАЛА обновляем lastFrameSize
        lastFrameSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        // ТЕПЕРЬ безопасно извлекаем актуальный размер
        guard let currentFrameSize = lastFrameSize else { 
            // Эта проверка почти не нужна теперь, но оставим на всякий случай
            print("ExerciseExecutionVC Error: Failed to get currentFrameSize.")
            return 
        }

        let imageOrientation: UIImage.Orientation = .right 
        let frameTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let milliseconds = Int(CMTimeGetSeconds(frameTimestamp) * 1000)

        // Передаем CVPixelBuffer напрямую во ViewModel, добавляем frameSize
        viewModel.processVideoFrame(
            pixelBuffer: pixelBuffer, 
            orientation: imageOrientation, 
            timeStamps: milliseconds,
            frameSize: currentFrameSize // Передаем актуальный размер
        )
    }
}

// MARK: - AR Session Management & Rendering (Удаляем)
/*
extension ExerciseExecutionViewController {
    private func setupARSession() { ... }
    private func pauseARSession() { ... }
    private func setupSkeletonEntities() { ... }
    private func updateSkeletonEntities(with landmarks: [Landmark]) { ... }
}
*/

// Добавляем утилиту безопасного доступа к массиву, если ее нет в другом месте
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
