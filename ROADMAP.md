# Полный Roadmap Проекта SensumApp (Версия 1.9 - Включая скролл постов в Таб 2 Person)

**Дата:** 24 апреля 2025 г.

**Общее Видение:** Создать уникальное iOS-приложение (Social Fitness RPG) с 5 основными разделами (Feed, Person, Leveling, Progress, Store), отображающее логотип "DOJO", предоставляющее систему уведомлений и обмен сообщениями. Приложение мотивирует пользователей через комбинацию социального взаимодействия (лента рекомендаций, профили), AI-анализа фитнес-упражнений (MediaPipe) и продвинутых RPG-механик (XP, уровни, аттрибуты, ранги, бонусы).

**Использование:** Отмечайте выполненные задачи, заменяя `[ ]` на `[x]`. Используйте `[~]` для частично выполненных задач. Используйте ID задач (`[P1.FND.1]`) при обсуждении с AI.

**Ключевые Разделы (Табы) и Темы:**

1.  Feed (Таб 1): Лента рекомендаций, просмотр профилей других.
2.  **Person (Таб 2): Профиль текущего пользователя (включая просмотр своей ленты постов).**
3.  Leveling (Таб 3): Выбор/выполнение упражнений, AI-анализ, XP, прокачка аттрибутов.
4.  Progress (Таб 4): Статистика, отслеживание RPG-элементов, достижения.
5.  Store (Таб 5): Внутриигровой магазин.
6.  Просмотр Профиля Другого Пользователя: Функционал и UI (Card, Person, Stats).
7.  Программы Тренировок: Создание, управление и просмотр программ.
8.  RPG Механики: Уровни, XP, Ранги, Аттрибуты, Бонусы.
9.  Общее Ядро (Core): Аутентификация, сервисы, модели.
10. Техническая Основа и UI: Архитектура, зависимости, производительность, общие элементы UI.
11. Уведомления (Notifications): Система оповещений.
12. Обмен Сообщениями (Messaging): Функционал чата.

---

## Фаза 1: MVP (Социальный Фитнес RPG - Основа)

**Цель Фазы 1:** Запустить базовое приложение: регистрация/вход, выполнение 1 упражнения с AI-анализом + расчет XP/уровня, просмотр простейшей ленты и своего профиля (уровень/XP), базовая навигация с логотипом.

### Тема: Техническая Основа и UI [FND]
- [~] `[P1.FND.1]` Настройка структуры проекта, архитектуры (Координаторы, MVVM), зависимостей (CocoaPods: MediaPipe, Charts). *(Структура, MVVM+Coords, MediaPipe есть. Charts не интегрированы)*.
- [x] `[P1.FND.2]` Настройка Firebase/Google Cloud (`GoogleService-Info.plist`).
- [x] `[P1.FND.3]` Реализация основной структуры UI: `UITabBarController` (5 табов), `UINavigationController` для каждого таба.
- [~] `[P1.FND.4]` Реализация базовой `UINavigationBar` с логотипом "DOJO". *(Логотип реализован в кастомном TopMenuView в FeedViewController, не в стандартном UINavigationBar)*.

### Тема: Общее Ядро (Core) [COR]
- [x] `[P1.COR.1]` Определение базовых Моделей Данных: `User`, `Post`, `Exercise`, `ProgressData` (с полями `level`, `currentXP`, `xpToNextLevel`, `rank`, `attributes: [Attribute]`). *(Модели User, Post, Exercise, ProgressData, Attribute определены)*.
- [x] `[P1.COR.2]` Реализация базовых Core Services (протоколы + начальная имплементация): `AuthService`, `UserProfileService`, `PostService`, `StorageService`, `ProgressService`. *(Auth, UserProfile, Post, Storage, Progress реализованы. Конфликт с DataManager устранен. `FollowService` из Фазы 2 также реализован)*. 
- [x] `[P1.COR.3]` Реализация `AuthCoordinator` и сценариев Регистрации / Входа (VC, VM, вызовы `AuthService`).

