// Copyright 2023 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import MediaPipeTasksVision // Убедись, что импорт правильный
import AVFoundation

// MARK: - Protocols -

/**
 This protocol must be adopted by any class that wants to get the detection results of the pose landmarker in live stream mode.
 */
protocol PoseLandmarkerHelperLiveStreamDelegate: AnyObject {
  func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                             didFinishDetection result: ResultBundle?,
                             error: Error?)
}

/**
 This protocol must be adopted by any class that wants to take appropriate actions during different stages of pose landmark detection on videos.
 */
protocol PoseLandmarkerHelperVideoDelegate: AnyObject {
 func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                                  didFinishDetectionOnVideoFrame index: Int)
 func poseLandmarkerHelper(_ poseLandmarkerHelper: PoseLandmarkerHelper,
                             willBeginDetection totalframeCount: Int)
}

// MARK: - Delegates Enum -
// УДАЛЯЕМ наш кастомный enum Delegates
/*
 enum Delegates: Int {
     case CPU
     case GPU
 }
 */

// MARK: - Result Bundle -
/**
 A result bundle containing the inference time and pose landmarker results for an image or video frame.
 */
struct ResultBundle {
  let inferenceTime: Double
  let poseLandmarkerResult: PoseLandmarkerResult? // Один результат
}

// MARK: - PoseLandmarkerHelper Class -

// Initializes and calls the MediaPipe APIs for pose detection.
class PoseLandmarkerHelper: NSObject {

  weak var liveStreamDelegate: PoseLandmarkerHelperLiveStreamDelegate?
  weak var videoDelegate: PoseLandmarkerHelperVideoDelegate?

  var poseLandmarker: PoseLandmarker?
  private(set) var runningMode: RunningMode = .image
  // УДАЛЯЕМ currentLiveStreamImage
  // private var currentLiveStreamImage: MPImage?


  // MARK: - Initialization -

  /**
   Creates a new instance of PoseLandmarkerHelper.
   - Parameters:
     - modelPath: The path to the pose landmarker model (.task file).
     - runningMode: The mode for running the pose landmarker (image, video, liveStream).
     - numPoses: The maximum number of poses to detect.
     - minPoseDetectionConfidence: The minimum confidence score for pose detection to be considered successful.
     - minPosePresenceConfidence: The minimum confidence score of pose presence landmark detection.
     - minTrackingConfidence: The minimum confidence score for the pose tracking to be considered successful.
     - computeDelegate: The delegate object that handles configurations for the model. (Usually handles CPU/GPU choice).
   */
  // Используем public init, если класс используется из другого модуля
  init?(modelPath: String,
        runningMode: RunningMode,
        numPoses: Int,
        minPoseDetectionConfidence: Float,
        minPosePresenceConfidence: Float,
        minTrackingConfidence: Float,
        // Используем встроенный Delegate из SDK
        computeDelegate: Delegate) {

    self.runningMode = runningMode
    super.init() // Вызываем init родителя

    // Пытаемся создать PoseLandmarker
    do {
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = numPoses
        options.minPoseDetectionConfidence = minPoseDetectionConfidence
        options.minPosePresenceConfidence = minPosePresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence

        // Настраиваем базовые опции
        let baseOptions = BaseOptions()
        baseOptions.modelAssetPath = modelPath
        // Используем переданный computeDelegate напрямую (он уже типа Delegate)
        baseOptions.delegate = computeDelegate
        options.baseOptions = baseOptions

        // Устанавливаем делегат для live stream, если нужно
        if runningMode == .liveStream {
          options.poseLandmarkerLiveStreamDelegate = self
        }

        self.poseLandmarker = try PoseLandmarker(options: options)

    } catch {
        print("Failed to create Pose Landmarker: \(error)")
        return nil // Возвращаем nil, если инициализация не удалась
    }
  }

  // MARK: - Static Initializers (Convenience) -

