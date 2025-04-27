import UIKit
import Kingfisher // Добавляем для аватаров
import Combine // Добавляем для биндингов
// Удаляем import DGCharts
// import DGCharts 

// Удаляем временные модели отсюда
/*
// --- Модели Данных (Оставляем здесь временно) ---
struct Achievement { // TODO: Вынести в Models
    let id: String
    let name: String
    let iconName: String
}

struct FeedEvent { // TODO: Вынести в Models
    let id: String
    let description: String
    let timestamp: Date
}
*/

// --- Протокол Делегата (Оставляем здесь временно) ---
// TODO: Перенести в файл Координатора или ViewModel?
// protocol PersonViewControllerDelegate: AnyObject {
    // Пока не используем, но оставим для будущих Stats/Achievements
    // func personViewControllerDidRequestShowAllAchievements(_ controller: PersonViewController)
    // func personViewControllerDidRequestShowAllFeed(_ controller: PersonViewController)
    // func personViewControllerDidTapSettings(_ controller: PersonViewController)
// }

// --- Класс ViewController ---
// Переименовываем класс в UserProfileCardViewController
// Возвращаем соответствие протоколам для ImagePicker (пока оставим, хотя выбор аватара тут не нужен будет)
class UserProfileCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    // MARK: - Dependencies
    // Меняем тип ViewModel
    var viewModel: UserProfileCardViewModel! 
    private var cancellables = Set<AnyCancellable>()
    // Координатор тут не нужен, управляет контейнер
    // var coordinator: PersonCoordinator?

    // MARK: - UI Properties
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .darkGray // Placeholder
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var bottomInfoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Добавляем градиентный фон вместо полупрозрачного черного
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [0.0, 0.4, 1.0] // Примерные точки градиента
        // Важно: Frame градиента нужно будет обновить в viewDidLayoutSubviews
        view.layer.insertSublayer(gradientLayer, at: 0)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private lazy var miniAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .lightGray // Placeholder
        // Добавляем рамку, как в дизайне
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()

    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()

    private lazy var followButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Стиль будет обновляться в setupBindings
        button.setTitle("Follow", for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 2 // Ограничиваем двумя строками
        // TODO: Добавить возможность редактирования статуса
        return label
    }()

    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .right
        return label
    }()

    private lazy var xpProgressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .cyan // Используем пока один цвет
        progressView.trackTintColor = UIColor.darkGray.withAlphaComponent(0.5) // Более темный трек
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        // TODO: Попробовать реализовать градиентный progressTintColor
        return progressView
    }()

    // Индикатор загрузки
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white // На случай, если фон темный
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // --- Жизненный цикл и настройка ---
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into UserProfileCardViewController")

        view.backgroundColor = .black // Оставим черный фон
        setupViews()
        setupConstraints()
        // Вызываем setupBindings
        setupBindings()
        // Убираем обработку тапа по аватару, это не для экрана Card
        // setupAvatarTapGesture(for: backgroundImageView) 
        // TODO: Убрать ненужную логику делегата TopMenuView из этого VC
    }

    // Убираем viewWillAppear/Disappear, т.к. управляет контейнер
    /*
    override func viewWillAppear(_ animated: Bool) { ... }
    override func viewWillDisappear(_ animated: Bool) { ... }
    */

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем frame градиентного слоя, чтобы он соответствовал размеру контейнера
        if let gradientLayer = bottomInfoContainerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bottomInfoContainerView.bounds
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(backgroundImageView)
        view.addSubview(bottomInfoContainerView)
        view.addSubview(activityIndicator) // Добавляем индикатор

        bottomInfoContainerView.addSubview(miniAvatarImageView)
        bottomInfoContainerView.addSubview(usernameLabel)
        bottomInfoContainerView.addSubview(followButton)
        bottomInfoContainerView.addSubview(statusLabel)
        bottomInfoContainerView.addSubview(levelLabel)
        bottomInfoContainerView.addSubview(xpProgressBar)
        bottomInfoContainerView.addSubview(xpLabel)
    }

    private func setupConstraints() {
        // Фоновое изображение
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Нижний блок информации
        NSLayoutConstraint.activate([
            bottomInfoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomInfoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomInfoContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // Прижимаем к самому низу экрана
        ])

        // Констрейнты ВНУТРИ нижнего блока
        let padding: CGFloat = 20 // Увеличим отступы
        let smallPadding: CGFloat = 12

        NSLayoutConstraint.activate([
            // Аватар
            miniAvatarImageView.topAnchor.constraint(equalTo: bottomInfoContainerView.topAnchor, constant: padding),
            miniAvatarImageView.leadingAnchor.constraint(equalTo: bottomInfoContainerView.leadingAnchor, constant: padding),
            miniAvatarImageView.widthAnchor.constraint(equalToConstant: 50),
            miniAvatarImageView.heightAnchor.constraint(equalToConstant: 50),

            // Кнопка Follow
            followButton.trailingAnchor.constraint(equalTo: bottomInfoContainerView.trailingAnchor, constant: -padding),
            followButton.centerYAnchor.constraint(equalTo: miniAvatarImageView.centerYAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 90), // Чуть шире
            followButton.heightAnchor.constraint(equalToConstant: 34), // Чуть выше

            // Имя пользователя
            usernameLabel.leadingAnchor.constraint(equalTo: miniAvatarImageView.trailingAnchor, constant: smallPadding),
            usernameLabel.trailingAnchor.constraint(equalTo: followButton.leadingAnchor, constant: -smallPadding),
            usernameLabel.centerYAnchor.constraint(equalTo: miniAvatarImageView.centerYAnchor),

            // Статус
            statusLabel.topAnchor.constraint(equalTo: miniAvatarImageView.bottomAnchor, constant: smallPadding),
            statusLabel.leadingAnchor.constraint(equalTo: bottomInfoContainerView.leadingAnchor, constant: padding),
            statusLabel.trailingAnchor.constraint(equalTo: bottomInfoContainerView.trailingAnchor, constant: -padding),

            // Прогресс бар XP
            xpProgressBar.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: padding),
            xpProgressBar.leadingAnchor.constraint(equalTo: bottomInfoContainerView.leadingAnchor, constant: padding),
            xpProgressBar.trailingAnchor.constraint(equalTo: bottomInfoContainerView.trailingAnchor, constant: -padding),

            // Уровень
            levelLabel.topAnchor.constraint(equalTo: xpProgressBar.bottomAnchor, constant: smallPadding),
            levelLabel.leadingAnchor.constraint(equalTo: bottomInfoContainerView.leadingAnchor, constant: padding),
            levelLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding), // Привязываем к Safe Area низу контейнера

            // XP Лейбл
            xpLabel.centerYAnchor.constraint(equalTo: levelLabel.centerYAnchor),
            xpLabel.trailingAnchor.constraint(equalTo: bottomInfoContainerView.trailingAnchor, constant: -padding),
            xpLabel.leadingAnchor.constraint(greaterThanOrEqualTo: levelLabel.trailingAnchor, constant: smallPadding),
            
            // Констрейнты для индикатора
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Bindings
    private func setupBindings() {
        guard let viewModel = viewModel else { return }
        
        // Подписка на данные пользователя
        viewModel.$userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.usernameLabel.text = user?.username ?? "-"
                self?.statusLabel.text = user?.status ?? ""
                self?.updateAvatar(url: user?.avatarURL)
            }
            .store(in: &cancellables)
            
        // Подписка на данные прогресса
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressData in
                guard let data = progressData else { return }
                self?.levelLabel.text = "Level \(data.level)"
                self?.xpLabel.text = "\(data.currentXP)/\(data.xpToNextLevel) XP"
                let progress = data.xpToNextLevel > 0 ? Float(data.currentXP) / Float(data.xpToNextLevel) : 0
                self?.xpProgressBar.setProgress(max(0.0, min(1.0, progress)), animated: self?.view.window != nil)
            }
            .store(in: &cancellables)
            
        // Подписка на статус подписки
        viewModel.$isFollowing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFollowing in
                self?.configureFollowButton(isFollowing: isFollowing)
            }
            .store(in: &cancellables)
            
        // Подписка на состояние загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.activityIndicator.isHidden = !isLoading
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.bottomInfoContainerView.isHidden = true // Скрываем инфо во время загрузки
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.bottomInfoContainerView.isHidden = false
                }
            }
            .store(in: &cancellables)
            
        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                // TODO: Показать Alert?
                print("*** UserProfileCardVC Error: \(message) ***")
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Update Helpers
    
    private func updateAvatar(url avatarURL: String?) {
        let placeholder = UIImage(systemName: "person.crop.circle.fill")?.withTintColor(.darkGray)
        let miniPlaceholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        
        if let urlString = avatarURL, let url = URL(string: urlString) {
            // Загружаем фон
            backgroundImageView.kf.indicatorType = .activity
            backgroundImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))]) { result in
                if case .failure = result { self.backgroundImageView.image = placeholder }
            }
            // Загружаем мини-аватар
            miniAvatarImageView.kf.setImage(with: url, placeholder: miniPlaceholder, options: [.transition(.fade(0.2))]) { result in
                 if case .failure = result { self.miniAvatarImageView.image = miniPlaceholder }
            }
        } else {
            backgroundImageView.image = placeholder
            backgroundImageView.tintColor = .darkGray
            backgroundImageView.contentMode = .scaleAspectFit 
            backgroundImageView.backgroundColor = UIColor(white: 0.1, alpha: 1.0) 
            miniAvatarImageView.image = miniPlaceholder
            miniAvatarImageView.tintColor = .lightGray
            miniAvatarImageView.backgroundColor = .darkGray
        }
    }
    
    private func configureFollowButton(isFollowing: Bool) {
        // Скрываем кнопку, если это профиль текущего пользователя
        followButton.isHidden = viewModel.isCurrentUser 
        if viewModel.isCurrentUser { return }
        
        if isFollowing {
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = .clear
            followButton.setTitleColor(.lightGray, for: .normal)
            followButton.layer.borderWidth = 1
            followButton.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = .white
            followButton.setTitleColor(.black, for: .normal)
            followButton.layer.borderWidth = 0
        }
    }

    // MARK: - Actions
    @objc private func followButtonTapped() {
        print("Follow button tapped")
        viewModel.followButtonTapped() // Вызываем ViewModel
    }
}

// Убираем ненужные расширения
/*
// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension UserProfileCardViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate { ... }

// MARK: - Avatar File Management Helpers
extension UserProfileCardViewController { ... }

// MARK: - TopMenuViewDelegate
extension UserProfileCardViewController: TopMenuViewDelegate { ... }
*/

