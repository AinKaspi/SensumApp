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
class UserProfileFeedViewController: UIViewController, PHPickerViewControllerDelegate, CreatePostViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

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
    private lazy var postsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 3 // Новый spacing = 3
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.scrollDirection = .vertical
        // Задаем отступы секции
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10) // Новый отступ = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(PostGridCell.self, forCellWithReuseIdentifier: PostGridCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self // Устанавливаем delegate для FlowLayout
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
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupBindings()
        // Устанавливаем contentInset ПОСЛЕ настройки констрейнтов
        setupContentInset()
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
            // Ограничиваем ширину имени справа до кнопки настроек
            topBarUsernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: topBarSettingsButton.leadingAnchor, constant: -8),
            
            // Кнопка настроек сразу справа от имени
            topBarSettingsButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            topBarSettingsButton.leadingAnchor.constraint(equalTo: topBarUsernameLabel.trailingAnchor, constant: 4),
            topBarSettingsButton.widthAnchor.constraint(equalToConstant: topBarButtonSize),
            topBarSettingsButton.heightAnchor.constraint(equalToConstant: topBarButtonSize),
            
            // Кнопка сообщений справа
            topBarMessagesButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            topBarMessagesButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),
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
    
    private func setupBindings() {
        // Подписка на профиль пользователя
        viewModel.$userProfile
            .receive(on: DispatchQueue.main) // Обновляем UI в главном потоке
            .sink { [weak self] user in
                guard let self = self, let user = user else { return }
                
                // Обновляем displayNameLabel и topBarUsernameLabel
                self.displayNameLabel.text = user.username // Или user.displayName, если такое поле есть
                self.topBarUsernameLabel.text = user.username
                self.statusLabel.text = user.status ?? "" // Показываем статус или пусто
                
                // Обновляем статы (только Posts, Followers, Following)
                self.updateStatStack(self.postsStatStack, value: "\(self.viewModel.userPosts.count)", label: "Posts")
                self.updateStatStack(self.followersStatStack, value: "\(user.followerCount ?? 0)", label: "Followers")
                // Убираем обновление Following
                // self.updateStatStack(self.followingStatStack, value: "\(user.followingCount ?? 0)", label: "Following")
                
                print("Attempting to load avatar from URL: \(user.avatarURL ?? "nil")") 
                
                let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
                
                if let urlString = user.avatarURL, let url = URL(string: urlString) {
                    self.avatarImageView.kf.indicatorType = .activity 
                    self.avatarImageView.kf.setImage(
                        with: url, 
                        placeholder: placeholder, 
                        options: [
                            .transition(.fade(0.2)),
                            .cacheOriginalImage,
                            .onFailureImage(UIImage(named: "default_avatar")?.withTintColor(.darkGray))
                        ],
                        completionHandler: { result in
                            switch result {
                            case .success(let value):
                                print("Kingfisher: Image loaded successfully from \(value.source.url?.absoluteString ?? "N/A")")
                            case .failure(let error):
                                print("Kingfisher Error: Failed to load image - \(error.localizedDescription)")
                                self.avatarImageView.image = placeholder
                                self.avatarImageView.contentMode = .scaleAspectFit // Может быть лучше для плейсхолдера
                            }
                        }
                    )
                } else {
                    self.avatarImageView.image = placeholder
                    self.avatarImageView.contentMode = .scaleAspectFit // Может быть лучше для плейсхолдера
                }
                
                // Настраиваем кнопки в зависимости от isCurrentUser
                self.configureActionButtons(isCurrentUser: self.viewModel.isCurrentUser)
                // Настраиваем видимость кнопок в topBarView
                self.configureTopBarButtons(isCurrentUser: self.viewModel.isCurrentUser)
            }
            .store(in: &cancellables)
        
        // Подписка на общее количество лайков (НОВАЯ)
        viewModel.$totalLikes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] likes in
                // Используем ?? 0 и форматируем?
                self?.updateStatStack(self?.likesStatStack ?? UIStackView(), value: "\(likes ?? 0)", label: "Likes")
            }
            .store(in: &cancellables)
        
        // Подписка на состояние подписки (для чужого профиля)
        viewModel.$isFollowing
             .receive(on: DispatchQueue.main)
             .sink { [weak self] isFollowing in
                 guard let self = self, !self.viewModel.isCurrentUser else { return }
                 self.configureFollowButton(isFollowing: isFollowing)
             }
             .store(in: &cancellables)
        
        // Подписка на состояние загрузки (можно объединить isLoadingProfile и isLoadingProgress)
        Publishers.CombineLatest(viewModel.$isLoadingProfile, viewModel.$isLoadingProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoadingProfile, isLoadingProgress in
                let isLoading = isLoadingProfile || isLoadingProgress
                // TODO: Показать/скрыть общий индикатор загрузки для шапки
                print("Profile/Progress loading state: \(isLoading)")
            }
            .store(in: &cancellables)
            
        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let message = errorMessage, !message.isEmpty else { return }
                // TODO: Показать ошибку пользователю (например, в Alert)
                print("Error: \(message)")
                // Сбросить ошибку во ViewModel после показа?
                // self?.viewModel.errorMessage = nil 
            }
            .store(in: &cancellables)
            
        // Подписка на посты пользователя
        viewModel.$userPosts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in // Нам не нужны сами посты здесь, просто сигнал к перезагрузке
                print("Received new posts data. Reloading collection view...")
                self?.postsCollectionView.reloadData()
                // Обновляем счетчик постов в шапке
                self?.updateStatStack(self?.postsStatStack ?? UIStackView(), value: "\(self?.viewModel.userPosts.count ?? 0)", label: "Posts")
            }
            .store(in: &cancellables)
            
        // Подписка на состояние загрузки постов
        viewModel.$isLoadingPosts
             .receive(on: DispatchQueue.main)
             .sink { [weak self] isLoading in
                 // TODO: Показать/скрыть индикатор загрузки для сетки постов
                 print("Posts loading state: \(isLoading)")
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

        var selectedMediaItems: [MediaItem] = []
        let dispatchGroup = DispatchGroup()

        for result in results {
            dispatchGroup.enter()
            let provider = result.itemProvider

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    defer { dispatchGroup.leave() }
                    if let image = image as? UIImage {
                        print("Loaded image")
                        selectedMediaItems.append(.image(image))
                    } else if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        // TODO: Показать ошибку пользователю?
                    }
                }
            } else {
                // Убрали обработку видео (UTType.movie/UTType.video)
                print("Unsupported media type selected (expected image).")
                // TODO: Показать сообщение пользователю?
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            print("Finished loading all media. Count: \(selectedMediaItems.count)")
            if !selectedMediaItems.isEmpty {
                // Вызываем метод координатора для показа экрана создания поста
                // TODO: Убедиться, что координатор реализует showCreatePost
                if let coordinator = self?.delegate as? CurrentUserProfileCoordinator {
                     coordinator.showCreatePost(with: selectedMediaItems)
                } else {
                    print("Error: Delegate does not conform to expected coordinator type or is nil.")
                    // TODO: Показать ошибку
                }
            } else {
                print("No valid media items were loaded.")
                // TODO: Показать сообщение пользователю?
            }
        }
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

    private func presentMediaPicker() {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos]) // Разрешаем фото и видео
        config.selectionLimit = 10 // Ограничение на количество выбранных файлов (можно изменить)
        config.preferredAssetRepresentationMode = .current // Получаем наиболее подходящее представление

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // ... остальной код ...
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
}

// MARK: - CreatePostViewControllerDelegate
// Реализация делегата находится в extension для лучшей организации
extension UserProfileFeedViewController {

    func didFinishCreatingPost(_ controller: CreatePostViewController) {
        print("CreatePostViewController finished creating post.")
        controller.dismiss(animated: true) {
            // Обновляем все данные пользователя после создания поста
            // Убедитесь, что ваш ViewModel имеет этот метод или аналогичный
            self.viewModel.fetchAllUserData()
            print("CreatePostViewController dismissed. (Finished & Reloading profile data)")
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
