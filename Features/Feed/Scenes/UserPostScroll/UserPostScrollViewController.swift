import UIKit
import Combine // Понадобится для будущих действий?

// Протокол для обработки нажатия на имя пользователя
protocol UserPostScrollViewControllerDelegate: AnyObject {
    func didTapUsername(userID: String)
}

class UserPostScrollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    private var allPosts: [Post] // Делаем var, чтобы можно было менять isLiked/likeCount
    private let initialIndex: Int // Индекс поста, с которого начинаем
    weak var delegate: UserPostScrollViewControllerDelegate?

    // Добавляем кэш для соотношений сторон
    private var knownAspectRatios: [IndexPath: CGFloat] = [:]

    // Добавляем сервис для лайков
    private let postService: PostServiceProtocol

    // Добавляем кэш для состояния expanded/collapsed подписи
    private var captionExpandedState: [IndexPath: Bool] = [:]

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        // УБИРАЕМ estimatedItemSize - ширина будет задана констрейнтом в ячейке
        // layout.estimatedItemSize = ...

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black // Черный фон (Пункт 5)
        cv.dataSource = self
        cv.delegate = self
        // Отключаем постраничную прокрутку
        cv.isPagingEnabled = false
        cv.showsVerticalScrollIndicator = false
        cv.register(FullPostCell.self, forCellWithReuseIdentifier: FullPostCell.identifier)
        return cv
    }()

    // MARK: - Initialization

    init(posts: [Post], startIndex: Int, postService: PostServiceProtocol = PostService()) {
        self.allPosts = posts
        self.initialIndex = startIndex
        self.postService = postService // Инъекция зависимости
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
        view.backgroundColor = .black
        
        // УБИРАЕМ установку estimatedItemSize отсюда
        
        setupViews()
        setupConstraints()
        setupNavigationBar()
        
        print("UserPostScrollViewController: viewDidLoad...")

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

    // УБИРАЕМ флаг и логику установки estimatedItemSize
    // private var estimatedSizeHasBeenSet = false
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // УБИРАЕМ установку estimatedItemSize
        /*
        if !estimatedSizeHasBeenSet, view.bounds.width > 0 {
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.estimatedItemSize = CGSize(width: view.bounds.width, height: 600) 
                estimatedSizeHasBeenSet = true
                print("UserPostScrollViewController: Установлен estimatedItemSize = \(layout.estimatedItemSize) в viewWillLayoutSubviews")
            }
        }
        */
       
        // Можно инвалидировать layout при изменении ширины, чтобы ячейки пересчитались
        // (хотя констрейнт ширины в ячейке должен сам это обработать)
        // if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
        //     layout.invalidateLayout()
        // }
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
            fatalError("Unable to dequeue FullPostCell")
        }
        let post = allPosts[indexPath.item]
        print("UserPostScrollViewController: cellForItemAt \(indexPath.item) - конфигурация ячейки с постом ID=\(post.id ?? "nil")")

        // Устанавливаем делегата для обычных действий и indexPath
        cell.delegate = self
        cell.indexPath = indexPath

        // Вызываем configure с indexPath и ЗАМЫКАНИЕМ, которое принимает aspectRatio
        cell.configure(with: post, indexPath: indexPath) { [weak self] pathForUpdate, receivedAspectRatio in
            self?.handleLayoutUpdateRequest(at: pathForUpdate, aspectRatio: receivedAspectRatio)
        }

        print("UserPostScrollViewController: Размеры ячейки после конфигурации - frame: \(cell.frame), bounds: \(cell.bounds), contentView: \(cell.contentView.bounds)")

        return cell
    }
    
    // Вспомогательный метод для обработки запроса на обновление layout (теперь принимает aspectRatio)
    private func handleLayoutUpdateRequest(at indexPath: IndexPath, aspectRatio: CGFloat) {
        print("UserPostScrollViewController: Запрос на обновление layout для indexPath \(indexPath) с aspectRatio \(aspectRatio).")
        
        // Проверяем, изменился ли aspect ratio
        if knownAspectRatios[indexPath] != aspectRatio {
            // Сохраняем НОВЫЙ aspect ratio в кэш
            knownAspectRatios[indexPath] = aspectRatio
            print("UserPostScrollViewController: Обновлен aspectRatio в кэше для indexPath \(indexPath) -> \(aspectRatio).")
            
            // Инвалидируем layout для этой ячейки
            let context = UICollectionViewFlowLayoutInvalidationContext()
            context.invalidateItems(at: [indexPath])
            collectionView.collectionViewLayout.invalidateLayout(with: context)
            print("UserPostScrollViewController: Layout инвалидирован для indexPath \(indexPath) из-за изменения aspectRatio.")
        } else {
             print("UserPostScrollViewController: AspectRatio для indexPath \(indexPath) не изменился (\(aspectRatio)), инвалидация не требуется.")
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    // ВОЗВРАЩАЕМ МЕТОД ДЕЛЕГАТА ДЛЯ РАСЧЕТА РАЗМЕРА
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let cellWidth = collectionView.bounds.width
        guard cellWidth > 0 else {
            // Если ширина еще 0, возвращаем временный размер (или .zero)
            return CGSize(width: 50, height: 50) // Или UIScreen.main.bounds.size
        }

        // --- Расчет высоты --- 
        var totalHeight: CGFloat = 0
        let padding: CGFloat = 10
        let footerPadding: CGFloat = 8

        // 1. Хедер
        totalHeight += padding // Отступ сверху
        totalHeight += 36 // Высота аватара
        totalHeight += padding // Отступ под аватаром

        // 2. Изображение - используем КЭШИРОВАННОЕ или дефолтное (1:1) соотношение
        let aspectRatio = knownAspectRatios[indexPath] ?? 1.0 // Используем 1.0 если еще не посчитано
        let imageHeight = cellWidth * aspectRatio
        totalHeight += imageHeight
        
        // 3. Кнопки действий
        totalHeight += 12 // Отступ над кнопками
        totalHeight += 28 // Высота кнопок действий

        // 4. Футер (лайки + подпись + кнопка комментов)
        totalHeight += footerPadding // Отступ над лайками
        totalHeight += 20 // Примерная высота для likeCountLabel (одна строка)
        totalHeight += footerPadding // Отступ под лайками/над подписью

        // Расчет высоты подписи с учетом состояния expanded/collapsed
        let post = allPosts[indexPath.item]
        let isExpanded = captionExpandedState[indexPath] ?? false // Получаем состояние из кэша (по умолчанию false)
        let captionHeight = calculateCaptionHeight(
            for: post.caption ?? "",
            width: cellWidth - 2 * padding, // Ширина для текста
            isExpanded: isExpanded,
            maxCollapsedLines: FullPostCell.captionMaxLinesCollapsed // Используем значение из ячейки
        )
        totalHeight += captionHeight
        
        // 5. Кнопка "View all comments" (если есть комментарии)
        if post.commentCount > 0 {
            totalHeight += 4 // Отступ над кнопкой
            totalHeight += 20 // Примерная высота кнопки (можно уточнить)
        }

        totalHeight += padding // Отступ снизу
        
        // Убираем дополнительный запас, расчет должен быть точнее
        // totalHeight += 10
        
        print("UserPostScrollViewController: sizeForItemAt \(indexPath.item) - AspectRatio: \(aspectRatio), isExpanded: \(isExpanded) - Calculated Size: (\(cellWidth), \(totalHeight))")

        return CGSize(width: cellWidth, height: totalHeight)
    }
    
    // Обновленная функция для расчета высоты подписи
    private func calculateCaptionHeight(for text: String, width: CGFloat, isExpanded: Bool, maxCollapsedLines: Int) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        
        let font = UIFont.systemFont(ofSize: 14) // Шрифт из FullPostCell
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)

        // Сначала считаем полную высоту
        let fullBoundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        let fullHeight = ceil(fullBoundingBox.height)
        
        // Если текст должен быть свернут
        if !isExpanded {
            // Считаем высоту для N строк (более надежно, чем обрезка текста)
            let lineCountLabel = UILabel() // Используем UILabel для расчета высоты N строк
            lineCountLabel.font = font
            lineCountLabel.numberOfLines = maxCollapsedLines
            lineCountLabel.text = text // Присваиваем полный текст
            let collapsedSize = lineCountLabel.sizeThatFits(constraintRect)
            let collapsedHeight = ceil(collapsedSize.height)
            
            // Если полная высота БОЛЬШЕ высоты для N строк, возвращаем высоту N строк
            // Иначе (если текст и так помещается в N строк) возвращаем полную высоту
            if fullHeight > collapsedHeight + 1 { // +1 для погрешности
                return collapsedHeight
            }
        }
        
        // Если текст развернут или помещается в N строк, возвращаем полную высоту
        return fullHeight
    }
}

