import UIKit

// Кастомный View для заголовка таблицы, содержащий сторис
class StoriesHeaderView: UIView {

    // UICollectionView для сторис
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 15
        // Рассчитываем высоту ячейки: 80 (аватар) + 8 (отступ) + ~30 (лейбл) = 118. Округляем до 120.
        layout.itemSize = CGSize(width: 80, height: 120)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(StoryCell.self, forCellWithReuseIdentifier: StoryCell.identifier)
        // dataSource и delegate будут установлены во FeedViewController
        // Устанавливаем отступы, чтобы контент начинался не от самого края
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black // Фон для всего хедера
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(collectionView)
    }

    private func setupConstraints() {
        // CollectionView занимает весь хедер
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // Метод для установки делегата и источника данных извне
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate: D, forRow row: Int) {
         collectionView.delegate = dataSourceDelegate
         collectionView.dataSource = dataSourceDelegate
         collectionView.tag = row // Можно использовать tag для идентификации, если нужно
         collectionView.reloadData()
     }
}
