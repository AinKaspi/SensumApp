import UIKit

// MARK: - GridOverlayView Definition (Moved from PostCropViewController)
/// View для отрисовки сетки третей поверх изображения.
private class GridOverlayView: UIView {

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let width = rect.width
        let height = rect.height

        let oneThirdWidth = width / 3
        let twoThirdsWidth = 2 * width / 3
        let oneThirdHeight = height / 3
        let twoThirdsHeight = 2 * height / 3

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(1.0 / UIScreen.main.scale) // Толщина в 1 пиксель

        // Вертикальные линии
        context.move(to: CGPoint(x: oneThirdWidth, y: 0))
        context.addLine(to: CGPoint(x: oneThirdWidth, y: height))
        context.move(to: CGPoint(x: twoThirdsWidth, y: 0))
        context.addLine(to: CGPoint(x: twoThirdsWidth, y: height))

        // Горизонтальные линии
        context.move(to: CGPoint(x: 0, y: oneThirdHeight))
        context.addLine(to: CGPoint(x: width, y: oneThirdHeight))
        context.move(to: CGPoint(x: 0, y: twoThirdsHeight))
        context.addLine(to: CGPoint(x: width, y: twoThirdsHeight))

        context.strokePath()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        isOpaque = false // Важно для прозрачности
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
}


// MARK: - ImageCropView Definition
/// Представление для отображения и кропа изображения с поддержкой различных соотношений сторон
class ImageCropView: UIView {

    // MARK: - Public Properties

    /// Исходное изображение для кропа
    var sourceImage: UIImage? {
        didSet {
            // --- НЕМЕДЛЕННЫЙ СБРОС состояния scrollView перед настройкой --- //
            resetScrollViewState() // Сбрасываем zoom, offset, insets, contentSize

            guard let image = sourceImage else {
                // Если новое изображение nil, очищаем imageView
                scrollView.isHidden = true
                imageView.image = nil // Очищаем image здесь
                // resetScrollViewState() уже вызван
                needsInitialSetup = true
                setNeedsLayout()
                return
            }

            // Если новое изображение есть, устанавливаем его
            scrollView.isHidden = false
            imageView.image = image // Устанавливаем image здесь
            scrollView.contentSize = image.size
            updateImageViewConstraints()
            print("✅ Source Image set. ContentSize = \(image.size)")

            needsInitialSetup = true
            setNeedsLayout()
        }
    }

    /// Соотношение сторон кропа (ширина / высота)
    var aspectRatio: CGFloat = 1.0 {
        didSet {
            if oldValue != aspectRatio {
                needsInitialSetup = true // Требуется перенастройка при смене AR
                setNeedsLayout()
                // layoutIfNeeded() // Не нужно здесь, layoutSubviews сделает
            }
        }
    }

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

