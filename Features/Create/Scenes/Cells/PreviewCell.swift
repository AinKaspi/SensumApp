import UIKit
import Kingfisher // Если будем показывать URL в будущем

/// Ячейка для отображения превью изображения (исходного или кропнутого)
class PreviewCell: UICollectionViewCell {
    static let identifier = "PreviewCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit // Отображаем все изображение, вписывая его
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black // Фон, если изображение с прозрачностью
        return imageView
    }()
    
    // Опциональная рамка для индикации выбранного соотношения
    private let aspectRatioOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.layer.borderWidth = 2
        view.isHidden = true // Скрыта по умолчанию
        return view
    }()
    
    private var aspectRatioConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.addSubview(imageView)
        contentView.addSubview(aspectRatioOverlayView)
        setupConstraints()
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
            
            // Overlay для AR центрирован и будет иметь констрейнт соотношения сторон
            aspectRatioOverlayView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            aspectRatioOverlayView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            aspectRatioOverlayView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            aspectRatioOverlayView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor)
        ])
    }
    
    func configure(with image: UIImage?, targetAspectRatio: CGFloat? = nil) {
        imageView.image = image
        
        // Настраиваем рамку соотношения сторон, если оно передано
        if let targetAR = targetAspectRatio {
            aspectRatioOverlayView.isHidden = false
            
            // Удаляем старый констрейнт, если он был
            aspectRatioConstraint?.isActive = false
            
            // Рассчитываем размер рамки, вписанной в imageView
            let viewSize = imageView.bounds.size
            guard viewSize.width > 0, viewSize.height > 0 else { return }
            
            var overlayWidth: CGFloat
            var overlayHeight: CGFloat
            
            if viewSize.width / viewSize.height >= 1.0 / targetAR { // Если view шире, чем нужно
                overlayHeight = viewSize.height
                overlayWidth = overlayHeight / targetAR // Ширина = Высота / Соотношение (H/W)
            } else { // Если view выше, чем нужно
                overlayWidth = viewSize.width
                overlayHeight = overlayWidth * targetAR // Высота = Ширина * Соотношение (H/W)
            }
            
            // Добавляем констрейнт соотношения сторон для overlay
            // Важно: targetAR = Height / Width
            aspectRatioConstraint = aspectRatioOverlayView.widthAnchor.constraint(equalTo: aspectRatioOverlayView.heightAnchor, multiplier: 1.0 / targetAR)
            aspectRatioConstraint?.priority = .defaultHigh // Избегаем конфликтов
            aspectRatioConstraint?.isActive = true
            
            // Дополнительно ограничиваем размер рамки
            NSLayoutConstraint.activate([
                aspectRatioOverlayView.widthAnchor.constraint(equalToConstant: overlayWidth),
                aspectRatioOverlayView.heightAnchor.constraint(equalToConstant: overlayHeight)
            ])
            
        } else {
            aspectRatioOverlayView.isHidden = true
            aspectRatioConstraint?.isActive = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        aspectRatioOverlayView.isHidden = true
        aspectRatioConstraint?.isActive = false
    }
} 