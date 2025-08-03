import Foundation
import EventKit
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarRepository")

class CalendarRepository {
    
    private let eventStore = EKEventStore()
    
    // MARK: - Authorization
    
    func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            // Using a continuation to bridge the gap for the older callback-based API.
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - Calendars
    
    func getCalendars(with prefix: String) async throws -> [EKCalendar] {
        try await checkAccessAndRequestIfNeeded()
        return eventStore.calendars(for: .event).filter { $0.title.contains(prefix) }
    }
    
    func getCalendar(withId id: String) async throws -> EKCalendar? {
        try await checkAccessAndRequestIfNeeded()
        return eventStore.calendar(withIdentifier: id)
    }
    
    func saveCalendar(_ calendar: EKCalendar) async throws {
        try await checkAccessAndRequestIfNeeded()
        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            throw InternalError.wrap(error: error, humanText: "Не удалось сохранить календарь")
        }
    }
    
    func createCalendar(title: String) async throws -> EKCalendar {
        try await checkAccessAndRequestIfNeeded()
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title
        
        if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCalendar.source = source
        } else {
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        try await saveCalendar(newCalendar)
        return newCalendar
    }
    
    // MARK: - Events
    
    func getEvents(from startDate: Date, to endDate: Date, in calendars: [EKCalendar]) async throws -> [EKEvent] {
        try await checkAccessAndRequestIfNeeded()
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    func getEvent(withId id: String) async throws -> EKEvent? {
        try await checkAccessAndRequestIfNeeded()
        return eventStore.event(withIdentifier: id)
    }
    
    func saveEvent(_ event: EKEvent) async throws {
        try await checkAccessAndRequestIfNeeded()
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw InternalError.wrap(error: error, humanText: "Не удалось сохранить событие")
        }
    }
    
    func deleteEvent(_ event: EKEvent) async throws {
        try await checkAccessAndRequestIfNeeded()
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
    
    private func checkAccessAndRequestIfNeeded() async throws {
        var status = getAuthorizationStatus()
        
        if status == .notDetermined {
            logger.debug("Calendar access not determined. Requesting now.")
            let granted = try await requestAccess()
            if !granted {
                throw UserError.new(
                    errorText: "calendar access was denied by user",
                    humanText: "Доступ к календарю не был предоставлен."
                )
            }
        }
        
        // Re-check status after potential request
        status = getAuthorizationStatus()
        
        guard status == .authorized || status == .fullAccess || status == .writeOnly else {
            throw UserError.new(
                errorText: "cannot get calendar access",
                humanText: "Для работы приложения необходим доступ к календарю. Пожалуйста, включите его в Настройках."
            )
        }
    }
}