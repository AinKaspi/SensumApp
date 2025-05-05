import UIKit

// Определяем протокол делегата для взаимодействия с ячейками постов
protocol PostCellDelegate: AnyObject {
    // Вызывается при нажатии на аватар или имя пользователя
    func postCellDidTapAuthor(_ cell: UITableViewCell)
    
    // Вызывается при нажатии на кнопку лайка
    // Передает текущее состояние лайка (после нажатия)
    func postCellDidTapLikeButton(_ cell: UITableViewCell, currentLikeState: Bool)
    
    // Вызывается при нажатии на кнопку комментариев
    func postCellDidTapCommentButton(_ cell: UITableViewCell)
    
    // Вызывается при разворачивании/сворачивании описания
    func postCellDidToggleCaption(_ cell: UITableViewCell)
}
