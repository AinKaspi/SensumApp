import UIKit

/// Представление для отображения и кропа изображения с поддержкой различных соотношений сторон
class ImageCropView: UIView {
    
    // MARK: - Public Properties
    
    /// Исходное изображение для кропа
    var image: UIImage? {
        didSet {
            guard let image = image else {
                scrollView.isHidden = true
                // Сбрасываем contentSize, если изображение удалено
                scrollView.contentSize = .zero
                imageView.image = nil // Убираем старое изображение
                return
            }
            
            scrollView.isHidden = false
            imageView.image = image
            
            // Устанавливаем contentSize СРАЗУ после получения изображения
            // Это размер контента при масштабе 1.0
            scrollView.contentSize = image.size
            print("✅ Image set. ContentSize = \(image.size)")
            
            // Сбрасываем параметры кропа, т.к. пришло новое изображение
            // Не анимируем, чтобы избежать визуальных артефактов при быстрой смене AR
            resetCropParameters(animated: false)
            
            // Запрашиваем обновление layout, т.к. изменился контент и его размер
            // layoutSubviews позаботится об остальном (констрейнты, зум, центр)
            setNeedsLayout()
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
        // 1. Сначала вызываем super
        super.layoutSubviews()
        
        // 2. Обновляем констрейнты контейнера для нового AR
        // Важно сделать это до расчета масштаба
        updateConstraintsForAspectRatio()
        
        // 3. Принудительно обновляем layout, чтобы containerView получил правильный размер
        // Это важно, так как updateMinZoomScaleForImage использует containerView.bounds
        superview?.layoutIfNeeded() // Используем layoutIfNeeded у superview или self?
                                   // Попробуем self.layoutIfNeeded() сначала.
        self.layoutIfNeeded()
        
        print("🔄 layoutSubviews: Bounds=\(self.bounds), Container=\(containerView.bounds)")
        
        // 4. Обновляем минимальный/максимальный зум, центрируем offset и обновляем инсеты
        if let image = image, scrollView.contentSize != .zero {
            updateZoomScaleAndSetInitialOffset(image: image, animated: false)
        } else if image == nil {
             // Если картинки нет, сбросим зум на всякий случай
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 1.0
            scrollView.zoomScale = 1.0
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
        guard scrollView.minimumZoomScale.isFinite, scrollView.minimumZoomScale > 0 else {
            print("⚠️ resetCropParameters: Invalid minimumZoomScale (\(scrollView.minimumZoomScale)). Cannot reset.")
            return
        }
        
        // Просто устанавливаем минимальный зум. 
        // Центрирование offset'а произойдет в updateZoomScaleAndSetInitialOffset ПОСЛЕ применения зума.
        print("🔄 Resetting Zoom to Minimum: \(scrollView.minimumZoomScale)")
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: animated)
        
        // Убираем расчет и установку offset отсюда
        /*
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        let offsetX = max(0, (imageViewSize.width - scrollViewSize.width) / 2)
        let offsetY = max(0, (imageViewSize.height - scrollViewSize.height) / 2)
        let targetOffset = CGPoint(x: offsetX, y: offsetY)
        print("🔄 Resetting Crop: Target Offset = \(targetOffset)")
        scrollView.setContentOffset(targetOffset, animated: animated)
        updateContentInsetsForCentering(animated: animated)
        */
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
        guard bounds.width > 0, bounds.height > 0, aspectRatio > 0 else {
            print("⚠️ updateConstraintsForAspectRatio: Invalid bounds or aspectRatio. Bounds=\(bounds), AR=\(aspectRatio)")
            return
        }
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        
        // Рассчитываем высоту, если бы ширина контейнера равнялась ширине view
        let heightBasedOnWidth = viewWidth / aspectRatio
        
        var targetWidth: CGFloat
        var targetHeight: CGFloat
        
        if heightBasedOnWidth <= viewHeight {
            // Контейнер помещается по высоте, используем полную ширину view
            targetWidth = viewWidth
            targetHeight = heightBasedOnWidth
            print("📐 AR Constraint Update (Fit Width): Target Size = (\(targetWidth), \(targetHeight))")
        } else {
            // Контейнер не помещается по высоте, используем полную высоту view
            targetWidth = viewHeight * aspectRatio
            targetHeight = viewHeight
            print("📐 AR Constraint Update (Fit Height): Target Size = (\(targetWidth), \(targetHeight))")
        }
        
        // Обновляем константы констрейнтов
        // Константа - это разница между размером scrollView и размером containerView
        // Мы хотим, чтобы containerView был по центру, поэтому разница делится пополам для инсетов,
        // но констрейнты width/height привязаны к scrollView (который равен bounds)
        containerViewWidthConstraint?.constant = -(viewWidth - targetWidth)
        containerViewHeightConstraint?.constant = -(viewHeight - targetHeight)
        
        print("   -> Constraints Updated: Width Constant = \(containerViewWidthConstraint?.constant ?? -999), Height Constant = \(containerViewHeightConstraint?.constant ?? -999)")
    }
    
    private func updateMinZoomScaleForImage(_ image: UIImage) {
        // Убираем старый лог
        // print("➡️ updateMinZoomScaleForImage called.")
        
        // Используем image.size напрямую вместо scrollView.contentSize
        guard containerView.bounds.width > 0, containerView.bounds.height > 0,
              image.size.width > 0, image.size.height > 0 else {
            print("⚠️ updateMinZoomScaleForImage: Invalid bounds or image size. Container: \(containerView.bounds), Image: \(image.size)")
            return
        }
        
        let cWidth = containerView.bounds.width
        let cHeight = containerView.bounds.height
        // Используем РАЗМЕР ИЗОБРАЖЕНИЯ!
        let iWidth = image.size.width
        let iHeight = image.size.height
        print("   📏 Calc Scale: Container=(\(cWidth), \(cHeight)), ImageSize=(\(iWidth), \(iHeight))")
        
        // Рассчитываем масштабы относительно размера изображения
        let widthScale = cWidth / iWidth
        let heightScale = cHeight / iHeight
        
        print("   📊 Scales: WidthScale=\(widthScale), HeightScale=\(heightScale)")
        
        // minScale должен ЗАПОЛНЯТЬ контейнер
        let minScale = max(widthScale, heightScale)
        
        // Ограничиваем максимальный зум относительно minScale, чтобы избежать слишком большого увеличения
        let maxScale = max(minScale * 3.0, 3.0) // Максимум в 3 раза больше minScale, но не меньше 3.0
        
        // Проверяем, что minScale не NaN или infinity
        guard minScale.isFinite, minScale > 0, maxScale.isFinite, maxScale > minScale else {
            print("⚠️ updateMinZoomScaleForImage: Invalid calculated scales. min: \(minScale), max: \(maxScale)")
            return
        }
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale
        
        print("🔎 Updated Zoom Scales: Min=\(minScale), Max=\(maxScale)")
        
        // Если текущий масштаб вне новых пределов, корректируем его
        if scrollView.zoomScale < minScale {
            print("   -> Setting zoomScale to minimum: \(minScale)")
            scrollView.setZoomScale(minScale, animated: false)
        } else if scrollView.zoomScale > maxScale {
             print("   -> Setting zoomScale to maximum: \(maxScale)")
             scrollView.setZoomScale(maxScale, animated: false)
        } else {
            // Если масштаб в пределах, просто центрируем
            centerImage()
        }
    }
    
    private func centerImage(animated: Bool = false) {
        // Добавляем проверку на почти нулевой размер imageView, что может случаться во время layout
        guard imageView.bounds.width > 1, imageView.bounds.height > 1 else {
            print("⚠️ centerImage: imageView bounds too small (\(imageView.bounds)). Skipping centering.")
            return
        }
        
        let scrollViewSize = scrollView.bounds.size
        // Размер imageView при текущем масштабе - используем frame, т.к. он учитывает transform
        let imageViewSize = imageView.frame.size
        
        // Проверка на валидность размеров
        guard scrollViewSize.width > 0, scrollViewSize.height > 0,
              imageViewSize.width.isFinite, imageViewSize.height.isFinite,
              imageViewSize.width >= 0, imageViewSize.height >= 0 else {
            print("⚠️ centerImage: Invalid sizes. ScrollView: \(scrollViewSize), ImageView: \(imageViewSize)")
            return
        }
        
        // Рассчитываем необходимый offset для центрирования
        let offsetX = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let offsetY = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
        
        print("🔄 Centering image: Frame=\(imageView.frame), Bounds=\(imageView.bounds), OffsetX = \(offsetX), OffsetY = \(offsetY)")

        // Устанавливаем contentInset, чтобы создать 'поля' для центрирования
        // Этот подход более стандартный для UIScrollView
        let newInsets = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        
        if scrollView.contentInset != newInsets {
            if animated {
                UIView.animate(withDuration: 0.2) {
                    self.scrollView.contentInset = newInsets
                }
            } else {
                scrollView.contentInset = newInsets
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
    
    // Переименовываем centerImage в updateContentInsetsForCentering
    private func updateContentInsetsForCentering(animated: Bool = false) {
        // Убираем guard let image, он не нужен для центрирования
        // guard let image = imageView.image else { return }
        
        // Добавляем проверку на почти нулевой размер imageView, что может случаться во время layout
        guard imageView.bounds.width > 1, imageView.bounds.height > 1 else {
            print("⚠️ updateContentInsetsForCentering: imageView bounds too small (\(imageView.bounds)). Skipping centering.")
            return
        }
        
        let scrollViewSize = scrollView.bounds.size
        // Размер imageView при текущем масштабе - используем frame, т.к. он учитывает transform
        let imageViewSize = imageView.frame.size
        
        // Проверка на валидность размеров
        guard scrollViewSize.width > 0, scrollViewSize.height > 0,
              imageViewSize.width.isFinite, imageViewSize.height.isFinite,
              imageViewSize.width >= 0, imageViewSize.height >= 0 else {
            print("⚠️ updateContentInsetsForCentering: Invalid sizes. ScrollView: \(scrollViewSize), ImageView: \(imageViewSize)")
            return
        }
        
        // Рассчитываем необходимый offset для центрирования
        let offsetX = max(0, (imageViewSize.width - scrollViewSize.width) / 2)
        let offsetY = max(0, (imageViewSize.height - scrollViewSize.height) / 2)
        
        print("🔄 Updating Insets: Frame=\(imageView.frame), Bounds=\(imageView.bounds), OffsetX = \(offsetX), OffsetY = \(offsetY)")

        // Устанавливаем contentInset, чтобы создать 'поля' для центрирования
        // Этот подход более стандартный для UIScrollView
        let newInsets = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        
        if scrollView.contentInset != newInsets {
            if animated {
                UIView.animate(withDuration: 0.2) {
                    self.scrollView.contentInset = newInsets
                }
            } else {
                scrollView.contentInset = newInsets
            }
        }
    }
    
    // Переименовываем и добавляем логику установки начального offset
    private func updateZoomScaleAndSetInitialOffset(image: UIImage, animated: Bool = false) {
        guard containerView.bounds.width > 0, containerView.bounds.height > 0,
              image.size.width > 0, image.size.height > 0 else {
            print("⚠️ updateZoomScaleAndSetInitialOffset: Invalid bounds or image size. Container: \(containerView.bounds), Image: \(image.size)")
            return
        }
        
        // --- ДОБАВЛЕНО ОБРАТНО: Расчет minScale и maxScale ---
        let cWidth = containerView.bounds.width
        let cHeight = containerView.bounds.height
        let iWidth = image.size.width
        let iHeight = image.size.height
        print("   📏 Calc Scale: Container=(\(cWidth), \(cHeight)), ImageSize=(\(iWidth), \(iHeight))")
        
        let widthScale = cWidth / iWidth
        let heightScale = cHeight / iHeight
        print("   📊 Scales: WidthScale=\(widthScale), HeightScale=\(heightScale)")
        
        let minScale = max(widthScale, heightScale)
        let maxScale = max(minScale * 3.0, 3.0) // Максимум в 3 раза больше minScale, но не меньше 3.0
        
        guard minScale.isFinite, minScale > 0, maxScale.isFinite, maxScale > minScale else {
            print("⚠️ updateZoomScaleAndSetInitialOffset: Invalid calculated scales. min: \(minScale), max: \(maxScale)")
            return
        }
        // --- КОНЕЦ ДОБАВЛЕННОГО БЛОКА ---
        
        print("🔎 Updated Zoom Scales: Min=\(minScale), Max=\(maxScale)")
        
        var zoomChanged = false
        var targetZoomScale = scrollView.zoomScale
        
        // Если текущий масштаб вне новых пределов, корректируем его
        if scrollView.zoomScale < minScale {
            print("   -> Setting zoomScale to minimum: \(minScale)")
            targetZoomScale = minScale
            zoomChanged = true
        } else if scrollView.zoomScale > maxScale {
             print("   -> Setting zoomScale to maximum: \(maxScale)")
             targetZoomScale = maxScale
             zoomChanged = true
        }
        
        if zoomChanged {
            scrollView.setZoomScale(targetZoomScale, animated: animated)
            // Важно: setZoomScale асинхронный, frame imageView обновится позже.
            // Чтобы точно отцентрировать, нужно это делать в scrollViewDidEndZooming или
            // использовать completion handler, если бы он был.
            // НО! Для НАЧАЛЬНОЙ установки (animated: false) можно попробовать сразу.
            // Вызываем layoutIfNeeded, чтобы обновить frame imageView немедленно после setZoomScale(..., animated: false)
            if !animated {
                 scrollView.layoutIfNeeded()
            }
        }
        
        // --- Установка НАЧАЛЬНОГО contentOffset ---
        // Делаем это ПОСЛЕ установки/проверки zoomScale
        let imageViewSize = imageView.frame.size // Frame должен быть актуален после layoutIfNeeded()
        let scrollViewSize = scrollView.bounds.size
        let offsetX = max(0, (imageViewSize.width - scrollViewSize.width) / 2)
        let offsetY = max(0, (imageViewSize.height - scrollViewSize.height) / 2)
        let targetOffset = CGPoint(x: offsetX, y: offsetY)
        
        // Устанавливаем offset только если зум МИНИМАЛЬНЫЙ (т.е. при инициализации/сбросе)
        // и текущий offset отличается. Не устанавливаем при ручном зуме/перетаскивании.
        if abs(scrollView.zoomScale - minScale) < 0.001 && scrollView.contentOffset != targetOffset {
            print("🎯 Setting Initial Content Offset: \(targetOffset) (Zoom: \(scrollView.zoomScale))")
            scrollView.setContentOffset(targetOffset, animated: animated)
        } else {
             print("   -> Skipping initial offset setting (Zoom: \(scrollView.zoomScale), MinZoom: \(minScale), Offset: \(scrollView.contentOffset), Target: \(targetOffset))")
        }
        
        // --- Обновление Content Insets ---
        // Вызываем всегда, чтобы инсеты были правильными для текущего зума/положения
        updateContentInsetsForCentering(animated: animated)
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Центрируем (обновляем инсеты) после зума
        updateContentInsetsForCentering(animated: false)
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
