import Foundation

// Общие модели для основного приложения и виджета
struct TimeSession: Identifiable, Codable {
    let id = UUID()
    let title: String
    let calendarId: String
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

struct CalendarInfo: Identifiable, Codable {
    let id: String
    let title: String
    let color: String
} 