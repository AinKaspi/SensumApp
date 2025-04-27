import Foundation
import UIKit // Для UIImage
import Combine
import FirebaseFirestore // Добавляем импорт

// Протокол перенесен в Coordinator.swift
/*
protocol EditProfileViewModelDelegate: AnyObject {
    func editProfileDidFinish(didSave: Bool)
}
*/

class EditProfileViewModel {

    weak var delegate: EditProfileViewModelDelegate?

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let storageService: StorageServiceProtocol

    // MARK: - Published Properties
    // Данные, загруженные изначально
    @Published private(set) var initialUsername: String = ""
    @Published private(set) var initialStatus: String = ""
    @Published private(set) var initialAvatarURL: String? = nil
    // @Published private(set) var initialAvatarImage: UIImage? // Можно добавить для сравнения

    // Состояния UI
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private var currentUserID: String?

    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService(),
         userProfileService: UserProfileServiceProtocol = UserProfileService(),
         storageService: StorageServiceProtocol = StorageService()) {
        self.authService = authService
        self.userProfileService = userProfileService
        self.storageService = storageService
        self.currentUserID = authService.currentUserID
        loadInitialData()
    }

    // MARK: - Data Loading
    func loadInitialData() {
        guard let userID = currentUserID else {
            errorMessage = "Ошибка: Не удалось определить пользователя."
            return
        }

        isLoading = true
        errorMessage = nil

        userProfileService.fetchUserProfile(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.initialUsername = user.username
                    self.initialStatus = user.status ?? ""
                    self.initialAvatarURL = user.avatarURL
                    // TODO: Загрузить UIImage из initialAvatarURL, если нужно для отображения
                    print("EditProfileViewModel: Initial data loaded.")
                case .failure(let error):
                    self.errorMessage = "Не удалось загрузить профиль: \(error.localizedDescription)"
                    print("EditProfileViewModel Error loading profile: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Profile Saving
    func saveProfile(newUsername: String?, newStatus: String?, newAvatarImage: UIImage?) {
        guard let userID = currentUserID else {
            errorMessage = "Ошибка: Не удалось определить пользователя."
            delegate?.editProfileDidFinish(didSave: false) // Уведомляем об ошибке
            return
        }

        isLoading = true
        errorMessage = nil

        // Определяем, что изменилось
        let usernameChanged = newUsername != nil && newUsername != initialUsername
        let statusChanged = newStatus != initialStatus // Сравниваем с initialStatus (nil == пустая строка?)
        let avatarChanged = newAvatarImage != nil // Проверяем, было ли выбрано новое изображение

        // Словарь для обновления данных в Firestore
        var dataToUpdate: [String: Any] = [:]
        if usernameChanged { dataToUpdate[User.CodingKeys.username.rawValue] = newUsername! }
        // Обновляем статус, даже если он стал пустым (приравниваем nil к пустой строке при сохранении)
        if statusChanged { dataToUpdate[User.CodingKeys.status.rawValue] = newStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? FieldValue.delete() }

        // Задача 1: Загрузить аватар, если он изменился
        let uploadAvatarTask: Future<String?, Error> = Future { promise in
            if avatarChanged, let image = newAvatarImage {
                print("EditProfileViewModel: Uploading new avatar...")
                self.storageService.uploadAvatarImage(image, forUserID: userID) { result in
                    switch result {
                    case .success(let url):
                        print("EditProfileViewModel: Avatar uploaded successfully. URL: \(url.absoluteString)")
                        promise(.success(url.absoluteString))
                    case .failure(let error):
                        print("EditProfileViewModel Error uploading avatar: \(error.localizedDescription)")
                        promise(.failure(error))
                    }
                }
            } else {
                // Аватар не менялся, возвращаем nil (URL не изменился)
                promise(.success(nil))
            }
        }

        // Задача 2: Обновить профиль в Firestore после загрузки аватара (если нужно)
        uploadAvatarTask
            .receive(on: DispatchQueue.main) // Переключаемся на главный поток для обновления UI/dataToUpdate
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.isLoading = false
                    self.errorMessage = "Ошибка сохранения аватара: \(error.localizedDescription)"
                    self.delegate?.editProfileDidFinish(didSave: false) // Уведомляем об ошибке
                }
                // Успешное завершение Future (даже если аватар не загружался) обрабатывается в receiveValue
            }, receiveValue: { [weak self] newAvatarURL in
                guard let self = self else { return }

                // Добавляем новый URL аватара в данные для обновления, если он есть
                if let url = newAvatarURL {
                    dataToUpdate[User.CodingKeys.avatarURL.rawValue] = url
                }

                // Проверяем, есть ли вообще что обновлять
                if dataToUpdate.isEmpty {
                    print("EditProfileViewModel: No changes detected. Finishing.")
                    self.isLoading = false
                    self.delegate?.editProfileDidFinish(didSave: false) // Изменений не было
                    return
                }

                // Вызываем обновление UserProfileService
                print("EditProfileViewModel: Updating profile in Firestore...")
                self.userProfileService.updateUserProfile(userID: userID, data: dataToUpdate) { [weak self] error in
                    // Обновляем UI на главном потоке
                    DispatchQueue.main.async {
                         guard let self = self else { return }
                         self.isLoading = false
                         if let error = error {
                             self.errorMessage = "Ошибка сохранения профиля: \(error.localizedDescription)"
                             print("EditProfileViewModel Error updating profile: \(error.localizedDescription)")
                             self.delegate?.editProfileDidFinish(didSave: false)
                         } else {
                             print("EditProfileViewModel: Profile updated successfully.")
                             self.delegate?.editProfileDidFinish(didSave: true) // Успешно сохранено
                         }
                    }
                }
            })
            .store(in: &cancellables)
    }
}

// Требуется добавить метод updateUserProfile в UserProfileServiceProtocol и его реализацию
