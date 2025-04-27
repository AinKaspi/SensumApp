import UIKit
import Combine

// Делегат для обработки действий внутри ленты постов
protocol UserPostScrollViewControllerDelegate: AnyObject {
    func didTapUsername(userID: String)
    func didTapCommentsButton(forPostID postID: String)
    // Можно добавить другие действия, если нужно
}

// Меняем базовый класс и протоколы
// Убираем избыточное объявление UICollectionViewDataSource здесь
class UserPostScrollViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    // MARK: - Dependencies
    // var viewModel: UserPostScrollViewModel! // Добавим позже
    weak var delegate: UserPostScrollViewControllerDelegate?

    // MARK: - Properties
    private var posts: [Post] // Теперь это источник данных
    private let startIndex: Int
    private var cancellables = Set<AnyCancellable>()
    // Флаг, чтобы избежать прокрутки при обновлении данных
    private var hasScrolledToInitial = false

    // MARK: - UI Elements
    // Заменяем UITableView на UICollectionView
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
        // collectionView.refreshControl = refreshControl // Нужен ли рефреш?
        // TODO: Добавить футер для пагинации?
        return collectionView
    }()
    
    // TODO: Добавить индикаторы

    // MARK: - Initialization
    init(posts: [Post], startIndex: Int) {
        self.posts = posts
        self.startIndex = startIndex
        super.init(nibName: nil, bundle: nil)
        print("UserPostScrollVC: Init with \(posts.count) posts, startIndex: \(startIndex)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupConstraints()
        // setupBindings() // Добавим позже
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
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // CollectionView на весь экран (под Navigation Bar)
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Привязываем низ к safe area, чтобы не заезжать под TabBar (если он есть)
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func scrollToInitialPost() {
        guard startIndex >= 0 && startIndex < posts.count else {
            print("UserPostScrollVC Error: Invalid startIndex \(startIndex) for posts count \(posts.count)")
            return
        }
        // Прокручиваем UICollectionView
        let indexPath = IndexPath(item: self.startIndex, section: 0)
        // Используем animated: false для мгновенного перехода
        // Используем .centeredVertically, чтобы пост был по центру
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        print("UserPostScrollVC: Scrolled to initial post at index \(self.startIndex)")
        // Устанавливаем флаг после первой прокрутки
        // hasScrolledToInitial = true // Перенесено в viewDidLayoutSubviews
    }

    // MARK: - Bindings
    /*
    private func setupBindings() {
        // Подписки на viewModel.$posts, viewModel.$isLoading и т.д.
    }
     */

}

// MARK: - UICollectionViewDataSource
extension UserPostScrollViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count // Пока используем начальный массив
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullPostCell.identifier, for: indexPath) as? FullPostCell else {
            fatalError("Unable to dequeue FullPostCell")
        }
        let post = posts[indexPath.item] // Используем item для CollectionView
        // TODO: Настроить configure в FullPostCell для передачи замыкания обновления layout
        cell.configure(with: post, indexPath: indexPath, needsLayoutUpdateAction: nil) 
        // cell.delegate = self // Когда будет делегат для FullPostCell
        return cell
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
}

// MARK: - UICollectionViewDelegate
// Пока не нужен, но оставляем для будущих действий (пагинация и т.д.)
// extension UserPostScrollViewController: UICollectionViewDelegate {}

// TODO: Добавить реализацию делегата для FullPostCell (аналогично PostCellDelegate)
// TODO: Реализовать пагинацию в willDisplay
