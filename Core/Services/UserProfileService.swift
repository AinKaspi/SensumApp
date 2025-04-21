import Foundation
import FirebaseFirestore

// Протокол для UserProfileService
protocol UserProfileServiceProtocol {
    func createUserProfile(user: User, completion: @escaping (Error?) -> Void)
    func fetchUserProfile(userID: String, completion: @escaping (Result<User, Error>) -> Void)
    // TODO: Добавить методы для обновления профиля (update), получения нескольких профилей и т.д.
}

class UserProfileService: UserProfileServiceProtocol {
    
    // Ссылка на Firestore
    private let db = Firestore.firestore()
    
    // Получаем ссылку на коллекцию пользователей
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    // Создает документ для нового пользователя
    func createUserProfile(user: User, completion: @escaping (Error?) -> Void) {
        // Убедимся, что ID пользователя не nil (должен быть установлен из Auth)
        guard let userID = user.id else {
            completion(NSError(domain: "UserProfileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])) 
            return
        }
        
        do {
            // Используем userID как ID документа в Firestore
            try usersCollection.document(userID).setData(from: user) {
                error in
                if let error = error {
                     print("UserProfileService Error (Create): \(error.localizedDescription)")
                }
                completion(error)
            }
        } catch let error {
            print("UserProfileService Error (Encoding User): \(error.localizedDescription)")
            completion(error)
        }
    }
    
    // Загружает профиль пользователя по ID
    func fetchUserProfile(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        usersCollection.document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    // Пытаемся декодировать данные в модель User
                    let user = try document.data(as: User.self)
                    completion(.success(user))
                } catch let error {
                    print("UserProfileService Error (Decoding User): \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                let fetchError = error ?? NSError(domain: "UserProfileService", code: -2, userInfo: [NSLocalizedDescriptionKey: "User document not found"]) 
                print("UserProfileService Error (Fetch): \(fetchError.localizedDescription)")
                completion(.failure(fetchError))
            }
        }
    }
    
    // TODO: Метод для обновления
    // func updateUserProfile(userID: String, data: [String: Any], completion: @escaping (Error?) -> Void)
} 