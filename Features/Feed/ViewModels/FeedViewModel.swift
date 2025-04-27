import Foundation
import Combine
import FirebaseFirestore // Добавляем для DocumentSnapshot

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
    // Новые состояния для пагинации
    @Published var isFetchingMore: Bool = false
    @Published var canLoadMore: Bool = true // Флаг, что есть еще посты для загрузки
    
    // Состояние пагинации
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    private let postsLimit = 10 // Количество постов на страницу
    
    private var cancellables = Set<AnyCancellable>()
    
    init(postService: PostServiceProtocol = PostService()) {
        self.postService = postService
        // Загружаем первую страницу при инициализации
        fetchPosts(refresh: true)
        
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
    
    // Универсальный метод загрузки постов
    func fetchPosts(refresh: Bool = false) {
        // Предотвращаем одновременные запросы
        guard !isLoading && !isFetchingMore else {
            print("FeedViewModel: Already fetching posts.")
            return
        }
        
        // Если это не обновление, а дозагрузка, используем флаг isFetchingMore
        if !refresh {
            isFetchingMore = true
        } else {
            isLoading = true // Показываем основной индикатор при обновлении
            // Сбрасываем состояние пагинации при обновлении
            lastDocumentSnapshot = nil
            canLoadMore = true 
        }
        errorMessage = nil
        
        postService.fetchFeedPosts(limit: postsLimit, startingAfter: refresh ? nil : lastDocumentSnapshot) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Сбрасываем флаги загрузки
                if refresh {
                    self.isLoading = false
                } else {
                    self.isFetchingMore = false
                }

                switch result {
                case .success(let resultData):
                    let newPosts = resultData.posts
                    self.lastDocumentSnapshot = resultData.lastSnapshot
                    
                    // Если постов пришло меньше лимита, значит, больше нет
                    if newPosts.count < self.postsLimit {
                        self.canLoadMore = false
                    }
                    
                    if refresh {
                        // Заменяем массив при обновлении
                        self.feedPosts = newPosts
                        print("FeedViewModel: Refreshed feed with \(newPosts.count) posts.")
                    } else {
                        // Добавляем новые посты при дозагрузке
                        self.feedPosts.append(contentsOf: newPosts)
                        print("FeedViewModel: Fetched \(newPosts.count) more posts. Total: \(self.feedPosts.count)")
                    }
                    
                case .failure(let error):
                     print("FeedViewModel Error (Fetch Feed w/ Paging): \(error.localizedDescription)")
                    self.errorMessage = "Failed to load feed: \(error.localizedDescription)"
                    // Если была ошибка, возможно, стоит разрешить попробовать снова?
                    self.canLoadMore = true 
                }
            }
        }
    }
    
    // Метод для вызова из View при необходимости дозагрузки
    func loadMorePostsIfNeeded() {
        // Загружаем еще, только если не идет загрузка и есть что загружать
        guard !isLoading && !isFetchingMore && canLoadMore else {
            if !canLoadMore { print("FeedViewModel: No more posts to load.") }
            return
        }
        print("FeedViewModel: Requesting more posts...")
        fetchPosts(refresh: false) // Вызываем загрузку НЕ как обновление
    }
    
    // Метод для Pull-to-Refresh
    func refreshFeed() {
        print("FeedViewModel: Refreshing feed (Pull-to-Refresh)...")
        fetchPosts(refresh: true)
    }
    
    // TODO: Добавить методы для пагинации (загрузка старых постов)
    // TODO: Добавить методы для обработки лайков/комментариев
    
    // MARK: - Liking Posts
    
    func toggleLike(for postID: String) {
        // 1. Найти пост в массиве
        guard let index = feedPosts.firstIndex(where: { $0.id == postID }) else {
            print("FeedViewModel Error: Post with ID \(postID) not found for liking.")
            return
        }
        
        // 2. Оптимистично обновить UI
        var post = feedPosts[index]
        let originalLikeState = post.isLiked
        let originalLikeCount = post.likeCount
        
        post.isLiked.toggle()
        post.likeCount += post.isLiked ? 1 : -1
        // Убедимся, что счетчик не уходит ниже нуля
        post.likeCount = max(0, post.likeCount)
        
        feedPosts[index] = post // Обновляем пост в массиве (это вызовет @Published)
        
        // 3. Вызвать сервис
        let completion: (Error?) -> Void = { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("FeedViewModel Error (Toggle Like): \(error.localizedDescription)")
                    // Откатываем изменения при ошибке
                    self.feedPosts[index].isLiked = originalLikeState
                    self.feedPosts[index].likeCount = originalLikeCount
                    // Уведомить пользователя об ошибке?
                    self.errorMessage = "Failed to update like status: \(error.localizedDescription)"
                } else {
                    print("FeedViewModel: Like status toggled successfully for post \(postID)")
                    // Успех, UI уже обновлен оптимистично
                }
            }
        }
        
        if post.isLiked { // Если ПОСЛЕ переключения состояние true, значит, мы лайкнули
            postService.likePost(postID: postID, completion: completion)
        } else { // Иначе - анлайкнули
            postService.unlikePost(postID: postID, completion: completion)
        }
    }
    
    // MARK: - Notification Handling
    
    @objc private func handleNewPostCreated() {
        print("FeedViewModel: Received notification that a new post was created. Refreshing feed.")
        refreshFeed()
    }
} 