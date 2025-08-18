import Foundation
import EventKit
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarRepository")

class CalendarRepository {
    
    let eventStore = EKEventStore()
    
    // MARK: - Authorization
    
    func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }
    
    // MARK: - Calendars
    
    func getCalendars(with prefix: String) throws -> [EKCalendar] {
        try checkAccess()
        return eventStore.calendars(for: .event).filter { $0.title.contains(prefix) }
    }
    
    func getCalendar(withId id: String) throws -> EKCalendar? {
        try checkAccess()
        return eventStore.calendar(withIdentifier: id)
    }
    
    func saveCalendar(_ calendar: EKCalendar) throws {
        try checkAccess()
        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            throw InternalError.wrap(error: error, humanText: "Не удалось сохранить календарь")
        }
    }
    
    func createCalendar(title: String) throws -> EKCalendar {
        try checkAccess()
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title
        
        if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCalendar.source = source
        } else {
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        try saveCalendar(newCalendar)
        return newCalendar
    }
    
    // MARK: - Events
    
    func getEvents(from startDate: Date, to endDate: Date, in calendars: [EKCalendar]) throws -> [EKEvent] {
        try checkAccess()
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    func getEvent(withId id: String) throws -> EKEvent? {
        try checkAccess()
        return eventStore.event(withIdentifier: id)
    }
    
    func saveEvent(_ event: EKEvent) throws {
        try checkAccess()
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw InternalError.wrap(error: error, humanText: "Не удалось сохранить событие")
        }
    }
    
    func deleteEvent(_ event: EKEvent) throws {
        try checkAccess()
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw InternalError.wrap(error: error, humanText: "Не удалось удалить событие")
        }
    }
    
    // MARK: - Notifications
    
    func addObserver(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    func removeObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Private Helpers
    
    private func checkAccess() throws {
        let status = getAuthorizationStatus()
        guard status == .authorized || status == .fullAccess || status == .writeOnly else {
            throw UserError.new(
                errorText: "cannot get calendar access",
                humanText: "Для работы приложения необходим доступ к календарю"
            )
        }
    }
}
