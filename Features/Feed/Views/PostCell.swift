import UIKit
import Kingfisher

class PostCell: UITableViewCell {
    
    static let identifier = "PostCell"
    
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
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.text = "username"
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
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(userAvatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(postImageView)
        contentView.addSubview(captionLabel)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 8
        let avatarSize: CGFloat = 30
        
        NSLayoutConstraint.activate([
            // Аватар и имя пользователя сверху
            userAvatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            userAvatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            userAvatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            userAvatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: padding),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            usernameLabel.centerYAnchor.constraint(equalTo: userAvatarImageView.centerYAnchor),
            
            // Изображение поста (под шапкой)
            postImageView.topAnchor.constraint(equalTo: userAvatarImageView.bottomAnchor, constant: padding),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), // Во всю ширину
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Рассчитываем высоту по соотношению 9:16
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 16.0/9.0),
            
            // Текст под фото
            captionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: padding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding) // Не прижимаем жестко к низу
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with post: Post) {
        // Устанавливаем данные автора из поста
        usernameLabel.text = post.authorUsername ?? "Unknown User"
        let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        if let avatarUrlString = post.authorAvatarURL, let url = URL(string: avatarUrlString) {
             userAvatarImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            userAvatarImageView.image = placeholder
            userAvatarImageView.tintColor = .darkGray
        }
        
        // Устанавливаем данные поста
        captionLabel.text = post.caption
        if let url = URL(string: post.imageURL) {
            postImageView.kf.indicatorType = .activity
            postImageView.kf.setImage(with: url)
        }
    }
} 