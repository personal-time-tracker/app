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

private let logger = Logger(subsystem: "TiteTracker", category: "Main")

@main
struct TImeTracerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                scheduleAppRefresh()
            }
        }
    }

    init() {
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
            let calendarService = CalendarService()
            calendarService.loadCurrentActivity() // Обновляем данные
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
        Factory(self) { return CalendarService() }.singleton
    }
}
