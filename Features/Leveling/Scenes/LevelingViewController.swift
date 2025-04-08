import UIKit
import AVFoundation // Импортируем AVFoundation
import MediaPipeTasksVision // Импортируем MediaPipe

// MARK: - Protocols (Переносим сюда или убеждаемся, что они доступны)
// Если эти определения уже есть в PoseLandmarkerHelper.swift, их здесь дублировать НЕ НУЖНО.
// Оставляю на случай, если они не импортируются автоматически.
/*
 protocol PoseLandmarkerServiceLiveStreamDelegate: AnyObject {
     func poseLandmarkerService(_ poseLandmarkerService: PoseLandmarkerHelper, // Используем новое имя
                                didFinishDetection result: ResultBundle?,
                                error: Error?)
     // Возможно, были и другие методы?
 }

 struct ResultBundle {
     let inferenceTime: Double
     let poseLandmarkerResults: [PoseLandmarkerResult?]
     var size: CGSize = .zero
 }

 protocol PoseLandmarkerDelegate: AnyObject { // Нужен для базовых опций
     var delegate: Delegates { get }
 }
 */

// MARK: - LevelingViewController
class LevelingViewController: UIViewController {

    // MARK: - AVFoundation Properties
    private var captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill // Или .resizeAspect
        return layer
    }()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    // Используем последовательную очередь, чтобы избежать проблем с потоками при настройке сессии
    private let sessionQueue = DispatchQueue(label: "com.sensum.sessionQueue")

    // MARK: - Pose Landmarker Properties
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private let modelPath = "pose_landmarker_full.task" // Убедись, что имя файла верное
    
    // --- Параметры для инициализации хелпера (из примера Google) ---
    private let numPoses = DefaultConstants.numPoses // Используем константы, если они есть
    private let minPoseDetectionConfidence: Float = DefaultConstants.minPoseDetectionConfidence
    private let minPosePresenceConfidence: Float = DefaultConstants.minPosePresenceConfidence
    private let minTrackingConfidence: Float = DefaultConstants.minTrackingConfidence
    // -------------------------------------------------------

    // --- Добавляем свойство для анализатора приседаний ---
    private var squatAnalyzer: SquatAnalyzer?
    // ---------------------------------------------------

    private lazy var poseOverlayView: PoseOverlayView = {
        let overlayView = PoseOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.clearsContextBeforeDrawing = true // Для очистки предыдущих поз
        return overlayView
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Или другой фон
        setupViews()
        setupAVSession()
        // Настраиваем MediaPipe ПОСЛЕ настройки AVFoundation
        sessionQueue.async {
            self.setupPoseLandmarker()
            // Инициализируем анализатор здесь же, после MediaPipe
            self.setupSquatAnalyzer()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession() // Запускаем сессию при появлении экрана
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession() // Останавливаем при уходе с экрана
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем frame previewLayer при изменении layout'а
        previewLayer.frame = view.bounds 
        poseOverlayView.frame = view.bounds // Убедимся, что overlay тоже обновляется
    }

    // MARK: - UI Setup
    private func setupViews() {
        // Добавляем слой превью камеры ПОД overlay view
        view.layer.addSublayer(previewLayer)
        // Добавляем overlay view
        view.addSubview(poseOverlayView)
        
        // Констрейнты для overlay (занимает весь экран)
        NSLayoutConstraint.activate([
            poseOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            poseOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poseOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poseOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - AVFoundation Setup and Control
    private func setupAVSession() {
        sessionQueue.async {
            // Начинаем конфигурацию сессии
            self.captureSession.beginConfiguration()
            
            // Настраиваем качество сессии (можно выбрать другое)
            self.captureSession.sessionPreset = .high 
            
            // 1. Находим и настраиваем устройство ввода (камеру)
            guard let captureDevice = self.getDefaultCamera(),
                  let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
                  self.captureSession.canAddInput(captureDeviceInput) 
            else {
                print("Ошибка: Не удалось получить доступ к камере или добавить ввод.")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(captureDeviceInput)
            
            // 2. Настраиваем вывод видео данных
            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                // Устанавливаем формат пикселей BGRA, часто используемый MediaPipe
                self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
                // Отбрасываем кадры, если обработка не успевает
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true 
                self.captureSession.addOutput(self.videoDataOutput)
                
                // Устанавливаем ориентацию видео
                 self.updateVideoOutputOrientation()
            } else {
                 print("Ошибка: Не удалось добавить вывод видео данных.")
                 self.captureSession.commitConfiguration()
                 return
            }
            
            // Завершаем конфигурацию
            self.captureSession.commitConfiguration()
        }
    }

    private func startSession() {
        sessionQueue.async {
            // Проверяем права доступа к камере
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // Права есть, запускаем сессию
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("AVCaptureSession запущена.")
                }
            case .notDetermined: // Прав нет, запрашиваем
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard let self = self else { return }
                    if granted {
                        // Запускаем на sessionQueue, так как startRunning - блокирующая операция
                        self.sessionQueue.async {
                            if !self.captureSession.isRunning {
                                 self.captureSession.startRunning()
                                 print("AVCaptureSession запущена после запроса прав.")
                            }
                        }
                    } else {
                        print("Доступ к камере запрещен пользователем.")
                        // Можно показать алерт или сообщение
                    }
                }
            case .denied, .restricted: // Доступ запрещен или ограничен
                print("Доступ к камере запрещен или ограничен.")
                // Можно показать алерт с предложением перейти в настройки
            @unknown default:
                // Используем assertionFailure вместо fatalError для отладки
                assertionFailure("Неизвестный статус доступа к камере")
            }
        }
    }

    private func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("AVCaptureSession остановлена.")
            }
        }
    }

    // MARK: - MediaPipe Setup
    private func setupPoseLandmarker() {
        // Убедимся, что вызывается из sessionQueue
        // УДАЛЯЕМ assert, так как currentLabel больше не доступен
        // assert(DispatchQueue.currentLabel == sessionQueue.label, "Must be called on sessionQueue")

        guard let modelPath = Bundle.main.path(forResource: modelPath, ofType: nil) else {
            print("Ошибка: Не удалось найти файл модели MediaPipe (\(self.modelPath)). Убедись, что он добавлен в таргет.")
            // TODO: Показать ошибку пользователю
            return
        }

        // Используем статический метод инициализации из PoseLandmarkerHelper
        poseLandmarkerHelper = PoseLandmarkerHelper.liveStreamPoseLandmarkerHelper(
            modelPath: modelPath,
            numPoses: self.numPoses,
            minPoseDetectionConfidence: self.minPoseDetectionConfidence,
            minPosePresenceConfidence: self.minPosePresenceConfidence,
            minTrackingConfidence: self.minTrackingConfidence,
            liveStreamDelegate: self,
            // Используем встроенный Delegate из SDK
            computeDelegate: DefaultConstants.delegate // Убедись, что DefaultConstants.delegate имеет тип Delegate (.CPU или .GPU)
        )

        if poseLandmarkerHelper == nil {
             print("Ошибка инициализации PoseLandmarkerHelper.")
             // TODO: Показать ошибку пользователю
        } else {
            print("PoseLandmarkerHelper успешно инициализирован.")
        }
    }

    // MARK: - Analyzer Setup (Новый метод)
    private func setupSquatAnalyzer() {
        // Убедимся, что вызывается из sessionQueue (или main, если безопасно)
        // DispatchQueue.main.async { // Если инициализация быстрая, можно и в main
            self.squatAnalyzer = SquatAnalyzer(delegate: self)
            print("SquatAnalyzer инициализирован в LevelingViewController.")
        // }
    }

    // MARK: - Helper Methods
    private func getDefaultCamera() -> AVCaptureDevice? {
        // Предпочитаем фронтальную камеру для селфи-режима упражнений
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return device
        }
        // Если фронтальной нет, берем заднюю
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        // Если и задней нет...
        return nil
    }
    
     private func updateVideoOutputOrientation() {
         guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else { return }
         // Устанавливаем ориентацию видео на портретную (может понадобиться другая)
         connection.videoOrientation = .portrait 
         // Если используем фронтальную камеру, часто нужно зеркальное отображение
         if connection.isVideoMirroringSupported, let input = captureSession.inputs.first as? AVCaptureDeviceInput, input.device.position == .front {
             connection.isVideoMirrored = true
         }
     }

    // Метод для конвертации AVCaptureVideoOrientation в UIImage.Orientation
    private func uiImageOrientation(from videoOrientation: AVCaptureVideoOrientation) -> UIImage.Orientation {
        switch videoOrientation {
            case .portrait: return .up
            case .portraitUpsideDown: return .down
            case .landscapeRight: return .right // Важно: .landscapeRight для AVCapture -> .right для UIImage
            case .landscapeLeft: return .left   // Важно: .landscapeLeft для AVCapture -> .left для UIImage
            @unknown default:
                assertionFailure("Неизвестная AVCaptureVideoOrientation")
                return .up // Возвращаем значение по умолчанию
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension LevelingViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Выполняется в sessionQueue
        
        // --- Получаем размер кадра из CMSampleBuffer --- 
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Error: Failed to get CVPixelBuffer from CMSampleBuffer.")
            return
        }
        // Размер кадра (может быть повернут относительно UI)
        let frameSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer),
                               height: CVPixelBufferGetHeight(imageBuffer))
        // -------------------------------------------------

        // Определяем ориентацию для MediaPipe ИЗ CONNECTION
        let videoOrientation = connection.videoOrientation
        let orientation = uiImageOrientation(from: videoOrientation)

        // Получаем временную метку
        let frameTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let milliseconds = Int(CMTimeGetSeconds(frameTimestamp) * 1000)

        // Вызываем detectAsync из PoseLandmarkerHelper
        poseLandmarkerHelper?.detectAsync(
            sampleBuffer: sampleBuffer,
            orientation: orientation,
            timeStamps: milliseconds
        )
        
        // --- СОХРАНЯЕМ размер кадра для использования в делегате --- 
        // Важно: Это не потокобезопасно, если кадры могут обрабатываться параллельно.
        // Более надежный способ - передать frameSize вместе с результатом через делегат,
        // но текущая структура PoseLandmarkerHelper этого не позволяет.
        // Для простой реализации пока сохраним в свойство.
        // Убедись, что доступ к этому свойству происходит только из DispatchQueue.main.async
        // в методе делегата.
        self.lastFrameSize = frameSize
        // -----------------------------------------------------------
    }
}

