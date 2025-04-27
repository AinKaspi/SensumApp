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

// Добавляем делегат для UIImagePickerController
// Обновляем: используем PHPickerViewControllerDelegate и добавляем CreatePostViewControllerDelegate
class UserProfileFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPickerViewControllerDelegate, CreatePostViewControllerDelegate {

    // Добавляем ViewModel
    var viewModel: UserProfileFeedViewModel! // Используем !, т.к. он будет инжектирован координатором
    // Добавляем слабого делегата
    weak var delegate: UserProfileFeedViewControllerDelegate?
    private var cancellables = Set<AnyCancellable>() // Для хранения подписок Combine

    // TODO: Добавить ViewModel для загрузки данных профиля и постов

    // MARK: - UI Elements
    
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
        // Настраиваем layout для сетки
        let spacing: CGFloat = 1
        let itemsPerRow: CGFloat = 3
        let totalSpacing = (itemsPerRow - 1) * spacing
        let itemWidth = (view.bounds.width - totalSpacing) / itemsPerRow
        let itemHeight = itemWidth * (16 / 9.0) // Используем 9.0 для деления с плавающей точкой
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight) // Устанавливаем новый размер
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        // Регистрируем ячейку
        collectionView.register(PostGridCell.self, forCellWithReuseIdentifier: PostGridCell.identifier)
        collectionView.dataSource = self // Устанавливаем dataSource
        collectionView.delegate = self   // Устанавливаем delegate (для FlowLayout и нажатий)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Фон как в макете
        setupViews()
        setupConstraints()
        setupBindings() // <-- Вызываем настройку биндингов
    }

    // MARK: - Setup UI

    private func setupViews() {
        // Добавляем сначала wrapper
        view.addSubview(contentWrapperView)
        // Добавляем все остальные элементы ВНУТРЬ wrapper
        contentWrapperView.addSubview(profileHeaderView)
        contentWrapperView.addSubview(usernameLabel)
        contentWrapperView.addSubview(statusLabel)
        contentWrapperView.addSubview(actionButtonsStackView)
        contentWrapperView.addSubview(contentSegmentedControl)
        contentWrapperView.addSubview(postsCollectionView) 
        contentWrapperView.addSubview(programsPlaceholderView)
        contentWrapperView.addSubview(signOutButton)
        
        profileHeaderView.addSubview(avatarImageView)
        profileHeaderView.addSubview(statsStackView)
        
        // Добавляем кнопки в стек действий
        // Пока добавим обе: Edit и New Post
        actionButtonsStackView.addArrangedSubview(editProfileButton)
        actionButtonsStackView.addArrangedSubview(newPostButton) 
    }

    private func setupConstraints() {
        let padding: CGFloat = 15
        let containerWidthMultiplier: CGFloat = 0.86
        
        NSLayoutConstraint.activate([
            // Констрейнты для contentWrapperView (86% ширины, центрирован, прижат к safe area)
            contentWrapperView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentWrapperView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentWrapperView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: containerWidthMultiplier),
            contentWrapperView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // --- Констрейнты ВНУТРИ contentWrapperView --- 
            
            // Шапка (прижата к верху wrapper, ширина = ширине wrapper)
            profileHeaderView.topAnchor.constraint(equalTo: contentWrapperView.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            profileHeaderView.heightAnchor.constraint(equalToConstant: 100),
            
            // Аватар и Статы внутри шапки (без изменений, они уже привязаны к profileHeaderView)
            avatarImageView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            avatarImageView.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            statsStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: padding),
            statsStackView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),
            statsStackView.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor),
            
            // Имя пользователя (под шапкой, отступы внутри wrapper)
            usernameLabel.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 10),
            usernameLabel.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -padding),
            
            // Статус (под именем, отступы внутри wrapper)
            statusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            // Стек кнопок (под статусом, отступы внутри wrapper)
            actionButtonsStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: padding),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -padding),
            actionButtonsStackView.heightAnchor.constraint(equalToConstant: 30),
            
            // Segmented Control (под кнопками, отступы внутри wrapper)
            contentSegmentedControl.topAnchor.constraint(equalTo: actionButtonsStackView.bottomAnchor, constant: padding),
            contentSegmentedControl.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: padding),
            contentSegmentedControl.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -padding),
            
            // Сетка постов (под Segmented Control, до кнопки выхода, ширина = ширине wrapper)
            postsCollectionView.topAnchor.constraint(equalTo: contentSegmentedControl.bottomAnchor, constant: padding),
            postsCollectionView.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor),
            postsCollectionView.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor),
            postsCollectionView.bottomAnchor.constraint(equalTo: signOutButton.topAnchor, constant: -padding),
            
            // Placeholder для программ (там же, где и сетка)
            programsPlaceholderView.topAnchor.constraint(equalTo: postsCollectionView.topAnchor),
            programsPlaceholderView.leadingAnchor.constraint(equalTo: postsCollectionView.leadingAnchor),
            programsPlaceholderView.trailingAnchor.constraint(equalTo: postsCollectionView.trailingAnchor),
            programsPlaceholderView.bottomAnchor.constraint(equalTo: postsCollectionView.bottomAnchor),

            // Кнопка Выхода (внизу wrapper)
            signOutButton.leadingAnchor.constraint(equalTo: contentWrapperView.leadingAnchor, constant: padding),
            signOutButton.trailingAnchor.constraint(equalTo: contentWrapperView.trailingAnchor, constant: -padding),
            signOutButton.bottomAnchor.constraint(equalTo: contentWrapperView.bottomAnchor, constant: -10),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
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
                            .cacheOriginalImage
                        ],
                        completionHandler: { result in
                            switch result {
                            case .success(let value):
                                print("Kingfisher: Image loaded successfully from \(value.source.url?.absoluteString ?? "N/A")")
                            case .failure(let error):
                                print("Kingfisher Error: Failed to load image - \(error.localizedDescription)")
                                self.avatarImageView.image = placeholder 
                                self.avatarImageView.tintColor = .darkGray
                            }
                        }
                    )
                } else {
                    self.avatarImageView.image = placeholder
                    self.avatarImageView.tintColor = .darkGray 
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

    func didFinishCreatingPost(_ controller: CreatePostViewController) {
        print("CreatePostViewController finished creating post.")
        controller.dismiss(animated: true) {
            // Обновляем все данные пользователя после создания поста
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

    // Вспомогательный Alert для теста (можно удалить или оставить для других нужд)
    private func showAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default))
         present(alert, animated: true)
     }
     
    // TODO: Actions для Follow/Message
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

