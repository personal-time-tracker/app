import Foundation
import EventKit
import Combine
import SwiftUI

@Observable
class CalendarService {
    
    @ObservationIgnored
    private let eventStore = EKEventStore()
    
    var calendars: [CalendarInfo] = []
    var currentSession: TimeSession?
    
    @ObservationIgnored
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
        
    init() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            requestAccess()
        case .authorized, .fullAccess, .writeOnly:
            loadCalendars()
            loadCurrentSession()
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
                            self.loadCurrentSession()
                        }
                    }
                } catch {
                    eventStore.requestFullAccessToEvents { [weak self] granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                self?.loadCalendars()
                                self?.loadCurrentSession()
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
                        self?.loadCurrentSession()
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
    
    func loadCurrentSession() {
        let now = Date()
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        // Если нет календарей с префиксом, не показываем ничего
        guard !timeTrackingCalendars.isEmpty else {
            currentSession = nil
            AppStorageService.saveCurrentSession(nil)
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
        let currentEvent = events.first { event in
            event.startDate <= now && (event.endDate == nil || event.endDate > now)
        }
        
        if let event = currentEvent {
            currentSession = TimeSession(
                title: event.title,
                calendarName: event.calendar.title,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        } else {
            currentSession = nil
        }
        
        // Сохраняем для виджета
        AppStorageService.saveCurrentSession(currentSession)
    }
    
    func startNewSession(title: String, calendarId: String, duration: TimeInterval) {
        // Завершаем текущую сессию
        endCurrentSession()
        
        // Создаем событие в календаре
        createCalendarEvent(title: title, calendarId: calendarId, duration: duration)
        
        // Перезагружаем текущую сессию из календаря
        loadCurrentSession()
    }
    
    func endCurrentSession() {
        guard let session = currentSession, session.isActive else { return }
        
        // Обновляем событие в календаре
        updateCalendarEvent(for: session)
        
        // Перезагружаем текущую сессию из календаря
        loadCurrentSession()
    }
    
    private func createCalendarEvent(title: String, calendarId: String, duration: TimeInterval) {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(duration) // Используем переданную продолжительность
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Ошибка создания события: \(error)")
        }
    }
    
    private func updateCalendarEvent(for session: TimeSession) {
        let now = Date()
        
        let predicate = eventStore.predicateForEvents(
            withStart: session.startTime,
            end: now.addingTimeInterval(3600),
            calendars: [eventStore.calendar(withIdentifier: session.calendarName)].compactMap { $0 }
        )
        
        let events = eventStore.events(matching: predicate)
        if let event = events.first {
            event.endDate = now
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("Ошибка обновления события: \(error)")
            }
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
                title: event.title,
                calendarName: event.calendar.title,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        }
    }
} 
