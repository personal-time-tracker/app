import Foundation
import EventKit

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var calendars: [CalendarInfo] = []
    @Published var currentSession: TimeSession?
    
    init() {
        requestAccess()
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.loadCalendars()
                }
            }
        }
    }
    
    func loadCalendars() {
        let ekCalendars = eventStore.calendars(for: .event)
        calendars = ekCalendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.cgColor?.components?.map(String.init).joined(separator: ",") ?? ""
            )
        }
    }
    
    func startNewSession(title: String, calendarId: String) {
        // Завершаем текущую сессию
        endCurrentSession()
        
        // Создаем новую сессию
        let newSession = TimeSession(
            title: title,
            calendarId: calendarId,
            startTime: Date(),
            endTime: nil,
            category: nil
        )
        
        currentSession = newSession
        
        // Создаем событие в календаре
        createCalendarEvent(for: newSession)
    }
    
    func endCurrentSession() {
        guard let session = currentSession, session.isActive else { return }
        
        var updatedSession = session
        updatedSession.endTime = Date()
        currentSession = updatedSession
        
        // Обновляем событие в календаре
        updateCalendarEvent(for: updatedSession)
    }
    
    private func createCalendarEvent(for session: TimeSession) {
        guard let calendar = eventStore.calendar(withIdentifier: session.calendarId) else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = session.title
        event.startDate = session.startTime
        event.endDate = session.startTime.addingTimeInterval(3600) // 1 час по умолчанию
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Ошибка создания события: \(error)")
        }
    }
    
    private func updateCalendarEvent(for session: TimeSession) {
        guard let endTime = session.endTime else { return }
        
        let predicate = eventStore.predicateForEvents(
            withStart: session.startTime,
            end: endTime,
            calendars: [eventStore.calendar(withIdentifier: session.calendarId)].compactMap { $0 }
        )
        
        let events = eventStore.events(matching: predicate)
        if let event = events.first {
            event.endDate = endTime
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("Ошибка обновления события: \(error)")
            }
        }
    }
    
    func getSessions(from startDate: Date, to endDate: Date) -> [TimeSession] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
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