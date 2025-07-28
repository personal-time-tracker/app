import Foundation
import EventKit
import Combine
import SwiftUI

@Observable
class CalendarService {
    
    @ObservationIgnored
    private let eventStore = EKEventStore()
    
    var calendars: [CalendarInfo] = []
    var currentActivity: TimeSession?
    var previousActivity: TimeSession?
    
    @ObservationIgnored
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
        
    init() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            requestAccess()
        case .authorized, .fullAccess, .writeOnly:
            loadCalendars()
            loadCurrentActivity()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    func requestAccess() {
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    await MainActor.run {
                        if granted {
                            self.loadCalendars()
                            self.loadCurrentActivity()
                        }
                    }
                } catch {
                    eventStore.requestFullAccessToEvents { [weak self] granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                self?.loadCalendars()
                                self?.loadCurrentActivity()
                            }
                        }
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.loadCalendars()
                        self?.loadCurrentActivity()
                    }
                }
            }
        }
    }
    
    func createCalendar(fullTitle: String) {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = fullTitle
        
        // Пытаемся найти источник. Если не находим, используем дефолтный.
        if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCalendar.source = source
        } else {
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            // После создания сразу обновляем список календарей
            loadCalendars()
        } catch {
            print("Ошибка создания календаря: \(error.localizedDescription)")
        }
    }
    
    func loadCalendars() {
        let ekCalendars = eventStore.calendars(for: .event)
        
        // Фильтруем календари по настраиваемому префиксу
        let filteredCalendars = ekCalendars.filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        calendars = filteredCalendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.cgColor?.components?.map(String.init).joined(separator: ",") ?? ""
            )
        }
    }
    
    func loadCurrentActivity() {
        let now = Date()
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        // Если нет календарей с префиксом, не показываем ничего
        guard !timeTrackingCalendars.isEmpty else {
            currentActivity = nil
            AppStorageService.saveCurrentActivity(nil)
            return
        }
        
        // Ищем события, которые происходят прямо сейчас
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // 1 час назад
            end: now.addingTimeInterval(3600), // 1 час вперед
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
        
        // Ищем событие, которое активно сейчас (началось, но не закончилось)
        let currentEvent = events.last { event in
            event.startDate <= now && (event.endDate == nil || event.endDate > now)
        }
        
        if let event = currentEvent {
            currentActivity = TimeSession(
                id: event.eventIdentifier, // Сохраняем ID
                title: event.title,
                calendarName: event.calendar.title,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        } else {
            currentActivity = nil
        }
        
        // Сохраняем для виджета
        AppStorageService.saveCurrentActivity(currentActivity)
        
        // После загрузки текущей сессии, загружаем последнюю завершенную
        loadPreviousActivity()
    }
    
    func loadPreviousActivity() {
        let now = Date()
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        guard !timeTrackingCalendars.isEmpty else {
            previousActivity = nil
            return
        }
        
        // Ищем события за последний день, чтобы найти последнее
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-24 * 3600), // День назад
            end: now, // До текущего момента
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
            .filter { $0.endDate != nil && $0.endDate! <= now } // Только завершенные
            .sorted(by: { $0.endDate! > $1.endDate! }) // Сортируем по дате окончания, самые новые вверху
            
        if let lastEvent = events.first {
            previousActivity = TimeSession(
                id: lastEvent.eventIdentifier,
                title: lastEvent.title,
                calendarName: lastEvent.calendar.title,
                startTime: lastEvent.startDate,
                endTime: lastEvent.endDate,
                category: lastEvent.calendar.title
            )
        } else {
            previousActivity = nil
        }
    }
    
    func startNewSession(title: String, calendarId: String, duration: TimeInterval) {
        // Запоминаем точное время начала новой сессии
        let newSessionStartDate = Date()
        
        // Завершаем текущую сессию, устанавливая ее конец точно в момент начала новой
        endCurrentActivity(endDate: newSessionStartDate)
        
        // Создаем событие в календаре, начиная с того же самого момента
        createCalendarEvent(title: title, calendarId: calendarId, duration: duration, startDate: newSessionStartDate)
        
        // Перезагружаем текущую сессию из календаря
        loadCurrentActivity()
    }
    
    func endCurrentActivity(endDate: Date) {
        guard let session = currentActivity else { return }
        
        updateCalendarEvent(eventId: session.id, newEndDate: endDate)
        
        loadCurrentActivity()
    }

    func extendSession(eventId: String, by timeInterval: TimeInterval) {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            print("Ошибка: не удалось найти событие с ID \(eventId) для продления")
            return
        }
        
        guard let currentEndDate = event.endDate else { return }
        
        event.endDate = currentEndDate.addingTimeInterval(timeInterval)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            // После продления нужно обновить состояние
            loadPreviousActivity()
        } catch {
            print("Ошибка продления события: \(error)")
        }
    }
    
    private func createCalendarEvent(title: String, calendarId: String, duration: TimeInterval, startDate: Date) {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate // Используем переданную дату начала
        event.endDate = startDate.addingTimeInterval(duration)
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Ошибка создания события: \(error)")
        }
    }
    
    private func updateCalendarEvent(eventId: String, newEndDate: Date) {
        // Получаем событие напрямую по его идентификатору
        guard let event = eventStore.event(withIdentifier: eventId) else {
            print("Ошибка: не удалось найти событие с ID \(eventId)")
            return
        }
        
        event.endDate = newEndDate
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Ошибка обновления события: \(error)")
        }
    }
    
    func getSessions(from startDate: Date, to endDate: Date) -> [TimeSession] {
        // Получаем только календари с настраиваемым префиксом
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
        return events.map { event in
            TimeSession(
                id: event.eventIdentifier,
                title: event.title,
                calendarName: event.calendar.title,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        }
    }
} 
