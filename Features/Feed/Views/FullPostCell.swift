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
    // УДАЛЯЕМ делегат для toggle caption, он больше не нужен для обновления layout
    // func fullPostCellDidToggleCaption(_ cell: FullPostCell, at indexPath: IndexPath)
    // ДОБАВЛЯЕМ новый метод делегата для запроса обновления layout
    func fullPostCellDidRequestLayoutUpdate(at indexPath: IndexPath)
}

class FullPostCell: UICollectionViewCell {

    static let identifier = "FullPostCell"
    weak var delegate: FullPostCellDelegate?
    var indexPath: IndexPath?
    
    // УДАЛЯЕМ замыкание для запроса обновления layout
    // var needsLayoutUpdateAction: ((IndexPath, CGFloat) -> Void)?
    
    // Добавляем свойство для хранения активного констрейнта соотношения сторон
    private var imageAspectRatioConstraint: NSLayoutConstraint?

    // ОБНОВЛЕНИЕ: Добавляем новые свойства
    private var isCaptionExpanded: Bool = false
    private var truncatedCaption: String? // Храним усеченный текст
    private var fullCaption: String? // Храним полный текст
    static let captionMaxLinesCollapsed = 3 // Сколько строк показывать в свернутом виде (СДЕЛАНО STATIC INTERNAL)

    // Добавляем свойства для хранения констрейнтов, управляющих низом ячейки
    private var captionBottomConstraint: NSLayoutConstraint?
    private var commentsButtonBottomConstraint: NSLayoutConstraint?

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

    // -- Footer Stack --
    private lazy var footerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [likeCountLabel, captionLabel, viewAllCommentsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4 // Уменьшаем отступ для более компактного вида
        stackView.alignment = .fill // Элементы растягиваются по ширине
        stackView.distribution = .fill // Распределение по высоте
        return stackView
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
        // Добавляем footerStackView вместо отдельных элементов
        contentView.addSubview(footerStackView)
    }

