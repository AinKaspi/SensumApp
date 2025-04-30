import UIKit
import Combine
// import AVFoundation // Убрали, т.к. видео не поддерживается

// Импортируем, чтобы PostAspectRatio был доступен (предполагая модульную структуру)
// Если это не модуль, а просто файлы в одном таргете, импорт не нужен,
// но Xcode должен найти тип. Если ошибка останется, нужно проверить Target Membership.
// import Core // Если 'Core' это модуль
// Пока просто добавим импорт Foundation/UIKit, если PostAspectRatio там не объявлен

// MARK: - PostAspectRatio Enum moved to Core/Models/PostAspectRatio.swift -

/*
/// Enum defining aspect ratios for posts
enum PostAspectRatio: String, CaseIterable {
    case square = "1:1"     // Квадрат
    case portrait = "9:16"   // Вертикальный (старый был 4:5)
    case landscape = "1.91:1" // Горизонтальный (Instagram Landscape)
    
    /// String representation for UI display
    var stringValue: String {
        return self.rawValue
    }
    
    /// Actual CGFloat ratio value (width / height)
    var ratio: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .portrait:
            return 9.0 / 16.0 // ~0.5625
        case .landscape:
            return 1.91 / 1.0 // 1.91
        }
    }
}
*/

extension Notification.Name {
    static let didCreateNewPost = Notification.Name("didCreateNewPostNotification")
}

/// Структура для хранения редактируемого медиа-элемента
struct EditableMediaItem: Identifiable {
    let id = UUID() // Уникальный ID для SwiftUI/Combine
    let originalImage: UIImage
    var finalImage: UIImage? // Финальное (обрезанное) изображение для загрузки
    // Добавляем параметры для ручного кропа
    var manualZoomScale: CGFloat? = nil
    var manualContentOffset: CGPoint? = nil
    // Удаляем старое поле cropRect, оно больше не нужно в таком виде
    // var cropRect: CGRect? // Опционально: прямоугольник кропа (если нужен ручной кроп)
    // TODO: Добавить параметры масштаба/смещения, если cropRect недостаточен
}

/// View model responsible for managing the state and logic of the Create Post screen.
final class CreatePostViewModel {

    // MARK: - Properties

    // Заменяем selectedMedia на массив редактируемых элементов
    // @Published var selectedMedia: [MediaItem] = [] - Старое
    @Published var editableMedia: [EditableMediaItem] = [] 
    
    @Published var selectedMediaIndex: Int = 0
    // Удаляем общее selectedAspectRatio, оно теперь в EditableMediaItem
    // @Published var selectedAspectRatio: PostAspectRatio = .square 

    // Добавляем единое соотношение сторон для всего поста
    @Published var postAspectRatio: PostAspectRatio = .square

    @Published var caption: String = ""
    @Published var isSharing: Bool = false
    @Published var errorMessage: String?

    private let storageService: StorageServiceProtocol
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    // Обновляем init для приема массива медиа
    init(
        initialMedia: [MediaItem], // Принимаем массив оригинальных MediaItem
        storageService: StorageServiceProtocol = StorageService(),
        postService: PostServiceProtocol = PostService()
    ) {
        // Конвертируем [MediaItem] в [EditableMediaItem]
        self.editableMedia = initialMedia.compactMap {
            if case .image(let img) = $0 {
                // Удаляем передачу selectedAspectRatio
                return EditableMediaItem(originalImage: img) // Было: EditableMediaItem(originalImage: img, selectedAspectRatio: .square)
            } else {
                return nil // Пропускаем не-изображения
            }
        }
        self.storageService = storageService
        self.postService = postService

        // Убедимся, что начальный индекс валиден
        if editableMedia.isEmpty {
            self.selectedMediaIndex = -1 // Или другое значение, указывающее на отсутствие выбора
        } else {
            self.selectedMediaIndex = 0
        }
    }

