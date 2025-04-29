import Foundation
import Combine
import FirebaseFirestore

class UserProfileFeedViewModel {
    
    // Входные данные
    let userID: String
    let isCurrentUser: Bool
    
    // Зависимости
    private let userProfileService: UserProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let followService: FollowServiceProtocol
    private let progressService: ProgressServiceProtocol
    
    // Состояния для UI
    @Published var userProfile: User? = nil
    @Published var userPosts: [Post] = []
    @Published var totalLikes: Int? = nil // TODO: Реализовать получение этого значения
    @Published var progressData: ProgressData? = nil
    @Published var isFollowing: Bool = false // Только если !isCurrentUser
    @Published var isLoadingProfile: Bool = false
    @Published var isLoadingProgress: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var isLastPageReached: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    private let postsPerPage: Int = 18
    
    init(userID: String, 
         isCurrentUser: Bool,
         userProfileService: UserProfileServiceProtocol = UserProfileService(), 
         postService: PostServiceProtocol = PostService(),
         followService: FollowServiceProtocol = FollowService(),
         progressService: ProgressServiceProtocol) {
        
        self.userID = userID
        self.isCurrentUser = isCurrentUser
        self.userProfileService = userProfileService
        self.postService = postService
        self.followService = followService
        self.progressService = progressService
        
        fetchAllUserData()
        
        // Проверяем статус подписки, только если это профиль другого пользователя
        if !isCurrentUser {
            checkFollowingStatus()
        }
        
        // Подписываемся на уведомление о создании нового поста, но только если
        // это профиль текущего пользователя (для других профилей не обновляем автоматически)
        if isCurrentUser {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleNewPostCreated),
                name: .didCreateNewPost,
                object: nil
            )
            print("📣 UserProfileFeedVM: Подписались на уведомления о новых постах")
        }
    }
    
    deinit {
        // Отписываемся от уведомлений
        NotificationCenter.default.removeObserver(self, name: .didCreateNewPost, object: nil)
        print("📣 UserProfileFeedVM: Отписались от уведомлений при деинициализации")
    }
    
    // MARK: - Data Fetching
    
    func fetchAllUserData() {
        isLoadingProfile = true
        isLoadingProgress = true
        isLoadingPosts = true
        errorMessage = nil
        print("UserProfileFeedVM: Fetching all data for userID: \(userID)")
        
        let group = DispatchGroup()
        var fetchError: Error? = nil

        // --- Загрузка Профиля (User) ---
        group.enter()
        userProfileService.fetchUserProfile(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingProfile = false
                switch result {
                case .success(let user):
                    self?.userProfile = user
                case .failure(let error):
                    print("UserProfileFeedVM Error (Fetch User): \(error.localizedDescription)")
                    fetchError = error
                }
                group.leave()
            }
        }

        // --- Загрузка Прогресса (ProgressData) ---
        group.enter()
        progressService.fetchProgressData(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingProgress = false
                switch result {
                case .success(let progress):
                    self?.progressData = progress
                case .failure(let error):
                    print("UserProfileFeedVM Error (Fetch Progress): \(error.localizedDescription)")
                    // Не перезаписываем ошибку профиля, если она уже есть
                    if fetchError == nil { fetchError = error }
                }
                 group.leave()
            }
        }
        
        // --- Загрузка Постов --- 
        group.enter()
        print("🟢 UserProfileFeedVM: Начинаем загрузку постов для пользователя: \(userID)")
        postService.fetchPosts(forUserID: userID, limit: 18, startingAfter: nil) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingPosts = false
                switch result {
                case .success(let resultData):
                    let posts = resultData.posts
                    self?.userPosts = posts
                case .failure(let error):
                     print("❌ UserProfileFeedVM Error (Fetch Posts): \(error.localizedDescription)")
                    if fetchError == nil { fetchError = error }
                }
                group.leave()
            }
        }
        
        // --- Обработка результатов --- 
        group.notify(queue: .main) { [weak self] in
            if let error = fetchError {
                self?.errorMessage = "Failed to load profile data: \(error.localizedDescription)"
                
            } else {
               
                self?.errorMessage = nil
            }
        }
    }
    
    func checkFollowingStatus() {
        guard !isCurrentUser else { return } // Нет смысла проверять для себя
        
        followService.checkIfFollowing(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isFollowingStatus):
                    self?.isFollowing = isFollowingStatus
                case .failure(let error):
                    print("UserProfileFeedViewModel Error (Check Following): \(error.localizedDescription)")
                    // Можно показать ошибку?
                }
            }
        }
    }
    
    // MARK: - Actions
    
    func followButtonTapped() {
        guard !isCurrentUser else { return }
        
        // Сохраняем текущее состояние и счетчик для оптимистичного обновления
        let wasFollowing = isFollowing
        let currentFollowerCount = userProfile?.followerCount ?? 0
        let optimisticFollowerCount = wasFollowing ? max(0, currentFollowerCount - 1) : currentFollowerCount + 1
        
        // Оптимистично обновляем UI
        self.isFollowing.toggle()
        self.userProfile?.followerCount = optimisticFollowerCount // Обновляем локально
        
        let actionCompletion: (Error?) -> Void = { [weak self] error in
             DispatchQueue.main.async {
                if let error = error {
                     print("UserProfileFeedViewModel Error (Follow/Unfollow): \(error.localizedDescription)")
                     // Откатываем изменения UI при ошибке
                     self?.isFollowing = wasFollowing
                     self?.userProfile?.followerCount = currentFollowerCount
                     self?.errorMessage = "Failed to update follow status: \(error.localizedDescription)"
                 } else {
                     // Успех. Можно дополнительно перезагрузить счетчики с сервера,
                     // если логика follow/unfollow на сервере их возвращает или обновляет.
                     // В данном случае UserProfileService не обновляет User, 
                     // FollowService обновляет счетчики в двух документах User.
                     // Поэтому для точности можно перезагрузить профиль.
                     // self?.fetchUserProfileData() 
                     print("UserProfileFeedVM: Follow status updated successfully.")
                 }
             }
        }
        
        if wasFollowing {
            print("Attempting to unfollow user: \(userID)")
            followService.unfollow(userIDToUnfollow: userID, completion: actionCompletion)
        } else {
            print("Attempting to follow user: \(userID)")
            followService.follow(userIDToFollow: userID, completion: actionCompletion)
        }
    }
    
    func messageButtonTapped() {
        guard !isCurrentUser else { return }
        print("Message button tapped for user: \(userID)")
        // TODO: Передать координатору запрос на открытие чата
        // coordinatorDelegate?.didRequestMessage(userID: userID)
    }
    
    func editProfileButtonTapped() {
        guard isCurrentUser else { return }
        print("Edit profile button tapped")
        // TODO: Передать координатору запрос на открытие экрана редактирования
        // coordinatorDelegate?.didRequestEditProfile()
    }
    
    // MARK: - Notification Handling
    
    @objc private func handleNewPostCreated() {
        print("📣 UserProfileFeedVM: Получено уведомление о новом посте. Обновляем данные профиля.")
        fetchAllUserData()
    }
    
    // Добавляем метод для загрузки только постов, с возможностью принудительного обновления
    func fetchPosts(forceReload: Bool = false) {
        // Устанавливаем флаг загрузки
        isLoadingPosts = true
        
        // Если это принудительное обновление, сбрасываем состояние пагинации
        if forceReload {
            lastDocumentSnapshot = nil
            isLastPageReached = false
        }
        
        print("🟢 UserProfileFeedVM: Начинаем загрузку постов для пользователя: \(userID)" + (forceReload ? " (принудительное обновление)" : ""))
        
        // Вызываем сервис для загрузки постов
        postService.fetchPosts(forUserID: userID, limit: postsPerPage, startingAfter: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoadingPosts = false
                
                switch result {
                case .success(let resultData):
                    let posts = resultData.posts
                    print("✅ UserProfileFeedVM: Успешно загружено \(posts.count) постов для пользователя \(self.userID)")
                    self.userPosts = posts
                    
                    // Сохраняем последний документ для пагинации
                    self.lastDocumentSnapshot = resultData.lastSnapshot
                    
                    // Проверяем, достигнут ли конец страницы
                    if posts.count < self.postsPerPage {
                        self.isLastPageReached = true
                        print("📜 UserProfileFeedVM: Достигнут конец списка постов (получено < \(self.postsPerPage))")
                    } else {
                        self.isLastPageReached = false
                    }
                    
                case .failure(let error):
                    print("❌ UserProfileFeedVM Error (Fetch Posts): \(error.localizedDescription)")
                    self.errorMessage = "Не удалось загрузить посты: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Метод для загрузки следующей страницы постов
    func loadMorePosts() {
        // Проверяем, что не выполняется загрузка и не достигнут конец списка
        guard !isLoadingPosts, !isLastPageReached else {
            print("📜 UserProfileFeedVM: Пропускаем loadMorePosts - уже загружается или достигнут конец")
            return
        }
        
        isLoadingPosts = true
        print("📜 UserProfileFeedVM: Загружаем следующую страницу постов после документа: \(lastDocumentSnapshot != nil ? "имеется" : "nil")")
        
        postService.fetchPosts(forUserID: userID, limit: postsPerPage, startingAfter: lastDocumentSnapshot) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoadingPosts = false
                
                switch result {
                case .success(let resultData):
                    let newPosts = resultData.posts
                    print("✅ UserProfileFeedVM: Успешно загружено еще \(newPosts.count) постов")
                    
                    // Добавляем новые посты к существующим
                    self.userPosts.append(contentsOf: newPosts)
                    
                    // Обновляем последний документ
                    self.lastDocumentSnapshot = resultData.lastSnapshot
                    
                    // Проверяем, достигнут ли конец страницы
                    if newPosts.count < self.postsPerPage {
                        self.isLastPageReached = true
                        print("📜 UserProfileFeedVM: Достигнут конец списка постов")
                    }
                    
                case .failure(let error):
                    print("❌ UserProfileFeedVM Error (Load More Posts): \(error.localizedDescription)")
                    self.errorMessage = "Не удалось загрузить дополнительные посты: \(error.localizedDescription)"
                }
            }
        }
    }
} 
