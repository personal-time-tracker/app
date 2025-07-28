import SwiftUI

struct PreviousActivityWidgetView: View {
    
    var previousActivity: TimeSession?
    
    @State private var vm = PreviousActivityWidgetViewModel()

    var body: some View {
        // Показываем виджет только если есть последняя завершенная сессия
        if let session = previousActivity {
            VStack(alignment: .leading, spacing: 12) {
                // Заголовок
                Text("Последнее занятие")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Информация о занятии
                VStack(alignment: .leading) {
                    Text(session.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(formatTime(session.startTime)) - \(formatTime(session.endTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Длительность: \(format(duration: session.duration))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Кнопки для продления и завершения
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button("+5 мин") {
                            vm.extendSession(eventId: session.id, by: 300)
                        }
                        .buttonStyle(ExtensionButtonStyle())
                        
                        Button("+15 мин") {
                            vm.extendSession(eventId: session.id, by: 900)
                        }
                        .buttonStyle(ExtensionButtonStyle())
                        
                        Button("+30 мин") {
                            vm.extendSession(eventId: session.id, by: 1800)
                        }
                        .buttonStyle(ExtensionButtonStyle())
                    }
                    
                    Button(action: {
                        vm.finishSessionNow(eventId: session.id)
                    }) {
                        Label("Закончить сейчас", systemImage: "stop.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain) // Используем plain, чтобы наш фон применился корректно
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // Хелпер для форматирования времени
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // Хелпер для форматирования времени
    private func format(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

// Стиль для кнопок
struct ExtensionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.accentColor.opacity(0.15))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
    }
}

// Preview
struct PreviousActivityWidget_Previews: PreviewProvider {
    static var previews: some View {      
        return PreviousActivityWidgetView(
            previousActivity: nil
        )
            .padding()
            .background(Color(.systemGroupedBackground))
    }
} 
