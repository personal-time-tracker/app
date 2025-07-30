import SwiftUI

struct TimelineView: View {
    let activities: [TimeActivity]
    let selectedDate: Date
    
    var body: some View {
        ScrollView {
            DayTimelineView(activities: activities, date: selectedDate)
        }
    }
}

struct DayTimelineView: View {
    let activities: [TimeActivity]
    let date: Date
    
    private let hourHeight: CGFloat = 80.0
    private let timeLabelWidth: CGFloat = 60.0
    
    private struct ActivityLayout: Identifiable {
        let id: String
        let activity: TimeActivity
        let xOffset: CGFloat
    }
    
    private var activityLayouts: [ActivityLayout] {
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        var layouts: [ActivityLayout] = []
        let overlapIndent: CGFloat = 20.0

        for activity in sortedActivities {
            // Находим последнее событие, с которым текущее пересекается
            let lastOverlappingLayout = layouts.filter { layout in
                // Условие пересечения: (StartA < EndB) и (EndA > StartB)
                return activity.startTime < layout.activity.endTime && activity.endTime > layout.activity.startTime
            }.max { $0.xOffset < $1.xOffset }

            let newOffset: CGFloat
            if let lastOverlap = lastOverlappingLayout {
                newOffset = lastOverlap.xOffset + overlapIndent
            } else {
                newOffset = 0
            }
            
            layouts.append(ActivityLayout(id: activity.id, activity: activity, xOffset: newOffset))
        }
        return layouts
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Сетка времени (фон)
            VStack(spacing: 0) {
                ForEach(0...24, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Text(String(format: "%02d:00", hour))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .offset(y: -7)
                            .frame(width: timeLabelWidth - 4, alignment: .trailing)
                            .padding(.trailing, 4)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.systemGray5))
                    }
                    .frame(height: hourHeight)
                }
            }
            
            // Активности
            ForEach(activityLayouts) { layout in
                ActivityBracketView(
                    activity: layout.activity,
                    hourHeight: hourHeight,
                    timelineStartOffset: timeLabelWidth,
                    xOverlapOffset: layout.xOffset
                )
            }
        }
        .padding(.top, 12)
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
