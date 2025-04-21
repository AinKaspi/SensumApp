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
    
    // Состояния для UI
    @Published var userProfile: User? = nil
    @Published var userPosts: [Post] = []
    @Published var isFollowing: Bool = false // Только если !isCurrentUser
    @Published var isLoadingProfile: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userID: String, 
         isCurrentUser: Bool,
         userProfileService: UserProfileServiceProtocol = UserProfileService(), 
         postService: PostServiceProtocol = PostService(),
         followService: FollowServiceProtocol = FollowService()) {
        
        self.userID = userID
        self.isCurrentUser = isCurrentUser
        self.userProfileService = userProfileService
        self.postService = postService
        self.followService = followService
        
        fetchUserProfileData()
        fetchUserPostsData()
        
        // Проверяем статус подписки, только если это профиль другого пользователя
        if !isCurrentUser {
            checkFollowingStatus()
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchUserProfileData() {
        isLoadingProfile = true
        errorMessage = nil
        userProfileService.fetchUserProfile(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingProfile = false
                switch result {
                case .success(let user):
                    self?.userProfile = user
                case .failure(let error):
                    self?.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchUserPostsData() {
        isLoadingPosts = true
        // errorMessage = nil // Не перезатираем ошибку профиля
        postService.fetchPosts(forUserID: userID) { [weak self] result in
             DispatchQueue.main.async {
                self?.isLoadingPosts = false
                switch result {
                case .success(let posts):
                    self?.userPosts = posts
                case .failure(let error):
                    // Можно показать отдельную ошибку для постов
                    print("UserProfileFeedViewModel Error (Fetch Posts): \(error.localizedDescription)")
                    self?.errorMessage = (self?.errorMessage ?? "") + "\nFailed to load posts."
                }
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
        
        let actionCompletion: (Error?) -> Void = { [weak self] error in
             DispatchQueue.main.async {
                if let error = error {
                     print("UserProfileFeedViewModel Error (Follow/Unfollow): \(error.localizedDescription)")
                     // TODO: Показать ошибку пользователю
                 } else {
                     // Обновляем локальное состояние и данные профиля (счетчики)
                     self?.isFollowing.toggle()
                     // TODO: Оптимистичное обновление счетчиков или перезагрузка профиля?
                     // self?.fetchUserProfileData()
                 }
             }
        }
        
        if isFollowing {
            // Выполнить отписку
            print("Attempting to unfollow user: \(userID)")
            followService.unfollow(userIDToUnfollow: userID, completion: actionCompletion)
        } else {
            // Выполнить подписку
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