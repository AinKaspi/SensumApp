import UIKit
import Kingfisher

// Протокол для делегата ячейки
protocol PostCellDelegate: AnyObject {
    func postCellDidTapAuthor(_ cell: PostCell)
    // Добавляем метод для лайка
    func postCellDidTapLikeButton(_ cell: PostCell, currentLikeState: Bool)
    // Добавляем метод для кнопки комментариев
    func postCellDidTapCommentButton(_ cell: PostCell)
    // Добавляем метод для разворачивания/сворачивания текста
    func postCellDidToggleCaption(_ cell: PostCell)
}

class PostCell: UITableViewCell {
    
    static let identifier = "PostCell"
    
    // Делегат
    weak var delegate: PostCellDelegate?
    // Свойство для хранения userID автора (чтобы делегат мог его получить)
    private var authorUserID: String?
    // Добавляем хранение текущего состояния лайка и ID поста
    private var currentPostID: String?
    private var isCurrentlyLiked: Bool = false
    // Состояния для текста
    private var isCaptionExpanded: Bool = false
    private var fullCaption: String?
    private var canExpandCaption: Bool = false // Флаг, нужно ли показывать кнопку "more"
    
    // MARK: - UI Elements
    
    private let userAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15 // Маленький аватар
        imageView.backgroundColor = .lightGray
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .darkGray
        // Включаем интерактивность для жестов
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.text = "username"
        // Включаем интерактивность для жестов
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Или .scaleAspectFit?
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 25 // Оставляем скругление
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Добавляем UI для действий (Like, Comment, Share)
    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart"), for: .normal) // Иконка пустого сердца
        button.tintColor = .white
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "message"), for: .normal)
        button.tintColor = .white
        // Раскомментируем addTarget
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperplane"), for: .normal)
        button.tintColor = .white
        // button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var actionButtonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        // Ограничим ширину кнопок
        likeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        commentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        shareButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        return stackView
    }()
    
    // Добавляем лейбл для счетчика лайков
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.text = "0 likes"
        return label
    }()
    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        // Изначально 0 строк, чтобы можно было измерить полную высоту
        label.numberOfLines = 0 
        // Добавляем обработчик нажатия на сам текст
        label.isUserInteractionEnabled = true
        return label
    }()
    
    // Кнопка "more..."
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("еще", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.lightGray, for: .normal)
        button.addTarget(self, action: #selector(toggleCaptionExpansion), for: .touchUpInside)
        button.isHidden = true // Скрыта по умолчанию
        button.contentHorizontalAlignment = .left // Прижимаем текст к левому краю
        return button
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .black
        selectionStyle = .none // Убираем выделение при нажатии
        setupViews()
        setupConstraints()
        // Добавляем распознаватели нажатий
        setupTapGestures()
        // Добавляем обработчик нажатия на captionLabel
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(toggleCaptionExpansion))
        captionLabel.addGestureRecognizer(captionTap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userAvatarImageView.image = UIImage(systemName: "person.circle.fill") // Сброс аватара
        usernameLabel.text = nil
        postImageView.kf.cancelDownloadTask()
        postImageView.image = nil
        captionLabel.text = nil
        authorUserID = nil // Сбрасываем ID автора
        currentPostID = nil // Сбрасываем ID поста
        isCurrentlyLiked = false // Сбрасываем состояние лайка
        updateLikeButtonAppearance() // Обновляем вид кнопки
        likesLabel.text = "0 likes" // Сбрасываем счетчик
        delegate = nil // Сбрасываем делегата
        // Сбрасываем состояние текста
        isCaptionExpanded = false 
        canExpandCaption = false
        fullCaption = nil
        moreButton.isHidden = true
        captionLabel.numberOfLines = 0 // Возвращаем 0 строк
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(userAvatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(postImageView)
        // Добавляем новые элементы
        contentView.addSubview(actionButtonsStackView)
        contentView.addSubview(likesLabel)
        contentView.addSubview(captionLabel)
        // Добавляем кнопку "more"
        contentView.addSubview(moreButton)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 8
        let smallPadding: CGFloat = 4
        let avatarSize: CGFloat = 30
        let actionButtonHeight: CGFloat = 30
        
        NSLayoutConstraint.activate([
            userAvatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            userAvatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            userAvatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            userAvatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            usernameLabel.centerYAnchor.constraint(equalTo: userAvatarImageView.centerYAnchor),
            
            postImageView.topAnchor.constraint(equalTo: userAvatarImageView.bottomAnchor, constant: padding),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 16.0/9.0),
            
            actionButtonsStackView.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: padding),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            actionButtonsStackView.heightAnchor.constraint(equalToConstant: actionButtonHeight),
            
            likesLabel.topAnchor.constraint(equalTo: actionButtonsStackView.bottomAnchor, constant: smallPadding),
            likesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            likesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            captionLabel.topAnchor.constraint(equalTo: likesLabel.bottomAnchor, constant: smallPadding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            // Кнопка "more" под captionLabel
            moreButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 0),
            moreButton.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            // Привязываем низ кнопки к низу contentView
            moreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    // Добавляем настройку жестов
    private func setupTapGestures() {
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleAuthorTap))
        userAvatarImageView.addGestureRecognizer(avatarTap)
        
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(handleAuthorTap))
        usernameLabel.addGestureRecognizer(usernameTap)
        
        // Добавляем обработчик нажатия на captionLabel
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(toggleCaptionExpansion))
        captionLabel.addGestureRecognizer(captionTap)
    }
    
    // MARK: - Actions
    
    @objc private func handleAuthorTap() {
        delegate?.postCellDidTapAuthor(self)
    }
    
    // Обработчик нажатия кнопки лайка
    @objc private func likeButtonTapped() {
        delegate?.postCellDidTapLikeButton(self, currentLikeState: isCurrentlyLiked)
        // Оптимистичное обновление UI (ViewModel подтвердит или откатит)
        // isCurrentlyLiked.toggle()
        // updateLikeButtonAppearance() 
        // ^^^ Лучше пусть ViewModel управляет состоянием через configure
    }
    
    // Добавляем action для кнопки комментов
    @objc private func commentButtonTapped() {
        delegate?.postCellDidTapCommentButton(self)
    }

    // MARK: - Caption Handling
    
    // Вызывается при нажатии на captionLabel или moreButton
    @objc private func toggleCaptionExpansion() {
        // Ничего не делаем, если текст и так полностью помещается
        guard canExpandCaption else { return }
        
        isCaptionExpanded.toggle()
        updateCaptionAppearance()
        
        // Уведомляем делегата (ViewController), что нужно обновить layout таблицы
        delegate?.postCellDidToggleCaption(self)
    }
    
    // Обновляет numberOfLines и видимость кнопки "more"
    private func updateCaptionAppearance() {
        captionLabel.numberOfLines = isCaptionExpanded ? 0 : 2 // 2 строки в свернутом виде
        moreButton.isHidden = !canExpandCaption || isCaptionExpanded
    }
    
    // Проверяет, нужно ли показывать кнопку "more"
    private func checkAndSetupCaptionExpansion() {
        // Даем UI время отрисоваться и получить реальную ширину captionLabel
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.canExpandCaption = self.captionLabel.isTruncated()
            self.updateCaptionAppearance()
        }
    }

    // MARK: - Configuration
    
    func configure(with post: Post) {
        // Сохраняем ID автора
        self.authorUserID = post.userID
        self.currentPostID = post.id // Сохраняем ID поста
        self.isCurrentlyLiked = post.isLiked // Сохраняем состояние лайка
        self.fullCaption = post.caption
        self.isCaptionExpanded = false // Сбрасываем состояние при конфигурации
        
        usernameLabel.text = post.authorUsername ?? "Unknown User"
        let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
             userAvatarImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            userAvatarImageView.image = placeholder
            userAvatarImageView.tintColor = .darkGray
        }
        
        captionLabel.text = self.fullCaption // Ставим полный текст для расчета
        captionLabel.numberOfLines = 0 // Сначала ставим 0 строк для расчета
        // Обновляем счетчик лайков
        likesLabel.text = "\(post.likeCount) likes"
        // Обновляем вид кнопки лайка
        updateLikeButtonAppearance()
        
        // Загружаем изображение поста
        // Сначала проверяем, есть ли превью для сетки
        if let url = URL(string: post.gridThumbnailURL), !post.gridThumbnailURL.isEmpty {
            postImageView.kf.indicatorType = .activity
            postImageView.kf.setImage(with: url)
        } 
        // Если нет превью, используем первый элемент из mediaItems
        else if let firstMediaItem = post.mediaItems.first, 
                let url = URL(string: firstMediaItem.url) {
            postImageView.kf.indicatorType = .activity
            postImageView.kf.setImage(with: url)
        } else {
            postImageView.image = UIImage(systemName: "photo")
            postImageView.tintColor = .gray
        }
        
        // Проверяем необходимость кнопки "more" после установки текста
        checkAndSetupCaptionExpansion()
    }
    
    // Обновляет вид кнопки лайка
    private func updateLikeButtonAppearance() {
        let imageName = isCurrentlyLiked ? "heart.fill" : "heart"
        let tintColor: UIColor = isCurrentlyLiked ? .systemRed : .white
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
        likeButton.tintColor = tintColor
    }
    
    // Добавляем метод для получения ID автора
    func getAuthorUserID() -> String? {
        return authorUserID
    }
    
    // Метод для получения ID поста (если понадобится делегату)
    func getPostID() -> String? {
        return currentPostID
    }
    
    // Новый метод для установки скругления картинки поста
    func setPostImageCornerRadius(_ radius: CGFloat) {
        postImageView.layer.cornerRadius = radius
        postImageView.clipsToBounds = true 
    }
}

// Хелпер для определения, обрезан ли текст в UILabel
// (Можно вынести в Extensions)
extension UILabel {
    func isTruncated() -> Bool {
        guard let labelText = text else {
            return false
        }
        // Рассчитываем реальный размер текста для текущей ширины и неограниченной высоты
        let labelTextSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font!],
            context: nil).size

        // Сравниваем с текущей высотой bounds (с небольшой погрешностью)
        return labelTextSize.height > bounds.size.height + 2 
    }
} 