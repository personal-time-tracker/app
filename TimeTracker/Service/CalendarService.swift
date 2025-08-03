import Foundation
import EventKit
import Combine
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

// Service is now non-isolated. It can do its work on any thread.
@Observable
class CalendarService {
    
    private let repository = CalendarRepository()
    
    // These properties are still observed by the UI, so changes must be published from the MainActor.
    var calendars: [CalendarInfo] = []
    var currentActivity: TimeActivity?
    var previousActivity: TimeActivity?
    
    @ObservationIgnored
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
        
    init() {
        if repository.getAuthorizationStatus() == .authorized || repository.getAuthorizationStatus() == .fullAccess {
            Task {
                do {
                    try await loadCurrentActivity()
                } catch {
                    logger.error("Failed to load initial data: \(error.localizedDescription)")
                }
            }
        }
        
        repository.addObserver(self, selector: #selector(calendarDidChange))
    }
    
    func createCalendar(title: String) async throws {
        let fullTitle = "\(calendarPrefix) \(title)"
        _ = try await repository.createCalendar(title: fullTitle)
        try await loadCalendars()
    }
    
    func loadCalendars() async throws {
        let ekCalendars = try await repository.getCalendars(with: calendarPrefix)
        let newCalendars = ekCalendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.cgColor?.components?.map(String.init).joined(separator: ",") ?? ""
            )
        }
        // Switch to MainActor only to update the published property.
        await MainActor.run {
            self.calendars = newCalendars
        }
    }
    
    func loadCurrentActivity() async throws {
        let now = Date()
        let timeTrackingCalendars = try await repository.getCalendars(with: calendarPrefix)
        
        var newCurrentActivity: TimeActivity?
        var newPreviousActivity: TimeActivity?

        if timeTrackingCalendars.isEmpty {
            newCurrentActivity = nil
            newPreviousActivity = nil
        } else {
            // --- Get Current Activity ---
            let currentEvents = try await repository.getEvents(from: now.addingTimeInterval(-3600), to: now.addingTimeInterval(3600), in: timeTrackingCalendars)
            let currentEvent = currentEvents.last { $0.startDate <= now && ($0.endDate == nil || $0.endDate > now) }
            newCurrentActivity = currentEvent.map { TimeActivity(from: $0) }
            
            // --- Get Previous Activity ---
            let previousEvents = try await repository.getEvents(from: now.addingTimeInterval(-24 * 3600), to: now, in: timeTrackingCalendars)
            let lastEvent = previousEvents
                .filter { $0.endDate != nil && $0.endDate! <= now }
                .sorted(by: { $0.endDate! > $1.endDate! })
                .first
            newPreviousActivity = lastEvent.map { TimeActivity(from: $0) }
        }

        // --- Perform Atomic State Update on MainActor ---
        await MainActor.run {
            self.currentActivity = newCurrentActivity
            self.previousActivity = newPreviousActivity
            AppStorageService.saveCurrentActivity(self.currentActivity)
        }
    }
    
    func startNewSession(title: String, calendarId: String, duration: TimeInterval, startDate: Date) async throws {
        try await endCurrentActivity(endDate: startDate)
        
        guard let calendar = try await repository.getCalendar(withId: calendarId) else {
            throw NotFound.new(errorText: "Calendar not found", humanText: "Календарь не найден")
        }
        
        let event = EKEvent(eventStore: EKEventStore())
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration)
        event.calendar = calendar
        
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }
    
    func updateActivityEndTime(for activity: TimeActivity, by timeInterval: TimeInterval) async throws {
        guard let event = try await repository.getEvent(withId: activity.id) else {
            throw NotFound.new(errorText: "Event to update not found", humanText: "Событие для обновления не найдено")
        }
        
        event.endDate = event.endDate.addingTimeInterval(timeInterval)
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }

    func endCurrentActivity(endDate: Date) async throws {
        let activityID = await MainActor.run { self.currentActivity?.id }
        guard let activity = activityID else { return }
        
        let eventId = activity.components(separatedBy: "_part").first ?? ""
        guard let event = try await repository.getEvent(withId: eventId) else { return }
        
        event.endDate = endDate
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }

    func extendSession(eventId: String, by timeInterval: TimeInterval) async throws {
        guard let event = try await repository.getEvent(withId: eventId) else {
            throw NotFound.new(errorText: "Event to extend not found", humanText: "Событие для продления не найдено")
        }
        
        event.endDate = Date().addingTimeInterval(timeInterval)
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }

    func finishSessionNow(eventId: String) async throws {
        guard let event = try await repository.getEvent(withId: eventId) else {
            throw NotFound.new(errorText: "Event to finish not found", humanText: "Событие для завершения не найдено")
        }
        
        event.endDate = Date()
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }
    
    func updateActivity(_ activity: TimeActivity) async throws {
        let originalEventId = activity.id.components(separatedBy: "_part").first ?? activity.id
        guard let event = try await repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event to update not found", humanText: "Событие для обновления не найдено")
        }
        
        event.title = activity.title
        event.startDate = activity.startTime
        event.endDate = activity.endTime
        
        if let calendar = try await repository.getCalendar(withId: activity.calendarId) {
            event.calendar = calendar
        }
        
        try await repository.saveEvent(event)
        try await loadCurrentActivity()
    }
    
    func deleteActivity(_ activity: TimeActivity) async throws {
        let originalEventId = activity.id.components(separatedBy: "_part").first ?? activity.id
        guard let event = try await repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event to delete not found", humanText: "Событие для удаления не найдено")
        }
        
        try await repository.deleteEvent(event)
        try await loadCurrentActivity()
    }
    
    func getActivities(from startDate: Date, to endDate: Date) async throws -> [TimeActivity] {
        let timeTrackingCalendars = try await repository.getCalendars(with: calendarPrefix)
        let events = try await repository.getEvents(from: startDate, to: endDate, in: timeTrackingCalendars)
        
        // This mapping is pure computation and can happen on a background thread.
        var resultingActivities: [TimeActivity] = []
        for event in events {
            guard let eventEndDate = event.endDate else { continue }
            let calendar = Calendar.current
            let eventStartDate = event.startDate!

            if calendar.isDate(eventStartDate, inSameDayAs: eventEndDate) || eventEndDate == calendar.startOfDay(for: eventEndDate) {
                if eventStartDate != eventEndDate { resultingActivities.append(TimeActivity(from: event)) }
            } else {
                var currentDate = eventStartDate
                var partIndex = 1
                while currentDate < eventEndDate {
                    let startOfNextDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
                    let endOfThisSegment = min(startOfNextDay, eventEndDate)
                    if currentDate < endOfThisSegment {
                        resultingActivities.append(TimeActivity(
                            id: "\(event.eventIdentifier ?? UUID().uuidString)_part\(partIndex)",
                            title: event.title,
                            calendarId: event.calendar.calendarIdentifier,
                            calendarName: event.calendar.title,
                            startTime: currentDate,
                            endTime: endOfThisSegment,
                            category: event.calendar.title
                        ))
                    }
                    currentDate = endOfThisSegment
                    partIndex += 1
                }
            }
        }
        return resultingActivities
    }
    
    func getActivity(by id: String) async throws -> TimeActivity {
        let originalEventId = id.components(separatedBy: "_part").first ?? id
        
        guard let event = try await repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event not found by id", humanText: "Событие не найдено по ID")
        }
        
        return TimeActivity(from: event)
    }
    
    func getUniqueRecentActivities() async throws -> [TimeActivity] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        
        let allActivities = try await getActivities(from: startDate, to: endDate)
        
        var uniqueActivities: [TimeActivity] = []
        var seenTuples = Set<String>()
        
        for activity in allActivities.reversed() {
            let tuple = "\(activity.title)-\(activity.calendarId)"
            if !seenTuples.contains(tuple) {
                uniqueActivities.append(activity)
                seenTuples.insert(tuple)
            }
        }
        
        return uniqueActivities
    }
    
    @objc private func calendarDidChange() {
        logger.debug("Calendar data changed, reloading activities...")
        Task {
            do {
                try await loadCurrentActivity()
            } catch {
                logger.error("Failed to reload on calendar change: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        repository.removeObserver(self)
    }
}

extension TimeActivity {
    init(from event: EKEvent) {
        self.init(
            id: event.eventIdentifier,
            title: event.title,
            calendarId: event.calendar.calendarIdentifier,
            calendarName: event.calendar.title,
            startTime: event.startDate,
            endTime: event.endDate,
            category: event.calendar.title
        )
    }
}
