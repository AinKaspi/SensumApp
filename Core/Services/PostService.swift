import Foundation
import FirebaseFirestore

// Протокол для PostService
protocol PostServiceProtocol {
    func createPost(post: Post, completion: @escaping (Error?) -> Void)
    func fetchPosts(forUserID userID: String, completion: @escaping (Result<[Post], Error>) -> Void)
    func fetchFeedPosts(limit: Int, completion: @escaping (Result<[Post], Error>) -> Void)
    // TODO: Добавить методы для пагинации, лайков, комментариев, удаления и т.д.
}

class PostService: PostServiceProtocol {
    
    private let db = Firestore.firestore()
    
    private var postsCollection: CollectionReference {
        return db.collection("posts")
    }
    
    // Создает пост
    func createPost(post: Post, completion: @escaping (Error?) -> Void) {
        do {
            // Firestore автоматически сгенерирует ID для нового документа
            _ = try postsCollection.addDocument(from: post) { error in
                if let error = error {
                    print("PostService Error (Create): \(error.localizedDescription)")
                }
                completion(error)
            }
        } catch let error {
            print("PostService Error (Encoding Post): \(error.localizedDescription)")
            completion(error)
        }
    }
    
    // Загружает посты для конкретного пользователя
    func fetchPosts(forUserID userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        postsCollection
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true) // Сортируем по дате
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
} 