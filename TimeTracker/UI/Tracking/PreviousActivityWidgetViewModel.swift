//
//  PreviousActivityWidgetViewModel.swift
//  TimeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@MainActor
@Observable
class PreviousActivityWidgetViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    private var timer: Timer?
    var currentDate = Date()
    
    var alert: AlertModel?
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func timeSinceEndedString(for activity: TimeActivity) -> String {
        let sinceEnd = currentDate.timeIntervalSince(activity.endTime)
        return "Прошло: \(formatDuration(max(0, sinceEnd)))"
    }
        
    func extendSession(
        eventId: String,
        by duration: TimeInterval
    ) {
        Task {
            do {
                try await calendarService.extendSession(
                    eventId: eventId,
                    by: duration
                )
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
    
    func finishSessionNow(eventId: String) {
        Task {
            do {
                try await calendarService.finishSessionNow(eventId: eventId)
            } catch {
                alert = AlertModel(error: error)
            }
        }
    }
}