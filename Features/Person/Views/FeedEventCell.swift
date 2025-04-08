import UIKit

class FeedEventCell: UITableViewCell {

    static let identifier = "FeedEventCell"

    // Контейнер ("пузырь") для сообщения
    private let messageBubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.18, alpha: 1.0) // Чуть светлее фона карточки
        view.layer.cornerRadius = 8 // Свое скругление
        return view
    }()

    // Лейбл для описания события
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0 // Автоматический перенос строк
        return label
    }()

    // Лейбл для времени
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    // Инициализаторы
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear // Фон contentView ячейки прозрачный
        backgroundColor = .clear          // И фон самой ячейки тоже
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Добавление subviews
    private func setupViews() {
        contentView.addSubview(messageBubbleView) // Пузырь добавляем на contentView
        // Лейблы добавляем ВНУТРЬ пузыря
        messageBubbleView.addSubview(descriptionLabel)
        messageBubbleView.addSubview(timestampLabel)
    }

    // Настройка констрейнтов
    private func setupConstraints() {
        // Отступы пузыря от краев ячейки
        let cellPadding: CGFloat = 5 // Можно настроить
        // Отступы текста внутри пузыря
        let bubblePadding: CGFloat = 8

        NSLayoutConstraint.activate([
            // --- Констрейнты для messageBubbleView ВНУТРИ contentView ---
            messageBubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: cellPadding),
            messageBubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: cellPadding * 2),
            messageBubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -cellPadding * 2),
            messageBubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -cellPadding),

            // --- Констрейнты для descriptionLabel ВНУТРИ messageBubbleView ---
            descriptionLabel.topAnchor.constraint(equalTo: messageBubbleView.topAnchor, constant: bubblePadding),
            descriptionLabel.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor, constant: bubblePadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor, constant: -bubblePadding),

            // --- Констрейнты для timestampLabel ВНУТРИ messageBubbleView ---
            timestampLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor, constant: bubblePadding),
            timestampLabel.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor, constant: -bubblePadding),
            // Привязываем низ timestampLabel к низу "пузыря"
            timestampLabel.bottomAnchor.constraint(equalTo: messageBubbleView.bottomAnchor, constant: -bubblePadding)
        ])
    }

    // Конфигурация ячейки
    public func configure(with event: FeedEvent, dateFormatter: DateFormatter) {
        descriptionLabel.text = event.description
        timestampLabel.text = dateFormatter.string(from: event.timestamp)
    }
}
