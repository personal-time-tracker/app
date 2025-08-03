import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")


@MainActor
@Observable
class CreateCalendarViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var calendarTitle: String = ""
    
    var calendarPrefix: String {
        calendarService.calendarPrefix
    }
    
    var alert: AlertModel?
    
    var isTitleValid: Bool {
        !calendarTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func createCalendar() {
        guard isTitleValid else { return }
        let title = calendarTitle.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                try await calendarService.createCalendar(title: title)
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
}
