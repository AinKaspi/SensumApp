import UIKit
// Импортируем DGCharts, так как это имя продукта в Package.swift для SPM
import DGCharts

// Добавляем Charts для RadarChartView, если он используется
// import Charts 

// --- Модели Данных ---
struct Achievement {
    let id: String
    let name: String
    let iconName: String
}

struct FeedEvent {
    let id: String
    let description: String
    let timestamp: Date
}

// --- Протокол Делегата ---
protocol PersonViewControllerDelegate: AnyObject {
    func personViewControllerDidRequestShowAllAchievements(_ controller: PersonViewController)
    func personViewControllerDidRequestShowAllFeed(_ controller: PersonViewController)
}

// --- Класс ViewController ---
class PersonViewController: UIViewController, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // --- Свойства ---
    weak var delegate: PersonViewControllerDelegate?

    // Данные (Примеры)
    private var userAchievements: [Achievement] = [
        Achievement(id: "ach1", name: "Первый шаг", iconName: "figure.walk"),
        Achievement(id: "ach2", name: "Мастер приседаний", iconName: "figure.squat.square"),
        Achievement(id: "ach3", name: "Чемпион дня", iconName: "star.fill"),
        Achievement(id: "ach4", name: "Второе дыхание", iconName: "wind"),
        Achievement(id: "ach5", name: "Сила воли", iconName: "bolt.heart"),
        Achievement(id: "ach6", name: "Неудержимый", iconName: "flame.fill"),
        Achievement(id: "ach7", name: "Ранняя пташка", iconName: "sunrise"),
        Achievement(id: "ach8", name: "Полуночник", iconName: "moon.stars"),
        Achievement(id: "ach9", name: "Еще одна", iconName: "gift"),
        Achievement(id: "ach10", name: "Десять", iconName: "10.square"),
        Achievement(id: "ach11", name: "Одиннадцать", iconName: "11.square"),
        Achievement(id: "ach12", name: "Дюжина", iconName: "12.square"),
        Achievement(id: "ach13", name: "Тринадцать", iconName: "13.square"),
    ]
    private var feedEvents: [FeedEvent] = [
        FeedEvent(id: "f1", description: "Достижение 'Первый шаг' разблокировано!", timestamp: Date().addingTimeInterval(-3600 * 2)),
        FeedEvent(id: "f2", description: "Уровень повышен до 1!", timestamp: Date().addingTimeInterval(-3600 * 24)),
        FeedEvent(id: "f3", description: "Выполнено ежедневное задание 'Утренняя зарядка'. Это очень длинное описание для теста того, как ячейка будет растягиваться по высоте, если текста много.", timestamp: Date().addingTimeInterval(-3600 * 26)),
        FeedEvent(id: "f4", description: "Новый ранг: E", timestamp: Date().addingTimeInterval(-3600 * 48)),
        FeedEvent(id: "f5", description: "Куплен новый эффект 'Пламя'", timestamp: Date().addingTimeInterval(-3600 * 72))
    ]

    // Форматтер даты
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // KVO Свойства - УДАЛЯЕМ
    // ВРЕМЕННО ВОЗВРАЩАЕМ ОБЪЯВЛЕНИЯ для теста с фикс. высотой
    private var achievementsCollectionViewHeightConstraint: NSLayoutConstraint?
    private var feedTableViewHeightConstraint: NSLayoutConstraint?
    // private var tableViewContentSizeObserver: NSKeyValueObservation?
    // private var collectionViewContentSizeObserver: NSKeyValueObservation?

    // --- UI Элементы (Lazy Vars) ---

    // ScrollView и StackView
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20 // Расстояние между карточками
        return stackView
    }()

    // Контейнеры (График и Статы в отдельных контейнерах в один ряд)
    private lazy var profileHeaderContainerView: UIView = createContainerView() 
    private lazy var profileXPContainerView: UIView = createContainerView()     
    private lazy var profileChartContainerView: UIView = createContainerView() // Контейнер ТОЛЬКО для графика
    private lazy var profileStatsListContainerView: UIView = createContainerView() // Контейнер ТОЛЬКО для статов
    // Удаляем общий контейнер
    // private lazy var profileChartStatsContainerView: UIView = createContainerView()
    private lazy var achievementsContainerView: UIView = createContainerView()
    private lazy var feedContainerView: UIView = createContainerView()

    // --- Элементы Профиля --- 
    // Блок 1: Header
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .lightGray
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12 // Скругление для 100x100
        return imageView
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Имя Игрока"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    private lazy var rankLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ранг: E / Новобранец"
        label.textColor = .systemOrange
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    // Блок 2: Chart & Stats (Снова вместе)
    private lazy var radarChartView: DGCharts.RadarChartView = {
        // Явно указываем тип переменной chartView с модулем
        let chartView: DGCharts.RadarChartView = DGCharts.RadarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        // Убираем всю настройку отсюда, оставляем только создание
        /*
        // --- Настройка внешнего вида для Charts 4.x/5.x ---
        // Убираем свойства web... и настраиваем сетку через оси
        // chartView.webLineWidth = 1.5
        // ... (остальная убранная настройка)
        chartView.legend.enabled = false // Отключаем легенду
        */
        return chartView
    }()
    private lazy var statsDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        // Убираем установку текста здесь, т.к. функция createStatsAttributedString удалена/переименована
        // и self еще недоступен. Текст будет установлен в updateProfileDisplay.
        // label.attributedText = createStatsAttributedString()
        return label
    }()
    // Удаляем разделитель
    // private lazy var statsDividerView: UIView = { ... }()
    
    // Блок 3: XP 
    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Уровень: 1"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular) // Делаем шрифт как у XP
        // label.textAlignment = .left // Стек будет управлять
        return label
    }()
    private lazy var xpProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = UIColor.gray.withAlphaComponent(0.5)
        progressView.progress = 0.6
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "600 / 1000 XP"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .right
        return label
    }()

    // --- Стеки для новой структуры --- 
    private lazy var nameLevelRankStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, rankLabel]) 
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading 
        stackView.spacing = 4 
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        // Аватар слева, стек с инфо справа
        let stackView = UIStackView(arrangedSubviews: [avatarImageView, nameLevelRankStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center // Выравниваем по центру вертикально
        stackView.spacing = 15
        // avatarImageView будет иметь фиксированный размер, nameLevelRankStackView займет остальное
        return stackView
    }()
    
    // Удаляем chartStatsHorizontalStackView
    // private lazy var chartStatsHorizontalStackView: UIStackView = { ... }()

    // НОВЫЙ СТЕК для РЯДА с графиком и статами
    private lazy var chartStatsRowStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileChartContainerView, profileStatsListContainerView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill // Будем управлять шириной через констрейнты контейнеров
        stackView.spacing = 20 // Отступ МЕЖДУ контейнерами графика и статов
        return stackView
    }()

    // НОВЫЙ СТЕК для лейблов Уровня и XP
    private lazy var levelXPLabelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [levelLabel, xpLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        // levelLabel займет свое место слева, xpLabel (с textAlignment = .right) уйдет вправо
        stackView.distribution = .fill // Или .equalSpacing, .fillEqually - можно поиграть
        return stackView
    }()

    private lazy var xpStackView: UIStackView = {
        // Теперь содержит levelXPLabelStackView и xpProgressView
        let stackView = UIStackView(arrangedSubviews: [levelXPLabelStackView, xpProgressView]) 
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6 // Немного увеличим отступ между лейблами и прогрессом
        // stackView.setCustomSpacing(...) // Больше не нужно
        return stackView
    }()

    // Элементы достижений
    private lazy var achievementsTitleLabel: UILabel = createTitleLabel(text: "Достижения")
    private lazy var achievementsChevronImageView: UIImageView = createChevronImageView()
    private lazy var achievementsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 45, height: 45)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let collectionView = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(AchievementCell.self, forCellWithReuseIdentifier: AchievementCell.identifier)
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false // Динамическая высота
        return collectionView
    }()

    // Элементы ленты
    private lazy var feedTitleLabel: UILabel = createTitleLabel(text: "Лента")
    private lazy var feedChevronImageView: UIImageView = createChevronImageView()
    private lazy var feedTableView: UITableView = {
        let tableView = SelfSizingTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(FeedEventCell.self, forCellReuseIdentifier: FeedEventCell.identifier)
        tableView.dataSource = self
        tableView.isScrollEnabled = false // Динамическая высота (через KVO)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        return tableView
    }()

    // --- Вспомогательные функции для создания UI (ПОЛНЫЙ КОД) ---
    private func createTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }

    private func createChevronImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    private func createContainerView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        container.layer.cornerRadius = 12
        return container
    }

    // --- Жизненный цикл и настройка ---
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        addTapGestures()
        setupAvatarTapGesture() // Добавляем настройку нажатия на аватар
        setupRadarChartAppearance() // Вызываем новую функцию настройки
    }
    
    // Отладочный Print
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }

    // --- Обновление UI при появлении ---
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileDisplay() // Обновляем данные профиля перед показом
    }

    // --- Обновление данных профиля ---
    /// Загружает актуальные данные из DataManager и обновляет UI элементы профиля.
    private func updateProfileDisplay() {
        // 1. Получаем самый свежий профиль пользователя
        let profile = DataManager.shared.getCurrentUserProfile()

        // 2. Обновляем UI элементы, связанные с уровнем и XP
        // Устанавливаем текст для лейбла уровня
        levelLabel.text = "Уровень: \(profile.level)"
        // Устанавливаем текст для лейбла XP, показывая текущее / необходимое
        xpLabel.text = "\(profile.currentXP) / \(profile.xpToNextLevel) XP"

        // 3. Рассчитываем прогресс для XP ProgressBar
        // Проверяем, что xpToNextLevel не равен нулю, чтобы избежать деления на ноль
        let progress: Float
        if profile.xpToNextLevel > 0 {
            // Рассчитываем прогресс как отношение текущего XP к необходимому
            progress = Float(profile.currentXP) / Float(profile.xpToNextLevel)
        } else {
            // Если xpToNextLevel равен 0 (теоретически возможно при очень высоких уровнях или ошибках), устанавливаем прогресс в 0
            progress = 0.0
        }

        // 4. Ограничиваем значение прогресса диапазоном от 0.0 до 1.0
        // Это нужно на случай, если currentXP вдруг станет больше xpToNextLevel (хотя логика в addXP должна это предотвращать)
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // 5. Устанавливаем рассчитанный прогресс в UIProgressView
        // animated: false, так как обновление происходит перед тем, как view появится
        xpProgressView.setProgress(clampedProgress, animated: false)
        
        // 6. Обновляем другие элементы профиля (имя, ранг, аватар и т.д.) - TODO: Загрузить реальные данные
        nameLabel.text = profile.username ?? "Игрок" // Используем имя из профиля или дефолтное
        rankLabel.text = "Ранг: \(profile.rank.rawValue)" // Используем ранг из профиля
        // TODO: Загрузить и установить изображение аватара (если есть)
        if let avatar = loadAvatarImage(forUserID: profile.userID) {
            avatarImageView.image = avatar
        } else {
            avatarImageView.image = nil // Убедимся, что старое изображение убрано, если аватар удалили/не нашли
            avatarImageView.backgroundColor = .lightGray // Возвращаем серый фон, если нет картинки
        }

        // 7. Обновляем список базовых атрибутов
        statsDescriptionLabel.attributedText = createBaseAttributesString(from: profile)
        
        // 8. Обновляем Radar Chart
        updateRadarChart(with: profile)
    }

    // Настройка Views
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Добавляем 5 "строк" в главный стек
        contentStackView.addArrangedSubview(profileHeaderContainerView)
        contentStackView.addArrangedSubview(profileXPContainerView)    
        // Добавляем горизонтальный стек для графика и статов
        contentStackView.addArrangedSubview(chartStatsRowStackView) 
        contentStackView.addArrangedSubview(achievementsContainerView)
        contentStackView.addArrangedSubview(feedContainerView)

        // Добавляем внутренние элементы в их ПРЯМЫЕ контейнеры
        profileHeaderContainerView.addSubview(headerStackView)
        profileXPContainerView.addSubview(xpStackView)
        // График в свой контейнер (который уже в chartStatsRowStackView)
        profileChartContainerView.addSubview(radarChartView)
        // Статы в свой контейнер (который уже в chartStatsRowStackView)
        profileStatsListContainerView.addSubview(statsDescriptionLabel)

        // --- Остальные контейнеры без изменений ---
        achievementsContainerView.addSubview(achievementsTitleLabel)
        achievementsContainerView.addSubview(achievementsChevronImageView)
        achievementsContainerView.addSubview(achievementsCollectionView)

        feedContainerView.addSubview(feedTitleLabel)
        feedContainerView.addSubview(feedChevronImageView)
        feedContainerView.addSubview(feedTableView)
    }

    // Настройка жестов
    private func addTapGestures() {
        let achievementsTap = UITapGestureRecognizer(target: self, action: #selector(achievementsHeaderTapped))
        achievementsTap.delegate = self
        achievementsContainerView.addGestureRecognizer(achievementsTap)

        let feedTap = UITapGestureRecognizer(target: self, action: #selector(feedHeaderTapped))
        feedTap.delegate = self
        feedContainerView.addGestureRecognizer(feedTap)
    }
    
    // Добавляем настройку жеста для аватара
    private func setupAvatarTapGesture() {
        // Делаем avatarImageView интерактивным
        avatarImageView.isUserInteractionEnabled = true
        // Создаем распознаватель нажатия
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        // Добавляем его к avatarImageView
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    // Настройка констрейнтов
    private func setupConstraints() {
        let horizontalPadding: CGFloat = 16
        let containerPadding: CGFloat = 15
        let cardInternalPadding: CGFloat = 12
        // spacing между контейнерами графика и статов задается в chartStatsRowStackView

        NSLayoutConstraint.activate([
            // --- ScrollView и ContentStackView --- 
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalPadding),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * horizontalPadding),

            // --- Констрейнты для profileHeaderContainerView ---
            headerStackView.topAnchor.constraint(equalTo: profileHeaderContainerView.topAnchor, constant: containerPadding),
            headerStackView.leadingAnchor.constraint(equalTo: profileHeaderContainerView.leadingAnchor, constant: containerPadding),
            headerStackView.trailingAnchor.constraint(equalTo: profileHeaderContainerView.trailingAnchor, constant: -containerPadding),
            headerStackView.bottomAnchor.constraint(equalTo: profileHeaderContainerView.bottomAnchor, constant: -containerPadding),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),
            
            // --- Констрейнты для profileXPContainerView ---
            xpStackView.topAnchor.constraint(equalTo: profileXPContainerView.topAnchor, constant: containerPadding),
            xpStackView.leadingAnchor.constraint(equalTo: profileXPContainerView.leadingAnchor, constant: containerPadding),
            xpStackView.trailingAnchor.constraint(equalTo: profileXPContainerView.trailingAnchor, constant: -containerPadding),
            xpStackView.bottomAnchor.constraint(equalTo: profileXPContainerView.bottomAnchor, constant: -containerPadding),
            xpProgressView.heightAnchor.constraint(equalToConstant: 8),

            // --- Констрейнты для chartStatsRowStackView (Строка с графиком и статами) ---
            // Определяем пропорции ширины КОНТЕЙНЕРОВ внутри стека
            profileChartContainerView.widthAnchor.constraint(equalTo: chartStatsRowStackView.widthAnchor, multiplier: 0.6, constant: -(chartStatsRowStackView.spacing * 0.6)),
            profileStatsListContainerView.widthAnchor.constraint(equalTo: chartStatsRowStackView.widthAnchor, multiplier: 0.4, constant: -(chartStatsRowStackView.spacing * 0.4)),
            
            // --- Констрейнты ВНУТРИ profileChartContainerView ---
            radarChartView.topAnchor.constraint(equalTo: profileChartContainerView.topAnchor, constant: containerPadding),
            radarChartView.leadingAnchor.constraint(equalTo: profileChartContainerView.leadingAnchor, constant: containerPadding),
            radarChartView.trailingAnchor.constraint(equalTo: profileChartContainerView.trailingAnchor, constant: -containerPadding),
            radarChartView.bottomAnchor.constraint(equalTo: profileChartContainerView.bottomAnchor, constant: -containerPadding),
            radarChartView.heightAnchor.constraint(equalTo: radarChartView.widthAnchor), // Квадратный
            
            // --- Констрейнты ВНУТРИ profileStatsListContainerView ---
            // Центрируем лейбл внутри его контейнера
            statsDescriptionLabel.topAnchor.constraint(equalTo: profileStatsListContainerView.topAnchor, constant: containerPadding),
            statsDescriptionLabel.bottomAnchor.constraint(equalTo: profileStatsListContainerView.bottomAnchor, constant: -containerPadding),
            statsDescriptionLabel.centerXAnchor.constraint(equalTo: profileStatsListContainerView.centerXAnchor), // Центрируем по горизонтали
            // Ограничиваем ширину, если нужно, чтобы текст не прилипал к краям при длинных строках (хотя numberOfLines=0 должен переносить)
            statsDescriptionLabel.widthAnchor.constraint(lessThanOrEqualTo: profileStatsListContainerView.widthAnchor, constant: -2 * containerPadding), // Оставляем боковые отступы

            // --- Констрейнты для Достижений и Ленты (без изменений) ---
            achievementsTitleLabel.topAnchor.constraint(equalTo: achievementsContainerView.topAnchor, constant: cardInternalPadding),
            achievementsTitleLabel.leadingAnchor.constraint(equalTo: achievementsContainerView.leadingAnchor, constant: cardInternalPadding),
            achievementsChevronImageView.centerYAnchor.constraint(equalTo: achievementsTitleLabel.centerYAnchor),
            achievementsChevronImageView.trailingAnchor.constraint(equalTo: achievementsContainerView.trailingAnchor, constant: -cardInternalPadding),
            achievementsChevronImageView.widthAnchor.constraint(equalToConstant: 10),
            achievementsChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            achievementsTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: achievementsChevronImageView.leadingAnchor, constant: -8),
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsTitleLabel.bottomAnchor, constant: cardInternalPadding / 2),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: achievementsContainerView.leadingAnchor, constant: cardInternalPadding),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: achievementsContainerView.trailingAnchor, constant: -cardInternalPadding),
            achievementsContainerView.bottomAnchor.constraint(equalTo: achievementsCollectionView.bottomAnchor, constant: cardInternalPadding),

            feedTitleLabel.topAnchor.constraint(equalTo: feedContainerView.topAnchor, constant: cardInternalPadding),
            feedTitleLabel.leadingAnchor.constraint(equalTo: feedContainerView.leadingAnchor, constant: cardInternalPadding),
            feedChevronImageView.centerYAnchor.constraint(equalTo: feedTitleLabel.centerYAnchor),
            feedChevronImageView.trailingAnchor.constraint(equalTo: feedContainerView.trailingAnchor, constant: -cardInternalPadding),
            feedChevronImageView.widthAnchor.constraint(equalToConstant: 10),
            feedChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            feedTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: feedChevronImageView.leadingAnchor, constant: -8),
            feedTableView.topAnchor.constraint(equalTo: feedTitleLabel.bottomAnchor, constant: cardInternalPadding / 2),
            feedTableView.leadingAnchor.constraint(equalTo: feedContainerView.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: feedContainerView.trailingAnchor),
            feedContainerView.bottomAnchor.constraint(equalTo: feedTableView.bottomAnchor, constant: cardInternalPadding),
        ])
    }

    // --- Обработчики нажатий ---
    @objc private func achievementsHeaderTapped() {
        delegate?.personViewControllerDidRequestShowAllAchievements(self)
    }

    @objc private func feedHeaderTapped() {
        delegate?.personViewControllerDidRequestShowAllFeed(self)
    }

    // --- Обработчик нажатия на аватар ---
    @objc private func avatarTapped() {
        // Создаем стандартный контроллер для выбора изображений
        let imagePickerController = UIImagePickerController()
        // Устанавливаем делегата для получения результата выбора
        imagePickerController.delegate = self
        // Указываем, что хотим выбирать из фотогалереи
        imagePickerController.sourceType = .photoLibrary
        // Опционально: разрешить редактирование (кадрирование) перед выбором
        // imagePickerController.allowsEditing = true 
        // Показываем контроллер выбора изображения
        present(imagePickerController, animated: true, completion: nil)
    }

    // --- UIGestureRecognizerDelegate ---
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // --- Новая функция для настройки внешнего вида графика ---
    private func setupRadarChartAppearance() {
        // Настройка внешнего вида для Charts 4.x/5.x
        // Настройка сетки через оси
        radarChartView.xAxis.labelFont = .systemFont(ofSize: 9, weight: .light)
        radarChartView.xAxis.xOffset = 0
        radarChartView.xAxis.yOffset = 0
        radarChartView.xAxis.valueFormatter = RadarChartXAxisValueFormatter() // Форматтер меток оси X (будет перезаписан в updateRadarChart)
        radarChartView.xAxis.labelTextColor = .white
        radarChartView.xAxis.drawGridLinesEnabled = true // Линии от центра
        radarChartView.xAxis.gridLineWidth = 1.5 
        radarChartView.xAxis.gridColor = UIColor.lightGray.withAlphaComponent(0.8)
        
        radarChartView.yAxis.labelFont = .systemFont(ofSize: 9, weight: .light)
        radarChartView.yAxis.labelCount = 6 // Количество меток (0, 20, 40, 60, 80, 100)
        radarChartView.yAxis.axisMinimum = 0
        // Максимальное значение = База(20) + 2 * (Макс.Атрибут(100)/10) = 40
        // Устанавливаем максимум оси Y в 60 для большего пространства
        radarChartView.yAxis.axisMaximum = 60
        // Убираем числовые метки с оси Y
        radarChartView.yAxis.drawLabelsEnabled = false // Показываем метки (0, 20, ...)
        radarChartView.yAxis.valueFormatter = YAxisValueFormatter() // Форматтер меток оси Y
        radarChartView.yAxis.labelTextColor = UIColor.lightGray
        // Устанавливаем полный диапазон оси явно
        radarChartView.yAxis.axisRange = 100
        // Попробуем принудительно использовать указанное количество меток
        radarChartView.yAxis.forceLabelsEnabled = true
        // Добавляем гранулярность для четких шагов по 20
        radarChartView.yAxis.granularityEnabled = true
        radarChartView.yAxis.granularity = 20
        // Настройка сетки оси Y (концентрические линии)
        radarChartView.yAxis.drawGridLinesEnabled = true
        radarChartView.yAxis.gridLineWidth = 1.0
        radarChartView.yAxis.gridColor = UIColor.darkGray.withAlphaComponent(0.8)

        radarChartView.rotationEnabled = false
        radarChartView.legend.enabled = false // Отключаем легенду
        
    }
}

