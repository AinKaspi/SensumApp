import Foundation
import Combine

@MainActor // Указываем, что класс будет работать в главном потоке
class CommentsViewModel {

    // MARK: - Dependencies
    let postId: String
    private let postService: PostServiceProtocol
    private let authService: AuthServiceProtocol
    // Добавляем UserProfileService для получения информации о текущем пользователе
    // (хотя PostService теперь сам ее получает для денормализации при добавлении)
    // private let userProfileService: UserProfileServiceProtocol

    // MARK: - Published Properties
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSending: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(postId: String,
         postService: PostServiceProtocol = PostService(),
         authService: AuthServiceProtocol = AuthService()
         /*, userProfileService: UserProfileServiceProtocol = UserProfileService() */ ) {
        self.postId = postId
        self.postService = postService
        self.authService = authService
        // self.userProfileService = userProfileService
        print("CommentsViewModel initialized for postId: \(postId)")
    }

    // MARK: - Public Methods

    func fetchComments() {
        guard !isLoading else { return } // Не загружаем, если уже идет загрузка

        print("CommentsViewModel: Fetching comments for postId: \(postId)")
        isLoading = true
        errorMessage = nil

        postService.fetchComments(for: postId) { [weak self] result in
            // Убедимся, что обновляем UI в главном потоке (хотя класс помечен @MainActor)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let fetchedComments):
                    self.comments = fetchedComments
                    print("CommentsViewModel: Fetched \(fetchedComments.count) comments.")
                case .failure(let error):
                    self.errorMessage = "Ошибка загрузки комментариев: \(error.localizedDescription)"
                    print("CommentsViewModel Error fetching comments: \(error.localizedDescription)")
                }
            }
        }
    }

    func addComment(text: String) {
        guard !isSending else { return } // Не отправляем, если уже идет отправка
        guard authService.currentUserID != nil else {
            errorMessage = "Необходимо войти для добавления комментария."
            return
        }

        print("CommentsViewModel: Attempting to add comment: '\(text)'")
        isSending = true
        errorMessage = nil

        postService.addComment(text, for: postId) { [weak self] error in
             DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSending = false
                if let error = error {
                    self.errorMessage = "Ошибка отправки комментария: \(error.localizedDescription)"
                    print("CommentsViewModel Error adding comment: \(error.localizedDescription)")
                } else {
                    print("CommentsViewModel: Comment added successfully. Re-fetching comments...")
                    // Перезагружаем комментарии, чтобы увидеть добавленный
                    // В идеале, addComment мог бы возвращать созданный коммент, чтобы не перезагружать все
                    self.fetchComments()
                }
            }
        }
    }
}
