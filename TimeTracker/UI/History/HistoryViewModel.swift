import Foundation
import Factory

@Observable
class HistoryViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var activitiesByDate: [Date: [Activity]] {
        Dictionary(grouping: calendarService.activities, by: { activity in
            Calendar.current.startOfDay(for: activity.startTime)
        }).mapValues { activities in
            activities.sorted(by: { $0.startTime > $1.startTime })
        }
    }
    
    var sortedDates: [Date] {
        activitiesByDate.keys.sorted(by: { $0 > $1 })
    }
}
