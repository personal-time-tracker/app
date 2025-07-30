import SwiftUI
import Factory

@Observable
class CreateCalendarViewModel {
    
    @ObservationIgnored @Injected(\.calendarService) private var calendarService
    @ObservationIgnored @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
    
    var alert: AlertModel?
    
    var isDisableSaveButton: Bool {
        currentCalendar.title.isEmpty
    }
    
    var currentCalendar: CalendarInfo
    
    init(currentCalendar: CalendarInfo) {
        self.currentCalendar = currentCalendar
    }
    
    func createCalendar() {
        
        do {
            
            // Конвертируем в структуру создания
            var req = currentCalendar.convertToCreateCalendar()
            
            // Удаляем пробелы в начале и конце
            req.title = req.title.trimmingCharacters(in: .whitespaces)
            
            // Добавляем префикс
            req.title = "\(calendarPrefix) \(req.title)"
            
            // Создаем календарь
            try calendarService.createCalendar(req: req)
            
        } catch {
        
            alert = AlertModel(error: error)
        }
    }
} 
