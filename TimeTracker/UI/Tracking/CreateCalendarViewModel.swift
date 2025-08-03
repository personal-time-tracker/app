import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")


@Observable
class CreateCalendarViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var calendarTitle: String = ""
    
    let calendarPrefix: String
    
    var alert: AlertModel?
    
    init() {
        let service = Container.shared.calendarService()
        self.calendarPrefix = service.calendarPrefix
    }
    
    var isTitleValid: Bool {
        !calendarTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func createCalendar() {
        guard isTitleValid else { return }
        let title = calendarTitle.trimmingCharacters(in: .whitespaces)
        let fullTitle = "\(calendarPrefix) \(title)"
        do {
            try calendarService.createCalendar(fullTitle: fullTitle)
        } catch {
            alert = AlertModel(error: error)
        }
    }
}
