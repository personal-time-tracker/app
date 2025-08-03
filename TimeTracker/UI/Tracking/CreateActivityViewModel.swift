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
    
    func refreshData() {
        Task {
            do {
                if calendarService.calendars.isEmpty {
                    try await calendarService.loadCalendars()
                }
                self.recentActivities = try await calendarService.getUniqueRecentActivities()
                
                if calendars.count == 1 {
                    selectedCalendarId = calendars.first?.id ?? ""
                }
            } catch {
                self.alert = AlertModel(error: error)
            }
        }
    }
    
    var canStartActivity: Bool {
        !activityTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCalendarId.isEmpty &&
        (hours > 0 || minutes > 0)
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
    
    // This function is now async and throws, allowing the View to await its result.
    func startActivity() async throws {
        guard canStartActivity else { return }
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeInterval = TimeInterval(hours * 3600 + minutes * 60)
        
        try await calendarService.startNewSession(title: trimmedTitle, calendarId: selectedCalendarId, duration: timeInterval, startDate: startTime)
    }
}
