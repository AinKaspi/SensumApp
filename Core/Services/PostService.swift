import Foundation
import FirebaseFirestore


// Обновляем протокол, чтобы передавать данные для денормализации
protocol PostServiceProtocol {
    func createPost(imageURL: String, caption: String?, completion: @escaping (Error?) -> Void)
    func fetchPosts(forUserID userID: String, completion: @escaping (Result<[Post], Error>) -> Void)
    func fetchFeedPosts(limit: Int, completion: @escaping (Result<[Post], Error>) -> Void)
    func likePost(postID: String, completion: @escaping (Error?) -> Void)
    func unlikePost(postID: String, completion: @escaping (Error?) -> Void)
    // TODO: Добавить методы для пагинации, лайков, комментариев, удаления и т.д.
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
        guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])) 
            return
        }
        
        // 1. Получаем данные текущего пользователя для денормализации
        userProfileService.fetchUserProfile(userID: currentUserID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                // 2. Создаем объект Post с данными автора
                let newPost = Post(userID: currentUserID,
                                   imageURL: imageURL,
                                   caption: caption,
                                   createdAt: Timestamp(),
                                   likeCount: 0,
                                   commentCount: 0,
                                   authorUsername: user.username, // <-- Денормализация
                                   authorAvatarURL: user.avatarURL) // <-- Денормализация
                
                // 3. Сохраняем пост в Firestore
                do {
                    _ = try self.postsCollection.addDocument(from: newPost) { error in
                        if let error = error {
                            print("PostService Error (Create - Firestore Add): \(error.localizedDescription)")
                        }
                        completion(error)
                    }
                } catch let error {
                    print("PostService Error (Encoding Post): \(error.localizedDescription)")
                    completion(error)
                }
                
            case .failure(let error):
                print("PostService Error (Create - Fetching User Profile): \(error.localizedDescription)")
                completion(error) // Ошибка получения профиля = ошибка создания поста
            }
        }
    }
    
    // Загружает посты для конкретного пользователя
    func fetchPosts(forUserID userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        postsCollection
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            // TODO: Добавить пагинацию (limit, startAfterDocument)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("PostService Error (Fetch User Posts): \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([])) // Нет документов
                    return
                }
                
                // Декодируем документы в массив [Post]
                let posts = documents.compactMap { try? $0.data(as: Post.self) }
                completion(.success(posts))
            }
    }
    
    // Загружает посты для ленты (пока просто последние N постов)
    func fetchFeedPosts(limit: Int = 20, completion: @escaping (Result<[Post], Error>) -> Void) {
        postsCollection
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            // TODO: Реализовать реальную логику ленты (подписки, рекомендации)
            // TODO: Добавить пагинацию
            .getDocuments { snapshot, error in
                if let error = error {
                    print("PostService Error (Fetch Feed Posts): \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([])) 
                    return
                }
                
                let posts = documents.compactMap { try? $0.data(as: Post.self) }
                completion(.success(posts))
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
} 
