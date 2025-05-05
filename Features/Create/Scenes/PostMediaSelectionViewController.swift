import UIKit

// Определяем протокол делегата
protocol PostMediaSelectionDelegate: AnyObject {
    func postMediaSelectionDidTapNext(items: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidTapItem(at index: Int, currentItems: [EditableMediaItem], aspectRatio: PostAspectRatio)
    func postMediaSelectionDidCancel()
    // Добавляем метод для уведомления о завершении кропа (чтобы координатор закрыл экран)
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
    // ❗️ Формат по умолчанию - портретный
    private var selectedAspectRatio: PostAspectRatio = .portrait
    // ❗️ Переносим объявление сюда
    private var previewCollectionViewHeightConstraint: NSLayoutConstraint?
    // ❗️ Добавляем переменную для верхнего констрейнта
    private var previewCollectionViewTopConstraint: NSLayoutConstraint?
    
    // MARK: - UI Elements

    // Переносим определение previewCollectionView внутрь класса
    private lazy var previewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        // Возвращаем небольшой отступ между ячейками
        layout.minimumLineSpacing = 10
        // Добавляем боковые отступы секции для эффекта "подглядывания"
        let sideInset: CGFloat = 40
        layout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = false // Отключаем пейджинг
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
        // Позволяем видеть контент за границами
        collectionView.clipsToBounds = false 
        collectionView.register(PreviewCell.self, forCellWithReuseIdentifier: PreviewCell.identifier)
        return collectionView
    }()

