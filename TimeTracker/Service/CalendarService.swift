import Foundation
import EventKit
import Combine
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@Observable
class CalendarService {
    
    @ObservationIgnored
    private let eventStore = EKEventStore()
    
    var calendars: [CalendarInfo] = []
    var currentActivity: TimeActivity?
    var previousActivity: TimeActivity?
    
    @ObservationIgnored
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
        
    init() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            requestAccess()
        case .authorized, .fullAccess, .writeOnly:
            loadCalendars()
            loadCurrentActivity()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
        
        // Регистрируем наблюдателя за изменениями в календаре
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarDidChange),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    func requestAccess() {
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    await MainActor.run {
                        if granted {
                            self.loadCalendars()
                            self.loadCurrentActivity()
                        }
                    }
                } catch {
                    eventStore.requestFullAccessToEvents { [weak self] granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                self?.loadCalendars()
                                self?.loadCurrentActivity()
                            }
                        }
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.loadCalendars()
                        self?.loadCurrentActivity()
                    }
                }
            }
        }
    }
    
    func createCalendar(fullTitle: String) throws {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = fullTitle
        
        // Пытаемся найти источник. Если не находим, используем дефолтный.
        if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCalendar.source = source
        } else {
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            // После создания сразу обновляем список календарей
            loadCalendars()
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось создать календарь",
                parameters: ["title": fullTitle]
            )
        }
    }
    
    func loadCalendars() {
        let ekCalendars = eventStore.calendars(for: .event)
        
        // Фильтруем календари по настраиваемому префиксу
        let filteredCalendars = ekCalendars.filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        calendars = filteredCalendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.cgColor?.components?.map(String.init).joined(separator: ",") ?? ""
            )
        }
    }
    
    func loadCurrentActivity() {
        let now = Date()
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        // Если нет календарей с префиксом, не показываем ничего
        guard !timeTrackingCalendars.isEmpty else {
            currentActivity = nil
            AppStorageService.saveCurrentActivity(nil)
            return
        }
        
        // Ищем события, которые происходят прямо сейчас
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // 1 час назад
            end: now.addingTimeInterval(3600), // 1 час вперед
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
        
        // Ищем событие, которое активно сейчас (началось, но не закончилось)
        let currentEvent = events.last { event in
            event.startDate <= now && (event.endDate == nil || event.endDate > now)
        }
        
        if let event = currentEvent {
            currentActivity = TimeActivity(
                id: event.eventIdentifier, // Сохраняем ID
                title: event.title,
                calendarId: event.calendar.calendarIdentifier,
                calendarName: event.calendar.title,
                startTime: event.startDate,
                endTime: event.endDate,
                category: event.calendar.title
            )
        } else {
            currentActivity = nil
        }
        
        // Сохраняем для виджета
        AppStorageService.saveCurrentActivity(currentActivity)
        
        // После загрузки текущей сессии, загружаем последнюю завершенную
        loadPreviousActivity()
    }
    
    func loadPreviousActivity() {
        let now = Date()
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        guard !timeTrackingCalendars.isEmpty else {
            previousActivity = nil
            return
        }
        
        // Ищем события за последний день, чтобы найти последнее
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-24 * 3600), // День назад
            end: now, // До текущего момента
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
            .filter { $0.endDate != nil && $0.endDate! <= now } // Только завершенные
            .sorted(by: { $0.endDate! > $1.endDate! }) // Сортируем по дате окончания, самые новые вверху
            
        if let lastEvent = events.first {
            previousActivity = TimeActivity(
                id: lastEvent.eventIdentifier,
                title: lastEvent.title,
                calendarId: lastEvent.calendar.calendarIdentifier,
                calendarName: lastEvent.calendar.title,
                startTime: lastEvent.startDate,
                endTime: lastEvent.endDate,
                category: lastEvent.calendar.title
            )
        } else {
            previousActivity = nil
        }
    }
    
    func startNewSession(title: String, calendarId: String, duration: TimeInterval, startDate: Date) throws {
        // Запоминаем точное время начала новой сессии
        let newSessionStartDate = startDate
        
        // Завершаем текущую сессию, устанавливая ее конец точно в момент начала новой
        try endCurrentActivity(endDate: newSessionStartDate)
        
        // Создаем событие в календаре, начиная с того же самого момента
        try createCalendarEvent(title: title, calendarId: calendarId, duration: duration, startDate: newSessionStartDate)
        
        // Перезагружаем текущую сессию из календаря
        loadCurrentActivity()
    }
    
    func updateActivityEndTime(for activity: TimeActivity, by timeInterval: TimeInterval) throws {
        guard let event = eventStore.event(withIdentifier: activity.id) else {
            throw NotFound.new(
                errorText: "Cannot find event to update end time",
                humanText: "Не найдено событие для изменения времени окончания",
                parameters: ["activityId": activity.id]
            )
        }
        
        event.endDate = event.endDate.addingTimeInterval(timeInterval)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            loadCurrentActivity() // Обновляем UI
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось изменить время окончания события",
                parameters: ["activityId": activity.id]
            )
        }
    }
    
    func endCurrentActivity(endDate: Date) throws {
        guard let activity = currentActivity else { return }
        
        try updateCalendarEvent(eventId: activity.id.components(separatedBy: "_part").first ?? "", newEndDate: endDate)
        
        loadCurrentActivity()
    }

    func extendSession(eventId: String, by timeInterval: TimeInterval) throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw NotFound.new(
                errorText: "Cannot find event to extend",
                humanText: "Не найдено событие для продления",
                parameters: ["eventId": eventId]
            )
        }
        
        // Продлеваем от ТЕКУЩЕГО времени, а не от старого времени окончания
        event.endDate = Date().addingTimeInterval(timeInterval)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            // После продления нужно обновить состояние
            loadPreviousActivity()
            // Также проверим, не стало ли это событие текущим
            loadCurrentActivity()
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось продлить событие",
                parameters: ["eventId": eventId]
            )
        }
    }

    func finishSessionNow(eventId: String) throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw NotFound.new(
                errorText: "Cannot find event to finish",
                humanText: "Не найдено событие для завершения",
                parameters: ["eventId": eventId]
            )
        }
        
        event.endDate = Date()
        
        do {
            try eventStore.save(event, span: .thisEvent)
            loadPreviousActivity()
            loadCurrentActivity()
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось завершить событие",
                parameters: ["eventId": eventId]
            )
        }
    }
    
    private func createCalendarEvent(
        title: String,
        calendarId: String,
        duration: TimeInterval,
        startDate: Date
    ) throws {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw NotFound.new(
                errorText: "Cannot find calendar for event creation",
                humanText: "Не найден календарь для создания события",
                parameters: ["calendarId": calendarId]
            )
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate // Используем переданную дату начала
        event.endDate = startDate.addingTimeInterval(duration)
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось создать событие",
                parameters: ["title": title, "calendarId": calendarId]
            )
        }
    }
    
    private func updateCalendarEvent(eventId: String, newEndDate: Date) throws {
        // Получаем событие напрямую по его идентификатору
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw NotFound.new(
                errorText: "Cannot find event for updating",
                humanText: "Не найдено событие для обновления",
                parameters: ["eventId": eventId]
            )
        }
        
        event.endDate = newEndDate
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось обновить событие",
                parameters: ["eventId": eventId]
            )
        }
    }
    
    func updateActivity(_ activity: TimeActivity) throws {
        guard let event = eventStore.event(withIdentifier: activity.id) else {
            throw NotFound.new(
                errorText: "Cannot find event for updating",
                humanText: "Не найдено событие для обновления",
                parameters: ["activity": activity]
            )
        }
        
        event.title = activity.title
        event.startDate = activity.startTime
        event.endDate = activity.endTime
        
        if let calendar = eventStore.calendar(withIdentifier: activity.calendarId) {
            event.calendar = calendar
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            loadCurrentActivity()
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось обновить событие",
                parameters: ["event": event]
            )
        }
    }
    
    func deleteActivity(_ activity: TimeActivity) throws {
        guard let event = eventStore.event(withIdentifier: activity.id) else {
            throw NotFound.new(
                errorText: "Cannot find event for deletion",
                humanText: "Не найдено событие для удаления",
                parameters: ["eventId": activity.id]
            )
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            loadCurrentActivity()
        } catch {
            throw InternalError.wrap(
                error: error,
                humanText: "Не удалось удалить событие"
            )
        }
    }
    
    func getActivities(from startDate: Date, to endDate: Date) -> [TimeActivity] {
        // Получаем только календари с настраиваемым префиксом
        let timeTrackingCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.title.contains(calendarPrefix)
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: timeTrackingCalendars
        )
        
        let events = eventStore.events(matching: predicate)
        var resultingActivities: [TimeActivity] = []

        for event in events {
            guard let eventEndDate = event.endDate else { continue } // Пропускаем сессии без времени окончания

            let calendar = Calendar.current
            let eventStartDate = event.startDate!

            // Если сессия не пересекает полночь, просто добавляем ее
            if calendar.isDate(eventStartDate, inSameDayAs: eventEndDate) || eventEndDate == calendar.startOfDay(for: eventEndDate) {
                if eventStartDate != eventEndDate { // Исключаем события с нулевой длительностью на границе дня
                    resultingActivities.append(TimeActivity(
                        id: event.eventIdentifier,
                        title: event.title,
                        calendarId: event.calendar.calendarIdentifier,
                        calendarName: event.calendar.title,
                        startTime: eventStartDate,
                        endTime: eventEndDate,
                        category: event.calendar.title
                    ))
                }
            } else {
                // Если сессия пересекает полночь, делим ее на части
                var currentDate = eventStartDate
                var partIndex = 1

                while currentDate < eventEndDate {
                    let startOfNextDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
                    let endOfThisSegment = min(startOfNextDay, eventEndDate)

                    if currentDate < endOfThisSegment { // Добавляем сегмент, только если он имеет продолжительность
                        let activityPart = TimeActivity(
                            id: "\(event.eventIdentifier ?? UUID().uuidString)_part\(partIndex)",
                            title: event.title,
                            calendarId: event.calendar.calendarIdentifier,
                            calendarName: event.calendar.title,
                            startTime: currentDate,
                            endTime: endOfThisSegment,
                            category: event.calendar.title
                        )
                        resultingActivities.append(activityPart)
                    }

                    currentDate = endOfThisSegment
                    partIndex += 1
                }
            }
        }
        
        return resultingActivities
    }
    
    func getActivity(by id: String) throws -> TimeActivity {
        // Извлекаем оригинальный ID, отбрасывая суффикс "_part"
        let originalEventId = id.components(separatedBy: "_part").first ?? id
        
        guard let event = eventStore.event(withIdentifier: originalEventId) else {
            throw NotFound.new(
                errorText: "Cannot find event by id",
                humanText: "Не найдено событие по ID",
                parameters: ["id": id, "originalEventId": originalEventId]
            )
        }
        
        // Возвращаем полный, неразрезанный TimeActivity
        return TimeActivity(
            id: event.eventIdentifier,
            title: event.title,
            calendarId: event.calendar.calendarIdentifier,
            calendarName: event.calendar.title,
            startTime: event.startDate,
            endTime: event.endDate,
            category: event.calendar.title
        )
    }
    
    func getUniqueRecentActivities() -> [TimeActivity] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        
        let allActivities = getActivities(from: startDate, to: endDate)
        
        var uniqueActivities: [TimeActivity] = []
        var seenTuples = Set<String>()
        
        for activity in allActivities.reversed() { // Начинаем с самых свежих
            let tuple = "\(activity.title)-\(activity.calendarId)"
            if !seenTuples.contains(tuple) {
                uniqueActivities.append(activity)
                seenTuples.insert(tuple)
            }
        }
        
        return uniqueActivities
    }
    
    func getCalendarTitle(by id: String) -> String {
        return eventStore.calendar(withIdentifier: id)?.title ?? ""
    }
    
    // MARK: - Calendar Synchronization
    
    @objc private func calendarDidChange() {
        logger.debug("Данные календаря изменились, перезагружаю активности...")
        // Обновления UI должны происходить в основном потоке, так как они влияют на @Observable properties
        DispatchQueue.main.async { [weak self] in
            // loadCurrentActivity() уже вызывает loadPreviousActivity(), так что достаточно одного вызова
            self?.loadCurrentActivity()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
