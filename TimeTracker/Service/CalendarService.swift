import Foundation
import EventKit
import Combine
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@Observable
class CalendarService {
    
    private let repository = CalendarRepository()
    
    var calendars: [CalendarInfo] = []
    var currentActivity: TimeActivity?
    var previousActivity: TimeActivity?
    
    @ObservationIgnored
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
        
    init() {
        let status = repository.getAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            requestAccess()
        case .authorized, .fullAccess, .writeOnly:
            loadCalendars()
            loadCurrentActivity()
        case .denied, .restricted:
            // TODO: Handle denied access properly, maybe show an alert to the user.
            break
        @unknown default:
            break
        }
        
        repository.addObserver(self, selector: #selector(calendarDidChange))
    }
    
    func requestAccess() {
        Task {
            do {
                let granted = try await repository.requestAccess()
                if granted {
                    await MainActor.run {
                        self.loadCalendars()
                        self.loadCurrentActivity()
                    }
                }
            } catch {
                // TODO: Handle error properly.
                logger.error("Error requesting calendar access: \(error.localizedDescription)")
            }
        }
    }
    
    func createCalendar(title: String) throws {
        let fullTitle = "\(calendarPrefix) \(title)"
        _ = try repository.createCalendar(title: fullTitle)
        loadCalendars() // Refresh the list
    }
    
    func loadCalendars() {
        do {
            let ekCalendars = try repository.getCalendars(with: calendarPrefix)
            self.calendars = ekCalendars.map { calendar in
                CalendarInfo(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    color: calendar.cgColor?.components?.map(String.init).joined(separator: ",") ?? ""
                )
            }
        } catch {
            // TODO: Handle error properly.
            logger.error("Failed to load calendars: \(error.localizedDescription)")
            self.calendars = []
        }
    }
    
    func loadCurrentActivity() {
        do {
            let now = Date()
            let timeTrackingCalendars = try repository.getCalendars(with: calendarPrefix)
            
            guard !timeTrackingCalendars.isEmpty else {
                currentActivity = nil
                AppStorageService.saveCurrentActivity(nil)
                return
            }
            
            // Ищем события, которые происходят прямо сейчас
            let events = try repository.getEvents(
                from: now.addingTimeInterval(-3600),
                to: now.addingTimeInterval(3600),
                in: timeTrackingCalendars
            )
            
            let currentEvent = events.last { event in
                event.startDate <= now && (event.endDate == nil || event.endDate > now)
            }
            
            if let event = currentEvent {
                currentActivity = TimeActivity(from: event)
            } else {
                currentActivity = nil
            }
            
            AppStorageService.saveCurrentActivity(currentActivity)
            loadPreviousActivity()
            
        } catch {
            // TODO: Handle error properly.
            logger.error("Failed to load current activity: \(error.localizedDescription)")
            currentActivity = nil
            AppStorageService.saveCurrentActivity(nil)
        }
    }
    
    func loadPreviousActivity() {
        do {
            let now = Date()
            let timeTrackingCalendars = try repository.getCalendars(with: calendarPrefix)
            
            guard !timeTrackingCalendars.isEmpty else {
                previousActivity = nil
                return
            }
            
            let events = try repository.getEvents(
                from: now.addingTimeInterval(-24 * 3600),
                to: now,
                in: timeTrackingCalendars
            )
            
            let lastEvent = events
                .filter { $0.endDate != nil && $0.endDate! <= now }
                .sorted(by: { $0.endDate! > $1.endDate! })
                .first
                
            if let event = lastEvent {
                previousActivity = TimeActivity(from: event)
            } else {
                previousActivity = nil
            }
        } catch {
            // TODO: Handle error properly.
            logger.error("Failed to load previous activity: \(error.localizedDescription)")
            previousActivity = nil
        }
    }
    
    func startNewSession(title: String, calendarId: String, duration: TimeInterval, startDate: Date) throws {
        let newSessionStartDate = startDate
        
        try endCurrentActivity(endDate: newSessionStartDate)
        
        guard let calendar = try repository.getCalendar(withId: calendarId) else {
            throw NotFound.new(errorText: "Calendar not found", humanText: "Календарь не найден")
        }
        
        let event = EKEvent(eventStore: EKEventStore()) // Dummy store, repository will use its own
        event.title = title
        event.startDate = newSessionStartDate
        event.endDate = newSessionStartDate.addingTimeInterval(duration)
        event.calendar = calendar
        
        try repository.saveEvent(event)
        
        loadCurrentActivity()
    }
    
    func updateActivityEndTime(for activity: TimeActivity, by timeInterval: TimeInterval) throws {
        guard let event = try repository.getEvent(withId: activity.id) else {
            throw NotFound.new(
                errorText: "Cannot find event to update end time",
                humanText: "Не найдено событие для изменения времени окончания",
                parameters: ["activityId": activity.id]
            )
        }
        
        event.endDate = event.endDate.addingTimeInterval(timeInterval)
        
        try repository.saveEvent(event)
        loadCurrentActivity() // Обновляем UI
    }

