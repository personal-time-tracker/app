//
//  TrackingViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")

@Observable
class TrackingViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) var calendarService
    
    var alert: AlertModel?
    
    var currentActivity: TimeActivity? {
        return calendarService.currentActivity
    }

    var previousActivity: TimeActivity? {
        return calendarService.previousActivity
    }
    
    var isShowNewSessionSheet: Bool = false
}