// MARK: - PoseLandmarkerHelperLiveStreamDelegate
extension LevelingViewController: PoseLandmarkerHelperLiveStreamDelegate {
    // --- Добавляем свойство для хранения размера последнего кадра --- 
    private static var lastFrameSizeAssociationKey: UInt8 = 0
    private var lastFrameSize: CGSize? {
        get {
            return objc_getAssociatedObject(self, &Self.lastFrameSizeAssociationKey) as? CGSize
        }
        set(newValue) {
            objc_setAssociatedObject(self, &Self.lastFrameSizeAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    // -------------------------------------------------------------

    func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                              didFinishDetection result: ResultBundle?,
                              error: Error?) {
        // Вызывается из PoseLandmarkerHelper

        DispatchQueue.main.async {
            // --- Получаем сохраненный размер кадра --- 
            guard let currentFrameSize = self.lastFrameSize else {
                print("Warning: Could not get last frame size for drawing.")
                 // Можно сбросить overlay или использовать размер view как крайнюю меру
                 self.poseOverlayView.clearOverlay()
                return
            }
            // -----------------------------------------

            // Обработка ошибки
            if let error = error {
                print("Ошибка детекции поз: \(error.localizedDescription)")
                // Можно сбросить overlay
                self.poseOverlayView.clearOverlay()
                // TODO: Показать ошибку пользователю?
                return
            }

            // Обработка результата (ResultBundle БЕЗ size)
            guard let result = result else {
                // Поз не найдено
                self.poseOverlayView.clearOverlay()
                return
            }

            // --- Передаем landmarks в анализатор --- 
            // Получаем landmarks как [[NormalizedLandmark]]
            if let poseLandmarksArray = result.poseLandmarkerResults.first??.landmarks {
                // Извлекаем ПЕРВЫЙ массив точек ([NormalizedLandmark])
                if let firstPoseLandmarks = poseLandmarksArray.first,
                   !firstPoseLandmarks.isEmpty {
                     // Передаем именно [NormalizedLandmark]
                     self.squatAnalyzer?.analyze(landmarks: firstPoseLandmarks)
                }
            } else {
                // Если landmarks нет, возможно, стоит сбросить состояние анализатора?
                // self.squatAnalyzer?.reset() 
            }
            // ----------------------------------------

            // Передаем данные в overlay view
            self.poseOverlayView.drawResult(result, frameSize: currentFrameSize)
        }
    }
}

// MARK: - SquatAnalyzerDelegate (Новое расширение)
extension LevelingViewController: SquatAnalyzerDelegate {
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didCountSquat totalCount: Int) {
        // Вызывается, когда засчитано приседание
        // TODO: Обновить UI, отобразить счетчик
        print("\n >>>>> ПРИСЕДАНИЕ #\(totalCount) ЗАСЧИТАНО! <<<<< \n")
        // Например, обновить лейбл:
        // countLabel.text = "\(totalCount)"
    }
    
    func squatAnalyzer(_ analyzer: SquatAnalyzer, didChangeState newState: String) {
        // Вызывается при смене состояния (up/down/unknown)
        // TODO: Обновить UI, отобразить текущее состояние
        print("--- Состояние приседания: \(newState.uppercased()) ---")
        // Например, изменить цвет индикатора:
        // stateIndicatorView.backgroundColor = (newState == "down") ? .red : .green
    }
}

// MARK: - PoseOverlayView (Пример реализации на основе Google Sample)
// TODO: Этот код можно вынести в отдельный файл Views/PoseOverlayView.swift
class PoseOverlayView: UIView {

