# Дорожная карта SensumApp - Социальная Платформа

## Концептуальное Дерево Архитектуры (Планируемое)

```
SensumApp/
|-- App/
|   |-- AppDelegate.swift
|   |-- SceneDelegate.swift  (Содержит AppCoordinator)
|   +-- Coordinator.swift    (Базовый протокол)
|
|-- Core/
|   |-- Models/              (User.swift, Post.swift, Follow.swift, Stats.swift, etc.)
|   |-- Networking/          (APIService.swift, FirebaseService.swift, etc.)
|   |-- Services/            (AuthService.swift, StorageService.swift, FeedService.swift, etc.)
|   +-- Utils/               (Extensions, Helpers, etc.)
|
|-- Features/
|   |-- Authentication/      (Флоу входа/регистрации)
|   |   |-- Coordinators/    (AuthCoordinator.swift)
|   |   |-- Scenes/
|   |   |   |-- Login/       (LoginViewController.swift, LoginViewModel.swift)
|   |   |   +-- Register/    (RegisterViewController.swift, RegisterViewModel.swift)
|   |
|   |-- Feed/                (Таб 1: Лента)
|   |   |-- Coordinators/    (FeedCoordinator.swift)
|   |   |-- Scenes/
|   |   |   +-- FeedList/    (FeedViewController.swift, FeedViewModel.swift)
|   |   +-- Views/           (StoryCircleCell.swift, PostCell.swift, etc.)
|   |
|   |-- UserProfile/         (Экраны для профиля *ДРУГОГО* пользователя - НЕ в таббаре)
|   |   |-- Coordinators/    (UserProfileCoordinator.swift - запускается из Feed)
|   |   |-- Scenes/
|   |   |   |-- Container/   (UserProfileContainerViewController.swift - управляет Card/Person/Stats)
|   |   |   |-- Card/        (UserProfileCardViewController.swift - старый ProfileVC, макет 2)
|   |   |   |-- FeedGrid/    (UserProfileFeedViewController.swift - макет 3, ПЕРЕИСПОЛЬЗУЕТСЯ!)
|   |   |   +-- Stats/       (UserProfileStatsViewController.swift - макет 4)
|   |   +-- Views/           (TopMenuView.swift - используется в Container)
|   |
|   |-- CurrentUserProfile/  (Таб 2: Профиль Текущего Пользователя)
|   |   |-- Coordinators/    (CurrentUserProfileCoordinator.swift)
|   |   |-- Scenes/          (Использует UserProfileFeedViewController, UserProfileStatsViewController)
|   |   |   +-- Container?/  (Возможно, нужен свой контейнер или доп. логика)
|   |
|   |-- Create/              (Таб 3: Создать - Пока заменен на Leveling)
|   |   |-- ... (Заглушка)
|   |
|   |-- Leveling/            (Таб 3: Тренировки)
|   |   |-- Coordinators/    (LevelingCoordinator.swift)
|   |   |-- Scenes/          (ExerciseSelectionViewController.swift, ExerciseExecutionViewController.swift)
|   |   +-- ... (ViewModels, Helpers, Views)
|   |
|   |-- Progress/            (Таб 4: Прогресс - Заглушка)
|   |   |-- Coordinators/    (ProgressCoordinator.swift)
|   |   +-- Scenes/          (ProgressViewController.swift)
|   |
|   |-- Store/               (Таб 5: Магазин - Заглушка)
|   |   |-- Coordinators/    (StoreCoordinator.swift)
|   |   +-- Scenes/          (StoreViewController.swift)
|   |
|   +-- Messaging/           (Позже: Чаты)
|       |-- Coordinators/    (MessagingCoordinator.swift)
|       +-- Scenes/          (ChatListViewController.swift, ChatViewController.swift)
```

## Phase 1: Refactoring & Setup (Приоритет!)

*Цель: Перестроить структуру проекта под новую концепцию, переименовать компоненты, настроить базовые координаторы для всех вкладок.*

-   [ ] **Rename Feature:** Rename folder `Features/Person` -> `Features/UserProfile`. (Выполнено пользователем)
-   [ ] **Rename/Create UserProfile Components (Модальный профиль другого пользователя):**
    -   [x] Rename `PersonCoordinator` -> `UserProfileCoordinator` (file & class). (Выполнено)
    -   [x] Rename `PersonContainerViewController` -> `UserProfileContainerViewController` (file & class). (Выполнено)
    -   [x] Rename `ProfileViewController` -> `UserProfileCardViewController` (file & class, Макет 2). (Выполнено)
    -   [ ] Rename `StatsViewController` -> `UserProfileStatsViewController` (file & class, Макет 4).
    -   [ ] Create placeholder `UserProfileFeedViewController.swift` (file & class, Макет 3).
    -   [ ] Update `UserProfileContainerViewController` to manage Card/Person/Stats VCs.
    -   [ ] Update `TopMenuView.swift` segments: "Card", "Person", "Stats". Add back arrow delegate?.
