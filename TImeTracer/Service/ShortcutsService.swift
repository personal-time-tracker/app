import Foundation
import AppIntents

struct StartTimeTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Начать трекинг времени"
    static var description: LocalizedStringResource = "Начинает новую сессию трекинга времени"
    
    @Parameter(title: "Название занятия")
    var activityTitle: String
    
    @Parameter(title: "Календарь")
    var calendarId: String
    
    init() {}
    
    init(activityTitle: String, calendarId: String) {
        self.activityTitle = activityTitle
        self.calendarId = calendarId
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let calendarService = CalendarService()
        let sharedDefaults = UserDefaults(suiteName: "group.com.timetracer.app")
        let calendarIdToUse = self.calendarId ?? sharedDefaults?.string(forKey: "selectedCalendarId") ?? ""
        
        guard !calendarIdToUse.isEmpty else {
            return .result()
        }
        
        calendarService.startNewSession(title: activityTitle, calendarId: calendarIdToUse)
        
        return .result()
    }
}

struct EndTimeTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Завершить трекинг времени"
    static var description: LocalizedStringResource = "Завершает текущую сессию трекинга времени"
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let calendarService = CalendarService()
        calendarService.endCurrentSession()
        
        return .result()
    }
}

extension Notification.Name {
    static let startTimeTracking = Notification.Name("startTimeTracking")
    static let endTimeTracking = Notification.Name("endTimeTracking")
}

class ShortcutsService: ObservableObject {
    static let shared = ShortcutsService()
    
    private init() {}
    
    func registerIntents() {
        // Регистрируем интенты для Shortcuts
        // В реальном приложении это делается через App Intents framework
    }
} 
