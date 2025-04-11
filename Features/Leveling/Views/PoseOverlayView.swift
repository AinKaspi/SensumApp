import UIKit
import MediaPipeTasksVision

// Класс для отрисовки 2D-скелета поверх видео
class PoseOverlayView: UIView {

    private var poseLandmarks: [[NormalizedLandmark]]?
    private var frameSize: CGSize = .zero

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
        // print("--- PoseOverlayView: draw(_:) вызван ---") // Убираем лог
        guard let landmarks = poseLandmarks, !landmarks.isEmpty else { 
            // print("--- PoseOverlayView: draw(_:) прервано - landmarks пуст или nil")
            return 
        }
        guard frameSize != .zero else { 
            // print("--- PoseOverlayView: draw(_:) прервано - frameSize = zero")
            return 
        }
        // print("--- PoseOverlayView: Данные для отрисовки валидны, рисуем... ---") // Убираем лог

        drawLandmarks(landmarks, in: rect, imageSize: frameSize)
        drawConnections(landmarks, in: rect, imageSize: frameSize)
    }

    private func drawLandmarks(_ landmarks: [[NormalizedLandmark]], in rect: CGRect, imageSize: CGSize) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        // Убираем единый цвет заливки отсюда
        // context.setFillColor(Constants.pointFillColor.cgColor)

        for (poseIndex, pose) in landmarks.enumerated() {
            for (landmarkIndex, landmark) in pose.enumerated() {
                 let visibility = landmark.visibility?.floatValue ?? 0.0 // Используем видимость из landmark
                 
                 guard visibility > Constants.visibilityThreshold else { continue }
                 
                 // Убираем определение цвета по видимости
                 // let pointColor = color(forVisibility: visibility).cgColor
                 // context.setFillColor(pointColor)
                 context.setFillColor(Constants.pointFillColor.cgColor) // Используем стандартный цвет
                 
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
         // Используем стандартный цвет линии
         context.setStrokeColor(Constants.lineColor.cgColor)

         for (poseIndex, pose) in landmarks.enumerated() {
             for connection in Constants.poseConnections {
                 guard let startLandmark = pose[safe: connection.start],
                       let endLandmark = pose[safe: connection.end] else { continue }
                 
                 // Получаем видимости для связанных точек
                 let startVisibility = startLandmark.visibility?.floatValue ?? 0.0
                 let endVisibility = endLandmark.visibility?.floatValue ?? 0.0

                 // Рисуем линию только если ОБЕ точки достаточно видны
                 guard startVisibility > Constants.visibilityThreshold,
                       endVisibility > Constants.visibilityThreshold else { continue }
                 
                 // Убрано определение цвета линии по видимости

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
        self.frameSize = frameSize
        self.setNeedsDisplay()
    }

    func clearOverlay() {
        self.poseLandmarks = nil
        self.setNeedsDisplay()
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

    // Добавляем хелпер для определения цвета по видимости (он не используется сейчас, но оставим)
    private func color(forVisibility visibility: Float) -> UIColor {
        // Заглушка, т.к. мы используем стандартные цвета
        return Constants.pointFillColor 
    }

    private enum Constants {
        static let pointRadius: CGFloat = 5.0
        static let pointFillColor: UIColor = .yellow // Возвращаем стандартный цвет
        static let lineWidth: CGFloat = 2.0
        static let lineColor: UIColor = .green // Возвращаем стандартный цвет
        static let visibilityThreshold: Float = 0.1 // Порог видимости

        // Используем те же коннекторы, что и раньше
        // Обращаемся к PoseConnections из файла ExerciseAnalyzerProtocols
        static let poseConnections: [(start: Int, end: Int)] = PoseConnections.connections 
    }
}