// MARK: - UICollectionViewDataSource
// Объявляем соответствие протоколу ЗДЕСЬ
extension PersonViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let countToShow = min(userAchievements.count, 12)
        return countToShow
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AchievementCell.identifier, for: indexPath) as? AchievementCell else {
            fatalError("Unable to dequeue AchievementCell")
        }
        let achievement = userAchievements[indexPath.item]
        cell.configure(with: achievement)
        return cell
    }
}

// MARK: - UITableViewDataSource
// Объявляем соответствие протоколу ЗДЕСЬ
extension PersonViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let countToShow = min(feedEvents.count, 3)
        return countToShow
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedEventCell.identifier, for: indexPath) as? FeedEventCell else {
            fatalError("Unable to dequeue FeedEventCell")
        }
        let event = feedEvents[indexPath.row]
        cell.configure(with: event, dateFormatter: dateFormatter)
        return cell
    }
}

// MARK: - UIImagePickerControllerDelegate Methods

extension PersonViewController {
    
    // Метод вызывается, когда пользователь выбрал изображение (или видео)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Пытаемся получить выбранное изображение
        // Сначала проверяем отредактированное изображение (если allowsEditing = true)
        // Иначе берем оригинальное
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            // Закрываем пикер в любом случае
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        // 1. Обновляем UI немедленно
        avatarImageView.image = selectedImage
        
