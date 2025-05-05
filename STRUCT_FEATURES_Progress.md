### Features/Progress

_Модуль отвечает за отображение RPG-прогресса пользователя (уровень, ранг, атрибуты)._

*   `/Users/inga/Desktop/SensumApp/Features/Progress`:
    *   `Coordinators/`: Координатор для управления навигацией в рамках фичи.
        *   `ProgressCoordinator.swift`: (Предположительно) Координирует показ экрана прогресса и переходы из него.
    *   `ProgressViewModel.swift`: (Предположительно) ViewModel, управляющая логикой и состоянием экрана прогресса (`ProgressViewController`). Находится в корне фичи.
    *   `Scenes/`: Содержит экран(ы) фичи.
        *   `ProgressViewController.swift`: (Предположительно) Экран (`UIViewController`) для отображения деталей прогресса пользователя (уровень, XP, ранг, атрибуты, возможно, с визуализацией).