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
    // Удаляем старый метод createPost
    // func createPost(imageURL: String, caption: String?, completion: @escaping (Error?) -> Void)
    // Удаляем старый метод createPostWithAspectRatio
    // func createPostWithAspectRatio(imageURL: String, caption: String?, aspectRatio: String, completion: @escaping (Error?) -> Void)
    
    // Новый метод для создания поста с несколькими медиа и параметрами
    func createPost(mediaItems: [MediaItemDTO], feedAspectRatio: String, gridThumbnailURL: String, caption: String?, completion: @escaping (Error?) -> Void)
    
    func fetchPosts(forUserID userID: String, limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void)
    func fetchFeedPosts(limit: Int, startingAfter lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (Result<(posts: [Post], lastSnapshot: DocumentSnapshot?), Error>) -> Void)
    func likePost(postID: String, completion: @escaping (Error?) -> Void)
    func unlikePost(postID: String, completion: @escaping (Error?) -> Void)
    // TODO: Добавить методы для пагинации, лайков, комментариев, удаления и т.д.
    
    // MARK: - Comments
    // Новый протокол для комментов
    // Удаляем старый fetchComments
    // func fetchComments(for postId: String, completion: @escaping (Result<[Comment], Error>) -> Void)
    // Добавляем метод для прослушивания комментариев
    func listenForComments(for postId: String, listener: @escaping (Result<[Comment], Error>) -> Void) -> ListenerRegistration?
    // Изменяем completion, чтобы возвращать добавленный комментарий
    func addComment(_ text: String, for postId: String, parentCommentId: String?, completion: @escaping (Result<Comment, Error>) -> Void)
    
    // Удаляем дубликат createPostWithAspectRatio из конца протокола
    // func createPostWithAspectRatio(imageURL: String, caption: String?, aspectRatio: String, completion: @escaping (Error?) -> Void)
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
    
    // Удаляем реализацию старого метода createPost(imageURL:caption:completion:)
    /*
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
    */

    // Удаляем реализацию старого метода createPostWithAspectRatio
    /*
    // Обновленный метод для создания поста с указанием соотношения сторон
    func createPostWithAspectRatio(imageURL: String, caption: String?, aspectRatio: String, completion: @escaping (Error?) -> Void) {
        print("🔶 PostService: Начинаем создание поста с AspectRatio: \(aspectRatio)")
        guard let currentUserID = authService.currentUserID else {
            print("❌ PostService: Ошибка - пользователь не авторизован")
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }

        print("🔶 PostService: Получаем данные пользователя \(currentUserID)")
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

                let newPost = Post(
                    userID: currentUserID,
                    mediaItems: [mediaItemDTO], // Используем массив
                    feedAspectRatio: aspectRatio, // Используем переданный aspectRatio
                    gridThumbnailURL: imageURL, // Пока используем то же изображение
                    caption: caption,
                    createdAt: Timestamp(),
                    likeCount: 0,
                    commentCount: 0,
                    authorUsername: user.username,
                    authorAvatarURL: user.avatarURL
                )

                print("🔶 PostService: Создан объект Post с aspectRatio, сохраняем в Firestore")
                do {
                    _ = try self.postsCollection.addDocument(from: newPost) { error in
                        if let error = error {
                            print("❌ PostService Error (Create w/ AR - Firestore Add): \(error.localizedDescription)")
                        } else {
                            print("✅ PostService: Пост с aspectRatio успешно сохранен")
                        }
                        completion(error)
                    }
                } catch let error {
                    print("❌ PostService Error (Encoding Post w/ AR): \(error.localizedDescription)")
                    completion(error)
                }

            case .failure(let error):
                print("❌ PostService Error (Create w/ AR - Fetching User Profile): \(error.localizedDescription)")
                completion(error)
            }
        }
    }
    */
    
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

            let posts = documents.compactMap { doc -> Post? in
                var post = try? doc.data(as: Post.self)
                post?.id = doc.documentID // <-- Добавляем ID вручную
                return post
            }
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
            let posts = documents.compactMap { doc -> Post? in
                var post = try? doc.data(as: Post.self)
                post?.id = doc.documentID // <-- Добавляем ID вручную
                return post
            }
            
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
    
    // Реализуем метод для прослушивания комментариев
    func listenForComments(for postId: String, listener: @escaping (Result<[Comment], Error>) -> Void) -> ListenerRegistration? {
        let commentsCollection = postsCollection.document(postId).collection("comments")
        
        // Создаем listener
        let registration = commentsCollection
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ PostService Error (Listen Comments): \(error.localizedDescription)")
                    listener(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    // Если нет ошибки, но нет и документов, возвращаем пустой массив
                    print("ℹ️ PostService (Listen Comments): Snapshot exists but no documents found for postId \(postId).")
                    listener(.success([]))
                    return
                }
                
                // Теперь декодируем напрямую в модель Comment
                let comments = documents.compactMap { doc -> Comment? in
                    var comment = try? doc.data(as: Comment.self)
                    // ВАЖНО: Устанавливаем ID из документа вручную
                    if comment != nil && comment?.id == nil {
                        comment?.id = doc.documentID
                    }
                    return comment
                }
                
                // Отправляем обновленный список комментариев подписчику
                listener(.success(comments))
            }
        
        return registration // Возвращаем регистрацию для возможности отмены
    }

    // Обновляем сигнатуру и логику completion
    func addComment(_ text: String, for postId: String, parentCommentId: String? = nil, completion: @escaping (Result<Comment, Error>) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            // Оборачиваем ошибку в .failure
            completion(.failure(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))) 
            return
        }
        
        let postRef = postsCollection.document(postId)
        let commentsCollection = postRef.collection("comments")
        
        // 1. Получаем данные текущего пользователя для денормализации
        userProfileService.fetchUserProfile(userID: currentUserID) { [weak self] result in
            guard let self = self else { 
                // Оборачиваем ошибку в .failure
                completion(.failure(NSError(domain: "PostService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))) 
                return 
            }
            
            switch result {
            case .success(let userProfile):
                // 2. Создаем объект Comment
                // Генерируем ID для нового комментария
                let newCommentRef = commentsCollection.document()
                let commentId = newCommentRef.documentID
                
                // Создаем комментарий с новой структурой
                let newComment = Comment(
                    id: commentId,
                    postId: postId,
                    userId: currentUserID,
                    text: text,
                    timestamp: Timestamp(),
                    user: userProfile,
                    parentCommentId: parentCommentId // Добавляем ID родительского комментария
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
                        print("❌ PostService Error (Add Comment Transaction): \(error.localizedDescription)")
                        completion(.failure(error)) // Возвращаем ошибку
                    } else {
                        if let parentId = parentCommentId {
                            print("✅ PostService: Ответ на комментарий \(parentId) успешно добавлен к посту \(postId)")
                        } else {
                            print("✅ PostService: Комментарий успешно добавлен к посту \(postId)")
                        }
                        completion(.success(newComment)) // Возвращаем успешный результат с комментарием
                    }
                }
                
            case .failure(let error):
                print("PostService Error (Add Comment - Fetching User Profile): \(error.localizedDescription)")
                // Оборачиваем ошибку в .failure
                completion(.failure(error)) // Ошибка получения профиля
                return
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

    // Новый метод создания поста
    func createPost(mediaItems: [MediaItemDTO], feedAspectRatio: String, gridThumbnailURL: String, caption: String?, completion: @escaping (Error?) -> Void) {
        print("🔶 PostService: Начинаем создание нового поста (v2) с \(mediaItems.count) медиа, AR: \(feedAspectRatio), Thumbnail: \(gridThumbnailURL)")
        guard let currentUserID = authService.currentUserID else {
            print("❌ PostService: Ошибка - пользователь не авторизован")
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        guard !mediaItems.isEmpty else {
            print("❌ PostService: Ошибка - нет медиа для поста")
            completion(NSError(domain: "PostService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No media items provided"]))
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
                
                // 2. Создаем объект Post со всеми данными
                let newPost = Post(
                    userID: currentUserID,
                    mediaItems: mediaItems, // Используем переданный массив
                    feedAspectRatio: feedAspectRatio, // Используем переданное значение
                    gridThumbnailURL: gridThumbnailURL, // Используем переданное значение
                    caption: caption,
                    createdAt: Timestamp(), // Текущее время
                    likeCount: 0,
                    commentCount: 0,
                    authorUsername: user.username, // Денормализация
                    authorAvatarURL: user.avatarURL // Денормализация
                )
                
                print("🔶 PostService: Создан объект Post, сохраняем в Firestore")
                // 3. Сохраняем пост в Firestore
                do {
                    // Используем Codable для сохранения
                    _ = try self.postsCollection.addDocument(from: newPost) { error in
                        if let error = error {
                            print("❌ PostService Error (Create v2 - Firestore Add): \(error.localizedDescription)")
                        } else {
                            print("✅ PostService: Пост (v2) успешно сохранен в Firestore")
                        }
                        completion(error)
                    }
                } catch let error {
                    print("❌ PostService Error (Encoding Post v2): \(error.localizedDescription)")
                    completion(error)
                }
                
            case .failure(let error):
                print("❌ PostService Error (Create v2 - Fetching User Profile): \(error.localizedDescription)")
                completion(error) // Ошибка получения профиля = ошибка создания поста
            }
        }
    }
}
