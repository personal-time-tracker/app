import Foundation

struct TimeSession: Identifiable, Codable {
    
    init(
        title: String,
        calendarName: String,
        startTime: Date,
        endTime: Date? = nil,
        category: String?
    ) {
        self.title = title
        self.calendarName = calendarName
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
    }
    
    var id = UUID()
    let title: String
    let calendarName: String
    let startTime: Date
    var endTime: Date?
    let category: String?
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        return endTime == nil
    }
}