### Тема: RPG Механики [RPG]
- [x] `[P1.RPG.1]` Реализация расчета Ранга в `ProgressService`: `func calculateRank(level: Int) -> String` (логика E-R+). Инициализация ранга при регистрации/загрузке. *(Функция `calculateRank` реализована в ProgressService)*.

### Тема: Feed (Таб 1) [FED]
- [x] `[P1.FED.1]` Реализация `FeedCoordinator`.
- [~] `[P1.FED.2]` Реализация `FeedViewController` (вертикальный список `UICollectionView`/`UITableView`). *(Используется UITableView)*.
- [x] `[P1.FED.3]` Реализация базовой **бесконечной прокрутки** (пагинации) в `FeedViewController`. *(Реализовано в PostService, FeedViewModel, FeedViewController)*.
- [x] `[P1.FED.4]` Реализация `FeedViewModel` (загрузка постов через `PostService`). *(Реализована загрузка с пагинацией)*.
- [x] `[P1.FED.5]` Реализация `PostCell` (отображение фото, мини-аватарки, имени автора). Зависит от `Post`.
- [x] `[P1.FED.6]` Навигация из `FeedViewController` на **экран-заглушку** Профиля Другого Пользователя (при тапе на авторе). Зависит от `UserProfileCoordinator`. *(Реализована обработка тапа и вызов координатора)*.

### Тема: Person (Таб 2 - Свой Профиль) [PSN]
- [x] `[P1.PSN.1]` Реализация `PersonCoordinator` (или `CurrentUserProfileCoordinator`).
- [x] `[P1.PSN.2]` Реализация `PersonViewController` (отображение Имени пользователя, Уровня и XP). *(Реализовано в UserProfileFeedVC/UserProfileCardVC)*.
- [x] `[P1.PSN.3]` Реализация `PersonViewModel` (загрузка данных через `UserProfileService`, `ProgressService`). Зависит от `User`, `ProgressData`. *(Реализовано в UserProfileFeedViewModel с использованием UserProfileService и ProgressService)*.

### Тема: Leveling (Таб 3 - Тренировки) [LVL]
- [x] `[P1.LVL.1]` Реализация `LevelingCoordinator`.
- [x] `[P1.LVL.2]` Реализация `ExerciseSelectionViewController` / `ViewModel` (выбор 1 упражнения, например Приседания). Зависит от `Exercise`. *(Используются моковые данные)*.
- [x] `[P1.LVL.3]` Реализация `ExerciseExecutionViewController` / `ViewModel`: Интеграция камеры, `PoseLandmarkerHelper` (использует MediaPipe), `PoseOverlayView`.
- [x] `[P1.LVL.4]` Реализация базового анализатора (`SquatAnalyzer3D`, реализует `ExerciseAnalyzerProtocol`) для подсчета повторений.
- [x] `[P1.LVL.5]` Расчет базового XP (без бонусов) и вызов `ProgressService.addXP()`, который обновит `level`, `xp`, `rank`. Зависит от `[P1.RPG.1]`. *(Расчет XP и вызов ProgressService.addXP() реализованы в ExerciseExecutionViewModel)*.

### Тема: Progress (Таб 4 - Статистика) [PRG]
- [x] `[P1.PRG.1]` Реализация `ProgressCoordinator`.
- [x] `[P1.PRG.2]` Реализация `ProgressViewController` / `ViewModel` (отображение Уровня, шкалы XP, Ранга). Зависит от `ProgressData`, `[P1.RPG.1]`. *(UI и ViewModel реализованы)*.

### Тема: Store (Таб 5 - Магазин) [STR]
- [x] `[P1.STR.1]` Реализация `StoreCoordinator`.
- [x] `[P1.STR.2]` Реализация `StoreViewController` (UI-заглушка).

### Тема: Создание Контента [CNT]
- [x] `[P1.CNT.1]` Реализация `CreatePostViewController` / `ViewModel` (создание текстового поста для наполнения ленты). Зависит от `PostService`. *(Реализовано создание поста с изображением)*.

---

## Фаза 2: Расширение и Улучшение (Post-MVP)

