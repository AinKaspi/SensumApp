import UIKit
import Kingfisher // Если будем показывать URL в будущем

/// Ячейка для отображения превью изображения (исходного или кропнутого)
class PreviewCell: UICollectionViewCell {
    static let identifier = "PreviewCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black // Фон, если изображение с прозрачностью
        // --- УБИРАЕМ DEBUG BORDER ---
        // imageView.layer.borderColor = UIColor.red.cgColor
        // imageView.layer.borderWidth = 2.0
        // --- END DEBUG BORDER ---
        return imageView
    }()
    
    // Убираем aspectRatioOverlayView
    /*
    private let aspectRatioOverlayView: UIView = {
        ...
    }()
    */
    
    // Убираем ссылки на констрейнты overlay
    // private var overlayWidthConstraint: NSLayoutConstraint?
    // private var overlayHeightConstraint: NSLayoutConstraint?
    // private var overlayAspectRatioConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.addSubview(imageView)
        // Убираем добавление aspectRatioOverlayView
        // contentView.addSubview(aspectRatioOverlayView)
        setupConstraints()
        
        // --- DEBUG BACKGROUND ---
        contentView.backgroundColor = .purple // Устанавливаем фон для contentView
        // --- END DEBUG BACKGROUND ---
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ImageView занимает всю ячейку
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Убираем констрейнты для aspectRatioOverlayView
            /*
            aspectRatioOverlayView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            aspectRatioOverlayView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            */
        ])
        
        // Убираем создание констрейнтов для overlay
        /*
        overlayWidthConstraint = aspectRatioOverlayView.widthAnchor.constraint(equalToConstant: 0)
        ...
        */
    }
    
    // Упрощаем configure, убираем настройку overlay
    func configure(with image: UIImage?) { // Убираем targetAspectRatio
        imageView.image = image
        
        // Убираем всю логику настройки overlay
        /*
        if let targetAR = targetAspectRatio {
            ...
        } else {
            ...
        }
        */
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        // --- DEBUG BORDER --- 
        // Убираем рамку при реюзе, configure установит снова если надо
        // imageView.layer.borderWidth = 0 
        // --- END DEBUG BORDER ---
        // --- DEBUG BACKGROUND ---
        // contentView.backgroundColor = .black // Возвращаем фон при реюзе
        // --- END DEBUG BACKGROUND ---
        
        // Убираем деактивацию констрейнтов overlay
        /*
        overlayWidthConstraint?.isActive = false
        ...
        */
    }
} 