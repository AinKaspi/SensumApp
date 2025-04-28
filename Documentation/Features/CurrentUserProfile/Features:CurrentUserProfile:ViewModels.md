Папка: Features/CurrentUserProfile/ViewModels
Название папки: ViewModels
Содержит: EditProfileViewModel.swift.
Файл: Features/CurrentUserProfile/ViewModels/EditProfileViewModel.swift
Название файла: EditProfileViewModel.swift
Назначение файла: Логика экрана редактирования профиля.
Описание: Загружает начальные данные пользователя (loadInitialData через UserProfileService). Содержит метод saveProfile, который определяет измененные данные, загружает новый аватар (если выбран) через StorageService, а затем обновляет документ пользователя в Firestore через UserProfileService.updateUserProfile. Управляет состояниями isLoading, errorMessage. Уведомляет координатора о завершении через EditProfileViewModelDelegate.
Содержит: Класс EditProfileViewModel, протокол EditProfileViewModelDelegate, @Published свойства, методы loadInitialData, saveProfile.
Технологии: Combine, Foundation, UIKit (для UIImage).
Путь: Создается в CurrentUserProfileCoordinator.showEditProfile(). Вызывается из EditProfileViewController. Взаимодействует с UserProfileService, StorageService, AuthService.
