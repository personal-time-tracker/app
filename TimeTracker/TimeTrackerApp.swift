//
//  TImeTracerApp.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI
import AppIntents
import BackgroundTasks
import Factory
import OSLog
import EventKit

@main
struct TimeTrackerApp: App {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "TimeTracer")
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State var alert: AlertModel?
    
    @Injected(\.calendarService) private var calendarService

        
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    calendarService.loadData()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                scheduleAppRefresh()
            }
        }
    }

    init() {
        
        // Регистрируем фоновую задачу
        registerBackgroundTask()
        
        // Проверяем доступ к календарю
        do {
            try checkCalendarAccess()
        } catch {
//            alertManager.error(error)
        }
    }

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bonavi.timetracer.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func checkCalendarAccess() throws {
                
        // Смотрим статус доступа к календарю
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
            
        // Не определен
        case .notDetermined:
            try requestAccess(eventStore: EKEventStore())
            
        // Есть доступ, все ок
        case .fullAccess:
            break
            
        // Нет доступа или он не тот
        default:
            throw UserError.new(
                errorText: "Cannot access calendar",
                humanText: "Необходим доступ к календарям, текущий статус: \(status)",
                parameters: ["status": status]
            )
        }
    }
    
    private func requestAccess(eventStore: EKEventStore) throws {
        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                guard granted else {
                    throw UserError.new(
                        errorText: "Cannot access calendar",
                        humanText: "Необходим доступ к календарям",
                        parameters: ["granted": granted]
                    )
                }
            } catch {
                throw InternalError.wrap(
                    error: error,
                    humanText: "Не удалось получить доступ к календарю"
                )
            }
        }
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.bonavi.timetracer.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Не ранее, чем через 15 минут

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Планируем следующее обновление

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            
            // Инициализируем зависимости
            let eventStore = EKEventStore()
            let calendarRepository = CalendarRepository(eventStore: eventStore)
            let widgetSyncController = WidgetSyncController(calendarRepository: calendarRepository)
            
            // Получаем и кладем текущую активность в Defaults
            widgetSyncController.loadAndSaveCurrentActivityInDefaults()
            
            print("Background refresh completed")
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            operation.cancel()
            print("Background task expired")
        }

        queue.addOperation(operation)
    }
}

extension Container {
    var calendarService: Factory<CalendarService> {
        
        // Получаем стор календаря
        let eventStore = EKEventStore()
        
        // Инициализируем репозиторий
        let calendarRepository = CalendarRepository(eventStore: eventStore)
        
        // Инициализируем контроллер обновления виджета
        let widgetSyncController = WidgetSyncController(calendarRepository: calendarRepository)
        
        // Инициализируем сервис
        let calendarService = CalendarService(
            calendarRepository: calendarRepository,
            widgetSyncController: widgetSyncController
        )
        
        return Factory(self) { return calendarService }.singleton
    }
}
