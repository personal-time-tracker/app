//
//  CurrentActivityViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@MainActor
@Observable
class CurrentActivityWidgetViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    private var timer: Timer?
    var currentDate = Date()
    
    var alert: AlertModel?
    
    func startTimer() {
        // Invalidate any existing timer before creating a new one
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func progress(for activity: TimeActivity) -> Double {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        let total = activity.endTime.timeIntervalSince(activity.startTime)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
    
    func elapsedTimeString(for activity: TimeActivity) -> String {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        return formatDuration(max(0, elapsed))
    }
    
    func remainingTimeString(for activity: TimeActivity) -> String {
        let remaining = activity.endTime.timeIntervalSince(currentDate)
        return formatDuration(max(0, remaining))
    }
    
    func updateEndTime(for activity: TimeActivity, by timeInterval: TimeInterval) {
        Task {
            do {
                try await calendarService.updateActivityEndTime(for: activity, by: timeInterval)
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