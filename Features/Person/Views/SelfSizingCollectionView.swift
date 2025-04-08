import UIKit

/// UICollectionView, который автоматически подстраивает свою высоту под контент,
/// когда isScrollEnabled = false. Использует высоту из collectionViewLayout.
class SelfSizingCollectionView: UICollectionView {

    // Переопределяем intrinsicContentSize, чтобы он возвращал реальную высоту контента из layout'а
    override var intrinsicContentSize: CGSize {
        // Для CollectionView высота контента обычно определяется его layout'ом
        // Убеждаемся, что layout посчитан
        layoutIfNeeded()
        // Возвращаем высоту контента из layout'а. Ширина не важна.
        return CGSize(width: UIView.noIntrinsicMetric, height: collectionViewLayout.collectionViewContentSize.height)
    }

    // Переопределяем contentSize, чтобы при его изменении обновлять intrinsicContentSize
    override var contentSize: CGSize {
        didSet {
            // Если высота контента изменилась, сообщаем системе AutoLayout,
            // что наш внутренний размер нужно пересчитать.
            if oldValue.height != contentSize.height {
                invalidateIntrinsicContentSize()
            }
        }
    }

    // Переопределяем reloadData, чтобы после перезагрузки данных
    // немедленно обновить intrinsicContentSize.
    override func reloadData() {
        super.reloadData()
        // Сообщаем системе, что размер мог измениться
        self.invalidateIntrinsicContentSize()
        // Принудительно обновляем layout
        self.layoutIfNeeded()
    }
} 