        // 2. Сохраняем изображение в файл
        // Получаем ID текущего пользователя для имени файла
        let userID = DataManager.shared.getCurrentUserProfile().userID
        if saveAvatarImage(selectedImage, forUserID: userID) {
        } else {
            // Можно показать пользователю сообщение об ошибке, если сохранение критично
        }

        // 3. Закрываем контроллер выбора изображения
        picker.dismiss(animated: true, completion: nil)
    }

    // Метод вызывается, если пользователь нажал "Отмена"
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Просто закрываем контроллер выбора
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Avatar File Management Helpers

extension PersonViewController {

    /// Получает URL для сохранения/загрузки аватара пользователя.
    /// - Parameter userID: Уникальный идентификатор пользователя.
    /// - Returns: Полный URL файла аватара в папке Documents или nil, если не удалось получить папку Documents.
    private func getAvatarFileURL(forUserID userID: UUID) -> URL? {
        // Получаем URL папки Documents для текущего пользователя
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        // Формируем имя файла, используя UUID пользователя, чтобы оно было уникальным
        // Используем .png как формат по умолчанию
        let fileName = "avatar_\(userID.uuidString).png"
        // Создаем полный URL, добавляя имя файла к пути папки Documents
        return documentsDirectory.appendingPathComponent(fileName)
    }