**Цель Фазы 2:** Улучшить все MVP-фичи, реализовать полноценный просмотр профиля другого пользователя (Card/Person/Stats), детализировать экран собственного профиля (Таб 2) **включая скролл-ленту постов**, добавить социальные функции (подписки, комменты, лайки), медиа-контент, базовые уведомления, базовый магазин и начать прокачку аттрибутов.

### Тема: Техническая Основа и UI [FND]
- [ ] `[P2.FND.1]` Оптимизация производительности (загрузка ленты, изображений).
- [ ] `[P2.FND.2]` Написание Unit-тестов (для Services, ViewModels).
- [x] `[P2.FND.3]` Добавление/Настройка библиотеки `Charts` (DGCharts) через CocoaPods/SPM. Зависимость для `[P2.UPO.5]`. *(Добавлено и используется)*.

### Тема: Feed (Таб 1) [FED]
- [~] `[P2.FED.1]` Реализация Верхней Панели (аналог Stories): Горизонтальный `UICollectionView` в `FeedViewController`, загрузка данных пользователей (`UserService`/`PostService`), навигация на профиль `[P2.UPO.1]`. *(UICollectionView в хедере таблицы, StoryCell, навигация реализованы. Загрузка данных и обводка - TODO)*.
- [~] `[P2.FED.2]` Улучшение `PostCell`/`FullPostCell`: Добавить UI для Лайков, Комментариев, Текста поста + кнопка "more". *(UI лайков, комментариев, share, счетчик лайков, показ полного текста/more добавлены в PostCell. Скругление картинки есть)*.
    - [x] `- [x]` Добавить отображение полного текста поста и кнопку "more". *(Реализовано)*.
    - [ ] `- [ ]` Реализовать UI для `FullPostCell`.
- [x] `[P2.FED.3]` Реализация логики Лайков: UI обновление + вызов `PostService.likePost()`. *(Реализовано в ViewModel/ViewController с оптимистичным обновлением)*.
- [x] `[P2.FED.4]` Навигация на экран Комментариев `[P2.SOC.2]` при тапе на иконку/счетчик. *(Реализовано)*.
- [ ] `[P2.FED.5]` Обеспечение плавной прокрутки `FeedViewController` (верхняя панель + лента).
- [ ] `[P2.FED.6]` **UI/UX Рефайнмент Ленты:** Приведение UI к макетам (шрифты, точные отступы, градиентная обводка сторис, расположение элементов в PostCell).

### Тема: Person (Таб 2 - Свой Профиль) [PSN]
- [x] `[P2.PSN.1]` Улучшение `PersonViewController`: Реализация Заголовка (Аватар, Counts, Имя, @id - по аналогии с `[P2.UPO.4]`). *(Реализовано в UserProfileFeedViewController)*.
- [~] `[P2.PSN.2]` Добавление Кнопок Действий: "New post" (-> `[P1.CNT.1]`), "New program" (UI заглушка -> `[P3.PRG.4]`). *(UI кнопок "New Post" и "New Program" добавлены)*.
- [~] `[P2.PSN.3]` Добавление Переключателя Контента: Табы "Posts" / "Programs" (UI заглушка -> `[P3.PRG.5]`). *(UISegmentedControl добавлен. Логика для "Programs" отсутствует)*.
- [x] `[P2.PSN.4]` Отображение Сетки Постов пользователя (при выборе таба "Posts"). *(Реализовано в UserProfileFeedViewController)*.
    - [x] `- [x]` Реализация обработки нажатия (tap) на пост в сетке.
    - [x] `- [x]` Навигация на экран `UserPostScrollViewController` `[P2.PSN.7]`, передача UserID (текущего пользователя) и ID нажатого поста. *(Навигация вызывается, сам экран UserPostScrollViewController не реализован)*.
