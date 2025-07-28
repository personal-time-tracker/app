//
//  CurrentActivityViewModel.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import Foundation
import Factory

@Observable
class CurrentActivityWidgetViewModel {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    init() {}
    
    func finishSessionNow(eventId: String) {
        calendarService.finishSessionNow(eventId: eventId)
    }
}
