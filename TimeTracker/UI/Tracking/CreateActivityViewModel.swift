import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@MainActor
@Observable
class CreateActivityViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var activityTitle = ""
    var selectedCalendarId = ""
    var showingCreateCalendarSheet = false
    
    var hours: Int = 1
    var minutes: Int = 0
    var startTime = Date()
    
    var recentActivities: [TimeActivity] = []
    
    var alert: AlertModel?
    
    var filteredActivities: [TimeActivity] {
        if activityTitle.isEmpty {
            return recentActivities
        }
        return recentActivities.filter {
            $0.title.lowercased().contains(activityTitle.lowercased()) && $0.title.lowercased() != activityTitle.lowercased()
        }
    }
    
    var lastFinishedActivity: TimeActivity? {
        recentActivities.first(where: { $0.endTime < Date() })
    }
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    var calendarPrefix: String {
        calendarService.calendarPrefix
    }
    
    func refreshCalendarsIfNeeded() {
        if calendarService.calendars.isEmpty {
            calendarService.loadCalendars()
        }
        
        // Загружаем недавние активности
        recentActivities = calendarService.getUniqueRecentActivities()
        
        // Если остался только один календарь, выбираем его автоматически
        if calendars.count == 1 {
            selectedCalendarId = calendars.first?.id ?? ""
        }
    }
    
    var canStartActivity: Bool {
        !activityTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCalendarId.isEmpty &&
        (hours > 0 || minutes > 0) // Продолжительность должна быть больше нуля
    }
    
    func selectSuggestion(_ activity: TimeActivity) {
        activityTitle = activity.title
        selectedCalendarId = activity.calendarId
    }
    
    func setStartTimeFromPrevious() {
        if let lastEndTime = lastFinishedActivity?.endTime {
            startTime = lastEndTime
        }
    }
    
    func startActivity() throws {
        guard canStartActivity else { return }
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let timeInterval = TimeInterval(hours * 3600 + minutes * 60)
        
        do {
            try calendarService.startNewSession(title: trimmedTitle, calendarId: selectedCalendarId, duration: timeInterval, startDate: startTime)
        } catch {
            alert = AlertModel(error: error)
            throw error
        }
    }
}
