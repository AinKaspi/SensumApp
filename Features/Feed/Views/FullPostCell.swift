import UIKit
import Kingfisher

// ОБНОВЛЯЕМ ДЕЛЕГАТ: Добавляем методы для Follow и Comments
protocol FullPostCellDelegate: AnyObject {
    func didTapUsername(in cell: FullPostCell)
    func didTapFollowButton(in cell: FullPostCell)
    func didTapLikeButton(in cell: FullPostCell)
    func didTapCommentButton(in cell: FullPostCell)
    func didTapShareButton(in cell: FullPostCell)
    // func didTapBookmarkButton(in cell: FullPostCell) // Удалено
    func didTapViewAllComments(in cell: FullPostCell)
    func fullPostCellDidToggleCaption(_ cell: FullPostCell, at indexPath: IndexPath)
}

class FullPostCell: UICollectionViewCell {

    static let identifier = "FullPostCell"
    weak var delegate: FullPostCellDelegate?
    var indexPath: IndexPath?
    
    // НОВОЕ: Замыкание для запроса обновления layout С ПЕРЕДАЧЕЙ ASPECT RATIO
    var needsLayoutUpdateAction: ((IndexPath, CGFloat) -> Void)?

    // ОБНОВЛЕНИЕ: Добавляем новые свойства
    private var isCaptionExpanded: Bool = false
    private var truncatedCaption: String? // Храним усеченный текст
    private var fullCaption: String? // Храним полный текст
    static let captionMaxLinesCollapsed = 3 // Сколько строк показывать в свернутом виде (СДЕЛАНО STATIC INTERNAL)

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

