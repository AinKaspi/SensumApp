import UIKit
// import AVFoundation // Убрали, т.к. видео не поддерживается

class MediaThumbnailCell: UICollectionViewCell {
    static let reuseIdentifier = "MediaThumbnailCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .darkGray // Placeholder color
        return iv
    }()

    // Убрали videoIconImageView

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        // Убрали videoIconImageView из subviews

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Убрали констрейнты для videoIconImageView
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Меняем сигнатуру для приема UIImage?
    func configure(with image: UIImage?) {
        imageView.image = image
        // Убираем switch, так как теперь принимаем только UIImage?
        /*
        switch media {
        case .image(let image):
            imageView.image = image
        // case .video: // Убрали обработку видео
        //     break
        }
        */
        // Убрали currentMediaItem
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        // Убрали videoIconImageView.isHidden = true
        // Убрали thumbnailGenerator?.cancelAllCGImageGeneration()
        // Убрали currentMediaItem = nil
    }

    // Убрали MARK: - Helpers и все связанные с видео свойства и методы
    // (thumbnailGenerator, currentMediaItem, generateThumbnail)
}

// Убрали дублирующееся определение MediaItem