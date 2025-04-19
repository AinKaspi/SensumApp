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
class ProfileViewController: UIViewController {

    // MARK: - Dependencies
    var viewModel: PersonViewModel!
    var coordinator: PersonCoordinator?
    // Удаляем старый PersonViewControllerDelegate
    // weak var delegate: PersonViewControllerDelegate?

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
        // assert(viewModel != nil, "ViewModel not set for PersonViewController") 
        // Вместо assert делаем guard, если viewModel опционален
        guard viewModel != nil else {
             fatalError("ViewModel not injected into PersonViewController") // Или другая обработка ошибки
        }

        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupAvatarTapGesture(for: backgroundImageView)
        updateProfileDisplayFromViewModel() 
        // TODO: Настроить делегата для topMenuView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Обновляем UI ИЗ ViewModel
        updateProfileDisplayFromViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

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

        // Назначаем обработчик нажатия на фоновый аватар
        setupAvatarTapGesture(for: backgroundImageView)
        // Назначаем обработчик нажатия на статус
        setupStatusLabelTapGesture()
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
        // Получаем данные из ViewModel
        usernameLabel.text = viewModel.usernameText
        statusLabel.text = viewModel.statusText
        levelLabel.text = viewModel.levelText
        xpLabel.text = viewModel.xpText
        xpProgressBar.setProgress(viewModel.xpProgress, animated: view.window != nil) // Анимируем только если view видима
        
        // Устанавливаем аватары из ViewModel
        if let avatar = viewModel.avatarImage {
            backgroundImageView.image = avatar
            backgroundImageView.contentMode = .scaleAspectFill
            miniAvatarImageView.image = avatar
        } else {
            // Устанавливаем плейсхолдеры
            backgroundImageView.image = UIImage(systemName: "person.crop.circle.fill")
            backgroundImageView.tintColor = .darkGray
            backgroundImageView.contentMode = .scaleAspectFit 
            backgroundImageView.backgroundColor = UIColor(white: 0.1, alpha: 1.0) 
            miniAvatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            miniAvatarImageView.tintColor = .lightGray
            miniAvatarImageView.backgroundColor = .darkGray
        }
    }

    // MARK: - Avatar Handling
    private func setupAvatarTapGesture(for imageView: UIImageView) {
        // Убедимся, что старый жест удален, если он был
        imageView.gestureRecognizers?.forEach { imageView.removeGestureRecognizer($0) }
        
        imageView.isUserInteractionEnabled = true // Убедимся, что интерактивность включена
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        imageView.addGestureRecognizer(tapGesture)
    }

    @objc private func avatarTapped(_ sender: UITapGestureRecognizer) {
        // Определяем, по какому ImageView тапнули (если нужно будет разное поведение)
        // let tappedImageView = sender.view as? UIImageView
        // if tappedImageView == backgroundImageView { ... }
        
        // TODO: Проверить права доступа к галерее
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        // imagePickerController.allowsEditing = true // Разрешить редактирование?
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Status Handling (Новый раздел)
    private func setupStatusLabelTapGesture() {
        statusLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(statusLabelTapped))
        statusLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func statusLabelTapped() {
        // Показываем Alert для редактирования статуса
        let alertController = UIAlertController(title: "Изменить статус", message: nil, preferredStyle: .alert)
        
        // Добавляем текстовое поле
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Введите новый статус..."
            // Устанавливаем текущий статус как начальное значение
            textField.text = self?.viewModel.statusText.contains("placeholder") ?? true ? "" : self?.viewModel.statusText
        }
        
        // Кнопка Сохранить
        let saveAction = UIAlertAction(title: "Сохранить", style: .default) { [weak self, weak alertController] _ in
            guard let self = self, let textField = alertController?.textFields?.first else { return }
            let newStatus = textField.text ?? "" // Получаем новый статус
            
            // Вызываем ViewModel для сохранения
            self.viewModel.saveNewStatus(newStatus)
            
            // Обновляем UI (ViewModel должна была обновить свой userProfile)
            self.updateProfileDisplayFromViewModel()
        }
        
        // Кнопка Отмена
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    @objc private func followButtonTapped() {
        print("Follow button tapped - Action Placeholder")
    }
    
    // Метод settingsButtonTapped удален, т.к. обработка идет через делегат TopMenuViewDelegate
    /*
    @objc private func settingsButtonTapped() {
        delegate?.personViewControllerDidTapSettings(self)
    }
    */

}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        // Обновляем UI через ViewModel
        viewModel.saveNewAvatar(selectedImage) 
        // Обновляем UI немедленно (ViewModel сам обновит свое свойство avatarImage)
        backgroundImageView.image = selectedImage
        miniAvatarImageView.image = selectedImage
        backgroundImageView.contentMode = .scaleAspectFill
        
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Avatar File Management Helpers
extension ProfileViewController {
    // Оставляем эти хелперы приватными для VC, пока ViewModel не реализована
    private func getAvatarFileURL(forUserID userID: UUID) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "avatar_\(userID.uuidString).png"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    private func saveAvatarImage(_ image: UIImage, forUserID userID: UUID) -> Bool {
        guard let fileURL = getAvatarFileURL(forUserID: userID), let imageData = image.pngData() else { return false }
        do {
            try imageData.write(to: fileURL, options: .atomic)
            return true
        } catch {
            print("Error saving avatar image: \(error)")
            return false
        }
    }

    private func loadAvatarImage(forUserID userID: UUID) -> UIImage? {
        guard let fileURL = getAvatarFileURL(forUserID: userID),
              FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading avatar image: \(error)")
            return nil
        }
    }
}

// MARK: - TopMenuViewDelegate
extension ProfileViewController: TopMenuViewDelegate {
    func topMenuViewDidSelect(segment: TopMenuView.Segment) {
        print("--- PersonVC: Выбран сегмент меню: \(segment) ---")
        // Вызываем методы координатора для навигации
        switch segment {
        case .profile:
            // Ничего не делаем, мы уже здесь
            // (Или можно обеспечить возврат, если были показаны Stats/Achievements модально)
            break
        case .stats:
            coordinator?.showStats()
        // case .achievements: // Удалено
        //    coordinator?.showAchievements()
        //    break
        }
    }
    
    func topMenuViewDidTapSettings() {
        print("--- PersonVC: Нажата кнопка настроек --- ")
        // Вызываем координатора
        coordinator?.showSettings()
    }
}

// Удаляем пустой UIGestureRecognizerDelegate
/*
extension PersonViewController {
    // func gestureRecognizer(...) -> Bool { return true }
}
*/

