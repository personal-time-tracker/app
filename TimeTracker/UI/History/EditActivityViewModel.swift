import Foundation
import Factory

enum EditActivityMode {
    case create
    case update
}

@Observable
class EditActivityViewModel {
    
    // MARK: - Parameters
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var currentActivity: Activity
    private var oldActivity: Activity
    var alert: AlertModel?
    var calendarID: String? {
        didSet {
            currentActivity.calendarId = calendarID ?? ""
        }
    }
    
    var durationHours: Int = 0 {
        didSet {
            addDurationToEndTime()
        }
    }
    var durationMinutes: Int = 0 {
        didSet {
            addDurationToEndTime()
        }
    }
    
    func addDurationToEndTime() {
        currentActivity.endTime = Date().addingTimeInterval(TimeInterval(durationHours * 3600 + durationMinutes * 60))
    }
    
    private var activities: [Activity] = []
    
    var lastFinishedActivity: Activity? {
        activities.first(where: { $0.endTime <= currentActivity.startTime })
    }
    
    let mode: EditActivityMode
    
    var calendars: [CalendarInfo] {
        calendarService.calendars
    }
    
    // MARK: - Init
    
    init(
        currentActivity: Activity,
        oldActivity: Activity = Activity(),
        mode: EditActivityMode
    ) {
        self.mode = mode
        
        self.currentActivity = currentActivity
        self.oldActivity = oldActivity
        
        if mode == .update {
            
            // "Склеиваем" событие: по ID "осколка" загружаем полную версию
            if let fullActivity = calendarService.getSplittedActivity(by: currentActivity.id) {
                self.currentActivity = fullActivity
                self.oldActivity = fullActivity
            }
        } else {
            
            // По дефолту ставим 1
            durationHours = 1
        }
    }
    
    // MARK: - UI
    
    var isDisabledSaveButton: Bool {
        switch mode {
        case .create:
            currentActivity.title == "" || durationHours == 0 && durationMinutes == 0 || currentActivity.calendarId == ""
        case .update:
            currentActivity == oldActivity
        }
    }
    
    var isShowSuggestionAutoStartTime: Bool {
        guard let lastFinishedActivity else { return false }
        return currentActivity.startTime != lastFinishedActivity.endTime
    }
    
    // MARK: - Activity Suggestions
    
    private let limitActivitiesSuggestions: Int = 5
    var isSuggestionsExpanded = false
    var isShowExpandedButton: Bool {
        suggestionActivities.count > limitActivitiesSuggestions
    }
    var totalSuggestionsCount: Int = 0
    var suggestionActivities: [Activity] {
        
        var activities = activities
        
        // Фильтруем по названию, если оно не пустое
        if !currentActivity.title.isEmpty {
            
            activities = activities.filter {
                $0.title.lowercased().contains(currentActivity.title.lowercased()) && $0.title.lowercased() != currentActivity.title.lowercased()
            }
        }
        
        totalSuggestionsCount = activities.count
        
        // Лимитируем события
        if activities.count > limitActivitiesSuggestions && !isSuggestionsExpanded {
            activities = Array(activities[0..<limitActivitiesSuggestions])
        }
        
        return activities
    }
    
    func selectSuggestion(_ activity: Activity) {
        currentActivity.title = activity.title
        currentActivity.calendarId = activity.calendarId
        currentActivity.calendarName = activity.calendarName
    }
    
    // MARK: - Functions
    
    func setStartTimeFromPrevious() {
        guard let lastFinishedActivity else { return }
        currentActivity.startTime = lastFinishedActivity.endTime
    }
    
    func save() {
        do {
            switch mode{
            case .create:
                try calendarService.createActivity(req: currentActivity.convertToCreateActivity())
            case .update:
                try calendarService.updateActivity(req: try currentActivity.compareAndReturnUpdateDiff(with: oldActivity))
            }
        } catch {
            alert = AlertModel(error: error)
        }
    }
    
    func delete() {
        do {
            try calendarService.deleteActivity(id: currentActivity.id)
        } catch {
            alert = AlertModel(error: error)
        }
    }
} 
