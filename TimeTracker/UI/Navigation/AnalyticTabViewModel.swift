//
//  AnalyticTabViewModel.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import SwiftUI
import Factory

@Observable
class AnalyticTabViewModel {
    
    @ObservationIgnored @Injected(\.calendarService) private var calendarService
    
    var selectedPeriod: AnalyticsPeriod = .week
    
    var activities: [Activity] {
        calendarService.activities
    }
}

struct DailyData: Identifiable {
    let id = UUID()
    let day: Int
    let hours: Double
}

struct ActivityStats {
    let title: String
    let totalDuration: TimeInterval
}

enum AnalyticsPeriod: String, CaseIterable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    
    var dateInterval: DateInterval {
        let now = Date()
        switch self {
        case .day:
            return DateInterval(start: Calendar.current.startOfDay(for: now), duration: 86400)
        case .week:
            return DateInterval(start: Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start ?? now, duration: 604800)
        case .month:
            return DateInterval(start: Calendar.current.dateInterval(of: .month, for: now)?.start ?? now, duration: 2592000)
        }
    }
}
