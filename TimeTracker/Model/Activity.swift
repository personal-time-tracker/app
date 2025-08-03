import Foundation

struct Activity: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var calendarId: String = ""
    var calendarName: String = ""
    var startTime: Date = Date()
    var endTime: Date = Date()
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        startTime <= Date.now && Date.now < endTime
    }
    
    var isPrevious: Bool {
        Date.now < startTime
    }
    
    // Сравнивает две структуры и отдает дифф для обновления этой структуры
    func compareAndReturnUpdateDiff(with other: Activity) throws -> UpdateActivity {
        
        let map = ["old": self, "new": other]
        
        // Сравниваем полностью
        guard self != other else {
            throw UserError.new(
                errorText: "Structs are equal",
                humanText: "Нечего обновлять",
                parameters: map
            )
        }
        
        // Сравниваем идентификаторы
        guard self.id == other.id else {
            throw InternalError.new(
                errorText: "Try to compare activities with different id",
                humanText: "Произошла ошибка",
                parameters: map
            )
        }
        
        // Создаем базовую структуру
        var updateReq = UpdateActivity(
            id: self.id
        )
        
        // Проходимся по каждому полю и сравниваем с каждым полем
        if self.title != other.title {
            updateReq.title = other.title
        }
        if self.calendarId != other.calendarId {
            updateReq.calendarId = other.calendarId
        }
        if self.startTime != other.startTime {
            updateReq.startTime = other.startTime
        }
        if self.endTime != other.endTime {
            updateReq.endTime = other.endTime
        }
        
        return updateReq
    }
    
    func convertToCreateActivity() -> CreateActivity {
        CreateActivity(
            title: self.title,
            calendarId: self.calendarId,
            startTime: self.startTime,
            endTime: self.endTime
        )
    }
    
    mutating func patch(req: UpdateActivity) {
        if let title = req.title {
            self.title = title
        }
        if let calendarId = req.calendarId {
            self.calendarId = calendarId
        }
        if let startTime = req.startTime {
            self.startTime = startTime
        }
        if let endTime = req.endTime {
             self.endTime = endTime
         }
    }
}

struct CreateActivity {
    var title: String
    var calendarId: String
    var startTime: Date
    var endTime: Date
    
    func convertToActivity() -> Activity {
        Activity(
            id: UUID().uuidString,
            title: self.title,
            calendarId: self.calendarId,
            startTime: self.startTime,
            endTime: self.endTime
        )
    }
}

struct UpdateActivity {
    var id: String
    var title: String?
    var calendarId: String?
    var startTime: Date?
    var endTime: Date?
}
