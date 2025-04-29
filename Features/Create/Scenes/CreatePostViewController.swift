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
        // Начальное соотношение сторон установится в viewDidLoad/updatePreviewImage
        return cropView
    }()

    // Добавляем кнопки/контролы для выбора соотношения сторон
    private lazy var aspectRatioSegmentedControl: UISegmentedControl = {
        let items = PostAspectRatio.allCases.map { $0.stringValue }
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0 // Индекс обновится в viewDidLoad/updatePreviewImage
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
        textView.text = "Write a caption... (optional)" // Placeholder
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
        setupConstraints() // Constraint для высоты imageCropView обновится в updatePreviewImage
        setupBindings()

        // Устанавливаем начальное изображение и соотношение для превью (если есть)
        updatePreviewImage(at: viewModel.selectedMediaIndex) // Используем начальный индекс из VM
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
        view.addSubview(imageCropView)
        view.addSubview(aspectRatioSegmentedControl)
        view.addSubview(mediaCollectionView)
        view.addSubview(captionTextView)
        view.addSubview(activityIndicatorView)
    }

    // Constraints для imageCropView height anchor
    private var imageCropViewHeightConstraint: NSLayoutConstraint?

    private func setupConstraints() {
        // Начальное соотношение 1:1, но оно будет обновлено
        let initialRatio = PostAspectRatio.square.ratio

        // Создаем constraint для высоты, но пока не активируем его полностью, сохраняем ссылку
        imageCropViewHeightConstraint = imageCropView.heightAnchor.constraint(equalTo: imageCropView.widthAnchor, multiplier: initialRatio)
        imageCropViewHeightConstraint?.priority = .defaultHigh // Даем возможность изменить

        NSLayoutConstraint.activate([
            // ImageCropView сверху
            imageCropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            imageCropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageCropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Активируем constraint высоты
            imageCropViewHeightConstraint!,

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
            // Привязка к низу Safe Area, чтобы клавиатура не перекрывала
            captionTextView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            // Индикатор активности по центру
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Привязываем выбранный индекс медиа
        viewModel.$selectedMediaIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                // Обновляем превью и контролы для выбранного элемента
                self?.updatePreviewImage(at: index)
                // Прокручиваем collectionView к выбранной ячейке (если нужно)
                let indexPath = IndexPath(item: index, section: 0)
                self?.mediaCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                // Выделяем ячейку визуально (если используется кастомный вид ячейки)
                // self?.mediaCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            }
            .store(in: &cancellables)

        // Привязываем массив медиа для перезагрузки коллекции при изменении
        // (например, если в будущем будет добавлено удаление/добавление)
        viewModel.$editableMedia
             .receive(on: DispatchQueue.main)
             .sink { [weak self] _ in
                 self?.mediaCollectionView.reloadData()
                 // После перезагрузки данных, возможно, нужно снова обновить превью
                 // на случай, если массив изменился, а индекс остался прежним
                 if let currentIndex = self?.viewModel.selectedMediaIndex {
                    self?.updatePreviewImage(at: currentIndex)
                 }
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
                // Убедимся, что индикатор остановлен перед показом ошибки
                self?.updateSharingState(isSharing: false)
                self?.showAlert(title: "Error", message: errorMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelCreatingPost(self)
    }

    @objc private func shareTapped() {
        view.endEditing(true) // Скрываем клавиатуру

        // 1. СОХРАНЯЕМ параметры кропа для ТЕКУЩЕГО элемента перед отправкой
        saveCurrentCropParameters()
        
        // 2. Устанавливаем текст из TextView в ViewModel
        viewModel.caption = (captionTextView.text == "Write a caption... (optional)") ? "" : captionTextView.text

        // 3. Запускаем процесс публикации из ViewModel
        viewModel.sharePost { [weak self] error in
            // Обработка завершения (успех/ошибка) выполняется через $isSharing и $errorMessage bindings
            DispatchQueue.main.async {
                 guard let self = self else { return }
                 if error == nil {
                     self.delegate?.didFinishCreatingPost(self)
                 }
                 // Сообщение об ошибке покажется через binding к $errorMessage
             }
        }
    }

    @objc private func aspectRatioChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        guard selectedIndex >= 0 && selectedIndex < PostAspectRatio.allCases.count else { return }
        let selectedAspectRatio = PostAspectRatio.allCases[selectedIndex]
        
        // 1. Обновляем соотношение в ViewModel (это также сбросит finalImage)
        viewModel.updateAspectRatioForCurrentItem(selectedAspectRatio)
        
        // 2. Сбрасываем параметры ручного кропа в ViewModel для текущего элемента
        viewModel.resetManualCropParametersForCurrentItem()
        
        // 3. Обновляем constraint высоты imageCropView немедленно
        updateImageCropViewHeightConstraint(ratio: selectedAspectRatio.ratio)
        
        // 4. Обновляем вид кропа в imageCropView (устанавливаем соотношение и сбрасываем зум/смещение)
        imageCropView.aspectRatio = selectedAspectRatio.ratio
        imageCropView.resetCropParameters(animated: true)
    }

    // MARK: - Helpers

    private func updatePreviewImage(at index: Int) {
        guard index >= 0 && index < viewModel.editableMedia.count else {
            // Нет изображения для показа, возможно, очистить imageCropView
            imageCropView.image = nil
            // Может быть, скрыть aspectRatioSegmentedControl или показать дефолтное состояние
            return
        }

        let currentItem = viewModel.editableMedia[index]

        // Устанавливаем изображение (берем finalImage если есть, иначе original)
        imageCropView.image = currentItem.finalImage ?? currentItem.originalImage

        // Устанавливаем текущее соотношение сторон для этого элемента
        let currentAspectRatio = currentItem.selectedAspectRatio
        imageCropView.aspectRatio = currentAspectRatio.ratio

        // ЗАГРУЖАЕМ параметры ручного кропа, если они есть
        if let zoom = currentItem.manualZoomScale, let offset = currentItem.manualContentOffset {
            imageCropView.setCrop(zoomScale: zoom, contentOffset: offset, animated: false)
            print("🖼️ Loaded manual crop for index \(index): zoom=\(zoom), offset=\(offset)")
        } else {
            // Если ручного кропа нет, сбрасываем к дефолту для этого aspect ratio
            imageCropView.resetCropParameters(animated: false)
            print("🖼️ No manual crop found for index \(index), resetting crop.")
        }

        // Обновляем segmented control, чтобы он отражал соотношение ТЕКУЩЕГО элемента
        if let aspectRatioIndex = PostAspectRatio.allCases.firstIndex(of: currentAspectRatio) {
            aspectRatioSegmentedControl.selectedSegmentIndex = aspectRatioIndex
        }

        // Обновляем constraint высоты для imageCropView
        updateImageCropViewHeightConstraint(ratio: currentAspectRatio.ratio)
    }

    // Обновляет констрейнт высоты для imageCropView
    private func updateImageCropViewHeightConstraint(ratio: CGFloat) {
        // Деактивируем старый constraint, если он есть
        imageCropViewHeightConstraint?.isActive = false
        // Создаем новый constraint с новым множителем
        imageCropViewHeightConstraint = imageCropView.heightAnchor.constraint(equalTo: imageCropView.widthAnchor, multiplier: ratio)
        imageCropViewHeightConstraint?.priority = .defaultHigh
        // Активируем новый constraint
        imageCropViewHeightConstraint?.isActive = true

        // Анимируем изменение layout, если нужно
         UIView.animate(withDuration: 0.3) {
             self.view.layoutIfNeeded()
         }
    }

    // НОВЫЙ Helper: Сохраняет параметры кропа из imageCropView в текущий viewModel.editableMedia
    private func saveCurrentCropParameters() {
        let currentIndex = viewModel.selectedMediaIndex
        guard currentIndex >= 0 && currentIndex < viewModel.editableMedia.count else { return }
        
        let zoomScale = imageCropView.currentZoomScale
        let contentOffset = imageCropView.currentContentOffset
        
        // Проверяем, отличается ли от дефолтного (minimumZoomScale)? 
        // Можно добавить более сложную проверку, если нужно избегать сохранения дефолтных значений
        // Используем публичный getter minimumZoomScale
        if zoomScale != imageCropView.minimumZoomScale || contentOffset != .zero { // Упрощенная проверка
             viewModel.setManualCropParametersForCurrentItem(zoomScale: zoomScale, contentOffset: contentOffset)
             print("💾 Saved manual crop for index \(currentIndex): zoom=\(zoomScale), offset=\(contentOffset)")
        } else {
             print("💾 Crop parameters for index \(currentIndex) are default, not saving.")
             // Опционально: можно сбросить параметры в nil, если они равны дефолтным
             // viewModel.resetManualCropParametersForCurrentItem()
        }
        
        // Также сохраняем финальное изображение, если нужно (например, для превью)
        // Это нужно, если мы хотим, чтобы thumbnail в mediaCollectionView отражал кроп
        // Но это может быть затратно по памяти, если изображений много
        // if let cropped = imageCropView.croppedImage() {
        //     viewModel.setCroppedImage(cropped, forIndex: currentIndex) 
        // }
    }

    // Helper для показа алертов
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    // Обновляет UI в зависимости от состояния загрузки
    private func updateSharingState(isSharing: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = !isSharing
        navigationItem.leftBarButtonItem?.isEnabled = !isSharing
        captionTextView.isEditable = !isSharing
        mediaCollectionView.isUserInteractionEnabled = !isSharing
        aspectRatioSegmentedControl.isEnabled = !isSharing
        if isSharing {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    // Helper для получения текущего кропнутого изображения (ИСПОЛЬЗУЕТСЯ ДЛЯ СОХРАНЕНИЯ В VM)
    private func getCurrentCroppedImage() -> UIImage? {
        return imageCropView.croppedImage()
    }
}

// MARK: - UICollectionViewDataSource
extension CreatePostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.editableMedia.count // Используем новый массив
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaThumbnailCell.reuseIdentifier, for: indexPath) as? MediaThumbnailCell else {
            fatalError("Unable to dequeue MediaThumbnailCell")
        }

        let item = viewModel.editableMedia[indexPath.item] // Получаем EditableMediaItem
        cell.configure(with: item.finalImage ?? item.originalImage) // Показываем final или original

        // Добавляем визуальное выделение для выбранной ячейки
        cell.isSelected = (indexPath.item == viewModel.selectedMediaIndex)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CreatePostViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 1. СОХРАНЯЕМ параметры кропа для ПРЕДЫДУЩЕГО элемента
        saveCurrentCropParameters()
        
        // 2. Обновляем индекс в ViewModel
        viewModel.selectedMediaIndex = indexPath.item

        // 3. Обновляем выделение ячеек (произойдет через binding к selectedMediaIndex -> updatePreviewImage -> reloadData)
        // collectionView.reloadData() // Перезагрузка теперь не нужна здесь, т.к. она в биндинге
        
        // 4. ЗАГРУЖАЕМ параметры кропа для НОВОГО элемента (произойдет в updatePreviewImage)
        // updatePreviewImage(at: indexPath.item) // Вызовется через binding
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CreatePostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Делаем ячейки квадратными, чтобы поместилось больше
        let height = collectionView.bounds.height - 4 // Небольшой отступ сверху/снизу
        return CGSize(width: height, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a caption... (optional)"
            textView.textColor = .placeholderText
        } else {
            // Передаем текст в ViewModel при завершении редактирования
            viewModel.caption = textView.text
        }
    }

    // Опционально: обновлять viewModel.caption по мере ввода
    // func textViewDidChange(_ textView: UITextView) {
    //     viewModel.caption = textView.text
    // }
}

// Удаляем временное определение MediaThumbnailCell, так как оно есть в своем файле
/*
// MARK: - Placeholder for MediaThumbnailCell
// TODO: Убедиться, что эта ячейка существует и настроена правильно
class MediaThumbnailCell: UICollectionViewCell {
    static let reuseIdentifier = "MediaThumbnailCell"
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        // Стиль для выделения
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = UIColor.systemBlue.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with image: UIImage?) {
        imageView.image = image
    }

    override var isSelected: Bool {
        didSet {
            contentView.layer.borderWidth = isSelected ? 2.0 : 0.0
        }
    }
} 
*/ 