    /// Сохраняет изображение аватара в папку Documents.
    /// - Parameters:
    ///   - image: Изображение для сохранения.
    ///   - userID: ID пользователя, для которого сохраняется аватар.
    /// - Returns: `true` при успешном сохранении, `false` при ошибке.
    private func saveAvatarImage(_ image: UIImage, forUserID userID: UUID) -> Bool {
        // Получаем URL файла, куда будем сохранять
        guard let fileURL = getAvatarFileURL(forUserID: userID) else {
            return false
        }

        // Конвертируем UIImage в данные в формате PNG
        // PNG сохраняет прозрачность и обычно без потерь качества
        guard let imageData = image.pngData() else {
            return false
        }

        // Пытаемся записать данные в файл
        do {
            // Атомарная запись означает, что файл сначала полностью записывается во временное место,
            // а затем перемещается в конечное, что безопаснее при сбоях.
            try imageData.write(to: fileURL, options: .atomic)
            return true
        } catch {
            // Если произошла ошибка при записи, выводим ее в лог
            return false
        }
    }

    /// Загружает изображение аватара из папки Documents.
    /// - Parameter userID: ID пользователя, чей аватар нужно загрузить.
    /// - Returns: Загруженное изображение `UIImage` или `nil`, если файл не найден или произошла ошибка.
    private func loadAvatarImage(forUserID userID: UUID) -> UIImage? {
        // Получаем URL файла, откуда будем загружать
        guard let fileURL = getAvatarFileURL(forUserID: userID) else {
            return nil
        }

        // Проверяем, существует ли файл по указанному пути
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Пытаемся загрузить данные из файла
        do {
            let imageData = try Data(contentsOf: fileURL)
            // Пытаемся создать UIImage из загруженных данных
            if let image = UIImage(data: imageData) {
                return image
            } else {
                return nil
            }
        } catch {
            // Если произошла ошибка при чтении данных из файла
            return nil
        }
    }
}

