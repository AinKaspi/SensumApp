import UIKit
import Combine // Добавляем для биндингов
import Kingfisher // <-- Импортируем Kingfisher
// TODO: Импортировать библиотеку для загрузки изображений (Kingfisher, SDWebImage, Nuke)?
// Импортируем PhotosUI для PHPicker
import PhotosUI // <-- Добавляем импорт для PHPicker

// Добавляем делегат для кнопки Выхода
protocol UserProfileFeedViewControllerDelegate: AnyObject {
    func didTapEditProfileButton()
    func didTapFollowButton() // (Будет использоваться, когда isCurrentUser=false)
    func didTapMessageButton() // (Будет использоваться, когда isCurrentUser=false)
    func didRequestSignOut() // Новый метод
    // Удаляем делегат для кнопки New Program
    // func didTapNewProgramButton()
}

// Обновляем: используем PHPickerViewControllerDelegate и добавляем CreatePostViewControllerDelegate
// Убираем лишние протоколы из объявления класса, они будут в extensions
// Consolidated protocol conformances here
class UserProfileFeedViewController: UIViewController, PHPickerViewControllerDelegate, CreatePostViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {

    // Добавляем ViewModel
    var viewModel: UserProfileFeedViewModel! // Используем !, т.к. он будет инжектирован координатором
    // Добавляем слабого делегата
    weak var delegate: UserProfileFeedViewControllerDelegate?
    private var cancellables = Set<AnyCancellable>() // Для хранения подписок Combine

    // TODO: Добавить ViewModel для загрузки данных профиля и постов

    // MARK: - UI Elements
    
