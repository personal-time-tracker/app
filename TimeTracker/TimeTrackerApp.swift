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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
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

        task.expirationHandler = {
            // Task has expired. Clean up.
            print("Background task expired")
        }

        // Выполняем асинхронную работу в Task
        Task {
            let calendarService = Container.shared.calendarService()
            do {
                try await calendarService.loadCurrentActivity()
                print("Background refresh completed successfully")
                task.setTaskCompleted(success: true)
            } catch {
                print("Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}

extension Container {
    // CalendarService is no longer a MainActor, so we don't need any special handling here.
    var calendarService: Factory<CalendarService> {
        Factory(self) { CalendarService() }.singleton
    }
}
