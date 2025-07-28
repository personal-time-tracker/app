import SwiftUI

struct CurrentActivityWidgetView: View {
    
    @State private var vm = CurrentActivityWidgetViewModel()
        
    var currentActivity: TimeActivity?
    @Binding var isShowNewSessionSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Сейчас занимаюсь")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Текущее занятие
            if let currentSession = currentActivity {
                VStack(alignment: .leading, spacing: 12) {
                    // Информация о занятии
                    VStack(alignment: .leading) {
                        Text(currentSession.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Время начала и окончания + длительность
                        Text("\(formatTime(currentSession.startTime)) - \(formatTime(currentSession.endTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Полоса прогресса
                    VStack(spacing: 4) {
                        ProgressView(value: vm.progress(for: currentSession))
                            .tint(.blue)
                        
                        HStack {
                            Text(vm.elapsedTimeString(for: currentSession))
                            Spacer()
                            Text(vm.remainingTimeString(for: currentSession))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Календарь
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(currentSession.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(currentSession.duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Кнопка действия
                HStack(spacing: 8) {
                    Button {
                        isShowNewSessionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Сменить")
                        }
                        .fontWeight(.medium)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let currentActivity {
                        Button {
                            vm.finishSessionNow(eventId: currentActivity.id)
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Завершить")
                            }
                            .fontWeight(.medium)
                            .padding()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                
            } else {
                Button {
                    isShowNewSessionSheet = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Начать занятие")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)ч \(minutes)м"
        } else if hours > 0 {
            return "\(hours)ч"
        } else {
            return "\(minutes)м"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview("With data") {
    VStack {
        CurrentActivityWidgetView(
            currentActivity: TimeActivity(
                id: UUID().uuidString,
                title: "Занятие",
                calendarId: UUID().uuidString,
                calendarName: "⏱️ Работа",
                startTime: Date.now.addingTimeInterval(-3600),
                endTime: Date.now,
                category: nil
            ),
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Without data") {
    VStack {
        CurrentActivityWidgetView(
            currentActivity: nil,
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
