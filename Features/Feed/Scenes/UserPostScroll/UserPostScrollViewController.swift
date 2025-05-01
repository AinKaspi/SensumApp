import UIKit
import Combine

// Делегат для обработки действий внутри ленты постов
protocol UserPostScrollViewControllerDelegate: AnyObject {
    func didTapUsername(userID: String)
    func didTapCommentsButton(forPostID postID: String)
    // Можно добавить другие действия, если нужно
}

// Меняем базовый класс и протоколы
// Убираем избыточное объявление UICollectionViewDataSource здесь еще раз
// Добавляем UICollectionViewDataSourcePrefetching
class UserPostScrollViewController: UIViewController, UICollectionViewDelegateFlowLayout, FullPostCellDelegate, UICollectionViewDataSourcePrefetching {

    // MARK: - Dependencies
    var viewModel: UserPostScrollViewModel! // Раскомментируем
    weak var delegate: UserPostScrollViewControllerDelegate?

    // MARK: - Properties
    // private var posts: [Post] // Теперь данные приходят из ViewModel
    private let startIndex: Int
    private var cancellables = Set<AnyCancellable>()
    private var hasScrolledToInitial = false

    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        // Создаем layout: одна ячейка на всю ширину экрана
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0 // Убираем промежутки между ячейками
        layout.minimumInteritemSpacing = 0
        // Размер ячейки будет задаваться делегатом --> УДАЛЯЕМ
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.register(FullPostCell.self, forCellWithReuseIdentifier: FullPostCell.identifier) // Регистрируем FullPostCell
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false // Отключаем постраничную прокрутку
        collectionView.showsVerticalScrollIndicator = false
        // Добавляем футер для индикатора пагинации
        collectionView.register(PaginationIndicatorFooterView.self, 
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, 
                              withReuseIdentifier: PaginationIndicatorFooterView.identifier)
        // Устанавливаем prefetchDataSource
        collectionView.prefetchDataSource = self
        return collectionView
    }()
    
    // Индикатор для начальной загрузки (если нужен)
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization
    // Обновляем init, принимаем ViewModel
    init(viewModel: UserPostScrollViewModel, startIndex: Int) {
        // self.posts = posts // Удаляем
        self.viewModel = viewModel
        self.startIndex = startIndex
        super.init(nibName: nil, bundle: nil)
        print("UserPostScrollVC: Init with startIndex: \(startIndex)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected")
        view.backgroundColor = .black
        setupUI()
        setupConstraints()
        
        // УДАЛЯЕМ настройку automatic size
        
        // Раскомментируем биндинги
        setupBindings() 
        title = "Посты" 
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Прокручиваем к начальному элементу после того, как layout будет готов
        // и только один раз
        
        // --- ОТЛАДКА РАЗМЕРОВ --- 
        print("UserPostScrollVC [viewDidLayoutSubviews]:")
        print("  view.bounds: \(view.bounds)")
        print("  collectionView.frame: \(collectionView.frame)")
        print("  collectionView.bounds: \(collectionView.bounds)")
        print("  collectionView.safeAreaInsets: \(collectionView.safeAreaInsets)")
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            print("  layout.itemSize: \(layout.itemSize)")
            print("  layout.estimatedItemSize: \(layout.estimatedItemSize)")
        }
        // -------------------------
        
        if !hasScrolledToInitial {
            scrollToInitialPost()
            hasScrolledToInitial = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    private func setupUI() {
        // Добавляем collectionView
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // CollectionView на весь экран (под Navigation Bar)
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Привязываем низ к safe area, чтобы не заезжать под TabBar (если он есть)
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Индикатор по центру
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func scrollToInitialPost() {
        // Используем viewModel.posts
        guard startIndex >= 0 && startIndex < viewModel.posts.count else {
            print("UserPostScrollVC Error: Invalid startIndex \(startIndex) for posts count \(viewModel.posts.count)")
            return
        }
        // Прокручиваем UICollectionView
        let indexPath = IndexPath(item: self.startIndex, section: 0)
        // Используем animated: false для мгновенного перехода
        // Используем .centeredVertically, чтобы пост был по центру
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        print("UserPostScrollVC: Scrolled to initial post at index \(self.startIndex)")
    }

    // MARK: - Bindings
    private func setupBindings() {
        // Подписка на посты
        viewModel.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
                // Перепрокручиваем, если нужно и еще не сделали этого
                 if !(self?.hasScrolledToInitial ?? true) {
                     self?.scrollToInitialPost()
                     self?.hasScrolledToInitial = true
                 }
            }
            .store(in: &cancellables)
            
        // Подписка на состояние загрузки (первой)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
            
        // Подписка на состояние пагинации
        viewModel.$isFetchingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                // Обновляем футер (он сам себя покажет/скроет)
                self?.collectionView.collectionViewLayout.invalidateLayout() // Чтобы футер обновился
            }
            .store(in: &cancellables)
            
        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                print("*** UserPostScrollVC Error: \(message) ***") // Оставляем лог для отладки
                self?.showErrorAlert(message: message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Error Handling
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error", 
            message: message, 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

// MARK: - UICollectionViewDataSource
extension UserPostScrollViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.posts.count // Используем ViewModel
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullPostCell.identifier, for: indexPath) as? FullPostCell else {
            fatalError("Unable to dequeue FullPostCell")
        }
        let post = viewModel.posts[indexPath.item]
        // TODO: Передать замыкание для обновления layout? --> КОММЕНТАРИЙ УСТАРЕЛ
        cell.configure(with: post, indexPath: indexPath)
        cell.delegate = self // Устанавливаем делегата
        return cell
    }
    
    // Метод для отображения футера пагинации
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PaginationIndicatorFooterView.identifier, for: indexPath) as? PaginationIndicatorFooterView else {
                fatalError("Cannot dequeue PaginationIndicatorFooterView")
            }
            // Управляем анимацией индикатора в футере
            if viewModel.isFetchingMore {
                footer.startAnimating()
            } else {
                footer.stopAnimating()
            }
            return footer
        } else {
            // Для других типов supplementary views (например, header)
            fatalError("Unexpected supplementary view kind: \(kind)")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension UserPostScrollViewController {
    // ВОССТАНАВЛИВАЕМ ручной расчет высоты
    
    // Создаем временную ячейку для расчета высоты
    // Лучше использовать одну и ту же временную ячейку для производительности
    private static let sizingCell = FullPostCell(frame: .zero)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 1. Получаем ширину collection view
        let targetWidth = collectionView.bounds.width
        
        // 2. Получаем данные для поста
        guard let post = viewModel.posts[safe: indexPath.item] else {
            // Возвращаем дефолтный размер или нулевой, если поста нет
            print("UserPostScrollVC [sizeForItemAt] Warning: No post data for indexPath \(indexPath)")
            return CGSize(width: targetWidth, height: 300) // Примерная минимальная высота
        }
        
        // 3. Используем статическую временную ячейку
        let cell = UserPostScrollViewController.sizingCell
  
        // 4. Устанавливаем ширину ячейки, конфигурируем ее
        cell.bounds.size.width = targetWidth
        cell.configure(with: post, indexPath: indexPath)
        cell.layoutIfNeeded() // ВАЖНО: Рассчитать layout ДО измерения subviews
  
        // 5. Рассчитываем итоговый размер всей contentView ячейки
        let calculatedSize = cell.contentView.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, 
            verticalFittingPriority: .fittingSizeLevel 
        )
  
        print("UserPostScrollVC [sizeForItemAt \(indexPath.item)]: Final Calculated size = \(calculatedSize)")
  
        // 6. Возвращаем рассчитанный размер
        return CGSize(width: targetWidth, height: max(1, calculatedSize.height))
    }
    
    // Метод для установки размера футера
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        // Показываем футер только если есть еще что грузить
        return viewModel.canLoadMore ? CGSize(width: collectionView.bounds.width, height: 50) : .zero
    }
}

