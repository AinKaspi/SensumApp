import Foundation
import Combine

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
    }
    
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
        // TODO: Реализовать обновление ленты (pull-to-refresh)
        fetchFeed()
    }
    
    // TODO: Добавить методы для пагинации (загрузка старых постов)
    // TODO: Добавить методы для обработки лайков/комментариев
} 