    // Новая верхняя панель
    private lazy var topBarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = .blue // Для отладки
        return view
    }()
    
    private lazy var topBarUsernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.text = "username"
        return label
    }()
    
    private lazy var topBarSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(topBarSettingsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var topBarMessagesButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // TODO: Использовать иконку с индикатором? Или кастомную view?
        button.setImage(UIImage(systemName: "message"), for: .normal) 
        button.tintColor = .white
        button.addTarget(self, action: #selector(topBarChatsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Добавляем ScrollView
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    // Добавляем contentWrapperView
    private let contentWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = .orange // Для отладки
        return view
    }()
    
    // --- Шапка Профиля ---
    private lazy var profileHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = .darkGray // Для отладки
        return view
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 55 // Увеличиваем радиус
        imageView.backgroundColor = .lightGray // Placeholder
        // TODO: Загрузка изображения из viewModel.userProfile.avatarURL
        imageView.image = UIImage(systemName: "person.circle.fill") // Placeholder
        imageView.tintColor = .darkGray
        return imageView
    }()
    
    // Стеки для статов
    private func createStatLabel(value: String = "-", label: String) -> UIStackView {
        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .left
        valueLabel.text = value
        
        let textLabel = UILabel()
        textLabel.font = .systemFont(ofSize: 12)
        textLabel.textColor = .lightGray
        textLabel.textAlignment = .left
        textLabel.text = label
        
        let stack = UIStackView(arrangedSubviews: [valueLabel, textLabel])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }
    
    private lazy var postsStatStack: UIStackView = createStatLabel(label: "Posts")
    private lazy var followersStatStack: UIStackView = createStatLabel(label: "Followers")
    // Убираем Following
    // private lazy var followingStatStack: UIStackView = createStatLabel(label: "Following")
    // Добавляем Likes
    private lazy var likesStatStack: UIStackView = createStatLabel(label: "Likes")
    
    // Создаем spacer views для statsStackView
    private func createSpacerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }
    private lazy var spacer1 = createSpacerView()
    private lazy var spacer2 = createSpacerView()
    // Убираем третий spacer
    // private lazy var spacer3 = createSpacerView()
    
    private lazy var statsStackView: UIStackView = {
        // Убираем subviews из инициализатора, будем добавлять в setupViews
        let stack = UIStackView() 
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill // Используем fill, чтобы spacer могли растягиваться
        stack.spacing = 0 // Убираем фиксированный spacing
        return stack
    }()
    
    // Контейнер для имени и статов (для центрирования)
    private lazy var nameAndStatsContainer: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        // Увеличиваем зазор между именем и статами еще раз
        stack.spacing = 11 // Было 8
        stack.alignment = .fill // Новое: заставляем дочерние view растягиваться
        return stack
    }()
    
    // Имя пользователя (Display Name)
    private lazy var displayNameLabel: UILabel = { // Переименовываем usernameLabel
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        // Увеличиваем шрифт еще немного
        label.font = .systemFont(ofSize: 22, weight: .bold) // Было 20
        label.textColor = .white
        label.text = "Display Name" // Меняем плейсхолдер
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.numberOfLines = 0 // Позволяем переносить статус
        label.text = "Status placeholder..."
        return label
    }()

    // --- Кнопки под статусом ---
    // Стек для кнопок Edit/Follow/Message
    private lazy var actionButtonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Edit Profile", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black // Новый фон
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12) // Было top/bottom 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        // TODO: Скрывать/показывать в зависимости от viewModel.isCurrentUser
        return button
    }()
    
    // Новая кнопка "New Post"
    private lazy var newPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("New Post", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black // Новый фон
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12) // Было top/bottom 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(newPostButtonTapped), for: .touchUpInside)
        // TODO: Показывать только если isCurrentUser?
        return button
    }()
    
    // Добавляем кнопки Follow и Message
    private lazy var followButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Follow", for: .normal) // Начальный текст
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        // Стиль будет настраиваться в configureFollowButton
        return button
    }()
    
    private lazy var messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Message", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // --- Переключатель Контента --- 
    /*
    private lazy var contentSegmentedControl: UISegmentedControl = {
        let items = ["Posts", "Programs"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0 // По умолчанию выбраны посты
        control.backgroundColor = .darkGray // Цвет фона
        control.selectedSegmentTintColor = .systemBlue // Цвет выбранного сегмента
        control.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        return control
    }()
    */
    
    // --- Сетка Постов ---
    lazy var postsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 3 // Меньше расстояние между строками
        layout.minimumInteritemSpacing = 3 // Меньше расстояние между ячейками
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // Убираем отступы секции
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.register(PostGridCell.self, forCellWithReuseIdentifier: PostGridCell.identifier)
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "LoadingFooter")
        return collectionView
    }()

    // Удаляем Placeholder View для вкладки Programs
    /*
    private lazy var programsPlaceholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear // или .black
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Программы тренировок (скоро)"
        label.textColor = .lightGray
        label.textAlignment = .center
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        view.isHidden = true // Скрыт по умолчанию
        return view
    }()
    */

    // Add missing UI elements
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true // Hidden by default
        return label
    }()

    // Moved height constraint property inside the class
    private lazy var collectionViewHeightConstraint: NSLayoutConstraint = {
        postsCollectionView.heightAnchor.constraint(equalToConstant: 0) // Начальная высота 0
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Устанавливаем фон основного view
        view.backgroundColor = .black
        
        // Явно задаем translatesAutoresizingMaskIntoConstraints
        postsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        setupViews()
        setupConstraints()
        bindViewModel()
        
        // Настройка делегатов
        postsCollectionView.dataSource = self
        postsCollectionView.delegate = self
        postsCollectionView.prefetchDataSource = self
        
        // Проверка, является ли это профилем текущего пользователя
        setupActionsForUserType()
        
        if viewModel.isCurrentUser {
            setupCurrentUserTopBar()
        } else {
            setupOtherUserTopBar()
        }
        
        // Загружаем данные, если это необходимо
        if viewModel.userProfile == nil {
            viewModel.fetchAllUserData()
        }
    }

    // MARK: - Setup UI
    private func setupViews() {
        // Добавляем topBarView НАД scrollView
        view.addSubview(topBarView)
        topBarView.addSubview(topBarUsernameLabel)
        topBarView.addSubview(topBarSettingsButton)
        topBarView.addSubview(topBarMessagesButton)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentWrapperView)

        // Добавляем элементы шапки в contentWrapperView
        contentWrapperView.addSubview(profileHeaderView)
        // Элементы ДОЛЖНЫ добавляться в profileHeaderView, а не напрямую в contentWrapperView
        profileHeaderView.addSubview(avatarImageView)
        profileHeaderView.addSubview(statusLabel)
        profileHeaderView.addSubview(actionButtonsStackView)
        
        // Добавляем контейнер с именем и статами
        profileHeaderView.addSubview(nameAndStatsContainer)
        // Добавляем имя и статы в их контейнер
        nameAndStatsContainer.addArrangedSubview(displayNameLabel)
        nameAndStatsContainer.addArrangedSubview(statsStackView)
        
        // Добавляем элементы и spacer'ы в statsStackView
        statsStackView.addArrangedSubview(postsStatStack)
        statsStackView.addArrangedSubview(spacer1)
        statsStackView.addArrangedSubview(likesStatStack)
        statsStackView.addArrangedSubview(spacer2)
        statsStackView.addArrangedSubview(followersStatStack)
        
        // Добавляем кнопки в стек
        configureActionButtons(isCurrentUser: self.viewModel.isCurrentUser) // Этот метод добавит кнопки в actionButtonsStackView

        // Удаляем Segmented Control
        // contentWrapperView.addSubview(contentSegmentedControl)

        // Добавляем CollectionView в contentWrapperView ПОД шапкой
        contentWrapperView.addSubview(postsCollectionView)

        // Удаляем Placeholder View
        // contentWrapperView.addSubview(programsPlaceholderView)

        // Добавляем индикатор загрузки и сообщение об ошибке поверх всего scrollView
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
    }

    private func setupConstraints() {
        let padding: CGFloat = 10 // Новый основной отступ = 10
        let topBarHeight: CGFloat = 44 // Высота верхней панели
        let topBarButtonSize: CGFloat = 30 // Размер иконок вверху
        // let statsSpacing: CGFloat = 5 // Не используется напрямую
        // let avatarSize: CGFloat = 100 // Старый размер
        let avatarSize: CGFloat = 110 // Новый увеличенный размер

        // Констрейнты для topBarView
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            topBarView.heightAnchor.constraint(equalToConstant: topBarHeight),

            // Имя пользователя слева (с небольшим отступом от края панели)
            topBarUsernameLabel.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 4),
            topBarUsernameLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),

            // Кнопка настроек сразу справа от имени
            topBarSettingsButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            topBarSettingsButton.leadingAnchor.constraint(equalTo: topBarUsernameLabel.trailingAnchor, constant: 4),
            topBarSettingsButton.widthAnchor.constraint(equalToConstant: topBarButtonSize),
            topBarSettingsButton.heightAnchor.constraint(equalToConstant: topBarButtonSize),

            // Кнопка сообщений справа
            topBarMessagesButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            topBarMessagesButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),
            topBarMessagesButton.leadingAnchor.constraint(greaterThanOrEqualTo: topBarSettingsButton.trailingAnchor, constant: 8),
            topBarMessagesButton.widthAnchor.constraint(equalToConstant: topBarButtonSize),
            topBarMessagesButton.heightAnchor.constraint(equalToConstant: topBarButtonSize),
        ])

        // ScrollView и ContentWrapperView (ScrollView теперь начинается под topBarView с отступом)
        NSLayoutConstraint.activate([
            // Добавляем отступ 5pt
            scrollView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 5),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentWrapperView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentWrapperView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentWrapperView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentWrapperView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentWrapperView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor) // Ширина равна ширине scrollView
        ])

        // Элементы в profileHeaderView (НОВАЯ ВЕРСТКА)
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: contentWrapperView.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            // Нижний край profileHeaderView будет определяться низом actionButtonsStackView

            // Аватар (слева)
            avatarImageView.topAnchor.constraint(equalTo: profileHeaderView.topAnchor, constant: padding),
            avatarImageView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize), // Новый размер
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize), // Новый размер

            // Констрейнты для nameAndStatsContainer
            nameAndStatsContainer.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor), // Центрируем по вертикали с аватаром
            nameAndStatsContainer.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: padding + 13), // Было padding + 3
            nameAndStatsContainer.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding), // До правого края

            // Добавляем констрейнт для равенства ширины spacer'ов
            spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor),
            // Убираем равенство с spacer3
            // spacer2.widthAnchor.constraint(equalTo: spacer3.widthAnchor),

            // Статус (под аватаром и статами)
            statusLabel.topAnchor.constraint(greaterThanOrEqualTo: avatarImageView.bottomAnchor, constant: padding + 5),
            statusLabel.topAnchor.constraint(greaterThanOrEqualTo: nameAndStatsContainer.bottomAnchor, constant: padding + 5), // Привязка к контейнеру
            statusLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            statusLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),

            // Стек кнопок действий (под статусом) (используем новый padding = 10)
            actionButtonsStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: padding + 10),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),
            // Привязываем низ хедера к низу стека кнопок
            profileHeaderView.bottomAnchor.constraint(equalTo: actionButtonsStackView.bottomAnchor, constant: padding)
        ])

        // Обновляем констрейнты CollectionView (верх привязан к низу profileHeaderView) (используем новый padding = 10)
        NSLayoutConstraint.activate([
            postsCollectionView.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: padding + 10), 
            postsCollectionView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            postsCollectionView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            // Важно: Привязываем низ CollectionView к низу contentWrapperView
            // Это позволит contentWrapperView растягиваться по высоте контента
            postsCollectionView.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -padding),
            // Добавляем констрейнт высоты для CollectionView, который будет обновляться
            collectionViewHeightConstraint
        ])

        // Индикатор загрузки и ошибка (поверх scrollView)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Сдвигаем индикатор ниже topBarView
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: topBarHeight / 2),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Старая позиция
            errorLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10), // Под индикатором
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: padding),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -padding)
        ])
    }

    // Новый метод для установки contentInset
    private func setupContentInset() {
        // Рассчитываем отступ: Высота TopMenu (55) + Отступ TopMenu от Safe Area (15) + Дополнительный зазор (10)
        // let topInset: CGFloat = 55.0 + 15.0 + 10.0 // Итого = 80 - Убираем
        // Обнуляем contentInset, т.к. scrollView теперь начинается под topBarView
        scrollView.contentInset = .zero 
        scrollView.scrollIndicatorInsets = .zero
        // Начальное смещение ставим в 0
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    // MARK: - Bindings
    
    private func bindViewModel() {
        // Подписываемся на изменения в профиле пользователя
        viewModel.$userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self, let user = user else { return }
                self.setupUserProfile(with: user)
                print("UserProfileFeedVC: Получен обновленный профиль пользователя")
            }
            .store(in: &cancellables)
        
        // Подписываемся на изменения в общем количестве лайков
        viewModel.$totalLikes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] totalLikes in
                guard let self = self, let totalLikes = totalLikes else { return }
                self.setupTotalLikes(count: totalLikes)
                print("UserProfileFeedVC: Получено обновленное количество лайков")
            }
            .store(in: &cancellables)
        
        // Подписываемся на изменения в данных о прогрессе
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressData in
                guard let self = self, let progressData = progressData else { return }
                self.setupProgressData(progressData)
                print("UserProfileFeedVC: Получены обновленные данные о прогрессе")
            }
            .store(in: &cancellables)
        
        // Подписываемся на изменения в списке постов
        viewModel.$userPosts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                guard let self = self else { return }
                print("UserProfileFeedVC: Получено \(posts.count) постов")
                // Сначала обновляем высоту, потом перезагружаем данные
                self.updateCollectionViewHeight(postCount: posts.count)
                self.postsCollectionView.reloadData()
            }
            .store(in: &cancellables)
        
        // Подписываемся на изменения в статусе подписки (если это не текущий пользователь)
        if !viewModel.isCurrentUser {
            viewModel.$isFollowing
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isFollowing in
                    guard let self = self else { return }
                    self.updateFollowButton(isFollowing: isFollowing)
                    print("UserProfileFeedVC: Статус подписки обновлен: \(isFollowing)")
                }
                .store(in: &cancellables)
        }
        
        // Подписываемся на изменения состояния загрузки постов для обновления футера
        viewModel.$isLoadingPosts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                // Если изменилось состояние загрузки, нужно обновить размер футера
                if let layout = self.postsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    layout.invalidateLayout()
                }
                // Сделаем видимым индикатор загрузки, если загрузка идет
                if isLoading {
                    // Прокручиваем, чтобы показать индикатор загрузки, если загружаются дополнительные посты
                    if !self.viewModel.userPosts.isEmpty {
                        let bottomOffset = CGPoint(
                            x: 0,
                            y: self.postsCollectionView.contentSize.height - self.postsCollectionView.bounds.height + self.postsCollectionView.contentInset.bottom
                        )
                        if bottomOffset.y > 0 {
                            self.postsCollectionView.setContentOffset(bottomOffset, animated: true)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Button Configuration
    
    // Настраивает видимость кнопок в topBarView
    private func configureTopBarButtons(isCurrentUser: Bool) {
        topBarSettingsButton.isHidden = !isCurrentUser
        topBarMessagesButton.isHidden = false // Кнопка чатов всегда видна
    }
    
    // Настраивает кнопки в actionButtonsStackView
    private func configureActionButtons(isCurrentUser: Bool) {
        // Очищаем стек перед добавлением
        actionButtonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isCurrentUser {
            actionButtonsStackView.addArrangedSubview(newPostButton)
            actionButtonsStackView.addArrangedSubview(editProfileButton)
        } else {
            // Для чужого профиля добавляем Follow и Message
            actionButtonsStackView.addArrangedSubview(followButton)
            actionButtonsStackView.addArrangedSubview(messageButton)
            configureFollowButton(isFollowing: viewModel.isFollowing) // Настроить начальный вид кнопки Follow
        }
    }
    
    // Настраивает внешний вид кнопки Follow
    private func configureFollowButton(isFollowing: Bool) {
        if isFollowing {
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = .systemGray // Серый фон
            followButton.setTitleColor(.white, for: .normal)
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = .white // Белый фон
            followButton.setTitleColor(.black, for: .normal)
        }
    }
    
    // Вспомогательный метод для обновления стека статов
    private func updateStatStack(_ stackView: UIStackView, value: String, label: String) {
        if let valueLabel = stackView.arrangedSubviews.first as? UILabel,
           let textLabel = stackView.arrangedSubviews.last as? UILabel {
            valueLabel.text = value
            textLabel.text = label
        }
    }

    // MARK: - Actions

    @objc private func editProfileTapped() {
        delegate?.didTapEditProfileButton()
    }

    // Обновляем newPostButtonTapped для вызова presentMediaPicker. Добавить presentMediaPicker для настройки и показа PHPickerViewController. Реализовать PHPickerViewControllerDelegate для обработки выбранных медиа и вызова координатора. Удалить ненужные методы CreatePostViewControllerDelegate.
    @objc private func newPostButtonTapped() {
        print("New Post button tapped")
        presentMediaPicker()
    }

    @objc private func followButtonTapped() {
        viewModel.followButtonTapped() // Вызываем метод ViewModel
    }
    
    @objc private func messageButtonTapped() {
        delegate?.didTapMessageButton() // Уведомляем координатора
    }
    
    // MARK: - Image Picker Logic

    // Меняем на PHPicker
    private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images // Только изображения
        config.selectionLimit = 0 // 0 = без лимита (позволяем выбрать несколько фото)
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            print("Media selection cancelled.")
            return
        }

        // Обрабатываем выбранные изображения по очереди и отправляем на кроп
        processNextImage(from: results, at: 0, withCroppedImages: [], selectedAspectRatio: nil)
    }

    // MARK: - Helpers

    private func presentMediaPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images // Только изображения (убрали видео для упрощения)
        config.selectionLimit = 10 // Ограничение на количество выбранных файлов
        config.preferredAssetRepresentationMode = .current // Получаем наиболее подходящее представление

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // Рекурсивная функция для последовательной обработки выбранных изображений
    private func processNextImage(from results: [PHPickerResult], at index: Int, withCroppedImages croppedImages: [MediaItem], selectedAspectRatio: CGFloat? = nil) {
        // Проверяем, что мы не вышли за пределы массива
        guard index < results.count else {
            // Все изображения обработаны, можем показать экран создания поста
            if !croppedImages.isEmpty {
                if let coordinator = self.delegate as? CurrentUserProfileCoordinator {
                    coordinator.showCreatePost(with: croppedImages)
                } else {
                    print("Error: Delegate does not conform to expected coordinator type or is nil.")
                }
            }
            return
        }
        
        let result = results[index]
        let provider = result.itemProvider
        
        // Только если провайдер может предоставить UIImage
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        // Переходим к следующему изображению, даже если это изображение не загрузилось
                        self.processNextImage(from: results, at: index + 1, withCroppedImages: croppedImages, selectedAspectRatio: selectedAspectRatio)
                        return
                    }
                    
                    if let image = object as? UIImage {
                        // Если это первое изображение или нет выбранного соотношения сторон, 
                        // показываем экран кропа
                        if index == 0 || selectedAspectRatio == nil {
                            // Показываем экран кропа для изображения
                            let cropViewController = ImageCropViewController(image: image, imageIndex: index)
                            cropViewController.delegate = self
                            
                            // Передаем данные для сохранения контекста между вызовами
                            cropViewController.originalResults = results
                            cropViewController.originalIndex = index
                            cropViewController.croppedImages = croppedImages
                            
                            self.present(cropViewController, animated: true)
                        } else {
                            // Для последующих изображений применяем автоматический кроп
                            // с тем же соотношением сторон, что было выбрано для первого изображения
                            print("Applying automatic crop with aspect ratio \(selectedAspectRatio!) to image at index \(index)")
                            
                            // Создаем кропнутое изображение с центрированием
                            let croppedImage = self.autoCropImage(image, withAspectRatio: selectedAspectRatio!)
                            
                            // Добавляем результат в массив и переходим к следующему изображению
                            var updatedCroppedImages = croppedImages
                            updatedCroppedImages.append(.image(croppedImage))
                            
                            // Обрабатываем следующее изображение
                            self.processNextImage(from: results, at: index + 1, withCroppedImages: updatedCroppedImages, selectedAspectRatio: selectedAspectRatio)
                        }
                    } else {
                        // Если не удалось загрузить изображение, переходим к следующему
                        self.processNextImage(from: results, at: index + 1, withCroppedImages: croppedImages, selectedAspectRatio: selectedAspectRatio)
                    }
                }
            }
        } else {
            // Если провайдер не может предоставить UIImage, переходим к следующему
            processNextImage(from: results, at: index + 1, withCroppedImages: croppedImages, selectedAspectRatio: selectedAspectRatio)
        }
    }

    // Функция для автоматического кропа изображения с заданным соотношением сторон
    private func autoCropImage(_ image: UIImage, withAspectRatio aspectRatio: CGFloat) -> UIImage {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let imageRatio = imageWidth / imageHeight
        
        // Размеры области кропа
        var cropWidth: CGFloat
        var cropHeight: CGFloat
        
        if imageRatio > aspectRatio {
            // Изображение шире, чем требуемое соотношение
            cropHeight = imageHeight
            cropWidth = cropHeight * aspectRatio
        } else {
            // Изображение выше, чем требуемое соотношение
            cropWidth = imageWidth
            cropHeight = cropWidth / aspectRatio
        }
        
        // Центрируем область кропа
        let originX = (imageWidth - cropWidth) / 2
        let originY = (imageHeight - cropHeight) / 2
        
        // Создаем CGRect для области кропа
        let cropRect = CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)
        
        // Выполняем кроп
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        // Если что-то пошло не так, возвращаем исходное изображение
        return image
    }

    // MARK: - CreatePostViewControllerDelegate

    // Эти методы теперь не нужны здесь, так как делегатом CreatePostVC является координатор
    /*
    func didFinishCreatingPost(_ controller: CreatePostViewController) {
        controller.dismiss(animated: true) {
            // TODO: Обновить ленту постов?
            print("Post created successfully!")
            self.viewModel.fetchPosts() // Перезагружаем посты
        }
    }

    func didCancelCreatingPost(_ controller: CreatePostViewController) {
        controller.dismiss(animated: true)
    }
    */

    // MARK: - Helpers

    // ... остальной код ...

    // Метод для принудительного обновления данных в профиле
    func refreshUserData() {
        print("👤 UserProfileFeedVC: Принудительное обновление данных пользователя и постов")
        viewModel.fetchAllUserData()
        viewModel.fetchPosts(forceReload: true)
        
        // Перезагружаем коллекцию
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.postsCollectionView.reloadData()
        }
    }
    
    // Вызываем принудительное обновление данных при появлении экрана
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👤 UserProfileFeedVC: viewWillAppear - запрашиваем обновление данных")
        refreshUserData()
    }

    // MARK: - UI Configuration Methods
    
    // Метод для настройки элементов интерфейса в зависимости от типа пользователя
    private func setupActionsForUserType() {
        configureActionButtons(isCurrentUser: viewModel.isCurrentUser)
        configureTopBarButtons(isCurrentUser: viewModel.isCurrentUser)
    }
    
    // Методы для настройки верхней панели
    private func setupCurrentUserTopBar() {
        topBarUsernameLabel.text = viewModel.userProfile?.username ?? "My Profile"
        topBarSettingsButton.isHidden = false
        topBarMessagesButton.isHidden = false
    }
    
    private func setupOtherUserTopBar() {
        topBarUsernameLabel.text = viewModel.userProfile?.username ?? "User Profile"
        topBarSettingsButton.isHidden = true
        topBarMessagesButton.isHidden = false
    }
    
    // Методы для обновления данных профиля
    private func setupUserProfile(with user: User) {
        // Обновляем имя пользователя и другие текстовые поля
        displayNameLabel.text = user.username
        topBarUsernameLabel.text = user.username
        statusLabel.text = user.status ?? ""
        
        // Обновляем статистику
        updateStatStack(postsStatStack, value: "\(viewModel.userPosts.count)", label: "Posts")
        updateStatStack(followersStatStack, value: "\(user.followerCount ?? 0)", label: "Followers")
        
        // Загружаем аватар
        if let urlString = user.avatarURL, let url = URL(string: urlString) {
            let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
            
            avatarImageView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { result in
                    switch result {
                    case .success:
                        print("Аватар успешно загружен")
                    case .failure(let error):
                        print("Ошибка при загрузке аватара: \(error.localizedDescription)")
                    }
                }
            )
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        // Обновляем кнопки в зависимости от текущего пользователя
        configureActionButtons(isCurrentUser: viewModel.isCurrentUser)
    }
    
    private func setupTotalLikes(count: Int) {
        updateStatStack(likesStatStack, value: "\(count)", label: "Likes")
    }
    
    private func setupProgressData(_ progress: ProgressData) {
        // Обновляем UI с прогрессом пользователя
        // Например, обновление радарной диаграммы, если она есть
        print("Обновлен прогресс пользователя: \(progress)")
    }
    
    // Переименовываем метод для соответствия вызову в bindViewModel
    private func updateFollowButton(isFollowing: Bool) {
        configureFollowButton(isFollowing: isFollowing)
    }

    // НОВЫЙ МЕТОД: Рассчитывает и обновляет высоту CollectionView
    private func updateCollectionViewHeight(postCount: Int) {
        guard postCount > 0 else {
            collectionViewHeightConstraint.constant = 0
            return
        }
        
        // Получаем размер ячейки (аналогично sizeForItemAt)
        guard let layout = postsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let spacing: CGFloat = 3
        let itemsPerRow: CGFloat = 3
        let totalSpacing = (itemsPerRow - 1) * spacing
        let availableWidth = postsCollectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - totalSpacing
        
        // Проверка на деление на ноль или отрицательную ширину
        guard itemsPerRow > 0, availableWidth > 0 else { 
             print("⚠️ updateCollectionViewHeight: Невозможно рассчитать ширину ячейки (itemsPerRow=\(itemsPerRow), availableWidth=\(availableWidth))")
             collectionViewHeightConstraint.constant = 0 // Ставим 0, если расчет невозможен
             return
        }
        
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * (16.0 / 9.0)
        
        // Рассчитываем количество рядов
        let numberOfRows = ceil(CGFloat(postCount) / itemsPerRow)
        
        // Общая высота = (количество рядов * высота ячейки) + (количество_промежутков * расстояние)
        let totalHeight = (numberOfRows * itemHeight) + (max(0, numberOfRows - 1) * spacing)
        
        print("📏 updateCollectionViewHeight: postCount=\(postCount), itemHeight=\(itemHeight), rows=\(numberOfRows), totalHeight=\(totalHeight)")
        
        // Обновляем констрейнт
        collectionViewHeightConstraint.constant = totalHeight
        
        // Можно добавить анимацию изменения высоты
        // UIView.animate(withDuration: 0.3) {
        //     self.view.layoutIfNeeded()
        // }
    }
}

