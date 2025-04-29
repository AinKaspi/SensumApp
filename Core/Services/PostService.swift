import Foundation
import FirebaseFirestore
// Удаляем проблемные комментарии и импорты
// Более простой подход - использовать структуру напрямую

// Структура для обработки комментариев (дублирование для обхода проблем с модулями)
// УДАЛЯЕМ DTO - будем использовать основную модель Comment
/*
struct CommentDTO: Codable {
    let id: String
    let postId: String
    let authorUid: String
    let authorUsername: String
    let authorAvatarUrl: String?
    let text: String
    let timestamp: Timestamp
    
    // Для Firestore
    var asFirestoreData: [String: Any] {
        var data: [String: Any] = [
            "postId": postId,
            "authorId": authorUid,
            "authorUsername": authorUsername,
            "text": text,
            "timestamp": timestamp
        ]
        
        if let authorAvatarUrl = authorAvatarUrl {
            data["authorAvatarUrl"] = authorAvatarUrl
        }
        
        return data
    }
}
*/

// Протокол для PostService
protocol PostServiceProtocol {
    func createPost(imageURL: String, caption: String?, completion: @escaping (Error?) -> Void)
    func fetchPosts(forUserID userID: String, limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void)
    func fetchFeedPosts(limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void)
    func likePost(postID: String, completion: @escaping (Error?) -> Void)
    func unlikePost(postID: String, completion: @escaping (Error?) -> Void)
    // TODO: Добавить методы для пагинации, лайков, комментариев, удаления и т.д.
    
    // MARK: - Comments
    // Новый протокол для комментов
    func fetchComments(for postId: String, completion: @escaping (Result<[Comment], Error>) -> Void)
    func addComment(_ text: String, for postId: String, completion: @escaping (Error?) -> Void)
    
    // Обновленный метод для создания поста с указанием соотношения сторон
    func createPostWithAspectRatio(imageURL: String, caption: String?, aspectRatio: String, completion: @escaping (Error?) -> Void)
}

class PostService: PostServiceProtocol {
    
    private let db = Firestore.firestore()
    // Добавляем зависимости
    private let authService: AuthServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    
    private var postsCollection: CollectionReference {
        return db.collection("posts")
    }
    
    // Обновляем init
    init(authService: AuthServiceProtocol = AuthService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService()) {
        self.authService = authService
        self.userProfileService = userProfileService
    }
    
