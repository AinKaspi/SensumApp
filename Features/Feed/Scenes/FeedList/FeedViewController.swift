import UIKit
import Combine
import FirebaseAuth

// Определяем делегат здесь временно, или найдем его правильное место позже
protocol FeedViewControllerDelegate: AnyObject {
    func feedViewControllerDidTapNotifications(_ controller: FeedViewController)
    func feedViewControllerDidTapMessages(_ controller: FeedViewController)
    func feedViewController(_ controller: FeedViewController, didTapUsername userID: String)
    func feedViewController(_ controller: FeedViewController, didTapCommentsForPostID postID: String)
    // Добавьте другие методы по мере необходимости
}

// Меняем базовый класс и конформансы протоколов
class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, FullPostCellDelegate {

    // MARK: - Dependencies
    var viewModel: FeedViewModel!
    weak var delegate: FeedViewControllerDelegate?

    // Добавляем статическую ячейку для расчета высоты
    private static let sizingCell = FullPostCell()
    // Восстанавливаем cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 15 // Промежуток между постами
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black // Или другой цвет фона?
        // Регистрируем FullPostCell
        collectionView.register(FullPostCell.self, forCellWithReuseIdentifier: FullPostCell.identifier)
        // Регистрируем футер для пагинации
        collectionView.register(PaginationIndicatorFooterView.self,
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                              withReuseIdentifier: PaginationIndicatorFooterView.identifier)
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self // Добавляем prefetchDataSource
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true // Для pull-to-refresh
        return collectionView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // Добавляем refresh control для pull-to-refresh
    private let refreshControl = UIRefreshControl()

    // MARK: - Properties
    private var expandedCaptions: Set<String> = [] // Для отслеживания развернутых описаний

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected")
        view.backgroundColor = .black
        setupUI()
        setupConstraints()
        setupRefreshControl() // Настраиваем pull-to-refresh
        setupBindings()
        // viewModel.loadInitialPosts() // Загружаем первые посты
    }

    // MARK: - Setup
    private func setupUI() {
        // Добавляем collectionView вместо tableView
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        // refreshControl добавляется к collectionView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // collectionView на весь экран
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Индикатор по центру
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.tintColor = .white // Цвет индикатора
        collectionView.refreshControl = refreshControl // Привязываем к collectionView
    }

    private func setupBindings() {
        // Загрузка начальных данных при первом появлении
        // Используем fetchPosts(refresh: true)
        viewModel.fetchPosts(refresh: true)

        // Подписка на обновление постов
        viewModel.$feedPosts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Перезагружаем collectionView вместо tableView
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)

        // Подписка на состояние загрузки (начальной)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                    // Останавливаем pull-to-refresh, если он был активен
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        // Подписка на состояние пагинации (загрузки следующих)
        viewModel.$isFetchingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                // Обновляем футер пагинации
                // Найдем видимые футеры и обновим их состояние
                self?.collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter)
                    .compactMap { self?.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: $0) as? PaginationIndicatorFooterView }
                    .forEach { footer in
                        if isFetching {
                            footer.startAnimating()
                        } else {
                            footer.stopAnimating()
                        }
                    }
                // Также нужно вызвать reloadData или invalidation для футера, чтобы он появился/исчез
                // Проще всего обновить секцию, но это может быть избыточно
                 self?.collectionView.collectionViewLayout.invalidateLayout() // Пересчет layout для футера
            }
            .store(in: &cancellables)

        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 } // Пропускаем nil
            .sink { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
                // Останавливаем все индикаторы
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                // TODO: Возможно, остановить и индикатор пагинации, если ошибка при ней
            }
            .store(in: &cancellables)

        // TODO: Добавить подписку на isLastPageReached, если нужно скрывать футер полностью
    }

    // MARK: - Actions
    @objc private func refreshData(_ sender: UIRefreshControl) {
        // Вызываем метод ViewModel для обновления
        // Используем refreshFeed()
        viewModel.refreshFeed()
    }

    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 // У нас одна секция для постов
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.feedPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullPostCell.identifier, for: indexPath) as? FullPostCell else {
            fatalError("Unable to dequeue FullPostCell")
        }

        // 1. Пытаемся получить пост
        guard let post = viewModel.feedPosts[safe: indexPath.item] else {
            print("FeedVC [cellForItemAt] Warning: No post data for indexPath \(indexPath)")
            // Вернуть пустую ячейку, если нет поста
            return cell
        }

        // 2. Получаем currentUserID из Firebase Auth
        guard let currentUserID = Auth.auth().currentUser?.uid else {
             print("FeedVC Error: Could not get current user ID from Firebase Auth.")
             // Вернуть пустую ячейку, если нет ID текущего пользователя
             return cell
        }

        // 3. Используем метод configure с неопциональным post и currentUserID
        cell.configure(with: post, currentUserID: currentUserID, indexPath: indexPath)
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }

    // Метод для футера пагинации
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PaginationIndicatorFooterView.identifier, for: indexPath) as? PaginationIndicatorFooterView else {
                fatalError("Unable to dequeue PaginationIndicatorFooterView")
            }
            // Показываем анимацию, если идет загрузка и это последняя секция
            if viewModel.isFetchingMore && indexPath.section == collectionView.numberOfSections - 1 && !viewModel.canLoadMore {
                footer.startAnimating()
            } else {
                footer.stopAnimating()
            }
            return footer
        default:
            assert(false, "Unexpected element kind")
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FeedViewController: UICollectionViewDelegateFlowLayout {

    // Переписанный метод для расчета размера ячейки
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let targetWidth = collectionView.bounds.width

        guard let post = viewModel.feedPosts[safe: indexPath.item] else {
            if indexPath.item == 0 {
                print("FeedVC [sizeForItemAt 0] ⚠️ Warning: No post data")
            }
            return CGSize(width: targetWidth, height: 300) // Fallback
        }

        // Явный расчет высоты медиа
        let aspectRatio = aspectRatioMultiplier(from: post.feedAspectRatio)
        let mediaHeight = targetWidth * aspectRatio

        // Расчет высоты остальных компонентов
        // TODO: Уточнить эти константы или измерять их более точно, если нужно
        let headerHeight: CGFloat = 50 // Аватар, имя, кнопка опций
        let actionsHeight: CGFloat = 40 // Лайк, коммент, иконки
        let footerSpacing: CGFloat = 10 // Отступ под caption

        // Расчет высоты caption
        let captionHeight = calculateCaptionHeight(for: post, targetWidth: targetWidth)

        // Суммарная высота
        let totalHeight = headerHeight + mediaHeight + actionsHeight + captionHeight + footerSpacing

        // Логирование для первой ячейки
        if indexPath.item == 0 {
            print("FeedVC [sizeForItemAt 0]: AspectRatio String: \(post.feedAspectRatio), Multiplier: \(aspectRatio)")
            print("FeedVC [sizeForItemAt 0]: H = Header(\(headerHeight)) + Media(\(mediaHeight)) + Actions(\(actionsHeight)) + Caption(\(captionHeight)) + Footer(\(footerSpacing)) = \(totalHeight)")
        }

        return CGSize(width: targetWidth, height: max(1, totalHeight))
    }
}

