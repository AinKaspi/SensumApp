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

    // KVO Свойства
    private var feedTableViewHeightConstraint: NSLayoutConstraint?
    private var achievementsCollectionViewHeightConstraint: NSLayoutConstraint?
    private var tableViewContentSizeObserver: NSKeyValueObservation?
    private var collectionViewContentSizeObserver: NSKeyValueObservation?


    // --- UI Элементы (Lazy Vars) ---

    // Контейнеры
    private lazy var profileInfoContainerView: UIView = createContainerView()
    private lazy var achievementsContainerView: UIView = createContainerView()
    private lazy var feedContainerView: UIView = createContainerView()

    // Элементы профиля (ПОЛНЫЙ КОД)
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .lightGray // Временно серый фон
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50 // Делаем круглым
        return imageView
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Имя Игрока"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Уровень: 1"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    private lazy var rankLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ранг: E / Новобранец"
        label.textColor = .systemOrange
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    // Элементы достижений
    private lazy var achievementsTitleLabel: UILabel = createTitleLabel(text: "Достижения")
    private lazy var achievementsChevronImageView: UIImageView = createChevronImageView()
    private lazy var achievementsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 45, height: 45)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        let tableView = UITableView()
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
        setupKVO()
    }
    
    // Отладочный Print
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("--- viewDidLayoutSubviews ---")
        print("achievementsContainerView height: \(achievementsContainerView.frame.height)")
        print("achievementsCollectionView height: \(achievementsCollectionView.frame.height), contentSize: \(achievementsCollectionView.contentSize.height)")
        print("achievementsCollectionViewHeightConstraint constant: \(achievementsCollectionViewHeightConstraint?.constant ?? -1)")
        print("feedContainerView height: \(feedContainerView.frame.height)")
        print("feedTableView height: \(feedTableView.frame.height), contentSize: \(feedTableView.contentSize.height)")
        print("feedTableViewHeightConstraint constant: \(feedTableViewHeightConstraint?.constant ?? -1)")
        print("-----------------------------")
    }

    // Настройка Views
    private func setupViews() {
        view.addSubview(profileInfoContainerView)
        view.addSubview(achievementsContainerView)
        view.addSubview(feedContainerView)

        profileInfoContainerView.addSubview(avatarImageView)
        profileInfoContainerView.addSubview(nameLabel)
        profileInfoContainerView.addSubview(levelLabel)
        profileInfoContainerView.addSubview(rankLabel)

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
        let verticalSpacing: CGFloat = 20
        let profileContainerPadding: CGFloat = 15
        let cardInternalPadding: CGFloat = 12

        // Создаем констрейнты высоты для ОБОИХ списков
        achievementsCollectionViewHeightConstraint = achievementsCollectionView.heightAnchor.constraint(equalToConstant: 1) // Начинаем с 1
        feedTableViewHeightConstraint = feedTableView.heightAnchor.constraint(equalToConstant: 1) // Начинаем с 1

        NSLayoutConstraint.activate([
            // profileInfoContainerView
            profileInfoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalSpacing),
            profileInfoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            profileInfoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            // Высота определяется rankLabel.bottom
            rankLabel.bottomAnchor.constraint(equalTo: profileInfoContainerView.bottomAnchor, constant: -profileContainerPadding),

            // Элементы внутри profileInfoContainerView
            avatarImageView.topAnchor.constraint(equalTo: profileInfoContainerView.topAnchor, constant: profileContainerPadding),
            avatarImageView.centerXAnchor.constraint(equalTo: profileInfoContainerView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: profileContainerPadding),
            nameLabel.leadingAnchor.constraint(equalTo: profileInfoContainerView.leadingAnchor, constant: profileContainerPadding),
            nameLabel.trailingAnchor.constraint(equalTo: profileInfoContainerView.trailingAnchor, constant: -profileContainerPadding),
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: profileInfoContainerView.leadingAnchor, constant: profileContainerPadding),
            levelLabel.trailingAnchor.constraint(equalTo: profileInfoContainerView.trailingAnchor, constant: -profileContainerPadding),
            rankLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
            rankLabel.leadingAnchor.constraint(equalTo: profileInfoContainerView.leadingAnchor, constant: profileContainerPadding),
            rankLabel.trailingAnchor.constraint(equalTo: profileInfoContainerView.trailingAnchor, constant: -profileContainerPadding),
            // rankLabel.bottomAnchor уже привязан выше

            // achievementsContainerView
            achievementsContainerView.topAnchor.constraint(equalTo: profileInfoContainerView.bottomAnchor, constant: verticalSpacing),
            achievementsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            achievementsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            // НЕТ ФИКСИРОВАННОЙ ВЫСОТЫ

            // Заголовок и шеврон внутри achievementsContainerView
            achievementsTitleLabel.topAnchor.constraint(equalTo: achievementsContainerView.topAnchor, constant: cardInternalPadding),
            achievementsTitleLabel.leadingAnchor.constraint(equalTo: achievementsContainerView.leadingAnchor, constant: cardInternalPadding),
            achievementsChevronImageView.centerYAnchor.constraint(equalTo: achievementsTitleLabel.centerYAnchor),
            achievementsChevronImageView.trailingAnchor.constraint(equalTo: achievementsContainerView.trailingAnchor, constant: -cardInternalPadding),
            achievementsChevronImageView.widthAnchor.constraint(equalToConstant: 10),
            achievementsChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            achievementsTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: achievementsChevronImageView.leadingAnchor, constant: -8),

            // achievementsCollectionView внутри achievementsContainerView
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsTitleLabel.bottomAnchor, constant: cardInternalPadding / 2),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: achievementsContainerView.leadingAnchor, constant: cardInternalPadding),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: achievementsContainerView.trailingAnchor, constant: -cardInternalPadding),
            // Низ КОНТЕЙНЕРА привязан к низу КОЛЛЕКЦИИ (с отступом)
            achievementsContainerView.bottomAnchor.constraint(equalTo: achievementsCollectionView.bottomAnchor, constant: cardInternalPadding),
            // Активируем явный констрейнт высоты КОЛЛЕКЦИИ
            achievementsCollectionViewHeightConstraint!,

            // feedContainerView
            feedContainerView.topAnchor.constraint(equalTo: achievementsContainerView.bottomAnchor, constant: verticalSpacing),
            feedContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            feedContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            // НЕТ ФИКСИРОВАННОЙ ВЫСОТЫ
            // Привязываем низ ПОСЛЕДНЕГО контейнера к низу Safe Area (опционально)
            feedContainerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -verticalSpacing),

            // Заголовок и шеврон внутри feedContainerView
            feedTitleLabel.topAnchor.constraint(equalTo: feedContainerView.topAnchor, constant: cardInternalPadding),
            feedTitleLabel.leadingAnchor.constraint(equalTo: feedContainerView.leadingAnchor, constant: cardInternalPadding),
            feedChevronImageView.centerYAnchor.constraint(equalTo: feedTitleLabel.centerYAnchor),
            feedChevronImageView.trailingAnchor.constraint(equalTo: feedContainerView.trailingAnchor, constant: -cardInternalPadding),
            feedChevronImageView.widthAnchor.constraint(equalToConstant: 10),
            feedChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            feedTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: feedChevronImageView.leadingAnchor, constant: -8),

            // feedTableView внутри feedContainerView
            feedTableView.topAnchor.constraint(equalTo: feedTitleLabel.bottomAnchor, constant: cardInternalPadding / 2),
            feedTableView.leadingAnchor.constraint(equalTo: feedContainerView.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: feedContainerView.trailingAnchor),
            // Низ КОНТЕЙНЕРА привязан к низу ТАБЛИЦЫ (с отступом)
            feedContainerView.bottomAnchor.constraint(equalTo: feedTableView.bottomAnchor, constant: cardInternalPadding),
            // Активируем ЯВНЫЙ констрейнт высоты для ТАБЛИЦЫ
            feedTableViewHeightConstraint!
        ])
    }

    // --- KVO Настройка (теперь для обоих) ---
    private func setupKVO() {
        // Наблюдатель для Таблицы Ленты
        tableViewContentSizeObserver = feedTableView.observe(\.contentSize, options: [.old, .new]) { [weak self] tableView, change in
             guard let self = self, let newSize = change.newValue else { return }
             let oldHeight = self.feedTableViewHeightConstraint?.constant ?? 0
             guard abs(newSize.height - oldHeight) > 0.1, newSize.height >= 1 else { return }

             self.feedTableViewHeightConstraint?.constant = newSize.height
             print("KVO Feed: Обновлена высота feedTableView до \(newSize.height)")
             DispatchQueue.main.async { self.view.layoutIfNeeded() }
        }
        print("KVO Feed: Обсервер для contentSize добавлен")

        // Наблюдатель для Коллекции Достижений
        collectionViewContentSizeObserver = achievementsCollectionView.observe(\.contentSize, options: [.old, .new]) { [weak self] collectionView, change in
             guard let self = self, let newSize = change.newValue else { return }
             let oldHeight = self.achievementsCollectionViewHeightConstraint?.constant ?? 0
             guard abs(newSize.height - oldHeight) > 0.1, newSize.height >= 1 else { return }

             self.achievementsCollectionViewHeightConstraint?.constant = newSize.height
             print("KVO Achievements: Обновлена высота achievementsCollectionView до \(newSize.height)")
             DispatchQueue.main.async { self.view.layoutIfNeeded() }
        }
         print("KVO Achievements: Обсервер для contentSize добавлен")
    }


    // --- Обработчики нажатий ---
    @objc private func achievementsHeaderTapped() {
        print("Нажата область заголовка/карточки достижений")
        // delegate?.personViewControllerDidRequestShowAllAchievements(self)
    }

    @objc private func feedHeaderTapped() {
        print("Нажата область заголовка/карточки ленты")
        // delegate?.personViewControllerDidRequestShowAllFeed(self)
    }

    // --- UIGestureRecognizerDelegate ---
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // --- deinit ---
     deinit {
         // Обнуляем оба наблюдателя
         tableViewContentSizeObserver = nil
         collectionViewContentSizeObserver = nil
         print("PersonViewController deinit")
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