// MARK: - UICollectionViewDataSource
extension UserProfileFeedViewController {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.userPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostGridCell.identifier, for: indexPath) as? PostGridCell else {
            fatalError("Unable to dequeue PostGridCell")
        }
        let post = viewModel.userPosts[indexPath.item]
        cell.configure(with: post)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension UserProfileFeedViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let spacing: CGFloat = 3 // Используем новый spacing = 3
        let itemsPerRow: CGFloat = 3
        let totalSpacing = (itemsPerRow - 1) * spacing // (3-1)*3 = 6
        // Убираем расчет боковых отступов здесь, используем sectionInset
        // let sidePadding: CGFloat = 20
        // let totalPadding = sidePadding * 2
        
        // Доступная ширина = ширина collection view - отступы секции слева/справа - общее пространство между ячейками
        let availableWidth = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - totalSpacing
        let itemWidth = availableWidth / itemsPerRow
        
        // Рассчитываем высоту 16:9 (перевернуто, т.к. ячейки вертикальные)
        let itemHeight = itemWidth * (16.0 / 9.0)
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    // Предоставляем размер для футера с индикатором загрузки
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        // Показываем футер только если загружаются дополнительные посты и не достигнут конец
        return viewModel.isLoadingPosts && !viewModel.isLastPageReached ? CGSize(width: collectionView.bounds.width, height: 50) : .zero
    }
}

