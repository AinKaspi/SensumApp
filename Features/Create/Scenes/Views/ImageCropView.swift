import Foundation
@_spi(SPI) import UIKit

class ImageCropView: UIView {
    
    // MARK: - Properties
    private var imageView: UIImageView!
    private var scrollView: UIScrollView!
    private var overlayView: UIView!
    
    // Текущее соотношение сторон
    var aspectRatio: CGFloat = 1.0 {
        didSet {
            updateCropFrame()
        }
    }
    
    // Исходное изображение
    private var originalImage: UIImage?
    
    // Минимальный и максимальный зум
    private let minZoomScale: CGFloat = 1.0
    private var maxZoomScale: CGFloat = 3.0
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        // Создаем ScrollView для зума и перемещения изображения
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)
        
        // Создаем ImageView для отображения изображения
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        
        // Создаем полупрозрачный оверлей для затемнения области вне кропа
        overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)
        
        // Устанавливаем констрейнты
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Добавляем жест двойного тапа для зума
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    // MARK: - Public Methods
    
    func setImage(_ image: UIImage) {
        // Сохраняем оригинальное изображение
        originalImage = image
        imageView.image = image
        
        // Сбрасываем зум
        scrollView.zoomScale = 1.0
        
        // Масштабируем изображение, чтобы оно сразу было полностью видно
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Рассчитываем размеры изображения и обновляем кроп
            self.layoutIfNeeded()
            self.updateCropFrame()
            
            // Устанавливаем минимальный масштаб и отображаем всё изображение
            if let image = self.imageView.image {
                // Определяем размеры контейнера
                let containerSize = self.scrollView.bounds.size
                
                // Вычисляем соотношение сторон изображения и контейнера
                let imageRatio = image.size.width / image.size.height
                let containerRatio = containerSize.width / containerSize.height
                
                // Определяем начальный масштаб, чтобы всё изображение было видно
                var initialScale: CGFloat = 1.0
                
                if imageRatio > containerRatio {
                    // Если изображение шире контейнера
                    initialScale = containerSize.width / imageView.bounds.width
                } else {
                    // Если изображение выше контейнера
                    initialScale = containerSize.height / imageView.bounds.height
                }
                
                // Устанавливаем начальный масштаб
                self.scrollView.minimumZoomScale = initialScale
                self.scrollView.zoomScale = initialScale
                self.scrollView.maximumZoomScale = initialScale * 3.0
                
                // Центрируем изображение
                self.centerImageInScrollView()
            }
        }
    }
    
    func getCroppedImage() -> UIImage? {
        return croppedImage()
    }
    
    func croppedImage() -> UIImage? {
        guard let image = originalImage else { return nil }
        
        // Вычисляем фактический видимый прямоугольник
        let cropRect = computeVisibleRectForCrop()
        
        // Если весь скролл виден, просто преобразуем все изображение
        if cropRect.size.width >= imageView.bounds.width && cropRect.size.height >= imageView.bounds.height {
            return image
        }
        
        // Вычисляем соотношение размеров оригинального изображения к отображаемому
        let scaleX = image.size.width / imageView.bounds.width
        let scaleY = image.size.height / imageView.bounds.height
        
        // Преобразуем cropRect в координаты оригинального изображения
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * scaleX,
            y: cropRect.origin.y * scaleY,
            width: cropRect.size.width * scaleX,
            height: cropRect.size.height * scaleY
        )
        
        // Вырезаем часть изображения
        if let cgImage = image.cgImage?.cropping(to: scaledCropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func updateCropFrame() {
        guard let image = imageView.image else { return }
        
        // Определяем размер вида кропа (размер scrollView)
        let cropViewWidth = bounds.width
        let cropViewHeight = cropViewWidth * aspectRatio
        
        // Проверяем, чтобы высота не выходила за пределы bounds
        let adjustedCropViewHeight = min(cropViewHeight, bounds.height)
        
        // Если высота ограничена, пересчитываем ширину
        let adjustedCropViewWidth = adjustedCropViewHeight / aspectRatio
        
        // Центрируем область кропа
        let cropRect = CGRect(
            x: (bounds.width - adjustedCropViewWidth) / 2,
            y: (bounds.height - adjustedCropViewHeight) / 2,
            width: adjustedCropViewWidth,
            height: adjustedCropViewHeight
        )
        
        // Обновляем размеры scrollView
        scrollView.frame = cropRect
        
        // Рассчитываем размер контента для изображения
        let imageRatio = image.size.width / image.size.height
        let viewRatio = cropRect.width / cropRect.height
        
        var contentWidth: CGFloat = 0
        var contentHeight: CGFloat = 0
        
        if imageRatio > viewRatio {
            // Изображение шире области кропа
            contentHeight = cropRect.height
            contentWidth = contentHeight * imageRatio
        } else {
            // Изображение выше области кропа
            contentWidth = cropRect.width
            contentHeight = contentWidth / imageRatio
        }
        
        // Устанавливаем размер и положение imageView
        imageView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        // Центрируем контент
        let offsetX = max((contentWidth - cropRect.width) / 2, 0)
        let offsetY = max((contentHeight - cropRect.height) / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        
        // Настраиваем зум
        let xScale = cropRect.width / contentWidth
        let yScale = cropRect.height / contentHeight
        let minScale = max(xScale, yScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = minScale * 3.0 // Позволяем зумировать до 3х от минимума
        scrollView.zoomScale = minScale
        
        // Обновляем оверлей с вырезом для области кропа
        updateOverlayWithCutout(cropRect: cropRect)
    }
    
    private func updateOverlayWithCutout(cropRect: CGRect) {
        // Создаем path для вырезания области кропа
        let path = UIBezierPath(rect: bounds)
        let cutout = UIBezierPath(rect: cropRect)
        path.append(cutout.reversing())
        
        // Создаем слой с маской
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        
        overlayView.layer.mask = maskLayer
    }
    
    private func computeVisibleRectForCrop() -> CGRect {
        // Получаем видимый прямоугольник в scrollView
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x,
            y: scrollView.contentOffset.y,
            width: scrollView.bounds.width,
            height: scrollView.bounds.height
        )
        
        return visibleRect
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let pointInView = gesture.location(in: imageView)
            let newZoomScale = scrollView.maximumZoomScale / 2
            let width = scrollView.bounds.width / newZoomScale
            let height = scrollView.bounds.height / newZoomScale
            let x = pointInView.x - width / 2
            let y = pointInView.y - height / 2
            
            let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: rectToZoomTo, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }
    
    func centerImageInScrollView() {
        // Центрируем изображение после зума
        let offsetX = max((scrollView.contentSize.width - scrollView.bounds.width) / 2, 0)
        let offsetY = max((scrollView.contentSize.height - scrollView.bounds.height) / 2, 0)
        
        // Корректируем смещение, если контент меньше, чем scrollView
        let centerX = (scrollView.bounds.width > scrollView.contentSize.width) ?
            (scrollView.bounds.width - scrollView.contentSize.width) / 2 : 0
        let centerY = (scrollView.bounds.height > scrollView.contentSize.height) ?
            (scrollView.bounds.height - scrollView.contentSize.height) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(
            top: centerY,
            left: centerX,
            bottom: centerY,
            right: centerX
        )
    }
} 