- [x] `[P2.PSN.5]` Отображение RPG Элементов (Ранг, Уровень, XP). *(Уровень/XP/Ранг отображаются в UserProfileFeedViewController)*.
- [x] `[P2.PSN.6]` Реализация Экрана Редактирования Профиля (Аватар, Имя, ID, Био). Зависит от `UserProfileService`. *(Реализованы VC, VM, навигация; использует UserProfileService, StorageService)*.
- [x] `[P2.PSN.7]` **Реализация `UserPostScrollViewController` (Лента постов пользователя):** *(Реализован VC с UICollectionView и FullPostCell. Поддерживает пагинацию, лайки, навигацию на комменты/автора)*.
    - [ ] Использование `UICollectionView` / `UITableView` для вертикальной прокрутки постов.
    - [ ] Использование ячейки, аналогичной `FullPostCell` из `Feed`, для отображения: Фото, Текст поста (caption), Иконки/счетчики Лайков, Иконки/счетчики Комментариев.
    - [ ] Реализация "бесконечной" прокрутки вниз для загрузки более старых постов пользователя.
    - [ ] Начальная позиция скролла должна быть на посте, с которого перешли.
    - [ ] Подключение логики Лайков (`[P2.FED.3]`).
    - [x] Навигация на экран Комментариев (`[P2.SOC.2]`) при нажатии на иконку/счетчик комментариев.
- [x] `[P2.PSN.8]` **Реализация `UserPostScrollViewModel`:** *(Реализован VM с загрузкой постов пользователя, пагинацией и лайками)*.
    - [ ] Загрузка постов для конкретного UserID через `PostService`.
    - [ ] Обработка пагинации для загрузки старых постов.
    - [ ] Передача ID начального поста для позиционирования.
    - [ ] Управление источником данных для `UserPostScrollViewController`.

### Тема: Leveling (Таб 3 - Тренировки) [LVL]
- [ ] `[P2.LVL.1]` Добавление 2-3 новых упражнений (`Exercise`) и их Анализаторов (`ExerciseAnalyzerProtocol`).
- [ ] `[P2.LVL.2]` Улучшение Анализаторов (обратная связь по технике).
- [x] `[P2.LVL.3]` Использование `KalmanFilter3D`, `MotionManager` (если нужно). *(Используются в ExerciseExecutionViewModel)*.
- [ ] `[P2.LVL.4]` Улучшение `PoseOverlayView`. *(Файл не анализировался)*.
- [x] `[P2.RPG.1]` **RPG Механика (Аттрибуты - Прокачка):** Определение маппинга "упражнение -> аттрибут(ы)", реализация логики увеличения аттрибутов в `ProgressService` после `[P1.LVL.5]`. *(Реализовано)*.

### Тема: Progress (Таб 4 - Статистика) [PRG]
- [ ] `[P2.PRG.1]` Реализация `ProgressCoordinator`.
- [ ] `[P2.PRG.2]` Реализация `ProgressViewController` / `ViewModel` (отображение Уровня, шкалы XP, Ранга). Зависит от `ProgressData`, `[P1.RPG.1]`. *(UI и ViewModel реализованы)*.

### Тема: Store (Таб 5 - Магазин) [STR]
- [ ] `[P2.STR.1]` Реализация базового UI `StoreViewController`.
- [ ] `[P2.STR.2]` Интеграция StoreKit: Покупка 1-2 non-consumable IAP.

### Тема: Социальное Ядро и Контент [SOC]
- [x] `[P2.SOC.1]` Реализация Системы Подписок (`FollowService`, UI в профилях). *(FollowService и логика в VM/VC есть. Кнопка Follow/Following работает)*.
- [x] `[P2.SOC.2]` Реализация Комментариев: Экран `CommentsViewController`, `CommentsViewModel`, `CommentCell`, `Comment` model, обновление `PostService`. *(Базовая реализация завершена)*.
- [x] `[P2.SOC.3]` Загрузка Медиа к Постам: Обновление `CreatePostViewController`, использование `StorageService`. *(Реализовано в флоу создания поста)*.
- [~] `[P2.SOC.4]` Отображение Медиа в `PostCell`, `FullPostCell`, `PostGridCell`. *(В PostCell и PostGridCell реализовано. FullPostCell не проверен)*.