// MARK: - FullPostCellDelegate
extension UserPostScrollViewController: FullPostCellDelegate {
    func didTapUsername(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath else { return }
        let post = allPosts[indexPath.item]
        print("Username tapped for post by user ID: \(post.userID)")
        // TODO: Навигация на профиль пользователя
        // coordinator?.showUserProfile(userID: post.userID)
    }
    
    func didTapFollowButton(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath else { return }
        let post = allPosts[indexPath.item]
        print("Follow button tapped for user ID: \(post.userID)")
        // TODO: Метод для подписки/отписки
    }
    
    func didTapLikeButton(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath, indexPath.item < allPosts.count else { return }
        let post = allPosts[indexPath.item]
        print("Like button tapped for post ID: \(post.id ?? "nil")")
        // TODO: Реализовать логику лайка/анлайка
    }
    
    func didTapCommentButton(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath else { return }
        let post = allPosts[indexPath.item]
        print("Comment button tapped for post ID: \(post.id ?? "nil")")
        // TODO: Показать комментарии
    }
    
    func didTapShareButton(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath else { return }
        let post = allPosts[indexPath.item]
        print("Share button tapped for post ID: \(post.id ?? "nil")")
        // TODO: Показать меню "Поделиться"
    }
    
    func didTapViewAllComments(in cell: FullPostCell) {
        guard let indexPath = cell.indexPath else { return }
        let post = allPosts[indexPath.item]
        print("View all comments tapped for post ID: \(post.id ?? "nil")")
        // TODO: Показать комментарии
        // coordinator?.showComments(for: post)
    }
    
    // НОВЫЙ МЕТОД, который заменяет fullPostCellNeedsLayoutUpdate из FullPostCellLayoutDelegate
    func fullPostCellDidToggleCaption(_ cell: FullPostCell, at indexPath: IndexPath) {
        print("UserPostScrollViewController: Caption toggle для indexPath \(indexPath).")
        
        // Обновляем состояние в кэше
        let currentState = captionExpandedState[indexPath] ?? false
        captionExpandedState[indexPath] = !currentState
        print("UserPostScrollViewController: Обновлен captionExpandedState[\(indexPath)] = \(!currentState)")
        
        // Инвалидируем layout для этой ячейки, чтобы пересчитать высоту
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateItems(at: [indexPath])
        collectionView.collectionViewLayout.invalidateLayout(with: context)
    }
} 