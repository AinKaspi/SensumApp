import UIKit

// Определяем протокол делегата
protocol PostMediaSelectionDelegate: AnyObject {
    func postMediaSelectionDidTapNext(items: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidTapItem(at index: Int, currentItems: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidCancel()
    // ✅ Добавляем метод для уведомления о завершении кропа (чтобы координатор закрыл экран)
    func postMediaSelectionDidFinishCropping()
}

/// Экран для выбора единого соотношения сторон поста и предпросмотра/выбора медиа для кропа.
class PostMediaSelectionViewController: UIViewController, UIScrollViewDelegate, CropDelegate {

    // Добавляем ViewModel (пока опционально)
    // private var viewModel: PostMediaSelectionViewModel?
    weak var delegate: PostMediaSelectionDelegate?

    // Храним EditableMediaItem
    /* private */ var editableMedia: [EditableMediaItem]
    private var currentSelectedIndex: Int = 0
    private var selectedAspectRatio: PostAspectRatio = .square
    
    // MARK: - UI Elements

    // Переносим определение previewCollectionView внутрь класса
    private lazy var previewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        // ✅ Добавляем небольшой отступ между ячейками
        layout.minimumLineSpacing = 10 // Подберите значение
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true // Оставим пейджинг, но с отступом
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black // Возвращаем черный фон
        collectionView.register(PreviewCell.self, forCellWithReuseIdentifier: PreviewCell.identifier)
        return collectionView
    }()

    // Переносим определение aspectRatioSegmentedControl внутрь класса
    private lazy var aspectRatioSegmentedControl: UISegmentedControl = {
        let items = PostAspectRatio.allCases.map { $0.stringValue }
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        let defaultIndex = PostAspectRatio.allCases.firstIndex(of: .square) ?? 0
        control.selectedSegmentIndex = defaultIndex
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(aspectRatioChanged(_:)), for: .valueChanged)
        return control
    }()

    // MARK: - Initialization

    init(media: [MediaItem]) {
        // Конвертируем MediaItem в EditableMediaItem при инициализации
        self.editableMedia = media.map { item -> EditableMediaItem in
            switch item {
            case .image(let img):
                return EditableMediaItem(originalImage: img)
            // TODO: Обработать другие типы, если они появятся
            }
        }
        // Устанавливаем начальный индекс, если медиа есть
        self.currentSelectedIndex = editableMedia.isEmpty ? -1 : 0
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
        setupCollectionView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Select Format"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextTapped))
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
        // Добавляем UI элементы на view
        view.addSubview(previewCollectionView)
        view.addSubview(aspectRatioSegmentedControl)
    }

    private func setupConstraints() {
        // Констрейнты для UI элементов
        NSLayoutConstraint.activate([
            previewCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            // ✅ Добавляем боковые отступы
            previewCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            previewCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            // ✅ Уменьшаем высоту CollectionView (подберите значение, начнем с 0.5)
            previewCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            // ✅ Восстанавливаем привязку верха SegmentedControl к низу CollectionView
            aspectRatioSegmentedControl.topAnchor.constraint(equalTo: previewCollectionView.bottomAnchor, constant: 20),
            aspectRatioSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            aspectRatioSegmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            aspectRatioSegmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupCollectionView() {
        previewCollectionView.dataSource = self
        previewCollectionView.delegate = self
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.postMediaSelectionDidCancel()
    }

    @objc private func nextTapped() {
        print("Next tapped. Selected Aspect Ratio: \(selectedAspectRatio.stringValue)")
        delegate?.postMediaSelectionDidTapNext(items: editableMedia, aspectRatio: selectedAspectRatio)
    }
    
    @objc private func aspectRatioChanged(_ sender: UISegmentedControl) {
        let newIndex = sender.selectedSegmentIndex
        guard newIndex >= 0 && newIndex < PostAspectRatio.allCases.count else { return }
        let newAspectRatio = PostAspectRatio.allCases[newIndex]
        
        // Сохраняем выбранное значение
        selectedAspectRatio = newAspectRatio
        
        // 🐞 DEBUG: Логируем изменение
        print("🕹️ Aspect Ratio Selection Changed: Index=\(newIndex), New AR=\(newAspectRatio.stringValue) (\(newAspectRatio.ratio))")
        
        // ✅ Перезагружаем данные, чтобы ячейки обновились с новым aspectRatio
        previewCollectionView.reloadData()
    }
    
    // MARK: - Public Methods
    
    // Метод для обновления editableMedia извне (после кропа)
    func updateEditableItem(at index: Int, with newItem: EditableMediaItem) {
        guard index >= 0 && index < editableMedia.count else { return }
        editableMedia[index] = newItem
        // Обновляем только нужную ячейку для эффективности
        let indexPath = IndexPath(item: index, section: 0)
        if previewCollectionView.indexPathsForVisibleItems.contains(indexPath) {
             previewCollectionView.reloadItems(at: [indexPath])
             print("🔄 Reloaded cell at index \(index) after update.")
        } else {
             print("🔄 Updated item at index \(index) in data source (cell not visible).")
        }
    }
}

// MARK: - UICollectionViewDataSource
extension PostMediaSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editableMedia.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewCell.identifier, for: indexPath) as? PreviewCell else {
            fatalError("Unable to dequeue PreviewCell")
        }
        
        let mediaItem = editableMedia[indexPath.item]
        // ✅ Приоритет отдаем finalImage (результат кропа), если он есть
        let imageToDisplay = mediaItem.finalImage ?? mediaItem.originalImage
        
        cell.configure(with: imageToDisplay, aspectRatio: selectedAspectRatio)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension PostMediaSelectionViewController: UICollectionViewDelegate {
    // Обработка тапа на ячейку
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedIndex = indexPath.item
        print("Tapped item at index: \(selectedIndex)")
        delegate?.postMediaSelectionDidTapItem(at: selectedIndex, currentItems: editableMedia, aspectRatio: selectedAspectRatio)
    }
    
    // Обновляем currentSelectedIndex при скролле (для пейджинга)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let indexPath = previewCollectionView.indexPathForItem(at: visiblePoint) {
            currentSelectedIndex = indexPath.item
            print("Current selected index (scroll): \(currentSelectedIndex)")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PostMediaSelectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // ✅ Размер ЯЧЕЙКИ остается НЕИЗМЕННЫМ (альбомным)
        // Визуальное изменение формата происходит ВНУТРИ ячейки за счет containerView
        let cellHeight = collectionView.bounds.height 
        let cellWidth = collectionView.bounds.width * 0.9 
        
        // 🐞 DEBUG: Логируем размер ячейки
        print("🐞 sizeForItemAt: Returning size \(cellWidth)x\(cellHeight)")
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - CropDelegate Implementation
extension PostMediaSelectionViewController {
    func cropViewControllerDidFinishCropping(item: EditableMediaItem) {
        // 1. Находим индекс обновленного элемента в нашем массиве
        guard let index = editableMedia.firstIndex(where: { $0.id == item.id }) else {
            print("⚠️ CropDelegate Error: Could not find item with id \(item.id) to update.")
            return
        }
        
        // 2. Обновляем элемент в массиве
        editableMedia[index] = item
        
        // 3. Перезагружаем ТОЛЬКО измененную ячейку
        let indexPath = IndexPath(item: index, section: 0)
        previewCollectionView.reloadItems(at: [indexPath])
        
        print("✅ CropDelegate: Updated item at index \(index) and reloaded cell.")
        
        // ✅ Уведомляем делегата о завершении кропа
        delegate?.postMediaSelectionDidFinishCropping()
    }
}
