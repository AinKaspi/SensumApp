import UIKit
import MediaPipeTasksVision

// Класс для отрисовки 2D-скелета поверх видео
class PoseOverlayView: UIView {

    private var poseLandmarks: [[NormalizedLandmark]]?
    private var frameSize: CGSize = .zero
    // Добавляем хранилище для видимостей
    private var landmarkVisibilities: [Float]?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        clearsContextBeforeDrawing = true
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        print("--- PoseOverlayView: draw(_:) вызван ---")
        guard let landmarks = poseLandmarks, !landmarks.isEmpty else { return }
        guard frameSize != .zero else { return }
        print("--- PoseOverlayView: Данные для отрисовки валидны, рисуем... ---")

        drawLandmarks(landmarks, in: rect, imageSize: frameSize)
        drawConnections(landmarks, in: rect, imageSize: frameSize)
    }

    private func drawLandmarks(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        // Убираем единый цвет заливки отсюда
        // context.setFillColor(Constants.pointFillColor.cgColor)

        for (poseIndex, pose) in landmarks.enumerated() {
            // Получаем видимости для текущей позы (если есть)
            let visibilitiesForPose = (landmarkVisibilities != nil && landmarkVisibilities!.count == pose.count) ? landmarkVisibilities : nil
            
            for (landmarkIndex, landmark) in pose.enumerated() {
                 let visibility = visibilitiesForPose?[landmarkIndex] ?? (landmark.visibility?.floatValue ?? 0.0) // Берем точную видимость, если есть, иначе из landmark
                 
                 // Пропускаем отрисовку, если видимость ниже порога
                 guard visibility > Constants.visibilityThreshold else { continue }
                 
                 // Определяем цвет точки в зависимости от видимости
                 let pointColor = color(forVisibility: visibility).cgColor
                 context.setFillColor(pointColor)
                 
                 let viewPoint = normalizedPoint(from: landmark, imageSize: imageSize, viewRect: rect)
                 let pointRect = CGRect(x: viewPoint.x - Constants.pointRadius, y: viewPoint.y - Constants.pointRadius, width: Constants.pointRadius * 2, height: Constants.pointRadius * 2)
                 context.fillEllipse(in: pointRect)
            }
        }
        context.restoreGState()
    }

    private func drawConnections(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
         guard let context = UIGraphicsGetCurrentContext() else { return }
         context.saveGState()
         context.setLineWidth(Constants.lineWidth)
         // Убираем единый цвет линии отсюда
         // context.setStrokeColor(Constants.lineColor.cgColor)

         for (poseIndex, pose) in landmarks.enumerated() {
             let visibilitiesForPose = (landmarkVisibilities != nil && landmarkVisibilities!.count == pose.count) ? landmarkVisibilities : nil
             
             for connection in Constants.poseConnections {
                 guard let startLandmark = pose[safe: connection.start],
                       let endLandmark = pose[safe: connection.end] else { continue }
                 
                 // Получаем видимости для связанных точек
                 let startVisibility = visibilitiesForPose?[connection.start] ?? (startLandmark.visibility?.floatValue ?? 0.0)
                 let endVisibility = visibilitiesForPose?[connection.end] ?? (endLandmark.visibility?.floatValue ?? 0.0)

                 // Рисуем линию только если ОБЕ точки достаточно видны
                 guard startVisibility > Constants.visibilityThreshold,
                       endVisibility > Constants.visibilityThreshold else { continue }
                 
                 // Определяем цвет линии на основе МИНИМАЛЬНОЙ видимости из двух точек
                 let connectionColor = color(forVisibility: min(startVisibility, endVisibility)).cgColor
                 context.setStrokeColor(connectionColor)

                 let startPoint = normalizedPoint(from: startLandmark, imageSize: imageSize, viewRect: rect)
                 let endPoint = normalizedPoint(from: endLandmark, imageSize: imageSize, viewRect: rect)

                 context.move(to: startPoint)
                 context.addLine(to: endPoint)
                 context.strokePath()
             }
         }
         context.restoreGState()
     }

    // Обновляем метод, чтобы он принимал и сохранял видимости
    func drawResult(landmarks: [[NormalizedLandmark]]?, frameSize: CGSize) {
        self.poseLandmarks = landmarks
        // Извлекаем и сохраняем видимости из первого набора landmarks
        self.landmarkVisibilities = landmarks?.first?.map { $0.visibility?.floatValue ?? 0.0 }
        self.frameSize = frameSize
        // Лог оставляем как есть или убираем
        // let landmarksCount = landmarks?.first?.count ?? 0
        // print("--- PoseOverlayView: drawResult вызван -> Landmarks: \(landmarksCount > 0 ? "OK (\(landmarksCount))" : "NIL или пусто"), FrameSize: \(frameSize) ---")
        self.setNeedsDisplay()
    }

    func clearOverlay() {
        self.poseLandmarks = nil
        self.landmarkVisibilities = nil // Очищаем видимости тоже
        self.setNeedsDisplay()
    }
    
    // Добавляем хелпер для определения цвета по видимости
    private func color(forVisibility visibility: Float) -> UIColor {
        // Простая градиентная логика: от красного к зеленому
        if visibility < 0.3 {
            return .systemRed
        } else if visibility < 0.6 {
            return .systemOrange
        } else {
            return .systemGreen // Используем зеленый для линий, желтый для точек оставим
        }
        // Альтернатива: можно использовать HSB для плавного градиента
        // let hue = CGFloat(visibility) * 0.33 // 0.0 (красный) до 0.33 (зеленый)
        // return UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 0.8)
    }

    private func normalizedPoint(from normalizedLandmark: NormalizedLandmark, imageSize: CGSize, viewRect: CGRect) -> CGPoint {
         guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

         let absoluteX = CGFloat(normalizedLandmark.x) * imageSize.width
         let absoluteY = CGFloat(normalizedLandmark.y) * imageSize.height

         let viewWidth = viewRect.width
         let viewHeight = viewRect.height
         let scaleX = viewWidth / imageSize.width
         let scaleY = viewHeight / imageSize.height
         // Используем min для .scaleAspectFit или max для .scaleAspectFill
         // Для оверлея обычно лучше .scaleAspectFill, чтобы совпадало с previewLayer
         let scale = max(scaleX, scaleY)

         let offsetX = (viewWidth - imageSize.width * scale) / 2.0
         let offsetY = (viewHeight - imageSize.height * scale) / 2.0

         let viewPointX = absoluteX * scale + offsetX
         let viewPointY = absoluteY * scale + offsetY

         return CGPoint(x: viewPointX, y: viewPointY)
     }


    private enum Constants {
        static let pointRadius: CGFloat = 5.0
        static let pointFillColor: UIColor = .yellow
        static let lineWidth: CGFloat = 2.0
        static let lineColor: UIColor = .green // Вернем зеленый для 2D
        static let visibilityThreshold: Float = 0.1 // Порог видимости

        // Используем те же коннекторы, что и раньше
        // Обращаемся к PoseConnections из файла ExerciseAnalyzerProtocols
        static let poseConnections: [(start: Int, end: Int)] = PoseConnections.connections 
    }
}
