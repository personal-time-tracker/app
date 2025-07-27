import SwiftUI

struct CurrentActivityWidget: View {
    @ObservedObject var calendarService: CalendarService
    @State private var showingActivitySheet = false
    
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
            if let currentSession = calendarService.currentSession {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentSession.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(getCalendarTitle(for: currentSession.calendarId))
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
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Начать занятие")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Кнопка действия
            Button(action: {
                showingActivitySheet = true
            }) {
                HStack {
                    Image(systemName: calendarService.currentSession != nil ? "arrow.triangle.2.circlepath" : "play.fill")
                    Text(calendarService.currentSession != nil ? "Сменить занятие" : "Начать занятие")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(isPresented: $showingActivitySheet) {
            ActivitySelectionView(calendarService: calendarService)
        }
    }
    
    private func getCalendarTitle(for id: String) -> String {
        return calendarService.calendars.first { $0.id == id }?.title ?? "Неизвестный календарь"
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

#Preview {
    CurrentActivityWidget(calendarService: CalendarService())
} 