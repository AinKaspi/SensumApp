import UIKit
import Combine
import PhotosUI // Импортируем PhotosUI для PHPickerViewController

protocol CreatePostViewControllerDelegate: AnyObject {
    func didFinishCreatingPost(_ controller: CreatePostViewController)
    func didCancelCreatingPost(_ controller: CreatePostViewController)
}

// Используем PostAspectRatio из ViewModel

class CreatePostViewController: UIViewController {

    weak var delegate: CreatePostViewControllerDelegate?
    private let viewModel: CreatePostViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    // Заменяем imageView на collectionView для медиа
    private lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        // Размер ячейки будет установлен позже
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MediaThumbnailCell.self, forCellWithReuseIdentifier: MediaThumbnailCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // Добавляем ImageCropView вместо previewImageView
    private lazy var imageCropView: ImageCropView = {
        let cropView = ImageCropView()
        cropView.translatesAutoresizingMaskIntoConstraints = false
        return cropView
    }()

    // Добавляем кнопки/контролы для выбора соотношения сторон
    private lazy var aspectRatioSegmentedControl: UISegmentedControl = {
        let items = PostAspectRatio.allCases.map { $0.stringValue }
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0 // По умолчанию 1:1
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(aspectRatioChanged(_:)), for: .valueChanged)
        return control
    }()

    private lazy var captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 5
        textView.text = "Write a caption... (optional)"
        textView.textColor = .placeholderText
        textView.delegate = self
        return textView
    }()

    // Добавляем индикатор активности
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    // Обновляем init для приема ViewModel
    init(viewModel: CreatePostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
        setupBindings()

        // Устанавливаем начальное изображение для превью (если есть)
        updatePreviewImage(at: 0) // Показываем первое изображение
        updateCropPreviewAspectRatio() // Устанавливаем начальное соотношение сторон
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "New Post"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(shareTapped))

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
        view.backgroundColor = .black
        
        // Настраиваем навигационную панель
        title = "New Post"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(shareTapped))
        
        // Добавляем основные элементы на view
        view.addSubview(imageCropView) // Заменили previewImageView на imageCropView
        view.addSubview(aspectRatioSegmentedControl)
        view.addSubview(mediaCollectionView)
        view.addSubview(captionTextView)
        view.addSubview(activityIndicatorView)
    }

    private func setupConstraints() {
        // Используем aspectRatio = 1.0 для начального соотношения 1:1
        let cropViewHeightMultiplier = PostAspectRatio.square.ratio

        NSLayoutConstraint.activate([
            // ImageCropView сверху
            imageCropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            imageCropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageCropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Высота зависит от соотношения сторон (будет обновляться)
            imageCropView.heightAnchor.constraint(equalTo: imageCropView.widthAnchor, multiplier: cropViewHeightMultiplier),

            // Сегментный контрол под превью
            aspectRatioSegmentedControl.topAnchor.constraint(equalTo: imageCropView.bottomAnchor, constant: 10),
            aspectRatioSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            aspectRatioSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            // Коллекция медиа под сегментным контролом
            mediaCollectionView.topAnchor.constraint(equalTo: aspectRatioSegmentedControl.bottomAnchor, constant: 10),
            mediaCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaCollectionView.heightAnchor.constraint(equalToConstant: 100), // Фиксированная высота для горизонтального скролла

            // Текстовое поле под коллекцией
            captionTextView.topAnchor.constraint(equalTo: mediaCollectionView.bottomAnchor, constant: 10),
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            captionTextView.heightAnchor.constraint(equalToConstant: 80), // Задаем высоту для поля ввода

            // Индикатор активности по центру
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Привязываем аспектное соотношение
        viewModel.$selectedAspectRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] aspectRatio in
                guard let self = self else { return }
                self.aspectRatioSegmentedControl.selectedSegmentIndex = PostAspectRatio.allCases.firstIndex(of: aspectRatio) ?? 0
                self.imageCropView.aspectRatio = aspectRatio.ratio
            }
            .store(in: &cancellables)
        
        // Привязываем выбранный индекс медиа
        viewModel.$selectedMediaIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.updatePreviewImage(at: index)
            }
            .store(in: &cancellables)
        
        // Привязываем состояние загрузки
        viewModel.$isSharing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSharing in
                self?.updateSharingState(isSharing: isSharing)
            }
            .store(in: &cancellables)
        
        // Привязываем сообщения об ошибках
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "Error", message: errorMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelCreatingPost(self)
    }

    @objc private func shareTapped() {
        view.endEditing(true)
        
        // Получаем текущее выбранное и кропнутое изображение
        if let croppedImage = getCurrentCroppedImage() {
            viewModel.setCroppedImage(croppedImage, forIndex: viewModel.selectedMediaIndex)
        }
        
        // Отправляем пост
        viewModel.sharePost { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil {
                    self.delegate?.didFinishCreatingPost(self)
                }
            }
        }
    }

    @objc private func aspectRatioChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        guard selectedIndex >= 0 && selectedIndex < PostAspectRatio.allCases.count else { return }
        let selectedAspectRatio = PostAspectRatio.allCases[selectedIndex]
        viewModel.selectedAspectRatio = selectedAspectRatio
    }

    // MARK: - Helpers

    private func updatePreviewImage(at index: Int) {
        guard index >= 0 && index < viewModel.selectedMedia.count else {
            // Нет изображения для показа
            return
        }
        
        let media = viewModel.selectedMedia[index]
        switch media {
        case .image(let image):
            imageCropView.setImage(image)
        default:
            // Пока не поддерживаем другие типы медиа
            break
        }
    }

    private func updateCropPreviewAspectRatio() {
        let aspectRatio = viewModel.selectedAspectRatio.ratio
        // Находим существующий constraint высоты и обновляем его multiplier
        if let heightConstraint = imageCropView.constraints.first(where: { $0.firstAttribute == .height }) {
            NSLayoutConstraint.deactivate([heightConstraint])
            let newHeightConstraint = imageCropView.heightAnchor.constraint(equalTo: imageCropView.widthAnchor, multiplier: aspectRatio)
            NSLayoutConstraint.activate([newHeightConstraint])
            // Анимируем изменение высоты
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            // Если constraint не найден (не должно случиться при правильной настройке)
            let newHeightConstraint = imageCropView.heightAnchor.constraint(equalTo: imageCropView.widthAnchor, multiplier: aspectRatio)
            NSLayoutConstraint.activate([newHeightConstraint])
        }
    }

    private func getCurrentCroppedImage() -> UIImage? {
        return imageCropView.getCroppedImage()
    }

    private func updateSharingState(isSharing: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = !isSharing
        captionTextView.isEditable = !isSharing
        navigationItem.leftBarButtonItem?.isEnabled = !isSharing // Блокируем Cancel тоже
        if isSharing {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    private func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension CreatePostViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.selectedMedia.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaThumbnailCell.reuseIdentifier, for: indexPath) as? MediaThumbnailCell else {
            fatalError("Unable to dequeue MediaThumbnailCell")
        }
        let media = viewModel.selectedMedia[indexPath.item]
        cell.configure(with: media)
        // TODO: Add visual indication for the selected item (viewModel.selectedMediaIndex)
        cell.layer.borderWidth = (indexPath.item == viewModel.selectedMediaIndex) ? 2.0 : 0.0
        cell.layer.borderColor = (indexPath.item == viewModel.selectedMediaIndex) ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Делаем ячейки квадратными, равными высоте коллекции
        let height = collectionView.bounds.height - collectionView.contentInset.top - collectionView.contentInset.bottom
        return CGSize(width: height, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedMediaIndex = indexPath.item
        // Обновление превью и выделения ячейки произойдет через биндинги
        collectionView.reloadData() // Перезагружаем для обновления выделения
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
            // Поскольку текст изменился, вручную присваиваем пустую строку ViewModel,
            // так как publisher сработает только при следующем вводе символа
            viewModel.caption = ""
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || textView.text == "Write a caption... (optional)" {
            textView.text = "Write a caption... (optional)"
            textView.textColor = .placeholderText
            // Если текст пуст или это плейсхолдер, устанавливаем caption в ViewModel как пустую строку
            viewModel.caption = ""
        } else {
            // Если есть реальный текст, сохраняем его
            viewModel.caption = textView.text
        }
    }

    // Опционально: Обновлять ViewModel при каждом изменении текста
    // (textPublisher уже делает это, но можно добавить сюда, если нужно доп. логика)
//    func textViewDidChange(_ textView: UITextView) {
//        if textView.textColor != .placeholderText {
//            viewModel.caption = textView.text ?? ""
//        }
//    }
} 

// Убрали временные определения MediaThumbnailCell и MediaItem