    private func setupConstraints() {
        let padding: CGFloat = 10
        let footerPadding: CGFloat = 8
        let buttonSize: CGFloat = 28 // Размер кнопок действий
        let buttonSpacing: CGFloat = 12 // Расстояние между кнопками
        
        // УДАЛЯЕМ создание и активацию дефолтного констрейнта соотношения сторон
        // let defaultAspectRatioConstraint = postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 1.0)
        // defaultAspectRatioConstraint.priority = .defaultHigh // 750 (ниже чем required 1000)

        NSLayoutConstraint.activate([
            // УДАЛЯЕМ КОНСТРЕЙНТ ШИРИНЫ contentView
            // contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            // ---> ДОБАВЛЯЕМ ЭТОТ КОНСТРЕЙНТ <--- 
            // Принудительно устанавливаем ширину contentView равной ширине ячейки
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            
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
            // УДАЛЯЕМ активацию дефолтного констрейнта
            // defaultAspectRatioConstraint,

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
            
            // Footer Stack View
            footerStackView.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: footerPadding), // Отступ от кнопок
            footerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            footerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            footerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -footerPadding) // Привязываем низ стека к низу ячейки
        ])
        
        // Создаем, но НЕ активируем констрейнты для низа ячейки
        // captionBottomConstraint = captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -footerPadding)
        // commentsButtonBottomConstraint = viewAllCommentsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -footerPadding)
        
        print("FullPostCell: setupConstraints выполнен")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        print("Preparing cell for reuse")
        isCaptionExpanded = false
        
        // Исправление: проверяем наличие indexPath
        if let currentPath = indexPath {
            updateCaptionDisplay()
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
        // Обнуляем замыкание --> УДАЛЕНО
        // needsLayoutUpdateAction = nil 
        
        // Деактивируем и удаляем старый констрейнт соотношения сторон
        if let constraint = imageAspectRatioConstraint {
            constraint.isActive = false
        }
        imageAspectRatioConstraint = nil
    }

    // MARK: - Configuration
    
    // УДАЛЯЕМ параметр needsLayoutUpdateAction
    func configure(with post: Post, indexPath: IndexPath) {
        self.indexPath = indexPath
        // self.needsLayoutUpdateAction = needsLayoutUpdateAction --> УДАЛЕНО
        print("FullPostCell: Начало конфигурации с постом ID=\(post.id ?? "nil"), indexPath: \(indexPath)")

        // --- Сброс состояния --- 
        postImageView.image = nil
        isCaptionExpanded = false
        fullCaption = post.caption ?? ""
        // Деактивируем и удаляем предыдущий констрейнт
        if let constraint = imageAspectRatioConstraint {
            constraint.isActive = false
        }
        imageAspectRatioConstraint = nil
        
        // Устанавливаем полный текст и начальное кол-во строк
        captionLabel.text = fullCaption
        captionLabel.numberOfLines = FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC

        // --- Настройка UI --- 
        authorUsernameButton.setTitle(post.authorUsername ?? "Unknown User", for: .normal)
        let isFollowed = false // Пока заглушка
        followButton.isSelected = isFollowed
        followButton.configurationUpdateHandler?(followButton) // Обновляем вид кнопки

        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
            authorAvatarImageView.kf.indicatorType = .activity
            authorAvatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray))
        } else {
            authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        }

        // --- Настройка изображения и Aspect Ratio --- 
        var aspectRatio: CGFloat = 1.0 // Дефолтное соотношение 1:1
        var imageURL: URL? = nil

        // ---> НОВАЯ ЛОГИКА: Используем post.feedAspectRatio <--- 
        aspectRatio = aspectRatioMultiplier(from: post.feedAspectRatio) // Используем хелпер
        print("FullPostCell [\(indexPath.item)]: Используем aspectRatio \(aspectRatio) из post.feedAspectRatio ('\(post.feedAspectRatio)')")
        
        // Получаем URL первого медиа элемента (предполагаем, что он основной для ленты)
        if let firstMediaItem = post.mediaItems.first, let url = URL(string: firstMediaItem.url) {
            imageURL = url
        } else {
            // Если нет media item, пробуем grid thumbnail (хотя он 9:16)
            imageURL = URL(string: post.gridThumbnailURL)
            if imageURL == nil {
                 print("FullPostCell [\(indexPath.item)]: ОШИБКА - URL изображения поста отсутствует")
                 postImageView.image = UIImage(systemName: "photo")?.withTintColor(.darkGray)
            }
        }
        
        // --- ОТЛАДКА --- 
        print("FullPostCell [\(indexPath.item)]: Итоговый aspectRatio для констрейнта: \(aspectRatio)")
        
        // Устанавливаем констрейнт соотношения сторон ПЕРЕД загрузкой
        setupAspectRatioConstraint(ratio: aspectRatio)
        
        // Загружаем изображение, если есть URL
        if let url = imageURL {
            loadPostImage(from: url) // УДАЛЯЕМ передачу indexPath и completion
        } else {
            // Если URL нет, просто устанавливаем placeholder
             postImageView.image = UIImage(systemName: "photo")?.withTintColor(.darkGray)
        }
        
        // --- Настройка Footer --- 
        likeButton.isSelected = post.isLiked
        likeCountLabel.text = "\(post.likeCount) likes"

        // Комментарии и настройка нижнего констрейнта
        configureFooter(commentCount: post.commentCount)

        // Вызываем updateCaptionDisplay ПОСЛЕ установки констрейнта aspect ratio
        updateCaptionDisplay()
        
        print("FullPostCell: Конфигурация завершена для indexPath \(indexPath)")
    }
    
    // Новый метод для установки констрейнта соотношения сторон
    private func setupAspectRatioConstraint(ratio: CGFloat) {
        // Убедимся, что старый констрейнт удален
        if let existingConstraint = imageAspectRatioConstraint {
            existingConstraint.isActive = false
        }
        // Создаем новый констрейнт
        let constraint = postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: max(0.1, ratio)) // Ограничиваем минимальный ratio
        constraint.priority = .required // ВАЖНО: Делаем приоритет обязательным (1000)
        constraint.isActive = true
        self.imageAspectRatioConstraint = constraint
    }
    
    // Новый метод для настройки футера и нижних констрейнтов
    private func configureFooter(commentCount: Int) {
        if commentCount > 0 {
            viewAllCommentsButton.setTitle("View all \(commentCount) comments", for: .normal)
            viewAllCommentsButton.isHidden = false
            // Логика активации/деактивации констрейнтов низа больше не нужна,
            // StackView сам управляет видимостью дочерних элементов.
        } else {
            viewAllCommentsButton.isHidden = true
            // Логика обновления нижних констрейнтов больше не нужна.
            // Просто обновляем видимость кнопки, если это не было сделано в configureFooter.
            // configureFooter(commentCount: viewAllCommentsButton.isHidden ? 0 : 1)
        }
    }

    // Метод теперь НЕ принимает indexPath
    private func updateCaptionDisplay() {
        guard let currentPath = indexPath else { return } // Защита
        
        // Сначала проверяем, нужно ли вообще усечение
        if needsTruncation(label: captionLabel, maxLines: FullPostCell.captionMaxLinesCollapsed) { // ИСПОЛЬЗУЕМ STATIC
             print("FullPostCell [\(currentPath.item)]: Caption needs truncation.")
             truncatedCaption = truncateText(label: captionLabel, maxLines: FullPostCell.captionMaxLinesCollapsed) + " ... more" // ИСПОЛЬЗУЕМ STATIC
             captionLabel.text = isCaptionExpanded ? fullCaption : truncatedCaption
             captionLabel.numberOfLines = isCaptionExpanded ? 0 : FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC
        } else {
             print("FullPostCell [\(currentPath.item)]: Caption fits.")
             truncatedCaption = nil
             captionLabel.text = fullCaption
             captionLabel.numberOfLines = 0
             isCaptionExpanded = true // Считаем развернутым
        }
        
        // Логика обновления нижних констрейнтов больше не нужна.
        // Просто обновляем видимость кнопки, если это не было сделано в configureFooter.
        // configureFooter(commentCount: viewAllCommentsButton.isHidden ? 0 : 1)
    }

    // Вспомогательный метод для загрузки изображения поста (упрощен)
    private func loadPostImage(from url: URL) {
        postImageView.kf.indicatorType = .activity
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.darkGray)
        
        postImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [.transition(.fade(0.2))]
            // УДАЛЯЕМ completionHandler, так как ratio устанавливается до загрузки
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
        
        // Обновляем отображение подписи (текст, numberOfLines)
        updateCaptionDisplay()
        
        // ВАЖНО: Уведомляем UICollectionView об изменениях, чтобы он пересчитал высоту
        // Вместо прямого вызова делегата, используем стандартный механизм
        // (предполагаем, что controller сделает invalidateLayout)
        // УДАЛЕНО: delegate?.fullPostCellDidToggleCaption(self, at: indexPath)
        
        // Запрашиваем обновление layout для этой ячейки
        // УДАЛЯЕМ: self.contentView.setNeedsLayout()
        // УДАЛЯЕМ: self.contentView.layoutIfNeeded()
        
        // Сообщаем CollectionView, что layout нужно обновить (лучше делать в контроллере)
        // УДАЛЯЕМ прямую инвалидацию layout из ячейки
        // Но можно попробовать так для простоты, хотя не идеально
        // if let collectionView = self.superview as? UICollectionView {
        //     collectionView.collectionViewLayout.invalidateLayout()
        // }
        
        // ВЫЗЫВАЕМ НОВЫЙ ДЕЛЕГАТ
        delegate?.fullPostCellDidRequestLayoutUpdate(at: indexPath)
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
    
    // MARK: - Aspect Ratio Helper
    
    private func aspectRatioMultiplier(from string: String) -> CGFloat {
        switch string {
            case "9:16": return 16.0 / 9.0
            case "1:1": return 1.0 / 1.0
            case "1.91:1": return 1.0 / 1.91
            default:
                print("FullPostCell Warning: Unknown aspectRatio string '\(string)', defaulting to 1:1")
                return 1.0 // Дефолт 1:1
        }
    }
    
    // MARK: - Layout Debugging
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Логируем размеры ключевых элементов ПОСЛЕ расчета Auto Layout
        if let indexPath = indexPath {
            print("--- LayoutSubviews for Cell [\(indexPath.item)] ---")
            print("  contentView frame: \(contentView.frame)")
            print("  postImageView frame: \(postImageView.frame)")
            print("    imageAspectRatioConstraint: \(imageAspectRatioConstraint?.multiplier ?? -1)")
            print("  likeCountLabel frame: \(likeCountLabel.frame)")
            print("  captionLabel frame: \(captionLabel.frame)")
            print("    captionLabel lines: \(captionLabel.numberOfLines)")
            print("  viewAllCommentsButton frame: \(viewAllCommentsButton.frame), isHidden: \(viewAllCommentsButton.isHidden)")
            print("    captionBottomConstraint active: \(captionBottomConstraint?.isActive ?? false)")
            print("    commentsButtonBottomConstraint active: \(commentsButtonBottomConstraint?.isActive ?? false)")
            print("------------------------------------------")
        }
    }
} 
