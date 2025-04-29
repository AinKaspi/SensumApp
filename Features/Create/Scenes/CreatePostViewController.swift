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

    // Добавляем View для предпросмотра кадрирования
    private lazy var cropPreviewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray // Для наглядности
        view.clipsToBounds = true
        // Добавим imageView внутрь для отображения контента
        view.addSubview(previewImageView)
        return view
    }()

    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Заполняем превью
        imageView.clipsToBounds = true
        return imageView
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
        textView.text = "Write a caption..."
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
        // Изначально кнопка "Share" может быть доступна, но мы будем управлять ее состоянием через биндинг
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(shareTapped))

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
        // Убираем старый imageView
        // view.addSubview(imageView)
        view.addSubview(cropPreviewView) // Добавляем превью
        view.addSubview(aspectRatioSegmentedControl) // Добавляем сегментный контрол
        view.addSubview(mediaCollectionView) // Добавляем коллекцию медиа
        view.addSubview(captionTextView)
        view.addSubview(activityIndicatorView)
    }

    private func setupConstraints() {
        let previewHeightMultiplier = PostAspectRatio.square.ratio // Начальное соотношение 1:1

        NSLayoutConstraint.activate([
            // Превью кадрирования сверху
            cropPreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cropPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Высота превью зависит от ширины и соотношения сторон (будет обновляться)
            cropPreviewView.heightAnchor.constraint(equalTo: cropPreviewView.widthAnchor, multiplier: previewHeightMultiplier),

            // ImageView внутри превью
            previewImageView.topAnchor.constraint(equalTo: cropPreviewView.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: cropPreviewView.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: cropPreviewView.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: cropPreviewView.bottomAnchor),

            // Сегментный контрол под превью
            aspectRatioSegmentedControl.topAnchor.constraint(equalTo: cropPreviewView.bottomAnchor, constant: 10),
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
        // Привязка текста из TextView к caption в ViewModel
        captionTextView.textPublisher
            // Пропускаем начальное значение плейсхолдера при первой загрузке
            .dropFirst(captionTextView.textColor == .placeholderText ? 1 : 0)
            // Удаляем начальные/конечные пробелы и новые строки
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .sink { [weak self] text in
                // Не обновляем ViewModel, если это плейсхолдер
                if self?.captionTextView.textColor != .placeholderText {
                    self?.viewModel.caption = text
                }
            }
            .store(in: &cancellables)

        // Наблюдение за состоянием загрузки
        viewModel.$isSharing
            .receive(on: DispatchQueue.main) // Обновляем UI в главном потоке
            .sink { [weak self] isSharing in
                self?.navigationItem.rightBarButtonItem?.isEnabled = !isSharing
                self?.captionTextView.isEditable = !isSharing
                self?.navigationItem.leftBarButtonItem?.isEnabled = !isSharing // Блокируем Cancel тоже
                if isSharing {
                    self?.activityIndicatorView.startAnimating()
                } else {
                    self?.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // Наблюдение за ошибками
        viewModel.$errorMessage
            .compactMap { $0 } // Пропускаем nil
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(message: errorMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelCreatingPost(self)
    }

    @objc private func shareTapped() {
        view.endEditing(true)
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
        // Обновление соотношения сторон превью произойдет через биндинг
    }

    // MARK: - Helpers

    private func updatePreviewImage(at index: Int) {
        guard index >= 0 && index < viewModel.selectedMedia.count else {
            previewImageView.image = nil // Очищаем, если индекс невалиден
            return
        }
        // TODO: Получить полноразмерное изображение или кешированную версию из ViewModel
        // Пока просто используем то, что есть в selectedMedia (это могут быть thumbnails)
        let media = viewModel.selectedMedia[index]
        switch media {
        case .image(let image):
            previewImageView.image = image
        // case .video(let avAsset): // TODO: Handle video preview (e.g., first frame)
        //     previewImageView.image = getThumbnailFrom(video: avAsset)
        default:
             previewImageView.image = nil // Placeholder for video or other types
        }
    }

    private func updateCropPreviewAspectRatio() {
        let aspectRatio = viewModel.selectedAspectRatio.ratio
        // Находим существующий constraint высоты и обновляем его multiplier
        if let heightConstraint = cropPreviewView.constraints.first(where: { $0.firstAttribute == .height }) {
            NSLayoutConstraint.deactivate([heightConstraint])
            let newHeightConstraint = cropPreviewView.heightAnchor.constraint(equalTo: cropPreviewView.widthAnchor, multiplier: aspectRatio)
            NSLayoutConstraint.activate([newHeightConstraint])
            // Анимируем изменение высоты
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            // Если constraint не найден (не должно случиться при правильной настройке)
            let newHeightConstraint = cropPreviewView.heightAnchor.constraint(equalTo: cropPreviewView.widthAnchor, multiplier: aspectRatio)
            NSLayoutConstraint.activate([newHeightConstraint])
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
        if textView.text.isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = .placeholderText
            // Если текст пуст, установим caption в ViewModel как пустую строку
            viewModel.caption = ""
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
