import Foundation
import FirebaseStorage
import UIKit // Для UIImage

// Протокол для StorageService
protocol StorageServiceProtocol {
    // Загружает изображение и возвращает URL для скачивания
    func uploadImage(_ image: UIImage, directory: String, completion: @escaping (Result<URL, Error>) -> Void) -> StorageUploadTask?
    // TODO: Добавить метод для загрузки по URL?
    // func downloadImage(from url: URL, completion: ...)
    // ✅ Добавляем метод для удаления файла по URL
    func deleteFile(at url: URL, completion: @escaping (Error?) -> Void)
    func uploadPostImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void)
    // Добавляем метод для загрузки аватара
    func uploadAvatarImage(_ image: UIImage, forUserID userID: String, completion: @escaping (Result<URL, Error>) -> Void)
}

class StorageService: StorageServiceProtocol {
    
    // Ссылка на Firebase Storage
    private let storage = Storage.storage()
    
    // Базовая ссылка на хранилище
    private var storageReference: StorageReference {
        return storage.reference()
    }
    
    // Загружает изображение
    func uploadImage(_ image: UIImage, directory: String, completion: @escaping (Result<URL, Error>) -> Void) -> StorageUploadTask? {
        // Генерируем уникальное имя файла
        let filename = UUID().uuidString + ".jpg"
        // Создаем ссылку на путь в Storage: /<directory>/<filename>
        let fileRef = storageReference.child(directory).child(filename)
        
        // Конвертируем UIImage в JPEG данные с умеренным сжатием
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"]))) 
            return nil
        }
        
        // Создаем метаданные (тип контента)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Начинаем загрузку
        let uploadTask = fileRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("StorageService Error (Upload): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Получаем URL для скачивания после успешной загрузки
            fileRef.downloadURL { url, error in
                if let downloadURL = url {
                    print("StorageService: Image uploaded successfully to \(downloadURL)")
                    completion(.success(downloadURL))
                } else {
                    let urlError = error ?? NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    print("StorageService Error (Get URL): \(urlError.localizedDescription)")
                    completion(.failure(urlError))
                }
            }
        }
        
        // Возвращаем задачу загрузки, чтобы можно было отслеживать прогресс или отменять
        return uploadTask
    }
    
    // MARK: - Post Images
    func uploadPostImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        print("🔷 StorageService: Начинаем загрузку изображения поста")
        // Генерируем уникальное имя файла
        let filename = UUID().uuidString + ".jpg"
        // Указываем путь в Storage (например, папка "post_images")
        let storageRef = storage.reference().child("post_images").child(filename)
        print("🔷 StorageService: Путь для загрузки: post_images/\(filename)")
        
        // Конвертируем UIImage в Data (с сжатием)
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("❌ StorageService: Ошибка конвертации изображения в JPEG")
            completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
            return
        }
        print("🔷 StorageService: Изображение сжато, размер данных: \(imageData.count) байт")
        
        // Создаем метаданные (тип контента)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Загружаем данные
        print("🔷 StorageService: Начинаем загрузку данных в Firebase Storage")
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ StorageService Error (Upload Post Image): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("🔷 StorageService: Данные загружены, получаем URL для скачивания")
            // Получаем URL для скачивания
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ StorageService Error (Get Download URL for Post): \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let url = url {
                    print("✅ StorageService: Изображение успешно загружено. URL: \(url)")
                    completion(.success(url))
                } else {
                    print("❌ StorageService: Не удалось получить URL загруженного изображения")
                    completion(.failure(NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
    }
    
    // MARK: - Avatar Images
    
    // Реализация метода для загрузки аватара
    func uploadAvatarImage(_ image: UIImage, forUserID userID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // Используем userID как имя файла для простоты (или можно добавить UUID)
        let filename = userID + ".jpg" // Или \(userID)_avatar.jpg
        // Путь к аватарам
        let storageRef = storage.reference().child("avatars").child(filename)
        
        // Конвертируем UIImage в Data (можно использовать PNG или JPEG)
        // Для аватаров часто лучше PNG без потерь, но размер больше
        // guard let imageData = image.pngData() else { ... }
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert avatar image to JPEG data"])))
            return
        }
        
        // Загружаем данные
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("StorageService Error (Upload Avatar): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Получаем URL для скачивания
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("StorageService Error (Get Download URL for Avatar): \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let url = url {
                    print("StorageService: Avatar image uploaded successfully for user \(userID). URL: \(url)")
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL for avatar"])))
                }
            }
        }
    }
    
    // MARK: - File Deletion
    
    func deleteFile(at url: URL, completion: @escaping (Error?) -> Void) {
        // Получаем ссылку на файл в Storage по его URL
        let storageRef = storage.reference(forURL: url.absoluteString)
        
        print("🗑️ StorageService: Attempting to delete file at URL: \(url.absoluteString)")
        
        storageRef.delete { error in
            if let error = error {
                // Проверяем, не является ли ошибка 'object not found' (код 404)
                // В Firebase Storage ошибка 'object not found' имеет код -13010 в домене StorageErrorDomain
                let nsError = error as NSError
                if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    print("⚠️ StorageService: File not found at URL \(url.absoluteString), considering deletion successful.")
                    completion(nil) // Считаем успешным, если файла и так нет
                } else {
                    print("❌ StorageService Error (Delete File): \(error.localizedDescription)")
                    completion(error)
                }
            } else {
                print("✅ StorageService: File deleted successfully at URL: \(url.absoluteString)")
                completion(nil)
            }
        }
    }
} 