    // +++ Добавляем новые элементы +++
    private lazy var ratioButtonsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Можно добавить стили для контейнера, если нужно (например, скругление)
        // view.layer.cornerRadius = 8
        // view.clipsToBounds = true
        return view
    }()
    
    private lazy var portraitRatioButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(PostAspectRatio.portrait.stringValue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8 // Скруглим углы
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner] // Только левые
        button.addTarget(self, action: #selector(portraitRatioTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var squareRatioButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(PostAspectRatio.square.stringValue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8 // Скруглим углы
        button.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] // Только правые
        button.addTarget(self, action: #selector(squareRatioTapped), for: .touchUpInside)
        return button
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
        updateRatioButtonStyles() 
        // ❗️ Вызываем layoutIfNeeded после setupConstraints, чтобы ширина view была известна для расчета начальной высоты
        view.layoutIfNeeded()
        // ❗️ Устанавливаем начальную высоту коллекции
        updateCollectionViewHeight(animated: false)
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
        // ❗️ Добавляем контейнер и кнопки
        view.addSubview(ratioButtonsContainer)
        ratioButtonsContainer.addSubview(portraitRatioButton)
        ratioButtonsContainer.addSubview(squareRatioButton)
    }

    private func setupConstraints() {
        // Рассчитываем начальную высоту (до активации констрейнтов)
        // Используем ширину view, но она может быть неточной до первого layout pass
        let initialHeight = calculateCollectionViewHeight(for: view.bounds.width)
        
        // Создаем констрейнт высоты и сохраняем его
        let heightConstraint = previewCollectionView.heightAnchor.constraint(equalToConstant: initialHeight)
        // ❗️ Присваиваем значение свойству класса
        self.previewCollectionViewHeightConstraint = heightConstraint
         
        // ❗️ Создаем верхний констрейнт и сохраняем его
        let topConstraint = previewCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20) // Начальный отступ 20
        self.previewCollectionViewTopConstraint = topConstraint
        
        // Констрейнты для UI элементов
        NSLayoutConstraint.activate([
            // ❗️ Активируем созданный верхний констрейнт
            topConstraint,
            previewCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // ❗️ Активируем созданный констрейнт высоты
            heightConstraint,

            // Констрейнты для контейнера кнопок
            // Привязываем верх кнопок к низу коллекции
            ratioButtonsContainer.topAnchor.constraint(equalTo: previewCollectionView.bottomAnchor, constant: 20),
            // ❗️ Увеличиваем боковые отступы до 50
            ratioButtonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 42),
            ratioButtonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -42),
            ratioButtonsContainer.heightAnchor.constraint(equalToConstant: 44), // Задаем высоту контейнера
            
            // ❗️ Констрейнты для кнопок внутри контейнера
            portraitRatioButton.topAnchor.constraint(equalTo: ratioButtonsContainer.topAnchor),
            portraitRatioButton.bottomAnchor.constraint(equalTo: ratioButtonsContainer.bottomAnchor),
            portraitRatioButton.leadingAnchor.constraint(equalTo: ratioButtonsContainer.leadingAnchor),
            portraitRatioButton.trailingAnchor.constraint(equalTo: ratioButtonsContainer.centerXAnchor), // Левая кнопка до центра
            
            squareRatioButton.topAnchor.constraint(equalTo: ratioButtonsContainer.topAnchor),
            squareRatioButton.bottomAnchor.constraint(equalTo: ratioButtonsContainer.bottomAnchor),
            squareRatioButton.leadingAnchor.constraint(equalTo: ratioButtonsContainer.centerXAnchor), // Правая кнопка от центра
            squareRatioButton.trailingAnchor.constraint(equalTo: ratioButtonsContainer.trailingAnchor)
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
    
    // +++ Добавляем новые обработчики и стилизацию +++
    @objc private func portraitRatioTapped() {
        guard selectedAspectRatio != .portrait else { return } // Не меняем, если уже выбрано
        selectedAspectRatio = .portrait
        print("Selected aspect ratio: Portrait")
        updateRatioButtonStyles()
        reloadCollectionViewLayout()
    }
    
    @objc private func squareRatioTapped() {
        guard selectedAspectRatio != .square else { return } // Не меняем, если уже выбрано
        selectedAspectRatio = .square
        print("Selected aspect ratio: Square")
        updateRatioButtonStyles()
        reloadCollectionViewLayout()
    }
    
    private func updateRatioButtonStyles() {
        let portraitIsActive = selectedAspectRatio == .portrait
        
        portraitRatioButton.backgroundColor = portraitIsActive ? .white : .black
        portraitRatioButton.setTitleColor(portraitIsActive ? .black : .white, for: .normal)
        // Можно добавить обводку для неактивной кнопки для лучшего контраста
        portraitRatioButton.layer.borderWidth = portraitIsActive ? 0 : 1
        portraitRatioButton.layer.borderColor = UIColor.darkGray.cgColor
        
        squareRatioButton.backgroundColor = !portraitIsActive ? .white : .black
        squareRatioButton.setTitleColor(!portraitIsActive ? .black : .white, for: .normal)
        squareRatioButton.layer.borderWidth = !portraitIsActive ? 0 : 1
        squareRatioButton.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    // Вспомогательный метод для перезагрузки layout'а
    private func reloadCollectionViewLayout() {
        // Обновляем высоту коллекции с анимацией
        updateCollectionViewHeight(animated: true)
         
        // ❗️ Оборачиваем reloadData в анимацию перехода
        UIView.transition(with: self.previewCollectionView, 
                          duration: 0.2, // Короткая длительность для cross-fade
                          options: .transitionCrossDissolve,
                          animations: { self.previewCollectionView.reloadData() },
                          completion: nil)
         
        // invalidateLayout не нужен при простой перезагрузке данных, если размер ячеек не меняется
         
        // Можно добавить плавный скролл к текущей ячейке после перезагрузки
        // if currentSelectedIndex >= 0 && currentSelectedIndex < editableMedia.count {
        //    let indexPath = IndexPath(item: currentSelectedIndex, section: 0)
        //    previewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        // }
    }
    
    // +++ Новый метод для расчета и обновления высоты +++
    private func calculateCollectionViewHeight(for width: CGFloat) -> CGFloat {
        // Используем ту же логику расчета, что и в sizeForItemAt, но для актуальной ширины КОЛЛЕКЦИИ
        guard previewCollectionView.bounds.width > 0 else { 
            print("⚠️ Warning: Trying to calculate height before collection view has width. Returning estimated height.")
            // Возвращаем примерное значение, если ширина еще 0
            return UIScreen.main.bounds.width / selectedAspectRatio.ratio 
        }
        let actualWidth = previewCollectionView.bounds.width
        let sideInset = (previewCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.left ?? 0
        let cellWidth = actualWidth - (sideInset * 2)
        let ratio = selectedAspectRatio.ratio
        let cellHeight = cellWidth / ratio
        print("Calculating CollectionView Height: actualWidth=\(actualWidth), ratio=\(ratio), height=\(cellHeight)")
        return cellHeight
    }
    
    private func updateCollectionViewHeight(animated: Bool) {
        let newHeight = calculateCollectionViewHeight(for: previewCollectionView.bounds.width)
        
        // ❗️ Добавляем вычисление нового верхнего отступа
        let newTopConstant: CGFloat = (selectedAspectRatio == .square) ? 120 : 20 // ❗️ Отступ 120 для 1:1, 20 для 9:16
        
        // Обновляем, если высота ИЛИ отступ изменились
        guard previewCollectionViewHeightConstraint?.constant != newHeight || previewCollectionViewTopConstraint?.constant != newTopConstant else { 
            print("CollectionView Height & Top already set to \(newHeight) & \(newTopConstant)")
            return 
        }
        
        print("Updating CollectionView Geometry: Height=\(newHeight), Top=\(newTopConstant)")
        previewCollectionViewHeightConstraint?.constant = newHeight
        // ❗️ Обновляем верхний отступ
        previewCollectionViewTopConstraint?.constant = newTopConstant
        
        if animated {
            UIView.animate(withDuration: 0.3) { // Длительность анимации можно настроить
                self.view.layoutIfNeeded() // Применяем изменение констрейнта с анимацией
            }
        } else {
            self.view.layoutIfNeeded() // Применяем немедленно
        }
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
             print(" Reloaded cell at index \(index) after update.")
        } else {
             print(" Updated item at index \(index) in data source (cell not visible).")
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
        // Приоритет отдаем finalImage (результат кропа), если он есть
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
        
        // Получаем боковой отступ из layout'а
        let sideInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.left ?? 0
        
        // Рассчитываем ширину ячейки: ширина collectionView МИНУС двойной боковой отступ
        let cellWidth = collectionView.bounds.width - (sideInset * 2)

        // Рассчитываем высоту ячейки ДИНАМИЧЕСКИ на основе выбранного соотношения сторон
        let ratio = selectedAspectRatio.ratio
        let cellHeight = cellWidth / ratio // Высота = Ширина / Соотношение (Ширина/Высота)
        
        // DEBUG: Логируем размер ячейки
        print(" sizeForItemAt: AspectRatio=\(selectedAspectRatio.stringValue), Ratio=\(ratio), CellWidth=\(cellWidth), sideInset=\(sideInset), Returning size \(cellWidth)x\(cellHeight)")
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - CropDelegate Implementation
extension PostMediaSelectionViewController {
    func cropViewControllerDidFinishCropping(item: EditableMediaItem) {
        // 1. Находим индекс обновленного элемента в нашем массиве
        guard let index = editableMedia.firstIndex(where: { $0.id == item.id }) else {
            print(" CropDelegate Error: Could not find item with id \(item.id) to update.")
            return
        }
        
        // 2. Обновляем элемент в массиве
        editableMedia[index] = item
        
        // 3. Перезагружаем ТОЛЬКО измененную ячейку
        let indexPath = IndexPath(item: index, section: 0)
        previewCollectionView.reloadItems(at: [indexPath])
        
        print(" Updated item at index \(index) and reloaded cell.")
        
        // Уведомляем делегата о завершении кропа
        delegate?.postMediaSelectionDidFinishCropping()
    }
}
