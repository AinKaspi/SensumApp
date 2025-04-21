import UIKit

// Этот VC будет отображать Макет 3 (Шапка с подписчиками, сетка постов)
// Он будет переиспользоваться для CurrentUserProfile и UserProfile (другого пользователя)
class UserProfileFeedViewController: UIViewController {

    // TODO: Добавить ViewModel для загрузки данных профиля и постов

    // MARK: - UI Elements (Placeholders)

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "User Profile Feed Grid (Mockup 3)"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Фон как в макете

        setupPlaceholderUI()

        // TODO: Настроить реальный UI:
        // - Шапка с аватаром, статами подписчиков/подписок
        // - Кнопки Follow/Message/Edit (в зависимости от ViewModel)
        // - Переключатель Grid/List(?)
        // - UICollectionView для сетки постов
    }

    private func setupPlaceholderUI() {
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Разместим по центру Safe Area для наглядности
            placeholderLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
} 