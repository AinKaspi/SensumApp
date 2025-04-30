import UIKit

// Определяем протокол делегата
protocol PostCropViewControllerDelegate: AnyObject {
    func postCropDidFinish(item: EditableMediaItem)
    func postCropDidCancel()
}

/// Экран для ручного кропа одного изображения под заданное соотношение сторон.
class PostCropViewController: UIViewController {

    weak var delegate: PostCropViewControllerDelegate?
    
    private var editableMediaItem: EditableMediaItem
    private let postAspectRatio: PostAspectRatio // Единое соотношение для поста

    // MARK: - UI Elements

    private lazy var cropView: ImageCropView = {
        let view = ImageCropView() // Используем наш существующий ImageCropView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Сетка третей (опционально)
    private lazy var gridOverlayView: UIView = {
        let view = GridOverlayView() // Предполагаем, что такой класс есть или будет создан
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false // Не должна мешать жестам cropView
        return view
    }()

    // MARK: - Initialization

    init(item: EditableMediaItem, aspectRatio: PostAspectRatio) {
        self.editableMediaItem = item
        self.postAspectRatio = aspectRatio
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen // Полноэкранный режим
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupNavigationBar()
        setupViews()
        setupConstraints()
        configureCropView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Crop"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        // Стиль NavigationBar (можно вынести в ThemeManager или BaseViewController)
        navigationController?.isNavigationBarHidden = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupViews() {
        view.addSubview(cropView)
        view.addSubview(gridOverlayView) // Добавляем сетку поверх cropView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // cropView занимает все доступное пространство под навбаром
            cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Сетка накладывается точно на cropView
            gridOverlayView.topAnchor.constraint(equalTo: cropView.topAnchor),
            gridOverlayView.leadingAnchor.constraint(equalTo: cropView.leadingAnchor),
            gridOverlayView.trailingAnchor.constraint(equalTo: cropView.trailingAnchor),
            gridOverlayView.bottomAnchor.constraint(equalTo: cropView.bottomAnchor)
        ])
    }
    
    private func configureCropView() {
        cropView.image = editableMediaItem.originalImage
        cropView.aspectRatio = postAspectRatio.ratio // Устанавливаем переданное соотношение
        
        // Загружаем сохраненные параметры кропа, если они есть
        if let zoom = editableMediaItem.manualZoomScale, let offset = editableMediaItem.manualContentOffset {
            cropView.setCrop(zoomScale: zoom, contentOffset: offset)
        } else {
            cropView.resetCropParameters() // Сбрасываем к дефолту, если параметров нет
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.postCropDidCancel()
        // dismiss(animated: true)
    }

    @objc private func doneTapped() {
        // 1. Сохраняем параметры кропа из cropView
        editableMediaItem.manualZoomScale = cropView.currentZoomScale
        editableMediaItem.manualContentOffset = cropView.currentContentOffset
        // Опционально: можно генерировать и сохранять finalImage здесь, 
        // но это может быть преждевременно, если пользователь вернется к кропу.
        // editableMediaItem.finalImage = cropView.croppedImage()
        
        print("✅ PostCropVC: Done tapped. Saved crop parameters: zoom=\(cropView.currentZoomScale), offset=\(cropView.currentContentOffset)")
        
        // 2. Уведомляем делегата
        delegate?.postCropDidFinish(item: editableMediaItem)
        
        // 3. Закрываем экран
        // dismiss(animated: true)
    }
}

// TODO: Создать класс GridOverlayView, который рисует сетку третей
class GridOverlayView: UIView {
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
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 