// MARK: - UICollectionViewDelegate
extension UserProfileFeedViewController {
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPost = viewModel.userPosts[indexPath.item]
        print("UserProfileFeedViewController: Выбран пост с ID: \(selectedPost.id ?? "N/A"), индекс: \(indexPath.item)")

        // Пытаемся получить координатора через свойство delegate
        if let coordinator = delegate as? CurrentUserProfileCoordinator {
            print("UserProfileFeedViewController: Вызываем coordinator.showUserPostScroll")
            coordinator.showUserPostScroll(posts: viewModel.userPosts, startIndex: indexPath.item)
        }
        // Пытаемся получить координатора через иерархию view controller'ов (если delegate не установлен или имеет другой тип)
        else if let containerCoordinator = self.parent?.parent as? UserProfileCoordinator {
             print("UserProfileFeedViewController: Вызываем coordinator.showUserPostScroll (via parent container)")
             // В этом сценарии UserProfileCoordinator уже знает userID
             // containerCoordinator.showUserPostScroll(posts: viewModel.userPosts, startIndex: indexPath.item)
             // TODO: Уточнить, как UserProfileCoordinator должен получать посты и индекс для этого сценария
        } else {
            print("UserProfileFeedViewController: ОШИБКА - не удалось получить координатора для навигации на UserPostScroll")
        }
    }
    
    // Добавляем метод для пагинации при прокрутке
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !viewModel.isLoadingPosts, !viewModel.isLastPageReached else { return }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // Загружаем больше постов, когда пользователь достиг 70% высоты контента
        if offsetY > contentHeight - height * 1.3 {
            print("📜 UserProfileFeedVC: Достигнут порог прокрутки, загружаем следующую страницу постов")
            viewModel.loadMorePosts()
        }
    }
}

