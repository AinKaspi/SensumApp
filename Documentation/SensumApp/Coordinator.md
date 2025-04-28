Файл: Coordinator.swift
Название файла: Coordinator.swift
Назначение файла: Определение базового протокола Coordinator и связанных протоколов делегатов.
Описание: Содержит протокол Coordinator, который определяет основной интерфейс для всех координаторов навигации в приложении (наличие navigationController, массива childCoordinators и метода start()). Также содержит extension с базовой реализацией добавления/удаления дочерних координаторов. В этот файл были также перенесены протоколы EditProfileViewControllerDelegate и EditProfileViewModelDelegate для обеспечения их глобальной доступности. Используется всеми классами-координаторами (AppCoordinator, FeedCoordinator и т.д.).
Содержит: Протокол Coordinator, extension Coordinator, протокол EditProfileViewControllerDelegate, протокол EditProfileViewModelDelegate.
Технологии: UIKit, Foundation.
Путь: Используется как базовый тип/интерфейс при создании и управлении всеми координаторами в приложении, начиная с AppCoordinator.
