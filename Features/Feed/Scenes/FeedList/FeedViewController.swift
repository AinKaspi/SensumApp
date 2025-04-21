import UIKit

class FeedViewController: UIViewController {

    // Координатор для навигации
    weak var coordinator: FeedCoordinator?
    // TODO: Добавить ViewModel

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
    private lazy var feedTableView: UITableView = { // TODO: Или UICollectionView?
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostCell") // Заменить на PostCell
        tableView.dataSource = self // Временно
        tableView.delegate = self // Временно
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
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
    
    // TODO: Добавить методы для обработки нажатий на сторис/пользователей в ленте
}

// Временные DataSource/Delegate
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 // Placeholder
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
        cell.backgroundColor = indexPath.row % 2 == 0 ? .darkGray : .black
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = "Post Placeholder \(indexPath.row)"
        // TODO: Настроить реальную PostCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Примерная высота для фото 9:16 + отступы/текст
        let screenWidth = tableView.bounds.width
        return (screenWidth / 9 * 16) + 80 
    }
} 