import Foundation

struct TimeSession: Identifiable, Codable {
    let id: String
    let title: String
    let calendarName: String
    let startTime: Date
    var endTime: Date
    let category: String?
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
