import UIKit
import Kingfisher

// ОБНОВЛЯЕМ ДЕЛЕГАТ: Добавляем методы для Follow и Comments
protocol FullPostCellDelegate: AnyObject {
    func didTapUsername(in cell: FullPostCell)
    func didTapFollowButton(in cell: FullPostCell)
    func didTapLikeButton(in cell: FullPostCell)
    func didTapCommentButton(in cell: FullPostCell)
    // УДАЛЯЕМ делегат для toggle caption, он больше не нужен для обновления layout
    // func fullPostCellDidToggleCaption(_ cell: FullPostCell, at indexPath: IndexPath)
    // ДОБАВЛЯЕМ новый метод делегата для запроса обновления layout
    func fullPostCellDidRequestLayoutUpdate(at indexPath: IndexPath)
    // ✅ Добавляем новый метод делегата для кнопки опций
    func didTapOptionsButton(in cell: FullPostCell, forPostId postId: String)
}

class FullPostCell: UICollectionViewCell {

    static let identifier = "FullPostCell"
    weak var delegate: FullPostCellDelegate?
    var indexPath: IndexPath?
    
    // Добавляем свойство для хранения ID поста
    private var currentPostId: String?
    
    // УДАЛЯЕМ замыкание для запроса обновления layout
    
    
    // Убираем private, чтобы FeedVC мог логировать его multiplier
    var imageAspectRatioConstraint: NSLayoutConstraint?

    // ОБНОВЛЕНИЕ: Добавляем новые свойства
    private var isCaptionExpanded: Bool = false
    private var truncatedCaption: String? // Храним усеченный текст
    private var fullCaption: String? // Храним полный текст
    static let captionMaxLinesCollapsed = 3 // Сколько строк показывать в свернутом виде (СДЕЛАНО STATIC INTERNAL)

    // Добавляем свойства для хранения констрейнтов, управляющих низом ячейки
    private var captionBottomConstraint: NSLayoutConstraint?
    private var commentsButtonBottomConstraint: NSLayoutConstraint?

