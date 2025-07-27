import Foundation
import EventKit
import AppIntents

// Интент для выбора календаря
@available(iOS 16.0, *)
struct SelectCalendarIntent: AppIntent {
    static var title: LocalizedStringResource = "Выбрать календарь"
    static var description: LocalizedStringResource = "Выбирает календарь для трекинга"
    
    @Parameter(title: "Календарь")
    var calendarId: String
    
    init() {}
    
    init(calendarId: String) {
        self.calendarId = calendarId
    }
    
    func perform() async throws -> some IntentResult {
        // Сохраняем выбранный календарь
        UserDefaults.standard.set(calendarId, forKey: "selectedCalendarId")
        return .result()
    }
}

// Интент для получения списка календарей
@available(iOS 16.0, *)
struct GetCalendarsIntent: AppIntent {
    static var title: LocalizedStringResource = "Получить календари"
    static var description: LocalizedStringResource = "Возвращает список доступных календарей"
    
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        let calendarTitles = calendars.map { $0.title }
        return .result(value: calendarTitles)
    }
} 
