import UIKit
import Kingfisher

// Протокол для делегата ячейки
protocol PostCellDelegate: AnyObject {
    func postCellDidTapAuthor(_ cell: PostCell)
    // Добавляем метод для лайка
    func postCellDidTapLikeButton(_ cell: PostCell, currentLikeState: Bool)
    // Добавляем метод для кнопки комментариев
    func postCellDidTapCommentButton(_ cell: PostCell)
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
        label.numberOfLines = 2 // Ограничим пока двумя строками
        return label
    }()
    
    // TODO: Добавить кнопки Like, Comment, Share
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .black
        selectionStyle = .none // Убираем выделение при нажатии
        setupViews()
        setupConstraints()
        // Добавляем распознаватели нажатий
        setupTapGestures()
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
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    // Добавляем настройку жестов
    private func setupTapGestures() {
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleAuthorTap))
        userAvatarImageView.addGestureRecognizer(avatarTap)
        
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(handleAuthorTap))
        usernameLabel.addGestureRecognizer(usernameTap)
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

    // MARK: - Configuration
    
    func configure(with post: Post) {
        // Сохраняем ID автора
        self.authorUserID = post.userID
        self.currentPostID = post.id // Сохраняем ID поста
        self.isCurrentlyLiked = post.isLiked // Сохраняем состояние лайка
        
        usernameLabel.text = post.authorUsername ?? "Unknown User"
        let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
             userAvatarImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            userAvatarImageView.image = placeholder
            userAvatarImageView.tintColor = .darkGray
        }
        
        captionLabel.text = post.caption
        // Обновляем счетчик лайков
        likesLabel.text = "\(post.likeCount) likes"
        // Обновляем вид кнопки лайка
        updateLikeButtonAppearance()
        
        if let url = URL(string: post.imageURL) {
            postImageView.kf.indicatorType = .activity
            postImageView.kf.setImage(with: url)
        }
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
} 