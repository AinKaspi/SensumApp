import UIKit
import Combine // Понадобится для будущих действий?

// Протокол для обработки нажатия на имя пользователя
protocol UserPostScrollViewControllerDelegate: AnyObject {
    func didTapUsername(userID: String)
}

class UserPostScrollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    private let allPosts: [Post] // Все посты пользователя
    private let initialIndex: Int // Индекс поста, с которого начинаем
    weak var delegate: UserPostScrollViewControllerDelegate?

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0 // Нет отступа между постами
        // Размер ячейки будет равен размеру видимой области collection view
        // Установим его в viewWillLayoutSubviews или layoutSubviews

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black // Черный фон (Пункт 5)
        cv.dataSource = self
        cv.delegate = self
        cv.isPagingEnabled = true // Постраничная прокрутка
        cv.showsVerticalScrollIndicator = false
        cv.register(FullPostCell.self, forCellWithReuseIdentifier: FullPostCell.identifier)
        return cv
    }()

    // MARK: - Initialization

    init(posts: [Post], startIndex: Int) {
        self.allPosts = posts
        self.initialIndex = startIndex
        super.init(nibName: nil, bundle: nil)
        
        // Добавляем отладочную информацию
        print("UserPostScrollViewController: Инициализирован с \(posts.count) постами, начальный индекс: \(startIndex)")
        for (index, post) in posts.enumerated() {
            print("  Пост #\(index): ID=\(post.id ?? "nil"), URL=\(post.imageURL)")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Черный фон (Пункт 5)
        setupViews()
        setupConstraints()
        setupNavigationBar()
        
        print("UserPostScrollViewController: viewDidLoad, размер коллекции: \(collectionView.bounds.size), посты: \(allPosts.count)")

        // Прокручиваем к начальному посту ПОСЛЕ того, как layout будет готов
        // Использование DispatchQueue.main.async гарантирует, что scrollToItem вызовется
        // после завершения начальной настройки layout'а.
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.initialIndex < self.allPosts.count else { 
                print("UserPostScrollViewController: Не удалось прокрутить к начальному индексу \(self?.initialIndex ?? -1), всего постов: \(self?.allPosts.count ?? 0)")
                return 
            }
            let indexPath = IndexPath(item: self.initialIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            print("UserPostScrollViewController: Прокручено к начальному индексу: \(self.initialIndex)")
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // УДАЛЕНО: Установка itemSize здесь ненадежна. Будем использовать делегат.
        /*
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let oldSize = layout.itemSize
            layout.itemSize = collectionView.bounds.size
            print("UserPostScrollViewController: Обновлен размер ячейки с \(oldSize) на \(layout.itemSize)")
        }
        */
        // Можно оставить этот метод пустым или удалить, если больше ничего не нужно делать при изменении layout.
        // Для чистоты можно и удалить, если super.viewWillLayoutSubviews() больше не требуется здесь.
    }


    // MARK: - Setup

    private func setupViews() {
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor), // От самого верха
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // До самого низа
        ])
    }

    private func setupNavigationBar() {
        // Можно оставить или скрыть NavigationBar
        // Если оставляем, кнопка "Назад" будет работать автоматически
        // title = "Posts"
         navigationItem.largeTitleDisplayMode = .never
         navigationController?.navigationBar.tintColor = .white // Белая стрелка назад
         // Можно добавить кастомную кнопку закрытия, если нужно
    }


    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("UserPostScrollViewController: numberOfItemsInSection вернул \(allPosts.count) постов")
        return allPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullPostCell.identifier, for: indexPath) as? FullPostCell else {
            print("UserPostScrollViewController: ОШИБКА! Не удалось получить ячейку FullPostCell")
            fatalError("Unable to dequeue FullPostCell")
        }
        let post = allPosts[indexPath.item]
        print("UserPostScrollViewController: cellForItemAt \(indexPath.item) - конфигурация ячейки с постом ID=\(post.id ?? "nil")")
        cell.configure(with: post)
        // Устанавливаем делегата для обработки нажатия на имя
        cell.delegate = self
        
        // Вызовем layout, чтобы обновить subviews и размеры
        cell.layoutIfNeeded()
        
        // Логируем размеры ячейки
        print("UserPostScrollViewController: Размеры ячейки после конфигурации - frame: \(cell.frame), bounds: \(cell.bounds), contentView: \(cell.contentView.bounds)")
        
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    // РАСКОММЕНТИРОВАНО: Используем этот метод для установки размера ячейки.
    // Он вызывается для каждой ячейки, гарантируя использование актуальных bounds.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       // Каждая ячейка должна занимать всю доступную область collection view.
       print("UserPostScrollViewController: sizeForItemAt запрошен, возвращаем \(collectionView.bounds.size)")
       return collectionView.bounds.size
    }
}

// MARK: - FullPostCellDelegate
extension UserPostScrollViewController: FullPostCellDelegate {
    func didTapUsername(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let post = allPosts[indexPath.item]
        print("Username tapped for post by user ID: \(post.userID)")
        delegate?.didTapUsername(userID: post.userID)
    }
} 