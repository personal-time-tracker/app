import SwiftUI
import WidgetKit

struct AppStorageService {
    @AppStorage("currentSession", store: UserDefaults(suiteName: "group.com.timetracer.app"))
    private static var currentSessionData: Data?

    @AppStorage("sessionHistory", store: UserDefaults(suiteName: "group.com.timetracer.app"))
    private static var sessionHistoryData: Data?

    static func saveCurrentActivity(_ session: TimeSession?) {
        if let session = session {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(session) {
                currentSessionData = encoded
            }
        } else {
            // Перед тем как обнулить сессию, добавляем ее в историю
            if let endedSession = getCurrentSession() {
                addSessionToHistory(endedSession)
            }
            currentSessionData = nil
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getCurrentSession() -> TimeSession? {
        guard let data = currentSessionData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(TimeSession.self, from: data)
    }

    private static func addSessionToHistory(_ session: TimeSession) {
        var history = getSessionHistory()
        history.insert(session, at: 0) // Добавляем в начало
        if history.count > 10 {
            history = Array(history.prefix(10)) // Ограничиваем до 10
        }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(history) {
            sessionHistoryData = encoded
        }
    }

    static func getSessionHistory() -> [TimeSession] {
        guard let data = sessionHistoryData else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([TimeSession].self, from: data)) ?? []
    }

    static func getRecentActivityTitles() -> [String] {
        let history = getSessionHistory()
        // Возвращаем уникальные названия, сохраняя порядок
        var uniqueTitles: [String] = []
        for session in history {
            if !uniqueTitles.contains(session.title) {
                uniqueTitles.append(session.title)
            }
        }
        return uniqueTitles
    }
} 
