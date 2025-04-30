import UIKit

// Определяем протокол делегата
protocol PostMediaSelectionDelegate: AnyObject {
    func postMediaSelectionDidTapNext(items: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidTapItem(at index: Int, currentItems: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidCancel()
}

/// Экран для выбора единого соотношения сторон поста и предпросмотра/выбора медиа для кропа.
class PostMediaSelectionViewController: UIViewController {

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
        // Размер делаем адаптирующимся к высоте экрана
        let availableHeight = view.bounds.height * 0.6 // 60% высоты view
        layout.itemSize = CGSize(width: view.bounds.width * 0.8, height: availableHeight) 
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
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
            previewCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Используем те же 60% высоты, что и при расчете itemSize
            previewCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),

            aspectRatioSegmentedControl.topAnchor.constraint(equalTo: previewCollectionView.bottomAnchor, constant: 20),
            aspectRatioSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            aspectRatioSegmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            aspectRatioSegmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupCollectionView() {
        previewCollectionView.register(PreviewCell.self, forCellWithReuseIdentifier: PreviewCell.identifier)
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
        selectedAspectRatio = PostAspectRatio.allCases[sender.selectedSegmentIndex]
        print("Aspect Ratio Changed: \(selectedAspectRatio.stringValue)")
        previewCollectionView.reloadData() // Перезагружаем для обновления рамок
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
        let item = editableMedia[indexPath.item]
        cell.configure(with: item.originalImage, targetAspectRatio: selectedAspectRatio.ratio)
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

// TODO: Добавить реализацию UICollectionViewDelegateFlowLayout если нужен кастомный размер/отступы
// extension PostMediaSelectionViewController: UICollectionViewDelegateFlowLayout {}