    private var currentResult: ResultBundle?
    // Добавляем свойство для хранения размера кадра
    private var currentFrameSize: CGSize = .zero 

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let result = currentResult, !result.poseLandmarkerResults.isEmpty else { return }

        // Отрисовка каждой найденной позы
        for poseResult in result.poseLandmarkerResults where poseResult != nil {
            // Используем currentFrameSize для нормализации
            drawLandmarks(poseResult!.landmarks, in: rect, imageSize: currentFrameSize)
            drawConnections(poseResult!.landmarks, in: rect, imageSize: currentFrameSize)
        }
    }

    /**
     Рисует точки (landmarks) на вью.
     - Parameters:
       - landmarks: Массив массивов нормализованных координат точек.
       - rect: Границы текущего UIView.
       - imageSize: Размер исходного изображения/кадра, к которому нормализованы landmarks.
     */
    private func drawLandmarks(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext(), !landmarks.isEmpty else { return }

        context.saveGState()
        context.setFillColor(Constants.pointFillColor.cgColor)

        for poseLandmarks in landmarks {
            for landmark in poseLandmarks {
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
       - landmarks: Массив массивов нормализованных координат точек.
       - rect: Границы текущего UIView.
       - imageSize: Размер исходного изображения/кадра, к которому нормализованы landmarks.
     */
    private func drawConnections(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext(), !landmarks.isEmpty else { return }

        context.saveGState()
        context.setLineWidth(Constants.lineWidth)
        context.setStrokeColor(Constants.lineColor.cgColor)

        for poseLandmarks in landmarks {
            // Возвращаемся к стандартному PoseLandmarker.poseConnections()
            // Заменяем вызов SDK на вручную определенный массив соединений
            for connection in Constants.poseConnections {
                guard let startLandmark = poseLandmarks[safe: connection.start],
                      let endLandmark = poseLandmarks[safe: connection.end] else {
                    continue // Пропускаем, если индексы некорректны
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
     Преобразует нормализованную точку из координат изображения в координаты UIView,
     учитывая размер изображения и `videoGravity` (предполагается `.resizeAspectFill`).
     - Parameters:
       - normalizedLandmark: Нормализованная точка от MediaPipe.
       - imageSize: Размер исходного изображения/кадра.
       - viewRect: Границы текущего UIView.
     - Returns: Точка в системе координат UIView.
     */
     private func normalizedPoint(from normalizedLandmark: NormalizedLandmark, imageSize: CGSize, viewRect: CGRect) -> CGPoint {
         guard imageSize.width > 0, imageSize.height > 0 else { return .zero } // Защита от деления на ноль

         // Масштабируем нормализованные координаты до абсолютных координат изображения
         let absoluteX = CGFloat(normalizedLandmark.x) * imageSize.width
         let absoluteY = CGFloat(normalizedLandmark.y) * imageSize.height

         // Рассчитываем коэффициент масштабирования для .resizeAspectFill
         let viewWidth = viewRect.width
         let viewHeight = viewRect.height
         let scaleX = viewWidth / imageSize.width
         let scaleY = viewHeight / imageSize.height
         let scale = max(scaleX, scaleY)

         // Рассчитываем смещение для центрирования изображения в .resizeAspectFill
         let offsetX = (viewWidth - imageSize.width * scale) / 2.0
         let offsetY = (viewHeight - imageSize.height * scale) / 2.0

         // Применяем масштаб и смещение к абсолютным координатам
         let viewPointX = absoluteX * scale + offsetX
         let viewPointY = absoluteY * scale + offsetY

         return CGPoint(x: viewPointX, y: viewPointY)
     }


    // MARK: - Constants
    private enum Constants {
        static let pointRadius: CGFloat = 6.0
        static let pointFillColor: UIColor = .yellow
        static let lineWidth: CGFloat = 3.0
        static let lineColor: UIColor = .green
        
        // Стандартные соединения скелета MediaPipe Pose (v0.10+)
        // Индексы соответствуют точкам в PoseLandmarkerResult.landmarks
        static let poseConnections: [(start: Int, end: Int)] = [
            // Торс
            (start: 11, end: 12), // Плечи
            (start: 11, end: 23), // Левое плечо -> Левое бедро
            (start: 12, end: 24), // Правое плечо -> Правое бедро
            (start: 23, end: 24), // Бедра
            // Левая рука
            (start: 11, end: 13), // Плечо -> Локоть
            (start: 13, end: 15), // Локоть -> Запястье
            // Правая рука
            (start: 12, end: 14), // Плечо -> Локоть
            (start: 14, end: 16), // Локоть -> Запястье
            // Левая нога
            (start: 23, end: 25), // Бедро -> Колено
            (start: 25, end: 27), // Колено -> Лодыжка
             // (start: 27, end: 29), // Лодыжка -> Пятка (опционально)
             // (start: 27, end: 31), // Лодыжка -> Носок (опционально)
             // (start: 29, end: 31), // Пятка -> Носок (опционально)
            // Правая нога
            (start: 24, end: 26), // Бедро -> Колено
            (start: 26, end: 28), // Колено -> Лодыжка
             // (start: 28, end: 30), // Лодыжка -> Пятка (опционально)
             // (start: 28, end: 32), // Лодыжка -> Носок (опционально)
             // (start: 30, end: 32) // Пятка -> Носок (опционально)
            // Голова (опционально, линий мало)
             // (start: 0, end: 1), // Нос -> Левый глаз (внутр)
             // (start: 0, end: 4), // Нос -> Правый глаз (внутр)
             // (start: 9, end: 10) // Рот
        ]
    }
}

// MARK: - Utility Extensions

// Добавляем безопасный доступ к массиву по индексу
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Конвертер ориентации (из примера Google)
@available(iOS 13.0, *)
extension AVCaptureVideoOrientation {
    init(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
            case .portrait: self = .portrait
            case .landscapeLeft: self = .landscapeLeft
            case .landscapeRight: self = .landscapeRight
            case .portraitUpsideDown: self = .portraitUpsideDown
            default: self = .portrait // Или можно выбросить ошибку
        }
    }
}

extension AVCaptureVideoOrientation {
    // Этот инициализатор нужен для поддержки iOS < 13
    init(interfaceOrientation: UIInterfaceOrientation?) {
        guard let orientation = interfaceOrientation else {
            self = .portrait // Значение по умолчанию
            return
        }
        switch orientation {
            case .portrait: self = .portrait
            case .landscapeLeft: self = .landscapeLeft
            case .landscapeRight: self = .landscapeRight
            case .portraitUpsideDown: self = .portraitUpsideDown
            default: self = .portrait
        }
    }
}

// Константы по умолчанию (из примера Google)
// TODO: Этот код можно вынести в отдельный файл Configurations/DefaultConstants.swift
struct DefaultConstants {
  // Используем встроенный Delegate
  static let delegate: Delegate = .GPU
  static let modelPath: String = "pose_landmarker_full.task"
  static let numPoses: Int = 1
  static let minPoseDetectionConfidence: Float = 0.5
  static let minPosePresenceConfidence: Float = 0.5
  static let minTrackingConfidence: Float = 0.5

  static let inferenceIntervalMs: Double = 100.0
  static let minimumPressDuration: Double = 1.0
} 