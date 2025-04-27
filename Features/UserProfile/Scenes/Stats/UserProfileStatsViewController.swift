import UIKit
import Combine
import DGCharts

// УБЕДИТЕСЬ, ЧТО ТИПЫ НИЖЕ ОПРЕДЕЛЕНЫ В ДРУГОМ МЕСТЕ ВАШЕГО ПРОЕКТА
// И ЧТО ЭТОТ ФАЙЛ ИМЕЕТ К НИМ ДОСТУП
// import MyModels // Пример импорта, если они в отдельном модуле

/* --- УДАЛИТЕ ЭТИ СТРОКИ, ЕСЛИ КОПИРОВАЛИ ИХ РАНЕЕ ---
 // enum AttributeType: String, CaseIterable ... { ... } // УДАЛИТЬ
 // struct Attribute: ... { ... } // УДАЛИТЬ
 // struct ProgressData: ... { ... } // УДАЛИТЬ
 // protocol UserProfileStatsViewModelProtocol { ... } // УДАЛИТЬ
 --- КОНЕЦ УДАЛЯЕМЫХ СТРОК --- */

// --- Основной ViewController ---
class UserProfileStatsViewController: UIViewController {

    // MARK: - Dependencies
    // Меняем тип viewModel на конкретный класс
    var viewModel: UserProfileStatsViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var radarChartView: RadarChartView = {
        let chartView = RadarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.webLineWidth = 1.5
        chartView.innerWebLineWidth = 0.75
        chartView.webColor = .systemGray3
        chartView.innerWebColor = .systemGray5
        chartView.webAlpha = 1.0
        chartView.rotationEnabled = false
        chartView.legend.enabled = false

        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .medium)
        xAxis.labelTextColor = .label
        xAxis.xOffset = 0
        xAxis.yOffset = 0
        // Используем self
        xAxis.valueFormatter = self 

