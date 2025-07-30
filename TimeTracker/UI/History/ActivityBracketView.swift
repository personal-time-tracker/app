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
    
    private var height: CGFloat {
        let minSizeInHours: CGFloat = 0.25
        let activityDurationInHours = activity.duration / 3600
        let ziseInHours = max(activityDurationInHours, minSizeInHours) // Мин. высота
        return ziseInHours * hourHeight
    }
    
    var body: some View {
            BracketShape()
                .stroke(Color.blue, lineWidth: 3)
                .overlay(alignment: .topLeading) {
                    BracketShapeDescription(
                        activity: activity,
                        isNeedShowDuration: true
                    )
                    .padding(.leading)
                }
            

        .frame(height: height, alignment: .topLeading)
        .padding(.leading)
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
    ActivityBracketView(
        activity:
        TimeActivity(
            id: UUID().uuidString,
            title: "Title",
            calendarId: UUID().uuidString,
            calendarName: "Calendar",
            startTime: Date.now,
            endTime: Date.now.addingTimeInterval(3600),
            category: nil
        ),
        hourHeight: 10
    )
}

struct BracketShapeDescription: View {
    
    var activity: TimeActivity
    var isNeedShowDuration: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(activity.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(activity.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if isNeedShowDuration {
                Text("\(formatTime(activity.startTime)) - \(formatTime(activity.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
