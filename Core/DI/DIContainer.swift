import Foundation
import FirebaseFirestore

// Простой DI Контейнер для управления экземплярами сервисов
class DIContainer {
    
    // Создаем экземпляры сервисов лениво (lazy),
    // чтобы они создавались только при первом обращении к ним.
    // Передаем зависимости между сервисами там, где это необходимо.
    
    lazy var authService: AuthServiceProtocol = AuthService()
    
    lazy var userProfileService: UserProfileServiceProtocol = UserProfileService()
    
    // PostService зависит от AuthService и UserProfileService
    lazy var postService: PostServiceProtocol = PostService(
        authService: self.authService,
        userProfileService: self.userProfileService
    )
    
    // FollowService может зависеть от AuthService и UserProfileService (проверить его init)
    lazy var followService: FollowServiceProtocol = FollowService(
        // authService: self.authService, // Раскомментировать, если нужно
        // userProfileService: self.userProfileService // Раскомментировать, если нужно
    )
    
    lazy var storageService: StorageServiceProtocol = StorageService()
    
    lazy var progressService: ProgressServiceProtocol = ProgressService()
    
    // Добавьте сюда другие сервисы по мере их появления
    // lazy var programService: ProgramServiceProtocol = ProgramService(...)
    // lazy var notificationService: NotificationServiceProtocol = NotificationService(...)
    // lazy var messagingService: MessagingServiceProtocol = MessagingService(...)

    init() {
        print("DIContainer Initialized. Services will be created lazily.")
    }
}
