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
            guard let image = sourceImage else {
                scrollView.isHidden = true
                imageView.image = nil
                scrollView.contentSize = .zero
                resetScrollViewState()
                needsInitialSetup = true // Готовимся к настройке при следующем layout
                return
            }

            scrollView.isHidden = false
            imageView.image = image
            scrollView.contentSize = image.size
            updateImageViewConstraints() // Обновляем констрейнты imageView под новый размер
            print("✅ Source Image set. ContentSize = \(image.size)")

            needsInitialSetup = true // Ставим флаг для выполнения начальной настройки в layoutSubviews
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
        // Используем Fit, т.к. размер imageView теперь определяется констрейнтами к contentSize
        imageView.contentMode = .scaleAspectFit
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
    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var containerViewWidthConstraint: NSLayoutConstraint?
    private var imageViewConstraints: [NSLayoutConstraint] = []

    // Флаг для отслеживания первой валидной настройки
    private var needsInitialSetup = true

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

        // 1. ScrollView
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        scrollView.delegate = self

        // 2. ContainerView (внутри ScrollView) - рамка кропа
        scrollView.addSubview(containerView)
        containerViewWidthConstraint = containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor) // Изначально равен ширине
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor) // Изначально равен высоте
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            containerViewWidthConstraint!,
            containerViewHeightConstraint!
        ])

        // 3. ImageView (внутри ScrollView) - ее размер = contentSize
        scrollView.addSubview(imageView)
        // Констрейнты для imageView будут установлены в updateImageViewConstraints()

        // 4. Dimming Overlay (поверх ScrollView)
        addSubview(dimmingOverlayView)
        NSLayoutConstraint.activate([
            dimmingOverlayView.topAnchor.constraint(equalTo: topAnchor),
            dimmingOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmingOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        dimmingOverlayView.layer.mask = overlayMaskLayer

        // 5. Grid Overlay (ВНУТРИ ContainerView)
        containerView.addSubview(gridOverlayView)
        NSLayoutConstraint.activate([
            // Привязываем сетку к границам ЕЕ SUPERVIEW (т.е. containerView)
            gridOverlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gridOverlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gridOverlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gridOverlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // 6. Жесты
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)

        // Инициализируем констрейнты imageView
        updateImageViewConstraints()
    }


    // MARK: - Layout & Update Logic

    override func layoutSubviews() {
        super.layoutSubviews()

        // --- 1. Проверяем валидность bounds ---
        guard bounds.width > 0, bounds.height > 0 else {
            // print("⚠️ layoutSubviews: Zero bounds, skipping layout.")
            return
        }

        // --- 2. Обновляем констрейнты containerView (рамки кропа) ---
        updateConstraintsForAspectRatio()

        // --- 3. Принудительно обновляем layout, чтобы containerView получил размер ---
        layoutIfNeeded() // Обновляем свой layout, чтобы containerView обновился

        print("🔄 layoutSubviews: Bounds=\(bounds), Container=\(containerView.bounds)")

        // --- 4. Обновляем маску затемнения ---
        updateOverlayMask()

        // --- 5. Настройка Zoom и Content Offset ---
        if let image = imageView.image {
            if needsInitialSetup {
                // Выполняем полную начальную настройку только один раз
                setupInitialZoomAndOffset(for: image)
                needsInitialSetup = false // Сбрасываем флаг
            } else {
                // При последующих layout просто проверяем и корректируем зум
                ensureZoomScaleWithinLimits()
                // И обновляем инсеты для центрирования
                updateContentInsetsForCentering()
            }
        } else {
            // Если картинки нет, сбрасываем состояние scrollView
            resetScrollViewState()
        }
    }

    // Обновление констрейнтов рамки кропа
    private func updateConstraintsForAspectRatio() {
        guard bounds.width > 0, bounds.height > 0, aspectRatio > 0 else {
            // print(\"⚠️ updateConstraintsForAspectRatio: Invalid bounds or aspectRatio.\")
            return
        }

        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let heightBasedOnWidth = viewWidth / aspectRatio

        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if heightBasedOnWidth <= viewHeight {
            targetWidth = viewWidth
            targetHeight = heightBasedOnWidth
        } else {
            targetWidth = viewHeight * aspectRatio
            targetHeight = viewHeight
        }

        let widthConstant = -(viewWidth - targetWidth)
        let heightConstant = -(viewHeight - targetHeight)

        // Обновляем только если изменилось
        if containerViewWidthConstraint?.constant != widthConstant {
            containerViewWidthConstraint?.constant = widthConstant
            // print(\"📐 AR Width Constraint Updated: Constant = \(widthConstant)\" )
        }
        if containerViewHeightConstraint?.constant != heightConstant {
             containerViewHeightConstraint?.constant = heightConstant
             // print(\"📐 AR Height Constraint Updated: Constant = \(heightConstant)\" )
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
        // print(\"📐 Updated ImageView Constraints for contentSize: \(contentSize)\")
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
        // print(\"🎭 Updated Overlay Mask: Bounds=\(bounds), ClearRect=\(clearRect)\")
    }

    // --- Логика Zoom / Offset ---

    // Выполняется один раз при первом layout после установки image или aspectRatio
    private func setupInitialZoomAndOffset(for image: UIImage) {
        guard bounds.width > 0, bounds.height > 0,
              containerView.bounds.width > 0, containerView.bounds.height > 0,
              image.size.width > 0, image.size.height > 0 else {
            print("⚠️ setupInitialZoomAndOffset: Invalid bounds or sizes. Cannot perform initial setup.")
            needsInitialSetup = true // Попробуем еще раз при следующем layout
            return
        }

        // 1. Рассчитываем min/max scale
        let cWidth = containerView.bounds.width
        let cHeight = containerView.bounds.height
        let iWidth = image.size.width
        let iHeight = image.size.height
        let widthScale = cWidth / iWidth
        let heightScale = cHeight / iHeight
        let minScale = max(widthScale, heightScale)
        let maxScale = max(minScale * 3.0, 3.0)

        guard minScale.isFinite, minScale > 0, maxScale.isFinite, maxScale > minScale else {
            print("⚠️ setupInitialZoomAndOffset: Invalid calculated scales. min: \(minScale), max: \(maxScale)")
            needsInitialSetup = true // Попробуем еще раз
            return
        }

        print("🚀 Performing Initial Setup: Min=\(minScale), Max=\(maxScale)")

        // 2. Устанавливаем пределы зума
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale

        // 3. Устанавливаем НАЧАЛЬНЫЙ зум
        scrollView.setZoomScale(minScale, animated: false)
        print("   -> Initial zoom set to: \(minScale)")

        // 4. Рассчитываем и устанавливаем НАЧАЛЬНЫЙ offset
        let expectedImageViewSize = CGSize(width: iWidth * minScale, height: iHeight * minScale)
        let scrollViewSize = scrollView.bounds.size // Используем bounds scrollView, т.к. contentInset еще может быть не настроен
        let targetOffsetX = max(0, (expectedImageViewSize.width - scrollViewSize.width) / 2)
        let targetOffsetY = max(0, (expectedImageViewSize.height - scrollViewSize.height) / 2)
        let targetOffset = CGPoint(x: targetOffsetX, y: targetOffsetY)

        print("   -> Setting Initial Content Offset: \(targetOffset)")
        scrollView.setContentOffset(targetOffset, animated: false)

        // 5. Обновляем инсеты (после установки offset)
        updateContentInsetsForCentering()
    }

    // Проверка и коррекция зума при последующих layout
    private func ensureZoomScaleWithinLimits() {
        guard scrollView.minimumZoomScale.isFinite, scrollView.maximumZoomScale.isFinite,
              scrollView.minimumZoomScale > 0, scrollView.maximumZoomScale >= scrollView.minimumZoomScale else {
            // print(\"⚠️ ensureZoomScaleWithinLimits: Invalid min/max zoom scales.\")
            return
        }

        let currentZoom = scrollView.zoomScale
        let minZoom = scrollView.minimumZoomScale
        let maxZoom = scrollView.maximumZoomScale

        var finalZoom = currentZoom
        if currentZoom < minZoom {
            finalZoom = minZoom
        } else if currentZoom > maxZoom {
            finalZoom = maxZoom
        }

        if abs(currentZoom - finalZoom) > 0.0001 {
            // print(\"   -> Correcting zoom scale from \(currentZoom) to \(finalZoom)\")
            scrollView.setZoomScale(finalZoom, animated: false)
        }
    }

    // Обновление инсетов для центрирования (вызывается из setupInitial... и scrollViewDidZoom)
    private func updateContentInsetsForCentering() {
        guard sourceImage != nil,
              imageView.bounds.width > 1, imageView.bounds.height > 1 else {
            if scrollView.contentInset != .zero { scrollView.contentInset = .zero }
            return
        }

        let imageViewSize = imageView.frame.size // frame учитывает текущий zoomScale
        let scrollViewSize = scrollView.bounds.size

        guard scrollViewSize.width > 0, scrollViewSize.height > 0,
              imageViewSize.width.isFinite, imageViewSize.height.isFinite,
              imageViewSize.width >= 0, imageViewSize.height >= 0 else {
            // print(\"⚠️ updateContentInsetsForCentering: Invalid sizes.\")
            return
        }

        // Рассчитываем отступы (положительные, если картинка меньше scrollView)
        let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
        let newInsets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)

        if scrollView.contentInset != newInsets {
            // print(\"🔄 Updating Insets to: \(newInsets)\")
            scrollView.contentInset = newInsets
        }
    }

    // Сброс состояния, вызываемый из VC
    func resetCropParameters(animated: Bool = false) {
        print("*** resetCropParameters called by VC ***")
        needsInitialSetup = true
        setNeedsLayout()
    }

    // Сброс состояния scrollView, если нет картинки
    private func resetScrollViewState() {
        print("--- Resetting ScrollView State (No Image) ---")
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = .zero
        scrollView.contentInset = .zero
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
        guard bounds.width > 0, bounds.height > 0 else {
            print("⚠️ setCrop called before view has bounds. Deferring may be needed.")
            // В идеале, нужно дождаться layout, но пока просто установим
            // и понадеемся, что ensureZoomScaleWithinLimits потом все скорректирует.
            // Либо PostCropViewController должен вызывать это позже (viewDidAppear).
            return // Пока просто выходим, если нет bounds
        }
        
        print("🔧 Applying saved crop: Zoom=\(zoomScale), Offset=\(contentOffset)")
        needsInitialSetup = false // Мы устанавливаем состояние вручную, инициализация не нужна
        scrollView.setZoomScale(zoomScale, animated: animated)
        scrollView.setContentOffset(contentOffset, animated: animated)
        // После установки нужно обновить инсеты
        updateContentInsetsForCentering()
    }
}


// MARK: - UIScrollViewDelegate
extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Обновляем инсеты после ручного зума
        updateContentInsetsForCentering()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Можно добавить логику, если нужно
    }
} 

