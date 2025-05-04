import UIKit
import Kingfisher // Если будем показывать URL в будущем

/// Ячейка для отображения превью изображения (исходного или кропнутого)
class PreviewCell: UICollectionViewCell {
    static let identifier = "PreviewCell"

    // MARK: - Properties
    private var currentImage: UIImage?
    // ✅ Добавляем контейнер и констрейнты для управления его размером
    private let containerView = UIView()
    private var containerWidthConstraint: NSLayoutConstraint?
    private var containerHeightConstraint: NSLayoutConstraint?

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // ✅ Устанавливаем фон contentView прозрачным
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.clipsToBounds = true // Убедимся, что contentView обрезает containerView
        // ❌ Убираем скругление с основного слоя ячейки
        // layer.cornerRadius = 10
        // layer.masksToBounds = true
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true // Обрезка по границам контейнера важна
        // ✅ Применяем скругление к containerView
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true // Можно и clipsToBounds, но masksToBounds тут тоже подходит
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(imageView)

        // ✅ Инициализируем констрейнты размера контейнера (сначала 0)
        containerWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: 0)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        // Устанавливаем приоритет ниже required, чтобы избежать конфликтов при инициализации
        containerWidthConstraint?.priority = .defaultHigh
        containerHeightConstraint?.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Центрируем containerView в contentView
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            // Убедимся, что containerView не вылезает за границы contentView
            containerView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor),
            
            // Активируем констрейнты размера
            containerWidthConstraint!,
            containerHeightConstraint!,
            
            // imageView заполняет containerView
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // ✅ Возвращаем configure с aspectRatio
    func configure(with image: UIImage, aspectRatio: PostAspectRatio) {
        imageView.image = image
        currentImage = image
        
        // Рассчитываем целевой размер для containerView
        let targetRatio = aspectRatio.ratio // Ширина / Высота
        let availableSize = contentView.bounds.size
        
        guard availableSize.width > 0, availableSize.height > 0 else {
            // Если размер contentView еще не определен, откладываем расчет
            // Можно установить дефолтные значения или 0
            containerWidthConstraint?.constant = 0
            containerHeightConstraint?.constant = 0
            print("⚠️ PreviewCell Configure: contentView bounds zero, cannot calculate size yet.")
            return
        }

        var targetWidth: CGFloat
        var targetHeight: CGFloat

        // Рассчитываем максимальный размер, вписывающийся в availableSize с нужным aspectRatio
        if availableSize.width / availableSize.height >= targetRatio { 
            // Ограничено высотой availableSize
            targetHeight = availableSize.height
            targetWidth = targetHeight * targetRatio
        } else { 
            // Ограничено шириной availableSize
            targetWidth = availableSize.width
            targetHeight = targetWidth / targetRatio
        }
        
        // 🐞 DEBUG: Логируем расчетные размеры контейнера
        print("🐞 PreviewCell Configure: AR=\(aspectRatio.stringValue), Available=\(availableSize), Target W=\(targetWidth), H=\(targetHeight)")

        // Обновляем константы констрейнтов
        containerWidthConstraint?.constant = targetWidth
        containerHeightConstraint?.constant = targetHeight
        
        // Принудительное обновление layout не нужно здесь, 
        // т.к. изменение констант само вызовет перерасчет при следующем цикле runloop.
        // contentView.layoutIfNeeded() 
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        currentImage = nil
        // Сбрасываем размер контейнера, чтобы избежать артефактов
        containerWidthConstraint?.constant = 0
        containerHeightConstraint?.constant = 0
    }
}