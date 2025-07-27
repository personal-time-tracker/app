import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var calendarPrefix: String {
        didSet {
            UserDefaults.standard.set(calendarPrefix, forKey: "calendarPrefix")
        }
    }
    
    private init() {
        self.calendarPrefix = UserDefaults.standard.string(forKey: "calendarPrefix") ?? "⏱️"
    }
    
    // Предустановленные префиксы
    static let defaultPrefixes = [
        "⏱️",
        "📅", 
        "🕐",
        "⏰",
        "TIME",
        "TRACK",
        "[TIME]",
        "[TRACK]"
    ]
} 