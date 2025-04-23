import UIKit
import Kingfisher

// Протокол для обработки нажатия на имя пользователя в ячейке
protocol FullPostCellDelegate: AnyObject {
    func didTapUsername(in cell: FullPostCell)
}

class FullPostCell: UICollectionViewCell {

    static let identifier = "FullPostCell"
    weak var delegate: FullPostCellDelegate?

    // MARK: - UI Elements

    // -- Header --
    private lazy var authorAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18 // Маленький аватар
        imageView.backgroundColor = .darkGray // Placeholder
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .lightGray
        return imageView
    }()

    private lazy var authorUsernameButton: UIButton = { // Используем кнопку для легкого нажатия
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal) // Белый текст (Пункт 5)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(usernameTapped), for: .touchUpInside)
        return button
    }()

    // -- Post Image --
    private lazy var postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit // Чтобы видеть все изображение без обрезки
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black // Фон под картинкой черный
        return imageView
    }()

    // -- Footer --
    private lazy var likeCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white // Белый текст (Пункт 5)
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white // Белый текст (Пункт 5)
        label.numberOfLines = 0 // Может быть длинным
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black // Черный фон ячейки (Пункт 5)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.addSubview(authorAvatarImageView)
        contentView.addSubview(authorUsernameButton)
        contentView.addSubview(postImageView)
        contentView.addSubview(likeCountLabel)
        contentView.addSubview(captionLabel)
    }

    private func setupConstraints() {
        let padding: CGFloat = 10
        let headerHeight: CGFloat = 50 // Высота шапки с аватаром/именем
        let footerPadding: CGFloat = 8 // Отступ между элементами футера

        NSLayoutConstraint.activate([
            // Header
            authorAvatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            authorAvatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            authorAvatarImageView.widthAnchor.constraint(equalToConstant: 36),
            authorAvatarImageView.heightAnchor.constraint(equalToConstant: 36),

            authorUsernameButton.leadingAnchor.constraint(equalTo: authorAvatarImageView.trailingAnchor, constant: 8),
            authorUsernameButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            authorUsernameButton.centerYAnchor.constraint(equalTo: authorAvatarImageView.centerYAnchor),

            // Post Image - изменяем констрейнты для растягивания по высоте
            postImageView.topAnchor.constraint(equalTo: authorAvatarImageView.bottomAnchor, constant: padding), // Верх под хедером
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // УДАЛЕНО: Высота больше не привязана к ширине
            // postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0),
            // ДОБАВЛЕНО: Низ картинки привязан к верху лайков (с отступом)
            postImageView.bottomAnchor.constraint(equalTo: likeCountLabel.topAnchor, constant: -footerPadding),

            // Footer
            // likeCountLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: footerPadding), // Этот констрейнт уже не нужен, т.к. низ картинки привязан к верху лайков
            likeCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            likeCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            captionLabel.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: footerPadding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        print("FullPostCell: setupConstraints выполнен, контент имеет размеры: \(contentView.bounds)")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.kf.cancelDownloadTask()
        postImageView.image = nil
        authorAvatarImageView.kf.cancelDownloadTask()
        authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        authorUsernameButton.setTitle(nil, for: .normal)
        likeCountLabel.text = nil
        captionLabel.attributedText = nil // Используем attributedText
    }

    // MARK: - Configuration

    func configure(with post: Post) {
        print("FullPostCell: Начало конфигурации с постом ID=\(post.id ?? "nil")")
        
        // Автор
        authorUsernameButton.setTitle(post.authorUsername ?? "Unknown User", for: .normal)
        print("FullPostCell: Установлено имя автора: \(post.authorUsername ?? "Unknown User")")
        
        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
            print("FullPostCell: Загрузка аватара из URL: \(avatarUrlString)")
            authorAvatarImageView.kf.indicatorType = .activity
            authorAvatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray))
        } else {
            print("FullPostCell: Нет URL аватара, использую плейсхолдер")
            authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        }

        // Пост
        if let url = URL(string: post.imageURL) {
            print("FullPostCell: Загрузка изображения поста из URL: \(post.imageURL)")
            postImageView.kf.indicatorType = .activity
            // Загружаем изображение без плейсхолдера, т.к. фон черный
            postImageView.kf.setImage(
                with: url, 
                options: [.transition(.fade(0.2))],
                completionHandler: { result in
                    switch result {
                    case .success(let value):
                        print("FullPostCell: Изображение поста успешно загружено, размер: \(value.image.size)")
                    case .failure(let error):
                        print("FullPostCell: ОШИБКА загрузки изображения поста: \(error.localizedDescription)")
                    }
                }
            )
        } else {
            print("FullPostCell: ОШИБКА - URL изображения поста пустой или некорректный: \(post.imageURL)")
            // Если URL нет, показываем заглушку
            postImageView.image = UIImage(systemName: "photo.fill")?.withTintColor(.darkGray)
        }

        // Лайки (Пункт 3)
        // TODO: Правильное склонение "like/likes"?
        let likeText = post.likeCount == 1 ? "like" : "likes"
        likeCountLabel.text = "\(post.likeCount) \(likeText)"
        print("FullPostCell: Установлен счетчик лайков: \(post.likeCount)")

        // Подпись (Пункт 4 - часть 1)
        let attributedCaption = NSMutableAttributedString()
        if let username = post.authorUsername {
             // Имя автора - жирным
             attributedCaption.append(NSAttributedString(string: username, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: UIColor.white]))
             attributedCaption.append(NSAttributedString(string: " ", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.white])) // Пробел
        }
        // Текст подписи - обычным
        attributedCaption.append(NSAttributedString(string: post.caption ?? "", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.white]))
        captionLabel.attributedText = attributedCaption
        print("FullPostCell: Установлена подпись: \(post.caption ?? "")")
        
        print("FullPostCell: Конфигурация завершена")
    }

    // MARK: - Actions

    @objc private func usernameTapped() {
        delegate?.didTapUsername(in: self)
    }
} 