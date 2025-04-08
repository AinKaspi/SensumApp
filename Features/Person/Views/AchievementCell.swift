import UIKit

class AchievementCell: UICollectionViewCell {

    // Уникальный идентификатор для переиспользования ячейки
    static let identifier = "AchievementCell"

    // UIImageView для отображения иконки
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white // Цвет иконки
        return imageView
    }()

    // Инициализаторы
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .darkGray // Фон самой ячейки для наглядности
        contentView.layer.cornerRadius = 8
        contentView.addSubview(iconImageView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Настройка констрейнтов для иконки внутри ячейки
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7), // Иконка чуть меньше ячейки
            iconImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.7)
        ])
    }

    // Метод для конфигурации ячейки данными
    public func configure(with achievement: Achievement) {
        iconImageView.image = UIImage(systemName: achievement.iconName)
    }

    // Сброс перед переиспользованием (опционально, но хорошая практика)
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
    }
}
