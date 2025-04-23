import UIKit
import Kingfisher

// Протокол для обработки нажатия на имя пользователя в ячейке
protocol FullPostCellDelegate: AnyObject {
    func didTapUsername(in cell: FullPostCell)
}

// НОВЫЙ ПРОТОКОЛ ДЕЛЕГАТА
protocol FullPostCellLayoutDelegate: AnyObject {
    func fullPostCell(_ cell: FullPostCell, didCalculateAspectRatio ratio: CGFloat, at indexPath: IndexPath)
}

class FullPostCell: UICollectionViewCell {

    static let identifier = "FullPostCell"
    weak var delegate: FullPostCellDelegate?
    weak var layoutDelegate: FullPostCellLayoutDelegate?
    var indexPath: IndexPath?

    // ВОЗВРАЩАЕМ свойство для хранения констрейнта
    private var imageAspectRatioConstraint: NSLayoutConstraint?

    // MARK: - UI Elements

    // -- Header --
    private lazy var authorAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18 // Маленький аватар
        imageView.backgroundColor = .darkGray // Placeholder color
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
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        // Убираем фон
        imageView.backgroundColor = .black 
        return imageView
    }()

    // -- Footer --
    private lazy var likeCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white // Белый текст (Пункт 5)
        // Убираем фон
        label.backgroundColor = .clear
        // Не даем этому лейблу сжиматься по вертикали
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white // Белый текст (Пункт 5)
        label.numberOfLines = 0 // Может быть длинным
        // Убираем фон
        label.backgroundColor = .clear
        // Не даем и этому лейблу сжиматься по вертикали
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Убираем фон
        contentView.backgroundColor = .black
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
        let footerPadding: CGFloat = 8
        
        // Создаем дефолтный констрейнт соотношения сторон 1:1
        // Он будет активирован ниже
        imageAspectRatioConstraint = postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 1.0)
        imageAspectRatioConstraint?.priority = .required // Используем required, т.к. он будет основным

        NSLayoutConstraint.activate([
            // УДАЛЯЕМ КОНСТРЕЙНТ ШИРИНЫ contentView
            // contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            // Header
            authorAvatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            authorAvatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            authorAvatarImageView.widthAnchor.constraint(equalToConstant: 36),
            authorAvatarImageView.heightAnchor.constraint(equalToConstant: 36),

            authorUsernameButton.leadingAnchor.constraint(equalTo: authorAvatarImageView.trailingAnchor, constant: 8),
            authorUsernameButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            authorUsernameButton.centerYAnchor.constraint(equalTo: authorAvatarImageView.centerYAnchor),

            // Post Image
            postImageView.topAnchor.constraint(equalTo: authorAvatarImageView.bottomAnchor, constant: padding),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // АКТИВИРУЕМ дефолтный констрейнт соотношения сторон
            imageAspectRatioConstraint!,

            // Footer
            likeCountLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: footerPadding),
            likeCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            likeCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            captionLabel.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: footerPadding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        print("FullPostCell: setupConstraints (с ДЕФОЛТНЫМ соотношением 1:1) выполнен")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.kf.cancelDownloadTask()
        postImageView.image = nil
        // Сбрасываем делегатов и indexPath
        delegate = nil
        layoutDelegate = nil
        indexPath = nil
        authorAvatarImageView.kf.cancelDownloadTask()
        authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        authorUsernameButton.setTitle(nil, for: .normal)
        likeCountLabel.text = nil
        captionLabel.attributedText = nil
        // Сбрасываем констрейнт к дефолтному значению 1:1 при переиспользовании
        updateImageAspectRatioConstraint(multiplier: 1.0)
        postImageView.image = nil // Убедимся, что картинки нет
    }

    // MARK: - Configuration

    func configure(with post: Post, indexPath: IndexPath) {
        print("FullPostCell: Начало конфигурации с постом ID=\(post.id ?? "nil"), indexPath: \(indexPath)")
        self.indexPath = indexPath

        postImageView.image = nil
        
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
            postImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.2))],
                completionHandler: { [weak self] result in
                    guard let self = self, let currentIndexPath = self.indexPath else { return }
                    switch result {
                    case .success(let value):
                        print("FullPostCell: Изображение поста успешно загружено для indexPath \(currentIndexPath), размер: \(value.image.size)")
                        guard value.image.size.width > 0 else { return } // Проверка ширины
                        let actualAspectRatio = value.image.size.height / value.image.size.width
                        // 1. Обновляем МНОЖИТЕЛЬ констрейнта и вызываем layoutIfNeeded
                        self.updateImageAspectRatioConstraint(multiplier: actualAspectRatio)
                        self.layoutIfNeeded() // Заставляем ячейку перерисоваться немедленно
                        // 2. Сообщаем контроллеру
                        self.layoutDelegate?.fullPostCell(self, didCalculateAspectRatio: actualAspectRatio, at: currentIndexPath)
                    case .failure(let error):
                        print("FullPostCell: ОШИБКА загрузки изображения поста для indexPath \(currentIndexPath): \(error.localizedDescription)")
                        // При ошибке можно оставить ratio 1:1 или установить другой
                        self.updateImageAspectRatioConstraint(multiplier: 1.0)
                        self.layoutIfNeeded()
                    }
                }
            )
        } else {
             print("FullPostCell: ОШИБКА - URL изображения поста пустой или некорректный: \(post.imageURL)")
             // Ставим дефолтный ratio 1:1
             updateImageAspectRatioConstraint(multiplier: 1.0)
             self.layoutIfNeeded()
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
        
        print("FullPostCell: Конфигурация завершена для indexPath \(indexPath)")
    }

    // Обновленный метод - меняет multiplier существующего констрейнта
    private func updateImageAspectRatioConstraint(multiplier: CGFloat) {
        guard let constraint = imageAspectRatioConstraint else { return }
        
        // Проверяем, изменился ли множитель, чтобы избежать лишней работы
        if constraint.multiplier != multiplier {
            // Деактивируем старый
            constraint.isActive = false
            // Создаем новый с тем же firstItem, attribute, relatedBy, secondItem, attribute
            // но новым multiplier
            imageAspectRatioConstraint = NSLayoutConstraint(item: constraint.firstItem as Any,
                                                          attribute: constraint.firstAttribute,
                                                          relatedBy: constraint.relation,
                                                          toItem: constraint.secondItem,
                                                          attribute: constraint.secondAttribute,
                                                          multiplier: multiplier, // Новый множитель
                                                          constant: constraint.constant)
            imageAspectRatioConstraint?.priority = .required
            // Активируем новый
            imageAspectRatioConstraint?.isActive = true
            print("FullPostCell: Обновлен multiplier aspect ratio constraint: \(multiplier)")
        } else {
             print("FullPostCell: Multiplier aspect ratio constraint уже равен \(multiplier), обновление не требуется.")
        }
    }

    // MARK: - Actions

    @objc private func usernameTapped() {
        delegate?.didTapUsername(in: self)
    }
} 
