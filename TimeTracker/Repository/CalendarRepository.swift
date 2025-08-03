//
//  CalendarRepository.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import Foundation
import EventKit
import Combine
import SwiftUI
import OSLog

@Observable
class CalendarRepository {
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarRepository")
    
    // MARK: - Dependendies
    
    @ObservationIgnored @AppStorage("calendarPrefix") private var calendarPrefix: String = "⏱️"
    @ObservationIgnored private let eventStore: EKEventStore
    
    // MARK: - State
    
    var calendars: [CalendarInfo] = []
    var events: [Activity] = [] {
        didSet {
            currentEvent = events.filter({ $0.isActive }).last
            previousEvent = events.filter({ $0.isPrevious }).last
        }
    }
    
    // Текущая активность это та, у которой время старта и конца между текущим моментом
    var currentEvent: Activity?
    
    // Предыдущая активность это последняя активность, которая была завершена до текущего момента
    var previousEvent: Activity?
    
    // MARK: - Init
    
    init(eventStore: EKEventStore) {
        
        self.eventStore = eventStore
        
        // Регистрируем наблюдателя за изменениями в календаре
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarDidChange),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    // MARK: - Functions
    
    func checkCalendarAccess(eventStore: EKEventStore) async throws {
        
        // Смотрим статус доступа к календарю
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
            
        // Не определен
        case .notDetermined:
            try await requestAccess(eventStore: eventStore)
            
        // Есть доступ, все ок
        case .fullAccess:
            break
            
        // Нет доступа или он не тот
        default:
            throw UserError.new(
                errorText: "Cannot access calendar",
                humanText: "Необходим доступ к календарям, текущий статус: \(status)",
                parameters: ["status": status]
            )
        }
    }
    
    func requestAccess(eventStore: EKEventStore) async throws {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                throw UserError.new(
                    errorText: "Cannot access calendar",
                    humanText: "Необходим доступ к календарям",
                    parameters: ["granted": granted]
                )
            }
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось получить доступ к календарю"
            )
        }
    }
    
    // Создает событие в календаре
    func createEvent(req: CreateActivity) async throws {
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        // Вслепую обновляем стейт
        let event = req.convertToActivity()
        switch (true) {
        case event.isActive:
            self.currentEvent = event
        case event.isPrevious:
            self.previousEvent = event
        default:
            break
        }
        
        // Получаем календарь по идентификатору из события
        guard let calendar = eventStore.calendar(withIdentifier: req.calendarId) else {
            throw NotFound.new(
                errorText: "Cannot get calendar by ID",
                humanText: "Календарь для создания события не найден",
                parameters: ["id": req.calendarId]
            )
        }
        
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = req.title
        calendarEvent.startDate = req.startTime
        calendarEvent.endDate = req.endTime
        calendarEvent.calendar = calendar
        
        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
        } catch {
            throw InternalError.new(
                errorText: "Cannot save event",
                humanText: "Не удалось сохранить событие в календаре",
                parameters: ["event": calendarEvent]
            )
        }
    }
    
    // Загружает календари из хранилища в стейт
    func loadCalendars() async throws {
        logger.info("Подгружаем календари из хранилища")
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        // Получаем календари
        let calendars = eventStore.calendars(for: .event)
            // Фильтруем их по префиксу
            .filter { $0.title.hasPrefix(calendarPrefix) }
//            // Сортируем по убыванию времени старта
//            .sorted { }
                
        // Конвертируем календари в нашу доменную модель
        self.calendars = calendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title
                    // Удаляем префикс
                    .replacingOccurrences(of: calendarPrefix, with: "")
                    // Удаляем пробелы и знаки переноса строк
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                color: calendar.cgColor
            )
        }
    }
    
    // Возвращает текущее активное событие, но не обновляет его в стейте
    func getCurrentEvent() async throws -> Activity? {
        logger.info("Загружаем текущее событие из хранилища")
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        let now = Date.now
        
        // Получаем календари
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        // Ищем события, которые происходят прямо сейчас
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // 1 час назад
            end: now.addingTimeInterval(3600), // 1 час вперед
            calendars: timeTrackingCalendars
        )

        // Получаем ивенты
        let events = eventStore.events(matching: predicate)

        // Ищем активное событие
        let currentEvent = events.last { $0.startDate <= now && ($0.endDate == nil || $0.endDate > now ) }
        
        if let currentEvent {
            return Activity(
                id: currentEvent.eventIdentifier,
                title: currentEvent.title,
                calendarId: currentEvent.calendar.calendarIdentifier,
                calendarName: currentEvent.calendar.title
                    // Удаляем префикс
                    .replacingOccurrences(of: calendarPrefix, with: "")
                    // Удаляем пробелы и знаки переноса строк
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: currentEvent.startDate,
                endTime: currentEvent.endDate
            )
        } else {
            return nil
        }
    }
    
    // Загружает события из хранилища в стейт
    func loadEvents() async throws {
        logger.info("Подгружаем события из хранилища")
        
        try await checkCalendarAccess(eventStore: eventStore)
                
        // Получаем календари
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        // Ищем события, которые происходят прямо сейчас
        let predicate = eventStore.predicateForEvents(
            withStart: Date.now.addingTimeInterval(-60*60*24),
            end: Date.now.addingTimeInterval(60*60*24),
            calendars: timeTrackingCalendars
        )
        
        // Получаем ивенты
        let events = eventStore.events(matching: predicate)

        self.events = events.map {
            Activity(
                id: $0.eventIdentifier,
                title: $0.title,
                calendarId: $0.calendar.calendarIdentifier,
                calendarName: $0.calendar.title
                    // Удаляем префикс
                    .replacingOccurrences(of: calendarPrefix, with: "")
                    // Удаляем пробелы и знаки переноса строк
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: $0.startDate,
                endTime: $0.endDate
            )
        }
    }
    
    // Обновляет событие в календаре
    func updateEvent(req: UpdateActivity) async throws {
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        // Вслепую обновляем стейт
        switch req.id {
        case currentEvent?.id:
            currentEvent?.patch(req: req)
        case previousEvent?.id:
            previousEvent?.patch(req: req)
        default:
            break
        }
    
        // Получаем актуальное событие из календаря
        guard let calendarEvent = eventStore.event(withIdentifier: req.id) else {
            throw NotFound.new(
                errorText: "Cannot find event by ID in calendar",
                humanText: "Не удалось обновить активность в календаре",
                parameters: ["id": req.id]
            )
        }
        
        let updatedCalendarEvent = calendarEvent
        
        // Патчем обновляем все доступные поля
        if let endTime = req.endTime {
            updatedCalendarEvent.endDate = endTime
        }
        if let startTime = req.startTime {
            updatedCalendarEvent.startDate = startTime
        }
        if let title = req.title {
            updatedCalendarEvent.title = title
        }
        if let calendarId = req.calendarId {
            // Получаем календарь из хранилища
            guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                throw NotFound.new(
                    errorText: "Cannot get calendar by ID",
                    humanText: "Календарь для создания события не найден",
                    parameters: ["id": calendarId]
                )
            }
            updatedCalendarEvent.calendar = calendar
        }
        
        // Пробуем сохранить
        do {
            try eventStore.save(updatedCalendarEvent, span: .thisEvent)
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Произошла ошибка при обновлении события в календарь",
                parameters: [
                    "updatedCalendarEvent": updatedCalendarEvent,
                    "calendarEvent": calendarEvent,
                    "req": req
                ]
            )
        }
    }
    
    // Удаляет событие
    func deleteEvent(id: String) async throws {
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        // Ищем событие в календаре
        guard let calendarEvent = eventStore.event(withIdentifier: id) else {
            throw NotFound.new(
                errorText: "Cannot find event by ID in calendar",
                humanText: "Событие для удаления не найдено в календаре"
            )
        }
        
        // Пробуем удалить событие
        do {
            try eventStore.remove(calendarEvent, span: .thisEvent)
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Произошла ошибка при удалении события из календаря",
                parameters: ["calendarEvent": calendarEvent]
            )
        }
    }
    
    // Создает календарь
    func createCalendar(req: CreateCalendar) async throws {
        
        try await checkCalendarAccess(eventStore: eventStore)
        
        // Создаем календарь
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Определяем имя
        newCalendar.title = req.title
        newCalendar.cgColor = req.color
        
        // Пытаемся найти источник iCloud
        if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCalendar.source = source
        } else {
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        logger.debug("Источник календаря: \(String(describing: newCalendar.source))")
        
        // Пробуем сохранить календарь
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Произошла ошибка при создании календаря",
                parameters: [
                    "newCalendar" : newCalendar,
                    "req": req
                ]
            )
        }
    }
    
    // Листенер для обновления календаря
    @objc private func calendarDidChange() {
        
        logger.debug("Данные календаря изменились, перезагружаю активности...")
        
        // Обновления UI должны происходить в основном потоке, так как они влияют на @Observable properties
//        DispatchQueue.main.async { [weak self] in
        Task {
            do {
                try await loadCalendars()
                try await loadEvents()
            } catch {
                logger.error("Ошибка при обновлении календаря: \(error)")
            }
        }
//        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
