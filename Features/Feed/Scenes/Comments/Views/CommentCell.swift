import UIKit
import Kingfisher

class CommentCell: UITableViewCell {

    static let identifier = "CommentCell"

    // MARK: - UI Elements

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18 // Немного меньше, чем в PostCell
        imageView.backgroundColor = .darkGray
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .lightGray
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        // label.setContentHuggingPriority(.required, for: .horizontal)
        // label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .right
        // label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let commentTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0 // Позволяем тексту переноситься
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .black // Фон ячейки
        selectionStyle = .none
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
        commentTextLabel.text = nil
        timestampLabel.text = nil
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(commentTextLabel)
    }

    private func setupConstraints() {
        let padding: CGFloat = 12
        let smallPadding: CGFloat = 8
        let avatarSize: CGFloat = 36

        NSLayoutConstraint.activate([
            // Аватар
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),
            // Низ аватара необязательно привязывать, т.к. есть commentTextLabel

            // Имя пользователя
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: smallPadding),
            
            // Время комментария
            timestampLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: smallPadding),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Текст комментария
            commentTextLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: smallPadding / 2),
            commentTextLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor), // Начинается там же, где имя
            commentTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            // Привязываем низ текста к низу контента ячейки
            commentTextLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        // Чтобы timestampLabel не перекрывал usernameLabel
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configuration

    func configure(with comment: Comment) {
        usernameLabel.text = comment.authorUsername
        commentTextLabel.text = comment.text
        
        // Временная замена timeAgoDisplay на DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timestampLabel.text = dateFormatter.string(from: comment.date) 
        // timestampLabel.text = comment.date.timeAgoDisplay() // Используем расширение Date

        let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        if let avatarUrlString = comment.authorAvatarUrl, let url = URL(string: avatarUrlString) {
            avatarImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.image = placeholder
        }
    }
}

// TODO: Добавить расширение Date для timeAgoDisplay(), если его еще нет
// Пример расширения:
/*
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
*/