// MARK: - UICollectionViewDelegate
extension UserPostScrollViewController: UICollectionViewDelegate {
    // УДАЛЯЕМ старую логику пагинации из willDisplay
    /*
    // Метод для пагинации
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Загружаем следующую страницу, когда приближаемся к концу списка
        // Например, за 3 элемента до конца
        if indexPath.item == viewModel.posts.count - 3 {
            viewModel.fetchMorePosts()
        }
    }
    */
}

// MARK: - UICollectionViewDataSourcePrefetching
extension UserPostScrollViewController {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard !viewModel.isFetchingMore, viewModel.canLoadMore else { return }
        
        // Проверяем, содержит ли массив indexPaths индекс, близкий к концу текущих данных
        // Например, если последний загруженный элемент - 20, а prefetchThreshold = 5,
        // то при запросе предзагрузки для индекса 16 (20 - 1 - 3) или больше, запускаем загрузку.
        let lastLoadedItemIndex = viewModel.posts.count - 1
        let prefetchThreshold = 5 // Начинаем загрузку за 5 элементов до конца
        
        let needsPrefetch = indexPaths.contains { $0.item >= lastLoadedItemIndex - prefetchThreshold }
        
        if needsPrefetch {
            print("UserPostScrollVC: Prefetching next page triggered at index \(indexPaths.first?.item ?? -1)")
            viewModel.fetchMorePosts()
        }
    }
}

