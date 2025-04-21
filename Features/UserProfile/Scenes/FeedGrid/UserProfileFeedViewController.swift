import UIKit
import Combine // Добавляем для биндингов
// TODO: Импортировать библиотеку для загрузки изображений (Kingfisher, SDWebImage, Nuke)?

// Этот VC будет отображать Макет 3 (Шапка с подписчиками, сетка постов)
// Он будет переиспользоваться для CurrentUserProfile и UserProfile (другого пользователя)
class UserProfileFeedViewController: UIViewController {

    // Добавляем ViewModel
    var viewModel: UserProfileFeedViewModel! // Используем !, т.к. он будет инжектирован координатором
    private var cancellables = Set<AnyCancellable>() // Для хранения подписок Combine

    // TODO: Добавить ViewModel для загрузки данных профиля и постов

    // MARK: - UI Elements
    
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
    private func createStatLabel(value: String, label: String) -> UIStackView {
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
    
    private lazy var postsStatStack: UIStackView = createStatLabel(value: "-", label: "Posts")
    private lazy var followersStatStack: UIStackView = createStatLabel(value: "-", label: "Followers")
    private lazy var followingStatStack: UIStackView = createStatLabel(value: "-", label: "Following")
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [postsStatStack, followersStatStack, followingStatStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
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

    // Кнопки
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
    
    // TODO: Добавить кнопки Follow/Message (показывать если !isCurrentUser)
    
    // --- Разделитель и Переключатель ---
    // TODO: Добавить разделитель
    // TODO: Добавить переключатель Grid/List
    
    // --- Сетка Постов (Placeholder) ---
    private lazy var postsCollectionView: UICollectionView = {
        // TODO: Настроить layout для сетки
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        // TODO: Зарегистрировать ячейку поста
        // collectionView.register(PostCell.self, forCellWithReuseIdentifier: "PostCell")
        // collectionView.dataSource = self
        // collectionView.delegate = self
        return collectionView
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
        // Добавляем основные компоненты
        view.addSubview(profileHeaderView)
        view.addSubview(usernameLabel)
        view.addSubview(statusLabel)
        view.addSubview(editProfileButton)
        view.addSubview(postsCollectionView) // Добавляем CollectionView
        
        // Добавляем элементы в шапку
        profileHeaderView.addSubview(avatarImageView)
        profileHeaderView.addSubview(statsStackView)
    }

    private func setupConstraints() {
        let padding: CGFloat = 15
        
        NSLayoutConstraint.activate([
            // Шапка
            profileHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileHeaderView.heightAnchor.constraint(equalToConstant: 100), // Примерная высота шапки
            
            // Аватар в шапке (слева)
            avatarImageView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: padding),
            avatarImageView.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Статы в шапке (справа от аватара)
            statsStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: padding),
            statsStackView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -padding),
            statsStackView.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor),
            
            // Имя пользователя (под шапкой)
            usernameLabel.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 10),
            usernameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            // Статус (под именем)
            statusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            // Кнопка Edit (под статусом)
            editProfileButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            editProfileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            editProfileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            editProfileButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Сетка постов (занимает оставшееся место)
            postsCollectionView.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: padding), // Или к разделителю/переключателю
            postsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            postsCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
                
                // TODO: Загрузить аватар из user.avatarURL
                // Например, с использованием Kingfisher:
                /*
                if let urlString = user.avatarURL, let url = URL(string: urlString) {
                    self.avatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
                } else {
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                }
                */
            }
            .store(in: &cancellables)
        
        // Подписка на состояние загрузки профиля
        viewModel.$isLoadingProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                // TODO: Показать/скрыть индикатор загрузки для шапки
                print("Profile loading state: \(isLoading)")
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
            
        // TODO: Добавить подписки для:
        // - viewModel.$userPosts -> обновить postsCollectionView
        // - viewModel.$isLoadingPosts -> индикатор для постов
        // - viewModel.$isFollowing -> обновить вид кнопки Follow/Edit
        // - viewModel.$isCurrentUser -> обновить вид кнопки Follow/Edit
        
        // Скрываем/показываем кнопку Edit в зависимости от isCurrentUser
        editProfileButton.isHidden = !viewModel.isCurrentUser
        // TODO: Добавить кнопки Follow/Message и скрывать/показывать их

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
        viewModel.editProfileButtonTapped()
    }
    
    // TODO: Actions для Follow/Message
} 