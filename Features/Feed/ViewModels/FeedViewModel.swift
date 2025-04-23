import Foundation
import Combine

// Добавляем имя уведомления (если оно еще не глобально)
// extension Notification.Name {
//    static let didCreateNewPost = Notification.Name("didCreateNewPostNotification")
// }

class FeedViewModel {
    
    // Зависимости
    private let postService: PostServiceProtocol
    // TODO: Добавить сервис для "сторис"/пользователей
    
    // Состояния для UI
    @Published var feedPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    // TODO: Добавить @Published для данных "сторис"
    
    private var cancellables = Set<AnyCancellable>()
    
    init(postService: PostServiceProtocol = PostService()) {
        self.postService = postService
        fetchFeed()
        
        // ---> Подписываемся на уведомление о создании нового поста <---
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewPostCreated),
            name: .didCreateNewPost, // Используем имя, определенное ранее
            object: nil)
    }
    
    deinit {
        // ---> Отписываемся от уведомлений <---
        NotificationCenter.default.removeObserver(self, name: .didCreateNewPost, object: nil)
        print("FeedViewModel deinitialized and observer removed.")
    }
    
    // MARK: - Data Fetching
    
    func fetchFeed() {
        isLoading = true
        errorMessage = nil
        
        // Пока просто загружаем последние N постов
        postService.fetchFeedPosts(limit: 20) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let posts):
                    print("FeedViewModel: Fetched \(posts.count) posts for feed.")
                    self?.feedPosts = posts
                case .failure(let error):
                     print("FeedViewModel Error (Fetch Feed): \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load feed: \(error.localizedDescription)"
                }
            }
        }
        
        // TODO: Загрузить данные для "сторис"
    }
    
    func refreshFeed() {
        print("FeedViewModel: Refreshing feed...")
        fetchFeed()
    }
    
    // TODO: Добавить методы для пагинации (загрузка старых постов)
    // TODO: Добавить методы для обработки лайков/комментариев
    
    // MARK: - Notification Handling
    
    // ---> Метод для обработки уведомления <---
    @objc private func handleNewPostCreated() {
        print("FeedViewModel: Received notification that a new post was created. Refreshing feed.")
        refreshFeed()
    }
} 