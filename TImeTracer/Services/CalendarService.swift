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
                        }
                    }
                } catch {
                    eventStore.requestFullAccessToEvents { [weak self] granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                self?.loadCalendars()
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
