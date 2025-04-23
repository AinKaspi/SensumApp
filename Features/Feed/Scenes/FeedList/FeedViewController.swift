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
        return tableView
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
    
    // MARK: - Bindings
    private func setupBindings() {
        // Подписка на посты ленты
        viewModel.$feedPosts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("FeedVC: Received new feed posts. Reloading table view...")
                self?.feedTableView.reloadData()
            }
            .store(in: &cancellables)
            
        // TODO: Добавить биндинги для isLoading, errorMessage, stories
    }
    
    // TODO: Добавить методы для обработки нажатий на сторис/пользователей в ленте
}

// Обновляем DataSource
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell else {
            fatalError("Unable to dequeue PostCell")
        }
        let post = viewModel.feedPosts[indexPath.row]
        
        // Передаем только пост, автор уже внутри
        cell.configure(with: post)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Рассчитываем высоту: (высота картинки 9:16) + (верхний отступ + аватар + отступ) + (отступ + caption + нижний отступ) + (отступы для кнопок действий)
        let padding: CGFloat = 8
        let avatarHeight: CGFloat = 30
        let screenWidth = tableView.bounds.width
        let imageHeight = (screenWidth / 9 * 16)
        // TODO: Рассчитать высоту caption более точно?
        let captionHeightEstimate: CGFloat = 40 // Примерная высота для 2 строк
        let actionButtonsHeight: CGFloat = 40 // Примерная высота для кнопок Like/Comment
        
        return padding + avatarHeight + padding + imageHeight + padding + captionHeightEstimate + padding + actionButtonsHeight + padding
    }
    
    // TODO: Добавить обработку нажатий на аватар/имя в ячейке
} 