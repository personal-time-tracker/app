import Foundation
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")


enum EditActivityMode {
    case create
    case update
}

@MainActor
@Observable
class EditActivityViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var alert: AlertModel?
    
    var currentActivity: TimeActivity?
    private var oldActivity: TimeActivity?
    let mode: EditActivityMode
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    init(activity: TimeActivity, mode: EditActivityMode) {
        self.mode = mode
        
        Task {
            do {
                // "Склеиваем" событие: по ID "осколка" загружаем полную версию
                let fullActivity = try await calendarService.getActivity(by: activity.id)
                self.currentActivity = fullActivity
                self.oldActivity = fullActivity
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
    
    func save() {
        guard let activity = currentActivity else { return }
        Task {
            do {
                try await calendarService.updateActivity(activity)
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
    
    func delete() {
        guard let activity = oldActivity else { return }
        Task {
            do {
                try await calendarService.deleteActivity(activity)
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
}
