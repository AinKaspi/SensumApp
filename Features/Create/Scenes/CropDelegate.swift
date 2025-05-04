import Foundation
import UIKit

/// Протокол для уведомления о завершении кропа изображения
protocol CropDelegate: AnyObject {
    /// Вызывается, когда пользователь завершил кроп и сохранил результат.
    /// - Parameter item: Обновленный EditableMediaItem с результатом в поле `finalImage`.
    func cropViewControllerDidFinishCropping(item: EditableMediaItem)
}
