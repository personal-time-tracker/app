import SwiftUI
import Charts
import Factory

struct AnalyticsTab: View {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    @State private var vm = AnalyticTabViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Период
                Picker("Период", selection: $vm.selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Общая статистика
                StatisticsCardsView(activities: vm.activities)
                
                // График по дням
                DailyChartView(activities: vm.activities)
                
                // Топ занятий
                TopActivitiesView(activities: vm.activities)
            }
            .padding()
        }
        .navigationTitle("Аналитика")
    }
}

struct StatisticsCardsView: View {
    let activities: [Activity]
    
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
                value: "\(activities.count)",
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
        Array(Set(activities.map { $0.title }))
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = activities.reduce(0) { $0 + $1.duration }
        return formatDuration(totalSeconds)
    }
    
    private func formatAverageSession() -> String {
        let totalSeconds = activities.reduce(0) { $0 + $1.duration }
        return formatDuration(totalSeconds)
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
    let activities: [Activity]
    
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
        let groupedactivities = Dictionary(grouping: activities) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return groupedactivities.map { date, activities in
            let totalHours = activities.reduce(0) { $0 + $1.duration } / 3600
            return DailyData(
                day: calendar.component(.day, from: date),
                hours: totalHours
            )
        }.sorted { $0.day < $1.day }
    }
}



struct TopActivitiesView: View {
    let activities: [Activity]
    
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
        let grouped = Dictionary(grouping: activities) { $0.title }
        return grouped.map { title, activities in
            let totalDuration = activities.reduce(0) { $0 + $1.duration }
            return ActivityStats(title: title, totalDuration: totalDuration)
        }.sorted { $0.totalDuration > $1.totalDuration }
    }
}



#Preview {
    AnalyticsTab()
}
