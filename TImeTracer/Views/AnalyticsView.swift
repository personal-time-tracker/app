import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var calendarService: CalendarService
    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var sessions: [TimeSession] = []
    
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Период
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Общая статистика
                    StatisticsCardsView(sessions: sessions)
                    
                    // График по дням
                    DailyChartView(sessions: sessions)
                    
                    // Топ занятий
                    TopActivitiesView(sessions: sessions)
                    
                    // График по категориям
                    CategoryChartView(sessions: sessions)
                }
                .padding()
            }
            .navigationTitle("Аналитика")
            .onAppear {
                loadSessions()
            }
            .onChange(of: selectedPeriod) { _ in
                loadSessions()
            }
        }
    }
    
    private func loadSessions() {
        let interval = selectedPeriod.dateInterval
        sessions = calendarService.getSessions(from: interval.start, to: interval.end)
    }
}

struct StatisticsCardsView: View {
    let sessions: [TimeSession]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Общее время",
                value: formatTotalTime(),
                icon: "clock.fill",
                color: .blue
            )
            
            StatCard(
                title: "Сессий",
                value: "\(sessions.count)",
                icon: "number.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Средняя сессия",
                value: formatAverageSession(),
                icon: "timer",
                color: .orange
            )
            
            StatCard(
                title: "Активность",
                value: "\(uniqueActivities.count)",
                icon: "list.bullet",
                color: .purple
            )
        }
    }
    
    private var uniqueActivities: [String] {
        Array(Set(sessions.map { $0.title }))
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
    
    private func formatAverageSession() -> String {
        guard !sessions.isEmpty else { return "0м" }
        
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let averageSeconds = totalSeconds / Double(sessions.count)
        let minutes = Int(averageSeconds) / 60
        
        return "\(minutes)м"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DailyChartView: View {
    let sessions: [TimeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Активность по дням")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(dailyData) { data in
                    BarMark(
                        x: .value("День", data.day),
                        y: .value("Время", data.hours)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("Графики доступны в iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dailyData: [DailyData] {
        let calendar = Calendar.current
        let groupedSessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return groupedSessions.map { date, sessions in
            let totalHours = sessions.reduce(0) { $0 + $1.duration } / 3600
            return DailyData(
                day: calendar.component(.day, from: date),
                hours: totalHours
            )
        }.sorted { $0.day < $1.day }
    }
}

struct DailyData: Identifiable {
    let id = UUID()
    let day: Int
    let hours: Double
}

struct TopActivitiesView: View {
    let sessions: [TimeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Топ занятий")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(topActivities.prefix(5), id: \.title) { activity in
                HStack {
                    Text(activity.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatDuration(activity.totalDuration))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var topActivities: [ActivityStats] {
        let grouped = Dictionary(grouping: sessions) { $0.title }
        return grouped.map { title, sessions in
            let totalDuration = sessions.reduce(0) { $0 + $1.duration }
            return ActivityStats(title: title, totalDuration: totalDuration)
        }.sorted { $0.totalDuration > $1.totalDuration }
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

struct ActivityStats {
    let title: String
    let totalDuration: TimeInterval
}

struct CategoryChartView: View {
    let sessions: [TimeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("По категориям")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(categoryData) { data in
                    SectorMark(
                        angle: .value("Время", data.hours),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Категория", data.category))
                }
                .frame(height: 200)
            } else {
                Text("Графики доступны в iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var categoryData: [CategoryData] {
        let grouped = Dictionary(grouping: sessions) { $0.category ?? "Без категории" }
        return grouped.map { category, sessions in
            let totalHours = sessions.reduce(0) { $0 + $1.duration } / 3600
            return CategoryData(category: category, hours: totalHours)
        }.sorted { $0.hours > $1.hours }
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let hours: Double
}

#Preview {
    AnalyticsView(calendarService: CalendarService())
} 