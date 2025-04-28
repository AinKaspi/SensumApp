Файл: Features/Leveling/ViewModels/ExerciseSelectionViewModel.swift
Название файла: ExerciseSelectionViewModel.swift
Назначение файла: Логика экрана выбора упражнения.
Описание: Предоставляет список упражнений (exercises - пока моковые данные) для ExerciseSelectionViewController. Обрабатывает выбор пользователя (didSelectExercise) и уведомляет координатора (LevelingCoordinator) через ExerciseSelectionViewModelCoordinatorDelegate.
Содержит: Класс ExerciseSelectionViewModel, протокол ExerciseSelectionViewModelCoordinatorDelegate, массив exercises, методы numberOfExercises, exercise(at:), didSelectExercise(at:).
Технологии: Foundation.
Путь: Создается в LevelingCoordinator. Используется ExerciseSelectionViewController.
