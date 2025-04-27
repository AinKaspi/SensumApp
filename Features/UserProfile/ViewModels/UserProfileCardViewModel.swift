import Foundation
import Combine

class UserProfileCardViewModel {

    // MARK: - Dependencies
    let userID: String
    let isCurrentUser: Bool // Должен передаваться при создании
    private let userProfileService: UserProfileServiceProtocol
    private let progressService: ProgressServiceProtocol
    private let followService: FollowServiceProtocol

    // MARK: - Published Properties
    @Published private(set) var userProfile: User? = nil
    @Published private(set) var progressData: ProgressData? = nil
    @Published private(set) var isFollowing: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(userID: String,
         isCurrentUser: Bool, // Принимаем флаг
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         progressService: ProgressServiceProtocol,
         followService: FollowServiceProtocol = FollowService()) {
        self.userID = userID
        self.isCurrentUser = isCurrentUser // Сохраняем
        self.userProfileService = userProfileService
        self.progressService = progressService
        self.followService = followService
        fetchCardData()

        if !isCurrentUser {
            checkFollowingStatus()
        }
    }

    // MARK: - Data Fetching
    func fetchCardData() {
        guard !isLoading else { return }
        print("UserProfileCardViewModel: Fetching card data for userID: \(userID)")
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()
        var fetchedUser: User? = nil
        var fetchedProgress: ProgressData? = nil
        var fetchError: Error? = nil

        group.enter()
        userProfileService.fetchUserProfile(userID: userID) { result in
            switch result {
            case .success(let user): fetchedUser = user
            case .failure(let error): fetchError = error
            }
            group.leave()
        }

        group.enter()
        progressService.fetchProgressData(userID: userID) { result in
            switch result {
            case .success(let data): fetchedProgress = data
            case .failure(let error):
                if fetchError == nil { fetchError = error }
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if let error = fetchError {
                self.errorMessage = "Ошибка загрузки данных карты: \(error.localizedDescription)"
                print("UserProfileCardViewModel Error fetching data: \(error.localizedDescription)")
            } else {
                self.userProfile = fetchedUser
                self.progressData = fetchedProgress
                print("UserProfileCardViewModel: Card data loaded successfully.")
            }
        }
    }

    func checkFollowingStatus() {
        guard !isCurrentUser else { return }
        followService.checkIfFollowing(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isFollowingStatus):
                    self?.isFollowing = isFollowingStatus
                case .failure(let error):
                    print("UserProfileCardViewModel Error (Check Following): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Actions
    func followButtonTapped() {
        guard !isCurrentUser else { return }
        let wasFollowing = isFollowing
        let currentFollowerCount = userProfile?.followerCount ?? 0
        let optimisticFollowerCount = wasFollowing ? max(0, currentFollowerCount - 1) : currentFollowerCount + 1

        self.isFollowing.toggle()
        self.userProfile?.followerCount = optimisticFollowerCount

        let actionCompletion: (Error?) -> Void = { [weak self] error in
             DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                     print("UserProfileCardViewModel Error (Follow/Unfollow): \(error.localizedDescription)")
                     self.isFollowing = wasFollowing
                     self.userProfile?.followerCount = currentFollowerCount
                     self.errorMessage = "Failed to update follow status: \(error.localizedDescription)"
                 } else {
                     print("UserProfileCardViewModel: Follow status updated successfully.")
                     // self.fetchCardData() // Перезагрузка для точности счетчиков
                 }
             }
        }

        if wasFollowing {
            followService.unfollow(userIDToUnfollow: userID, completion: actionCompletion)
        } else {
            followService.follow(userIDToFollow: userID, completion: actionCompletion)
        }
    }

    func refreshData() {
        fetchCardData()
        if !isCurrentUser {
            checkFollowingStatus()
        }
    }
}
