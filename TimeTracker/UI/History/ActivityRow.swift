//
//  ActivityRow.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import SwiftUI

struct ActivityRow: View {
    
    let activity: Activity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.title)
                    .font(.headline)
                Text(activity.calendarName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(formatTime(activity.startTime)) - \(formatTime(activity.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formatDuration(activity.duration))
                    .font(.headline)
                Text(formatPercentage(activity.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