// MARK: - UICollectionViewDelegate

extension FeedViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == 0, let fullPostCell = cell as? FullPostCell {
            let cellFrame = fullPostCell.frame
            // Доступ к 'mediaCollectionView' и 'imageAspectRatioConstraint' требует non-private в FullPostCell
            let mediaFrame = fullPostCell.mediaCollectionView.frame 
            let constraintMultiplier = fullPostCell.imageAspectRatioConstraint?.multiplier ?? -1
            let isActive = fullPostCell.imageAspectRatioConstraint?.isActive ?? false
            print("➡️ FeedVC [willDisplay 0]: Cell Frame: \(cellFrame), Media Frame: \(mediaFrame), Aspect Multiplier: \(String(format: "%.3f", constraintMultiplier)), IsActive: \(isActive)")
        }
        
        // Логика для пагинации (ВРЕМЕННО ЗАКОММЕНТИРОВАНА ИЗ-ЗА ОШИБОК КОМПИЛЯЦИИ)
        /*
        if indexPath.item == viewModel.feedPosts.count - 5 && viewModel.canLoadMore && !viewModel.isLoadingPosts {
            print("FeedVC [willDisplay]: Approaching end, loading more posts...")
            viewModel.loadMorePosts()
        }
        */
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            print("FeedVC [didEndDisplaying 0]: Cell disappeared.")
        }
        // Опционально: Отмена задач для ячейки, если необходимо (Kingfisher обычно справляется сам)
        // if let cell = cell as? FullPostCell {
        //     cell.cancelDownloadsIfNeeded()
        // }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension FeedViewController {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Проверяем, достигли ли мы конца списка при предзагрузке
        if indexPaths.contains(where: { $0.item >= viewModel.feedPosts.count - 5 }) { // Загружаем за 5 элементов до конца
            print("FeedVC: Prefetching near end, loading more...")
            viewModel.loadMorePostsIfNeeded()
        }
    }
}

// MARK: - FullPostCellDelegate
extension FeedViewController {

    // Исправляем сигнатуру и реализацию
    func didTapLikeButton(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let post = viewModel.feedPosts[safe: indexPath.item] else { return }
        print("FeedVC: Like button tapped for post ID: \(post.id ?? "N/A")")
        viewModel.toggleLike(for: post.id!)
    }

