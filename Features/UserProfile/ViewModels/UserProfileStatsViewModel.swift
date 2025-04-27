import Foundation
import Combine

// Определяем протокол для ViewModel (хорошая практика)
protocol UserProfileStatsViewModelProtocol {
    var userID: String { get }
    var progressData: CurrentValueSubject<ProgressData?, Never> { get }
    var userProfile: CurrentValueSubject<User?, Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var errorMessage: CurrentValueSubject<String?, Never> { get }
    
    func fetchStatsData()
    func refreshData()
}

// Используем Combine Subjects для @Published вне класса (если нужно будет мокать)
// Или оставляем @Published, но тогда протокол будет сложнее
// Пока оставим @Published внутри класса и используем конкретный класс в VC

class UserProfileStatsViewModel /*: UserProfileStatsViewModelProtocol*/ {

    // MARK: - Dependencies
    let userID: String
    private let progressService: ProgressServiceProtocol
    // Добавляем UserProfileService
    private let userProfileService: UserProfileServiceProtocol 

    // MARK: - Published Properties
    @Published private(set) var progressData: ProgressData? = nil
    // Добавляем User Profile
    @Published private(set) var userProfile: User? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    // Можно добавить @Published свойства для данных чарта, если нужна трансформация
    // @Published var radarChartData: RadarChartData?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    // Обновляем init
    init(userID: String,
         progressService: ProgressServiceProtocol, // Убираем значение по умолчанию
         userProfileService: UserProfileServiceProtocol) { // Добавляем userProfileService
        self.userID = userID
        self.progressService = progressService
        self.userProfileService = userProfileService // Сохраняем
        fetchStatsData() // Вызываем новый метод
    }

    // MARK: - Data Fetching
    // Переименовываем и обновляем метод
    func fetchStatsData() {
        guard !isLoading else { return }
        
        print("UserProfileStatsViewModel: Fetching stats data for userID: \(userID)")
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var fetchedUser: User? = nil
        var fetchedProgress: ProgressData? = nil
        var fetchError: Error? = nil

        // Загрузка ProgressData
        group.enter()
        progressService.fetchProgressData(userID: userID) { result in
            switch result {
            case .success(let data): fetchedProgress = data
            case .failure(let error): fetchError = error
            }
            group.leave()
        }
        
        // Загрузка User
        group.enter()
        userProfileService.fetchUserProfile(userID: userID) { result in
            switch result {
            case .success(let user): fetchedUser = user
            case .failure(let error): 
                if fetchError == nil { fetchError = error } // Сохраняем первую ошибку
            }
            group.leave()
        }

        // Обработка результатов
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if let error = fetchError {
                self.errorMessage = "Ошибка загрузки данных: \(error.localizedDescription)"
                print("UserProfileStatsViewModel Error fetching data: \(error.localizedDescription)")
                // Очищаем старые данные при ошибке?
                // self.userProfile = nil
                // self.progressData = nil
            } else {
                self.userProfile = fetchedUser
                self.progressData = fetchedProgress
                 print("UserProfileStatsViewModel: Stats data loaded successfully.")
                // Проверка, что оба объекта загрузились
                if fetchedUser == nil { print("Warning: User profile data is nil after fetch.") }
                if fetchedProgress == nil { print("Warning: Progress data is nil after fetch.") }
            }
        }
    }

    func refreshData() {
        fetchStatsData()
    }

    /*
    // Пример трансформации данных для RadarChart
    private func updateChartData(from progressData: ProgressData?) {
        guard let data = progressData else {
            // self.radarChartData = nil // Очистить данные чарта
            return
        }
        // TODO: Реализовать создание RadarChartData из data.attributes
        // Используя библиотеку DGCharts
        print("UserProfileStatsViewModel: Updating chart data (Not Implemented)")
    }
    */
}
