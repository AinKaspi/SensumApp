import UIKit
import PhotosUI

protocol ImageCropViewControllerDelegate: AnyObject {
    /// Вызывается, когда пользователь закончил кроп изображения
    /// - Parameter aspectRatioString: Строковое представление выбранного соотношения ("1:1", "9:16", "1.91:1")
    func imageCropViewController(_ controller: ImageCropViewController, didFinishCroppingImage image: UIImage, withAspectRatio aspectRatioString: String)
    
    /// Вызывается, когда пользователь отменил кроп
    func imageCropViewControllerDidCancel(_ controller: ImageCropViewController)
}

class ImageCropViewController: UIViewController {
    
    // MARK: - Public Properties
    
    weak var delegate: ImageCropViewControllerDelegate?
    
    // Добавляем свойства для передачи между экземплярами контроллера кропа
    var originalResults: [PHPickerResult]?
    var originalIndex: Int?
    var croppedImages: [MediaItem]?
    
    // MARK: - Private Properties
    
    private let originalImage: UIImage
    private let imageIndex: Int
    
    private lazy var cropView: ImageCropView = {
        let view = ImageCropView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var toolbarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отмена", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var aspectRatioSegmentedControl: UISegmentedControl = {
        let items = ["1:1", "9:16", "1.91:1"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = UIColor.darkGray
        control.selectedSegmentTintColor = UIColor.systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(aspectRatioChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // MARK: - Initialization
    
    init(image: UIImage, imageIndex: Int) {
        self.originalImage = image
        self.imageIndex = imageIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Устанавливаем изображение через свойство
        cropView.image = originalImage
        
        // Устанавливаем начальное соотношение сторон (квадрат)
        cropView.aspectRatio = 1.0
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Добавляем cropView
        view.addSubview(cropView)
        
        // Добавляем панель инструментов
        view.addSubview(toolbarView)
        toolbarView.addSubview(cancelButton)
        toolbarView.addSubview(doneButton)
        toolbarView.addSubview(aspectRatioSegmentedControl)
        
        // Устанавливаем констрейнты
        NSLayoutConstraint.activate([
            // Панель инструментов внизу экрана
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 60),
            
            // Crop View занимает все пространство над панелью
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor),
            
            // Кнопки в панели инструментов
            cancelButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            // Сегмент-контрол по центру
            aspectRatioSegmentedControl.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
            aspectRatioSegmentedControl.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            aspectRatioSegmentedControl.widthAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        delegate?.imageCropViewControllerDidCancel(self)
    }
    
    @objc private func doneButtonTapped() {
        if let croppedImage = cropView.croppedImage() {
            // Получаем строковое представление текущего выбранного соотношения
            let selectedIndex = aspectRatioSegmentedControl.selectedSegmentIndex
            let aspectRatioString = aspectRatioSegmentedControl.titleForSegment(at: selectedIndex) ?? "1:1" // Фоллбек на 1:1
            // Вызываем обновленный метод делегата
            delegate?.imageCropViewController(self, didFinishCroppingImage: croppedImage, withAspectRatio: aspectRatioString)
        } else {
            // Если по какой-то причине не удалось получить кропнутое изображение,
            // отменяем операцию
            delegate?.imageCropViewControllerDidCancel(self)
        }
    }
    
    @objc private func aspectRatioChanged(_ sender: UISegmentedControl) {
        let aspectRatio: CGFloat
        
        switch sender.selectedSegmentIndex {
        case 0:
            // 1:1
            aspectRatio = 1.0
        case 1:
            // 9:16 (Вертикальное)
            aspectRatio = 9.0 / 16.0
        case 2:
            // 1.91:1 (Горизонтальное)
            aspectRatio = 1.0 / 1.91
        default:
            aspectRatio = 1.0
        }
        
        // Обновляем соотношение сторон в view кропа
        cropView.aspectRatio = aspectRatio
    }
    
    // MARK: - Public Methods
    
    /// Возвращает индекс редактируемого изображения
    func getImageIndex() -> Int {
        return imageIndex
    }
} 