    func endCurrentActivity(endDate: Date) throws {
        guard let activity = currentActivity else { return }
        let eventId = activity.id.components(separatedBy: "_part").first ?? ""
        
        guard let event = try repository.getEvent(withId: eventId) else {
            throw NotFound.new(errorText: "Event to end not found", humanText: "Событие для завершения не найдено")
        }
        
        event.endDate = endDate
        try repository.saveEvent(event)
        
        loadCurrentActivity()
    }

    func extendSession(eventId: String, by timeInterval: TimeInterval) throws {
        guard let event = try repository.getEvent(withId: eventId) else {
            throw NotFound.new(errorText: "Event to extend not found", humanText: "Событие для продления не найдено")
        }
        
        event.endDate = Date().addingTimeInterval(timeInterval)
        try repository.saveEvent(event)
        
        loadPreviousActivity()
        loadCurrentActivity()
    }

    func finishSessionNow(eventId: String) throws {
        guard let event = try repository.getEvent(withId: eventId) else {
            throw NotFound.new(errorText: "Event to finish not found", humanText: "Событие для завершения не найдено")
        }
        
        event.endDate = Date()
        try repository.saveEvent(event)
        
        loadPreviousActivity()
        loadCurrentActivity()
    }
    
    func updateActivity(_ activity: TimeActivity) throws {
        let originalEventId = activity.id.components(separatedBy: "_part").first ?? activity.id
        guard let event = try repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event to update not found", humanText: "Событие для обновления не найдено")
        }
        
        event.title = activity.title
        event.startDate = activity.startTime
        event.endDate = activity.endTime
        
        if let calendar = try repository.getCalendar(withId: activity.calendarId) {
            event.calendar = calendar
        }
        
        try repository.saveEvent(event)
        loadCurrentActivity()
    }
    
    func deleteActivity(_ activity: TimeActivity) throws {
        let originalEventId = activity.id.components(separatedBy: "_part").first ?? activity.id
        guard let event = try repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event to delete not found", humanText: "Событие для удаления не найдено")
        }
        
        try repository.deleteEvent(event)
        loadCurrentActivity()
    }
    
    func getActivities(from startDate: Date, to endDate: Date) -> [TimeActivity] {
        do {
            let timeTrackingCalendars = try repository.getCalendars(with: calendarPrefix)
            let events = try repository.getEvents(from: startDate, to: endDate, in: timeTrackingCalendars)
            
            var resultingActivities: [TimeActivity] = []

            for event in events {
                guard let eventEndDate = event.endDate else { continue }

                let calendar = Calendar.current
                let eventStartDate = event.startDate!

                if calendar.isDate(eventStartDate, inSameDayAs: eventEndDate) || eventEndDate == calendar.startOfDay(for: eventEndDate) {
                    if eventStartDate != eventEndDate {
                        resultingActivities.append(TimeActivity(from: event))
                    }
                } else {
                    var currentDate = eventStartDate
                    var partIndex = 1
                    while currentDate < eventEndDate {
                        let startOfNextDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
                        let endOfThisSegment = min(startOfNextDay, eventEndDate)
                        if currentDate < endOfThisSegment {
                            let activityPart = TimeActivity(
                                id: "\(event.eventIdentifier ?? UUID().uuidString)_part\(partIndex)",
                                title: event.title,
                                calendarId: event.calendar.calendarIdentifier,
                                calendarName: event.calendar.title,
                                startTime: currentDate,
                                endTime: endOfThisSegment,
                                category: event.calendar.title
                            )
                            resultingActivities.append(activityPart)
                        }
                        currentDate = endOfThisSegment
                        partIndex += 1
                    }
                }
            }
            return resultingActivities
        } catch {
            // TODO: Handle error properly
            logger.error("Failed to get activities: \(error.localizedDescription)")
            return []
        }
    }
    
    func getActivity(by id: String) throws -> TimeActivity {
        let originalEventId = id.components(separatedBy: "_part").first ?? id
        
        guard let event = try repository.getEvent(withId: originalEventId) else {
            throw NotFound.new(errorText: "Event not found by id", humanText: "Событие не найдено по ID")
        }
        
        return TimeActivity(from: event)
    }
    
    func getUniqueRecentActivities() -> [TimeActivity] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        
        let allActivities = getActivities(from: startDate, to: endDate)
        
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
    
    // MARK: - Calendar Synchronization
    
    @objc private func calendarDidChange() {
        logger.debug("Calendar data changed, reloading activities...")
        DispatchQueue.main.async { [weak self] in
            self?.loadCurrentActivity()
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
