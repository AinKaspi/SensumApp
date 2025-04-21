import UIKit
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
    // ViewModel нужно будет адаптировать или заменить
    var viewModel: PersonViewModel! // Оставим пока старый
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
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
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

    // --- Жизненный цикл и настройка ---
    override func viewDidLoad() {
        super.viewDidLoad()
        guard viewModel != nil else {
             fatalError("ViewModel not injected into UserProfileCardViewController")
        }

        view.backgroundColor = .black // Оставим черный фон
        setupViews()
        setupConstraints()
        // Убираем обработку тапа по аватару, это не для экрана Card
        // setupAvatarTapGesture(for: backgroundImageView) 
        updateProfileDisplayFromViewModel() 
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
            xpLabel.leadingAnchor.constraint(greaterThanOrEqualTo: levelLabel.trailingAnchor, constant: smallPadding)
        ])
    }

    // MARK: - Data Handling
    private func updateProfileDisplayFromViewModel() {
        // Логика остается, будет получать данные из адаптированной ViewModel
        usernameLabel.text = viewModel.usernameText
        statusLabel.text = viewModel.statusText
        levelLabel.text = viewModel.levelText
        xpLabel.text = viewModel.xpText
        xpProgressBar.setProgress(viewModel.xpProgress, animated: view.window != nil)
        
        if let avatar = viewModel.avatarImage {
            backgroundImageView.image = avatar
            backgroundImageView.contentMode = .scaleAspectFill
            miniAvatarImageView.image = avatar
        } else {
            // Плейсхолдеры
            backgroundImageView.image = UIImage(systemName: "person.crop.circle.fill")
            backgroundImageView.tintColor = .darkGray
            backgroundImageView.contentMode = .scaleAspectFit 
            backgroundImageView.backgroundColor = UIColor(white: 0.1, alpha: 1.0) 
            miniAvatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            miniAvatarImageView.tintColor = .lightGray
            miniAvatarImageView.backgroundColor = .darkGray
        }
    }

    // Убираем все, что связано с редактированием аватара и статуса
    // MARK: - Avatar Handling
    /*
    private func setupAvatarTapGesture(for imageView: UIImageView) { ... }
    @objc private func avatarTapped(_ sender: UITapGestureRecognizer) { ... }
    */
    
    // MARK: - Status Handling
    /*
    private func setupStatusLabelTapGesture() { ... }
    @objc private func statusLabelTapped() { ... }
    */
    
    // MARK: - Actions
    @objc private func followButtonTapped() {
        print("Follow button tapped - Action Placeholder - Should be handled by Container/ViewModel?")
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

