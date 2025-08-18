//
//  Formatters.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import Foundation

// Форматирует надписи корректировки времени (+15 мин)
func formatTimeAdjustment(_ interval: TimeInterval) -> String {
        
    if interval > 0 {
        return "+ \(formatDuration(interval))"
    } else {
        return "- \(formatDuration(-interval))"
    }
}

// Форматирует время (00:00)
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

// Форматирует продолжительность (1ч 5 мин)
func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 && minutes > 0 {
        return "\(hours)ч \(minutes) мин"
    } else if hours > 0 {
        return "\(hours)ч"
    } else {
        return "\(minutes) мин"
    }
}

// Форматирует проценты (35%)
func formatPercentage(_ duration: TimeInterval) -> String {
    let totalSecondsInDay: Double = 24 * 60 * 60
    guard duration > 0 else { return "" }
    
    let percentage = (duration / totalSecondsInDay) * 100
    return String(format: "(%.0f%%)", percentage)
}