import Foundation
import Combine
import FirebaseFirestore // Добавляем импорт Firestore для ListenerRegistration

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
    
    // Состояние для ответа на комментарий
    @Published var replyingToComment: Comment? = nil // Comment, на который отвечаем
    @Published var isInReplyMode: Bool = false // Режим ответа активен

    private var cancellables = Set<AnyCancellable>()
    private var commentsListener: ListenerRegistration? // Свойство для хранения подписки

    // MARK: - Initialization
    init(postId: String,
         postService: PostServiceProtocol = PostService(),
         authService: AuthServiceProtocol = AuthService()
         /*, userProfileService: UserProfileServiceProtocol = UserProfileService() */ ) {
        self.postId = postId
        self.postService = postService
        self.authService = authService
        // self.userProfileService = userProfileService
        print("CommentsViewModel initialized for postId: \(postId). Starting listener.")
        listenForComments() // Запускаем прослушивание при инициализации
    }

    // MARK: - Deinitialization
    deinit {
        print("CommentsViewModel deinit for postId: \(postId). Removing listener.")
        commentsListener?.remove() // Отписываемся от обновлений при уничтожении VM
    }

    // MARK: - Public Methods

    // Удаляем старый fetchComments, т.к. теперь используем listener
    /*
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
    */

    // Новый метод для установки listener'а
    private func listenForComments() {
        guard commentsListener == nil else { // Убеждаемся, что listener еще не установлен
            print("CommentsViewModel: Listener already active for postId: \(postId).")
            return
        }
        
        isLoading = true // Показываем индикатор загрузки в начале
        errorMessage = nil
        print("CommentsViewModel: Setting up comments listener for postId: \(postId)")

        // Вызываем новый метод сервиса
        commentsListener = postService.listenForComments(for: postId) { [weak self] result in
            // Мы уже @MainActor, DispatchQueue.main.async не нужен
            guard let self = self else { return }
            
            // Скрываем индикатор после получения первого ответа (успешного или нет)
            if self.isLoading { self.isLoading = false }

            switch result {
            case .success(let updatedComments):
                self.comments = updatedComments
                self.errorMessage = nil // Сбрасываем ошибку при успехе
                print("CommentsViewModel: Received \(updatedComments.count) comments update.")
                
                // Если мы отвечаем на комментарий, который был удален, сбрасываем режим ответа
                if let replyingToComment = self.replyingToComment,
                   !updatedComments.contains(where: { $0.id == replyingToComment.id }) {
                    self.cancelReply()
                }
            case .failure(let error):
                // Показываем ошибку, но не перезаписываем комментарии (оставляем старые, если были)
                self.errorMessage = "Ошибка получения обновлений: \(error.localizedDescription)"
                print("CommentsViewModel Error listening for comments: \(error.localizedDescription)")
                // Можно добавить логику повторной попытки или более детальной обработки ошибки
            }
        }
    }
    
    // Метод для начала ответа на комментарий
    func startReplyTo(comment: Comment) {
        replyingToComment = comment
        isInReplyMode = true
        print("CommentsViewModel: Started replying to comment \(comment.id ?? "unknown")")
    }
    
    // Метод для отмены ответа
    func cancelReply() {
        replyingToComment = nil
        isInReplyMode = false
        print("CommentsViewModel: Reply mode canceled")
    }

    // Обновляем метод добавления комментария для поддержки ответов
    func addComment(text: String) {
        guard !isSending else { return } // Не отправляем, если уже идет отправка
        guard authService.currentUserID != nil else {
            errorMessage = "Необходимо войти для добавления комментария."
            return
        }

        let parentCommentId = replyingToComment?.id
        let replyModeText = parentCommentId != nil ? "как ответ на комментарий \(parentCommentId!)" : ""
        print("CommentsViewModel: Attempting to add comment: '\(text)' \(replyModeText)")
        
        isSending = true
        errorMessage = nil

        // Используем обновленный метод сервиса с parentCommentId
        postService.addComment(text, for: postId, parentCommentId: parentCommentId) { [weak self] result in
            // Мы уже @MainActor
            guard let self = self else { return }
            self.isSending = false

            switch result {
            case .success(let newComment):
                // Комментарий УЖЕ ДОЛЖЕН прийти через listener.
                // Локальное добавление больше не нужно, чтобы избежать дублирования.
                // self.comments.append(newComment) // <--- УДАЛЯЕМ ЭТУ СТРОКУ
                print("✅ CommentsViewModel: Comment add request successful. ID: \(newComment.id ?? "nil"). Listener should update the list.")
                
                // Сбрасываем режим ответа после успешной отправки
                if self.isInReplyMode {
                    self.cancelReply()
                }
                
                // TODO: Прокрутить таблицу к новому комментарию? (логика остается актуальной, но выполняется после обновления от listener'а)
            case .failure(let error):
                self.errorMessage = "Ошибка отправки комментария: \(error.localizedDescription)"
                print("❌ CommentsViewModel Error adding comment: \(error.localizedDescription)")
            }
        }
    }
}
