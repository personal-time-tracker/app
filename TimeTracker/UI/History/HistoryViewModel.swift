import Foundation
import Factory

@Observable
class HistoryViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    var sessionsByDate: [Date: [TimeSession]] = [:]
    
    var sortedDates: [Date] {
        sessionsByDate.keys.sorted(by: { $0 > $1 })
    }
    
    init() {
        fetchSessions()
    }
    
    func fetchSessions() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        let sessions = calendarService.getSessions(from: startDate, to: endDate)
        
        sessionsByDate = Dictionary(grouping: sessions, by: { session in
            Calendar.current.startOfDay(for: session.startTime)
        })
    }
}
