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
        // Сначала конфигурируем cropView с изображением и AR
        configureCropView()
        // Затем добавляем его в иерархию и устанавливаем констрейнты
        setupViews()
        setupConstraints()
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
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // cropView занимает все доступное пространство под навбаром
            cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func configureCropView() {
        // Используем промежуточную переменную с явным типом
        let imageToSet: UIImage? = editableMediaItem.originalImage
        cropView.sourceImage = imageToSet
        
        cropView.aspectRatio = postAspectRatio.ratio // Устанавливаем переданное соотношение
        
        // Загружаем сохраненные параметры кропа, если они есть
        if let zoom = editableMediaItem.manualZoomScale, let offset = editableMediaItem.manualContentOffset {
            print("🔧 configureCropView: Applying saved crop parameters: Zoom=\(zoom), Offset=\(offset)")
            cropView.setCrop(zoomScale: zoom, contentOffset: offset)
        } else {
            // ВОЗВРАЩАЕМ вызов resetCropParameters, если нет сохраненных данных
            print("🔧 configureCropView: No saved crop parameters. Resetting crop view state.")
            cropView.resetCropParameters() // Вызываем сброс явно
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