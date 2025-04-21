import Foundation
import FirebaseFirestore

// Протокол для FollowService
protocol FollowServiceProtocol {
    func follow(userIDToFollow: String, completion: @escaping (Error?) -> Void)
    func unfollow(userIDToUnfollow: String, completion: @escaping (Error?) -> Void)
    func checkIfFollowing(userID: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func fetchFollowers(forUserID userID: String, completion: @escaping (Result<[String], Error>) -> Void) // Возвращает массив ID
    func fetchFollowing(forUserID userID: String, completion: @escaping (Result<[String], Error>) -> Void) // Возвращает массив ID
}

class FollowService: FollowServiceProtocol {
    
    private let db = Firestore.firestore()
    private let authService: AuthServiceProtocol // Нужен для получения ID текущего пользователя
    
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    // Текущий пользователь подписывается на userIDToFollow
    func follow(userIDToFollow: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "FollowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user not logged in"]))
            return
        }
        
        // Нельзя подписаться на самого себя
        guard currentUserID != userIDToFollow else {
            completion(NSError(domain: "FollowService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot follow yourself"]))
            return
        }
        
        let batch = db.batch()
        
        // 1. Добавляем userIDToFollow в подколлекцию 'following' текущего пользователя
        let currentUserFollowingRef = usersCollection.document(currentUserID).collection("following").document(userIDToFollow)
        batch.setData(["timestamp": Timestamp()], forDocument: currentUserFollowingRef) // Просто ставим метку времени
        
        // 2. Добавляем currentUserID в подколлекцию 'followers' пользователя userIDToFollow
        let followedUserFollowersRef = usersCollection.document(userIDToFollow).collection("followers").document(currentUserID)
        batch.setData(["timestamp": Timestamp()], forDocument: followedUserFollowersRef)
        
        // 3. Обновляем счетчики (Increment)
        let currentUserRef = usersCollection.document(currentUserID)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
        
        let followedUserRef = usersCollection.document(userIDToFollow)
        batch.updateData(["followerCount": FieldValue.increment(Int64(1))], forDocument: followedUserRef)
        
        // Выполняем batch write
        batch.commit { error in
            if let error = error {
                print("FollowService Error (Follow Batch): \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    // Текущий пользователь отписывается от userIDToUnfollow
    func unfollow(userIDToUnfollow: String, completion: @escaping (Error?) -> Void) {
         guard let currentUserID = authService.currentUserID else {
            completion(NSError(domain: "FollowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user not logged in"]))
            return
        }
        
        let batch = db.batch()
        
        // 1. Удаляем userIDToUnfollow из 'following' текущего пользователя
        let currentUserFollowingRef = usersCollection.document(currentUserID).collection("following").document(userIDToUnfollow)
        batch.deleteDocument(currentUserFollowingRef)
        
        // 2. Удаляем currentUserID из 'followers' пользователя userIDToUnfollow
        let unfollowedUserFollowersRef = usersCollection.document(userIDToUnfollow).collection("followers").document(currentUserID)
        batch.deleteDocument(unfollowedUserFollowersRef)
        
        // 3. Обновляем счетчики (Decrement)
        let currentUserRef = usersCollection.document(currentUserID)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
        
        let unfollowedUserRef = usersCollection.document(userIDToUnfollow)
        batch.updateData(["followerCount": FieldValue.increment(Int64(-1))], forDocument: unfollowedUserRef)
        
        batch.commit { error in
            if let error = error {
                print("FollowService Error (Unfollow Batch): \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    // Проверяет, подписан ли текущий пользователь на userID
    func checkIfFollowing(userID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUserID = authService.currentUserID else {
            completion(.failure(NSError(domain: "FollowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user not logged in"])))
            return
        }
        
        usersCollection.document(currentUserID).collection("following").document(userID).getDocument { (document, error) in
            if let error = error {
                // Если ошибка не 'документ не найден', то это реальная ошибка
                if (error as NSError).code != FirestoreErrorCode.notFound.rawValue {
                     print("FollowService Error (Check Following): \(error.localizedDescription)")
                     completion(.failure(error))
                     return
                 }
            }
            // Если документ существует (даже без ошибки), значит подписан
            completion(.success(document?.exists ?? false))
        }
    }
    
    // Загружает список ID подписчиков пользователя
    func fetchFollowers(forUserID userID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        fetchIDs(from: usersCollection.document(userID).collection("followers"), completion: completion)
    }
    
    // Загружает список ID тех, на кого подписан пользователь
    func fetchFollowing(forUserID userID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        fetchIDs(from: usersCollection.document(userID).collection("following"), completion: completion)
    }
    
    // Вспомогательный метод для загрузки ID из коллекции
    private func fetchIDs(from collectionRef: CollectionReference, completion: @escaping (Result<[String], Error>) -> Void) {
        collectionRef.getDocuments { snapshot, error in
            if let error = error {
                print("FollowService Error (Fetch IDs): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            completion(.success(ids))
        }
    }
} 