  // Оставляем статические инициализаторы для удобства, но убедимся, что они вызывают основной init
  static func liveStreamPoseLandmarkerHelper(
    modelPath: String?, // Используем не опциональный String в основном init
    numPoses: Int,
    minPoseDetectionConfidence: Float,
    minPosePresenceConfidence: Float,
    minTrackingConfidence: Float,
    liveStreamDelegate: PoseLandmarkerHelperLiveStreamDelegate?,
    computeDelegate: Delegate) -> PoseLandmarkerHelper? {

      guard let modelPath = modelPath else {
          print("Error: Model path cannot be nil.")
          return nil
      }

      let helper = PoseLandmarkerHelper(
          modelPath: modelPath,
          runningMode: .liveStream,
          numPoses: numPoses,
          minPoseDetectionConfidence: minPoseDetectionConfidence,
          minPosePresenceConfidence: minPosePresenceConfidence,
          minTrackingConfidence: minTrackingConfidence,
          computeDelegate: computeDelegate)

      helper?.liveStreamDelegate = liveStreamDelegate
      return helper
  }

  static func videoPoseLandmarkerHelper(
    modelPath: String?,
    numPoses: Int,
    minPoseDetectionConfidence: Float,
    minPosePresenceConfidence: Float,
    minTrackingConfidence: Float,
    videoDelegate: PoseLandmarkerHelperVideoDelegate?,
    computeDelegate: Delegate) -> PoseLandmarkerHelper? {

      guard let modelPath = modelPath else {
          print("Error: Model path cannot be nil.")
          return nil
      }

      let helper = PoseLandmarkerHelper(
          modelPath: modelPath,
          runningMode: .video,
          numPoses: numPoses,
          minPoseDetectionConfidence: minPoseDetectionConfidence,
          minPosePresenceConfidence: minPosePresenceConfidence,
          minTrackingConfidence: minTrackingConfidence,
          computeDelegate: computeDelegate)

      helper?.videoDelegate = videoDelegate
      return helper
  }

 static func stillImageLandmarkerHelper(
    modelPath: String?,
    numPoses: Int,
    minPoseDetectionConfidence: Float,
    minPosePresenceConfidence: Float,
    minTrackingConfidence: Float,
    computeDelegate: Delegate) -> PoseLandmarkerHelper? {

      guard let modelPath = modelPath else {
          print("Error: Model path cannot be nil.")
          return nil
      }

      let helper = PoseLandmarkerHelper(
          modelPath: modelPath,
          runningMode: .image,
          numPoses: numPoses,
          minPoseDetectionConfidence: minPoseDetectionConfidence,
          minPosePresenceConfidence: minPosePresenceConfidence,
          minTrackingConfidence: minTrackingConfidence,
          computeDelegate: computeDelegate)

      // Для still image делегаты video/liveStream не нужны
      return helper
  }


  // MARK: - Detection Methods -

  /**
   Performs pose detection on a still image.
   - Parameter image: The UIImage to perform detection on.
   - Returns: A ResultBundle containing the detection results and inference time, or nil if detection fails.
   */
  func detect(image: UIImage) -> ResultBundle? {
    guard runningMode == .image else {
        print("Error: PoseLandmarkerHelper is not configured for image mode.")
        return nil
    }
    guard let landmarker = self.poseLandmarker else {
        print("Error: Pose Landmarker is not initialized.")
        return nil
    }
    guard let mpImage = try? MPImage(uiImage: image) else {
      print("Error: Failed to create MPImage from UIImage.")
      return nil
    }

    do {
      let startDate = Date()
      let result = try landmarker.detect(image: mpImage)
      let inferenceTime = Date().timeIntervalSince(startDate) * 1000
      // В ResultBundle больше нет size
      return ResultBundle(inferenceTime: inferenceTime, poseLandmarkerResult: result)
    } catch {
      print("Failed to detect pose in image: \(error)")
      // Можно передать ошибку наружу, если нужно
      // liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: error)
      return nil
    }
  }

