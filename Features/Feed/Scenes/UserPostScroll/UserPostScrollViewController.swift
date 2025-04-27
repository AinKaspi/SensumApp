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
class UserPostScrollViewController: UIViewController, UICollectionViewDelegateFlowLayout, FullPostCellDelegate {

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
        // Размер ячейки будет задаваться делегатом
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.register(FullPostCell.self, forCellWithReuseIdentifier: FullPostCell.identifier) // Регистрируем FullPostCell
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true // Включаем постраничную прокрутку (одна ячейка за раз)
        collectionView.showsVerticalScrollIndicator = false
        // Добавляем футер для индикатора пагинации
        collectionView.register(PaginationIndicatorFooterView.self, 
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, 
                              withReuseIdentifier: PaginationIndicatorFooterView.identifier)
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
        // Раскомментируем биндинги
        setupBindings() 
        title = "Посты" 
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Прокручиваем к начальному элементу после того, как layout будет готов
        // и только один раз
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
                // TODO: Показать alert
                print("*** UserPostScrollVC Error: \(message) ***")
            }
            .store(in: &cancellables)
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
        // TODO: Передать замыкание для обновления layout?
        cell.configure(with: post, indexPath: indexPath, needsLayoutUpdateAction: nil) 
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
    // Задаем размер ячейки равным размеру видимой области CollectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Используем bounds CollectionView для расчета размера
        // Отнимаем safeAreaInsets, чтобы контент не заезжал под NavigationBar/TabBar
        let safeAreaHeight = collectionView.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        return CGSize(width: collectionView.bounds.width, height: safeAreaHeight)
    }
    
    // Метод для установки размера футера
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        // Показываем футер только если есть еще что грузить
        return viewModel.canLoadMore ? CGSize(width: collectionView.bounds.width, height: 50) : .zero
    }
}

// MARK: - UICollectionViewDelegate
extension UserPostScrollViewController: UICollectionViewDelegate {
    // Метод для пагинации
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Загружаем следующую страницу, когда приближаемся к концу списка
        // Например, за 3 элемента до конца
        if indexPath.item == viewModel.posts.count - 3 {
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
        guard let indexPath = collectionView.indexPath(for: cell),
              let postID = viewModel.posts[safe: indexPath.item]?.id
        else { return }
        delegate?.didTapCommentsButton(forPostID: postID)
    }
    
    func didTapShareButton(in cell: FullPostCell) {
        print("UserPostScrollVC: Share button tapped (TBD)")
        // TODO: Реализовать Share
    }
    
    func didTapViewAllComments(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let postID = viewModel.posts[safe: indexPath.item]?.id
        else { return }
        delegate?.didTapCommentsButton(forPostID: postID)
    }
    
    func fullPostCellDidToggleCaption(_ cell: FullPostCell, at indexPath: IndexPath) {
        // Обновляем layout collectionView, чтобы пересчитать высоту ячейки
        collectionView.collectionViewLayout.invalidateLayout()
        // Можно добавить анимацию
        // UIView.animate(withDuration: 0.2) {
        //     self.collectionView.layoutIfNeeded()
        // }
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
