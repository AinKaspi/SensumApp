import Foundation
import Combine

class ProgressViewModel {

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let progressService: ProgressServiceProtocol

    // MARK: - Published Properties
    @Published var progressData: ProgressData? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService(),
         progressService: ProgressServiceProtocol) {
        self.authService = authService
        self.progressService = progressService
        fetchProgressData()
    }

    // MARK: - Data Fetching
    func fetchProgressData() {
        guard let userID = authService.currentUserID else {
            errorMessage = "Пользователь не авторизован."
            print("ProgressViewModel Error: User not logged in.")
            return
        }

        isLoading = true
        errorMessage = nil

        progressService.fetchProgressData(userID: userID) { [weak self] result in
            // Обновляем на главном потоке
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let data):
                    self.progressData = data
                    print("ProgressViewModel: Progress data loaded.")
                case .failure(let error):
                    self.errorMessage = "Ошибка загрузки прогресса: \(error.localizedDescription)"
                    print("ProgressViewModel Error fetching progress: \(error.localizedDescription)")
                }
            }
        }
    }

    // Можно добавить метод для Pull-to-Refresh, если потребуется
    func refreshData() {
        print("ProgressViewModel: Refreshing data...")
        fetchProgressData()
    }
}
