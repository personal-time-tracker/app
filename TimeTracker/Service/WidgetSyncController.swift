//
//  WidgetSyncController.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import SwiftUI

final class WidgetSyncController {
    
    var tracking: Any?
    let calendarRepository: CalendarRepository

    init(calendarRepository: CalendarRepository) {
        self.calendarRepository = calendarRepository
        self.tracking = withObservationTracking {
            _ = calendarRepository.events
        } onChange: {
            let currentActivity = calendarRepository.events.filter{ $0.isActive }.last
            self.saveCurrentActivityInDefaults(currentActivity)
        }
    }
    
    func saveCurrentActivityInDefaults(_ activity: Activity?) {
        AppStorageService.saveCurrentActivity(activity)
    }
    
    // Сохраняет текущую активность в UserDefaults
    func loadAndSaveCurrentActivityInDefaults() async throws {
        let currentActivity = try await calendarRepository.getCurrentEvent()
        saveCurrentActivityInDefaults(currentActivity)
    }
}
