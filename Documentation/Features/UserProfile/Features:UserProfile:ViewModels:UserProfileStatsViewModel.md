Файл: Features/UserProfile/ViewModels/UserProfileStatsViewModel.swift
Название файла: UserProfileStatsViewModel.swift
Назначение файла: Логика и состояние для UserProfileStatsViewController.
Описание: Загружает User и ProgressData для указанного userID с помощью UserProfileService и ProgressService. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileStatsViewModel, @Published свойства, метод fetchStatsData, refreshData.
Технологии: Combine, Foundation.
Путь: Создается в UserProfileContainerViewController. Используется UserProfileStatsViewController. Взаимодействует с UserProfileService, ProgressService.