    private lazy var usernameAndFollowStackView: UIStackView = { // Стек для имени и кнопки Follow
        let stackView = UIStackView(arrangedSubviews: [authorUsernameButton, followButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    private lazy var authorUsernameButton: UIButton = { // Переименовано для ясности
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal) // Белый текст (Пункт 5)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(usernameTapped), for: .touchUpInside)
        // Уменьшим сопротивление сжатию, чтобы кнопка Follow не выталкивалась
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private lazy var followButton: UIButton = { // Новая кнопка
        // Используем конфигурацию для современных настроек
        var config = UIButton.Configuration.filled() // Используем filled для синего фона
        config.title = "Follow"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .small // Аналог cornerRadius = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8) // Современный аналог
        
        // Конфигурация для состояния .selected ("Following")
        var selectedConfig = UIButton.Configuration.plain() // Используем plain для рамки
        selectedConfig.title = "Following"
        selectedConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        selectedConfig.baseForegroundColor = .lightGray
        selectedConfig.background.strokeColor = .lightGray // Цвет рамки
        selectedConfig.background.strokeWidth = 1
        selectedConfig.cornerStyle = .small
        selectedConfig.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configurationUpdateHandler = { button in
            button.configuration = button.isSelected ? selectedConfig : config
        }
        
        button.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    // -- Post Image --
    private lazy var postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Убираем фон
        imageView.backgroundColor = .black 
        return imageView
    }()

    // -- Action Buttons --
    private lazy var likeButton: UIButton = createActionButton(systemName: "heart")
    private lazy var commentButton: UIButton = createActionButton(systemName: "message")
    private lazy var shareButton: UIButton = createActionButton(systemName: "paperplane")

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
        label.textColor = .white
        label.numberOfLines = FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(captionTapped))
        label.addGestureRecognizer(tapGesture)
        return label
    }()

    private lazy var viewAllCommentsButton: UIButton = { // Новая кнопка для комментариев
       let button = UIButton(type: .system)
       button.translatesAutoresizingMaskIntoConstraints = false
       button.setTitle("View all comments", for: .normal)
       button.titleLabel?.font = .systemFont(ofSize: 14)
       button.setTitleColor(.lightGray, for: .normal)
       button.contentHorizontalAlignment = .left
       button.addTarget(self, action: #selector(viewAllCommentsTapped), for: .touchUpInside)
       return button
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
        // Используем StackView для имени и кнопки Follow
        contentView.addSubview(usernameAndFollowStackView)
        contentView.addSubview(postImageView)
        // Добавляем кнопки действий
        contentView.addSubview(likeButton)
        contentView.addSubview(commentButton)
        contentView.addSubview(shareButton)
        // Добавляем футер
        contentView.addSubview(likeCountLabel)
        contentView.addSubview(captionLabel)
        // Добавляем кнопку просмотра комментов
        contentView.addSubview(viewAllCommentsButton)
    }

    private func setupConstraints() {
        let padding: CGFloat = 10
        let footerPadding: CGFloat = 8
        let buttonSize: CGFloat = 28 // Размер кнопок действий
        let buttonSpacing: CGFloat = 12 // Расстояние между кнопками
        
        // Создаем констрейнт соотношения сторон 1:1, но с НИЗКИМ приоритетом
        let defaultAspectRatioConstraint = postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 1.0)
        defaultAspectRatioConstraint.priority = .defaultHigh // 750 (ниже чем required 1000)

        NSLayoutConstraint.activate([
            // УДАЛЯЕМ КОНСТРЕЙНТ ШИРИНЫ contentView
            // contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            // Header
            authorAvatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            authorAvatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            authorAvatarImageView.widthAnchor.constraint(equalToConstant: 30),
            authorAvatarImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // StackView для имени и кнопки Follow
            usernameAndFollowStackView.leadingAnchor.constraint(equalTo: authorAvatarImageView.trailingAnchor, constant: padding),
            usernameAndFollowStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -padding), // Не прижимаем к правому краю жестко
            usernameAndFollowStackView.centerYAnchor.constraint(equalTo: authorAvatarImageView.centerYAnchor),
            
            // Post Image
            postImageView.topAnchor.constraint(equalTo: authorAvatarImageView.bottomAnchor, constant: padding),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Активируем дефолтный констрейнт с НИЗКИМ приоритетом
            defaultAspectRatioConstraint,

            // Action Buttons (Под картинкой)
            likeButton.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: buttonSpacing),
            likeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            likeButton.widthAnchor.constraint(equalToConstant: buttonSize),
            likeButton.heightAnchor.constraint(equalToConstant: buttonSize),

            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: buttonSpacing),
            commentButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            commentButton.widthAnchor.constraint(equalToConstant: buttonSize),
            commentButton.heightAnchor.constraint(equalToConstant: buttonSize),

            shareButton.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: buttonSpacing),
            shareButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: buttonSize),
            shareButton.heightAnchor.constraint(equalToConstant: buttonSize),
            
            // Footer (Теперь под кнопками действий)
            likeCountLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: footerPadding),
            likeCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            likeCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            captionLabel.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: footerPadding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            // Низ captionLabel НЕ привязан жестко к низу, чтобы кнопка комментов могла встать под ним
            
            // View All Comments Button
            viewAllCommentsButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4), // Маленький отступ от подписи
            viewAllCommentsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            viewAllCommentsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            viewAllCommentsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding) // Низ кнопки привязан к низу ячейки
        ])
        
        print("FullPostCell: setupConstraints (с НИЗКИМ приоритетом ratio 1:1) выполнен")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        print("Preparing cell for reuse")
        isCaptionExpanded = false
        
        // Исправление: проверяем наличие indexPath
        if let currentPath = indexPath {
            updateCaptionDisplay(indexPath: currentPath)
        }
        
        // Сбрасываем содержимое
        postImageView.kf.cancelDownloadTask()
        postImageView.image = nil
        // Сбрасываем делегатов и indexPath
        delegate = nil
        indexPath = nil
        authorAvatarImageView.kf.cancelDownloadTask()
        authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        authorUsernameButton.setTitle(nil, for: .normal)
        likeCountLabel.text = nil
        captionLabel.attributedText = nil
        truncatedCaption = nil
        fullCaption = nil
        // Обнуляем замыкание
        needsLayoutUpdateAction = nil 
    }

    // MARK: - Configuration

    func configure(with post: Post, indexPath: IndexPath, needsLayoutUpdateAction: ((IndexPath, CGFloat) -> Void)?) {
        self.indexPath = indexPath
        self.needsLayoutUpdateAction = needsLayoutUpdateAction
        print("FullPostCell: Начало конфигурации с постом ID=\(post.id ?? "nil"), indexPath: \(indexPath)")

        // Сброс перед конфигурацией
        postImageView.image = nil
        isCaptionExpanded = false
        truncatedCaption = nil
        fullCaption = post.caption ?? ""
        
        // Устанавливаем полный текст и начальное кол-во строк
        captionLabel.text = fullCaption
        captionLabel.numberOfLines = FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC
        
        // Вызываем обновленный updateCaptionDisplay С ПЕРЕДАЧЕЙ indexPath
        updateCaptionDisplay(indexPath: indexPath)

        // Автор и кнопка Follow
        authorUsernameButton.setTitle(post.authorUsername ?? "Unknown User", for: .normal)
        // Используем реальное поле isFollowed (если оно будет добавлено в модель/логику)
        // let isFollowed = post.isFollowedByCurrentUser ?? false 
        let isFollowed = false // Пока оставляем заглушку
        followButton.isSelected = isFollowed
        // Меняем вид кнопки Follow
        followButton.backgroundColor = isFollowed ? .clear : .systemBlue
        followButton.layer.borderWidth = isFollowed ? 1 : 0
        followButton.layer.borderColor = isFollowed ? UIColor.lightGray.cgColor : UIColor.clear.cgColor
        // Скрываем кнопку Follow для своего поста?
        // followButton.isHidden = post.userID == CurrentUserService.shared.currentUser?.id 

        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
            print("FullPostCell: Загрузка аватара из URL: \(avatarUrlString)")
            authorAvatarImageView.kf.indicatorType = .activity
            authorAvatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray))
        } else {
            print("FullPostCell: Нет URL аватара, использую плейсхолдер")
            authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        }

        // Пост - используем превью или первый медиа-элемент
        // Сначала проверяем gridThumbnailURL
        if let url = URL(string: post.gridThumbnailURL), !post.gridThumbnailURL.isEmpty {
            print("FullPostCell: Загрузка изображения поста из gridThumbnailURL: \(post.gridThumbnailURL)")
            loadPostImage(from: url, indexPath: indexPath)
        }
        // Иначе используем первый элемент mediaItems
        else if let firstMediaItem = post.mediaItems.first, let url = URL(string: firstMediaItem.url) {
            print("FullPostCell: Загрузка изображения поста из mediaItems[0]: \(firstMediaItem.url)")
            loadPostImage(from: url, indexPath: indexPath)
        } else {
            print("FullPostCell: ОШИБКА - URL изображения поста отсутствует")
            // Устанавливаем placeholder
            postImageView.image = UIImage(systemName: "photo")?.withTintColor(.darkGray)
            // Вызываем замыкание для обновления с дефолтным ratio 1.0
            if let currentPath = self.indexPath, let updateAction = self.needsLayoutUpdateAction {
                updateAction(currentPath, 1.0) // Передаем дефолтный aspect ratio
            }
        }

        // Лайки
        likeButton.isSelected = post.isLiked
        // TODO: Сделать текст "Liked by..." или просто "X likes"
        likeCountLabel.text = "\(post.likeCount) likes"

        // Комментарии
        if post.commentCount > 0 {
            viewAllCommentsButton.setTitle("View all \(post.commentCount) comments", for: .normal)
            viewAllCommentsButton.isHidden = false
        } else {
            viewAllCommentsButton.isHidden = true // Скрываем, если комментов нет
        }
        
        print("FullPostCell: Конфигурация завершена для indexPath \(indexPath)")
    }

    // Метод теперь принимает indexPath
    private func updateCaptionDisplay(indexPath: IndexPath) {
        // Сначала проверяем, нужно ли вообще усечение
        if needsTruncation(label: captionLabel, maxLines: FullPostCell.captionMaxLinesCollapsed) { // ИСПОЛЬЗУЕМ STATIC
             // Используем переданный indexPath для лога
             print("FullPostCell [\(indexPath.item)]: Caption needs truncation AFTER aspect ratio update.")
             truncatedCaption = truncateText(label: captionLabel, maxLines: FullPostCell.captionMaxLinesCollapsed) + " ... more" // ИСПОЛЬЗУЕМ STATIC
             captionLabel.text = isCaptionExpanded ? fullCaption : truncatedCaption
             captionLabel.numberOfLines = isCaptionExpanded ? 0 : FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC
        } else {
            // Используем переданный indexPath для лога
            print("FullPostCell [\(indexPath.item)]: Caption fits AFTER aspect ratio update.")
            truncatedCaption = nil
            captionLabel.text = fullCaption
            captionLabel.numberOfLines = 0
            isCaptionExpanded = true // Считаем развернутым
        }
    }

    // Вспомогательный метод для загрузки изображения поста
    private func loadPostImage(from url: URL, indexPath: IndexPath) {
        postImageView.kf.indicatorType = .activity
        // Определяем плейсхолдер
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.darkGray)
        
        postImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [.transition(.fade(0.2))],
            completionHandler: { [weak self] result in
                // Используем слабую ссылку на self
                guard let self = self, let currentIndexPath = self.indexPath, let updateAction = self.needsLayoutUpdateAction else { return }
                var finalAspectRatio: CGFloat = 1.0 // Дефолтное значение
                
                switch result {
                case .success(let value):
                    print("FullPostCell: Изображение поста успешно загружено для indexPath \(currentIndexPath), размер: \(value.image.size)")
                    if value.image.size.width > 0 {
                        finalAspectRatio = value.image.size.height / value.image.size.width
                    }
                case .failure(let error):
                    print("FullPostCell: ОШИБКА загрузки изображения поста для indexPath \(currentIndexPath): \(error.localizedDescription)")
                    // Используем дефолтное ratio 1.0
                }
                // Вызываем замыкание для обновления размера с ФИНАЛЬНЫМ aspect ratio
                updateAction(currentIndexPath, finalAspectRatio)
            }
        )
    }

    // MARK: - Actions

    @objc private func usernameTapped() {
        delegate?.didTapUsername(in: self)
    }

    @objc private func followButtonTapped() {
        delegate?.didTapFollowButton(in: self)
    }

    // Вспомогательный метод для создания кнопок (добавляем таргеты)
    private func createActionButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: systemName + ".fill", withConfiguration: config), for: .selected) // Для Like/Bookmark
        button.tintColor = .white
        
        // Определяем селектор в зависимости от systemName (можно сделать элегантнее)
        let selector: Selector
        switch systemName {
            case "heart": selector = #selector(likeButtonTapped)
            case "message": selector = #selector(commentButtonTapped)
            case "paperplane": selector = #selector(shareButtonTapped)
            default: selector = #selector(actionButtonTapped) // Общий обработчик по умолчанию
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    // НОВЫЕ ОБРАБОТЧИКИ ДЛЯ КНОПОК
    @objc private func likeButtonTapped() {
        // Меняем состояние локально для быстрого отклика
        likeButton.isSelected.toggle()
        // Уведомляем делегата
        delegate?.didTapLikeButton(in: self)
    }
    
    @objc private func commentButtonTapped() {
        delegate?.didTapCommentButton(in: self)
    }
    
    @objc private func shareButtonTapped() {
        delegate?.didTapShareButton(in: self)
    }
    
    @objc private func viewAllCommentsTapped() {
        delegate?.didTapViewAllComments(in: self)
    }
    
    // Заглушка, если селектор не найден
    @objc private func actionButtonTapped() {
        print("Action button tapped - selector not specified")
    }

    @objc private func captionTapped(_ sender: UITapGestureRecognizer) {
        guard let indexPath = indexPath else {
            print("IndexPath is nil in captionTapped")
            return
        }
        
        isCaptionExpanded.toggle()
        
        updateCaptionDisplay(indexPath: indexPath)
        
        // Уведомляем делегата об изменении размера ячейки
        delegate?.fullPostCellDidToggleCaption(self, at: indexPath)
    }
    
    // MARK: - Helpers
    
    // Проверяет, действительно ли текст обрезается
    private func needsTruncation(label: UILabel, maxLines: Int) -> Bool {
        guard let text = label.text, !text.isEmpty else { return false }
        
        // Создаем временный лейбл с 0 строк, чтобы измерить полную высоту
        let tempLabel = UILabel()
        tempLabel.font = label.font
        tempLabel.text = text
        tempLabel.numberOfLines = 0
        tempLabel.frame.size.width = label.bounds.width // Важно: используем текущую ширину
        let fullSize = tempLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        // Создаем временный лейбл с N строками
        tempLabel.numberOfLines = maxLines
        let truncatedSize = tempLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // Если полная высота больше усеченной (с небольшой погрешностью)
        return fullSize.height > truncatedSize.height + 1 
    }
    
    // Генерирует усеченный текст (упрощенно)
    private func truncateText(label: UILabel, maxLines: Int) -> String {
        // Эта реализация очень упрощенная, не всегда точно обрезает
        // В идеале нужно использовать CTFramesetter для точного расчета
        guard let text = label.text else { return "" }
        
        var lines = 0
        var truncatedText = ""
        text.enumerateLines { line, stop in
            lines += 1
            if lines <= maxLines {
                truncatedText += line + (lines == maxLines ? "" : "\n") 
            } else {
                stop = true
            }
        }
        // Удаляем последний символ, если это перенос строки, перед добавлением "..."
        if truncatedText.last == "\n" {
            truncatedText.removeLast()
        }
        return truncatedText
    }
} 
