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
    
    init() {}
        
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
}