// MARK: - CreatePostViewControllerDelegate
// Реализация делегата находится в extension для лучшей организации
extension UserProfileFeedViewController {

    func didFinishCreatingPost(_ controller: CreatePostViewController) {
        print("⭐ UserProfileFeedVC: Выполняется didFinishCreatingPost")
        controller.dismiss(animated: true) {
            // Обновляем все данные пользователя после создания поста
            // Убедитесь, что ваш ViewModel имеет этот метод или аналогичный
            print("⭐ UserProfileFeedVC: Обновляем данные через fetchAllUserData()")
            self.viewModel.fetchAllUserData()
            // Явно перезагружаем коллекцию
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⭐ UserProfileFeedVC: Принудительное обновление коллекции постов")
                self.postsCollectionView.reloadData()
            }
            print("⭐ UserProfileFeedVC: didFinishCreatingPost завершен")
        }
    }

    func didCancelCreatingPost(_ controller: CreatePostViewController) {
        print("CreatePostViewController cancelled.")
        controller.dismiss(animated: true) {
            print("CreatePostViewController dismissed. (Cancelled)")
        }
    }

} // Конец extension

// MARK: - Actions for Top Bar
extension UserProfileFeedViewController {
    @objc private func topBarSettingsButtonTapped() {
        print("Top bar settings button tapped")
        
        // Создаем UIAlertController для отображения опций настроек
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Добавляем опцию Sign Out
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.signOutTapped()
        }
        alertController.addAction(signOutAction)
        
