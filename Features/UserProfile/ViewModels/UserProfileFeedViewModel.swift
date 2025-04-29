import Foundation
import Combine

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
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
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
        postService.fetchPosts(forUserID: userID, limit: 18, startingAfter: nil) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingPosts = false
                switch result {
                case .success(let resultData):
                    self?.userPosts = resultData.posts
                case .failure(let error):
                     print("UserProfileFeedVM Error (Fetch Posts): \(error.localizedDescription)")
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
} 
