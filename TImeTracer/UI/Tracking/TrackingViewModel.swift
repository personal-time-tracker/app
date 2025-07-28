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
    @Injected(\.calendarService) private var calendarService
    
    var currentActivity: TimeSession?
    var previousActivity: TimeSession?
    var isShowNewSessionSheet: Bool = false
        
    func load() async throws {
        currentActivity = calendarService.currentActivity
        previousActivity = calendarService.previousActivity
    }
}
