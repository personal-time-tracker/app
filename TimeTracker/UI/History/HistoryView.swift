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
                                    ActivityRow(activity: activity)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("История")
        }
    }
}

#Preview {
    HistoryView()
}
