import UIKit
import Kingfisher

class MediaItemCell: UICollectionViewCell {
    static let identifier = "MediaItemCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Заполняем ячейку
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground // Placeholder
        // Добавляем скругление углов
        imageView.layer.cornerRadius = 8 // Можешь изменить значение по вкусу
        imageView.layer.masksToBounds = true // Убедимся, что обрезка по маске включена
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        setupConstraints()
        contentView.clipsToBounds = true // Убедимся, что ячейка обрезает контент
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        print("➡️ MediaItemCell [prepareForReuse]: Called. Retrying after restart.")
        super.prepareForReuse()
        // Отменяем загрузку и очищаем изображение
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        print("➡️ MediaItemCell [prepareForReuse]: imageView.image set to nil.")
    }

    override func layoutSubviews() {
        print("➡️ MediaItemCell [layoutSubviews]: Called. Retrying after restart.")
        super.layoutSubviews()
        // Добавляем округление углов здесь, если нужно, чтобы применялось после всех расчетов layout
        // contentView.layer.cornerRadius = 10 // Например
        // contentView.layer.masksToBounds = true
        print("➡️ MediaItemCell [layoutSubviews]: ImageView Frame: \(imageView.frame), Image Size: \(imageView.image?.size ?? .zero)")
    }

    // MARK: - Configuration

    func configure(with url: URL?) {
        print("➡️ MediaItemCell [configure]: Called. Retrying after restart.")
        guard let url = url else {
            imageView.image = UIImage(systemName: "photo")?.withTintColor(.darkGray)
            return
        }
        
        print("➡️ MediaItemCell [configure]: URL: \(url.absoluteString). ImageView Frame BEFORE load: \(imageView.frame)")

        // Настраиваем индикатор загрузки Kingfisher
        imageView.kf.indicatorType = .activity
        let placeholder = UIImage(systemName: "photo")?.withTintColor(.darkGray)
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}