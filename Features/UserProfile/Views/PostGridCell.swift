import UIKit
import Kingfisher

class PostGridCell: UICollectionViewCell {
    
    static let identifier = "PostGridCell"
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true // Важно для скругления
        imageView.backgroundColor = .secondarySystemBackground // Placeholder
        // Добавляем скругление углов
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true // Убедимся, что изображение обрезается
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.kf.cancelDownloadTask() // Отменяем загрузку при переиспользовании
        postImageView.image = nil // Сбрасываем изображение
    }
    
    private func setupViews() {
        contentView.addSubview(postImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with post: Post) {
        // Загружаем изображение поста
        if let url = URL(string: post.imageURL) {
            postImageView.kf.indicatorType = .activity
            postImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            postImageView.image = UIImage(systemName: "photo") // Placeholder
            postImageView.tintColor = .gray
        }
    }
} 