        let yAxis = chartView.yAxis
        yAxis.labelFont = .systemFont(ofSize: 9, weight: .light)
        yAxis.setLabelCount(5, force: true)
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 100
        yAxis.drawLabelsEnabled = true
        yAxis.labelTextColor = .secondaryLabel
        // Используем стандартный форматер для целых чисел
        yAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0)

        return chartView
    }()

    private lazy var infoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var usernameLabel: UILabel = createInfoLabel(fontSize: 18, weight: .bold, text: "-", alignment: .center)
    private lazy var rankLabel: UILabel = createInfoLabel(fontSize: 16, weight: .semibold, text: "Ранг: -", alignment: .center)

    private lazy var attributesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        return stackView
    }()

    private lazy var leftAttributesStack: UIStackView = createVerticalAttributeStack()
    private lazy var rightAttributesStack: UIStackView = createVerticalAttributeStack()
    private var attributeLabels: [AttributeType: UILabel] = [:]

    private lazy var levelLabel: UILabel = createInfoLabel(fontSize: 14, weight: .regular, text: "Уровень: -", alignment: .center)
    private lazy var xpLabel: UILabel = createInfoLabel(fontSize: 14, weight: .regular, text: "XP: --/--", alignment: .center)
    private lazy var xpProgressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemCyan
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true
        progressView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        return progressView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .label
        indicator.hidesWhenStopped = true
        return indicator
    }()

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
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        setupBindings()
        // viewModel.fetchStats() // VM загружает данные в init
    }

    // MARK: - Setup UI
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentWrapperView)

        contentWrapperView.addSubview(radarChartView)
        contentWrapperView.addSubview(infoContainerView)
        contentWrapperView.addSubview(levelLabel)
        contentWrapperView.addSubview(xpProgressBar)
        contentWrapperView.addSubview(xpLabel)

        infoContainerView.addSubview(usernameLabel)
        infoContainerView.addSubview(rankLabel)
        infoContainerView.addSubview(attributesStackView)
        attributesStackView.addArrangedSubview(leftAttributesStack)
        attributesStackView.addArrangedSubview(rightAttributesStack)
        createAttributeLabels()

        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
    }

    private func setupConstraints() {
         let sidePadding: CGFloat = 20
         let containerPadding: CGFloat = 15
         let verticalSpacing: CGFloat = 15
         let chartPadding: CGFloat = 10

         NSLayoutConstraint.activate([
             scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
             scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
             scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

             contentWrapperView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
             contentWrapperView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
             contentWrapperView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
             contentWrapperView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
             contentWrapperView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

             // --- Констрейнты внутри contentWrapperView ---
             radarChartView.topAnchor.constraint(equalTo: contentWrapperView.topAnchor, constant: verticalSpacing),
             radarChartView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: chartPadding),
             radarChartView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -chartPadding),
             radarChartView.heightAnchor.constraint(equalTo: radarChartView.widthAnchor),

             infoContainerView.topAnchor.constraint(equalTo: radarChartView.bottomAnchor, constant: verticalSpacing * 1.5),
             infoContainerView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: sidePadding),
             infoContainerView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -sidePadding),

             usernameLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: containerPadding),
             usernameLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: containerPadding),
             usernameLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -containerPadding),

             rankLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
             rankLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
             rankLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),

             attributesStackView.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: containerPadding),
             attributesStackView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: containerPadding),
             attributesStackView.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -containerPadding),
             attributesStackView.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -containerPadding),

             levelLabel.topAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: verticalSpacing),
             levelLabel.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: sidePadding),
             levelLabel.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -sidePadding),

             xpProgressBar.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
             xpProgressBar.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor, constant: containerPadding),
             xpProgressBar.trailingAnchor.constraint(equalTo: levelLabel.trailingAnchor, constant: -containerPadding),

             xpLabel.topAnchor.constraint(equalTo: xpProgressBar.bottomAnchor, constant: 8),
             xpLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
             xpLabel.trailingAnchor.constraint(equalTo: levelLabel.trailingAnchor),
             xpLabel.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -verticalSpacing),

             // Activity Indicator и Error Label
             activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

             errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             errorLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
             errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding),
             errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding)
         ])
     }

    // MARK: - Bindings with Combine
    private func setupBindings() {
        guard let viewModel = viewModel else {
            showError(message: "Internal error: ViewModel not configured.")
            return
        }

        // Подписка на данные прогресса
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressData in 
                // Отображаем данные прогресса, если они есть
                if let data = progressData {
                     self?.updateProgressUI(with: data)
                     self?.updateRadarChart(with: data.attributes)
                 }
            }
            .store(in: &cancellables)
            
        // Подписка на данные пользователя
        viewModel.$userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                // Отображаем имя пользователя, если оно есть
                self?.updateUserUI(with: user)
            }
            .store(in: &cancellables)

        // Объединяем состояния isLoading и errorMessage для управления UI
        Publishers.CombineLatest(viewModel.$isLoading, viewModel.$errorMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading, errorMessage in
                guard let self = self else { return }
                
                // Скрываем ошибку при начале загрузки
                if isLoading { self.errorLabel.isHidden = true }
                
                self.activityIndicator.isHidden = !isLoading
                isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
                
                let hasError = errorMessage != nil
                self.errorLabel.text = errorMessage
                self.errorLabel.isHidden = !hasError || isLoading // Не показываем ошибку во время загрузки
                
                // Скрываем контент при загрузке или ошибке
                self.scrollView.isHidden = isLoading || hasError
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Update Logic
    // Разделяем обновление UI
    private func updateProgressUI(with data: ProgressData) {
        rankLabel.text = "Ранг: \(data.rank)"
        levelLabel.text = "Уровень: \(data.level)"
        xpLabel.text = "XP: \(data.currentXP)/\(data.xpToNextLevel)"

        let progress = (data.xpToNextLevel > 0) ? Float(data.currentXP) / Float(data.xpToNextLevel) : 0
        xpProgressBar.setProgress(progress, animated: view.window != nil)

        for type in AttributeType.allCases {
            if let label = attributeLabels[type] {
                 let value = data.value(for: type)
                label.text = "\(type.rawValue): \(value)"
            }
        }
    }
    
    private func updateUserUI(with user: User?) {
        usernameLabel.text = user?.username ?? "-"
        usernameLabel.isHidden = (user == nil) // Скрываем, если нет пользователя
    }

    // MARK: - Radar Chart Update Logic
    private func updateRadarChart(with attributes: [Attribute]) {
        let sortedAttributeTypes = AttributeType.allCases

        let entries = sortedAttributeTypes.map { type -> RadarChartDataEntry in
            let value = attributes.first(where: { $0.type == type })?.value ?? 0
            let cappedValue = Swift.min(Double(value), radarChartView.yAxis.axisMaximum)
            return RadarChartDataEntry(value: cappedValue)
        }

        let dataSet = RadarChartDataSet(entries: entries, label: "Attributes")
        dataSet.colors = [UIColor.systemCyan]
        dataSet.fillColor = UIColor.systemCyan.withAlphaComponent(0.6)
        dataSet.drawFilledEnabled = true
        dataSet.lineWidth = 2
        dataSet.drawValuesEnabled = false

        dataSet.drawHighlightCircleEnabled = true
        dataSet.highlightCircleFillColor = UIColor.white
        dataSet.highlightCircleInnerRadius = 3.0
        dataSet.highlightCircleOuterRadius = 4.0
        dataSet.highlightLineWidth = 1.0
        dataSet.highlightColor = UIColor.white.withAlphaComponent(0.8)

        let data = RadarChartData(dataSets: [dataSet])

        radarChartView.data = data
        // УДАЛЯЕМ ПОВТОРНОЕ ПРИСВАИВАНИЕ ФОРМАТЕРА
        // radarChartView.xAxis.valueFormatter = XAxisValueFormatter()
        radarChartView.xAxis.axisMinimum = 0
        radarChartView.xAxis.axisMaximum = Double(sortedAttributeTypes.count - 1)
        radarChartView.xAxis.setLabelCount(sortedAttributeTypes.count, force: true)

        radarChartView.notifyDataSetChanged()
    }

    // MARK: - Helper Methods
    private func createInfoLabel(fontSize: CGFloat, weight: UIFont.Weight, text: String, alignment: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = .label
        label.textAlignment = alignment
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func createVerticalAttributeStack() -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }

    private func createAttributeLabels() {
         leftAttributesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
         rightAttributesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
         attributeLabels.removeAll()

        let allAttributes = AttributeType.allCases
        let midIndex = (allAttributes.count + 1) / 2

        let leftTypes = allAttributes[0..<midIndex]
        let rightTypes = allAttributes[midIndex..<allAttributes.count]

        for type in leftTypes {
            let label = createInfoLabel(fontSize: 14, weight: .regular, text: "\(type.rawValue): -", alignment: .left)
            attributeLabels[type] = label
            leftAttributesStack.addArrangedSubview(label)
        }

        for type in rightTypes {
            let label = createInfoLabel(fontSize: 14, weight: .regular, text: "\(type.rawValue): -", alignment: .left)
            attributeLabels[type] = label
            rightAttributesStack.addArrangedSubview(label)
        }
    }

    private func showError(message: String?) {
        let hasError = message != nil && !message!.isEmpty
        errorLabel.text = message
        errorLabel.isHidden = !hasError
        if hasError {
            scrollView.isHidden = true
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
}

// MARK: - AxisFormatters
// ВОССТАНАВЛИВАЕМ extension и класс YAxisValueFormatter с правильным протоколом
extension UserProfileStatsViewController: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value) % AttributeType.allCases.count
        guard index >= 0 && index < AttributeType.allCases.count else { return "" }
        return AttributeType.allCases[index].rawValue
    }
}

class YAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if let axis = axis, value == axis.axisMinimum { return "" }
        return String(format: "%.0f", value)
    }
}
