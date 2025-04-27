import UIKit
import Combine
import DGCharts // Импортируем библиотеку DGCharts

class UserProfileStatsViewController: UIViewController {

    // MARK: - Dependencies
    var viewModel: UserProfileStatsViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements
    
    // Основной контейнер для прокрутки (если контент не поместится)
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Радар-диаграмма
    private lazy var radarChartView: RadarChartView = {
        let chartView = RadarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        // Настройки внешнего вида (можно кастомизировать)
        chartView.webLineWidth = 1.5
        chartView.innerWebLineWidth = 0.75
        chartView.webColor = .lightGray
        chartView.innerWebColor = .darkGray
        chartView.webAlpha = 1.0
        chartView.rotationEnabled = false // Отключаем вращение
        chartView.legend.enabled = false // Отключаем легенду
        
        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .medium)
        xAxis.labelTextColor = .white
        xAxis.xOffset = 0
        xAxis.yOffset = 0
        xAxis.valueFormatter = self // Устанавливаем себя форматером для названий атрибутов
        
        let yAxis = chartView.yAxis
        yAxis.labelFont = .systemFont(ofSize: 9, weight: .light)
        yAxis.labelCount = 4 // Количество уровней сетки (0, 25, 50, 75, 100) - зависит от axisMaximum
        yAxis.axisMinimum = 0 // Минимальное значение атрибута
        yAxis.axisMaximum = 100 // Максимальное значение атрибута (предполагаемое)
        yAxis.drawLabelsEnabled = true
        yAxis.labelTextColor = .lightGray
        // yAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0) // Используем стандартный для чисел
        yAxis.valueFormatter = YAxisValueFormatter() // Используем кастомный для целых чисел

