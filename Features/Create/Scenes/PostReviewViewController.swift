import UIKit
import Combine

// TODO: Возможно, нужен делегат для обработки закрытия или ошибки

/// Финальный экран для просмотра обрезанных изображений, добавления подписи и публикации поста.
class PostReviewViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    // ViewModel для управления состоянием и публикацией
    // Используем существующий CreatePostViewModel, адаптированный для нового флоу
    private var viewModel: CreatePostViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private lazy var previewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        // Размер теперь будет задаваться через UICollectionViewDelegateFlowLayout
        // layout.itemSize = CGSize(width: view.bounds.width * 0.8, height: view.bounds.height * 0.5) 
        layout.minimumLineSpacing = 0
        // Добавляем отступы по краям, чтобы первая/последняя ячейка не прилипала
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
        // TODO: Зарегистрировать ячейку (ту же PreviewCell?)
        // collectionView.register(PreviewCell.self, forCellWithReuseIdentifier: "PreviewCell")
        // TODO: Установить dataSource и delegate
        return collectionView
    }()

    private lazy var captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label // Адаптируется к теме
        textView.backgroundColor = .secondarySystemBackground // Адаптируется к теме
        textView.layer.cornerRadius = 5
        textView.text = "Add description..." // Placeholder
        textView.textColor = .placeholderText
        // TODO: Добавить delegate для обработки placeholder
        return textView
    }()
    
    private lazy var shareButton: UIButton = {
       let button = UIButton(type: .system)
       button.translatesAutoresizingMaskIntoConstraints = false
       button.setTitle("Share", for: .normal)
       button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
       button.setTitleColor(.white, for: .normal)
       button.backgroundColor = .systemBlue
       button.layer.cornerRadius = 10
       button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
       return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    // Принимаем массив EditableMediaItem и выбранное соотношение
    init(items: [EditableMediaItem], aspectRatio: PostAspectRatio) {
        // Создаем ViewModel с этими данными
        // TODO: Убедиться, что StorageService и PostService доступны здесь (возможно, через инъекцию)
        self.viewModel = CreatePostViewModel(initialEditableItems: items, postAspectRatio: aspectRatio)
        super.init(nibName: nil, bundle: nil)
    }
    
    // Добавляем хелпер-инициализатор в CreatePostViewModel
    /*
    // В CreatePostViewModel.swift:
    convenience init(initialEditableItems: [EditableMediaItem], postAspectRatio: PostAspectRatio, storageService: StorageServiceProtocol = StorageService(), postService: PostServiceProtocol = PostService()) {
        // Этот init обходит конвертацию из MediaItem
        self.init(initialMedia: [], storageService: storageService, postService: postService) // Вызываем основной init с пустым массивом
        self.editableMedia = initialEditableItems // Устанавливаем переданные items
        self.postAspectRatio = postAspectRatio // Устанавливаем переданный AR
        if !initialEditableItems.isEmpty {
            self.selectedMediaIndex = 0
        } else {
            self.selectedMediaIndex = -1
        }
    }
    */

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
        setupCollectionView()
        setupTextView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "New Post"
        // Кнопка "Назад" будет стандартной, если этот VC пушится в Navigation Stack
        // Если он модальный, нужна кнопка Cancel/Back
        // navigationItem.leftBarButtonItem = ... 
        
        // Стиль NavigationBar
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
        view.addSubview(previewCollectionView)
        view.addSubview(captionTextView)
        view.addSubview(shareButton)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Карусель превью
            previewCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            previewCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Возвращаем фиксированную высоту, равную высоте ячейки
            previewCollectionView.heightAnchor.constraint(equalToConstant: 250), 
            // Убираем привязку низа к верху captionTextView
            // previewCollectionView.bottomAnchor.constraint(equalTo: captionTextView.topAnchor, constant: -15),

            // Поле для подписи
            // Привязываем верх captionTextView к низу collectionView
            captionTextView.topAnchor.constraint(equalTo: previewCollectionView.bottomAnchor, constant: 15),
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            captionTextView.heightAnchor.constraint(equalToConstant: 120),

            // Кнопка Share
            shareButton.topAnchor.constraint(greaterThanOrEqualTo: captionTextView.bottomAnchor, constant: 20),
            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Индикатор активности
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        // Используем ту же ячейку PreviewCell
        previewCollectionView.register(PreviewCell.self, forCellWithReuseIdentifier: PreviewCell.identifier)
        previewCollectionView.dataSource = self
        // Устанавливаем delegate для FlowLayout
        previewCollectionView.delegate = self 
    }
    
    private func setupTextView() {
        captionTextView.delegate = self
    }
    
    private func setupBindings() {
        // Привязываем состояние загрузки к UI
        viewModel.$isSharing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSharing in
                self?.updateSharingState(isSharing)
            }
            .store(in: &cancellables)

        // Привязываем сообщения об ошибках
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.updateSharingState(false) // Убедимся, что UI разблокирован
                self?.showAlert(message: errorMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func shareTapped() {
        print("Share tapped")
        // 1. Получаем текст подписи
        let caption = (captionTextView.text == "Add description...") ? nil : captionTextView.text
        viewModel.caption = caption ?? ""
        
        // 2. Запускаем публикацию через ViewModel
        viewModel.sharePost { [weak self] error in
             DispatchQueue.main.async {
                 guard let self = self else { return }
                 if error == nil {
                     print("✅ PostReviewVC: Пост успешно опубликован!")
                     // TODO: Закрыть весь флоу создания поста (возможно, через делегата/координатора)
                     self.dismissFlow() 
                 } else {
                     // Ошибка уже показана через binding к $errorMessage
                     print("❌ PostReviewVC: Ошибка публикации поста: \(error!.localizedDescription)")
                 }
             }
        }
    }
    
    // MARK: - Helpers
    
    private func updateSharingState(_ isSharing: Bool) {
        shareButton.isEnabled = !isSharing
        captionTextView.isEditable = !isSharing
        // Блокируем/разблокируем кнопку назад?
        // navigationItem.hidesBackButton = isSharing 
        if isSharing {
            activityIndicator.startAnimating()
            shareButton.setTitle("Sharing...", for: .disabled)
        } else {
            activityIndicator.stopAnimating()
            shareButton.setTitle("Share", for: .normal)
        }
    }
    
    private func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func dismissFlow() {
        // TODO: Реализовать корректное закрытие всего флоу
        // Либо через координатора, либо dismiss до root, если все было модально
        presentingViewController?.presentingViewController?.dismiss(animated: true)
        // Или self.navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension PostReviewViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.editableMedia.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewCell.identifier, for: indexPath) as? PreviewCell else {
            fatalError("Unable to dequeue PreviewCell")
        }
        let item = viewModel.editableMedia[indexPath.item]
        // Генерируем финальное превью (может быть затратно, если делать при каждой прокрутке)
        // Альтернатива: генерировать превью заранее и хранить в ViewModel
        let previewImage = viewModel.generateCroppedImage(for: item) // Используем хелпер из VM
        
        // Логируем размер сгенерированного изображения
        if let img = previewImage {
            print("🖼️ Review Cell [\(indexPath.item)]: Generated image size: \(img.size), Orientation: \(img.imageOrientation.rawValue)")
        } else {
            print("🖼️ Review Cell [\(indexPath.item)]: Failed to generate image.")
        }
        
        // Отображаем финальное превью без рамки соотношения
        cell.configure(with: previewImage)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PostReviewViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Увеличиваем высоту превью еще раз
        let previewHeight: CGFloat = 350 // Было 160
        
        // Получаем соотношение сторон поста из ViewModel (Height / Width)
        let aspectRatio = viewModel.postAspectRatio.ratio
        
        // Рассчитываем ширину на основе высоты и соотношения
        // Width = Height / (Height / Width)
        let previewWidth = previewHeight / aspectRatio
        
        // Уменьшаем высоту для ревью экрана
        let finalPreviewHeight: CGFloat = 250 // Новая высота, можно подобрать
        let finalPreviewWidth = finalPreviewHeight / aspectRatio
        
        print("📏 Calculating size for review preview [\(indexPath.item)]: AR=\(aspectRatio), H=\(finalPreviewHeight), W=\(finalPreviewWidth)")
        
        return CGSize(width: finalPreviewWidth, height: finalPreviewHeight)
    }
}

// MARK: - UITextViewDelegate
extension PostReviewViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add description..."
            textView.textColor = .placeholderText
        }
    }
}

// TODO: Добавить реализацию UICollectionViewDelegate для карусели превью (если нужна) 