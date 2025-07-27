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
    
    func perform() async throws -> some IntentResult {
        // Отправляем уведомление в приложение
        NotificationCenter.default.post(
            name: .startTimeTracking,
            object: nil,
            userInfo: [
                "activityTitle": activityTitle,
                "calendarId": calendarId
            ]
        )
        
        return .result()
    }
}

struct EndTimeTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Завершить трекинг времени"
    static var description: LocalizedStringResource = "Завершает текущую сессию трекинга времени"
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .endTimeTracking, object: nil)
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