    // Обновляем метод создания поста
    func createPost(imageURL: String, caption: String?, completion: @escaping (Error?) -> Void) {
        print("🔶 PostService: Начинаем создание поста")
        guard let currentUserID = authService.currentUserID else {
            print("❌ PostService: Ошибка - пользователь не авторизован")
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        print("🔶 PostService: Получаем данные пользователя \(currentUserID)")
        // 1. Получаем данные текущего пользователя для денормализации
        userProfileService.fetchUserProfile(userID: currentUserID) { [weak self] result in
            guard let self = self else {
                print("❌ PostService: Ошибка - self потерян")
                return
            }
            
            switch result {
            case .success(let user):
                print("🔶 PostService: Получены данные пользователя. username: \(user.username), avatarURL: \(user.avatarURL ?? "nil")")
                // Создаем MediaItemDTO
                let mediaItemDTO = MediaItemDTO(type: .image, url: imageURL)
                
                // 2. Создаем объект Post с данными автора
                let newPost = Post(
                    userID: currentUserID,
                    mediaItems: [mediaItemDTO], // Используем массив из одного MediaItemDTO
                    feedAspectRatio: "1:1", // По умолчанию квадрат
                    gridThumbnailURL: imageURL, // Используем то же изображение для миниатюры
                    caption: caption,
                    createdAt: Timestamp(),
                    likeCount: 0,
                    commentCount: 0,
                    authorUsername: user.username, // <-- Денормализация
                    authorAvatarURL: user.avatarURL) // <-- Денормализация
                
                print("🔶 PostService: Создан объект Post, сохраняем в Firestore")
                // 3. Сохраняем пост в Firestore
                do {
                    _ = try self.postsCollection.addDocument(from: newPost) { error in
                        if let error = error {
                            print("❌ PostService Error (Create - Firestore Add): \(error.localizedDescription)")
                        } else {
                            print("✅ PostService: Пост успешно сохранен в Firestore")
                        }
                        completion(error)
                    }
                } catch let error {
                    print("❌ PostService Error (Encoding Post): \(error.localizedDescription)")
                    completion(error)
                }
                
            case .failure(let error):
                print("❌ PostService Error (Create - Fetching User Profile): \(error.localizedDescription)")
                completion(error) // Ошибка получения профиля = ошибка создания поста
            }
        }
    }
    
    // Обновляем fetchPosts для пагинации
    func fetchPosts(forUserID userID: String, limit: Int = 15, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void) {
        var query: Query = postsCollection
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        query.getDocuments { snapshot, error in
            if let error = error {
                print("PostService Error (Fetch User Posts w/ Paging): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success((posts: [], lastSnapshot: nil)))
                return
            }

            let posts = documents.compactMap { try? $0.data(as: Post.self) }
            let newLastSnapshot = documents.last
            
            print("PostService: Fetched \(posts.count) posts for user \(userID). Last snapshot: \(newLastSnapshot?.documentID ?? "None")")
            completion(.success((posts: posts, lastSnapshot: newLastSnapshot)))
        }
    }
    
    // Загружает посты для ленты (пока просто последние N постов)
    func fetchFeedPosts(limit: Int = 20, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void) {
        // Базовый запрос
        var query: Query = postsCollection
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        // Если есть lastDocumentSnapshot, добавляем курсор
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        // Выполняем запрос
        query.getDocuments { snapshot, error in
            if let error = error {
                print("PostService Error (Fetch Feed Posts w/ Pagination): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                // Нет документов (или ошибка без объекта error?)
                completion(.success((posts: [], lastSnapshot: nil)))
                return
            }
            
            // Декодируем посты
            let posts = documents.compactMap { try? $0.data(as: Post.self) }
            
            // Получаем последний документ для следующей страницы
            let newLastSnapshot = documents.last
            
            print("PostService: Fetched \(posts.count) posts. Last snapshot: \(newLastSnapshot?.documentID ?? "None")")
            
            // Возвращаем результат
            completion(.success((posts: posts, lastSnapshot: newLastSnapshot)))
        }
    }
    
    // MARK: - Liking
    
    func likePost(postID: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        let postRef = postsCollection.document(postID)
        let likeRef = postRef.collection("postLikes").document(currentUserID)
        
        // Используем транзакцию для атомарности
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Сначала проверяем, не лайкнут ли уже (хотя UI должен это предотвращать)
            // let postLikeDoc = try? transaction.getDocument(likeRef).data()
            // guard postLikeDoc == nil else { return nil } // Уже лайкнут
            
            // Обновляем счетчик лайков поста
            transaction.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: postRef)
            // Добавляем запись о лайке
            transaction.setData(["userID": currentUserID, "timestamp": Timestamp()], forDocument: likeRef)
            
            return nil // Успешное завершение транзакции
        }) { (object, error) in
            if let error = error {
                print("PostService Error (Like Transaction): \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    func unlikePost(postID: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        let postRef = postsCollection.document(postID)
        let likeRef = postRef.collection("postLikes").document(currentUserID)
        
        // Используем транзакцию
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Проверяем, существует ли лайк, перед удалением
            // let postLikeDoc = try? transaction.getDocument(likeRef).data()
            // guard postLikeDoc != nil else { return nil } // Лайка нет

            // Уменьшаем счетчик лайков (не даем уйти ниже нуля)
            transaction.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
            // Удаляем запись о лайке
            transaction.deleteDocument(likeRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("PostService Error (Unlike Transaction): \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    // MARK: - Comments
    
    // Переделываем на completion handlers вместо async/await
    func fetchComments(for postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        let commentsCollection = postsCollection.document(postId).collection("comments")
        
        commentsCollection
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("PostService Error (Fetch Comments): \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Теперь декодируем напрямую в модель Comment
                let comments = documents.compactMap { doc -> Comment? in
                    var comment = try? doc.data(as: Comment.self)
                    // Устанавливаем ID из документа, если он не был декодирован (@DocumentID может не работать без FirestoreSwift)
                    if comment != nil && comment?.id == nil {
                         // comment?.id = doc.documentID // У Comment нет id
                         print("Warning: Comment ID missing after decoding, document ID: \(doc.documentID)")
                    }
                    return comment
                }
                
                completion(.success(comments))
            }
    }

    // Переделываем на completion handlers вместо async/await
    func addComment(_ text: String, for postId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        let postRef = postsCollection.document(postId)
        let commentsCollection = postRef.collection("comments")
        
        // 1. Получаем данные текущего пользователя для денормализации
        userProfileService.fetchUserProfile(userID: currentUserID) { [weak self] result in
            guard let self = self else { 
                completion(NSError(domain: "PostService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])) 
                return 
            }
            
            var username: String = "Unknown"
            var avatarURL: String? = nil
            
            switch result {
            case .success(let userProfile):
                username = userProfile.username
                avatarURL = userProfile.avatarURL // Исправлено
            case .failure(let error):
                print("PostService Error (Add Comment - Fetching User Profile): \(error.localizedDescription)")
                completion(error) // Ошибка получения профиля
                return
            }
            
            // 2. Создаем объект Comment
            // Генерируем ID для нового комментария
            let newCommentRef = commentsCollection.document()
            let commentId = newCommentRef.documentID
            
            let newComment = Comment(
                id: commentId, // Используем сгенерированный ID
                postId: postId,
                authorUid: currentUserID,
                authorUsername: username,
                authorAvatarUrl: avatarURL,
                text: text,
                timestamp: Timestamp() // Используем Timestamp
            )
            
            // 3. Используем транзакцию для добавления комментария и обновления счетчика
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                // Добавляем документ комментария
                do {
                    try transaction.setData(from: newComment, forDocument: newCommentRef)
                } catch let error {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                
                // Обновляем счетчик комментариев в посте
                transaction.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: postRef)
                
                return nil // Успех транзакции
            }) { (object, error) in
                if let error = error {
                    print("PostService Error (Add Comment Transaction): \(error.localizedDescription)")
                } else {
                    print("PostService: Комментарий успешно добавлен к посту \(postId)")
                }
                completion(error) // Вызываем completion в любом случае
            }
        }
    }
    
    // Обновленный метод для создания поста с указанием соотношения сторон
    func createPostWithAspectRatio(imageURL: String, caption: String?, aspectRatio: String, completion: @escaping (Error?) -> Void) {
        print("🔶 PostService: Начинаем создание поста с aspectRatio: \(aspectRatio)")
        guard let currentUserID = authService.currentUserID else {
            print("❌ PostService: Ошибка - пользователь не авторизован")
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        print("🔶 PostService: Получаем данные пользователя \(currentUserID)")
        // 1. Получаем данные текущего пользователя для денормализации
        userProfileService.fetchUserProfile(userID: currentUserID) { [weak self] result in
            guard let self = self else {
                print("❌ PostService: Ошибка - self потерян")
                return
            }
            
            switch result {
            case .success(let user):
                print("🔶 PostService: Получены данные пользователя. username: \(user.username), avatarURL: \(user.avatarURL ?? "nil")")
                // Создаем MediaItemDTO
                let mediaItemDTO = MediaItemDTO(type: .image, url: imageURL)
                
                // 2. Создаем объект Post с данными автора
                let newPost = Post(
                    userID: currentUserID,
                    mediaItems: [mediaItemDTO], // Используем массив из одного MediaItemDTO
                    feedAspectRatio: aspectRatio, // Используем переданное соотношение сторон
                    gridThumbnailURL: imageURL, // Используем то же изображение для миниатюры
                    caption: caption,
                    createdAt: Timestamp(),
                    likeCount: 0,
                    commentCount: 0,
                    authorUsername: user.username, // <-- Денормализация
                    authorAvatarURL: user.avatarURL) // <-- Денормализация
                
                print("🔶 PostService: Создан объект Post с aspectRatio \(aspectRatio), сохраняем в Firestore")
                // 3. Сохраняем пост в Firestore
                do {
                    _ = try self.postsCollection.addDocument(from: newPost) { error in
                        if let error = error {
                            print("❌ PostService Error (Create - Firestore Add): \(error.localizedDescription)")
                        } else {
                            print("✅ PostService: Пост успешно сохранен в Firestore")
                        }
                        completion(error)
                    }
                } catch let error {
                    print("❌ PostService Error (Encoding Post): \(error.localizedDescription)")
                    completion(error)
                }
                
            case .failure(let error):
                print("❌ PostService Error (Create - Fetching User Profile): \(error.localizedDescription)")
                completion(error) // Ошибка получения профиля = ошибка создания поста
            }
        }
    }
} 
