Папка: Features/Progress/Scenes
Название папки: Scenes
Содержит: ProgressViewController.swift.
Файл: Features/Progress/Scenes/ProgressViewController.swift
Название файла: ProgressViewController.swift
Назначение файла: UI экрана "Progress".
Описание: Отображает основные RPG-статистики: Ранг, Уровень, XP (числовое значение и прогресс-бар). Связан с ProgressViewModel через Combine для получения данных и обновления UI. Отображает индикатор загрузки и сообщения об ошибках. Не реализует отображение истории тренировок, графиков, рекордов ([P2.PRG.*]).
Содержит: Класс ProgressViewController, UI элементы (UILabel, UIProgressView, UIStackView, UIActivityIndicatorView), setupBindings.
Технологии: UIKit, Combine.
Путь: ProgressCoordinator.start() -> Создание и показ ProgressViewController.