    // Хелпер-инициализатор для PostReviewViewController
    convenience init(initialEditableItems: [EditableMediaItem], postAspectRatio: PostAspectRatio, storageService: StorageServiceProtocol = StorageService(), postService: PostServiceProtocol = PostService()) {
        // Этот init обходит конвертацию из MediaItem
        self.init(initialMedia: [], storageService: storageService, postService: postService) // Вызываем основной init с пустым массивом
        self.editableMedia = initialEditableItems // Устанавливаем переданные items
        self.postAspectRatio = postAspectRatio // Устанавливаем переданный AR
        if !initialEditableItems.isEmpty {
            self.selectedMediaIndex = 0
        } else {
            self.selectedMediaIndex = -1
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods
    
    /// Сохраняет параметры ручного кропа для элемента по индексу
    func setManualCropParameters(for index: Int, zoomScale: CGFloat, contentOffset: CGPoint) {
        guard index >= 0 && index < editableMedia.count else { return }
        editableMedia[index].manualZoomScale = zoomScale
        editableMedia[index].manualContentOffset = contentOffset
        // Сбрасываем finalImage, т.к. кроп изменился
        editableMedia[index].finalImage = nil 
        print("💾 VM: Saved manual crop parameters for index \(index)")
    }

    /// Сбрасывает параметры ручного кропа для элемента по индексу
    func resetManualCropParameters(for index: Int) {
        guard index >= 0 && index < editableMedia.count else { return }
        editableMedia[index].manualZoomScale = nil
        editableMedia[index].manualContentOffset = nil
        // Сбрасываем finalImage
        editableMedia[index].finalImage = nil 
        print("🗑️ VM: Reset manual crop parameters for index \(index)")
    }

    /// Uploads the selected media to storage and creates a new post document in Firestore.
    /// - Parameter completion: A closure called upon completion, containing an optional error.
    func sharePost(completion: @escaping (Error?) -> Void) {
        print("🏁 sharePost: Starting...") // <-- Лог 1: Начало
        guard !editableMedia.isEmpty else {
            errorMessage = "Please select at least one image."
            print("🏁 sharePost: Error - No media selected.") // <-- Лог ошибки
            completion(nil)
            return
        }

        print("🏁 sharePost: Generating final images...") // <-- Лог 2: Перед генерацией
        isSharing = true
        errorMessage = nil

        // --- ОБНОВЛЕННАЯ логика для обработки всех медиа и ручного/авто кропа ---
        
        // 1. Генерируем финальные изображения для загрузки, используя ручной кроп, если доступен
        let finalImagesToUploadResult: Result<[UIImage], Error> = editableMedia.reduce(.success([])) { partialResult, item in
            // Если предыдущий шаг провалился, пропускаем дальше
            guard case .success(var images) = partialResult else { return partialResult }
            
            // Генерируем кропнутое изображение для текущего item
            let croppedImage = generateCroppedImage(for: item)
            
            if let image = croppedImage {
                images.append(image)
                return .success(images)
            } else {
                // Если кроп не удался, возвращаем ошибку
                let error = NSError(domain: "CreatePostViewModel", code: -10, userInfo: [NSLocalizedDescriptionKey: "Failed to crop image for item id: \(item.id)"])
                return .failure(error)
            }
        }
        
        // Проверяем результат генерации изображений
        guard case .success(let finalImagesToUpload) = finalImagesToUploadResult, 
              finalImagesToUpload.count == editableMedia.count else {
            // Прямая обработка ошибки без mapError и getError
            var errorDescription = "Image count mismatch after cropping."
            var completionError: Error? = nil
            
            if case .failure(let error) = finalImagesToUploadResult {
                 errorDescription = error.localizedDescription
                 completionError = error // Сохраняем оригинальную ошибку
                 print("❌ Error generating final images: \(errorDescription)")
            } // Если не .failure, значит .success с несовпадением количества
            
            errorMessage = "Failed to prepare images for upload: \(errorDescription)"
            isSharing = false
            print("🏁 sharePost: Error - Failed to generate final images or count mismatch.") // <-- Лог ошибки
            completion(completionError) // Передаем оригинальную ошибку или nil
            return
         }
         
        print("🏁 sharePost: ✅ Generated \(finalImagesToUpload.count) final images.") // <-- Лог 3: Успешная генерация
         
         // 2. Загружаем все ИЗОБРАЖЕНИЯ параллельно (без изменений)
         let uploadPublishers = finalImagesToUpload.enumerated().map { index, image in
             Future<URL, Error> { [weak self] promise in
                 guard let self = self else {
                     promise(.failure(NSError(domain: "CreatePostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])))
                     return
                 }
                 _ = self.storageService.uploadPostImage(image) { result in
                      print("📱 CreatePostViewModel: Результат загрузки изображения [\(index)]: \(result)")
                      promise(result)
                 }
             }
         }
         
         // 3. Генерируем 9:16 миниатюру для gridThumbnailURL (из ОРИГИНАЛА ПЕРВОГО изображения)
         guard let firstOriginalImage = editableMedia.first?.originalImage else {
             errorMessage = "Cannot generate thumbnail, no final images available."
             isSharing = false
             completion(NSError(domain: "CreatePostViewModel", code: -11, userInfo: [NSLocalizedDescriptionKey: "First original image is missing"])) 
             return
         }
         
         let thumbnailImage = autoCropImage(firstOriginalImage, withTargetAspectRatio: 9.0 / 16.0) // Используем автокроп для миниатюры
         guard let thumb = thumbnailImage else {
             errorMessage = "Failed to generate 9:16 thumbnail."
             isSharing = false
             completion(NSError(domain: "CreatePostViewModel", code: -12, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"])) 
             return
         }
         print("🏁 sharePost: ✅ Generated 9:16 thumbnail from first original image.") // <-- Лог 4: Успешная генерация миниатюры
         
         print("🏁 sharePost: Setting up upload publishers...") // <-- Лог 5: Перед Combine
         let thumbnailUploadPublisher = Future<URL, Error> { [weak self] promise in
             guard let self = self else {
                  promise(.failure(NSError(domain: "CreatePostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])))
                  return
              }
              print("⏳ CreatePostViewModel: Загрузка сгенерированной миниатюры 9:16...")
              _ = self.storageService.uploadPostImage(thumb) { result in // Загружаем 'thumb'
                  print("📱 CreatePostViewModel: Результат загрузки миниатюры 9:16: \(result)")
                  promise(result)
              }
          }

         // 4. Объединяем загрузку основных изображений и миниатюры (без изменений)
         Publishers.Zip(Publishers.MergeMany(uploadPublishers).collect(), thumbnailUploadPublisher)
             .flatMap { [weak self] (uploadedURLs, gridThumbnailURL) -> AnyPublisher<Void, Error> in
                 print("🏁 sharePost: Uploads finished. Preparing DTOs...") // <-- Лог 6: Загрузка завершена
                 guard let self = self else {
                     return Fail(error: NSError(domain: "CreatePostViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])) .eraseToAnyPublisher()
                 }

                 // Формируем MediaItemDTO
                 let mediaItemDTOs = uploadedURLs.map { url in
                     // TODO: Добавить реальные width/height, если они известны
                     MediaItemDTO(type: .image, url: url.absoluteString, width: nil, height: nil) 
                 }
                 
                 guard !mediaItemDTOs.isEmpty else {
                      return Fail(error: NSError(domain: "CreatePostViewModel", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create MediaItemDTOs"])) .eraseToAnyPublisher()
                 }

                 // Определяем feedAspectRatio для всего поста (по первому элементу)
                 print("🏁 sharePost: Creating post in Firestore...") // <-- Лог 7: Перед записью в Firestore
                 let feedAspectRatio = self.postAspectRatio.rawValue

                 return Future<Void, Error> { promise in
                     print("📱 CreatePostViewModel: Создаем пост с aspectRatio: \(feedAspectRatio), gridThumbnail: \(gridThumbnailURL.absoluteString)")
                     
                     // Вызываем НОВЫЙ метод сервиса
                     self.postService.createPost(
                         mediaItems: mediaItemDTOs,
                         feedAspectRatio: feedAspectRatio, // Используем соотношение первого элемента
                         gridThumbnailURL: gridThumbnailURL.absoluteString,
                         caption: self.caption
                     ) { error in
                         if let error = error {
                             print("📱 CreatePostViewModel: Ошибка создания поста (v2): \(error.localizedDescription)")
                             promise(.failure(error))
                         } else {
                             print("🏁 sharePost: ✅ Firestore post created successfully.") // <-- Лог 8: Успешная запись
                             promise(.success(()))
                         }
                     }
                 }
                 .eraseToAnyPublisher()
             }
             .receive(on: DispatchQueue.main) // Убедимся, что sink выполняется на главном потоке
             .sink { [weak self] completionResult in
                 print("🏁 sharePost: Combine pipeline finished with completion: \(completionResult)") // <-- Лог 9: Завершение Combine
                 guard let self = self else { return }
                 self.isSharing = false

                 switch completionResult {
                 case .finished:
                     print("🏁 sharePost: Success completion.")
                     NotificationCenter.default.post(name: .didCreateNewPost, object: nil)
                     completion(nil)
                 case .failure(let error):
                     print("🏁 sharePost: Failure completion: \(error.localizedDescription)")
                     self.errorMessage = "Failed to share post. Please try again. (Error: \(error.localizedDescription))"
                     completion(error)
                 }
             } receiveValue: { _ in
             }
             .store(in: &cancellables)
         // --- КОНЕЦ ОБНОВЛЕННОЙ ЛОГИКИ ---
    }

    // Метод для установки кропнутого изображения (теперь обновляет finalImage)
    func setCroppedImage(_ image: UIImage, forIndex index: Int) {
        guard index >= 0 && index < editableMedia.count else { return }
        // Заменяем/устанавливаем финальное кропнутое изображение
        editableMedia[index].finalImage = image
        print("📸 CreatePostViewModel: Установлено finalImage для индекса \(index)")
    }
    
    // Добавляем хелпер для кропа (аналогичный ImageCropViewController)
    // TODO: Вынести этот метод в утилиту?
    private func autoCropImage(_ image: UIImage, withAspectRatio aspectRatio: CGFloat) -> UIImage {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        var targetWidth: CGFloat
        var targetHeight: CGFloat

        // Рассчитываем целевые размеры для кропа
        if imageWidth / imageHeight > aspectRatio { // Исходное изображение шире целевого
            targetHeight = imageHeight
            targetWidth = targetHeight * aspectRatio
        } else { // Исходное изображение выше или такое же
            targetWidth = imageWidth
            targetHeight = targetWidth / aspectRatio
        }

        // Центрируем область кропа
        let cropX = (imageWidth - targetWidth) / 2
        let cropY = (imageHeight - targetHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: targetWidth, height: targetHeight)

        // Выполняем кроп
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("⚠️ autoCropImage: Не удалось обрезать CGImage")
            return image // Возвращаем оригинал при ошибке
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // НОВЫЙ хелпер для генерации кропнутого изображения с учетом ручных параметров
    // Меняем private на internal (или fileprivate)
    /* private */ func generateCroppedImage(for item: EditableMediaItem) -> UIImage? {
        let originalImage = item.originalImage
        // Используем единое соотношение для поста
        let targetAspectRatio = self.postAspectRatio.ratio
        
        // Если есть параметры ручного кропа, используем их
        if let zoomScale = item.manualZoomScale, let contentOffset = item.manualContentOffset {
            print("✂️ Generating image for item \(item.id) using MANUAL crop: zoom=\(zoomScale), offset=\(contentOffset)")
            return cropImageManually(
                originalImage: originalImage, 
                targetAspectRatio: targetAspectRatio, 
                zoomScale: zoomScale, 
                contentOffset: contentOffset
            )
        } else {
            // Иначе используем автокроп по центру
            print("✂️ Generating image for item \(item.id) using AUTO crop.")
            return autoCropImage(originalImage, withTargetAspectRatio: targetAspectRatio)
        }
    }
    
    // Оставляем private, так как используется только внутри generateCroppedImage
    private func cropImageManually(originalImage: UIImage, targetAspectRatio: CGFloat, zoomScale: CGFloat, contentOffset: CGPoint) -> UIImage? {
        
        print("📐 Cropping manually with AR: \(targetAspectRatio), Zoom: \(zoomScale), Offset: \(contentOffset)")
        let originalSize = originalImage.size
        
        // 1. Оцениваем размер рамки кропа (Crop Frame / ScrollView Bounds)
        // Мы не знаем точные bounds из ImageCropView, но можем оценить их,
        // зная targetAspectRatio и предполагая стандартную ширину экрана.
        // Это не идеально, но должно быть достаточно близко.
        let assumedViewWidth = UIScreen.main.bounds.width // Или другое значение, если известно
        let assumedViewHeight = UIScreen.main.bounds.height // Не используется напрямую, но для контекста
        
        var estimatedCropFrameWidth: CGFloat
        var estimatedCropFrameHeight: CGFloat
        let heightBasedOnWidth = assumedViewWidth / targetAspectRatio

        // Логика из ImageCropView.updateConstraintsForAspectRatio для расчета размера контейнера
        if heightBasedOnWidth <= assumedViewHeight { //TODO: Проверить эту логику, может зависеть от реальной высоты VC
            estimatedCropFrameWidth = assumedViewWidth
            estimatedCropFrameHeight = heightBasedOnWidth
        } else {
            // Если высота ограничивает, расчет другой (нужна высота VC)
            // Пока упростим: предположим, что ширина всегда ограничивает для оценки
            estimatedCropFrameWidth = assumedViewWidth
            estimatedCropFrameHeight = heightBasedOnWidth
             // В реальном сценарии, если высота лимитирует:
             // estimatedCropFrameHeight = assumedViewHeight - top_bottom_margins
             // estimatedCropFrameWidth = estimatedCropFrameHeight * targetAspectRatio
        }
        print("   -> Estimated Crop Frame Size (ScrollView Bounds): (\(estimatedCropFrameWidth), \(estimatedCropFrameHeight))")
        let estimatedCropFrameSize = CGSize(width: estimatedCropFrameWidth, height: estimatedCropFrameHeight)

        // 2. Рассчитываем cropRect в координатах оригинального изображения
        let cropRectX = contentOffset.x / zoomScale
        let cropRectY = contentOffset.y / zoomScale
        // Используем РАЗМЕР РАМКИ НА ЭКРАНЕ, деленный на зум
        let cropRectWidth = estimatedCropFrameSize.width / zoomScale
        let cropRectHeight = estimatedCropFrameSize.height / zoomScale

        let cropRect = CGRect(x: cropRectX, y: cropRectY, width: cropRectWidth, height: cropRectHeight)

        // 3. Проверка валидности cropRect
        let validationRect = CGRect(origin: .zero, size: originalSize)
        // Округляем значения для более надежного сравнения
        let roundedCropRect = CGRect(x: round(cropRect.origin.x * 100) / 100,
                                     y: round(cropRect.origin.y * 100) / 100,
                                     width: round(cropRect.size.width * 100) / 100,
                                     height: round(cropRect.size.height * 100) / 100)

        guard validationRect.contains(roundedCropRect) else {
            print("⚠️ cropImageManually: Invalid cropRect calculated: \(roundedCropRect) for original size \(originalSize)")
            // Фоллбек на автокроп при невалидном rect
            return autoCropImage(originalImage, withTargetAspectRatio: targetAspectRatio)
        }

        print("📐 Calculated manual cropRect (validated): \(roundedCropRect)")
        
        // 4. Выполняем кроп
        guard let cgImage = originalImage.cgImage?.cropping(to: roundedCropRect) else {
            print("⚠️ cropImageManually: Failed to crop CGImage with rect: \(roundedCropRect)")
            return autoCropImage(originalImage, withTargetAspectRatio: targetAspectRatio) // Фоллбек
        }

        return UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }
    
    // Заменяем старый autoCropImage на новый с другим именем параметра для ясности
    // Оставляем private, так как используется только внутри generateCroppedImage и thumbnail генерации
    private func autoCropImage(_ image: UIImage, withTargetAspectRatio targetAspectRatio: CGFloat) -> UIImage? {
        
        print("📐 Cropping automatically with AR: \(targetAspectRatio)")
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        var cropWidth: CGFloat
        var cropHeight: CGFloat

        // Рассчитываем целевые размеры для кропа
        let imageRatioWH = imageWidth / imageHeight // Соотношение изображения W/H
        let targetRatioWH = 1.0 / targetAspectRatio // Целевое соотношение W/H
        
        print("    Image Ratio (W/H): \(imageRatioWH)")
        print("    Target Ratio (W/H): \(targetRatioWH)")

        // Сравниваем соотношения W/H
        if imageRatioWH > targetRatioWH {
            // Изображение шире целевого (W/H). Сохраняем высоту, обрезаем ширину.
            print("    -> Image is wider than target.")
            cropHeight = imageHeight
            cropWidth = cropHeight / targetAspectRatio // Width = Height / (H/W)
        } else {
            // Изображение выше или такое же как целевое (W/H). Сохраняем ширину, обрезаем высоту.
            print("    -> Image is taller or same as target.")
            cropWidth = imageWidth
            cropHeight = cropWidth * targetAspectRatio // Height = Width * (H/W)
        }
        
        print("    Calculated Crop Size (W, H): (\(cropWidth), \(cropHeight))")

        // Центрируем область кропа
        let cropX = (imageWidth - cropWidth) / 2
        let cropY = (imageHeight - cropHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

        // Выполняем кроп
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("⚠️ autoCropImage: Не удалось обрезать CGImage")
            return nil // Возвращаем nil при ошибке
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}