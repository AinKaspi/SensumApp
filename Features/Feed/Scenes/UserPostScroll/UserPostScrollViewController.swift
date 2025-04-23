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

    // Добавляем кэш для соотношений сторон
    private var knownAspectRatios: [IndexPath: CGFloat] = [:]

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

        // Устанавливаем делегатов и indexPath
        cell.delegate = self
        cell.layoutDelegate = self
        cell.indexPath = indexPath

        // Вызываем configure с indexPath
        cell.configure(with: post, indexPath: indexPath)

        print("UserPostScrollViewController: Размеры ячейки после конфигурации - frame: \(cell.frame), bounds: \(cell.bounds), contentView: \(cell.contentView.bounds)")

        return cell
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

        // 3. Футер (лайки + подпись)
        totalHeight += footerPadding // Отступ над лайками
        // Примерная высота для лайков (одна строка)
        totalHeight += 20 
        totalHeight += footerPadding // Отступ под лайками
        // Примерная высота для подписи (допустим, 2 строки)
        // TODO: Более точный расчет высоты текста?
        let post = allPosts[indexPath.item]
        let captionHeight = calculateEstimatedCaptionHeight(for: post.caption ?? "", width: cellWidth - 2 * padding)
        totalHeight += captionHeight
        totalHeight += padding // Отступ снизу
        
        print("UserPostScrollViewController: sizeForItemAt \(indexPath.item) - AspectRatio: \(aspectRatio) - Calculated Size: (\(cellWidth), \(totalHeight))")

        return CGSize(width: cellWidth, height: totalHeight)
    }
    
    // Вспомогательная функция для примерного расчета высоты подписи
    // (Может потребоваться более точный расчет)
    private func calculateEstimatedCaptionHeight(for text: String, width: CGFloat) -> CGFloat {
        // Если текст пустой, высота 0
        guard !text.isEmpty else { return 0 }
        
        let approximateFont = UIFont.systemFont(ofSize: 14) // Шрифт из FullPostCell
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, 
                                              options: .usesLineFragmentOrigin,
                                              attributes: [.font: approximateFont], 
                                              context: nil)
        
        // Добавим небольшой запас
        return ceil(boundingBox.height) + 5 
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

// РЕАЛИЗАЦИЯ ДЕЛЕГАТА ОТ ЯЧЕЙКИ
extension UserPostScrollViewController: FullPostCellLayoutDelegate {
    func fullPostCell(_ cell: FullPostCell, didCalculateAspectRatio ratio: CGFloat, at indexPath: IndexPath) {
        // Проверяем, изменилось ли соотношение сторон, чтобы избежать лишних инвалидаций
        // и потенциальных циклов
        let existingRatio = knownAspectRatios[indexPath]
        if existingRatio != ratio {
            print("UserPostScrollViewController: Получен новый aspect ratio \(ratio) для indexPath \(indexPath). Старый: \(existingRatio ?? -1). Инвалидируем layout.")
            knownAspectRatios[indexPath] = ratio
            
            // Инвалидируем layout для этой ячейки
            let context = UICollectionViewFlowLayoutInvalidationContext()
            context.invalidateItems(at: [indexPath])
            collectionView.collectionViewLayout.invalidateLayout(with: context)
            // Примечание: Иногда может потребоваться collectionView.layoutIfNeeded() после инвалидации,
            // если обновление происходит не сразу, но обычно invalidateLayout(with:) достаточно.
        }
    }
} 