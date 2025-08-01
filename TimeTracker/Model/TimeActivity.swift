import Foundation

struct TimeActivity: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var calendarId: String
    var calendarName: String
    var startTime: Date
    var endTime: Date
    let category: String?
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
