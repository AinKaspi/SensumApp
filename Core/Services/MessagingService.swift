import Foundation
import FirebaseFirestore

protocol MessagingServiceProtocol {
    // Загружает список чатов для текущего пользователя
    func fetchChats(completion: @escaping (Result<[Chat], Error>) -> Void)
    
    // Загружает сообщения для конкретного чата с пагинацией
    func fetchMessages(chatID: String, limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(messages: [ChatMessage], lastSnapshot: DocumentSnapshot?), Error>) -> Void)
    
    // Отправляет новое сообщение
    func sendMessage(text: String, chatID: String, recipientID: String, completion: @escaping (Error?) -> Void)
    
    // Создает новый чат (если его еще нет) и отправляет первое сообщение
    // Возвращает ID созданного чата
    func createChatAndSendMessage(text: String, recipientID: String, completion: @escaping (Result<String, Error>) -> Void)
    
    // Отмечает последнее сообщение в чате как прочитанное
    func markChatAsRead(chatID: String, completion: @escaping (Error?) -> Void)

    // TODO: Подписка на новые сообщения в реальном времени?
    // func listenForNewMessages(chatID: String, ...) -> ListenerRegistration
    // func listenForChatUpdates(completion: ...) -> ListenerRegistration
}

class MessagingService: MessagingServiceProtocol {

    private let db = Firestore.firestore()
    private var chatsCollection: CollectionReference { db.collection("chats") }
    private func messagesCollection(chatID: String) -> CollectionReference {
        chatsCollection.document(chatID).collection("messages")
    }
    // Заглушка authService
    private let authService: AuthServiceProtocol = AuthService()

    func fetchChats(completion: @escaping (Result<[Chat], Error>) -> Void) {
        print("MessagingService: fetchChats - Not Implemented Yet")
         guard let userID = authService.currentUserID else {
             completion(.failure(NSError(domain: "MessagingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
             return
         }
        // TODO: Запрос Firestore: whereField("userIDs", arrayContains: userID), orderBy("lastUpdatedAt")
        completion(.success([]))
    }

    func fetchMessages(chatID: String, limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(messages: [ChatMessage], lastSnapshot: DocumentSnapshot?), Error>) -> Void) {
        print("MessagingService: fetchMessages for chat \(chatID) - Not Implemented Yet")
        // TODO: Запрос Firestore к messagesCollection(chatID: chatID), orderBy("timestamp"), limit(), startAfter()
         completion(.success((messages: [], lastSnapshot: nil)))
    }

    func sendMessage(text: String, chatID: String, recipientID: String, completion: @escaping (Error?) -> Void) {
        print("MessagingService: sendMessage to chat \(chatID) - Not Implemented Yet")
         guard let senderID = authService.currentUserID else {
             completion(NSError(domain: "MessagingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
             return
         }
        // TODO:
        // 1. Создать объект ChatMessage
        // 2. Добавить документ в messagesCollection(chatID: chatID)
        // 3. Обновить lastMessage и lastUpdatedAt в документе чата chats/{chatID} (транзакцией?)
         completion(NSError(domain: "MessagingService", code: -99, userInfo: [NSLocalizedDescriptionKey: "Not Implemented"]))
    }
    
    func createChatAndSendMessage(text: String, recipientID: String, completion: @escaping (Result<String, Error>) -> Void) {
         print("MessagingService: createChatAndSendMessage with recipient \(recipientID) - Not Implemented Yet")
         guard let senderID = authService.currentUserID else {
             completion(.failure(NSError(domain: "MessagingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
             return
         }
         // TODO:
         // 1. Проверить, существует ли уже чат между senderID и recipientID (query whereField("userIDs", arrayContains: senderID) ...)
         // 2. Если нет:
         //    а. Создать новый документ Chat (с userIDs, lastUpdatedAt)
         //    б. Получить его ID
         // 3. Если да, получить существующий chatID
         // 4. Вызвать sendMessage(text: text, chatID: chatID, recipientID: recipientID) { ... completion(Result) }
         completion(.failure(NSError(domain: "MessagingService", code: -99, userInfo: [NSLocalizedDescriptionKey: "Not Implemented"])))
    }

    func markChatAsRead(chatID: String, completion: @escaping (Error?) -> Void) {
        print("MessagingService: markChatAsRead for chat \(chatID) - Not Implemented Yet")
         guard authService.currentUserID != nil else {
             completion(NSError(domain: "MessagingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
             return
         }
        // TODO: Обновить поле lastMessage.isRead = true в документе chats/{chatID}
         completion(NSError(domain: "MessagingService", code: -99, userInfo: [NSLocalizedDescriptionKey: "Not Implemented"]))
    }
}
