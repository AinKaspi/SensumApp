import UIKit
import Combine

class FeedViewController: UIViewController {

    // Координатор для навигации
    weak var coordinator: FeedCoordinator?
    // Добавляем ViewModel
    var viewModel: FeedViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    // Верхняя плашка
    private lazy var topBarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Логотип DOJO
        let logoImageView = UIImageView() // Используем ImageView
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "dojo_logo") // Предполагаем, что есть ассет "dojo_logo"
        logoImageView.contentMode = .scaleAspectFit
        // TODO: Задать фиксированный размер логотипа?
        
        // Кнопка Уведомлений (колокольчик)
        let notificationsButton = UIButton(type: .system)
        notificationsButton.translatesAutoresizingMaskIntoConstraints = false
        notificationsButton.setImage(UIImage(systemName: "bell"), for: .normal)
        notificationsButton.setPreferredSymbolConfiguration(.init(pointSize: 22, weight: .medium), forImageIn: .normal)
        notificationsButton.tintColor = .white
        notificationsButton.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)
        // TODO: Добавить badge (кружок с цифрой) поверх кнопки
        
        // Кнопка Сообщений (самолетик)
        let messagesButton = UIButton(type: .system)
        messagesButton.translatesAutoresizingMaskIntoConstraints = false
        messagesButton.setImage(UIImage(systemName: "paperplane"), for: .normal) 
        messagesButton.setPreferredSymbolConfiguration(.init(pointSize: 24, weight: .medium), forImageIn: .normal)
        messagesButton.tintColor = .white
        messagesButton.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        
        view.addSubview(logoImageView)
        // Добавляем кнопки справа налево: сначала Сообщения, потом Уведомления
        view.addSubview(messagesButton)
        view.addSubview(notificationsButton)
        
        // Констрейнты внутри topBarView
        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), // <-- Отступ слева
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // Ограничим высоту логотипа
            logoImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5), // Например, 50% высоты topBar
            // Добавим констрейнт ширины, чтобы сохранить пропорции (если известно соотношение) или задать фиксированную ширину
            // Пример: logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: 3.0) // Если соотношение 3:1
            logoImageView.widthAnchor.constraint(equalToConstant: 100), // Или фиксированная ширина
            
            // Кнопка Сообщений прижата к правому краю
            messagesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), // <-- Отступ справа
            messagesButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messagesButton.widthAnchor.constraint(equalToConstant: 30),
            messagesButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Кнопка Уведомлений левее кнопки Сообщений
            notificationsButton.trailingAnchor.constraint(equalTo: messagesButton.leadingAnchor, constant: -15), // Отступ между кнопками
            notificationsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            notificationsButton.widthAnchor.constraint(equalToConstant: 30),
            notificationsButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()

    // Создаем StoriesHeaderView
    private lazy var storiesHeaderView: StoriesHeaderView = {
        // Высота хедера = высота ячейки сторис + верхний/нижний отступ (если нужен)
        let headerHeight: CGFloat = 120 + 10 // 120 высота ячейки + 10 отступ снизу?
        let header = StoriesHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width * 0.86, height: headerHeight))
        // Устанавливаем VC как делегата для CollectionView внутри хедера
        header.setCollectionViewDataSourceDelegate(self, forRow: 0) 
        return header
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
        // Добавляем отступы для тени/эффектов, если нужно, т.к. таблица будет обрезаться
        tableView.clipsToBounds = false 
        // Устанавливаем хедер таблицы
        tableView.tableHeaderView = storiesHeaderView
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
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width * 0.86, height: 50)) // Ширина футера = 86%
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
        view.addSubview(feedTableView)
    }

    private func setupConstraints() {
        let topBarHeight: CGFloat = 100
        let topBarTopPadding: CGFloat = 64 
        
        // Убираем множитель ширины
        // let containerWidthMultiplier: CGFloat = 0.86

        NSLayoutConstraint.activate([
            // Верхняя плашка (100% ширины, привязана к safeArea)
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), // Используем safeAreaLayoutGuide
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: topBarHeight),
            
            // Лента (UITableView) (оставляем 86% ширины, центрирована)
            feedTableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 8),
            feedTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.86), // <-- Оставляем 86%
            feedTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func messagesButtonTapped() {
        coordinator?.showMessages()
    }
    
    // Обработчик Pull-to-Refresh
    @objc private func handleRefreshControl() {
        viewModel.refreshFeed()
    }
    
    // Добавляем action для кнопки уведомлений
    @objc private func notificationsButtonTapped() {
        print("FeedVC: Notifications button tapped")
        // Раскомментируем вызов координатора
        coordinator?.showNotifications()
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
            
        // Добавляем биндинг для viewModel.$storyUsers
        viewModel.$storyUsers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Обновляем CollectionView внутри хедера
                self?.storiesHeaderView.collectionView.reloadData()
            }
            .store(in: &cancellables)
            
        // TODO: Добавить биндинги для errorMessage, stories
    }
    
    // TODO: Добавить методы для обработки нажатий на сторис/пользователей в ленте
}

// Обновляем DataSource и Delegate
extension FeedViewController: UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PostCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell else {
            fatalError("Unable to dequeue PostCell")
        }
        let post = viewModel.feedPosts[indexPath.row]
        cell.configure(with: post)
        cell.delegate = self
        cell.setPostImageCornerRadius(25)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let padding: CGFloat = 8
        let smallPadding: CGFloat = 4
        let avatarHeight: CGFloat = 30
        let actionButtonHeight: CGFloat = 30
        let likesLabelHeight: CGFloat = 18
        let imageWidth = view.bounds.width * 0.86 
        let imageHeight = (imageWidth / 9 * 16)
        let captionHeightEstimate: CGFloat = 40
        
        return padding + avatarHeight + padding + imageHeight + padding + actionButtonHeight + smallPadding + likesLabelHeight + smallPadding + captionHeightEstimate + padding
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRowIndex = tableView.numberOfRows(inSection: indexPath.section) - 1
        if indexPath.row == lastRowIndex {
            viewModel.loadMorePostsIfNeeded()
        }
    }
    
    // MARK: - UICollectionViewDataSource & Delegate (для Stories)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Возвращаем реальное количество пользователей
        return viewModel.storyUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoryCell.identifier, for: indexPath) as? StoryCell else {
            fatalError("Unable to dequeue StoryCell")
        }
        // Получаем данные пользователя из viewModel
        let user = viewModel.storyUsers[indexPath.item]
        // TODO: Определить hasNewContent
        cell.configure(username: user.username, avatarURL: user.avatarURL, hasNewContent: false) // Placeholder для hasNewContent
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Story cell tapped at index: \(indexPath.item)")
        // Получаем userID из viewModel и вызываем навигацию
        let userID = viewModel.storyUsers[indexPath.item].id
        guard let validUserID = userID else {
             print("FeedVC Error: User ID is nil for story at index \(indexPath.item)")
             return
        }
        coordinator?.showUserProfile(userID: validUserID)
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
    
    // Реализуем метод делегата для обновления ячейки
    func postCellDidToggleCaption(_ cell: PostCell) {
        // Обновляем layout таблицы, чтобы она пересчитала высоту ячейки
        // Используем performBatchUpdates для плавной анимации
        feedTableView.performBatchUpdates(nil, completion: nil)
        // Альтернатива (без анимации):
        // feedTableView.beginUpdates()
        // feedTableView.endUpdates()
    }
}
