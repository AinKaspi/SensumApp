import UIKit

/// UITableView, который автоматически подстраивает свою высоту под контент,
/// когда isScrollEnabled = false.
class SelfSizingTableView: UITableView {

    // Переопределяем intrinsicContentSize, чтобы он возвращал реальную высоту контента
    override var intrinsicContentSize: CGSize {
        // Убеждаемся, что layout посчитан, чтобы contentSize был актуальным
        layoutIfNeeded()
        // Возвращаем высоту контента. Ширина не имеет значения для AutoLayout в данном случае.
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
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
        // Принудительно обновляем layout, чтобы intrinsicContentSize пересчитался
        self.layoutIfNeeded()
    }
} 