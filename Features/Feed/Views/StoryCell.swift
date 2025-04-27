import UIKit
import Kingfisher

class StoryCell: UICollectionViewCell {
    static let identifier = "StoryCell"

    // MARK: - UI Elements

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 40 // 80 / 2
        imageView.backgroundColor = .darkGray
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .lightGray
        // TODO: Добавить обводку (градиентный слой?)
        imageView.layer.borderWidth = 2 // Временная простая обводка
        imageView.layer.borderColor = UIColor.clear.cgColor // Изначально прозрачная
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular) // Размер шрифта 13pt (26px / 2?)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // TODO: Добавить "+" overlay для своего аватара

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        usernameLabel.text = nil
        // Сброс обводки
        avatarImageView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
    }

    private func setupConstraints() {
        let avatarSize: CGFloat = 80
        let labelTopPadding: CGFloat = 8 // Отступ от кружка до имени (26pt / 2?)

        NSLayoutConstraint.activate([
            // Аватар (центр по горизонтали, верх)
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),

            // Имя пользователя (под аватаром)
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: labelTopPadding),
            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Привязываем низ к низу ячейки, чтобы определить ее высоту
            usernameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(username: String, avatarURL: String?, hasNewContent: Bool = false) {
        usernameLabel.text = username

        let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        if let urlString = avatarURL, let url = URL(string: urlString) {
            avatarImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.image = placeholder
        }
        
        // TODO: Реализовать градиентную обводку, если hasNewContent = true
        if hasNewContent {
             avatarImageView.layer.borderColor = UIColor.orange.cgColor // Временная обводка
        } else {
             avatarImageView.layer.borderColor = UIColor.clear.cgColor
        }
        
        // TODO: Показать/скрыть "+" overlay, если это ячейка текущего пользователя
    }
}