// MARK: - FullPostCellDelegate
extension UserPostScrollViewController {
    func didTapUsername(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let authorID = viewModel.posts[indexPath.item].userID
        delegate?.didTapUsername(userID: authorID)
    }
    
    func didTapFollowButton(in cell: FullPostCell) {
        // Логика подписки должна быть в ViewModel Профиля, а не здесь
        print("UserPostScrollVC: Follow button tapped (delegate TBD)")
    }
    
    func didTapLikeButton(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let postID = viewModel.posts[safe: indexPath.item]?.id // Безопасное извлечение ID
        else { return }
        viewModel.toggleLike(for: postID)
    }
    
    func didTapCommentButton(in cell: FullPostCell) {
        print("--- UserPostScrollVC: didTapCommentButton(in cell:). Calling delegate... ---") // DEBUG
        guard let indexPath = collectionView.indexPath(for: cell),
              let postID = viewModel.posts[safe: indexPath.item]?.id // Безопасное извлечение ID
        else {
            print("--- UserPostScrollVC Error: Failed to get indexPath or postID for comment button tap. IndexPath: \(String(describing: collectionView.indexPath(for: cell))), PostID: \(String(describing: viewModel.posts[safe: collectionView.indexPath(for: cell)?.item ?? -1]?.id)) ---")
            return
        }

        // Дополнительная проверка делегата
        guard delegate != nil else {
            print("--- UserPostScrollVC Error: delegate is nil! Cannot call didTapCommentsButton. ---")
            return
        }

        delegate?.didTapCommentsButton(forPostID: postID)
    }
    
    func didTapShareButton(in cell: FullPostCell) {
        print("UserPostScrollVC: Share button tapped (TBD)")
        // TODO: Реализовать Share
    }
    
    // Добавляем реализацию нового метода делегата
    func fullPostCellDidRequestLayoutUpdate(at indexPath: IndexPath) {
        print("UserPostScrollVC: Layout update requested for cell at \(indexPath)")
        // Выполняем batch updates, чтобы анимировать изменение высоты ячейки
        // Передаем nil в updates, так как изменения (numberOfLines) уже произошли в ячейке,
        // а collectionView просто нужно пересчитать layout.
        collectionView.performBatchUpdates(nil, completion: nil)
    }
}

// MARK: - Pagination Footer View
// (Можно вынести в отдельный файл Views)
class PaginationIndicatorFooterView: UICollectionReusableView {
    static let identifier = "PaginationIndicatorFooterView"

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
    }
}

// MARK: - Helper Methods
extension UserPostScrollViewController {
    private func aspectRatioMultiplier(from string: String) -> CGFloat {
        switch string {
            case "9:16": return 16.0 / 9.0
            case "16:9": return 9.0 / 16.0
            default: return 1.0 // Default case, assuming 1:1 aspect ratio
        }
    }
}
