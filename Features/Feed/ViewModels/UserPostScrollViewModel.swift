import Foundation
import Combine
import FirebaseFirestore

class UserPostScrollViewModel {

    // MARK: - Dependencies
    let userID: String
    private let postService: PostServiceProtocol
    // Понадобится для лайков
    private let authService: AuthServiceProtocol

    // MARK: - Published Properties
    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading: Bool = false // Для первой загрузки
    @Published private(set) var isFetchingMore: Bool = false // Для пагинации
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var canLoadMore: Bool = true // Флаг, что есть еще посты для загрузки

    // MARK: - Pagination State
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    private let postsLimit = 10 // Количество постов на страницу

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(userID: String,
         initialPosts: [Post], // Принимаем начальные посты
         initialSnapshot: DocumentSnapshot?, // И последний snapshot от предыдущей загрузки
         postService: PostServiceProtocol = PostService(),
         authService: AuthServiceProtocol = AuthService()) {
        self.userID = userID
        self.posts = initialPosts // Устанавливаем начальные посты
        self.lastDocumentSnapshot = initialSnapshot // Устанавливаем snapshot
        self.postService = postService
        self.authService = authService
        
        // Проверяем, можно ли загрузить больше сразу
        self.canLoadMore = initialPosts.count >= postsLimit
        
        print("UserPostScrollViewModel initialized for userID: \(userID) with \(initialPosts.count) initial posts.")
    }

    // MARK: - Data Fetching
    func fetchMorePosts() {
        // Загружаем еще, только если не идет загрузка и есть что загружать
        guard !isLoading && !isFetchingMore && canLoadMore else {
            if !canLoadMore { print("UserPostScrollViewModel: No more posts to load for user \(userID).") }
            return
        }

        print("UserPostScrollViewModel: Fetching more posts for user \(userID)...")
        isFetchingMore = true
        errorMessage = nil

        postService.fetchPosts(forUserID: userID, limit: postsLimit, startingAfter: lastDocumentSnapshot) { [weak self] result in
             DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingMore = false

                switch result {
                case .success(let resultData):
                    let newPosts = resultData.posts
                    self.lastDocumentSnapshot = resultData.lastSnapshot

                    if newPosts.count < self.postsLimit {
                        self.canLoadMore = false
                    }
                    
                    // Добавляем только уникальные посты (на всякий случай)
                    let existingIDs = Set(self.posts.compactMap { $0.id })
                    let uniqueNewPosts = newPosts.filter { !existingIDs.contains($0.id ?? "") }
                    self.posts.append(contentsOf: uniqueNewPosts)

                    

                case .failure(let error):
                    print("UserPostScrollViewModel Error fetching more posts: \(error.localizedDescription)")
                    self.errorMessage = "Не удалось загрузить больше постов: \(error.localizedDescription)"
                    // Можно разрешить попробовать снова
                    // self.canLoadMore = true
                }
            }
        }
    }

    // MARK: - Liking Posts (Аналогично FeedViewModel)
    func toggleLike(for postID: String) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            print("UserPostScrollViewModel Error: Post with ID \(postID) not found for liking.")
            return
        }

        var post = posts[index]
        let originalLikeState = post.isLiked
        let originalLikeCount = post.likeCount

        post.isLiked.toggle()
        post.likeCount += post.isLiked ? 1 : -1
        post.likeCount = max(0, post.likeCount)

        posts[index] = post // Обновляем массив, @Published сработает

        let completion: (Error?) -> Void = { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Проверяем, что индекс все еще валиден (массив мог измениться)
                guard self.posts.indices.contains(index) else { return }
                
                if let error = error {
                    print("UserPostScrollViewModel Error (Toggle Like): \(error.localizedDescription)")
                    // Откатываем
                    self.posts[index].isLiked = originalLikeState
                    self.posts[index].likeCount = originalLikeCount
                    self.errorMessage = "Failed to update like status: \(error.localizedDescription)"
                } else {
                    print("UserPostScrollViewModel: Like status toggled successfully for post \(postID)")
                }
            }
        }

        if post.isLiked {
            postService.likePost(postID: postID, completion: completion)
        } else {
            postService.unlikePost(postID: postID, completion: completion)
        }
    }
}
