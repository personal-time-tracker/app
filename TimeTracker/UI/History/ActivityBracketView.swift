//
//  ActivityBracketView.swift
//  TimeTracker
//
//  Created by Илья on 29.07.2025.
//

import SwiftUI

struct ActivityBracketView: View {
    let activity: TimeActivity
    let hourHeight: CGFloat
    let timelineStartOffset: CGFloat
    
    private var height: CGFloat {
        let durationInHours = max(activity.duration / 3600, 0.25) // Мин. высота
        return durationInHours * hourHeight
    }
    
    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: activity.startTime)
        let timeSinceStartOfDay = activity.startTime.timeIntervalSince(startOfDay)
        let hoursSinceStartOfDay = timeSinceStartOfDay / 3600
        // Добавляем половину высоты линии, чтобы выровнять по центру линии
        return (hoursSinceStartOfDay * hourHeight) + 0.5 * hourHeight
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            BracketShape()
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: 10)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(activity.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(activity.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("\(formatTime(activity.startTime)) - \(formatTime(activity.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 18)
        }
        .frame(height: height, alignment: .topLeading)
        .offset(x: timelineStartOffset, y: yOffset)
    }
}

struct BracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerSize: CGFloat = 8
        
        path.move(to: CGPoint(x: rect.minX + cornerSize, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerSize, y: rect.maxY))
        
        return path
    }
}

#Preview {
    DayTimelineView(
        activities: [
            TimeActivity(
                id: UUID().uuidString,
                title: "Title",
                calendarId: UUID().uuidString,
                calendarName: "Calendar",
                startTime: Date.now,
                endTime: Date.now.addingTimeInterval(3600),
                category: nil
            )
        ],
        date: Date()
    )
}
