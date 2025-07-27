//
//  TImeTracerApp.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI
import AppIntents
import BackgroundTasks

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
            calendarService.loadCurrentSession() // Обновляем данные
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

// Регистрируем интенты для Shortcuts
@available(iOS 16.0, *)
extension TImeTracerApp: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimeTrackingIntent(),
            phrases: [
                "Начать трекинг времени в ${applicationName}",
                "Запустить ${applicationName}",
                "Начать занятие в ${applicationName}"
            ],
            shortTitle: "Начать трекинг",
            systemImageName: "play.circle.fill"
        )
        
        AppShortcut(
            intent: EndTimeTrackingIntent(),
            phrases: [
                "Завершить трекинг времени в ${applicationName}",
                "Остановить ${applicationName}",
                "Завершить занятие в ${applicationName}"
            ],
            shortTitle: "Завершить трекинг",
            systemImageName: "stop.circle.fill"
        )
    }
}
