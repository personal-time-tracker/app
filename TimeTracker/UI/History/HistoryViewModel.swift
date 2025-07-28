import Foundation
import Factory

@Observable
class HistoryViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var activitiesByDate: [Date: [TimeActivity]] = [:]
    
    
    var sortedDates: [Date] {
        activitiesByDate.keys.sorted(by: { $0 > $1 })
    }
    
    init() {
        fetchActivities()
    }
    
    func fetchActivities() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        let activities = calendarService.getActivities(from: startDate, to: endDate)
        
        activitiesByDate = Dictionary(grouping: activities, by: { activity in
            Calendar.current.startOfDay(for: activity.startTime)
        }).mapValues { activities in
            activities.sorted(by: { $0.startTime > $1.startTime })
        }
    }
}
