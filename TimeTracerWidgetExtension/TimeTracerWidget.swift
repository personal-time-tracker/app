import WidgetKit
import SwiftUI

struct TimeTracerWidget: Widget {
    let kind: String = "TimeTracerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTracerTimelineProvider()) { entry in
            TimeTracerWidgetView(entry: entry)
        }
        .configurationDisplayName("TimeTracer")
        .description("Показывает текущее занятие")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TimeTracerWidgetView: View {
    let entry: TimeTracerTimelineEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Заголовок и время обновления
            HStack {
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Текущее занятие
            if let currentSession = entry.currentSession {
                VStack(spacing: 4) {
                    Text(currentSession.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(formatDuration(currentSession.duration))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Начать занятие")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
}

struct TimeTracerTimelineEntry: TimelineEntry {
    let date: Date
    let currentSession: TimeSession?
}

struct TimeTracerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeTracerTimelineEntry {
        TimeTracerTimelineEntry(
            date: Date(),
            currentSession: TimeSession(
                id: UUID().uuidString,
                title: "Работа",
                calendarName: "test",
                startTime: Date.now.addingTimeInterval(-3600),
                endTime: Date.now,
                category: "Работа"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTracerTimelineEntry) -> ()) {
        let entry = TimeTracerTimelineEntry(date: Date(), currentSession: AppStorageService.getCurrentSession())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTracerTimelineEntry>) -> ()) {
        // Получаем текущую сессию
        let currentSession = AppStorageService.getCurrentSession()
        
        let entry = TimeTracerTimelineEntry(
            date: Date(),
            currentSession: currentSession
        )
        
        // Обновляем каждые 5 секунд
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

#Preview(as: .systemSmall) {
    TimeTracerWidget()
} timeline: {
    TimeTracerTimelineEntry(date: Date(), currentSession: nil)
    TimeTracerTimelineEntry(
        date: Date(),
        currentSession: TimeSession(
            id: UUID().uuidString,
            title: "Работа",
            calendarName: "test",
            startTime: Date.now.addingTimeInterval(-3600),
            endTime: Date.now,
            category: "Работа"
        )
    )
} 