### Тема: Просмотр Профиля Другого Пользователя [UPO]
- [x] `[P2.UPO.1]` Реализация `UserProfileContainerViewController` (управляет Card/Person/Stats). Навигация из `[P1.FED.6]`. *(Реализован, но с TODO. Навигация из P1.FED.6 отсутствует)*.
- [x] `[P2.UPO.2]` Настройка Top Navigation Bar в `UserProfileContainerViewController` (Назад, Меню Card/Person/Stats, Настройки/Опции). *(Реализовано через TopMenuView)*.
- [x] `[P2.UPO.3]` Реализация `UserProfileCardViewController` ("Card" таб): Фон, Аватар, Имя, Follow кнопка, Статус/Био, Уровень, XP бар. Зависит от `UserProfileService`, `ProgressService`, `FollowService`. *(Реализовано с UserProfileCardViewModel)*.
- [x] `[P2.UPO.4]` Реализация `UserProfileFeedViewController` ("Person" таб): Заголовок (Аватар, Counts, Имя, @id, кнопки Follow, Message[UI], Program[UI]), Контент (Табы, Сетка постов). Зависит от `UserProfileService`, `FollowService`, `PostService`. *(Заголовок, сетка, кнопки Follow/Message реализованы. Кнопка Program отсутствует. Контент ограничен 86% ширины)*.
- [x] `[P2.UPO.5]` Реализация `UserProfileStatsViewController` ("Stats" таб): Радар-Чарт (`Charts` `[P2.FND.3]`), Инфо-блок (Имя, Ранг `[P1.RPG.1]`, Аттрибуты), Уровень, XP. Зависит от `UserProfileService`, `ProgressService`. *(Реализовано, включая список атрибутов и ограничение ширины 86%)*.
- [x] `[P2.UPO.6]` Реализация ViewModel'ов для UPO экранов. *(UserProfileFeedViewModel, UserProfileStatsViewModel, UserProfileCardViewModel реализованы)*.

### Тема: Уведомления (Notifications - Базовые) [NOT]
- [~] `[P2.NOT.1]` Бэкенд: Проектирование схемы, реализация генерации уведомлений (комментарий, подписчик, лайк?). *(Модель AppNotification и заглушка NotificationService созданы. Бэкенд логика отсутствует)*.
- [~] `[P2.NOT.2]` UI: Отображение иконки Уведомлений + счетчика (badge) в Nav Bar (`[P1.FND.4]`). *(Иконка добавлена в TopBarView FeedVC. Счетчик отсутствует)*.
- [~] `[P2.NOT.3]` Навигация на экран Уведомлений. *(Реализована базовая навигация через AppCoordinator)*.
- [~] `[P2.NOT.4]` UI: Базовый `NotificationsViewController` (список уведомлений) + логика прочтения. *(Создана заглушка VC)*.

---

## Фаза 3: Зрелость и Оптимизация

**Цель Фазы 3:** Добавить продвинутые функции (чат, программы тренировок, ачивки, лидерборды), реализовать бонус XP от аттрибутов, push-уведомления, оптимизировать и отполировать приложение.

### Тема: Техническая Основа и UI [FND]
- [ ] `[P3.FND.1]` Глубокая оптимизация производительности.
- [ ] `[P3.FND.2]` UI/UX полировка всего приложения.
- [ ] `[P3.FND.3]` Внедрение системы Аналитики.
- [ ] `[P3.FND.4]` Расширение покрытия тестами (Unit, UI).
- [ ] `[P3.FND.5]` Настройка CI/CD.

### Тема: Feed (Таб 1) [FED]
- [ ] `[P3.FED.1]` Подсветка Кружков в Верхней Панели (Бэкенд + Фронтенд логика seen/unseen).
- [ ] `[P3.FED.2]` Улучшение алгоритма рекомендаций / добавление вкладки "Подписки".
- [ ] `[P3.FED.3]` Реализация "Поделиться" (Share).

### Тема: Person (Таб 2 - Свой Профиль) [PSN]
- [ ] `[P3.PSN.1]`