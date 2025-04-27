import Foundation
import FirebaseFirestore

protocol NotificationServiceProtocol {
    // Загружает уведомления для текущего пользователя
    func fetchNotifications(completion: @escaping (Result<[AppNotification], Error>) -> Void)
    
    // Отмечает уведомление как прочитанное
    func markNotificationAsRead(notificationID: String, completion: @escaping (Error?) -> Void)
    
    // Отмечает ВСЕ уведомления как прочитанные
    func markAllNotificationsAsRead(completion: @escaping (Error?) -> Void)
    
    // TODO: Метод для отправки уведомления (скорее всего будет на бэкенде через Cloud Functions)
    // func sendNotification(_ notification: AppNotification, completion: @escaping (Error?) -> Void)
    
    // TODO: Подписка на новые уведомления в реальном времени?
}

class NotificationService: NotificationServiceProtocol {

    private let db = Firestore.firestore()
    private var notificationsCollection: CollectionReference { db.collection("notifications") }
    private let authService: AuthServiceProtocol = AuthService() // Заглушка

    func fetchNotifications(completion: @escaping (Result<[AppNotification], Error>) -> Void) {
        print("NotificationService: fetchNotifications - Not Implemented Yet")
        guard let userID = authService.currentUserID else {
            completion(.failure(NSError(domain: "NotificationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        // TODO: Запрос к Firestore whereField("recipientUserID", isEqualTo: userID), orderBy("createdAt")
        completion(.success([]))
    }

    func markNotificationAsRead(notificationID: String, completion: @escaping (Error?) -> Void) {
        print("NotificationService: markNotificationAsRead - Not Implemented Yet")
        guard let userID = authService.currentUserID else { // Доп. проверка безопасности?
            completion(NSError(domain: "NotificationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
         // TODO: Обновить документ в Firestore: notifications/{notificationID}, установить isRead = true
         completion(NSError(domain: "NotificationService", code: -99, userInfo: [NSLocalizedDescriptionKey: "Not Implemented"]))
    }
    
    func markAllNotificationsAsRead(completion: @escaping (Error?) -> Void) {
        print("NotificationService: markAllNotificationsAsRead - Not Implemented Yet")
        guard let userID = authService.currentUserID else {
            completion(NSError(domain: "NotificationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        // TODO: Найти все непрочитанные уведомления для userID и обновить их (может быть дорогой операцией!)
         completion(NSError(domain: "NotificationService", code: -99, userInfo: [NSLocalizedDescriptionKey: "Not Implemented"]))
    }
}
