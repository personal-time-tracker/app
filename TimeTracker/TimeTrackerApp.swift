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
    
    var alertManager: Factory<AlertManager> {
        return Factory(self) { return AlertManager() }.singleton
    }
}

@Observable
class AlertManager {
    
    init() {
        self.handle = { _ in }
    }
    
    let handle: (AlertModel) -> Void
    
    func error(
        _ error: Error,
        title: String = "Произошла ошибка",
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(error)")
        handle(AlertModel(title: title, message: error.localizedDescription, buttonText: buttonText, callback: callback))
    }
    
    func warn(
        title: String,
        message: String,
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(title)\n\(message)")
        handle(AlertModel(title: title, message: message, buttonText: buttonText, callback: callback))
    }
    
    init(handle: @escaping (AlertModel) -> Void) {
        self.handle = handle
    }
}

struct AlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
    let callback: () -> Void
}
