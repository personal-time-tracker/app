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
    
    var alert: AlertModel?
    
    var currentActivity: TimeActivity?
    private var oldActivity: TimeActivity?
    let mode: EditActivityMode
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    init(activity: TimeActivity, mode: EditActivityMode) {
        self.mode = mode
        
        // "Склеиваем" событие: по ID "осколка" загружаем полную версию
        if let fullActivity = calendarService.getActivity(by: activity.id) {
            self.currentActivity = fullActivity
            self.oldActivity = fullActivity
        }
    }
    
    func save() {
        guard let activity = currentActivity else { return }
        calendarService.updateActivity(activity)
    }
    
    func delete() {
        guard let activity = oldActivity else { return }
        calendarService.deleteActivity(activity)
    }
} 
