import UIKit

/// Представление для отображения и кропа изображения с поддержкой различных соотношений сторон
class ImageCropView: UIView {
    
    // MARK: - Public Properties
    
    /// Исходное изображение для кропа
    var image: UIImage? {
        didSet {
            guard let image = image else {
                scrollView.isHidden = true
                return
            }
            
            scrollView.isHidden = false
            imageView.image = image
            resetCropParameters(animated: false)
            
            // Обновляем layout после того, как view будет размещено
            if superview != nil {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }
    
    /// Соотношение сторон кропа (ширина / высота)
    var aspectRatio: CGFloat = 1.0 {
        didSet {
            if oldValue != aspectRatio {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        scrollView.clipsToBounds = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var containerViewWidthConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateConstraintsForAspectRatio()
        
        // Обновляем минимальный зум ПОСЛЕ обновления констрейнтов контейнера
        if let image = image {
            updateMinZoomScaleForImage(image)
        }
    }
    
    // MARK: - Public Methods (Crop Parameters)
    
    /// Текущий масштаб масштабирования изображения
    var currentZoomScale: CGFloat {
        return scrollView.zoomScale
    }
    
    /// Минимально допустимый масштаб масштабирования
    var minimumZoomScale: CGFloat {
        return scrollView.minimumZoomScale
    }
    
    /// Текущее смещение содержимого scrollView
    var currentContentOffset: CGPoint {
        return scrollView.contentOffset
    }
    
    /// Устанавливает параметры кропа (масштаб и смещение)
    /// - Parameters:
    ///   - zoomScale: Новый масштаб
    ///   - contentOffset: Новое смещение
    ///   - animated: Анимировать ли изменение
    func setCrop(zoomScale: CGFloat, contentOffset: CGPoint, animated: Bool = false) {
        scrollView.setZoomScale(zoomScale, animated: animated)
        scrollView.setContentOffset(contentOffset, animated: animated)
    }
    
    /// Сбрасывает позицию и масштаб изображения к начальным значениям
    /// - Parameter animated: Анимировать ли сброс
    func resetCropParameters(animated: Bool = false) {
        let minZoom = scrollView.minimumZoomScale
        scrollView.setZoomScale(minZoom, animated: animated)
        // После сброса зума нужно перецентровать
        centerImage(animated: animated)
    }
    
    
    // MARK: - Public Methods (Image Interaction)
    
    /// Возвращает кропнутое изображение с текущими настройками
    func croppedImage() -> UIImage? {
        guard let image = image else { return nil }
        
        // Соотношение оригинальное изображение / отображаемое
        let scale = image.size.width / imageView.bounds.size.width
        
        // Видимый прямоугольник прокрутки
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x,
            y: scrollView.contentOffset.y,
            width: scrollView.bounds.width,
            height: scrollView.bounds.height
        )
        
        // Коэффициент масштабирования
        let zoomScale = scrollView.zoomScale
        
        // Рассчитываем прямоугольник в координатах оригинального изображения
        let cropRect = CGRect(
            x: visibleRect.origin.x * scale / zoomScale,
            y: visibleRect.origin.y * scale / zoomScale,
            width: visibleRect.size.width * scale / zoomScale,
            height: visibleRect.size.height * scale / zoomScale
        )
        
        // Создаем контекст для рисования кропнутого изображения
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        print("⚠️ ImageCropView: Не удалось выполнить кроп cgImage.cropping(to: cropRect)")
        return nil
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        backgroundColor = .black
        
        // Добавляем scrollView
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Настройка scrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
        // Добавляем контейнер и imageView
        scrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        
        // Изображение должно заполнять весь контейнер
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Создаем ограничения для контейнера, которые будем обновлять
        containerViewWidthConstraint = containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            containerViewWidthConstraint!,
            containerViewHeightConstraint!
        ])
        
        // Добавляем жесты
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    private func updateConstraintsForAspectRatio() {
        // Определяем размеры контейнера на основе соотношения сторон
        let containerWidth = bounds.width
        let containerHeight = containerWidth / aspectRatio
        
        // Если высота контейнера больше высоты view, корректируем размеры
        if containerHeight > bounds.height {
            let newWidth = bounds.height * aspectRatio
            containerViewWidthConstraint?.constant = -bounds.width + newWidth
            containerViewHeightConstraint?.constant = 0
        } else {
            containerViewWidthConstraint?.constant = 0
            containerViewHeightConstraint?.constant = -bounds.height + containerHeight
        }
        
        scrollView.contentSize = CGSize(width: containerWidth, height: containerHeight)
    }
    
    private func updateMinZoomScaleForImage(_ image: UIImage) {
        let widthScale = containerView.bounds.width / image.size.width
        let heightScale = containerView.bounds.height / image.size.height
        
        // Используем максимальный масштаб, чтобы изображение целиком заполняло контейнер
        let minScale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        
        // Если текущий масштаб меньше минимального, устанавливаем минимальный
        if scrollView.zoomScale < minScale {
            scrollView.zoomScale = minScale
        }
        
        centerImage()
    }
    
    private func centerImage(animated: Bool = false) {
        // Центрируем изображение, если оно меньше, чем scrollView
        let contentWidth = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height
        let scrollViewSize = scrollView.bounds.size
        
        // Используем frame imageView вместо contentSize, т.к. contentSize может быть больше scrollView
        let imageViewSize = imageView.frame.size
        
        let horizontalPadding = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let verticalPadding = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
        
        let newInsets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.scrollView.contentInset = newInsets
            }
        } else {
            scrollView.contentInset = newInsets
        }
        
        // Корректируем contentOffset, если изображение стало меньше видимой области
        // чтобы избежать пустого пространства по краям после зума/отдаления
        let newOffsetX = max(-newInsets.left, min(scrollView.contentOffset.x, contentWidth - scrollViewSize.width + newInsets.right))
        let newOffsetY = max(-newInsets.top, min(scrollView.contentOffset.y, contentHeight - scrollViewSize.height + newInsets.bottom))
        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)

        if !scrollView.contentOffset.equalTo(newOffset) {
             if animated {
                 UIView.animate(withDuration: 0.2) {
                     self.scrollView.contentOffset = newOffset
                 }
             } else {
                 scrollView.contentOffset = newOffset
             }
        }
    }
    
    @objc private func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // Если уже приближено, отдаляем
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Иначе приближаем к месту двойного тапа
            let pointInView = gestureRecognizer.location(in: imageView)
            let zoomRect = CGRect(
                x: pointInView.x - (scrollView.bounds.width / 4),
                y: pointInView.y - (scrollView.bounds.height / 4),
                width: scrollView.bounds.width / 2,
                height: scrollView.bounds.height / 2
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // Указываем, какой view масштабировать
        return imageView // Масштабируем imageView, а не containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Центрируем изображение после зума
        centerImage(animated: false) // Не анимируем при зуме пальцами
    }
    
    // Опционально: можно добавить scrollViewDidEndZooming для сохранения состояния
     func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
         // Можно использовать для вызова делегата или сохранения состояния
         print("ScrollView Did End Zooming at scale: \(scale)")
     }

     // Опционально: можно добавить scrollViewDidEndDragging/Decelerating для сохранения состояния
     func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
         if !decelerate {
             // Сохраняем состояние, если скролл закончился без инерции
             print("ScrollView Did End Dragging at offset: \(scrollView.contentOffset)")
         }
     }

     func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         // Сохраняем состояние, если скролл закончился с инерцией
         print("ScrollView Did End Decelerating at offset: \(scrollView.contentOffset)")
     }
} 