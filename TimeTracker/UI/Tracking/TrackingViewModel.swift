//
//  TrackingViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory
import SwiftUI

@Observable
class TrackingViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) var calendarService
    
    var isShowNewSessionSheet: Bool = false
    var currentDate = Date()
    var alert: AlertModel?
    private var timer: Timer?

    var currentActivity: Activity? {
        return calendarService.currentActivity
    }

    var previousActivity: Activity? {
        return calendarService.previousActivity
    }
    
    let continueEndExtendActivitySuggestions: [TimeInterval] = [300, 900, 1800]

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }
    
    deinit {
        timer?.invalidate()
    }

    // MARK: - Current Activity Logic
    
    func progress(for activity: Activity) -> Double {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        let total = activity.endTime.timeIntervalSince(activity.startTime)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
    
    func elapsedTimeString(for activity: Activity) -> String {
        let elapsed = currentDate.timeIntervalSince(activity.startTime)
        return formatDuration(max(0, elapsed))
    }
    
    func remainingTimeString(for activity: Activity) -> String {
        let remaining = activity.endTime.timeIntervalSince(currentDate)
        return formatDuration(max(0, remaining))
    }
    
    func extendCurrentActivity(by timeInterval: TimeInterval) async {
        do {
            guard let activity = currentActivity else {
                throw UserError.new(
                    errorText: "Unable to add time, because no activity is currently running",
                    humanText: "Невозможно добавить время"
                )
            }
            let newEndTime = activity.endTime.addingTimeInterval(timeInterval)
            try await calendarService.updateActivity(req: UpdateActivity(id: activity.id, endTime: newEndTime))
        } catch {
            alert = AlertModel(error: error)
        }
    }
    
    func finishCurrentActivityNow() async {
        do {
            guard let activity = currentActivity else {
                throw UserError.new(
                    errorText: "Unable to add time, because no activity is currently running",
                    humanText: "Невозможно завершить активность"
                )
            }
            try await calendarService.updateActivity(req: UpdateActivity(id: activity.id, endTime: Date()))
        } catch {
            alert = AlertModel(error: error)
        }
    }

    // MARK: - Previous Activity Logic
    
    func timeSinceEndedString(for activity: Activity) -> String {
        let sinceEnd = currentDate.timeIntervalSince(activity.endTime)
        return "Прошло: \(formatDuration(max(0, sinceEnd)))"
    }
        
    func continueAndExtendPreviousActivity(by duration: TimeInterval) async {
        do {
            guard let activity = previousActivity else {
                throw UserError.new(
                    errorText: "Unable to add time, because there is no previous activity",
                    humanText: "Невозможно продолжить активность"
                )
            }
            let newEndTime = currentDate.addingTimeInterval(duration)
            try await calendarService.updateActivity(req: UpdateActivity(id: activity.id, endTime: newEndTime))
        } catch {
            alert = AlertModel(error: error)
        }
    }
}
