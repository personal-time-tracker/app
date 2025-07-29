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
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Сетка времени (фон)
                VStack(spacing: 0) {
                    ForEach(0...24, id: \.self) { hour in
                        HStack(alignment: .center, spacing: 10) {
                            Text(String(format: "%02d:00", hour))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 10)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(.systemGray5))
                        }
                        .frame(height: hourHeight)
                    }
                }
                
                // Активности (накладываются поверх)
                ForEach(activities) { activity in
                    ActivityBracketView(activity: activity, hourHeight: hourHeight, timelineStartOffset: timeLabelWidth)
                }
            }
        }
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
