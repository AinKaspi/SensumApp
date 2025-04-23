import UIKit
import Combine

// Добавляем имя уведомления
extension Notification.Name {
    static let didCreateNewPost = Notification.Name("didCreateNewPostNotification")
}

/// View model responsible for managing the state and logic of the Create Post screen.
final class CreatePostViewModel {

    // MARK: - Properties

    let selectedImage: UIImage
    @Published var caption: String = ""
    @Published var isSharing: Bool = false // To indicate loading state for the share button
    @Published var errorMessage: String? // To show potential errors to the user

    private let storageService: StorageServiceProtocol
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        selectedImage: UIImage,
        storageService: StorageServiceProtocol = StorageService(),
        postService: PostServiceProtocol = PostService()
    ) {
        self.selectedImage = selectedImage
        self.storageService = storageService
        self.postService = postService
    }

    // MARK: - Public Methods

    /// Uploads the selected image to storage and creates a new post document in Firestore using Combine Futures.
    /// - Parameter completion: A closure called upon completion, containing an optional error.
    func sharePost(completion: @escaping (Error?) -> Void) {
        guard !caption.isEmpty else {
            errorMessage = "Caption cannot be empty."
            completion(nil)
            return
        }

        isSharing = true
        errorMessage = nil

        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CreatePostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel was deallocated before image upload"])))
                return
            }
            _ = self.storageService.uploadImage(self.selectedImage, directory: "posts") { result in
                promise(result)
            }
        }
        .flatMap { [weak self] imageURL -> AnyPublisher<Void, Error> in
            guard let self = self else {
                return Fail(error: NSError(domain: "CreatePostViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "ViewModel was deallocated before post creation"]))
                    .eraseToAnyPublisher()
            }

            return Future<Void, Error> { promise in
                self.postService.createPost(imageURL: imageURL.absoluteString, caption: self.caption) { error in
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
                print("Post shared successfully via Combine chain.")
                // ---> Отправляем уведомление об успешном создании поста <---
                NotificationCenter.default.post(name: .didCreateNewPost, object: nil)
                completion(nil)
            case .failure(let error):
                print("Error sharing post via Combine chain: \(error.localizedDescription)")
                self.errorMessage = "Failed to share post. Please try again. (Error: \(error.localizedDescription))"
                completion(error)
            }
        } receiveValue: { _ in
        }
        .store(in: &cancellables)
    }
}