    // Добавляем контейнер для контента поста
    private lazy var postContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black // Или другой цвет фона, если нужно
        // Можно добавить скругление и для контейнера, если хочешь
        // view.layer.cornerRadius = 10
        // view.clipsToBounds = true
        return view
    }()

    // === НОВЫЕ ЭЛЕМЕНТЫ для МЕДИА ===
    // Убираем private, чтобы FeedVC мог логировать его frame
    lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black // Фон контейнера
        collectionView.register(MediaItemCell.self, forCellWithReuseIdentifier: MediaItemCell.identifier)
        return collectionView
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        // Уменьшаем размер точек через transform
        pageControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        pageControl.hidesForSinglePage = true
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.isUserInteractionEnabled = false // Не кликабельный
        return pageControl
    }()

    // Данные для mediaCollectionView
    private var mediaItems: [MediaItemDTO] = []
    // === КОНЕЦ НОВЫХ ЭЛЕМЕНТОВ ===

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

    // ✅ Новая кнопка "три точки" (Опции)
    private lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .white // Цвет иконки
        // Увеличим область нажатия, если иконка мелкая
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 5) 
        button.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        button.isHidden = true // Скрыта по умолчанию
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var usernameAndFollowStackView: UIStackView = { // Стек для имени и кнопки Follow
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal) // Растягиваем пространство
        let stackView = UIStackView(arrangedSubviews: [authorUsernameButton, followButton, spacer, optionsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8 // Отступ между элементами
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

    // -- Post Image --> ЗАМЕНЕН на mediaCollectionView --

    // -- Actions and Stats Row --
    private lazy var actionsAndStatsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12 // Увеличиваем отступ МЕЖДУ группами
        stackView.alignment = .center
        return stackView
    }()

    // -- Action Buttons --
    private lazy var likeButton: UIButton = createActionButton(systemName: "heart", selector: #selector(likeButtonTapped))
    private lazy var commentButton: UIButton = createActionButton(systemName: "message", selector: #selector(commentButtonTapped))
    
    // -- Sub-Stacks for Actions/Stats --
    private lazy var likeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [likeButton, likeCountLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4 // Маленький отступ внутри группы лайков
        stackView.alignment = .center
        return stackView
    }()

    private lazy var commentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [commentButton, commentCountLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4 // Маленький отступ внутри группы комментов
        stackView.alignment = .center
        return stackView
    }()

    // -- Footer Stack --
    private lazy var footerStackView: UIStackView = {
        // Удаляем viewAllCommentsButton из стека
        let stackView = UIStackView(arrangedSubviews: [captionLabel])
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

    // Новый лейбл для счетчика комментов
    private lazy var commentCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = .clear
        // Не даем сжиматься, чтобы текст был виден
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
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

    // MARK: - Setup

    // НОВЫЙ МЕТОД для настройки делегатов
    func setupDelegates() {
        // Делегаты и dataSource для mediaCollectionView
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = self
        mediaCollectionView.prefetchDataSource = self // Добавляем prefetching
        
        // TapGesture для captionLabel настраивается в lazy var
        // captionLabel.delegate = self // TTTAttributedLabelDelegate, если используется
        print("FullPostCell: setupDelegates выполнен")
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Оставляем imageAspectRatioConstraint пока nil

        // Убираем фон
        contentView.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupDelegates() // Вызываем ПОСЛЕ setupConstraints
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Добавляем postContainerView в contentView
        contentView.addSubview(postContainerView)

        // Добавляем все остальные элементы ВНУТРЬ postContainerView
        postContainerView.addSubview(authorAvatarImageView)
        postContainerView.addSubview(usernameAndFollowStackView)
        postContainerView.addSubview(mediaCollectionView)
        postContainerView.addSubview(pageControl)
        postContainerView.addSubview(footerStackView)
        postContainerView.addSubview(actionsAndStatsStackView)

        // Добавляем саб-стеки и кнопку Share ВНУТРЬ actionsAndStatsStackView
        // Spacer нужен, чтобы разнести кнопку Share вправо
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        actionsAndStatsStackView.addArrangedSubview(likeStackView)
        actionsAndStatsStackView.addArrangedSubview(commentStackView)
        actionsAndStatsStackView.addArrangedSubview(spacer) // Растягивающийся spacer
    }

    private func setupConstraints() {
        // СОЗДАЕМ КОНСТРЕЙНТ ЗДЕСЬ, В НАЧАЛЕ setupConstraints
        imageAspectRatioConstraint = mediaCollectionView.heightAnchor.constraint(equalTo: mediaCollectionView.widthAnchor, multiplier: 1.0) // Default 1:1
        imageAspectRatioConstraint?.priority = .required // Сразу ставим required
        imageAspectRatioConstraint?.identifier = "MediaAspectRatioConstraint" // Идентификатор для дебаггинга
        imageAspectRatioConstraint?.isActive = false // Неактивен при создании

        let padding: CGFloat = 10
        let footerPadding: CGFloat = 8
        let buttonSize: CGFloat = 28 // Размер кнопок действий
        let buttonSpacing: CGFloat = 12 // Расстояние между кнопками
        
        NSLayoutConstraint.activate([
            // postContainerView Constraints (отступы от contentView)
            postContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            postContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            postContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding), // Используем padding = 10
            postContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding), // Используем padding = 10

            // --- Обновляем констрейнты, чтобы они были относительно postContainerView ---
            
            // Header
            authorAvatarImageView.topAnchor.constraint(equalTo: postContainerView.topAnchor, constant: padding),
            authorAvatarImageView.leadingAnchor.constraint(equalTo: postContainerView.leadingAnchor, constant: padding),
            authorAvatarImageView.widthAnchor.constraint(equalToConstant: 30),
            authorAvatarImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // StackView для имени и кнопки Follow
            usernameAndFollowStackView.leadingAnchor.constraint(equalTo: authorAvatarImageView.trailingAnchor, constant: padding),
            usernameAndFollowStackView.trailingAnchor.constraint(lessThanOrEqualTo: postContainerView.trailingAnchor, constant: -padding), // Не прижимаем к правому краю жестко
            usernameAndFollowStackView.centerYAnchor.constraint(equalTo: authorAvatarImageView.centerYAnchor),
            
            // Media Collection View
            mediaCollectionView.topAnchor.constraint(equalTo: authorAvatarImageView.bottomAnchor, constant: padding),
            mediaCollectionView.leadingAnchor.constraint(equalTo: postContainerView.leadingAnchor), // Привязываем к postContainerView БЕЗ отступа
            mediaCollectionView.trailingAnchor.constraint(equalTo: postContainerView.trailingAnchor), // Привязываем к postContainerView БЕЗ отступа
            // Констрейнт соотношения сторон будет применяться к mediaCollectionView в configure

            // Page Control (Под mediaCollectionView)
            pageControl.topAnchor.constraint(equalTo: mediaCollectionView.bottomAnchor, constant: 4), // Небольшой отступ сверху
            pageControl.centerXAnchor.constraint(equalTo: postContainerView.centerXAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20), // Стандартная высота

            // Actions and Stats Stack View (Под PageControl)
            actionsAndStatsStackView.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: buttonSpacing - 4),
            actionsAndStatsStackView.leadingAnchor.constraint(equalTo: postContainerView.leadingAnchor, constant: padding),
            actionsAndStatsStackView.trailingAnchor.constraint(equalTo: postContainerView.trailingAnchor, constant: -padding),

            // Footer Stack View (Теперь под actionsAndStatsStackView)
            footerStackView.topAnchor.constraint(equalTo: actionsAndStatsStackView.bottomAnchor, constant: footerPadding), // Отступ от строки статов
            footerStackView.leadingAnchor.constraint(equalTo: postContainerView.leadingAnchor, constant: padding),
            footerStackView.trailingAnchor.constraint(equalTo: postContainerView.trailingAnchor, constant: -padding),
            footerStackView.bottomAnchor.constraint(equalTo: postContainerView.bottomAnchor, constant: -footerPadding) // Привязываем низ стека к низу postContainerView
        ])
    }

    override func prepareForReuse() {
        let oldMultiplier = imageAspectRatioConstraint?.multiplier ?? -1
        let oldIsActive = imageAspectRatioConstraint?.isActive ?? false
        print("➡️ FullPostCell [prepareForReuse \(indexPath?.item ?? -1)]: Called. Old Aspect Multiplier: \(String(format: "%.3f", oldMultiplier)), IsActive: \(oldIsActive)")
        
        super.prepareForReuse()
        
        print("Preparing cell for reuse")
        isCaptionExpanded = false
        
        // Исправление: проверяем наличие indexPath
        if let currentPath = indexPath {
            updateCaptionDisplay()
        }
        
        delegate = nil
        indexPath = nil
        authorAvatarImageView.kf.cancelDownloadTask()
        authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        authorUsernameButton.setTitle(nil, for: .normal)
        likeCountLabel.text = nil
        captionLabel.attributedText = nil
        truncatedCaption = nil
        fullCaption = nil

        // ВАЖНО: Деактивировать и удалить констрейнт соотношения сторон
        if let constraint = imageAspectRatioConstraint {
            print("➡️ FullPostCell [prepareForReuse]: Deactivating and removing existing constraint (Multiplier: \(String(format: "%.3f", constraint.multiplier))).")
            constraint.isActive = false
            // Удаляем из супервью, к которому добавляли (postContainerView)
            if postContainerView.constraints.contains(constraint) {
                postContainerView.removeConstraint(constraint)
                print("➡️ FullPostCell [prepareForReuse]: Removed constraint from postContainerView.")
            } else {
                print("⚠️ Warning: Constraint to remove was not found in postContainerView.")
            }
        } else {
            print("➡️ FullPostCell [prepareForReuse]: No existing constraint reference to remove.")
        }
        // Очищаем ссылку, чтобы updateAspectRatioConstraint гарантированно создал новый
        imageAspectRatioConstraint = nil
        print("➡️ FullPostCell [prepareForReuse]: Finished.")
    }

    // MARK: - Configuration
    func configure(with post: Post, currentUserID: String?, indexPath: IndexPath) {
        print("➡️ FullPostCell [configure \(indexPath.item)]: PostID: \(post.id ?? "nil"), AspectString: '\(post.feedAspectRatio)'")
        
        self.indexPath = indexPath

        // --- Сброс состояния --- 
        isCaptionExpanded = false
        fullCaption = post.caption ?? ""
        // Используем восстановленный метод и напрямую присваиваем результат,
        // так как новая функция возвращает String, а не String?
        truncatedCaption = truncateCaptionIfNeeded(text: fullCaption ?? "", font: captionLabel.font, maxWidth: postContainerView.bounds.width - 32, maxLines: FullPostCell.captionMaxLinesCollapsed)
 
        // Сохраняем ID поста для использования в делегатах
        self.currentPostId = post.id

        // Устанавливаем текст подписи и количество строк
        captionLabel.text = fullCaption
        captionLabel.numberOfLines = FullPostCell.captionMaxLinesCollapsed // ИСПОЛЬЗУЕМ STATIC

        // --- Настройка UI --- 
        authorUsernameButton.setTitle(post.authorUsername ?? "Unknown User", for: .normal)
        // TODO: Заменить на реальную логику проверки подписки
        let isFollowed = false // Пока заглушка
        followButton.isSelected = isFollowed
        followButton.configurationUpdateHandler?(followButton) // Обновляем вид кнопки
        // Скрываем кнопку Follow для своего поста
        followButton.isHidden = (post.userID == currentUserID)
        // Скрываем кнопку Options для чужого поста
        optionsButton.isHidden = (post.userID != currentUserID)
        
        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
            authorAvatarImageView.kf.indicatorType = .activity
            authorAvatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray))
        } else {
            authorAvatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray)
        }

        // --- Настройка Media Collection View и Page Control --- 
        var aspectRatio: CGFloat = 1.0 // Дефолтное соотношение 1:1
        self.mediaItems = post.mediaItems // Сохраняем медиа для DataSource
        
        // ---> НОВАЯ ЛОГИКА: Используем post.feedAspectRatio <--- 
        aspectRatio = aspectRatioMultiplier(from: post.feedAspectRatio) // Используем хелпер
        print("➡️ FullPostCell [configure \(indexPath.item)]: Calculated Aspect Multiplier: \(String(format: "%.3f", aspectRatio))")
        
        // Устанавливаем констрейнт соотношения сторон ПЕРЕД загрузкой
        // Применяем его к mediaCollectionView!
        print("➡️ FullPostCell [configure \(indexPath.item)]: Calling updateAspectRatioConstraint...")
        // Добавляем self. для вызова метода экземпляра
        self.updateAspectRatioConstraint(ratio: aspectRatio)
        
        // Настраиваем pageControl
        pageControl.numberOfPages = mediaItems.count
        pageControl.currentPage = 0
        // Скрываем, если страница одна
        pageControl.isHidden = mediaItems.count <= 1

        // Перезагружаем данные mediaCollectionView
        print("➡️ FullPostCell [configure \(indexPath.item)]: Calling mediaCollectionView.reloadData(). Media Frame BEFORE: \(mediaCollectionView.frame)")
        mediaCollectionView.reloadData()
        // Сбрасываем скролл в начало, если ячейка переиспользуется
        mediaCollectionView.setContentOffset(.zero, animated: false)
        print("➡️ FullPostCell [configure \(indexPath.item)]: Finished configure. Media Frame AFTER reload/reset: \(mediaCollectionView.frame)")

        // ---> ПРОАКТИВНАЯ ПРЕДЗАГРУЗКА <--- 
        // Запускаем предзагрузку для первых нескольких изображений карусели СРАЗУ
        let initialPrefetchUrls = mediaItems.prefix(3).compactMap { URL(string: $0.url) } // Берем первые 3
        if !initialPrefetchUrls.isEmpty {
            ImagePrefetcher(urls: initialPrefetchUrls).start()
        }

        // --- Настройка лайков и комментов --- 
        likeButton.isSelected = post.isLiked // Используем опциональное значение ?? false
        likeCountLabel.text = "\(post.likeCount ?? 0)"
        commentCountLabel.text = "\(post.commentCount ?? 0)"

        // Обновляем состояние UI в зависимости от данных (например, видимость кнопки 'more')
        updateCaptionDisplay()
        
    }
    
    // Упрощенный метод
    private func updateCaptionDisplay() {
        let currentPath = indexPath ?? IndexPath(item: -2, section: -2) // For logging
        print("FullPostCell [updateCaptionDisplay \(currentPath.item)]: Called. Expanded: \(isCaptionExpanded)")

        // 1. Устанавливаем текст и количество строк
        let textToShow = isCaptionExpanded ? fullCaption : truncatedCaption
        let linesToShow = isCaptionExpanded ? 0 : FullPostCell.captionMaxLinesCollapsed

        captionLabel.text = textToShow
        captionLabel.numberOfLines = linesToShow

        // 2. Определяем видимость кнопки "more"
        // Для этого нужно временно установить полный текст и посчитать, нужно ли усечение
        let originalText = captionLabel.text // Сохраняем текущее состояние
        let originalLines = captionLabel.numberOfLines
        captionLabel.text = fullCaption // Ставим полный текст для расчета
        captionLabel.numberOfLines = 0
        layoutIfNeeded() // Даем лейблу обновиться
        let captionNeedsTruncation = needsTruncation(text: fullCaption ?? "", font: captionLabel.font, maxWidth: postContainerView.bounds.width - 32, maxLines: FullPostCell.captionMaxLinesCollapsed)
        // Восстанавливаем отображаемое состояние
        captionLabel.text = originalText 
        captionLabel.numberOfLines = originalLines

        print("FullPostCell [updateCaptionDisplay \(currentPath.item)]: Caption needs truncation: \(captionNeedsTruncation)")
    }
    
    // MARK: - Layout Debugging
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Логируем размеры ключевых элементов ПОСЛЕ расчета Auto Layout
        if let indexPath = indexPath, indexPath.item == 0 { // Log only for the first cell to reduce noise
            
        }
    }
    
    // MARK: - Actions
    
    @objc private func usernameTapped() {
        delegate?.didTapUsername(in: self)
    }

    @objc private func followButtonTapped() {
        delegate?.didTapFollowButton(in: self)
    }

    @objc private func optionsButtonTapped() {
        guard let postId = currentPostId else { return }
        delegate?.didTapOptionsButton(in: self, forPostId: postId)
    }

    @objc private func likeButtonTapped() {
        delegate?.didTapLikeButton(in: self)
    }
    
    @objc private func commentButtonTapped() {
        print("--- FullPostCell: commentButtonTapped! Calling delegate... ---") // DEBUG
        delegate?.didTapCommentButton(in: self)
    }
    
    @objc private func captionTapped(_ sender: UITapGestureRecognizer) {
        guard let indexPath = indexPath else {
            print("IndexPath is nil in captionTapped")
            return
        }
        
        isCaptionExpanded.toggle()
        
        // Обновляем отображение подписи (текст, numberOfLines)
        updateCaptionDisplay()
        
        // Сообщаем CollectionView, что layout нужно обновить
        delegate?.fullPostCellDidRequestLayoutUpdate(at: indexPath)
    }
    
    @objc private func pageControlDidChange(_ sender: UIPageControl) {
        let currentPage = sender.currentPage
        let xOffset = CGFloat(currentPage) * mediaCollectionView.frame.width
        mediaCollectionView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }
    
    // MARK: - Helpers
    
    // Вспомогательный метод для создания кнопок (добавляем таргеты)
    private func createActionButton(systemName: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: systemName + ".fill", withConfiguration: config), for: .selected) // Для Like/Bookmark
        button.tintColor = .white
        
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
    
    // Проверяет, действительно ли текст обрезается
    private func needsTruncation(text: String, font: UIFont, maxWidth: CGFloat, maxLines: Int) -> Bool {
        guard !text.isEmpty, maxWidth > 0, maxLines > 0 else { return false }
        
        let textAttributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)

        // Создаем TextKit стек для точного расчета
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = maxLines
        layoutManager.addTextContainer(textContainer)

        // Вычисляем количество глифов, которые помещаются
        let range = layoutManager.glyphRange(for: textContainer)
        let numberOfGlyphs = range.length
        
        // Если количество отображаемых глифов меньше общего количества, нужно усечение
        let totalGlyphs = layoutManager.numberOfGlyphs
        let needs = numberOfGlyphs < totalGlyphs
        print("FullPostCell [needsTruncation Helper] - Needs: \(needs). Glyphs shown: \(numberOfGlyphs) / Total: \(totalGlyphs). MaxWidth: \(maxWidth), MaxLines: \(maxLines)")
        return needs
    }

    // Генерирует усеченный текст до нужного количества строк
    // Возвращает базовый усеченный текст БЕЗ '... more'
    private func truncateText(text: String, font: UIFont, maxWidth: CGFloat, maxLines: Int) -> String? {
        guard !text.isEmpty, maxWidth > 0, maxLines > 0 else { return nil }

        let textAttributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)

        // Создаем TextKit стек
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = maxLines
        textContainer.lineBreakMode = .byTruncatingTail // Важно для корректного расчета последней видимой строки
        layoutManager.addTextContainer(textContainer)

        // Находим диапазон глифов, которые помещаются
        let range = layoutManager.glyphRange(for: textContainer)
        
        // Если глифы не помещаются вообще (маловероятно, но возможно)
        guard range.length > 0 else { return nil }
        
        // Находим диапазон символов, соответствующий видимым глифам
        let characterRange = layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: nil)
        
        // Получаем подстроку
        let truncatedNSString = (text as NSString).substring(with: characterRange)
        
        print("FullPostCell [truncateText Helper] - Original: '\(text.prefix(50))...', Truncated base: '\(truncatedNSString.prefix(50))...'. MaxWidth: \(maxWidth), MaxLines: \(maxLines)")

        // Убираем возможные пробелы/переносы строк в конце усеченной строки
        return truncatedNSString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Главная функция, вызывающая вспомогательные
    // Возвращает либо оригинальный текст, либо усеченный текст с '... more'
    private func truncateCaptionIfNeeded(text: String, font: UIFont, maxWidth: CGFloat, maxLines: Int) -> String {
        print("FullPostCell [truncateCaptionIfNeeded Helper] - Checking text: '\(text.prefix(50))...'. MaxWidth: \(maxWidth), MaxLines: \(maxLines)")
        // Сначала проверяем, нужно ли вообще усечение
        if needsTruncation(text: text, font: font, maxWidth: maxWidth, maxLines: maxLines) {
            // Если нужно, получаем усеченный базовый текст
            if let truncatedBase = truncateText(text: text, font: font, maxWidth: maxWidth, maxLines: maxLines) {
                // Добавляем '... more'
                let result = truncatedBase + "... more"
                print("FullPostCell [truncateCaptionIfNeeded Helper] - Truncation needed. Result: '\(result.prefix(50))...'")
                return result
            } else {
                // Если truncateText вернул nil (ошибка или текст не помещается), возвращаем оригинал
                print("FullPostCell [truncateCaptionIfNeeded Helper] - Truncation needed but truncateText failed. Returning original.")
                return text
            }
        } else {
            // Если усечение не нужно, возвращаем оригинальный текст
            print("FullPostCell [truncateCaptionIfNeeded Helper] - No truncation needed. Returning original.")
            return text
        }
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

    // НОВЫЙ МЕТОД для обновления констрейнта
    private func updateAspectRatioConstraint(ratio: CGFloat) {
        // 1. Деактивируем и удаляем СТАРЫЙ констрейнт из postContainerView, если он существует
        if let existingConstraint = self.imageAspectRatioConstraint {
            print("➡️ FullPostCell [updateAspectRatioConstraint]: Deactivating and removing existing constraint (Multiplier: \(String(format: "%.3f", existingConstraint.multiplier)))")
            existingConstraint.isActive = false
            // Удаляем из супервью, к которому добавляли (postContainerView)
            if postContainerView.constraints.contains(existingConstraint) {
                postContainerView.removeConstraint(existingConstraint)
                print("➡️ FullPostCell [updateAspectRatioConstraint]: Removed constraint from postContainerView.")
            } else {
                print("⚠️ Warning: Existing constraint was not found in postContainerView during removal.")
                // Возможно, он был добавлен к contentView или mediaCollectionView? Проверь setupConstraints.
            }
        } else {
            print("➡️ FullPostCell [updateAspectRatioConstraint]: No existing constraint reference found (likely due to prepareForReuse).")
        }

        // 2. Создаем НОВЫЙ констрейнт
        print("➡️ FullPostCell [updateAspectRatioConstraint]: Creating new constraint with multiplier \(String(format: "%.3f", ratio))")
        let newConstraint = mediaCollectionView.heightAnchor.constraint(equalTo: mediaCollectionView.widthAnchor, multiplier: ratio)
        newConstraint.priority = .required // Всегда required
        newConstraint.identifier = "MediaAspectRatioConstraint" // Тот же идентификатор

        // 3. Сохраняем ссылку на новый
        self.imageAspectRatioConstraint = newConstraint

        // 4. Добавляем новый в postContainerView
        postContainerView.addConstraint(newConstraint)
        print("➡️ FullPostCell [updateAspectRatioConstraint]: Added new constraint to postContainerView.")


        // 5. Активируем новый
        newConstraint.isActive = true
        print("➡️ FullPostCell [updateAspectRatioConstraint]: Activated new constraint.")

        // Дополнительно: Форсируем немедленное обновление layout, если нужно
        // self.contentView.layoutIfNeeded()
        // print("➡️ FullPostCell [updateAspectRatioConstraint]: Called layoutIfNeeded on contentView.")
    }
}

