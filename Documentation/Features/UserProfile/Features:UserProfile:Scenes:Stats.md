Папка: Features/UserProfile/Scenes/Stats
Название папки: Stats
Содержит: UserProfileStatsViewController.swift.
Файл: Features/UserProfile/Scenes/Stats/UserProfileStatsViewController.swift
Название файла: UserProfileStatsViewController.swift
Назначение файла: UI для вкладки "Stats" профиля пользователя.
Описание: Отображает статистику RPG в контейнере 86% ширины: радар-диаграмму атрибутов (RadarChartView из DGCharts), информационный блок (имя, ранг, список атрибутов) и блок уровня/XP. Использует UIScrollView. Связан с UserProfileStatsViewModel через Combine для получения данных и отображения состояний. Реализует AxisValueFormatter для настройки осей чарта.
Содержит: Класс UserProfileStatsViewController, UI элементы (UIScrollView, RadarChartView, UILabel, UIStackView, UIProgressView, UIActivityIndicatorView), классы-форматеры XAxisValueFormatter, YAxisValueFormatter, реализация AxisValueFormatter, setupBindings, updateUI, updateRadarChart.
Технологии: UIKit, Combine, DGCharts.
Путь: UserProfileContainerViewController -> displayChildViewController(statsVC).
