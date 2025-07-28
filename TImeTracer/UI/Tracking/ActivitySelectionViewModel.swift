import SwiftUI
import Factory

@MainActor
@Observable
class ActivitySelectionViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var activityTitle = ""
    var selectedCalendarId = ""
    var showingCreateCalendarSheet = false
    
    var hours: Int = 1
    var minutes: Int = 0
    
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
    
    func startActivity() {
        guard canStartActivity else { return }
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let timeInterval = TimeInterval(hours * 3600 + minutes * 60)
        
        // Task и await здесь не нужны, так как и ViewModel, и Service - MainActor
        calendarService.startNewSession(title: trimmedTitle, calendarId: selectedCalendarId, duration: timeInterval)
    }
} 
