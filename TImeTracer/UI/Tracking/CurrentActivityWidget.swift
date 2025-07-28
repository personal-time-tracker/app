import SwiftUI

struct CurrentActivityWidget: View {
        
    @Binding var currentSession: TimeSession?
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
            if let currentSession = currentSession {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentSession.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(currentSession.calendarName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(currentSession.duration))
                            .font(.caption)
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
                Button {
                    isShowNewSessionSheet = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Сменить занятие")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                
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
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
}

#Preview("With data") {
    VStack {
        CurrentActivityWidget(
            currentSession: .constant(TimeSession(
                id: UUID().uuidString,
                title: "Занятие",
                calendarName: "⏱️ Работа",
                startTime: Date.now.addingTimeInterval(-3600),
                endTime: Date.now,
                category: nil
            )),
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Without data") {
    VStack {
        CurrentActivityWidget(
            currentSession: .constant(nil),
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
