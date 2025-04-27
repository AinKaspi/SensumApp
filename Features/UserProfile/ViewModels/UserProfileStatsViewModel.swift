import Foundation
import Combine

class UserProfileStatsViewModel {

    // MARK: - Dependencies
    let userID: String
    private let progressService: ProgressServiceProtocol

    // MARK: - Published Properties
    @Published private(set) var progressData: ProgressData? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    // Можно добавить @Published свойства для данных чарта, если нужна трансформация
    // @Published var radarChartData: RadarChartData?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(userID: String,
         progressService: ProgressServiceProtocol) {
        self.userID = userID
        self.progressService = progressService
        fetchProgressData()
    }

    // MARK: - Data Fetching
    func fetchProgressData() {
        guard !isLoading else { return }

        print("UserProfileStatsViewModel: Fetching progress data for userID: \(userID)")
        isLoading = true
        errorMessage = nil

        progressService.fetchProgressData(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let data):
                    self.progressData = data
                    print("UserProfileStatsViewModel: Progress data loaded.")
                    // Здесь можно будет обновить данные для чарта, если нужно
                    // self.updateChartData(from: data)
                case .failure(let error):
                    self.errorMessage = "Ошибка загрузки статистики: \(error.localizedDescription)"
                    print("UserProfileStatsViewModel Error fetching progress: \(error.localizedDescription)")
                }
            }
        }
    }

    // Метод для обновления, если потребуется
    func refreshData() {
        fetchProgressData()
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
