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
    // Добавляем делегат для новой кнопки
    func didTapNewProgramButton()
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
        imageView.layer.cornerRadius = 40 // Примерный радиус (половина ширины/высоты)
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
        valueLabel.textAlignment = .center
        valueLabel.text = value
        
        let textLabel = UILabel()
        textLabel.font = .systemFont(ofSize: 12)
        textLabel.textColor = .lightGray
        textLabel.textAlignment = .center
        textLabel.text = label
        
        let stack = UIStackView(arrangedSubviews: [valueLabel, textLabel])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }
    
    private lazy var postsStatStack: UIStackView = createStatLabel(label: "Posts")
    private lazy var followersStatStack: UIStackView = createStatLabel(label: "Followers")
    private lazy var followingStatStack: UIStackView = createStatLabel(label: "Following")
    private lazy var rankStatStack: UIStackView = createStatLabel(label: "Rank")
    private lazy var levelStatStack: UIStackView = createStatLabel(label: "Level")
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [postsStatStack, followersStatStack, followingStatStack, rankStatStack, levelStatStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 5
        return stack
    }()
    
    // Имя и Статус
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.text = "Username"
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
        button.backgroundColor = .darkGray // Цвет как в макете?
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
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
        button.backgroundColor = .systemBlue // Другой цвет для отличия
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(newPostButtonTapped), for: .touchUpInside)
        // TODO: Показывать только если isCurrentUser?
        return button
    }()
    
    // Добавляем кнопку New Program
    private lazy var newProgramButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("New Program", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen // Другой цвет
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(newProgramButtonTapped), for: .touchUpInside)
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
    
    // Добавляем кнопку Выхода (будет ниже)
    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        // TODO: Скрывать, если !isCurrentUser?
        return button
    }()
    
    // --- Переключатель Контента --- 
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
    
    // --- Сетка Постов ---
    private lazy var postsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 1
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(PostGridCell.self, forCellWithReuseIdentifier: PostGridCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self // Устанавливаем delegate для FlowLayout
        return collectionView
    }()

    // Добавляем Placeholder View для вкладки Programs
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
        view.addSubview(scrollView)
        scrollView.addSubview(contentWrapperView)

        // Добавляем элементы шапки в contentWrapperView
        contentWrapperView.addSubview(profileHeaderView)
        // Элементы ДОЛЖНЫ добавляться в profileHeaderView, а не напрямую в contentWrapperView
        profileHeaderView.addSubview(avatarImageView)
        profileHeaderView.addSubview(statsStackView)
        profileHeaderView.addSubview(usernameLabel)
        profileHeaderView.addSubview(statusLabel)
        profileHeaderView.addSubview(actionButtonsStackView)
        // Добавляем кнопки в стек
        configureActionButtons(isCurrentUser: self.viewModel.isCurrentUser) // Этот метод добавит кнопки в actionButtonsStackView

        // Добавляем Segmented Control в contentWrapperView
        contentWrapperView.addSubview(contentSegmentedControl)

        // Добавляем CollectionView в contentWrapperView ПОД шапкой
        contentWrapperView.addSubview(postsCollectionView)

        // Добавляем Placeholder View для вкладки Programs
        contentWrapperView.addSubview(programsPlaceholderView)

        // Добавляем индикатор загрузки и сообщение об ошибке поверх всего scrollView
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
    }

    private func setupConstraints() {
        let padding: CGFloat = 16
        let statsSpacing: CGFloat = 5
        let avatarSize: CGFloat = 80 // Явно задаем размер аватара

        // ScrollView и ContentWrapperView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentWrapperView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentWrapperView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentWrapperView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentWrapperView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentWrapperView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor) // Ширина равна ширине scrollView
        ])

        // Элементы в profileHeaderView
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: contentWrapperView.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            // Нижний край profileHeaderView будет определяться его содержимым

            // Аватар
            avatarImageView.topAnchor.constraint(equalTo: profileHeaderView.topAnchor, constant: padding),
            avatarImageView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize), // Явная ширина
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize), // Явная высота

            // Стек статов
            statsStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: padding),
            statsStackView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),
            statsStackView.heightAnchor.constraint(lessThanOrEqualTo: avatarImageView.heightAnchor), // Ограничиваем высоту статов

            // Имя пользователя
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: padding * 0.75),
            usernameLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),

            // Статус
            statusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),

            // Стек кнопок действий
            actionButtonsStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: padding),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),
            // Привязываем низ хедера к низу стека кнопок
            profileHeaderView.bottomAnchor.constraint(equalTo: actionButtonsStackView.bottomAnchor, constant: padding)
        ])

        // Сегментный контрол и CollectionView
        NSLayoutConstraint.activate([
            contentSegmentedControl.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: padding),
            contentSegmentedControl.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: padding),
            contentSegmentedControl.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -padding),

            // CollectionView
            postsCollectionView.topAnchor.constraint(equalTo: contentSegmentedControl.bottomAnchor, constant: padding),
            postsCollectionView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            postsCollectionView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            // Важно: Привязываем низ CollectionView к низу contentWrapperView
            // Это позволит contentWrapperView растягиваться по высоте контента
            postsCollectionView.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -padding),
            // Добавляем констрейнт высоты для CollectionView, который будет обновляться
            collectionViewHeightConstraint
        ])

        // Placeholder для Programs
        NSLayoutConstraint.activate([
            programsPlaceholderView.topAnchor.constraint(equalTo: contentSegmentedControl.bottomAnchor, constant: padding),
            programsPlaceholderView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            programsPlaceholderView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            programsPlaceholderView.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -padding) // Также привязываем к низу
        ])

        // Кнопка выхода (если она нужна вне хедера)
        // Если кнопка выхода должна быть всегда видна внизу, ее нужно добавлять в view, а не в scrollView
        // Если она должна скроллиться, то ее место в contentWrapperView
        // Пока оставим ее привязку к низу contentWrapperView для скроллинга
        // NSLayoutConstraint.activate([
        //     signOutButton.topAnchor.constraint(greaterThanOrEqualTo: postsCollectionView.bottomAnchor, constant: padding * 2), // Отступ сверху
        //     signOutButton.centerXAnchor.constraint(equalTo: contentWrapperView.centerXAnchor),
        //     signOutButton.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -padding * 2) // Отступ снизу
        // ])

        // Индикатор загрузки и ошибка (поверх scrollView)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: padding),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -padding)
        ])
    }

    // Новый метод для установки contentInset
    private func setupContentInset() {
        // Рассчитываем отступ: Высота TopMenu (55) + Отступ TopMenu от Safe Area (15) + Дополнительный зазор (10)
        let topInset: CGFloat = 55.0 + 15.0 + 10.0 // Итого = 80
        scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        // Начальное смещение ставим в 0, чтобы не было пустого места сверху при первой загрузке
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Подписка на профиль пользователя
        viewModel.$userProfile
            .receive(on: DispatchQueue.main) // Обновляем UI в главном потоке
            .sink { [weak self] user in
                guard let self = self, let user = user else { return }
                
                self.usernameLabel.text = user.username
                self.statusLabel.text = user.status ?? "" // Показываем статус или пусто
                
                // Обновляем статы
                // TODO: Форматировать большие числа (1000 -> 1K)
                self.updateStatStack(self.postsStatStack, value: "0", label: "Posts") // Пока посты не грузим
                self.updateStatStack(self.followersStatStack, value: "\(user.followerCount)", label: "Followers")
                self.updateStatStack(self.followingStatStack, value: "\(user.followingCount)", label: "Following")
                
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
            }
            .store(in: &cancellables)
        
        // Подписка на прогресс пользователя (ProgressData)
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self, let progress = progress else { return }
                // Обновляем статы из ProgressData
                self.updateStatStack(self.rankStatStack, value: progress.rank, label: "Rank")
                self.updateStatStack(self.levelStatStack, value: "\(progress.level)", label: "Level")
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
    
    // Настраивает кнопки в actionButtonsStackView
    private func configureActionButtons(isCurrentUser: Bool) {
        // Очищаем стек перед добавлением
        actionButtonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isCurrentUser {
            actionButtonsStackView.addArrangedSubview(editProfileButton)
            actionButtonsStackView.addArrangedSubview(newPostButton)
            actionButtonsStackView.addArrangedSubview(newProgramButton)
            signOutButton.isHidden = false
        } else {
            // Для чужого профиля добавляем Follow и Message
            actionButtonsStackView.addArrangedSubview(followButton)
            actionButtonsStackView.addArrangedSubview(messageButton)
            configureFollowButton(isFollowing: viewModel.isFollowing) // Настроить начальный вид кнопки Follow
            signOutButton.isHidden = true
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
        // Вызываем делегата
        delegate?.didTapEditProfileButton()
        // viewModel.editProfileButtonTapped() // Логику VM убираем отсюда, делегат решает
    }
    
    @objc private func signOutTapped() {
        // Вызываем делегата
        delegate?.didRequestSignOut()
    }
    
    // Action для кнопки New Post
    @objc private func newPostButtonTapped() {
        print("New Post button tapped")
        // TODO: Проверить права доступа к галерее
        presentImagePicker()
    }
    
    // Добавляем action для New Program
    @objc private func newProgramButtonTapped() {
        print("New Program button tapped - Action Placeholder")
        // Вызываем делегата, когда будет реализована навигация
         delegate?.didTapNewProgramButton()
    }
    
    // Добавляем actions для Follow/Message
    @objc private func followButtonTapped() {
        viewModel.followButtonTapped() // Вызываем метод ViewModel
    }
    
    @objc private func messageButtonTapped() {
        delegate?.didTapMessageButton() // Уведомляем координатора
    }
    
    // Добавляем action для Segmented Control
    @objc private func segmentedControlChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        print("Segmented control changed to index: \(selectedIndex)")
        
        // Показываем/скрываем CollectionView или Placeholder
        if selectedIndex == 0 { // Posts
            postsCollectionView.isHidden = false
            programsPlaceholderView.isHidden = true
            // TODO: Возможно, нужно перезагрузить посты?
        } else { // Programs
            postsCollectionView.isHidden = true
            programsPlaceholderView.isHidden = false
            // TODO: Загрузить и отобразить программы тренировок
        }
    }
    
    // MARK: - Image Picker Logic

    // Меняем на PHPicker
    private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images // Только изображения
        config.selectionLimit = 1 // Только одно фото
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let self = self, let selectedImage = image as? UIImage else {
                    print("Failed to load selected image from picker.")
                    // TODO: Show error to user
                    return
                }

                DispatchQueue.main.async {
                    print("Image selected via PHPicker. Size: \(selectedImage.size)")
                    // Шаг 3: Показываем CreatePostViewController
                    self.showCreatePostScreen(image: selectedImage)
                }
            }
        } else {
            print("Cannot load UIImage object from provider.")
            // TODO: Show error to user
        }
    }

    // MARK: - Navigation to Create Post

    private func showCreatePostScreen(image: UIImage) {
        // 1. Создаем ViewModel
        let viewModel = CreatePostViewModel(selectedImage: image)

        // 2. Создаем ViewController
        let createPostVC = CreatePostViewController(viewModel: viewModel)
        createPostVC.delegate = self // Устанавливаем себя делегатом

        // 3. Оборачиваем в UINavigationController для показа navigation bar
        let navigationController = UINavigationController(rootViewController: createPostVC)
        navigationController.modalPresentationStyle = .fullScreen // Или .automatic

        // 4. Показываем модально
        present(navigationController, animated: true)
    }

    // MARK: - CreatePostViewControllerDelegate

    // Вспомогательный Alert для теста (можно удалить или оставить для других нужд)
    private func showAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default))
         present(alert, animated: true)
     }

    // MARK: - CollectionView Height Calculation (Moved inside class)

    // Метод для обновления высоты CollectionView
    private func updateCollectionViewHeight() {
        // Пересчитываем высоту контента CollectionView
        postsCollectionView.layoutIfNeeded() // Убедимся, что layout актуален
        let contentHeight = postsCollectionView.collectionViewLayout.collectionViewContentSize.height

        // Обновляем констрейнт высоты
        // Use a reasonable minimum height, maybe related to one row? Calculate based on sizeForItemAt?
        // For now, keep the previous logic or a fixed minimum. Let's stick to the previous minimum.
        collectionViewHeightConstraint.constant = max(contentHeight, 200) // Минимальная высота, чтобы не схлопывался

        // Анимируем изменение высоты (опционально)
        // UIView.animate(withDuration: 0.3) {
        //     self.view.layoutIfNeeded()
        // }
        print("Updated CollectionView height constraint to: \(collectionViewHeightConstraint.constant)")
    }

    // Вызываем обновление высоты после перезагрузки данных
    // Moved inside class
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем высоту после того, как bounds станут известны
        // Делаем это здесь, а не в reloadData, чтобы учесть изменения layout
        updateCollectionViewHeight()
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
        let spacing = layout.minimumInteritemSpacing
        let itemsPerRow: CGFloat = 3
        let totalSpacing = (itemsPerRow - 1) * spacing
        // Используем ширину CollectionView (которая ограничена contentWrapperView)
        let itemWidth = (collectionView.bounds.width - totalSpacing) / itemsPerRow
        // Рассчитываем высоту 16:9
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
