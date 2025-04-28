Файл: Core/Services/StorageService.swift
Название файла: StorageService.swift
Назначение файла: Управление загрузкой/скачиванием файлов в Firebase Storage.
Описание: Предоставляет методы для загрузки изображений постов (uploadPostImage) и аватаров (uploadAvatarImage). Загружает UIImage (конвертируя в Data) в указанную папку (post_images или avatars) и возвращает URL для скачивания.
Содержит: Протокол StorageServiceProtocol, класс StorageService, методы uploadPostImage, uploadAvatarImage. (Содержит также общий метод uploadImage, который не используется напрямую в протоколе).
Технологии: Foundation, FirebaseStorage, UIKit.
Путь: Создается в DIContainer. Используется CreatePostViewModel (для uploadPostImage), EditProfileViewModel (для uploadAvatarImage).
