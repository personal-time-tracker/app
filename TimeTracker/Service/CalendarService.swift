import Foundation
import EventKit
import Combine
import SwiftUI



@Observable
class CalendarService {
    
    // MARK: Dependencies
    @ObservationIgnored
    private let calendarRepository: CalendarRepository
    private let widgetSyncController: WidgetSyncController
    
    // MARK: Init
    init(
        calendarRepository: CalendarRepository,
        widgetSyncController: WidgetSyncController
    ) {
        self.calendarRepository = calendarRepository
        self.widgetSyncController = widgetSyncController
    }
    
    // MARK: ProxyState
    
    var calendars: [CalendarInfo] {
        calendarRepository.calendars
    }
    
    var activities: [Activity] {
        calendarRepository.events
    } 
    
    // MARK: Computed
    
    // Предыдущее событие
    var previousActivity: Activity? {
        activities.filter{ $0.endTime < Date.now }.last
    }
    
    // Активное событие
    var currentActivity: Activity? {
        activities.filter{ $0.isActive }.last
    }
    
    // MARK: Functions
    
    // Создает календарь
    func createCalendar(req: CreateCalendar) async throws {
        try await calendarRepository.createCalendar(req: req)
    }
    
    // Обновляет календари
    func loadData() async throws {
        try await calendarRepository.loadCalendars()
        try await calendarRepository.loadEvents()
        widgetSyncController.saveCurrentActivityInDefaults(currentActivity)
    }
    
    // Создает активность
    func createActivity(req: CreateActivity) async throws {
        try await calendarRepository.createEvent(req: req)
    }
    
    // Обновляет активность
    func updateActivity(req: UpdateActivity) async throws {
        try await calendarRepository.updateEvent(req: req)
    }
    
    // Удаляет активность
    func deleteActivity(id: String) async throws {
        try await calendarRepository.deleteEvent(id: id)
    }
    
    // Возвращает активность, которая была разделена на две из-за пересечения 00:00
    func getSplittedActivity(by id: String) -> Activity? {
        
        // Извлекаем оригинальный ID, отбрасывая суффикс "_part"
        let originalEventId = id.components(separatedBy: "_part").first ?? id
        
        // Возвращаем полную, неразрезанную активность
        return activities.filter { $0.id == originalEventId }.first
    }
    
    func getUniqueActivities() -> [Activity] {
        
        var uniqueActivities: [Activity] = []
        var seenTuples = Set<String>()
        
        for activity in activities.reversed() { // Начинаем с самых свежих
            let tuple = "\(activity.title)-\(activity.calendarId)"
            if !seenTuples.contains(tuple) {
                uniqueActivities.append(activity)
                seenTuples.insert(tuple)
            }
        }
        
        return uniqueActivities
    }
} 