  /**
   Performs asynchronous pose detection on a sample buffer (live stream mode).
   - Parameters:
     - sampleBuffer: The CMSampleBuffer containing the video frame.
     - orientation: The orientation of the image within the buffer.
     - timeStamps: The timestamp of the frame in milliseconds.
   */
  func detectAsync(
    sampleBuffer: CMSampleBuffer,
    orientation: UIImage.Orientation,
    timeStamps: Int) {

    guard runningMode == .liveStream else {
        print("Error: PoseLandmarkerHelper is not configured for live stream mode.")
        return
    }
    guard let landmarker = self.poseLandmarker else {
        print("Error: Pose Landmarker is not initialized.")
        // Уведомляем об ошибке, если landmarker не создан
        liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: PoseLandmarkerHelperError.landmarkerNotInitialized)
        return
    }

    // Создаем MPImage из буфера
    guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
      print("Error: Failed to create MPImage from CMSampleBuffer.")
      // Уведомляем об ошибке создания кадра
       liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: PoseLandmarkerHelperError.failedToCreateMPImage)
      return
    }

    // НЕ сохраняем currentLiveStreamImage
    // self.currentLiveStreamImage = image

    // Вызываем асинхронную детекцию
    do {
      try landmarker.detectAsync(image: image, timestampInMilliseconds: timeStamps)
    } catch {
      print("Failed to call detectAsync: \(error)")
      // Уведомляем об ошибке вызова детекции
      liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: error)
      // НЕ очищаем currentLiveStreamImage, так как его нет
      // self.currentLiveStreamImage = nil
    }
  }

  /**
   Performs pose detection on a video asset.
   - Parameters:
     - videoAsset: The AVAsset representing the video file.
     - durationInMilliseconds: The total duration of the video segment to process.
     - inferenceIntervalInMilliseconds: The interval (in milliseconds) at which to process frames.
   - Returns: An optional ResultBundle containing aggregated results and average inference time.
   */
  func detect(
    videoAsset: AVAsset,
    durationInMilliseconds: Double,
    inferenceIntervalInMilliseconds: Double) async -> ResultBundle? {

    guard runningMode == .video else {
        print("Error: PoseLandmarkerHelper is not configured for video mode.")
        return nil
    }
     guard let landmarker = self.poseLandmarker else {
        print("Error: Pose Landmarker is not initialized.")
        return nil
    }

    let startDate = Date()
    let assetGenerator = imageGenerator(with: videoAsset)
    let frameCount = Int(durationInMilliseconds / inferenceIntervalInMilliseconds)

    // Уведомляем делегата о начале обработки
    await MainActor.run { // Используем MainActor для вызова UI-связанного делегата
        videoDelegate?.poseLandmarkerHelper(self, willBeginDetection: frameCount)
    }

    // Обрабатываем кадры асинхронно
    let resultsTuple = await detectPoseLandmarksInFramesGenerated(
        by: assetGenerator,
        landmarker: landmarker, // Передаем созданный landmarker
        totalFrameCount: frameCount,
        atIntervalsOf: inferenceIntervalInMilliseconds)

    // Рассчитываем среднее время обработки
    let averageInferenceTime = frameCount > 0 ? (Date().timeIntervalSince(startDate) / Double(frameCount) * 1000) : 0

    return ResultBundle(
      inferenceTime: averageInferenceTime,
      poseLandmarkerResult: resultsTuple.poseLandmarkerResults.first.flatMap { $0 }
    )
  }

  // MARK: - Video Processing Helpers -

  private func imageGenerator(with videoAsset: AVAsset) -> AVAssetImageGenerator {
    let generator = AVAssetImageGenerator(asset: videoAsset)
    generator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 25)
    generator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 25)
    generator.appliesPreferredTrackTransform = true
    return generator
  }

 // Асинхронная функция для обработки кадров видео
 private func detectPoseLandmarksInFramesGenerated(
    by assetGenerator: AVAssetImageGenerator,
    landmarker: PoseLandmarker, // Принимаем landmarker как параметр
    totalFrameCount frameCount: Int,
    atIntervalsOf inferenceIntervalMs: Double) async
  -> (poseLandmarkerResults: [PoseLandmarkerResult?], videoSize: CGSize) {

    var poseLandmarkerResults: [PoseLandmarkerResult?] = []
    var videoSize = CGSize.zero

    for i in 0..<frameCount {
        let timestampMs = Int(inferenceIntervalMs) * i
        let time = CMTime(value: Int64(timestampMs), timescale: 1000)
        var frameImage: CGImage?

        // Получаем кадр асинхронно
        do {
            frameImage = try await assetGenerator.image(at: time).image
        } catch {
            print("Failed to generate image at time \(timestampMs): \(error)")
            poseLandmarkerResults.append(nil) // Добавляем nil, чтобы сохранить порядок
            continue // Пропускаем кадр
        }

        guard let cgImage = frameImage else {
            poseLandmarkerResults.append(nil)
            continue
        }

        // Создаем MPImage
        let uiImage = UIImage(cgImage: cgImage)
        if videoSize == .zero { videoSize = uiImage.size } // Запоминаем размер первого кадра

        guard let mpImage = try? MPImage(uiImage: uiImage) else {
            print("Failed to create MPImage for video frame at time \(timestampMs)")
            poseLandmarkerResults.append(nil)
            continue
        }

        // Выполняем детекцию (синхронно для видеокадра)
        do {
            let result = try landmarker.detect(videoFrame: mpImage, timestampInMilliseconds: timestampMs)
            poseLandmarkerResults.append(result)
             // Уведомляем делегата в главном потоке
            await MainActor.run {
                 videoDelegate?.poseLandmarkerHelper(self, didFinishDetectionOnVideoFrame: i)
            }
        } catch {
            print("Failed to detect pose in video frame at time \(timestampMs): \(error)")
            poseLandmarkerResults.append(nil)
            // Не прерываем цикл, обрабатываем остальные кадры
        }
    } // Конец цикла for

    return (poseLandmarkerResults, videoSize)
  } // Конец detectPoseLandmarksInFramesGenerated

} // Конец класса PoseLandmarkerHelper


