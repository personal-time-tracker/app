//
//  CurrentActivityViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import SwiftUI
import Factory

@Observable
class CurrentActivityWidgetViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    private var timer: Timer?
    var currentDate = Date()
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }
    
    func progress(for activity: TimeActivity) -> Double {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        let total = activity.endTime.timeIntervalSince(activity.startTime)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
    
    func elapsedTimeString(for activity: TimeActivity) -> String {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        return formatInterval(max(0, elapsed))
    }
    
    func remainingTimeString(for activity: TimeActivity) -> String {
        let remaining = activity.endTime.timeIntervalSince(currentDate)
        return formatInterval(max(0, remaining))
    }
    
    func updateEndTime(for activity: TimeActivity, by timeInterval: TimeInterval) {
        calendarService.updateActivityEndTime(for: activity, by: timeInterval)
    }
    
    func finishSessionNow(eventId: String) {
        calendarService.finishSessionNow(eventId: eventId)
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }

    deinit {
        timer?.invalidate()
    }
}
