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
        context.setFillColor(Constants.pointFillColor.cgColor)

        for pose in landmarks {
            for landmark in pose {
                 guard landmark.visibility?.floatValue ?? 0.0 > Constants.visibilityThreshold else { continue }
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
         context.setStrokeColor(Constants.lineColor.cgColor)

         for pose in landmarks {
             for connection in Constants.poseConnections {
                 guard let startLandmark = pose[safe: connection.start],
                       let endLandmark = pose[safe: connection.end] else { continue }

                 guard (startLandmark.visibility?.floatValue ?? 0.0) > Constants.visibilityThreshold,
                       (endLandmark.visibility?.floatValue ?? 0.0) > Constants.visibilityThreshold else { continue }

                 let startPoint = normalizedPoint(from: startLandmark, imageSize: imageSize, viewRect: rect)
                 let endPoint = normalizedPoint(from: endLandmark, imageSize: imageSize, viewRect: rect)

                 context.move(to: startPoint)
                 context.addLine(to: endPoint)
                 context.strokePath()
             }
         }
         context.restoreGState()
     }


    func drawResult(landmarks: [[NormalizedLandmark]]?, frameSize: CGSize) {
        let landmarksCount = landmarks?.first?.count ?? 0
        print("--- PoseOverlayView: drawResult вызван -> Landmarks: \(landmarksCount > 0 ? "OK (\(landmarksCount))" : "NIL или пусто"), FrameSize: \(frameSize) ---")
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
