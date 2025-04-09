import UIKit

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
class PersonViewController: UIViewController, UIGestureRecognizerDelegate {

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
    private lazy var radarChartView: RadarChartView = {
        let chartView = RadarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    private lazy var statsDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.attributedText = createStatsAttributedString()
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
    }
    
    // Отладочный Print
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("--- PersonVC viewDidLayoutSubviews ---") // Уточним имя контроллера
        print("achievementsContainerView height: \(achievementsContainerView.frame.height)")
        print("achievementsCollectionView height: \(achievementsCollectionView.frame.height), contentSize: \(achievementsCollectionView.contentSize.height)")
        print("feedContainerView height: \(feedContainerView.frame.height)")
        print("feedTableView height: \(feedTableView.frame.height), contentSize: \(feedTableView.contentSize.height)")
        print("---------------------------------------")
    }

    // --- Обновление UI при появлении ---
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("--- PersonVC viewWillAppear ---")
        updateProfileDisplay() // Обновляем данные профиля перед показом
    }

    // --- Обновление данных профиля ---
    /// Загружает актуальные данные из DataManager и обновляет UI элементы профиля.
    private func updateProfileDisplay() {
        print("--- PersonVC updateProfileDisplay: Запрос данных из DataManager ---")
        // 1. Получаем самый свежий профиль пользователя
        let profile = DataManager.shared.getCurrentUserProfile()
        print("--- PersonVC updateProfileDisplay: Получен профиль: Уровень \(profile.level), XP \(profile.currentXP)/\(profile.xpToNextLevel), Ранг \(profile.rank.rawValue) ---")

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
            print("--- PersonVC updateProfileDisplay: ВНИМАНИЕ! xpToNextLevel равен 0. Прогресс установлен в 0. ---")
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
        // avatarImageView.image = ... 

        print("--- PersonVC updateProfileDisplay: UI обновлен (Уровень: \(levelLabel.text ?? "nil"), XP: \(xpLabel.text ?? "nil"), Прогресс: \(xpProgressView.progress)) ---")
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
        print("Нажата область заголовка/карточки достижений")
        delegate?.personViewControllerDidRequestShowAllAchievements(self)
    }

    @objc private func feedHeaderTapped() {
        print("Нажата область заголовка/карточки ленты")
        delegate?.personViewControllerDidRequestShowAllFeed(self)
    }

    // --- UIGestureRecognizerDelegate ---
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UICollectionViewDataSource
// Объявляем соответствие протоколу ЗДЕСЬ
extension PersonViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let countToShow = min(userAchievements.count, 12)
        print("Количество ачивок для отображения: \(countToShow) (из \(userAchievements.count))")
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
        print("Feed UITableView: numberOfRowsInSection возвращает \(countToShow) (из \(feedEvents.count))")
        return countToShow
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Feed UITableView: Запрос ячейки для строки \(indexPath.row)")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedEventCell.identifier, for: indexPath) as? FeedEventCell else {
            fatalError("Unable to dequeue FeedEventCell")
        }
        let event = feedEvents[indexPath.row]
        cell.configure(with: event, dateFormatter: dateFormatter)
        return cell
    }
}

// НОВАЯ ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ для статов
private func createStatsAttributedString() -> NSAttributedString {
    let stats: [(name: String, value: Int, change: Int)] = [
        ("STR", 80, 2),
        ("DEX", 60, -1),
        ("CON", 70, 0),
        ("INT", 50, 3),
        ("LCK", 90, -2)
    ]
    
    // Создаем стиль параграфа с увеличенным межстрочным интервалом
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4 // Подбери значение по вкусу
    
    let regularAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.lightGray,
        .paragraphStyle: paragraphStyle // Добавляем стиль параграфа
    ]
    let greenAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.systemGreen,
        .paragraphStyle: paragraphStyle
    ]
    let redAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.systemRed,
        .paragraphStyle: paragraphStyle
    ]

    let finalAttributedString = NSMutableAttributedString()

    for (index, stat) in stats.enumerated() {
        // Добавляем имя стата и значение
        let baseString = "\(stat.name): \(stat.value)"
        finalAttributedString.append(NSAttributedString(string: baseString, attributes: regularAttributes))
        
        // Добавляем изменение
        if stat.change > 0 {
            let changeString = " +\(stat.change)"
            finalAttributedString.append(NSAttributedString(string: changeString, attributes: greenAttributes))
        } else if stat.change < 0 {
             let changeString = " \(stat.change)" // Минус уже есть
             finalAttributedString.append(NSAttributedString(string: changeString, attributes: redAttributes))
        }
        // Для 0 ничего не добавляем

        // Добавляем перенос строки, если это не последний стат
        if index < stats.count - 1 {
            finalAttributedString.append(NSAttributedString(string: "\n", attributes: regularAttributes))
        }
    }
    
    return finalAttributedString
}
