import SwiftUI
import WidgetKit

struct AppStorageService {
    @AppStorage("currentSession", store: UserDefaults(suiteName: "group.com.timetracer.app"))
    private static var currentSessionData: Data?

    static func saveCurrentSession(_ session: TimeSession?) {
        if let session = session {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(session) {
                currentSessionData = encoded
            }
        } else {
            currentSessionData = nil
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getCurrentSession() -> TimeSession? {
        guard let data = currentSessionData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(TimeSession.self, from: data)
    }
} 