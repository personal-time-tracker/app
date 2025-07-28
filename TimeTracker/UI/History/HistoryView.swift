import SwiftUI

struct HistoryView: View {
    
    @State private var vm = HistoryViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.sortedDates, id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        if let sessions = vm.sessionsByDate[date] {
                            ForEach(sessions) { session in
                                VStack(alignment: .leading) {
                                    Text(session.title)
                                        .font(.headline)
                                    Text("\(formatTime(session.startTime)) - \(formatTime(session.endTime ?? Date()))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("История")
            .onAppear {
                vm.fetchSessions()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
}
