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
    }

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bonavi.timetracer.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
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
            Task {
                do {
                    try await widgetSyncController.loadAndSaveCurrentActivityInDefaults()
                } catch {
                    
                }
            }
            
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


