import UIKit
import Kingfisher

protocol CommentCellDelegate: AnyObject {
    func didTapReplyButton(for comment: Comment)
}

class CommentCell: UITableViewCell {

    static let identifier = "CommentCell"
    
    // MARK: - Properties
    
    private var comment: Comment?
    weak var delegate: CommentCellDelegate?
    
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
    
    // Добавляем кнопку "Ответить"
    private let replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Ответить", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.addTarget(self, action: #selector(handleReplyTap), for: .touchUpInside)
        return button
    }()
    
    // Добавляем контейнер для визуального отступа в случае ответа на комментарий
    private let indentationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        view.layer.cornerRadius = 1.5
        view.isHidden = true  // По умолчанию скрыт
        return view
    }()
    
    // Добавляем индикатор "В ответ пользователю" для ответов
    private let replyToLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.isHidden = true // По умолчанию скрыт
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
        indentationView.isHidden = true
        replyToLabel.isHidden = true
        replyToLabel.text = nil
        comment = nil
    }
    
    // MARK: - Actions
    
    @objc private func handleReplyTap() {
        guard let comment = comment else { return }
        delegate?.didTapReplyButton(for: comment)
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.addSubview(indentationView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(replyToLabel)
        contentView.addSubview(commentTextLabel)
        contentView.addSubview(replyButton)
    }

    private func setupConstraints() {
        let padding: CGFloat = 12
        let smallPadding: CGFloat = 8
        let avatarSize: CGFloat = 36
        let indentWidth: CGFloat = 3
        let indentLeading: CGFloat = padding / 2

        NSLayoutConstraint.activate([
            // Линия индентации (для вложенных комментариев)
            indentationView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            indentationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: indentLeading),
            indentationView.widthAnchor.constraint(equalToConstant: indentWidth),
            indentationView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            // Аватар - сдвигаем немного вправо в случае ответа
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            avatarImageView.leadingAnchor.constraint(equalTo: indentationView.trailingAnchor, constant: padding - indentLeading),
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
            
            // Лейбл "в ответ кому-то"
            replyToLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 1),
            replyToLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            replyToLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Текст комментария
            commentTextLabel.topAnchor.constraint(equalTo: replyToLabel.bottomAnchor, constant: 4),
            commentTextLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor), // Начинается там же, где имя
            commentTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Кнопка Reply
            replyButton.topAnchor.constraint(equalTo: commentTextLabel.bottomAnchor, constant: 6),
            replyButton.leadingAnchor.constraint(equalTo: commentTextLabel.leadingAnchor),
            replyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        // Чтобы timestampLabel не перекрывал usernameLabel
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configuration

    func configure(with comment: Comment) {
        self.comment = comment
        
        // Используем обновленную модель Comment
        if let user = comment.user {
            usernameLabel.text = user.username
            
            let placeholder = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            if let avatarURLString = user.avatarURL, let url = URL(string: avatarURLString) {
                avatarImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))])
            } else {
                avatarImageView.image = placeholder
            }
        } else {
            usernameLabel.text = "Неизвестный пользователь"
            avatarImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        }
        
        commentTextLabel.text = comment.text
        
        // Настраиваем отображение даты
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timestampLabel.text = dateFormatter.string(from: comment.timestamp.dateValue())
        
        // Настраиваем вид для ответа на комментарий
        if let _ = comment.parentCommentId {
            indentationView.isHidden = false
            replyToLabel.isHidden = false
            // TODO: Показать, на чей комментарий это ответ, но пока это требует
            // дополнительного запроса или загрузки родительского комментария
            replyToLabel.text = "Ответ на комментарий"
        } else {
            indentationView.isHidden = true
            replyToLabel.isHidden = true
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