        return chartView
    }()

    // Инфо-блок (Имя, Ранг, Уровень, XP)
    private lazy var infoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 10
        return view
    }()

    // TODO: Нужно передать или загрузить имя пользователя
    private lazy var usernameLabel: UILabel = createInfoLabel(fontSize: 18, weight: .bold, text: "-")
    private lazy var rankLabel: UILabel = createInfoLabel(fontSize: 16, weight: .semibold, text: "Ранг: -")
    private lazy var levelLabel: UILabel = createInfoLabel(fontSize: 14, weight: .regular, text: "Уровень: -")
    private lazy var xpLabel: UILabel = createInfoLabel(fontSize: 14, weight: .regular, text: "XP: --/--")
    
    // Индикатор загрузки
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Лейбл для ошибок
     private lazy var errorLabel: UILabel = {
         let label = UILabel()
         label.translatesAutoresizingMaskIntoConstraints = false
         label.textColor = .systemRed
         label.font = .systemFont(ofSize: 14, weight: .medium)
         label.textAlignment = .center
         label.numberOfLines = 0
         label.isHidden = true
         return label
     }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into UserProfileStatsViewController")
        view.backgroundColor = .black // Фон для всего VC
        setupViews()
        setupConstraints()
        setupBindings()
        // Загружаем данные при первом показе (если VM не загружает их сам в init)
        // viewModel.fetchProgressData()
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(radarChartView)
        contentView.addSubview(infoContainerView)
        
        infoContainerView.addSubview(usernameLabel)
        infoContainerView.addSubview(rankLabel)
        infoContainerView.addSubview(levelLabel)
        infoContainerView.addSubview(xpLabel)
        
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel) // Добавляем лейбл ошибки
    }

    private func setupConstraints() {
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView (растягивается по ширине ScrollView и определяет высоту контента)
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Radar Chart
            radarChartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            radarChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            radarChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            // Задаем соотношение сторон для радара, например, 1:1
            radarChartView.heightAnchor.constraint(equalTo: radarChartView.widthAnchor),
            
            // Info Container
            infoContainerView.topAnchor.constraint(equalTo: radarChartView.bottomAnchor, constant: padding * 1.5),
            infoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            infoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            // Привязываем низ контейнера к низу contentView, чтобы определить размер контента ScrollView
            infoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            // Элементы внутри Info Container
            usernameLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: padding),
            usernameLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -padding),
            
            rankLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            rankLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            rankLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            levelLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            levelLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            xpLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
            xpLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            xpLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            xpLabel.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -padding),
            
            // Индикатор загрузки и Лейбл ошибки по центру
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    // MARK: - Bindings
    private func setupBindings() {
        // Подписка на данные прогресса
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressData in
                guard let data = progressData else {
                    // Скрываем UI, если данных нет
                    self?.scrollView.isHidden = true
                    return
                }
                // Показываем UI и обновляем
                self?.scrollView.isHidden = false
                self?.updateUI(with: data)
                self?.updateRadarChart(with: data.attributes)
            }
            .store(in: &cancellables)

        // Подписка на состояние загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.errorLabel.isHidden = true // Скрываем ошибку при начале загрузки
                self?.activityIndicator.isHidden = !isLoading
                self?.scrollView.isHidden = isLoading // Скрываем контент во время загрузки
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let hasError = message != nil
                self?.errorLabel.text = message
                self?.errorLabel.isHidden = !hasError
                // Скрываем scrollView и индикатор, если есть ошибка
                if hasError {
                    self?.scrollView.isHidden = true
                    self?.activityIndicator.stopAnimating()
                    self?.activityIndicator.isHidden = true
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Update
    private func updateUI(with data: ProgressData) {
        // TODO: Получить имя пользователя (нужно передать User или загрузить здесь)
        // Пока не отображаем имя пользователя
        // usernameLabel.text = viewModel.username // Пример
        usernameLabel.isHidden = true // Временно скроем
        
        rankLabel.text = "Ранг: \(data.rank)"
        levelLabel.text = "Уровень: \(data.level)"
        xpLabel.text = "XP: \(data.currentXP)/\(data.xpToNextLevel)"
    }

    // MARK: - Radar Chart Update
    private func updateRadarChart(with attributes: [Attribute]) {
        // 1. Подготовка данных
        let sortedAttributes = AttributeType.allCases.compactMap { type -> Attribute? in
            attributes.first(where: { $0.type == type })
        }
        
        let entries = sortedAttributes.map { RadarChartDataEntry(value: Double($0.value)) }
        
        // 2. Создание DataSet
        let dataSet = RadarChartDataSet(entries: entries, label: "Attributes")
        dataSet.colors = [.systemCyan]
        dataSet.fillColor = .systemCyan.withAlphaComponent(0.6)
        dataSet.drawFilledEnabled = true
        dataSet.lineWidth = 2
        dataSet.drawValuesEnabled = true // Показываем значения на точках
        dataSet.valueFont = .systemFont(ofSize: 10, weight: .medium)
        dataSet.valueTextColor = .white
        // Устанавливаем маркеры (круги) на вершинах
        dataSet.drawHighlightCircleEnabled = true
        dataSet.highlightCircleFillColor = .white
        dataSet.highlightCircleInnerRadius = 3.0
        dataSet.highlightCircleOuterRadius = 4.0
        
        // 3. Создание ChartData
        let data = RadarChartData(dataSets: [dataSet])
        data.setValueFormatter(DefaultValueFormatter(decimals: 0)) // Форматтер для значений (0 знаков после запятой)
        data.setValueTextColor(.clear) // Скрываем дублирующиеся значения рядом с точками
        data.setValueFont(.systemFont(ofSize: 9))
        
        // 4. Установка данных в ChartView
        radarChartView.data = data
        // Устанавливаем анимацию
        radarChartView.animate(yAxisDuration: 0.8, easingOption: .easeOutQuad)
    }
    
    // MARK: - Helper Methods
    private func createInfoLabel(fontSize: CGFloat, weight: UIFont.Weight, text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        return label
    }
}

// MARK: - AxisFormatters
extension UserProfileStatsViewController: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value) % AttributeType.allCases.count
        // Проверяем границы на всякий случай
        guard index >= 0 && index < AttributeType.allCases.count else { return "" }
        return AttributeType.allCases[index].rawValue
    }
}

class YAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.0f", value)
    }
}
