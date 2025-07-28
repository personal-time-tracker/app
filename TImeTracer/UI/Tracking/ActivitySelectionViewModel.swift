import SwiftUI
import Factory

@Observable
class ActivitySelectionViewModel {
    
    @ObservationIgnored 
    @Injected(\.calendarService) private var calendarService
    
    var activityTitle = ""
    var selectedCalendarId = ""
    var showingCreateCalendarSheet = false
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    var calendarPrefix: String {
        calendarService.calendarPrefix
    }
    
    var canStartActivity: Bool {
        !activityTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCalendarId.isEmpty
    }
    
    func startActivity() {
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        calendarService.startNewSession(title: trimmedTitle, calendarId: selectedCalendarId)
    }
} 