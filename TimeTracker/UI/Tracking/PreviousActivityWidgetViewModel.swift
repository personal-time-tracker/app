//
//  PreviousActivityWidgetViewModel.swift
//  TimeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory

@Observable
class PreviousActivityWidgetViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    private var timer: Timer?
    var currentDate = Date()
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }
    
    func timeSinceEndedString(for activity: TimeActivity) -> String {
        let sinceEnd = currentDate.timeIntervalSince(activity.endTime)
        return "Прошло: \(formatDuration(max(0, sinceEnd)))"
    }
        
    func extendSession(
        eventId: String,
        by duration: TimeInterval
    ) {
        calendarService.extendSession(
            eventId: eventId,
            by: duration
        )
    }
    
    func finishSessionNow(eventId: String) {
        calendarService.finishSessionNow(eventId: eventId)
    }
    
    deinit {
        timer?.invalidate()
    }
}
