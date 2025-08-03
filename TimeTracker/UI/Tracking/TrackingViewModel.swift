//
//  TrackingViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory

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
