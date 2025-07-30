import SwiftUI
import WidgetKit

struct AppStorageService {
    @AppStorage("currentActivity", store: UserDefaults(suiteName: "group.com.timetracer.app"))
    private static var currentActivityData: Data?

    static func saveCurrentActivity(_ activity: Activity?) {
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

    static func getCurrentActivity() -> Activity? {
        guard let data = currentActivityData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Activity.self, from: data)
    }
} 