// MARK: - Chart Helper Classes & Functions
extension PersonViewController {
    
    // MARK: - Форматтеры для Radar Chart
    // Форматтер для оси X (названия статов) - используем IndexAxisValueFormatter стандартный
    // Раскомментируем этот класс, он нужен для начальной настройки
    class RadarChartXAxisValueFormatter: DGCharts.IndexAxisValueFormatter {
        // Оставляем пустым, будем использовать стандартный IndexAxisValueFormatter
    }

    // Форматтер для оси Y (значения 0-100)
    class YAxisValueFormatter: AxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            // Показываем значения кратные 20 (0, 20, 40, 60, 80, 100)
            if value.truncatingRemainder(dividingBy: 20) == 0 {
                return String(format: "%.0f", value)
            } else {
                return "" // Не показываем другие метки
            }
        }
    }

    // MARK: - Stat String Generation
    /// Создает NSAttributedString для отображения БАЗОВЫХ атрибутов.
    private func createBaseAttributesString(from profile: UserProfile) -> NSAttributedString {
        // Собираем базовые атрибуты из профиля, используя сокращения
        let attributes: [(name: String, value: Int)] = [
            ("STR", profile.strength),
            ("CON", profile.constitution),
            ("ACC", profile.accuracy),
            ("SPD", profile.speed),
            ("BAL", profile.balance),
            ("FLX", profile.flexibility)
        ]
        
        // Стиль параграфа
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        // Атрибуты текста
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: paragraphStyle
        ]

        let finalAttributedString = NSMutableAttributedString()

        for (index, attribute) in attributes.enumerated() {
            // Добавляем имя и значение атрибута
            let attributeString = "\(attribute.name): \(attribute.value)"
            finalAttributedString.append(NSAttributedString(string: attributeString, attributes: regularAttributes))
            
            // Добавляем перенос строки
            if index < attributes.count - 1 {
                finalAttributedString.append(NSAttributedString(string: "\n", attributes: regularAttributes))
            }
        }
        
        return finalAttributedString
    }

    // MARK: - Radar Chart Update
    /// Обновляет данные и внешний вид Radar Chart на основе профиля пользователя.
    private func updateRadarChart(with profile: UserProfile) {
        // 1. Определяем главные статы для отображения
        let stats = [
            ("PWR", profile.power), // Мощь
            ("CTL", profile.control), // Контроль
            ("END", profile.endurance), // Стойкость
            ("AGI", profile.agility), // Проворство
            ("MOB", profile.mobility), // Мобильность
            ("WLN", profile.wellness)  // Здоровье
        ]

        // 2. Готовим данные для графика
        // Каждый стат - это RadarChartDataEntry. Значение должно быть Double.
        // Главные статы теперь в диапазоне ~0-40. НЕ НУЖНО делить на 2.
        // Просто конвертируем в Double
        let entries = stats.map { DGCharts.RadarChartDataEntry(value: Double($0.1)) } 

        // 3. Создаем набор данных (DataSet)
        // Указываем модуль для типа RadarChartDataSet
        let dataSet = DGCharts.RadarChartDataSet(entries: entries, label: "Главные Статы")
        dataSet.lineWidth = 2
        // Устанавливаем цвет линии и заливки
        let dataSetColor = UIColor.systemGreen
        dataSet.colors = [dataSetColor]
        dataSet.fillColor = dataSetColor
        dataSet.drawFilledEnabled = true // Включаем заливку области
        dataSet.fillAlpha = 0.5 // Прозрачность заливки
        dataSet.drawValuesEnabled = false // Не показываем значения над точками
        dataSet.valueFont = .systemFont(ofSize: 10)
        dataSet.valueTextColor = .white

        // 4. Создаем объект данных для графика
        // Указываем модуль для типа RadarChartData
        let data = DGCharts.RadarChartData(dataSets: [dataSet])
        data.setValueTextColor(.white)
        data.setValueFont(.systemFont(ofSize: 8, weight: .light))
        
        // 5. Настраиваем оси X (названия статов)
        // Убедимся, что порядок совпадает с порядком в `stats`
        let statNames = stats.map { $0.0 }
        // Указываем модуль для типа IndexAxisValueFormatter
        radarChartView.xAxis.valueFormatter = DGCharts.IndexAxisValueFormatter(values: statNames)

        // 6. Устанавливаем данные в график и обновляем его
        radarChartView.data = data
        radarChartView.notifyDataSetChanged() // Уведомляем об изменениях

    }
}