    // MARK: - Private Properties

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        scrollView.clipsToBounds = false // Важно для зума за пределы frame
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // View, определяющий видимую область кропа
    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        // Возвращаем Fill, он лучше работает с bounds UIImageView
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black // Фон на случай прозрачности
        return imageView
    }()

    // Слой для затемнения области вне кропа
    private let dimmingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private let overlayMaskLayer = CAShapeLayer()

    // Сетка третей (приватный экземпляр)
    private let gridOverlayView: GridOverlayView = {
        let gridView = GridOverlayView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        return gridView
    }()

    // Констрейнты для динамического изменения
    private var containerViewWidthConstraint: NSLayoutConstraint?
    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var imageViewConstraints: [NSLayoutConstraint] = []

    // Флаг для отслеживания первой валидной настройки
    private var needsInitialSetup = true
    // Для отложенного восстановления состояния
    private var pendingZoomScale: CGFloat?
    private var pendingContentOffset: CGPoint?
    private var needsDeferredCropRestore = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .black
        clipsToBounds = true // Обрезаем все, что выходит за границы ImageCropView

        // 1. ContainerView (рамка кропа, дочерний self)
        addSubview(containerView)
        // Констрейнты размера будут управляться updateConstraintsForAspectRatio
        // Создаем констрейнты для ЗАДАНИЯ РАЗМЕРА (equalToConstant)
        containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: bounds.width) // Начальное значение
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: bounds.height) // Начальное значение
        containerViewWidthConstraint?.priority = .defaultHigh // Даем возможность измениться
        containerViewHeightConstraint?.priority = .defaultHigh // Даем возможность измениться

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerViewWidthConstraint!, // Активируем
            containerViewHeightConstraint!, // Активируем
            // Добавляем ограничивающие констрейнты, чтобы containerView не вылезал за границы
            containerView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ])

        // 2. ScrollView (дочерний self, размер равен containerView)
        addSubview(scrollView)
        scrollView.clipsToBounds = true // Обрезаем контент scrollView по его рамке
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        scrollView.delegate = self

        // 3. ImageView (внутри ScrollView)
        scrollView.addSubview(imageView)
        // Констрейнты imageView к scrollView.contentLayoutGuide устанавливаются в updateImageViewConstraints

        // 4. Dimming Overlay (поверх всего, кроме сетки)
        addSubview(dimmingOverlayView)
        NSLayoutConstraint.activate([
            dimmingOverlayView.topAnchor.constraint(equalTo: topAnchor),
            dimmingOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmingOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        dimmingOverlayView.layer.mask = overlayMaskLayer

        // 5. Grid Overlay (поверх Dimming, привязана к ContainerView)
        addSubview(gridOverlayView)
        NSLayoutConstraint.activate([
            gridOverlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gridOverlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gridOverlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gridOverlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // 6. Жесты (добавляем к scrollView)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)

        // Инициализируем констрейнты imageView
        updateImageViewConstraints()
    }


    // MARK: - Layout & Update Logic

    override func layoutSubviews() {
        super.layoutSubviews()

        // --- 1. Проверяем валидность bounds --- //
        guard bounds.width > 0, bounds.height > 0 else {
            return
        }

        // --- 2. Обновляем РАЗМЕР containerView (рамки кропа) --- //
        updateConstraintsForAspectRatio()

        // --- 3. Обновляем Layout немедленно, чтобы containerView и scrollView получили размеры --- //
        // Это нужно перед настройкой зума/смещения и маски
        layoutIfNeeded()

        print("🔄 layoutSubviews: Self.Bounds=\(bounds), Container=\(containerView.frame), Scroll=\(scrollView.frame)")

        // --- 4. Настройка Zoom/Offset и обновление маски --- //
        if let image = imageView.image {
             if needsInitialSetup {
                setupInitialZoomAndOffset(for: image)
                needsInitialSetup = false // Сбрасываем флаг ПОСЛЕ успешной начальной настройки
             } else {
                updateContentInsetsForCentering()
             }
             updateOverlayMask()
        } else {
             resetScrollViewState()
             updateOverlayMask()
        }

        // --- 5. Применяем отложенное состояние, если оно есть --- //
        applyPendingCropStateIfNeeded()
    }

    // Обновление констрейнтов РАЗМЕРА рамки кропа (containerView)
    private func updateConstraintsForAspectRatio() {
        guard bounds.width > 0, bounds.height > 0, aspectRatio > 0 else {
            return
        }

        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let heightBasedOnWidth = viewWidth / aspectRatio

        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if heightBasedOnWidth <= viewHeight {
            // Ширина равна viewWidth, высота подгоняется
            targetWidth = viewWidth
            targetHeight = heightBasedOnWidth
        } else {
            // Высота равна viewHeight, ширина подгоняется
            targetWidth = viewHeight * aspectRatio
            targetHeight = viewHeight
        }

        // Устанавливаем константы для констрейнтов РАЗМЕРА containerView
        // Теперь это констрейнты equalToConstant, обновляем их константы
        let newWidthConstant = targetWidth
        let newHeightConstant = targetHeight

        // Обновляем только если изменилось
        if containerViewWidthConstraint?.constant != newWidthConstant {
            containerViewWidthConstraint?.constant = newWidthConstant
            print("📐 AR Width Constraint Updated: Constant = \(newWidthConstant)" )
        }
        if containerViewHeightConstraint?.constant != newHeightConstant {
             containerViewHeightConstraint?.constant = newHeightConstant
             print("📐 AR Height Constraint Updated: Constant = \(newHeightConstant)" )
        }
    }

    // Обновление констрейнтов imageView при смене contentSize
    private func updateImageViewConstraints() {
        let contentSize = scrollView.contentSize
        // Обновляем, только если contentSize валидный
        guard contentSize.width > 0, contentSize.height > 0 else { return }

        NSLayoutConstraint.deactivate(imageViewConstraints)
        imageViewConstraints = [
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: contentSize.width),
            imageView.heightAnchor.constraint(equalToConstant: contentSize.height)
        ]
        NSLayoutConstraint.activate(imageViewConstraints)
        // print("📐 Updated ImageView Constraints for contentSize: \(contentSize)")
    }

    // Обновление маски затемнения
    private func updateOverlayMask() {
        let path = UIBezierPath(rect: bounds)
        let clearRect = containerView.convert(containerView.bounds, to: self)

        guard bounds.intersects(clearRect) else {
            overlayMaskLayer.path = path.cgPath
            return
        }

        path.append(UIBezierPath(rect: clearRect))
        overlayMaskLayer.path = path.cgPath
        overlayMaskLayer.fillRule = .evenOdd
        // print("🎭 Updated Overlay Mask: Bounds=\(bounds), ClearRect=\(clearRect)")
    }

    // Обновление инсетов для центрирования контента ВНУТРИ scrollView
    private func updateContentInsetsForCentering() {
        // Получаем текущий размер scrollView (равен containerView)
        let scrollViewSize = scrollView.bounds.size
        guard scrollViewSize.width > 0, scrollViewSize.height > 0 else { return }

        // Получаем размер imageView (контента) с учетом текущего зума
        let contentSize = imageView.bounds.size // Размер imageView совпадает с image.size
        let scaledContentWidth = contentSize.width * scrollView.zoomScale
        let scaledContentHeight = contentSize.height * scrollView.zoomScale

        // Рассчитываем необходимые отступы для центрирования
        var insetTop: CGFloat = 0
        var insetLeft: CGFloat = 0

        if scaledContentWidth < scrollViewSize.width {
            insetLeft = (scrollViewSize.width - scaledContentWidth) / 2.0
        }
        if scaledContentHeight < scrollViewSize.height {
            insetTop = (scrollViewSize.height - scaledContentHeight) / 2.0
        }

        let newInsets = UIEdgeInsets(top: insetTop, left: insetLeft, bottom: insetTop, right: insetLeft)

        // Применяем инсеты, если они изменились
        if scrollView.contentInset != newInsets {
            print("🔄 Updating Insets: \(newInsets)")
            scrollView.contentInset = newInsets
        }
    }


    // --- ЛОГИКА ZOOM/OFFSET ---
    // Основная функция начальной настройки
    private func setupInitialZoomAndOffset(for image: UIImage) {
        guard let containerSize = (containerView.bounds.size.width > 0 && containerView.bounds.size.height > 0) ? containerView.bounds.size : nil,
              image.size.width > 0, image.size.height > 0 else {
            print("⚠️ setupInitialZoomAndOffset: Invalid bounds/sizes.")
            needsInitialSetup = true
            return
        }

        // 1. Рассчитываем min/max scale (minScale теперь "Aspect Fill")
        let iWidth = image.size.width
        let iHeight = image.size.height
        let cWidth = containerSize.width
        let cHeight = containerSize.height

        let scaleWidth = cWidth / iWidth
        let scaleHeight = cHeight / iHeight
        let initialScale = max(scaleWidth, scaleHeight) // Aspect Fill scale

        // Max scale остается как был, но не меньше initialScale + небольшой буфер
        let maxScale = max(initialScale * 4.0, 3.0, initialScale + 0.1)

        guard initialScale.isFinite, initialScale > 0, maxScale.isFinite, maxScale >= initialScale else {
            print("⚠️ setupInitialZoomAndOffset: Invalid scales. initial: \(initialScale), max: \(maxScale)")
            needsInitialSetup = true
            return
        }

        print("🚀 Performing Initial Setup (Aspect Fill): Initial/Min=\(initialScale), Max=\(maxScale)")

        // 2. Устанавливаем пределы зума
        scrollView.minimumZoomScale = initialScale
        scrollView.maximumZoomScale = maxScale

        // 3. Устанавливаем НАЧАЛЬНЫЙ зум СИНХРОННО
        scrollView.setZoomScale(initialScale, animated: false)
        print("   -> Initial zoom set to: \(initialScale)")

        // 4. Рассчитываем и устанавливаем НАЧАЛЬНЫЙ offset (центрируем)
        let scaledImageWidth = iWidth * initialScale
        let scaledImageHeight = iHeight * initialScale

        var targetOffsetX: CGFloat = 0
        var targetOffsetY: CGFloat = 0

        if scaledImageWidth > cWidth {
            targetOffsetX = (scaledImageWidth - cWidth) / 2.0
        }
        if scaledImageHeight > cHeight {
            targetOffsetY = (scaledImageHeight - cHeight) / 2.0
        }

        let targetOffset = CGPoint(x: targetOffsetX, y: targetOffsetY)

        print("   -> Setting Initial Content Offset: \(targetOffset)")
        scrollView.setContentOffset(targetOffset, animated: false)

        // 5. Устанавливаем инсеты (скорее всего будут 0 при Aspect Fill, но на всякий случай)
        updateContentInsetsForCentering()

        // 6. Обновляем маску после всех настроек
        updateOverlayMask()
    }

    // Сброс состояния, вызываемый из VC или при смене картинки
    func resetCropParameters(animated: Bool = false) {
        print("*** resetCropParameters called by VC ***")
        resetScrollViewState() // Добавляем явный сброс состояния scrollView
        needsInitialSetup = true
        setNeedsLayout()
    }

    // Сброс состояния scrollView
    private func resetScrollViewState() {
        print("--- Resetting ScrollView State --- ")
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0 // Сброс max zoom тоже важен
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = .zero
        scrollView.contentInset = .zero
        scrollView.contentSize = .zero // Сбрасываем contentSize
        // Убираем очистку imageView.image отсюда
        // imageView.image = nil
    }

    // MARK: - Actions

    @objc private func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale + 0.001 { // Добавляем допуск
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
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

    // MARK: - Public Methods

    /// Устанавливает параметры кропа (масштаб и смещение)
    /// Используется для ВОССТАНОВЛЕНИЯ сохраненного состояния.
    func setCrop(zoomScale: CGFloat, contentOffset: CGPoint, animated: Bool = false) {
        // Убедимся, что view готово
        if bounds.width > 0 && bounds.height > 0 {
            print("🔧 Applying saved crop IMMEDIATELY: Zoom=\(zoomScale), Offset=\(contentOffset)")
            // Применяем немедленно
            scrollView.setZoomScale(zoomScale, animated: animated)
            scrollView.setContentOffset(contentOffset, animated: animated)
            updateContentInsetsForCentering() // Обновляем инсеты для нового состояния
            // Сбрасываем флаги, т.к. мы успешно применили состояние
            needsInitialSetup = false
            needsDeferredCropRestore = false
            pendingZoomScale = nil
            pendingContentOffset = nil
        } else {
            // View еще не готово, откладываем применение
            print("⚠️ setCrop called before view has bounds. Deferring application.")
            pendingZoomScale = zoomScale
            pendingContentOffset = contentOffset
            needsDeferredCropRestore = true
            // НЕ сбрасываем needsInitialSetup, т.к. начальная настройка все еще нужна
        }
    }

    // Применяет отложенное состояние, если оно было установлено
    private func applyPendingCropStateIfNeeded() {
        guard needsDeferredCropRestore,
              let zoom = pendingZoomScale,
              let offset = pendingContentOffset else {
            return
        }

        print("🔧 Applying DEFERRED crop: Zoom=\(zoom), Offset=\(offset)")
        // Устанавливаем с анимацией false, т.к. это происходит во время layout
        scrollView.setZoomScale(zoom, animated: false)
        scrollView.setContentOffset(offset, animated: false)
        updateContentInsetsForCentering() // Пересчитываем инсеты

        // Сбрасываем флаги/состояние
        needsDeferredCropRestore = false
        pendingZoomScale = nil
        pendingContentOffset = nil
        // needsInitialSetup уже должен быть false к этому моменту, т.к. setupInitial... отработал
    }
}


// MARK: - UIScrollViewDelegate
extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // После ручного зума нужно ОБНОВИТЬ инсеты (которые всегда 0)
        updateContentInsetsForCentering()
        // Удаляем вызов adjustContentOffsetAfterZoom
        // print("🔍 scrollViewDidZoom: Zoom = \(scrollView.zoomScale)")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Можно добавить логику, если нужно
        // print("↕️ scrollViewDidScroll: Offset = \(scrollView.contentOffset)")
    }
} 

