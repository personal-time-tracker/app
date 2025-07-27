//
//  TImeTracerApp.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI
import AppIntents

@main
struct TImeTracerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
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
