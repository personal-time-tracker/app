import SwiftUI

struct HistoryView: View {
    
    @State private var vm = HistoryViewModel()
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.sortedDates, id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        if let activities = vm.activitiesByDate[date] {
                            ForEach(activities) { activity in
                                NavigationLink(destination: EditActivityView(activity: activity)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(activity.title)
                                                .font(.headline)
                                            Text(activity.calendarName.replacingOccurrences(of: "\(calendarPrefix)", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
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
                        }
                    }
                }
            }
            .navigationTitle("История")
            .onAppear {
                vm.fetchActivities()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        if totalSeconds <= 0 {
            return ""
        }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)ч \(minutes)м"
        } else if hours > 0 {
            return "\(hours)ч"
        } else {
            return "\(minutes)м"
        }
    }
    
    private func formatPercentage(_ duration: TimeInterval) -> String {
        let totalSecondsInDay: Double = 24 * 60 * 60
        guard duration > 0 else { return "" }
        
        let percentage = (duration / totalSecondsInDay) * 100
        return String(format: "(%.1f%%)", percentage)
    }
}

#Preview {
    HistoryView()
}
