import UIKit
import Combine
// import AVFoundation // Убрали, т.к. видео не поддерживается

/// Enum defining aspect ratios for posts
enum PostAspectRatio: String, CaseIterable {
    case square = "1:1"     // Квадрат
    case portrait = "4:5"   // Вертикальный
    case landscape = "16:9" // Горизонтальный
    
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
            return 9.0 / 16.0
        }
    }
}

extension Notification.Name {
    static let didCreateNewPost = Notification.Name("didCreateNewPostNotification")
}

/// View model responsible for managing the state and logic of the Create Post screen.
final class CreatePostViewModel {

    // MARK: - Properties

    // Используем MediaItem из Core/Models (только .image)
    @Published var selectedMedia: [MediaItem] = []
    @Published var selectedMediaIndex: Int = 0
    @Published var selectedAspectRatio: PostAspectRatio = .square // По умолчанию 1:1

    @Published var caption: String = ""
    @Published var isSharing: Bool = false
    @Published var errorMessage: String?

    private let storageService: StorageServiceProtocol
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    // Обновляем init для приема массива медиа
    init(
        initialMedia: [MediaItem], // Принимаем массив медиа
        storageService: StorageServiceProtocol = StorageService(),
        postService: PostServiceProtocol = PostService()
    ) {
        self.selectedMedia = initialMedia
        self.storageService = storageService
        self.postService = postService

        // Убедимся, что начальный индекс валиден
        if initialMedia.isEmpty {
            self.selectedMediaIndex = -1 // Или другое значение, указывающее на отсутствие выбора
        } else {
            self.selectedMediaIndex = 0
        }
    }

    // MARK: - Public Methods

    /// Uploads the selected media to storage and creates a new post document in Firestore.
    /// - Parameter completion: A closure called upon completion, containing an optional error.
    func sharePost(completion: @escaping (Error?) -> Void) {
        guard !selectedMedia.isEmpty else {
            errorMessage = "Please select at least one image."
            completion(nil)
            return
        }

        guard !caption.isEmpty else {
            errorMessage = "Caption cannot be empty."
            completion(nil)
            return
        }

        isSharing = true
        errorMessage = nil

        // TODO: Реализовать логику загрузки НЕСКОЛЬКИХ медиафайлов.
        // Текущая реализация загружает только ПЕРВЫЙ элемент.
        // Нужно будет:
        // 1. Определить, как загружать видео (возможно, нужна отдельная функция в StorageService).
        // 2. Использовать Combine для параллельной или последовательной загрузки всех медиа.
        // 3. Собрать все URL после загрузки.
        // 4. Обновить PostService для приема массива URL и информации о соотношении сторон.

        guard let firstMedia = selectedMedia.first else {
            // Это не должно произойти из-за проверки selectedMedia.isEmpty выше
            isSharing = false
            completion(NSError(domain: "CreatePostViewModel", code: -3, userInfo: [NSLocalizedDescriptionKey: "No media selected despite check"]))
            return
        }

        // --- ВРЕМЕННАЯ ЛОГИКА: Загрузка только первого изображения ---
        // Извлекаем UIImage из MediaItem.image
        guard case .image(let imageToUpload) = firstMedia else {
            // Этого не должно произойти, так как мы поддерживаем только изображения
            errorMessage = "Invalid media type selected."
            isSharing = false
            completion(NSError(domain: "CreatePostViewModel", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid media type selected (expected image)"]))
            return
        }

        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CreatePostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel was deallocated before media upload"])))
                return
            }
            // Используем временное изображение для загрузки
            _ = self.storageService.uploadImage(imageToUpload, directory: "posts") { result in
                promise(result)
            }
        }
        .flatMap { [weak self] mediaURL -> AnyPublisher<Void, Error> in
            guard let self = self else {
                return Fail(error: NSError(domain: "CreatePostViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "ViewModel was deallocated before post creation"]))
                    .eraseToAnyPublisher()
            }

            // TODO: Обновить PostService.createPost для приема массива URL и aspectRatio
            let mediaURLs = [mediaURL.absoluteString] // Временно только один URL

            return Future<Void, Error> { promise in
                // Передаем временные данные
                self.postService.createPost(imageURL: mediaURLs.first ?? "", caption: self.caption) { error in
                // self.postService.createPost(mediaURLs: mediaURLs, caption: self.caption, aspectRatio: self.selectedAspectRatio) { error in // <- Целевой вызов
                    if let error = error {
                        promise(.failure(error))
                    } else {
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
                print("Post shared successfully (temporary logic).")
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
        // --- КОНЕЦ ВРЕМЕННОЙ ЛОГИКИ ---
    }
}