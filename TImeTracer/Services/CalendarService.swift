import Foundation
import EventKit

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var calendars: [CalendarInfo] = []
    @Published var currentSession: TimeSession?
    
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
    
    func loadCalendars() {
        let ekCalendars = eventStore.calendars(for: .event)
        
        // Фильтруем только календари с эмодзи ⏱️ в названии
        let filteredCalendars = ekCalendars.filter { calendar in
            calendar.title.contains("⏱️")
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
            calendar.title.contains("⏱️")
        }
        
        // Если нет календарей с эмодзи, не показываем ничего
        guard !timeTrackingCalendars.isEmpty else {
            currentSession = nil
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
                calendarId: event.calendar.calendarIdentifier,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        } else {
            currentSession = nil
        }
    }
    
    func startNewSession(title: String, calendarId: String) {
        // Завершаем текущую сессию
        endCurrentSession()
        
        // Создаем событие в календаре
        createCalendarEvent(title: title, calendarId: calendarId)
        
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
    
    private func createCalendarEvent(title: String, calendarId: String) {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(3600) // 1 час по умолчанию
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
            calendars: [eventStore.calendar(withIdentifier: session.calendarId)].compactMap { $0 }
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
        // Получаем только календари с эмодзи ⏱️
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains("⏱️")
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
                calendarId: event.calendar.calendarIdentifier,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        }
    }
} 