        // Добавляем опцию Edit Profile
        let editProfileAction = UIAlertAction(title: "Edit Profile", style: .default) { [weak self] _ in
            self?.editProfileTapped()
        }
        alertController.addAction(editProfileAction)
        
        // Добавляем опцию отмены
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // Для iPad, указываем источник всплывающего окна
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = topBarSettingsButton
            popoverController.sourceRect = topBarSettingsButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    @objc private func topBarChatsButtonTapped() {
        print("Top bar chats/notifications button tapped")
        // TODO: Реализовать переход к списку чатов/уведомлений (через делегата/координатора)
        // delegate?.didTapChatsButton()
    }
    
    // Добавляем метод для выхода из системы
    @objc private func signOutTapped() {
        print("Sign out requested")
        
        // Показываем диалог подтверждения
        let confirmAlert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirmAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            // Вызываем метод делегата для выхода из системы
            self?.delegate?.didRequestSignOut()
        }
        
        confirmAlert.addAction(cancelAction)
        confirmAlert.addAction(confirmAction)
        
        present(confirmAlert, animated: true)
    }
}

// Добавляем соответствие ImageCropViewControllerDelegate
extension UserProfileFeedViewController: ImageCropViewControllerDelegate {
    func imageCropViewController(_ controller: ImageCropViewController, didFinishCroppingImage image: UIImage) {
        // Получаем соотношение сторон изображения для применения к остальным изображениям
        let aspectRatio = image.size.width / image.size.height
        print("Selected image aspect ratio: \(aspectRatio)")
        
        // Закрываем контроллер кропа
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Получаем текущие результаты и обрабатываем следующее изображение
            if let results = controller.originalResults, let currentIndex = controller.originalIndex {
                var updatedCroppedImages = controller.croppedImages ?? []
                // Добавляем кропнутое изображение в массив
                updatedCroppedImages.append(.image(image))
                
                // Обрабатываем следующее изображение или завершаем процесс
                if currentIndex + 1 < results.count {
                    // Есть еще изображения для обработки - используем запомненное соотношение сторон
                    self.processNextImage(from: results, at: currentIndex + 1, withCroppedImages: updatedCroppedImages, selectedAspectRatio: aspectRatio)
                } else {
                    // Все изображения обработаны, переходим к созданию поста
                    if let coordinator = self.delegate as? CurrentUserProfileCoordinator {
                        coordinator.showCreatePost(with: updatedCroppedImages)
                    } else {
                        print("Error: Delegate does not conform to expected coordinator type or is nil.")
                    }
                }
            } else {
                // Если по какой-то причине нет информации о результатах, показываем экран создания поста с этим одним изображением
                if let coordinator = self.delegate as? CurrentUserProfileCoordinator {
                    coordinator.showCreatePost(with: [.image(image)])
                }
            }
        }
    }
    
    func imageCropViewControllerDidCancel(_ controller: ImageCropViewController) {
        // Закрываем контроллер кропа
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Пользователь отменил обработку этого изображения, переходим к следующему или завершаем
            if let results = controller.originalResults, let currentIndex = controller.originalIndex, let croppedImages = controller.croppedImages {
                // Если у нас уже есть какие-то обработанные изображения, продолжаем с ними
                if !croppedImages.isEmpty {
                    self.processNextImage(from: results, at: currentIndex + 1, withCroppedImages: croppedImages, selectedAspectRatio: nil)
                } else if currentIndex == 0 {
                    // Если это было первое изображение и пользователь отменил его, отменяем весь процесс
                    print("First image crop cancelled, aborting the whole process.")
                } else {
                    // Если это не первое изображение, продолжаем с тем, что уже имеем
                    self.processNextImage(from: results, at: currentIndex + 1, withCroppedImages: croppedImages, selectedAspectRatio: nil)
                }
            } else {
                // Если нет информации о результатах, просто завершаем процесс
                print("Image crop cancelled and no previous images available.")
            }
        }
    }
}

// MARK: - LoadingFooterView
class LoadingFooterView: UICollectionReusableView {
    static let identifier = "LoadingFooter"
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func startAnimating() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension UserProfileFeedViewController {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Если среди предзагружаемых индексов есть те, которые близки к концу,
        // начинаем загрузку следующей страницы
        let lastItemIndex = viewModel.userPosts.count - 1
        let prefetchThreshold = 5 // За сколько ячеек до конца начинать предзагрузку
        
        let needsPrefetch = indexPaths.contains { $0.item > lastItemIndex - prefetchThreshold }
        
        if needsPrefetch && !viewModel.isLoadingPosts && !viewModel.isLastPageReached {
            print("📜 UserProfileFeedVC: Предзагрузка следующей страницы постов")
            viewModel.loadMorePosts()
        }
    }
}

// MARK: - UICollectionViewDataSource extension
extension UserProfileFeedViewController {
    // Добавляем метод для создания футера
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "LoadingFooter",
                for: indexPath) as? LoadingFooterView else {
                return UICollectionReusableView()
            }
            
            if viewModel.isLoadingPosts {
                footerView.startAnimating()
            } else {
                footerView.stopAnimating()
            }
            
            return footerView
        }
        
        return UICollectionReusableView()
    }
}
