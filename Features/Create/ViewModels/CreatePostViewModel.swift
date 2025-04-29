import UIKit
import Combine
// import AVFoundation // Убрали, т.к. видео не поддерживается

/// Enum defining aspect ratios for posts
enum PostAspectRatio: String, CaseIterable {
    case square = "1:1"     // Квадрат
    case portrait = "4:5"   // Вертикальный
    case landscape = "1.91:1" // Горизонтальный (Instagram Landscape)
    
    /// String representation for UI display
    var stringValue: String {
        return self.rawValue
    }
    
    /// Actual CGFloat ratio value (height / width)
    var ratio: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .portrait:
            return 5.0 / 4.0
        case .landscape:
            return 1.0 / 1.91 // Height / Width для 1.91:1
        }
    }
}

extension Notification.Name {
    static let didCreateNewPost = Notification.Name("didCreateNewPostNotification")
}

/// Структура для хранения редактируемого медиа-элемента
struct EditableMediaItem: Identifiable {
    let id = UUID() // Уникальный ID для SwiftUI/Combine
    let originalImage: UIImage
    var finalImage: UIImage? // Финальное (обрезанное) изображение для загрузки
    var selectedAspectRatio: PostAspectRatio = .square // Соотношение сторон для этого элемента
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
                // Начальное соотношение можно оставить .square или определить по изображению
                return EditableMediaItem(originalImage: img, selectedAspectRatio: .square) 
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

    // MARK: - Public Methods
    
    /// Обновляет выбранное соотношение сторон для ТЕКУЩЕГО редактируемого элемента
    func updateAspectRatioForCurrentItem(_ aspectRatio: PostAspectRatio) {
        guard selectedMediaIndex >= 0 && selectedMediaIndex < editableMedia.count else { return }
        editableMedia[selectedMediaIndex].selectedAspectRatio = aspectRatio
        // Сбрасываем finalImage и параметры ручного кропа, т.к. соотношение изменилось
        editableMedia[selectedMediaIndex].finalImage = nil 
        resetManualCropParametersForCurrentItem() // Вызываем сброс параметров
        print("🔄 Updated aspect ratio for index \(selectedMediaIndex) to \(aspectRatio.stringValue), reset crop parameters.")
    }
    
    /// Сохраняет параметры ручного кропа для текущего элемента
    func setManualCropParametersForCurrentItem(zoomScale: CGFloat, contentOffset: CGPoint) {
        guard selectedMediaIndex >= 0 && selectedMediaIndex < editableMedia.count else { return }
        editableMedia[selectedMediaIndex].manualZoomScale = zoomScale
        editableMedia[selectedMediaIndex].manualContentOffset = contentOffset
        // Сбрасываем finalImage, т.к. кроп изменился
        editableMedia[selectedMediaIndex].finalImage = nil 
        print("💾 VM: Saved manual crop parameters for index \(selectedMediaIndex)")
    }

    /// Сбрасывает параметры ручного кропа для текущего элемента
    func resetManualCropParametersForCurrentItem() {
        guard selectedMediaIndex >= 0 && selectedMediaIndex < editableMedia.count else { return }
        editableMedia[selectedMediaIndex].manualZoomScale = nil
        editableMedia[selectedMediaIndex].manualContentOffset = nil
        // Сбрасываем finalImage
        editableMedia[selectedMediaIndex].finalImage = nil 
        print("🗑️ VM: Reset manual crop parameters for index \(selectedMediaIndex)")
    }

    /// Возвращает текущее выбранное соотношение для UI
    var currentSelectedAspectRatio: PostAspectRatio {
        guard selectedMediaIndex >= 0 && selectedMediaIndex < editableMedia.count else { return .square }
        return editableMedia[selectedMediaIndex].selectedAspectRatio
    }

    /// Uploads the selected media to storage and creates a new post document in Firestore.
    /// - Parameter completion: A closure called upon completion, containing an optional error.
    func sharePost(completion: @escaping (Error?) -> Void) {
        guard !editableMedia.isEmpty else {
            errorMessage = "Please select at least one image."
            completion(nil)
            return
        }

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
            completion(completionError) // Передаем оригинальную ошибку или nil
            return
         }
         
        print("✅ Generated \(finalImagesToUpload.count) final images for upload using manual/auto crop.")
        
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
        
        // 3. Генерируем 9:16 миниатюру для gridThumbnailURL (из ПЕРВОГО кропнутого изображения)
        guard let firstFinalImage = finalImagesToUpload.first else {
            errorMessage = "Cannot generate thumbnail, no final images available."
            isSharing = false
            completion(NSError(domain: "CreatePostViewModel", code: -11, userInfo: [NSLocalizedDescriptionKey: "First final image is missing"])) 
            return
        }
        