// Delegate нужен, чтобы FlowLayout работал корректно (размеры и отступы)
// Конкретные методы для этого layout не требуются, т.к. все задано в init
// extension UserProfileFeedViewController: UICollectionViewDelegateFlowLayout {}

// MARK: - UICollectionViewDelegate

extension UserProfileFeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPost = viewModel.userPosts[indexPath.item]
        print("UserProfileFeedViewController: Выбран пост с ID: \(selectedPost.id ?? "N/A"), индекс: \(indexPath.item)")
        print("UserProfileFeedViewController: Всего постов: \(viewModel.userPosts.count)")
        
        // Проверяем содержимое массива
        for (index, post) in viewModel.userPosts.enumerated() {
            print("UserProfileFeedViewController: Пост #\(index): ID=\(post.id ?? "nil"), URL=\(post.imageURL)")
        }
        
        // Вызываем метод координатора для показа постов в полноэкранном просмотре
        // Пытаемся привести делегата к нужному типу координатора
        if let coordinator = delegate as? CurrentUserProfileCoordinator {
            print("UserProfileFeedViewController: Вызываем coordinator.showUserPostScroll")
            coordinator.showUserPostScroll(posts: viewModel.userPosts, startIndex: indexPath.item)
        } else if let coordinator = self.parent?.parent as? UserProfileCoordinator { // Пытаемся получить координатор из родительского контейнера
             print("UserProfileFeedViewController: Вызываем coordinator.showUserPostScroll (via parent)")
            // TODO: Нужен способ передать userID в UserProfileCoordinator
            // coordinator.showUserPostScroll(forUserID: viewModel.userID, posts: viewModel.userPosts, startIndex: indexPath.item)
        } else {
            print("UserProfileFeedViewController: ОШИБКА - не удалось получить координатора")
        }
    }
} 