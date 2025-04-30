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

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with url: URL?) {
        guard let url = url else {
            imageView.image = UIImage(systemName: "photo")?.withTintColor(.darkGray)
            return
        }
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
} 