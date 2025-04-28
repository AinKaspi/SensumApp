Файл: Features/Progress/ProgressViewModel.swift
Название файла: ProgressViewModel.swift
Назначение файла: Логика и состояние для экрана "Progress".
Описание: Загружает ProgressData текущего пользователя через ProgressService. Предоставляет данные (progressData, isLoading, errorMessage) для ProgressViewController через @Published свойства.
Содержит: Класс ProgressViewModel, @Published свойства, методы init, fetchProgressData, refreshData.
Технологии: Combine, Foundation.
Путь: Создается в ProgressCoordinator. Используется ProgressViewController. Взаимодействует с AuthService, ProgressService.
