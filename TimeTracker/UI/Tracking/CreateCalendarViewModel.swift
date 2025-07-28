import SwiftUI
import Factory

@Observable
class CreateCalendarViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var calendarTitle: String = ""
    
    let calendarPrefix: String
    
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
        calendarService.createCalendar(fullTitle: fullTitle)
    }
} 