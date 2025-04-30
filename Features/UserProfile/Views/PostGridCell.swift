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
        var targetUrl: URL?
        let postId = post.id ?? "N/A" // Получаем ID поста для логов

        // Пытаемся получить URL
        let gridUrlString = post.gridThumbnailURL // Доступ напрямую
        if !gridUrlString.isEmpty, let url = URL(string: gridUrlString) { // Убрали if let для строки
            targetUrl = url
            
        } else if let firstMediaItem = post.mediaItems.first {
            let mediaUrlString = firstMediaItem.url // Доступ напрямую
            if !mediaUrlString.isEmpty, let url = URL(string: mediaUrlString) { // Убрали if let для строки
                targetUrl = url
                
            }
        }
        
        // Если URL не был найден после обеих проверок
        if targetUrl == nil {
            print("⚠️ PostGridCell [\(postId)]: Не найден валидный URL.")
            // Устанавливаем плейсхолдер и выходим
            self.postImageView.image = UIImage(systemName: "photo.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
            self.postImageView.contentMode = .scaleAspectFit // Может быть лучше для плейсхолдера
            return
        }

        // Если URL найден, пытаемся загрузить через Kingfisher
        if let url = targetUrl {
            postImageView.contentMode = .scaleAspectFill // Возвращаем нужный contentMode
            postImageView.kf.indicatorType = .activity
            let placeholder = UIImage(systemName: "photo") // Простой плейсхолдер на время загрузки
            postImageView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage,
                    .retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(2))) // Добавим стратегию повтора
                ],
                completionHandler: { result in
                    switch result {
                    case .success(_): break
                        // value.source.url показывает URL, который ФАКТИЧЕСКИ использовал Kingfisher
                        
                    case .failure(let error):
                        // Логируем конкретную ошибку Kingfisher
                        print("❌ PostGridCell [\(postId)]: Kingfisher ОШИБКА для URL \(url.absoluteString). Ошибка: \(error.localizedDescription)")
                        // Можно установить изображение ошибки
                        self.postImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                        self.postImageView.contentMode = .scaleAspectFit
                    }
                }
            )
        }
    }
} 
