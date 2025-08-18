import SwiftUI
import WidgetKit
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

struct AppStorageService {
    @AppStorage("currentActivity", store: UserDefaults(suiteName: "group.com.timetracer.app"))
    private static var currentActivityData: Data?

    static func saveCurrentActivity(_ activity: TimeActivity?) {
        if let activity = activity {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(activity) {
                currentActivityData = encoded
            }
        } else {
            currentActivityData = nil
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getCurrentActivity() -> TimeActivity? {
        guard let data = currentActivityData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(TimeActivity.self, from: data)
    }
} 