// MARK: - PoseLandmarkerLiveStreamDelegate Methods -

extension PoseLandmarkerHelper: PoseLandmarkerLiveStreamDelegate {

  // Этот метод вызывается ИЗНУТРИ MediaPipe SDK после асинхронной детекции
  func poseLandmarker(_ poseLandmarker: PoseLandmarker,
                      didFinishDetection result: PoseLandmarkerResult?,
                      timestampInMilliseconds: Int,
                      error: Error?) {

    // 1. Проверяем наличие ошибки от MediaPipe
    guard error == nil else {
      print("Pose detection error from MediaPipe: \(error!.localizedDescription)")
      // Передаем ошибку нашему внешнему делегату
      liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: error)
      // НЕ очищаем currentLiveStreamImage
      return
    }

    // 2. Проверяем, есть ли результат (может быть nil, если позы не найдены)
    guard let poseResult = result else {
      print("Pose detection finished with no results for timestamp \(timestampInMilliseconds).")
      // Передаем nil результат (без ошибки) нашему делегату
      liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: nil, error: nil)
       // НЕ очищаем currentLiveStreamImage
      return
    }

    // 3. НЕ получаем размер здесь
    /*
     guard let currentFrame = self.currentLiveStreamImage else {
          print("Error: Could not retrieve current MPImage to get frame size.")
          // ... обработка ошибки ...
          return
     }
     let frameSize = currentFrame.imageSize
     self.currentLiveStreamImage = nil
     */

    // 4. Создаем ResultBundle БЕЗ размера
    let resultBundle = ResultBundle(
      inferenceTime: Date().timeIntervalSince1970 * 1000 - Double(timestampInMilliseconds),
      poseLandmarkerResult: poseResult
    )

    // 5. Уведомляем наш внешний делегат (LevelingViewController)
    liveStreamDelegate?.poseLandmarkerHelper(self, didFinishDetection: resultBundle, error: nil)
  }
}

// MARK: - Helper Error Enum -

enum PoseLandmarkerHelperError: Error, LocalizedError {
    case landmarkerNotInitialized
    case failedToCreateMPImage
    case failedToGetImageSize // Можно убрать, если размер получаем в VC

    var errorDescription: String? {
        switch self {
        case .landmarkerNotInitialized:
            return "Pose Landmarker is not initialized."
        case .failedToCreateMPImage:
            return "Failed to create MPImage from input."
        case .failedToGetImageSize:
             return "Failed to retrieve the size of the processed image frame."
        }
    }
}