// MARK: - UICollectionViewDataSource (для mediaCollectionView)
extension FullPostCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.identifier, for: indexPath) as? MediaItemCell else {
            fatalError("Unable to dequeue MediaItemCell")
        }
        let mediaURL = URL(string: mediaItems[indexPath.item].url)
        cell.configure(with: mediaURL)
        return cell
    }
}

// MARK: - UICollectionViewDelegate (для mediaCollectionView)
extension FullPostCell: UICollectionViewDelegate {
    // Обновляем pageControl при смене страницы
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Убедимся, что это скролл именно mediaCollectionView
        guard scrollView == mediaCollectionView else { return }
        
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout (для mediaCollectionView)
extension FullPostCell: UICollectionViewDelegateFlowLayout {
    // Размер ячейки равен размеру mediaCollectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - UICollectionViewDataSourcePrefetching (для mediaCollectionView)
extension FullPostCell: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Убедимся, что это наш mediaCollectionView
        guard collectionView == mediaCollectionView else { return }

        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < mediaItems.count else { return nil }
            return URL(string: mediaItems[indexPath.item].url)
        }

        if !urls.isEmpty {
            print("FullPostCell [prefetchItemsAt]: Prefetching \(urls.count) images.")
            ImagePrefetcher(urls: urls).start()
        }
    }
} 
