import Foundation
import Factory

enum EditActivityMode {
    case create
    case update
}

@Observable
class EditActivityViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var currentActivity: TimeActivity
    private let oldActivity: TimeActivity
    let mode: EditActivityMode
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    init(activity: TimeActivity, mode: EditActivityMode) {
        self.currentActivity = activity
        self.oldActivity = activity
        self.mode = mode
    }
    
    func save() {
        calendarService.updateActivity(currentActivity)
    }
    
    func delete() {
        calendarService.deleteActivity(oldActivity)
    }
} 