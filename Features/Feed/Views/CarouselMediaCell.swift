import UIKit
import Kingfisher

class CarouselMediaCell: UICollectionViewCell {
    
    static let identifier = "CarouselMediaCell"
    
    private let mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Используем Fill для квадратных ячеек карусели
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground // Placeholder color
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(mediaImageView)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mediaImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.kf.cancelDownloadTask()
        mediaImageView.image = nil // Сбрасываем изображение
    }
    
    func configure(with mediaURL: String) {
        guard let url = URL(string: mediaURL) else {
            mediaImageView.image = UIImage(systemName: "photo") // Placeholder при ошибке URL
            mediaImageView.tintColor = .gray
            return
        }
        mediaImageView.kf.indicatorType = .activity
        mediaImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo")) { result in
            // Можно добавить обработку ошибок загрузки, если нужно
            switch result {
            case .failure(let error):
                print("Error loading carousel image: \(error.localizedDescription)")
                self.mediaImageView.image = UIImage(systemName: "exclamationmark.triangle")
                self.mediaImageView.tintColor = .systemRed
            case .success(_):
                break // Изображение успешно загружено
            }
        }
    }
}
