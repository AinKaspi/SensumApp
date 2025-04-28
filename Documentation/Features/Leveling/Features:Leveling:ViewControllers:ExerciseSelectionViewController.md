Файл: Features/Leveling/ViewControllers/ExerciseSelectionViewController.swift
Название файла: ExerciseSelectionViewController.swift
Назначение файла: UI экрана выбора упражнения.
Описание: Отображает список доступных упражнений с помощью UITableView и кастомной ячейки ExerciseCell. Получает данные из ExerciseSelectionViewModel. При выборе упражнения уведомляет ViewModel (viewModel.didSelectExercise), которая затем сообщает координатору.
Содержит: Класс ExerciseSelectionViewController, класс ExerciseCell, реализация UITableViewDataSource, UITableViewDelegate.
Технологии: UIKit.
Путь: LevelingCoordinator.start() -> Создание и показ ExerciseSelectionViewController.
