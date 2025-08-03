import Foundation
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")


@Observable
class HistoryViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var activitiesByDate: [Date: [TimeActivity]] = [:]
    
    var alert: AlertModel?
    
    var sortedDates: [Date] {
        activitiesByDate.keys.sorted(by: { $0 > $1 })
    }
    
    init() {
        Task {
            await fetchActivities()
        }
    }
    
    func fetchActivities() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
            let activities = try await calendarService.getActivities(from: startDate, to: endDate)
            
            activitiesByDate = Dictionary(grouping: activities, by: { activity in
                Calendar.current.startOfDay(for: activity.startTime)
            }).mapValues { activities in
                activities.sorted(by: { $0.startTime > $1.startTime })
            }
        } catch {
            alert = AlertModel(error: error)
        }
    }
}