        let thumbnailImage = autoCropImage(firstFinalImage, withTargetAspectRatio: 9.0 / 16.0) // Используем автокроп для миниатюры
        guard let thumb = thumbnailImage else {
            errorMessage = "Failed to generate 9:16 thumbnail."
            isSharing = false
            completion(NSError(domain: "CreatePostViewModel", code: -12, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"])) 
            return
        }
        print("🖼️ CreatePostViewModel: Сгенерирована миниатюра 9:16 из первого кропнутого изображения.")
        
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
                let feedAspectRatio = self.editableMedia.first?.selectedAspectRatio.rawValue ?? PostAspectRatio.square.rawValue

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
                            print("✅ CreatePostViewModel: Пост (v2) успешно создан через новый метод сервиса")
                            promise(.success(()))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] completionResult in
                guard let self = self else { return }
                self.isSharing = false

                switch completionResult {
                case .finished:
                    print("Post shared successfully.")
                    NotificationCenter.default.post(name: .didCreateNewPost, object: nil)
                    completion(nil)
                case .failure(let error):
                    print("Error sharing post: \(error.localizedDescription)")
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
    private func generateCroppedImage(for item: EditableMediaItem) -> UIImage? {
        let originalImage = item.originalImage
        let targetAspectRatio = item.selectedAspectRatio.ratio // Соотношение для рамки
        
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
    
    // НОВЫЙ хелпер: Кроп изображения по заданным параметрам масштаба и смещения
    private func cropImageManually(originalImage: UIImage, targetAspectRatio: CGFloat, zoomScale: CGFloat, contentOffset: CGPoint) -> UIImage? {
        
        let originalSize = originalImage.size
        
        // 1. Определяем размер видимой области (crop box) на основе targetAspectRatio
        // Это аналог bounds ImageCropView
        // Предполагаем, что crop box вписывается в какой-то максимальный размер (например, ширину экрана, но тут у нас его нет)
        // Для простоты, давайте считать, что crop box имеет ширину, равную ширине картинки при минимальном зуме
        // (т.е. когда картинка максимально вписана в aspect ratio)
        
        var viewBoxWidth: CGFloat
        var viewBoxHeight: CGFloat
        
        if originalSize.width / originalSize.height > targetAspectRatio { // Картинка шире, чем рамка
            viewBoxHeight = originalSize.height
            viewBoxWidth = viewBoxHeight * targetAspectRatio
        } else { // Картинка выше или такая же
            viewBoxWidth = originalSize.width
            viewBoxHeight = viewBoxWidth / targetAspectRatio
        }
        // Эти размеры соответствуют размеру ScrollView в ImageCropView при zoomScale = 1.0 и минимальном содержании
        // Но нам нужен размер видимой области при *текущем* zoomScale. 
        // Логика ImageCropView сложнее, она зависит от layoutSubviews. 
        
        // --- УПРОЩЕННЫЙ ПОДХОД (может быть неточным) ---
        // Попробуем воспроизвести логику из ImageCropView.croppedImage(), зная zoom и offset
        
        // Размер imageView при текущем зуме
        let imageViewWidth = originalSize.width / zoomScale
        let imageViewHeight = originalSize.height / zoomScale
        
        // Размер видимой области (приблизительно, т.к. мы не знаем реальный bounds cropView)
        // Давайте предположим, что видимая область равна размеру картинки, поделенному на зум,
        // но ограниченному соотношением сторон. Это НЕ совсем верно.
        // TODO: Нужен более точный способ расчета видимого прямоугольника, возможно, передавать bounds CropView?
        
        // Возьмем размеры viewBox как размер видимой части
        let visibleRectWidth = viewBoxWidth / zoomScale
        let visibleRectHeight = viewBoxHeight / zoomScale
        
        // Рассчитываем cropRect в координатах оригинального изображения
        let cropX = contentOffset.x * (originalSize.width / imageViewWidth) // scale = original / imageViewSize
        let cropY = contentOffset.y * (originalSize.height / imageViewHeight)
        let cropWidth = visibleRectWidth * (originalSize.width / imageViewWidth)
        let cropHeight = visibleRectHeight * (originalSize.height / imageViewHeight)
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        // Проверка валидности cropRect
        guard cropRect.origin.x >= 0, cropRect.origin.y >= 0,
              cropRect.maxX <= originalSize.width + 0.001, // Допуск на погрешность float
              cropRect.maxY <= originalSize.height + 0.001 else {
            print("⚠️ cropImageManually: Invalid cropRect calculated: \(cropRect) for original size \(originalSize)")
            // Фоллбек на автокроп при невалидном rect
            return autoCropImage(originalImage, withTargetAspectRatio: targetAspectRatio)
        }

        print("📐 Calculated manual cropRect: \(cropRect)")
        
        // Выполняем кроп
        guard let cgImage = originalImage.cgImage?.cropping(to: cropRect) else {
            print("⚠️ cropImageManually: Failed to crop CGImage with rect: \(cropRect)")
            return autoCropImage(originalImage, withTargetAspectRatio: targetAspectRatio) // Фоллбек
        }

        return UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }
    
    // Заменяем старый autoCropImage на новый с другим именем параметра для ясности
    private func autoCropImage(_ image: UIImage, withTargetAspectRatio targetAspectRatio: CGFloat) -> UIImage? {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        var cropWidth: CGFloat
        var cropHeight: CGFloat

        // Рассчитываем целевые размеры для кропа
        if imageWidth / imageHeight > targetAspectRatio { // Исходное изображение шире целевого
            cropHeight = imageHeight
            cropWidth = cropHeight * targetAspectRatio
        } else { // Исходное изображение выше или такое же
            cropWidth = imageWidth
            cropHeight = cropWidth / targetAspectRatio
        }

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