    // Исправляем сигнатуру (Comment а не Comments) и реализацию
    func didTapCommentButton(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let post = viewModel.feedPosts[safe: indexPath.item] else { return }
        print("FeedVC: Comments button tapped for post ID: \(post.id ?? "N/A")")
        delegate?.feedViewController(self, didTapCommentsForPostID: post.id!)
    }

    // Исправляем реализацию, чтобы получить userID
    func didTapUsername(in cell: FullPostCell) {
         guard let indexPath = collectionView.indexPath(for: cell),
               let post = viewModel.feedPosts[safe: indexPath.item] else { return }
        print("FeedVC: Username tapped for user ID: \(post.userID)")
        delegate?.feedViewController(self, didTapUsername: post.userID)
    }

    // Реализуем недостающий метод
    func didTapFollowButton(in cell: FullPostCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let post = viewModel.feedPosts[safe: indexPath.item] else { return }
        print("FeedVC: Follow button tapped for user ID: \(post.userID). Post ID: \(post.id ?? "N/A")")
        // TODO: Implement follow/unfollow logic using viewModel or a dedicated service
        // viewModel.toggleFollow(userId: post.userID)
    }

    // Реализуем недостающий метод
    func fullPostCellDidRequestLayoutUpdate(at indexPath: IndexPath) {
        // Этот метод вызывается из ячейки, когда ее контент изменился
        // (например, развернули/свернули текст) и требуется пересчет высоты.
        print("FeedVC: Layout update requested for cell at \(indexPath)")
        // Используем performBatchUpdates для плавной анимации изменения размера
        collectionView.performBatchUpdates({
            // Простого invalidateLayout для UICollectionViewFlowLayout обычно достаточно,
            // так как он заставит collection view переспросить размеры через sizeForItemAt.
            // Если используется Compositional Layout с estimated размерами, может потребоваться
            // collectionView.collectionViewLayout.invalidateLayout(with: context)
            // или даже переконфигурация снапшота.
            // Для Flow Layout этого должно хватить:
            collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)

        // Старый код с обновлением кэша (больше не нужен)
        /*
        guard let postId = viewModel.feedPosts[safe: indexPath.item]?.id else { return }
        // Сбрасываем кэш высоты для этой ячейки
        // cellHeightCache.removeValue(forKey: postId)

        collectionView.performBatchUpdates({
            // Инвалидируем layout только для измененного элемента, если возможно
            // let context = UICollectionViewFlowLayoutInvalidationContext()
            // context.invalidateItems(at: [indexPath])
            // collectionView.collectionViewLayout.invalidateLayout(with: context)
            // ИЛИ инвалидируем весь layout
            collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
        */
    }

    func didTapOptionsButton(in cell: FullPostCell, forPostId postId: String) {
        print("FeedVC: Options button tapped for post ID: \(postId)")
        // TODO: Implement options action sheet (e.g., report, unfollow, delete)
        showOptionsActionSheet(for: postId)
    }

    // MARK: - Private Helpers
    private func showOptionsActionSheet(for postId: String) {
        // TODO: Implement options action sheet
    }
}

// MARK: - Helper Methods (Re-added)

// Копируем или делаем доступным из FullPostCell
extension FeedViewController {
    private func aspectRatioMultiplier(from string: String) -> CGFloat {
        switch string {
            case "9:16": return 16.0 / 9.0
            case "1:1": return 1.0 / 1.0
            case "1.91:1": return 1.0 / 1.91
            default:
                print("FeedVC Warning: Unknown aspectRatio string '\(string)', defaulting to 1:1")
                return 1.0 // Дефолт 1:1
        }
    }

    private func calculateCaptionHeight(for post: Post, targetWidth: CGFloat) -> CGFloat {
        guard let caption = post.caption, !caption.isEmpty else {
            return 0 // Нет подписи - нет высоты
        }

        // Используем статическую ячейку для доступа к конфигурации шрифта/отступов captionLabel
        // Либо создаем label с такими же параметрами
        let sizingLabel = UILabel()
        // TODO: Убедиться, что шрифт и другие параметры соответствуют captionLabel в FullPostCell
        sizingLabel.font = .systemFont(ofSize: 14) // Пример, взять из FullPostCell
        sizingLabel.numberOfLines = FullPostCell.captionMaxLinesCollapsed // Используем лимит строк из ячейки
        sizingLabel.text = caption

        // Определяем максимальную ширину для текста подписи (ширина ячейки минус горизонтальные отступы)
        // TODO: Уточнить отступы (padding) из FullPostCell
        let captionPadding: CGFloat = 16 * 2 // Пример: 16pt слева и справа
        let captionMaxWidth = targetWidth - captionPadding

        guard captionMaxWidth > 0 else { return 0 }

        let calculatedSize = sizingLabel.systemLayoutSizeFitting(
            CGSize(width: captionMaxWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, // Ширина фиксирована
            verticalFittingPriority: .fittingSizeLevel // Высота подстраивается
        )

        return calculatedSize.height
    }
}
