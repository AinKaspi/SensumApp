import UIKit
import Combine

class FeedViewController: UIViewController {

    // Координатор для навигации
    weak var coordinator: FeedCoordinator?
    // Добавляем ViewModel
    var viewModel: FeedViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements (Placeholders)

    // Верхняя плашка
    private lazy var topBarView: UIView = { // TODO: Сделать кастомный UIView?
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = .darkGray // Для отладки
        
        let logoLabel = UILabel()
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.text = "DOJO" // Или использовать ImageView
        logoLabel.textColor = .white
        logoLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        let messagesButton = UIButton(type: .system)
        messagesButton.translatesAutoresizingMaskIntoConstraints = false
        messagesButton.setImage(UIImage(systemName: "paperplane.circle.fill"), for: .normal) // Пример иконки
        messagesButton.tintColor = .white
        messagesButton.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        // TODO: Добавить индикатор уведомлений
        
        view.addSubview(logoLabel)
        view.addSubview(messagesButton)
        
        NSLayoutConstraint.activate([
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            messagesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            messagesButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messagesButton.widthAnchor.constraint(equalToConstant: 30),
            messagesButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()

    // Горизонтальный скролл для "сторис"
    private lazy var storiesScrollView: UIScrollView = { // TODO: Лучше UICollectionView
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        // scrollView.backgroundColor = .blue // Для отладки
        // TODO: Добавить сюда ячейки "сторис"
        return scrollView
    }()

    // Основная лента
    private lazy var feedTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        // Регистрируем кастомную ячейку
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tableView.dataSource = self 
        tableView.delegate = self 
        // Добавляем Refresh Control
        tableView.refreshControl = refreshControl
        // Добавляем футер для индикатора пагинации
        tableView.tableFooterView = paginationIndicatorFooterView
        return tableView
    }()

    // Добавляем Refresh Control
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        refreshControl.tintColor = .white // Цвет индикатора
        return refreshControl
    }()
    
    // Добавляем индикатор загрузки для пагинации (в футере)
    private lazy var paginationIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Контейнер для индикатора пагинации
    private lazy var paginationIndicatorFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        paginationIndicator.center = footerView.center
        footerView.addSubview(paginationIndicator)
        return footerView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected")
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupBindings()
    }
    
    // Скрываем системный Navigation Bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupViews() {
        view.addSubview(topBarView)
        view.addSubview(storiesScrollView)
        view.addSubview(feedTableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Верхняя плашка
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 50),
            
            // "Сторис"
            storiesScrollView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 8),
            storiesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            storiesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            storiesScrollView.heightAnchor.constraint(equalToConstant: 100), // Примерная высота
            
            // Лента
            feedTableView.topAnchor.constraint(equalTo: storiesScrollView.bottomAnchor, constant: 8),
            feedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            feedTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // До Safe Area, чтобы не залезать под TabBar
        ])
    }

    @objc private func messagesButtonTapped() {
        coordinator?.showMessages()
    }
    
    // Обработчик Pull-to-Refresh
    @objc private func handleRefreshControl() {
        viewModel.refreshFeed()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Подписка на посты ленты
        viewModel.$feedPosts
            .receive(on: DispatchQueue.main)
            // Используем .sink вместо прямого reloadData для возможности анимации
            .sink { [weak self] _ in
                print("FeedVC: Received new feed posts. Reloading table view...")
                self?.feedTableView.reloadData() // Пока простой reload
            }
            .store(in: &cancellables)
        
        // Подписка на окончание обновления (Pull-to-Refresh)
        viewModel.$isLoading
             .receive(on: DispatchQueue.main)
             .filter { !$0 } // Реагируем только на окончание загрузки (isLoading = false)
             .sink { [weak self] _ in
                 self?.refreshControl.endRefreshing()
             }
             .store(in: &cancellables)
            
        // Подписка на состояние загрузки пагинации
        viewModel.$isFetchingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                if isFetching {
                    self?.paginationIndicator.startAnimating()
                    self?.feedTableView.tableFooterView?.isHidden = false
                } else {
                    self?.paginationIndicator.stopAnimating()
                    // Скрываем футер, если больше нечего грузить или если загрузка просто завершилась
                    if !(self?.viewModel.canLoadMore ?? true) {
                         self?.feedTableView.tableFooterView?.isHidden = true
                    }
                }
            }
            .store(in: &cancellables)
            
        // Подписка на флаг canLoadMore
        viewModel.$canLoadMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canLoadMore in
                // Если загрузка не идет и больше нечего грузить, скрываем футер
                if !canLoadMore && !(self?.viewModel.isFetchingMore ?? false) {
                    self?.feedTableView.tableFooterView?.isHidden = true
                }
            }
            .store(in: &cancellables)
            
        // TODO: Добавить биндинги для errorMessage, stories
    }
    
    // TODO: Добавить методы для обработки нажатий на сторис/пользователей в ленте
}

// Обновляем DataSource и Delegate
extension FeedViewController: UITableViewDataSource, UITableViewDelegate, PostCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell else {
            fatalError("Unable to dequeue PostCell")
        }
        let post = viewModel.feedPosts[indexPath.row]
        cell.configure(with: post)
        cell.delegate = self // Устанавливаем себя делегатом ячейки
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Пересчитываем с учетом кнопок и счетчика лайков
        let padding: CGFloat = 8
        let smallPadding: CGFloat = 4
        let avatarHeight: CGFloat = 30
        let actionButtonHeight: CGFloat = 30 // Высота ряда кнопок
        let likesLabelHeight: CGFloat = 18 // Примерная высота счетчика
        let screenWidth = tableView.bounds.width
        let imageHeight = (screenWidth / 9 * 16)
        let captionHeightEstimate: CGFloat = 40
        
        return padding + avatarHeight + padding + imageHeight + padding + actionButtonHeight + smallPadding + likesLabelHeight + smallPadding + captionHeightEstimate + padding
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRowIndex = tableView.numberOfRows(inSection: indexPath.section) - 1
        if indexPath.row == lastRowIndex {
            viewModel.loadMorePostsIfNeeded()
        }
    }
    
    // MARK: - PostCellDelegate
    
    func postCellDidTapAuthor(_ cell: PostCell) {
        guard let indexPath = feedTableView.indexPath(for: cell) else { return }
        let authorID = viewModel.feedPosts[indexPath.row].userID
        print("FeedVC: Author tapped for post at index \(indexPath.row), userID: \(authorID)")
        coordinator?.showUserProfile(userID: authorID)
    }
    
    func postCellDidTapLikeButton(_ cell: PostCell, currentLikeState: Bool) {
        guard let postID = cell.getPostID() else { return }
        print("FeedVC: Like button tapped for postID: \(postID), current state: \(currentLikeState)")
        viewModel.toggleLike(for: postID)
    }
    
    // Реализуем метод для кнопки комментариев
    func postCellDidTapCommentButton(_ cell: PostCell) {
        guard let postID = cell.getPostID() else { return }
        print("FeedVC: Comment button tapped for postID: \(postID)")
        // Вызываем метод координатора для показа комментариев
        coordinator?.showComments(for: postID)
    }
} 