-   [ ] **Create Feed Components (Tab 1 - Placeholders):**
    -   [ ] Create folder `Features/Feed`.
    -   [ ] Create `FeedCoordinator.swift` (file & class).
    -   [ ] Create `FeedViewController.swift` (file & class).
-   [ ] **Create CurrentUserProfile Components (Tab 2 - Placeholders):**
    -   [ ] Create folder `Features/CurrentUserProfile`.
    -   [ ] Create `CurrentUserProfileCoordinator.swift` (file & class).
    -   [ ] Create placeholder `CurrentUserProfileContainerViewController.swift`? (Or use `UserProfileFeedVC` directly).
-   [ ] **Verify/Update Leveling Components (Tab 3):**
    -   [ ] Verify `Features/Leveling` exists.
    *   [ ] Verify `LevelingCoordinator.swift` exists (update if needed).
    *   [ ] Verify `ExerciseSelectionViewController.swift` & `ExerciseExecutionViewController.swift` exist.
-   [ ] **Create Progress Components (Tab 4 - Placeholders):**
    *   [ ] Create folder `Features/Progress`.
    *   [ ] Create `ProgressCoordinator.swift` (file & class).
    *   [ ] Create `ProgressViewController.swift` (file & class).
-   [ ] **Verify/Update Store Components (Tab 5 - Placeholders):**
    *   [ ] Verify `Features/Store` exists.
    *   [ ] Verify `StoreCoordinator.swift` exists (update if needed).
    *   [ ] Verify `StoreViewController.swift` exists.
-   [ ] **Update AppCoordinator (`SceneDelegate.swift`):**
    *   [ ] Configure `UITabBarController` with: `FeedCoordinator`, `CurrentUserProfileCoordinator`, `LevelingCoordinator`, `ProgressCoordinator`, `StoreCoordinator`.
    *   [ ] Ensure all coordinators are initialized and started correctly.
-   [ ] **Update Imports & References:** Systematically fix all broken imports and class/file references project-wide after renames.
-   [ ] **Delete Unused Files:** Delete `SensumApp/ViewController.swift`.
-   [ ] **Build & Test:** Ensure the app compiles and runs with the new structure (mostly placeholders).

## Phase 2: Backend & Authentication

*Цель: Настроить Firebase, реализовать вход и регистрацию.*

-   [ ] Настроить Firebase Project (Auth, Firestore, Storage).
-   [ ] Реализовать `AuthService`.
-   [ ] Создать `AuthCoordinator`.
-   [ ] Реализовать `AppCoordinator` для запуска `AuthCoordinator`.
-   [ ] Создать UI и ViewModel для Login/Register (Email/Password, Google Sign-In).

## Phase 3: Core Models & Services

*Цель: Определить структуру данных и сервисы для взаимодействия с бэкендом.*

-   [ ] Определить Firestore Модели (`User`, `Post` - фото+текст, `Follow`, `Stats`).
-   [ ] Создать `StorageService`.
-   [ ] Создать `UserProfileService`.
-   [ ] Создать `PostService`.
-   [ ] Создать `FollowService`.
-   [ ] Создать `FeedService`.

## Phase 4: Feature Implementation - Feed & CurrentUserProfile

*Цель: Реализовать основные экраны - ленту и профиль текущего пользователя.*

-   [ ] **Feed (Tab 1):** UI ленты, "сторис", ViewModel, загрузка данных, навигация на `UserProfileCoordinator`.
-   [ ] **CurrentUserProfile (Tab 2):** Координатор, переиспользование `UserProfileFeedViewController`, отображение данных текущего юзера, настройка UI (Edit).

## Phase 5: Feature Implementation - UserProfile (Modal)

*Цель: Реализовать показ профиля другого пользователя.*

-   [ ] Реализация `UserProfileContainerViewController` (слайдер Card/Person/Stats).
-   [ ] Реализация `UserProfileCardViewController` (Макет 2).
-   [ ] Реализация `UserProfileFeedViewController` (Макет 3) - переиспользование.
-   [ ] Реализация `UserProfileStatsViewController` (Макет 4).
-   [ ] Настроить представление/переход из `FeedCoordinator`.

## Phase 6: Other Tabs & Features

*Цель: Реализовать заглушки/базовый функционал остальных вкладок и фич.*

-   [ ] Leveling (Tab 3) - Интеграция существующей логики.
-   [ ] Progress (Tab 4) - Базовый UI.
-   [ ] Store (Tab 5) - Базовый UI.
-   [ ] Create (Центральная кнопка) - Базовый UI/флоу (Заменен на Leveling).
-   [ ] Сообщения (иконка в Feed) - Базовый UI.
-   [ ] Подписки (логика и UI).
-   [ ] Статы/Достижения (логика и UI).

## Ongoing / TODOs

-   [ ] Исследовать и исправить баги компиляции Xcode 16 beta (`contentInsetAdjustmentBehavior`, `isTranslucent`).
-   [ ] Добавить проверку прав доступа к галерее.
-   [ ] Решить, как будет работать навигация на Настройки (из `UserProfile` или `CurrentUserProfile`).
